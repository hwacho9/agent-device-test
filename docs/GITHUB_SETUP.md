# GitHub repository setup

- Repository URL: `https://github.com/hwacho9/agent-device-test`
- Origin: `https://github.com/hwacho9/agent-device-test.git`
- Visibility: public (verified without credentials; existing setting preserved)
- Base branch: `master`
- Feature branch: `feat/ci-pr-evidence`
- Intended PR title: `feat: add CI and PR evidence for agent-device E2E`

The origin already existed and was preserved. Never delete it, rewrite history, or
force-push this work.

Native attachment support for local publication requires GitHub CLI 2.99.0 or
newer. Local publication uses the credential already stored by `gh auth login`:

```bash
gh auth login -h github.com
gh auth status
gh --version
git push -u origin feat/ci-pr-evidence
gh pr create --draft --base master \
  --title "feat: add CI and PR evidence for agent-device E2E" \
  --body-file docs/CI_PR_DESCRIPTION.md
gh pr checks --watch
```

No repository secret is required for CI media publication. The publisher uses the
ephemeral `github.token` to create a run-specific evidence prerelease and upload its
PNG/MP4 assets. After publishing the marker comment it attempts to delete older
evidence releases and tags for the same PR. The built-in token cannot create native
`user-attachments` media; a local invocation of `publish-pr-evidence.sh` can create
those with the OAuth credential already held by GitHub CLI 2.99 or newer.

After authentication, confirm the repository visibility and Actions policy with
`gh repo view` before pushing. Do not merge the draft PR as part of this workflow.
