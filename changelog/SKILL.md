---
name: changelog
description: Add entries to CHANGELOG.md following Keep a Changelog format. Analyzes recent git changes and categorizes them into Added, Changed, Deprecated, Removed, Fixed, and Security sections.
---

# /changelog — Update Changelog from Recent Changes

Adds entries to a `CHANGELOG.md` file following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format by analyzing recent git history.

## Trigger

Use this skill when:
- The user asks to update the changelog
- After a set of commits that should be documented
- Before a release to capture unreleased changes
- The user says `/changelog`

## Arguments

The skill accepts an optional argument string:

- **No argument**: Analyze commits since the last changelog entry or tag and add entries to `## [Unreleased]`
- **Version string** (e.g., `1.2.0`): Add entries under `## [1.2.0] - YYYY-MM-DD` using today's date
- **`unreleased`**: Explicitly target the `## [Unreleased]` section

## Workflow

```
┌─────────────────────────────────────────────┐
│  1. LOCATE CHANGELOG                        │
│     Find CHANGELOG.md in the repo root      │
│     If missing, create one with header      │
├─────────────────────────────────────────────┤
│  2. DETERMINE SCOPE                         │
│     Find the last version/tag in changelog  │
│     Collect commits since that point        │
├─────────────────────────────────────────────┤
│  3. CATEGORIZE CHANGES                      │
│     Map each commit to a changelog section  │
│     Use commit type, message, and diff      │
├─────────────────────────────────────────────┤
│  4. GENERATE ENTRIES                        │
│     Write human-readable descriptions       │
│     Group under correct section headers     │
├─────────────────────────────────────────────┤
│  5. INSERT INTO CHANGELOG                   │
│     Add to Unreleased or versioned section  │
│     Preserve existing content               │
└─────────────────────────────────────────────┘
```

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
| `feat:`, new files, new modules, new API endpoints | **Added** |
| `refactor:`, `perf:`, behavior changes, API changes | **Changed** |
| Deprecation notices, `deprecated` in message | **Deprecated** |
| Deleted files, removed features, `remove` in message | **Removed** |
| `fix:`, bug fixes, error corrections | **Fixed** |
| `security:`, vulnerability patches, dependency security updates | **Security** |

When a commit doesn't clearly map to a type, read the diff to determine the appropriate section.

## Execution Steps

1. **Find or create `CHANGELOG.md`** in the repository root.
   - If creating, add the standard header.

2. **Determine the target section**:
   - If the changelog has an `## [Unreleased]` section and no version argument was given, use it.
   - If a version argument was given, find or create `## [version] - YYYY-MM-DD`.
   - If no `[Unreleased]` exists and no version given, create `## [Unreleased]` below the header.

3. **Collect recent changes**:
   - Run `git log` to get commits since the last tagged/versioned entry.
   - Run `git diff` against the last version tag if available.
   - If no previous version exists, use all commits.

4. **Analyze and categorize**:
   - Parse commit messages for type prefixes (`feat:`, `fix:`, etc.).
   - Read diffs for commits without clear type prefixes.
   - Group related commits into single entries.
   - Skip merge commits and changelog-only commits.

5. **Write entries**:
   - Use clear, human-readable language.
   - Start each entry with a verb (Add, Change, Fix, Remove, etc.).
   - Include relevant context (what component, what behavior).
   - Don't include commit hashes or author names.

6. **Insert into the changelog**:
   - Add section headers only for sections that have entries.
   - Place new entries in the target section.
   - Preserve all existing content below.
   - Don't modify existing entries.

7. **Show the user** the entries that were added for review.

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

## Anti-Patterns

- **Raw commit messages**: Don't paste commit messages verbatim; rewrite for humans
- **Empty sections**: Don't include section headers with no entries
- **Overwriting**: Never modify or delete existing changelog entries
- **Implementation details**: Focus on user-visible changes, not internal refactoring noise
- **Duplicate entries**: Check existing entries before adding new ones
