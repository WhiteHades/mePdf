# Issue tracker: GitHub

Issues and product specifications for this repository live in GitHub Issues.
Use the `gh` CLI and infer the repository from `origin`.

## Conventions

- Create: `gh issue create --title "..." --body-file <file>`.
- Read: `gh issue view <number> --comments`.
- List: `gh issue list --state open --json number,title,body,labels,comments`.
- Comment: `gh issue comment <number> --body "..."`.
- Label: `gh issue edit <number> --add-label "..."`.
- Close: `gh issue close <number> --comment "..."`.

Pull requests are not a triage request surface.

## Wayfinding operations

- The roadmap is one issue labelled `wayfinder:map`.
- Work items are child issues where GitHub sub-issues are available. Otherwise,
  the roadmap uses a task list and each child says `Part of #<map>`.
- Blocking relationships use GitHub issue dependencies where available.
  Otherwise, the child body starts with `Blocked by: #<number>`.
- The next work item is the first open, unassigned child with no open blocker.
- Claim work with `gh issue edit <number> --add-assignee @me`.
- Resolve work by commenting with verification evidence, then closing the issue.
