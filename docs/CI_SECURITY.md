# CI security policy

The workflow uses `pull_request`, never `pull_request_target`. Its default token is
`contents: read`. Android and iOS jobs do not receive write scopes or secrets. The
PR evidence job alone declares `contents: write`, `issues: write`, and
`pull-requests: write`; its job-level condition requires a same-repository PR.
`contents: write` is used only to create the run-specific evidence prerelease and
tag, upload its four allowlisted assets, and remove older evidence releases and
tags for the same PR. Fork PRs run build/test and artifact upload only.

CI uses the ephemeral repository-scoped `github.token`. It does not store a user
OAuth token or PAT. Native `gh pr comment --attach` rejects the Actions installation
token, so CI links official GitHub Release assets from the PR comment instead. Each
run-specific release tag is created from the default branch, while the comment
records the tested PR SHA and workflow run. Cleanup of older matching releases is
best effort and runs only after the new marker has been published.

Actions use explicit released versions, and agent-device is installed with
`npm ci` from `package-lock.json` at 0.20.10. CI does not use `latest`, production
application credentials, real demo accounts, or tokens written to disk or logs.

Evidence collection is allowlisted to JSON, PNG, MP4, bounded logs, and test XML.
It rejects HTML and APK files. `.app`, DerivedData, complete build directories,
local-report HTML, and secrets are not uploaded. Visual baseline sources remain
tracked; generated current/diff/runtime outputs remain ignored. Copied log files
replace the workspace and home directory prefixes with `$REPO` and `$HOME` without
modifying the original local logs.

Comment updates and release uploads require both the workflow condition and a
runtime comparison of the PR head repository. The publisher only updates a marker
comment written by the current authenticated identity. Publishing or artifact
failures stay separate from test statuses.
