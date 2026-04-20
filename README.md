# Skills

A collection of [Claude Code](https://claude.ai/code) skills — reusable prompt-based tools that extend Claude Code's capabilities.

## Installation

To install a skill, add this repository to your Claude Code project settings:

```bash
claude project add-skill https://github.com/hpehl/skills <skill-name>
```

Or clone the repository and add skills manually:

```bash
git clone https://github.com/hpehl/skills.git
```

Then reference the skill directory in your Claude Code configuration.

## Available Skills

| Skill | Description |
|-------|-------------|
| [changelog](changelog/SKILL.md) | Add entries to CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. Analyzes recent git changes and categorizes them into Added, Changed, Deprecated, Removed, Fixed, and Security sections. |

## Skill Structure

Each skill lives in its own directory and contains:

- **`SKILL.md`** — Skill definition with YAML frontmatter (`name`, `description`) and the full prompt (trigger conditions, workflow, examples, anti-patterns)
- **`.claude/settings.local.json`** — Optional per-skill permission overrides

## Creating a New Skill

1. Create a directory named after the skill (lowercase kebab-case)
2. Add a `SKILL.md` with frontmatter and prompt instructions
3. Optionally add `.claude/settings.local.json` for skill-specific permissions

## License

Apache-2.0
