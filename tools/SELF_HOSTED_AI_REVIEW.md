# AI design review on your own machine (no API billing)

Yes, it's possible: the Claude Code and Codex CLIs can run non-interactively using
your **subscription login** (Claude Pro/Max/Team, or ChatGPT Plus/Pro) instead of
an API key. GitHub-hosted runners can't do that (no interactive login), so the
review runs on a **self-hosted runner** on your PC, or manually via the script.

## Option A - manual (no runner needed)
```powershell
claude            # once: /login   (or: codex login)
.\tools\ai-review.ps1 -PrNumber 7 -Post                 # Claude
.\tools\ai-review.ps1 -PrNumber 7 -Post -Provider codex # ChatGPT
```
It downloads the report from the PR's kicad-happy run and upserts a PR comment.

## Option B - automatic via self-hosted runner
1. Log the CLI in on this PC. Note: `claude auth status` showed the current login
   is the **Cubepilot Team** account and its token has expired; re-login, and
   decide whether a work account should review this repo.
   For ChatGPT: `npm i -g @openai/codex`, then `codex login`.
2. Register a runner (repo Settings -> Actions -> Runners -> New self-hosted
   runner -> Windows) with the label `ai-review`:
   `.\config.cmd --url https://github.com/MadManUAV/L431_RC_Periph --token <TOKEN> --labels ai-review`
   then `.\run.cmd`. If installed as a service, it must run as the user the CLI
   is logged in as.
3. Repo Settings -> Secrets and variables -> Actions -> Variables: add
   `LOCAL_AI_REVIEW` = `true`.
4. Repo Settings -> Actions -> General: "Require approval for all outside collaborators".
5. Choose the provider via `AI_PROVIDER` in `.github/workflows/kicad-happy-ai-local.yml`.

The PC must be on and the runner running for reviews to appear.

## Security (repo is public)
Never let a self-hosted runner run fork PR code. The workflow skips forks, never
checks out PR code, and the review script gives the LLM no tools.

## Terms
Check Anthropic/OpenAI terms for automated use of consumer subscriptions; keep use
personal and low-volume.
