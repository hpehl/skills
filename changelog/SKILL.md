---
name: changelog
description: >-
  This skill should be used when the user asks to "update the changelog",
  "add changelog entries", "generate release notes", "document recent changes",
  "write a changelog", "summarize recent changes", "prepare a release",
  or says /changelog. It adds entries to CHANGELOG.md
  following Keep a Changelog format by analyzing git history and uncommitted
  changes, categorizing them into Added, Changed, Deprecated, Removed, Fixed,
  and Security sections.
license: Apache-2.0
metadata:
  version: "0.1.0"
  author: "Harald Pehl <harald.pehl@gmail.com>"
---

# /changelog — Update Changelog from Recent Changes

Adds entries to a `CHANGELOG.md` file following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format by analyzing git history and uncommitted changes.

## Tools

- **Bash** — Run `git log`, `git tag`, `git diff`, `git diff --cached`, `git status`, and `git remote` commands
- **Read** — Read the existing `CHANGELOG.md`
- **Edit** — Insert new entries into the changelog (preferred for updates)
- **Write** — Create `CHANGELOG.md` from scratch when it doesn't exist

## Arguments

The skill accepts an optional argument string:

- **No argument**: Analyze commits since the last changelog entry or tag and add entries to `## [Unreleased]`
- **Version string** (e.g., `1.2.0`): Add entries under `## [1.2.0] - YYYY-MM-DD` using today's date
- **`unreleased`**: Explicitly target the `## [Unreleased]` section

## Changelog Format

The file MUST follow [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/):

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature description

### Changed
- Modified behavior description

### Deprecated
- Soon-to-be removed feature

### Removed
- Deleted feature description

### Fixed
- Bug fix description

### Security
- Vulnerability fix description

## [1.0.0] - 2024-01-15

### Added
- Initial release features
```

### Rules

- **Section order** is fixed: Added, Changed, Deprecated, Removed, Fixed, Security — never reorder or alphabetize
- **Dates** use ISO 8601 format: `YYYY-MM-DD`
- **Latest version** appears first, just below `[Unreleased]`
- **Only include sections** that have entries (don't add empty sections)
- **Each entry** is a bullet point starting with `- `
- **Entries are for humans**: write clear, concise descriptions of what changed and why it matters, not raw commit messages
- **Group related commits** into a single entry when they address the same change
- **Don't duplicate** entries already present in the changelog

## Commit-to-Section Mapping

| Commit Signal | Section |
|---------------|---------|
| `feat:`, `feat(scope):`, new files, new modules, new API endpoints | **Added** |
| `refactor:`, `perf:`, behavior changes, API changes | **Changed** |
| Deprecation notices, `deprecated` in message | **Deprecated** |
| Deleted files, removed features, `remove` in message | **Removed** |
| `fix:`, `fix(scope):`, bug fixes, error corrections | **Fixed** |
| `security:`, vulnerability patches, dependency security updates | **Security** |
| `feat!:`, `fix!:`, `BREAKING CHANGE:` in footer | **Prefix entry with "BREAKING:"** |

When a commit includes a scope (e.g., `feat(api): add endpoint`), use the scope as component context in the entry (e.g., "Add API endpoint"). When a commit doesn't clearly map to a type, read the diff to determine the appropriate section.

### Decision Rules for Ambiguous Cases

- If a commit both adds and removes user-visible functionality, categorize by the primary intent (e.g., `feat: replace old auth with OAuth` is **Added**, not Removed)
- If a refactor removes user-visible features or endpoints, categorize as **Removed**, not Changed
- If a performance improvement noticeably changes user experience (e.g., faster page loads), categorize as **Changed**
- Docs-only commits (`README.md`, `CONTRIBUTING.md`) are skipped unless they document a user-visible change (e.g., correcting a license is **Fixed**)
- `Initial commit` messages: skip if the changelog is being created retroactively for an established project; include as **Added** if this is genuinely a new project with meaningful initial functionality

## Execution Steps

1. **Find or create `CHANGELOG.md`** in the repository root.
   - If creating, add the standard header.

2. **Determine the target section**:
   - If the changelog has an `## [Unreleased]` section and no version argument was given, use it.
   - If a version argument was given, find or create `## [version] - YYYY-MM-DD`.
   - If no `[Unreleased]` exists and no version given, create `## [Unreleased]` below the header.

3. **Collect recent changes**:
   - Determine scope using git tags first: find the most recent tag matching `v*` or semver pattern.
   - If no tags exist, fall back to parsing the latest `## [x.y.z]` heading in the changelog to identify the last documented version, then use `git log` from that point.
   - If neither tags nor changelog versions exist, limit to the last 50 commits to avoid excessive analysis. The user can override scope by providing a commit range or tag as argument.
   - Run `git log --no-merges` to get commits within the determined scope.
   - Run `git diff` against the last version tag if available.
   - Run `git diff --cached` to collect staged but uncommitted changes.
   - Run `git diff` (no arguments) to collect unstaged changes in the working tree.
   - Combine committed and uncommitted changes. When the only source is uncommitted changes (no new commits in scope), still generate entries from those changes.

