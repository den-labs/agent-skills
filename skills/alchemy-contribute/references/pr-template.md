# Fallback PR template

Use this only if the target repo does not provide its own `.github/PULL_REQUEST_TEMPLATE.md`. Always prefer the repo's template.

```markdown
## Summary

<1–3 bullets describing what changed and why. Lead with the why.>

## Motivation

<Optional: link to issue, discussion, or context. Skip if the summary is self-explanatory.>

## Changes

- <bullet per logical change>
- <keep to atomic units — one PR per concern>

## Test plan

- [ ] <command or steps you ran to verify locally>
- [ ] <edge case covered>
- [ ] CI passes

## Screenshots / recordings

<Only if the change is user-visible. Otherwise omit.>

## Checklist

- [ ] I read CONTRIBUTING.md
- [ ] Lint and tests pass locally
- [ ] Commits follow the repo's convention
- [ ] DCO sign-off / signed commits if required
```

## Tips for the title

- Under 70 characters.
- Imperative mood: "Add X", not "Added X" or "Adds X".
- Match the repo's commit-message convention. If they use Conventional Commits in titles (`feat:`, `fix:`, `docs:`), do the same here.
- Include a scope when it helps reviewers route the PR (`feat(aa-sdk): ...`).
