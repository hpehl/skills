---
name: chezmoi
description: >-
  This skill should be used when the user asks to "check dotfiles",
  "update dotfiles", "chezmoi status", "find new config", "discover config",
  "dotfile health check", "chezmoi doctor", "what config files changed",
  "add config to chezmoi", "sync dotfiles",
  or says /chezmoi. It detects drift in managed dotfiles, discovers
  unmanaged config files worth tracking, and runs health checks on the
  chezmoi setup. Supports 1Password template scaffolding for sensitive files.
license: Apache-2.0
metadata:
  version: "0.1.0"
  author: "Harald Pehl <harald.pehl@gmail.com>"
---

# /chezmoi — Dotfile Management with Chezmoi

Operational dotfile management: detect drift, discover new config, and health-check your chezmoi setup.

## Tools

- **Bash** — Run `chezmoi status`, `chezmoi diff`, `chezmoi add`, `chezmoi git --`, `chezmoi doctor`, `chezmoi verify`, `op account list`, and the `filter-unmanaged.sh` helper script
- **Read** — Read file content for sensitivity scanning, read exclusion YAML files
- **Edit** — Update `excludes.local.yaml` when user excludes a file
- **Write** — Create `.tmpl` files in chezmoi source directory for sensitive file templates
- **AskUserQuestion** — Ask which subcommand to run, which files to add/exclude/skip, how to handle sensitive files

## Arguments

The skill accepts an optional subcommand:

- **No argument**: Show an overview of available subcommands and ask the user which to run
- **`status`**: Detect managed files with local drift
- **`discover`**: Find unmanaged config files worth tracking
- **`doctor`**: Run health checks on the chezmoi setup

## Subcommand Overview (no args)

When invoked without arguments, present this overview and ask which subcommand to run:

```
Chezmoi — Dotfile Management

Available subcommands:

  /chezmoi status    — Check for local changes to managed files that
                       haven't been captured back to the source repo yet

  /chezmoi discover  — Find config files in your home directory that
                       aren't managed by chezmoi, filtered to reduce noise

  /chezmoi doctor    — Health check: chezmoi doctor, verify, 1Password
                       connectivity, and source repo sync state

Which would you like to run?
```

Use **AskUserQuestion** to let the user pick a subcommand.

---

## Shared: Add Workflow

This workflow is used by both `status` and `discover` whenever a file needs to be added to chezmoi. It handles sensitivity detection, 1Password template scaffolding, and the git pipeline.

### Step 1: Sensitivity Scan

Before adding any file, scan it for secrets.

**For drifted files** (from `status`): run `chezmoi diff <file>` via Bash and scan the diff output for secret values.

**For new files** (from `discover`): read the full file content via Read and scan for secret values.

**Content-based detection** (always applied):
- Long random strings (high entropy, 20+ characters)
- Base64-encoded blobs
- Values adjacent to keys named `token`, `key`, `password`, `secret`, `auth`, `credential`, `api_key`, `apikey`, `access_token` in structured formats (JSON, YAML, TOML, XML, INI, env files)

**Path-based detection** (for new files from discover):
- Path contains: `ssh`, `gnupg`, `gpg`, `kube`, `aws`, `credentials`
- Filename contains: `secret`, `credential`, `token`, `key`, `password`, `auth`, `private`
- File permissions: check with `stat -f '%Lp' <file>` on macOS — mode 600 or more restrictive

If no secrets are detected, proceed directly to Step 3 (Git Pipeline).

### Step 2: Sensitive File Handling

When secrets are detected, use **AskUserQuestion** to ask the user:

```
This file appears to contain sensitive data. How should it be handled?
  1. Contains individual secrets (API keys, tokens) → Template with onepasswordRead
  2. Entire file is a secret (key, certificate)     → Template with onepasswordDocument
  3. Just needs restricted permissions               → Standard chezmoi add
  4. Not sensitive, false positive                   → Standard chezmoi add
```

#### Option 1: Template with `onepasswordRead`

For config files containing embedded secrets:

1. Read the file content
2. Identify which values are secrets
3. Generate a `.tmpl` version of the file. Replace each secret with a `{{ onepasswordRead "op://Vault/Item/Field" }}` placeholder. Keep all non-secret content exactly as-is.
4. Present the template to the user, listing each placeholder with its detected secret value (masked: show first 4 and last 4 characters only)
5. Ask the user to:
   - Store the secrets in 1Password (if not already there)
   - Provide the actual `op://` URI for each placeholder
6. Update the template with the real URIs
7. Determine the correct chezmoi source path:
   - Run `chezmoi source-path` to find the source directory
   - Convert the target path to chezmoi naming: replace leading `.` with `dot_`, use `private_` prefix for files with 600 permissions, add `.tmpl` suffix
   - Look at existing files in the source directory for naming convention reference
8. Write the template file to the source directory using Write
9. Proceed to Step 3

#### Option 2: Template with `onepasswordDocument`

For whole-file secrets (SSH private keys, certificates, PEM files):

1. Tell the user: "This file should be stored as a 1Password document. Please upload it to 1Password and provide the document UUID."
2. Wait for the user to provide the UUID
3. Create the template content: `{{- onepasswordDocument "<UUID>" }}`
4. Determine the correct source path (same logic as Option 1, with `private_` or `private_readonly_` prefix as appropriate)
5. Write the template file to the source directory using Write
6. Proceed to Step 3

#### Options 3 & 4: Standard add

Run via Bash:
```bash
chezmoi add ~/<file>
```

Chezmoi automatically detects file permissions and applies the `private_` prefix for 0600 files. Proceed to Step 3.

### Step 3: Git Pipeline

Run all git operations via Bash using chezmoi's native git integration:

1. Stage: `chezmoi git -- add .`
2. Commit: `chezmoi git -- commit -m "<message>"`
   - Generate a descriptive commit message from the files being added (e.g., "Add fish shell config and fzf bindings" or "Update zed editor settings")
   - For multiple files, summarize what changed rather than listing every file
3. Confirm with user before push (use **AskUserQuestion**: "Push to remote? [yes/no]")
4. Push: `chezmoi git -- push`

For multiple files added together, batch them into a single commit with a summary message.

---

## Subcommand: `status`

### Execution Steps

1. **Detect drift**: Run via Bash:
   ```bash
   chezmoi status
   ```
   Parse the output. Each line has a two-character status code and a file path (e.g., `MM .gitconfig`).

2. **Handle empty results**: If no output, report "All managed files are in sync" and stop.

3. **Group findings** by category based on the file path:
   - **Shell** — paths containing `fish`, `bash`, `zsh`, or shell config files (`.profile`, `.bashrc`, etc.)
   - **Git** — `.gitconfig`, `.gitignore_global`
   - **Config** — paths under `.config/`
   - **Sensitive** — paths under `.ssh/`, `.gnupg/`, or files that have `private_` prefix in the chezmoi source directory (check with `chezmoi source-path ~/<file>`)
   - **Other** — everything else

4. **Display summary table** showing each group with file paths and sensitivity flags.

5. **Offer actions** using **AskUserQuestion**:
   - **Add all** — run the shared Add Workflow for every drifted file
   - **Add selected** — present the file list and let the user pick which to add
   - **Diff** — ask which file to diff, then run `chezmoi diff ~/<file>` via Bash and display the output
   - **Skip** — do nothing, end the subcommand

6. **Execute chosen action**: For each file being added, run the shared Add Workflow (sensitivity scan on the diff → handling → git pipeline). Batch all files into a single commit when adding multiple.

---

## Subcommand: `discover`

### Execution Steps

1. **Locate the skill directory**: The `filter-unmanaged.sh` script, `excludes.yaml`, and `excludes.local.yaml` are in the same directory as this SKILL.md file. Determine the skill directory path from the skill invocation context.

2. **Run the filter script** via Bash:
   ```bash
   <skill-dir>/filter-unmanaged.sh <skill-dir>/excludes.yaml <skill-dir>/excludes.local.yaml
   ```
   Capture the output — one unmanaged file path per line (relative to home directory).

3. **Handle empty results**: If no output, report "No unmanaged config files found (after applying exclusion filters)" and stop.