4. **Analyze and categorize**:
   - Parse commit messages for type prefixes (`feat:`, `fix:`, etc.).
   - Read diffs for commits without clear type prefixes.
   - Group related commits into single entries.
   - Skip merge commits and changelog-only commits.
   - Skip commits that only touch CI config, documentation, or non-user-facing files (e.g., `.github/`, `README.md`, `CHANGELOG.md`) unless they represent meaningful user-visible changes.

5. **Write entries**:
   - Use clear, human-readable language.
   - Start each entry with an imperative verb matching the section: Add, Change, Deprecate, Remove, Fix, Secure.
   - Include relevant context (what component, what behavior).
   - Prefix breaking changes with **BREAKING:** (detect via `!` suffix on commit type, e.g. `feat!:`, or `BREAKING CHANGE:` in commit footer).
   - Order entries within a section by significance: most impactful changes first.
   - Don't include commit hashes or author names.

6. **Insert into the changelog**:
   - Add section headers only for sections that have entries.
   - Place new entries in the target section.
   - Preserve all existing content below.
   - Don't modify existing entries.

7. **Generate comparison links**:
   - Run `git remote get-url origin` to detect the repository URL.
   - Detect the hosting platform from the remote URL hostname and generate platform-appropriate links:
     - **GitHub** (`github.com`): `https://github.com/user/repo/compare/v1.0.0...HEAD`
     - **GitLab** (`gitlab.com` or self-hosted): `https://gitlab.com/user/repo/-/compare/v1.0.0...HEAD`
     - **Bitbucket** (`bitbucket.org`): `https://bitbucket.org/user/repo/branches/compare/HEAD..v1.0.0`
   - Add link references at the bottom of the changelog:
     ```
     [Unreleased]: https://github.com/user/repo/compare/v1.0.0...HEAD
     [1.0.0]: https://github.com/user/repo/compare/v0.9.0...v1.0.0
     ```
   - If there are no prior tags, use the initial commit hash as the base for the `[Unreleased]` link.
   - Update existing link references when adding new versions.
   - Skip this step if the remote URL cannot be parsed or is not available.

8. **Show the user** the new entries and wait for confirmation before writing to the file. For versioned releases, display the full section for review.

## Examples

### Example 1: Adding to Unreleased

Before:
```markdown
## [Unreleased]

### Fixed
- Resolve timeout on large file uploads
```

After running `/changelog`:
```markdown
## [Unreleased]

### Added
- Support for WebSocket connections in the API gateway

### Fixed
- Resolve timeout on large file uploads
- Correct off-by-one error in pagination logic
```

### Example 2: Creating a versioned release

Running `/changelog 2.1.0`:
```markdown
## [2.1.0] - 2026-04-20

### Added
- Bulk import endpoint for market data
- Rate limiting middleware with configurable thresholds

### Changed
- Upgrade authentication flow to use PKCE

### Fixed
- Memory leak in connection pool during high traffic
```

### Example 3: Creating changelog from scratch

Running `/changelog` in a repo without `CHANGELOG.md`:
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup with CLI interface
- Configuration file support
- Logging framework integration
```

## Error Handling

Handle these conditions gracefully:
- **Not a git repository**: Inform user and stop — do not attempt to create a changelog without git history
- **Invalid version argument**: Validate that the argument matches semver (`X.Y.Z`); reject with a clear message if not
- **Malformed changelog**: If the existing file cannot be parsed (missing headers, broken markdown), warn the user and ask before overwriting
- **Git command failures**: If `git log` or `git diff` fails, report the error and stop rather than producing incomplete entries
- **No changes in scope**: If scope detection finds zero commits and no uncommitted changes, inform the user — do not add empty sections

## Anti-Patterns

- **Raw commit messages**: Don't paste commit messages verbatim; rewrite for humans
- **Empty sections**: Don't include section headers with no entries
- **Overwriting**: Never modify or delete existing changelog entries
- **Implementation details**: Focus on user-visible changes, not internal refactoring noise
- **Duplicate entries**: Check existing entries before adding new ones
- **Unbounded history**: Don't analyze the entire git history when there are no tags — cap at 50 commits
- **CI/docs noise**: Don't add entries for commits that only change CI config, linting rules, or documentation unless user-visible
- **Future tense**: Write entries as completed actions ("Add support for X"), not future plans ("Will add support for X")
- **Unmarked breaking changes**: Always clearly mark breaking changes (e.g., prefix with "**BREAKING:**")
- **Stale comparison links**: When adding a new version, update all comparison link references at the bottom of the file
