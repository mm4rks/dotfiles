#!/bin/bash
set -euo pipefail

# Scaffold a new OpenCode skill in the dotfiles repository.

main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <skill-name>"
        exit 1
    fi

    local skill_name="$1"
    local repo_dir
    repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." &>/dev/null && pwd)
    local target_dir="$repo_dir/opencode/.config/opencode/skills/$skill_name"

    if [[ -d "$target_dir" ]]; then
        echo "Error: Skill '$skill_name' already exists at $target_dir"
        exit 1
    fi

    mkdir -p "$target_dir/scripts"

    cat <<EOF > "$target_dir/SKILL.md"
---
name: $skill_name
description: [What it does]. Use when [specific trigger keywords or contexts].
---

# ${skill_name^}

## Overview
Briefly describe the purpose of this skill.

## Workflow
1. Step one...
2. Step two...

## Best Practices
- Keep instructions concise.
- Use concrete examples.
- Delegate complex logic to scripts in the scripts/ directory.
EOF

    echo "Successfully scaffolded '$skill_name' at $target_dir"
}

main "$@"
