# OBS recording runbook

OBS installation, permissions and operation are manual. This project never changes them.

- Canvas: 1920×1080, 30 fps.
- Left: Codex terminal, approximately 42% (806 px).
- Right: Simulator/Emulator, approximately 58% (1114 px).
- Terminal: 22–26 px monospace font, dark background, concise AI step output.
- Hide notifications, personal account names, unrelated tabs and private files.
- Select the dedicated demo device and enlarge it without cropping its controls.

## Rehearsal
Build and validate both platforms first. Reset the demo app. Start OBS manually,
then run the platform exploration workflow. Read the OBSERVE / ACT / VERIFY
messages alongside actual device actions. Stop OBS after Saved and PASS appear.

An Agent Pass uses current snapshots to choose the next action. Deterministic
replay executes the reviewed saved `.ad` scenario; it is not a fresh AI decision.
Never present a replay as live exploration.

Clean recording captures only the device and is produced by recording scripts.
OBS captures terminal and device together and is controlled by the presenter.

## Backup paths (expected, only usable after verified generation)
- artifacts/android/runtime/android-clean-e2e.mp4
- artifacts/ios/runtime/ios-clean-e2e.mp4

Before the presentation, play both backup files from beginning to end. Verify
email/password input, login, Home, Profile, reminder enabled and persistent Saved.
If a live run fails, preserve its log and display FAIL; switch to the verified
backup video and disclose that it is a prerecorded successful run.
