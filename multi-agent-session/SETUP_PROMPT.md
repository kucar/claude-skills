Create the file ~/.claude/skills/multi-agent-session/SKILL.md with EXACTLY the content between the BEGIN and END lines below (do not include those two lines). Make the folder if it is missing. If the file already exists, back it up first to ~/.claude/handoffs/multi-agent-session-SKILL.backup.md. Then:
1. Check that `herdr` and `jq` are on PATH and that a `herdr` skill exists in ~/.claude/skills (it may be a symlink). Report the result.
2. Check that the `superpowers` plugin is installed. If it is not, tell me to install it with /plugin from claude-plugins-official. Do not install anything yourself.
3. Check whether a `grill-with-docs` skill exists. If it does not, just tell me. Do not install it.
4. Tell me to restart Claude inside a Herdr pane and type "multi agent session" (optionally followed by opus, sonnet or haiku).

-----BEGIN-----
---
name: multi-agent-session
description: Use when the user says "multi agent session" (or "multi-agent session"), optionally followed by a model (opus, sonnet, haiku or a full model ID). Makes this Claude the orchestrator of 3 worker agents in Herdr panes (default: the latest Opus); starts, resets or resumes them, and can add extra workers. Requires HERDR_ENV=1.
---

# Multi-Agent Session

You are the **orchestrator** (the brain). The workers do the work. Use the `herdr` skill for pane/agent commands; read its SKILL.md once if you have not this session.

## Names (one orchestrator = one pane)

```bash
P=$(echo "${HERDR_PANE_ID/:/}" | tr A-Z a-z)   # w8:pE -> w8pe (IDs carry the workspace, so unique; agent names must be lowercase)
H=~/.claude/handoffs/$(basename "$PWD")    # never inside the repo
```

- Workers: `$P-w1` … `$P-w6` (3 core + up to 3 extra). Below, `w1`/`<w>` means these full names.
- Your handoff: `$H/orchestrator-$P.md`. Briefs: `$H/brief-$P-w1.md` (w2, …).
- Workers with other prefixes belong to another orchestrator — never touch them, never touch their files.

## Worker model `M`

- Taken from the trigger: `multi agent session sonnet` → `M=sonnet`. Use the Claude Code aliases `opus`, `sonnet`, `haiku` as is (they always pick the latest model). A full model ID is used as is. Nothing named → `M=opus`.
- On Resume, `M` comes from the handoff file. If the user names a different model at Resume/Reset, say the workers already run on the old one; a new model needs a new session (close the workers, then Start).
- All workers use `M`. Never start a stronger model than `M` without asking the user.

## Know what your workers can do

Brief size, task choice and how hard you check depend on `M`:

| `M` | Give it | Brief | Check |
|---|---|---|---|
| Opus | Design, debugging, multi-file refactors, reviews, unclear problems | Goal + constraints; it can plan | Normal |
| Sonnet | Most normal coding: features, fixes, tests in a known area | Goal, files, steps for the hard part | Normal; you take the hard design calls |
| Haiku | Small mechanical work: search, rename, simple edits, run tests, collect facts | Exact files, exact steps, exact "done" | Strict; re-run its tests yourself |

If a task is beyond `M`, split it smaller, do the hard part yourself, or tell the user.

## Step 0: Start, Resume or Reset? Check Herdr and the file, not your memory

1. `test "${HERDR_ENV:-}" = 1` — if it fails, say "not inside Herdr" and stop.
2. `herdr agent list` and `test -f "$H/orchestrator-$P.md"`:

| Workers `$P-w*` exist | Handoff file exists | Do |
|---|---|---|
| No | any | **Start** |
| Yes | Yes | **Resume** |
| Yes | No | **Reset** |

## Start

1. Delete stale files from an old session with the same pane ID — exact names only:
   `rm -f "$H/orchestrator-$P.md" "$H"/brief-$P-w{1,2,3,4,5,6}.md`
2. Split the bottom half into 3 equal side-by-side panes (tested: gives exact thirds). Take each new pane ID from `.result.pane.pane_id`:

```bash
P1=$(herdr pane split --current --direction down --cwd "$PWD" --no-focus | jq -r .result.pane.pane_id)
P2=$(herdr pane split "$P1" --direction right --ratio 0.333 --cwd "$PWD" --no-focus | jq -r .result.pane.pane_id)
P3=$(herdr pane split "$P2" --direction right --ratio 0.5 --cwd "$PWD" --no-focus | jq -r .result.pane.pane_id)
herdr agent start "$P-w1" --kind claude --pane "$P1" -- --model "$M"
herdr agent start "$P-w2" --kind claude --pane "$P2" -- --model "$M"
herdr agent start "$P-w3" --kind claude --pane "$P3" -- --model "$M"
```

