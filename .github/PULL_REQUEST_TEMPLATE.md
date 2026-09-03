## What this changes

<!-- One or two sentences. What is different after this PR? -->

## Why

<!-- What problem does it solve? Link an issue if there is one. -->

## Checklist

- [ ] `./scripts/validate-skills.sh` passes
- [ ] `./tests/test-safety.sh` passes
- [ ] Edited `skills/_shared/erc8004/lib.sh` (not a vendored copy) and ran `./scripts/sync-shared.sh`, if shared code changed
- [ ] Bumped the skill's `version` in frontmatter and updated `CHANGELOG.md`
- [ ] New skills are listed in `README.md`
- [ ] No keys, mnemonics, or environment files in the diff

## If this touches an on-chain script

- [ ] Still defaults to a testnet
- [ ] Mainnet still requires an explicit confirmation
- [ ] Success is only reported after a verified receipt
- [ ] Added a case to `tests/test-safety.sh` for any new guarantee
