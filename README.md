# Skills

A collection of [Claude Code](https://claude.ai/code) skills — reusable prompt-based tools that extend Claude Code's capabilities.

## Installation

Clone the repository:

```bash
git clone https://github.com/hpehl/skills.git
```

Then symlink the desired skill directory into your project or personal skills directory:

```bash
# Project-level (shared via repo)
ln -s /path/to/skills/<skill-name> .claude/skills/<skill-name>

# Personal/global (all projects)
ln -s /path/to/skills/<skill-name> ~/.claude/skills/<skill-name>
```

Symlink the entire directory (not just `SKILL.md`) so that optional files like `.claude/settings.local.json` are included.

## Available Skills

| Skill | Description |
|-------|-------------|
| [changelog](changelog/) | Update `CHANGELOG.md` following Keep a Changelog format by analyzing git history and uncommitted changes |
| [chezmoi](chezmoi/) | Dotfile management with chezmoi — detect drift in managed files, discover new config worth tracking, and health-check your setup. Supports 1Password template scaffolding for sensitive files. |

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
