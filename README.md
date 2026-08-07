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

 - shows assigned, created and/or review requested pull requests;
 - for each pull request shows title, number, project, author, number of approvals, number of added/deleted lines and how long ago this PR was created;
 - show check suites information.

# Installation

There are 3 ways of installing the application: 

 - [Mac App Store](https://apps.apple.com/ca/app/pullbar/id1601913905)
 - Homebrew:
    ```shell
    brew tap menubar-apps/menubar-apps
    brew install pullbar
    ```
 - [Download](https://github.com/menubar-apps/PullBar/releases) from github releases

Then authenticate GitHub CLI on your Mac:

```shell
gh auth login --web
```

PullBar uses your local `gh` login session to query PRs.

## Authentication model (current)

PullBar now uses your local GitHub CLI session (`gh auth`) instead of storing a GitHub PAT in app preferences.

- Run `gh auth login --web` once.
- Verify with `gh auth status`.
- In PullBar preferences, set your GitHub username (or leave blank and PullBar will resolve it from `gh api /user`).

## Local unsigned build + install (for this Mac only)

If you only want to run PullBar locally, you can build without Apple development signing:

```shell
cd /Users/bkane/Git-LI-GH/PullBar

xcodebuild \
  -project pullBar.xcodeproj \
  -scheme pullBar \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  CODE_SIGN_ENTITLEMENTS="" \
  clean build
```

Install and launch:

```shell
cp -R build/Build/Products/Debug/pullBar.app /Applications/pullBar.app
open /Applications/pullBar.app
```

If macOS blocks first launch, right-click the app in Finder and choose **Open**.


<p align="center">
  <img width="731" alt="Screenshot 2023-07-09 at 11 08 51 AM" src="https://github.com/menubar-apps/PullBar/assets/9363150/7ee9f73b-ef6e-4a14-8af9-53404f0133c5">
</p>
