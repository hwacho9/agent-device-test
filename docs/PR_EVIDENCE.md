# Pull-request evidence

The `pr-evidence` job runs after both platform jobs, even if either failed, but
only for a pull request whose head repository equals the current repository. It
downloads both artifacts, parses JSON without guessing missing results, and writes
`artifacts/pr/pr-summary.md` with this marker:

```html
<!-- agent-device-mobile-e2e-report -->
```

`publish-pr-evidence.sh` checks authentication and repository identity. It updates
the newest marker comment authored by the current bot/user, or creates one if none
exists. It never edits another user's comment or an unmarked comment, so repeated
pushes do not add a new report each time.

```bash
./scripts/publish-pr-evidence.sh <PR_NUMBER>
```

The summary reports all six build/visual/E2E statuses, scenario, commit, run URL,
execution time, and which PNG/MP4 files exist in the workflow artifacts. HTML is
never generated or published in this job.

GitHub CLI 2.96.0 `gh pr comment --help` has body text/file options but no local
file attachment option. GitHub's supported issue-comment REST API also accepts
comment text, not binary upload. The implementation therefore does not fabricate
an attachment: it records each direct PNG/MP4 attachment as `NOT ATTACHED` and
points reviewers to the short-lived Actions artifacts. Using GitHub's private web
upload endpoints would require unsupported browser credentials and is intentionally
not automated. This publishing limitation does not change E2E status.
