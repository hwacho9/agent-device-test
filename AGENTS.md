# AgentDeviceE2EDemo
- Execute real commands before claiming success. Report unexecuted checks as NOT RUN.
- Do not guess paths, Gradle tasks, schemes, identifiers, or agent-device options.
- Follow gates A, B, C, D, visual tests, then agent-device integration. Stop on gate failure and diagnose it.
- Never update visual baselines during validation or delete assertions to pass tests.
- Prefer bounded state-based waits. Do not use production credentials.
- Verify final Android APK and iOS .app; framework compilation alone is not iOS app success.
- Keep failure screenshots, logs, and paths. Never fabricate evidence.
- Keep shared business logic in commonMain; Compose Android UI and SwiftUI iOS UI are separate.
- Use direct Xcode integration only; no CocoaPods.
- Do not install or operate OBS.
- Produce platform JSON with `bash scripts/run-platform-ci.sh android|ios`; only
  actual process exit codes and assertions may set PASS.
- Generate local HTML with `./scripts/generate-local-report.sh`; never commit,
  upload, publish, or attach `artifacts/local-report`.
- CI validates visual baselines and must never run either baseline update mode.
- CI jobs are independent, always collect bounded evidence, and keep HTML and app
  binaries out of workflow artifacts.
- PR evidence may update only the current bot/user marker comment on a
  same-repository PR. CI uploads allowlisted PNG/MP4 in a run-specific GitHub
  prerelease and attempts to remove older evidence releases for that PR after the
  marker is published; local OAuth publication may use GitHub CLI 2.99+ direct
  attachments. Fork PRs receive no write token, secret, comment, or media upload
  operation.
- Do not replace stable accessibility selectors with ephemeral `@eN` references.
- Artifact upload or report publication never changes a failed test to PASS.
