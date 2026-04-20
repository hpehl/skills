# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a collection of Claude Code skills — reusable prompt-based tools that extend Claude Code's capabilities via the `/skill` interface. Each skill lives in its own subdirectory.

## Structure

Each skill directory contains:
- `SKILL.md` — The skill definition with frontmatter (`name`, `description`) and full prompt instructions (trigger conditions, workflow, examples, anti-patterns)
- `.claude/settings.local.json` — Optional per-skill permission overrides (e.g., allowed domains for WebFetch)

## Creating a New Skill

1. Create a new directory under the repo root named after the skill
2. Add a `SKILL.md` with YAML frontmatter (`name`, `description`) followed by the skill prompt
3. Optionally add `.claude/settings.local.json` for skill-specific permissions
4. The skill prompt should define: trigger conditions, accepted arguments, step-by-step workflow, output format, examples, and anti-patterns

## Conventions

- Skill names use lowercase kebab-case for directory names
- `SKILL.md` frontmatter `name` field matches the directory name
- Skills are self-contained — each directory holds everything needed for that skill
