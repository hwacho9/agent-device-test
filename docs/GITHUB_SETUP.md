# GitHub repository setup

- Repository URL: `https://github.com/hwacho9/agent-device-test`
- Origin: `https://github.com/hwacho9/agent-device-test.git`
- Visibility: public (verified without credentials; existing setting preserved)
- Base branch: `master`
- Feature branch: `feat/ci-pr-evidence`
- Intended PR title: `feat: add CI and PR evidence for agent-device E2E`

The origin already existed and was preserved. Never delete it, rewrite history, or
force-push this work.

The saved `hwacho9` GitHub CLI credential was invalid when this feature was
implemented. Reauthenticate interactively; scripts never attempt login or store a
token:

```bash
gh auth login -h github.com
gh auth status
git push -u origin feat/ci-pr-evidence
gh pr create --draft --base master \
  --title "feat: add CI and PR evidence for agent-device E2E" \
  --body-file docs/CI_PR_DESCRIPTION.md
gh pr checks --watch
```

After authentication, confirm the repository visibility and Actions policy with
`gh repo view` before pushing. Do not merge the draft PR as part of this workflow.
