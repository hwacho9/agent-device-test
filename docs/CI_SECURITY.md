# CI security policy

The workflow uses `pull_request`, never `pull_request_target`. Its default token is
`contents: read`. Android and iOS jobs do not receive write scopes or secrets. The
PR evidence job declares only `contents: read`, `issues: write`, and
`pull-requests: write`, and its job-level condition requires a same-repository PR.
Fork PRs therefore run build/test and artifact upload only.

Actions use explicit released versions, and agent-device is installed with
`npm ci` from `package-lock.json` at 0.20.10. CI does not use `latest`, production
credentials, real accounts, or tokens written to disk or logs.

Evidence collection is allowlisted to JSON, PNG, MP4, bounded logs, and test XML.
It rejects HTML and APK files. `.app`, DerivedData, complete build directories,
local-report HTML, and secrets are not uploaded. Visual baseline sources remain
tracked; generated current/diff/runtime outputs remain ignored. Copied log files
replace the workspace and home directory prefixes with `$REPO` and `$HOME` without
modifying the original local logs.

Comment updates require both the workflow condition and a runtime comparison of
the PR head repository. The publisher only updates a marker comment written by the
current authenticated identity. Publishing, attachment, or artifact failures stay
separate from test statuses.
