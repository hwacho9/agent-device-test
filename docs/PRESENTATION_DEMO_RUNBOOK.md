# Presentation demo

Generate and check the offline evidence dashboard before presenting:

```bash
./scripts/generate-local-report.sh
./scripts/serve-local-report.sh
```

Open `http://127.0.0.1:8080` and confirm both JSON timestamps and embedded backup
videos. This HTML remains local and is never used as PR or CI evidence.

## Before the event
1. Run `bash scripts/run-all-local.sh` and review each platform result separately.
2. Run `bash scripts/record-android-clean.sh` and `bash scripts/record-ios-clean.sh`.
3. Play the clean MP4s. Verify inputs, login, navigation, reminder and Saved.
4. Keep the tested versions, runtimes, reference images and .ad files fixed.
5. Hide notifications/private windows and prepare OBS manually (see OBS runbook).

## Live sequence
Explain commonMain, native Compose/SwiftUI screens, and the shared fixture.
Show one common test and the two Visual reports. Show a deliberately explicit
reference command vs validation; never update references just to get green.

Choose one platform for the live Agent Pass. In Codex, ask it to run the matching
explore script and continue interactively from snapshots through the acceptance
criteria. The script only initializes exploration; Codex supplies actual decisions.
Show concise AI OBSERVE / ACT / VERIFY output while the device performs actions.
After verified Saved, capture evidence and close the armed session to save its .ad.

Then run the reviewed replay script. Explain that this pass executes a recorded,
reviewed scenario with stable selectors and assertions, without fresh AI decisions.
The runtime wrapper verifies the final JSON snapshot and reports PASS/FAIL with
an evidence directory. Compare the same business result across both platforms.

## Backup and failure
Use artifacts/android/runtime/android-clean-e2e.mp4 or
artifacts/ios/runtime/ios-clean-e2e.mp4 only after checking the generated files.
A failed live run remains FAIL, with its screenshot and log. Disclose that the
backup is prerecorded. Never fabricate evidence or hide a failed acceptance check.

## Timings
First-time downloads/runner compilation are preparation, not part of the live
demo. Prewarm the iOS runner after app installation. Clean recording creates an auditable video-scenario.ad copy containing every original
action/assertion plus short 1.75-second presentation pauses after selected steps.
Readiness still uses element/state waits. The canonical .ad is unchanged, and no
long fixed wait is used to mask a flaky check. The original-speed video remains
in its timestamped run directory.