3. Tell the user in one line: "3 workers ready on <M>. Waiting for a task." Then wait.

## Extra workers (when you need more hands)

- Add one when there is more independent work than free workers and the work is worth the cost. Do not add one to go faster on a single task.
- Up to 3 extra (`w4`–`w6`), no need to ask; tell the user in one line. More than 6 in total → ask the user.
- Split the pane of an idle core worker: `PX=$(herdr pane split <pane of w1/w2/w3> --direction down --cwd "$PWD" --no-focus | jq -r .result.pane.pane_id)`, then `herdr agent start "$P-w4" --kind claude --pane "$PX" -- --model "$M"`.
- When its task is done and no more parallel work waits: `herdr agent prompt <w> "/exit"`, then `herdr pane close <its pane>`. Core workers `w1`–`w3` stay.

## Resume (after the user ran /clear)

1. Read `$H/orchestrator-$P.md` (it gives `M` and the worker list), then delete it.
2. Tell the user in one line what you continue with, the worker model, and the previous session ID from the file.

## Reset

1. Every worker must be `idle`/`done`. If one is working, ask the user — never kill a working agent.
2. Close extra workers (`w4`+): `/exit`, then close their panes.
3. Write `$H/orchestrator-$P.md` (`mkdir -p "$H"` first): goal, decisions taken, open items, worker state, and these lines:
   `Worker model: <M>`
   `Previous session: <value of $CLAUDE_CODE_SESSION_ID> (full history: /resume it)`
4. `herdr agent prompt <w> "/clear"` for each core worker. Keep the panes.
5. Tell the user: "Handoff saved. Run `/clear`, then type `multi agent session`." **Never clear or restart yourself** — the user does that.

## How to run the workers

- Split work into clear, independent tasks sized for `M`. For each task overwrite the worker's brief file (goal, files/area, skill to use, what "done" means, "report back in ≤5 lines") and prompt: `herdr agent prompt <w> "Read <brief path> and do it."` This avoids quoting problems with long text. Write a new brief only when that worker is `idle`/`done`.
- Pick skills for them: mostly `superpowers:*` and `grill-with-docs`; others when the task fits. Repo rules (CLAUDE.md, code-owner agents) still apply to workers.
- Wait with `herdr agent wait <w> --until idle --until done --until blocked`. **Never end your turn with workers busy and no wait running**: workers cannot message you. After you send a brief, start the wait with the Bash tool `run_in_background: true` (one wait for each worker, `--timeout 3600000`). You wake up when it exits. Then read the result and report to the user. Read only what you need: `herdr agent read <w> --source recent --lines 60`. Your context matters too.
- Check their work before calling it done. Be strict on correctness, safety and repo rules; flexible on style and small choices.

## Answering workers' questions as the user

- Superpowers / grilling / design questions: answer on the user's behalf like a human owner would — short, decisive, with a reason. Not robotic.
- Never change a project's direction (scope, product goals) on your own — ask the user.
- Report every answer you gave in ASD-STE100 simple English, this exact shape:

```
w2 asked: Should the retry limit be 3?
Answer: Yes. It stays below the 10s timeout.
```

## Permission prompts (worker is `blocked`)

- Approve normal work in the repo (read, edit, tests, local commands).
- **Ask the user first** for: installing any new skill or plugin (prompt-injection risk), git push, deleting files or branches, anything outside the repo, anything that sends data outside.

## Worker context

- To check usage, prompt the worker with `/context` and read the result.
- Over **15%**: when it is `idle`/`done`, `herdr agent prompt <w> "/compact Keep: goal, decisions, files touched, next steps."`
- Up to **35%** is fine if the job is almost done — finish instead.
- Workers only. Never restart yourself — the user refreshes your context.

## Replace a worker (only if it hangs or breaks)

1. `herdr agent get <w>` → note its pane ID.
2. `herdr agent prompt <w> "/exit"`, then check the pane is back to a shell (`herdr pane read <pane> --source visible --lines 5`).
3. `herdr agent start <same-name> --kind claude --pane <same-pane> -- --model "$M"`.
4. Send its brief again if the task is not done.

## Two orchestrators, one repo

Names and files never clash (pane IDs). The working tree does: if two orchestrators work in the same folder, tell the user to use a git worktree for one of them.
-----END-----
