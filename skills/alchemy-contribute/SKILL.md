---
name: alchemy-contribute
license: Wolfcito Open / Commercial License (WOCL). See LICENSE.
compatibility: Requires git, the gh CLI, and a package manager appropriate to the target repo (pnpm, bun, yarn, npm, cargo, forge or go).
metadata:
  version: "1.0.1"
description: Automates the end-to-end contribution workflow to Alchemy open-source repos (github.com/alchemyplatform/*) — read CONTRIBUTING, fork via gh, clone, set upstream, install deps with the right package manager, create a feature branch, run lint/tests, stage/commit, push, and open a Pull Request. Use this skill whenever the user wants to contribute to, hack on, open a PR on, or fork any Alchemy repo (alchemy-sdk-js, aa-sdk, alchemy-web3, alchemy-docs, modular-account, light-account, account-kit, etc.), or says things like "contribuir a alchemy", "abrir PR a alchemy", "fork alchemyplatform", "PR en alchemy-sdk-js", "contribuir open source en alchemy". Also applicable as a generic OSS contribution playbook when the target is not Alchemy — the same 11-step flow works on any GitHub repo.
---

# Alchemy Contribution Workflow

You help the user ship a Pull Request to an Alchemy open-source repository (or any other GitHub OSS repo) by executing — not just narrating — the 11 steps of the official Alchemy Contribution Checklist. The user explicitly invoked this skill because the manual flow is tedious; your job is to automate everything that is safely automatable and ask for confirmation only at irreversible boundaries.

## Why this skill exists

The published checklist is correct but slow when followed by hand: 11 steps, several with copy-paste of URLs and branch names, a package manager you have to detect, a commit message you have to compose, and a PR you have to fill out in the browser. Most of that is mechanical. The interesting work — code changes and the commit message — happens in steps 7 and 9. Everything around those steps should feel like a single command.

## Prerequisites — verify once at the start

Before touching anything, run these checks in parallel and report any failure to the user before proceeding:

- `gh auth status` — `gh` CLI must be authenticated. If not, tell the user to run `gh auth login` themselves (it's interactive) and pause.
- `git config user.name` and `git config user.email` — must be set, otherwise commits will be malformed.
- Ask the user once for their **initials** (used for branch prefix, e.g. `wf/fix-typo`). Cache them in memory for the rest of the session — do not ask again.

If anything is missing, surface it as a single consolidated message rather than failing one at a time.

## Identifying the target repo

The user may say "Alchemy SDK", "aa-sdk", "the docs repo", or paste a URL. Resolve the target as follows, in order:

1. If the user provided a full URL or `org/repo` slug, use it.
2. If they named a known Alchemy repo, prepend `alchemyplatform/` (e.g. `aa-sdk` → `alchemyplatform/aa-sdk`).
3. If ambiguous, list the candidates with `gh search repos --owner alchemyplatform <keyword>` and ask the user to pick.

Never guess silently — confirm the resolved `owner/repo` slug back to the user in one line before forking.

**If the resolved target is under `alchemyplatform/*`, read `references/alchemy-context.md` before continuing.** That file documents repo-specific overrides (the docs repo has rules around generated specs, Cloudinary-hosted images, the `content/docs.yml` navigation manifest, and `pnpm run validate`; Solidity repos use Foundry instead of pnpm; etc.). Skipping it leads to PRs that get bounced on review.

## The 11-step automated flow

Steps 1–5 (Prep & Setup), 6–8 (Development & QC), and 9–11 (Submission) below correspond to the official checklist. Items marked **[gate]** require explicit user confirmation because they are visible to others or hard to undo.

### 1. Read the manual

Fetch and read `CONTRIBUTING.md` from the upstream repo before doing anything else:

```bash
gh api repos/<owner>/<repo>/contents/CONTRIBUTING.md --jq '.content' | base64 -d
```

If it doesn't exist, fall back to `README.md`. Surface to the user any repo-specific rule that overrides this skill's defaults — common overrides: required commit format (Conventional Commits, semantic prefixes), branch naming, signed commits (`-S`), DCO sign-off (`-s`), or a CLA. **If the repo's CONTRIBUTING differs from this skill, the repo wins.**

### 2. Fork the repo **[gate]**

Forking is visible on the user's GitHub profile, so confirm before doing it. Then:

```bash
gh repo fork <owner>/<repo> --clone=false --remote=false
```

If a fork already exists under the user's account, `gh` will say so — that's fine, reuse it.

### 3. Clone your fork

Clone into the parent of the current working directory (or into a directory the user names). Use the user's GitHub login from `gh api user --jq .login`:

```bash
gh repo clone <user>/<repo>
```

Prefer `gh repo clone` over raw `git clone` so the remote URL respects the user's auth (HTTPS via gh, per global rules).

### 4. Navigate & connect upstream

```bash
cd <repo> && git remote add upstream https://github.com/<owner>/<repo>.git
```

Verify with `git remote -v` and show the user both `origin` (their fork) and `upstream` (the official repo). Always chain `cd` with `&&` — never assume the working directory persists across Bash invocations.

### 5. Install dependencies

Detect the package manager by looking for lockfiles, in this priority order:

| File present | Command |
|---|---|
| `pnpm-lock.yaml` | `pnpm install` |
| `bun.lockb` or `bun.lock` | `bun install` |
| `yarn.lock` | `yarn install` |
| `package-lock.json` | `npm install` |
| `Cargo.toml` | `cargo build` |
| `go.mod` | `go mod download` |

If `package.json` declares `"packageManager"`, that wins over lockfile inference. If multiple lockfiles coexist (rare but happens after a migration), warn the user and ask which one to honor — don't pick silently.

### 6. Create a feature branch

Never work on `main` / `master` / `develop`. Branch name: `<initials>/<short-kebab-description>` (or whatever the repo's CONTRIBUTING dictates). Ask the user for a one-line description of what they're about to do, then:

```bash
git switch -c <initials>/<description>
```

### 7. Make your changes

This is where the user's actual work happens. You are not in autopilot here — make the code changes the user requested, following the repo's conventions and existing patterns. Apply the user's standard workflow (SDD → TDD → EDD when applicable). When done, return to step 8.

### 8. Run linter & tests

Run the repo's quality gates before committing. Read `package.json` scripts (or the equivalent for non-JS repos) and run, in this order, whichever exist:

1. Type-check (`tsc --noEmit`, `pnpm typecheck`, etc.)
2. Lint (`pnpm lint`, `pnpm run lint`)
3. Format check (`pnpm format:check` or `prettier --check`)
4. Tests (`pnpm test` — but only if the change has tests or the repo runs fast)

Report the pass count to the user. **Do not auto-fix lint/format errors silently** — show what failed and let the user decide whether to apply auto-fixes. If tests fail, stop and surface the failure; don't mask it.

### 9. Stage & commit **[gate]**

Show the user `git status` and `git diff --staged` before committing. Compose a commit message that matches the repo's convention (check CONTRIBUTING.md and recent `git log --oneline -20`). Default to Conventional Commits if no convention is clear:

```
<type>(<scope>): <imperative summary>

<body explaining the why, not the what>
```

Stage files explicitly (avoid `git add .` to prevent accidentally staging `.env`, build artifacts, or sensitive files):

```bash
git add <specific files>
git commit -m "$(cat <<'EOF'
<message>
EOF
)"
```

If pre-commit hooks fail, **never** retry with `--no-verify`. Investigate, fix, re-stage, create a NEW commit (never `--amend` after a hook failure — see global rules).

### 10. Push to your fork **[gate]**

Push is visible to others (and triggers CI on the fork). Confirm, then:

```bash
git push -u origin <branch-name>
```

`-u` sets upstream tracking so future `git push` calls work without arguments.

### 11. Open a Pull Request **[gate]**

Use `gh pr create` rather than opening the browser. Use a HEREDOC for the body to preserve formatting. The PR body should follow the repo's PR template if it has one — check `.github/PULL_REQUEST_TEMPLATE.md` first; otherwise use `references/pr-template.md` from this skill as a fallback.

```bash
gh pr create \
  --repo <owner>/<repo> \
  --base main \
  --head <user>:<branch-name> \
  --title "<PR title — under 70 chars>" \
  --body "$(cat <<'EOF'
## Summary
- <bullet 1>
- <bullet 2>

## Test plan
- [ ] <test step>
EOF
)"
```

Return the PR URL to the user as the final output of the workflow.

## Resuming a partial run

The user may invoke this skill mid-flow (e.g. "I already forked and cloned, just open the PR"). Detect the current state instead of running every step:

- `git remote -v` shows `origin` + `upstream` → steps 2–4 done.
- `node_modules/` (or equivalent) exists → step 5 done.
- Current branch ≠ default branch → step 6 done.
- `git log <default>..HEAD` shows commits → step 9 done.
- `git rev-parse --abbrev-ref --symbolic-full-name @{u}` resolves → step 10 done.

Skip what's done, run what's missing.

## Failure modes to watch for

- **`gh` not installed**: tell the user to install it (`brew install gh` on macOS) and pause.
- **2FA / push fails with auth error**: the user's `gh` session may have expired — `gh auth refresh`.
- **Upstream uses a non-`main` default branch**: read `gh repo view <owner>/<repo> --json defaultBranchRef --jq .defaultBranchRef.name` instead of hard-coding `main`.
- **Monorepo with multiple package.jsons**: the lint/test commands may live in a sub-package; check the root `package.json` workspaces and run from the right directory.
- **Repo requires DCO sign-off**: append `-s` to `git commit`. CONTRIBUTING.md will say so.
- **Repo requires signed commits**: use `git commit -S`. The user's GPG key must be configured.

## What this skill does NOT do

- It does not write the code change for step 7 — that's the user's intent, not a mechanical step.
- It does not respond to PR review comments — that's a separate flow, run this skill again from step 7 if more changes are needed.
- It does not merge the PR — maintainers do that.
- It does not skip CONTRIBUTING.md. Always read it; the repo's rules override this skill.
