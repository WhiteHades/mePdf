# mePdf agent guide

Read `CONTEXT.md` and the relevant ADRs before changing domain behavior.
Keep Kotlin limited to Android lifecycle, storage, accessibility, and UI concerns.
Keep document orchestration and state in the C core behind opaque handles.
Never modify an original document before a separately written replacement has
been reopened and verified.

## Agent skills

### Issue tracker

Work is tracked in GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

The repository uses the default Matt Pocock triage vocabulary. See
`docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repository. See `docs/agents/domain.md`.
