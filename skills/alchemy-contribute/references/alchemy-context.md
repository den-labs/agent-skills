# Alchemy-specific contribution context

Read this whenever the target repo is under `github.com/alchemyplatform/*`. The generic 11-step flow in SKILL.md still applies, but Alchemy repos have their own conventions, and the docs repo in particular has rules that catch first-time contributors off-guard.

## Known Alchemy repos and what they are

| Repo | What it is | Stack |
|---|---|---|
| `alchemyplatform/docs` | Public docs content (MDX + OpenAPI/OpenRPC specs). Site is rendered by a separate private Next.js app. | pnpm + TypeScript + Remark |
| `alchemyplatform/aa-sdk` | Account Kit SDK (smart accounts, ERC-4337). SDK reference is auto-generated from this repo via TypeDoc into the docs site. | pnpm monorepo |
| `alchemyplatform/alchemy-sdk-js` | Main JS/TS SDK for the Alchemy Web3 API. | pnpm |
| `alchemyplatform/alchemy-web3` | Legacy web3.js extension (older; check if still active before contributing). | npm |
| `alchemyplatform/modular-account` | Solidity smart-account contracts (ERC-6900 modular). | Foundry |
| `alchemyplatform/light-account` | Lightweight smart-account contract. | Foundry |
| `alchemyplatform/rundler` | Rust-based ERC-4337 bundler. | Cargo |

If the user names a repo not in this list, run `gh search repos --owner alchemyplatform <keyword>` and confirm before forking.

## Defaults that hold across the org

- Default branch is **`main`** (verify with `gh repo view <owner>/<repo> --json defaultBranchRef --jq .defaultBranchRef.name` rather than hard-coding it — some Solidity repos use `develop`).
- Branch naming: `<initials>/<feature-name>` (kebab-case description). This is documented in `alchemyplatform/docs/CONTRIBUTING.md` and is the convention you should follow on any Alchemy repo absent a different rule.
- Package manager is almost always **pnpm** for JS/TS repos. Node 22.x. Honor `.tool-versions` (asdf/mise) when present.
- Husky + lint-staged on commit — pre-commit hooks will run lint and formatting. **Never bypass with `--no-verify`** (per global rules); fix the issue and re-stage.
- CODEOWNERS routes reviews automatically — you don't need to request reviewers manually.
- Alchemy employees can push branches directly without forking (they have team access). External contributors must fork. If `gh api user --jq .login` returns an Alchemy team member, you can skip step 2 (the fork step) — but when in doubt, fork.

## Repo-specific overrides

### `alchemyplatform/docs` — content-only repo, special rules

This is the most common contribution target (typo fixes, new tutorials, API doc updates). Important deviations from the generic flow:

**Step 5 — install:**
```bash
pnpm install
```
`packageManager` is pinned to `pnpm@10.9.0`. Node 22.x.

**Step 7 — making changes:**
- Content lives in `content/<tab>/` as `.mdx` files (e.g. `content/api-reference/`, `content/tutorials/`, `content/wallets/`, `content/admin-api/`, `content/changelog/`).
- If you add, remove, or move a page, you **must** update `content/docs.yml` (the navigation manifest). Forgetting this is the #1 reason docs PRs get review pushback.
- **Do NOT edit `content/api-specs/`** — it's gitignored and regenerated from `src/openapi/` and `src/openrpc/` via `pnpm run generate` (or `generate:rest` / `generate:rpc` for one side only).
- **Do NOT commit images.** Assets must be hosted on Cloudinary (`https://alchemyapi-res.cloudinary.com/...`). External contributors must request the Alchemy team to upload images — flag this to the user immediately if their change involves screenshots or diagrams.
- Account Kit SDK reference content is **not** edited here — it lives in `alchemyplatform/aa-sdk` and is auto-generated. If the user wants to fix an SDK reference page, redirect them to `aa-sdk`.
- Smart Wallets has its own contributing guide at `content/wallets/README.md` — read it if the change is under `content/wallets/`.

**Step 8 — quality checks (run all of these before committing):**
```bash
pnpm run lint           # ESLint + Remark prose lint
pnpm run validate       # REST + RPC OpenAPI validation
pnpm run lint:broken-links   # lychee link checker (needs .env)
```
TypeScript check (`tsc --noEmit`) is also part of the lint pipeline. Prettier formatting is enforced via lint-staged on commit.

**Local preview:** `pnpm preview` exists but requires Upstash Redis + Algolia credentials in `.env`. External contributors **typically don't run it** — instead, they rely on the **PR preview link** that's auto-generated on each PR. Don't try to set up local preview unless the user has the credentials; just ship the PR and check the preview URL in the PR comments.

**Step 11 — PR template:** Use `.github/pull_request_template.md` (lowercase filename). The template asks for:
- Description
- Related Issues (link Asana task or GitHub issue if any)
- Changes Made
- Testing checklist with three boxes: "tested locally", "ran validation scripts (`pnpm run validate`)", "documentation builds correctly"

For external contributors who can't run `pnpm preview`, check "documentation builds correctly" only after the PR preview link comes back green.

### `alchemyplatform/aa-sdk` — Account Kit SDK monorepo

- pnpm workspaces. Most package-level commands are run from the root via `pnpm -F <package>`.
- TypeDoc generates the public SDK reference, which feeds into `alchemyplatform/docs`. If you rename or remove a public symbol, you're affecting the docs site indirectly — call this out in the PR description.
- Tests use Vitest. Run `pnpm test` from the root, or scope to a package.

### Solidity repos (`modular-account`, `light-account`)

- Foundry-based. Step 5 is `forge install` + `forge build`, not `pnpm install`.
- Step 8: `forge fmt --check` and `forge test`. Some repos enforce `slither` checks.
- Default branch may be `develop`, not `main`. Verify before pushing.

### `rundler` (Rust)

- Step 5: `cargo build`.
- Step 8: `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo test`.

## Things to surface to the user proactively

When the target is an Alchemy repo, mention these *before* the user invests time in changes:

1. **Image changes on docs**: "External contributors can't commit images directly — Alchemy hosts them on Cloudinary. If your change needs an image, expect to coordinate with the team."
2. **SDK reference edits**: "Account Kit reference docs are auto-generated from `aa-sdk`, not edited in `docs`. Want me to switch the target repo?"
3. **Generated specs**: "I won't touch `content/api-specs/` — those regenerate from the OpenAPI sources. If your change is to an API spec, I'll edit `src/openapi/` or `src/openrpc/` and run `pnpm run generate` for you."
4. **Local preview not required**: "PR preview link will render your change once you push — no need to run a dev server locally."
