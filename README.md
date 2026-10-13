# claude-skills

Personal [Claude Code](https://claude.com/claude-code) skills.

## multi-agent-session

Makes a Claude Code session the orchestrator of 3 worker agents in [Herdr](https://herdr.dev) panes.
Type `multi agent session` (optionally `opus`, `sonnet` or `haiku`) inside a Herdr pane.
See [multi-agent-session/SKILL.md](multi-agent-session/SKILL.md).

Needs: Claude Code, `herdr` + its skill, `jq`, the `superpowers` plugin. `grill-with-docs` is optional.

### Install

```bash
git clone https://github.com/kucar/claude-skills.git ~/claude-skills
mkdir -p ~/.claude/skills
ln -s ~/claude-skills/multi-agent-session ~/.claude/skills/multi-agent-session
sh ~/claude-skills/multi-agent-session/hooks/install.sh   # pane labels: 🔴 BUSY / 🟡 BG n (background tasks)
```

Update later with `git -C ~/claude-skills pull`.

No git on the machine? Paste [SETUP_PROMPT.md](multi-agent-session/SETUP_PROMPT.md) into Claude Code instead.
