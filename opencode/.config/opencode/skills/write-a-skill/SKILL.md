---
name: write-a-skill
description: Create new agent skills for OpenCode with proper structure, trigger phrases, and bundled resources. Use when user wants to create, write, or build a new skill.
---

# Writing Skills

## Process

1.  **Gather requirements** - ask user about:
    - What task/domain does the skill cover?
    - What specific use cases should it handle?
    - Does it need executable scripts or just instructions?
2.  **Draft the skill** - create:
    - `SKILL.md` with concise instructions and frontmatter.
    - Additional reference files (e.g., `REFERENCE.md`) if content exceeds 100 lines.
    - Utility scripts in `scripts/` (bash or python) for deterministic operations.
3.  **Review with user** - present draft and ask for feedback.

## Skill Structure (Dotfiles Repo)

```
/home/user/.dotfiles/opencode/.config/opencode/skills/skill-name/
├── SKILL.md           # Main instructions (required)
├── REFERENCE.md       # Detailed docs (optional)
└── scripts/           # Utility scripts (optional)
    └── helper.sh
```

## SKILL.md Template

```markdown
---
name: skill-name
description: [One sentence covering what this skill does AND when to trigger it]. Use when [specific keywords or file types].
---

# Skill Name

## Workflow
1. [Step-by-step instructions]
```

## Description Requirements
The description is the **only** thing the agent sees when deciding which skill to load.
- **Goal**: Provide just enough info for the agent to know the capability and the trigger.
- **Format**: "What it does. Use when [triggers]."
- **Example**: "Format and lint shell scripts. Use when working with .sh files or when user mentions shellcheck."

## Scaffolding
Use the included helper script to scaffold a new skill:
`bash /home/user/.dotfiles/opencode/.config/opencode/skills/write-a-skill/scripts/scaffold_skill.sh <name>`

## Best Practices
- **Strict Mode**: All bash scripts must use `set -euo pipefail`.
- **Repository First**: Always write to `/home/user/.dotfiles/...`, never directly to `~/.config/...`.
- **Keep it Slim**: `SKILL.md` should be under 100 lines. Use separate files for deep references.
