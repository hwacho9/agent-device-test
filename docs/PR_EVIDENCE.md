# Pull-request evidence

The `pr-evidence` job runs after both platform jobs, even if either failed, but
only for a pull request whose head repository equals the current repository. It
downloads both artifacts, parses JSON without guessing missing results, and writes
`artifacts/pr/pr-summary.md` with this marker:

```html
<!-- agent-device-mobile-e2e-report -->
```

`publish-pr-evidence.sh` checks authentication and repository identity. In CI it
uploads each existing final PNG and MP4 to the run-specific prerelease tagged
`pr-<number>-mobile-e2e-evidence-<run-id>-attempt-<attempt>`, then updates the
newest bot-owned marker comment. After the marker is published, it attempts to
delete older evidence releases and tags for the same PR. Cleanup failure emits a
warning and preserves the successfully published marker. Repeated pushes do not
accumulate marker comments. The publisher never edits another user's comment or an
unmarked comment.

```bash
./scripts/publish-pr-evidence.sh <PR_NUMBER>
```

The summary reports all six build/visual/E2E statuses, scenario, commit, run URL,
execution time, and which PNG/MP4 files exist. Release PNGs render inline and MP4s
have open/download links. A missing file is `NOT GENERATED` and is never replaced
by an empty file. HTML is never generated or published in this job.

CI uses the official Release asset API with the ephemeral `github.token`; it does
not persist a user OAuth token or PAT. Only the publisher job receives
`contents: write`, and it runs only for same-repository PRs. Unique run/attempt tags
give every published image and video a new URL before older matching releases are
cleaned up. If upload fails, the marker summary points to the short-lived workflow
artifacts and only the `pr-evidence` check fails. Build, visual, and E2E results
keep their actual verdicts.

Outside CI, GitHub CLI 2.99+ can use the currently logged-in OAuth user and upload
native PR attachments directly. PNG references are rewritten inline and MP4
references become GitHub video players:

```bash
./scripts/publish-pr-evidence.sh <PR_NUMBER>
```
