# E2E acceptance

Given a fresh logged-out demo session, enter demo@example.com / demo1234, submit,
verify home.title, open home.profile, verify profile.title and profile.name,
enable profile.reminder, save, and verify profile.saved. Assert the reminder's
checked state and absence of login.error. A text match alone is insufficient.

## Agent exploration
The operator/agent reads the current snapshot, states what it observed and why
it chose its action, acts on a current reference or stable selector, then reads
a new snapshot after navigation. Never reuse references from a previous screen.
Save only the actually successful session as a platform-specific .ad file.

## Replay
Review the recorded script and prefer stable accessibility identifiers. Reset
before each run. No automatic repair, selector rewriting or baseline updates in
validation. Each platform must succeed twice consecutively with identical
acceptance criteria. Keep failures and their evidence; do not overwrite them
with a later success.

## Presentation output
[AI OBSERVE] / [AI ACT] / [AI VERIFY] explain actual observations and actions.
[AI EVIDENCE] gives real output paths. [DEMO RESULT] is PASS only after all checks.
On failure print [FAILED STEP], [EXPECTED], [ACTUAL], and [EVIDENCE].

The preliminary adb and XCTest smoke checks validate gates C and D. They are
not Agent Passes and do not prove .ad replay support.
