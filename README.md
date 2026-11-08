# PullBar

<p align="center">
  <a href="https://github.com/menubar-apps/PullBar"><img src="https://img.shields.io/badge/-PullBar-black?logo=github&style=flat"></a>
  <img alt="GitHub all releases" src="https://img.shields.io/github/downloads/menubar-apps/pullbar/total">
  <img alt="GitHub top language" src="https://img.shields.io/github/languages/top/menubar-apps/pullbar">
  <img alt="GitHub release (with filter)" src="https://img.shields.io/github/v/release/menubar-apps/pullbar">
</p>
  
<p align="center">
<a href="https://apps.apple.com/ca/app/pullbar/id1601913905?mt=12&amp;itsct=apps_box_badge&amp;itscg=30200" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;" data-ol-has-click-handler="&h=42ae61fed6985dfa41e1aec1722a55b5"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-mac-app-store/white/en-us?size=250x83&amp;releaseDate=1659916800" alt="Download on the Mac App Store" style="border-radius: 13px; width: 250px; height: 83px;"></a>
</p>

Native MacOS menubar application to show GitHub Pull Requests in your menu bar! Keep track of created, assigned and review requested Pull Requests:

<p align="center">
  <img width="708" alt="Screen Shot 2022-07-17 at 9 06 36 PM" src="https://user-images.githubusercontent.com/9363150/179432557-f3db115e-fe9d-4f91-ac7c-0d85ce3f9e43.png">
</p>

If you liked the PullBar, check the [PullBar Pro](https://menubar-apps.github.io/#pullbar-pro) - an improved version with more features!

# Features

 - shows pull requests grouped into customizable categories (assigned, created, review requested or any GitHub search query);
 - for each pull request shows title, number, project, author, number of approvals, number of added/deleted lines and how long ago this PR was created;
 - hold Option while the menu is open, then click a pull request to copy its URL;
 - show check suites information.

# Action dashboard (this fork)

Enabled by default in Preferences → General. The menu shows **To review** and
**My PRs**, with actionable PRs first. Disable **Action dashboard** to use the
existing custom categories and single category counter again; saved categories
are preserved.

- **Red badge:** open PRs requesting your review (excluding your own PRs).
- **Orange badge:** your open PRs with failing CI, requested changes, unresolved
  review discussions, new review comments, conflicts, or ready to merge.
- Each PR counts once in its section, even when it has several action reasons.
  Zero badges are hidden; hover over the icon for the meaning of both counts.
- Each row shows current approvals, CI state and action reasons. Diff line counts
  are hidden. Click a PR to open it; Option-click still copies its URL.
- **Ready to merge** requires two distinct current approving reviewers, at least
  one successful CI check, completed successful/neutral/skipped remaining checks,
  no unresolved discussions or requested changes, a non-draft PR, and GitHub's
  `MERGEABLE` / `CLEAN` state with no outstanding review requirement. This is an
  indication based on the last refresh, not an automatic merge or a guarantee
  that every possible merge permission is satisfied.
- Review comments use GitHub's PR-level unread flag and the local time you last
  opened that PR from PullBar. GitHub does not expose an individual read flag per
  review here. Opening a PR acknowledges existing comments locally; unresolved
  threads and change requests remain actionable until addressed on GitHub.
- CI is fetched regardless of the old build-display setting. Missing, queued,
  unknown, or exclusively skipped checks never imply successful tests. PullBar
  reports GitHub checks; it cannot infer whether a workflow actually contains tests.
- Searches are paginated (GitHub's 1,000-result maximum is reported as an error).
  Review decisions, discussion threads and CI details are limited to 100 each;
  incomplete details are labelled and cannot produce a ready-to-merge verdict.
  The latest 100 comment reviews are inspected for unread feedback.
- Refresh errors retain the previous list with a warning and replace counters
  with `!`, so stale data cannot look like an empty action queue.

Run the standalone action-rule checks without accessing GitHub or the keychain:

```sh
swiftc pullBar/GitHub/GitHubDtos.swift Tests/ActionRulesTests.swift -o /tmp/pullbar-action-tests
/tmp/pullbar-action-tests
```

# Installation

There are 3 ways of installing the application: 

 - [Mac App Store](https://apps.apple.com/ca/app/pullbar/id1601913905)
 - Homebrew:
    ```shell
    brew tap menubar-apps/menubar-apps
    brew install pullbar
    ```
 - [Download](https://github.com/menubar-apps/PullBar/releases) from github releases

Then [generate](https://github.com/settings/tokens/new?scopes=repo) a github access token (you'll need to have a **repo** scope selected) and paste it in the application preferences:



<p align="center">
  <img width="731" alt="Screenshot 2023-07-09 at 11 08 51 AM" src="https://github.com/menubar-apps/PullBar/assets/9363150/7ee9f73b-ef6e-4a14-8af9-53404f0133c5">
</p>