4. **Group findings** by top-level directory (e.g., `.config/`, `.cargo/`, `.ssh/`).

5. **Present findings** grouped by directory with a count per group.

6. **For each finding**, use **AskUserQuestion** to offer:
   - **Add** — triggers the shared Add Workflow (sensitivity scan on full file content → handling → git pipeline)
   - **Exclude** — append the file's path pattern to `excludes.local.yaml` using Edit (add to the `patterns:` list). If the file is in a directory with other excluded siblings, suggest excluding the parent directory pattern (e.g., `.some-app/*` instead of `.some-app/cache.json`).
   - **Skip** — move to the next finding

7. **Batch adds**: Collect all files the user chose to add, then run the shared Add Workflow for the batch. Commit all together with a summary message.

---

## Subcommand: `doctor`

### Execution Steps

1. **Run chezmoi doctor** via Bash:
   ```bash
   chezmoi doctor
   ```
   Parse output for `ok`, `warning`, and `error` lines.

2. **Run chezmoi verify** via Bash:
   ```bash
   chezmoi verify 2>&1; echo "EXIT:$?"
   ```
   Exit code 0 means all files match. Non-zero means drift exists. Capture stderr for the list of differing files.

3. **Check 1Password connectivity** via Bash:
   ```bash
   op account list --format=json 2>/dev/null
   ```
   Parse for account names. If the command fails, report 1Password CLI is not authenticated.

4. **Check source repo state** via Bash:
   ```bash
   chezmoi git -- status --porcelain
   ```
   Empty output means clean. Non-empty means uncommitted changes.

5. **Check remote sync** via Bash:
   ```bash
   chezmoi git -- fetch --quiet 2>/dev/null
   DEFAULT_BRANCH=$(chezmoi git -- rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||')
   AHEAD=$(chezmoi git -- rev-list --count "origin/${DEFAULT_BRANCH}..HEAD" 2>/dev/null)
   BEHIND=$(chezmoi git -- rev-list --count "HEAD..origin/${DEFAULT_BRANCH}" 2>/dev/null)
   echo "branch:${DEFAULT_BRANCH} ahead:${AHEAD} behind:${BEHIND}"
   ```

6. **Display results** as a summary table with pass/warn/fail indicators for each check.

7. **Show recommendations** based on findings:
   - If verify found drift → suggest `/chezmoi status`
   - If source repo has uncommitted changes → suggest `chezmoi git -- add . && chezmoi git -- commit`
   - If local is ahead of remote → suggest `chezmoi git -- push`
   - If local is behind remote → suggest `chezmoi update`
   - If 1Password is not authenticated → suggest `eval $(op signin)`

---

## Error Handling

Handle these conditions gracefully:
- **chezmoi not installed**: Check with `command -v chezmoi` before any operation. Report and stop.
- **Not initialized**: If `chezmoi status` fails, suggest `chezmoi init`.
- **1Password CLI not installed**: If `op` is not found, skip 1Password checks in doctor and skip sensitivity Option 1/2 in the Add Workflow (fall back to standard add with a warning).
- **filter-unmanaged.sh not found**: If the script can't be located, report the error and suggest reinstalling the skill.
- **yq not installed**: The filter script handles this internally (grep fallback). No action needed.
- **Git push fails**: Report the error. Common causes: no remote configured, auth failure. Don't retry.
- **Empty chezmoi source directory**: If `chezmoi source-path` fails, suggest `chezmoi init`.

## Anti-Patterns

- **Never read secrets into conversation output**: When showing detected secrets during sensitivity scan, always mask them (show first 4 and last 4 characters only, e.g., `ghp_****...x7Qm`)
- **Never run `chezmoi add --encrypt`**: The user uses 1Password templates, not file encryption
- **Never use raw `cd` + `git`**: Always use `chezmoi git --` for git operations
- **Never modify `excludes.yaml`**: Only `excludes.local.yaml` gets modified at runtime (user's personal exclusions)
- **Never auto-push**: Always confirm with the user before running `chezmoi git -- push`
- **Never create directories manually**: Let chezmoi handle directory creation in the source state
- **Never skip the sensitivity scan**: Even for files that don't trigger path-based heuristics, always scan content before adding
