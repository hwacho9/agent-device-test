The existing local demo had no shared machine-readable status, offline dashboard,
or remote CI evidence. This change records each platform pipeline from real process
exit codes, renders the results locally, runs the existing Android/iOS validation
and deterministic replay in GitHub Actions, and updates one PR summary comment.

The Android job validates common logic and Compose screenshots, builds and freshly
installs the APK, replays the reviewed Android scenario, asserts the final state,
and records evidence. The iOS job validates snapshots, builds the final `.app` with
the embedded KMP framework, preserves boot → install → runner preparation order,
then replays and records the reviewed iOS scenario.

Local usage:

```bash
bash scripts/run-platform-ci.sh android
bash scripts/run-platform-ci.sh ios
./scripts/generate-local-report.sh
./scripts/serve-local-report.sh
```

The HTML dashboard is local-only: it is ignored by Git, never generated in CI,
never uploaded as an Actions artifact, and never attached to a PR. The two
five-day workflow artifacts contain JSON, representative/full PNG evidence, MP4,
bounded logs, and test results; they exclude HTML, APK, `.app`, DerivedData, and
complete xcresult bundles.

For same-repository PRs, the evidence job uploads each existing final PNG and MP4
to a run-specific GitHub prerelease and embeds the PNG previews and MP4 links in one
stable-marker report. After publishing the marker, it attempts to remove older
evidence releases and tags for that PR. It uses an ephemeral repository token and
no stored user credential. Fork PRs get read-only build/test and artifact upload
only. A publishing failure falls back to Actions artifact links and never changes
the test verdict.

Known limitations: Android emulator and iOS runner behavior still depend on hosted
runner availability. Snapshot baselines stay pinned and are never updated in CI.
The project-local agent-device 0.20.10 dependency retains the npm audit advisories
already documented in `docs/TROUBLESHOOTING.md`.
