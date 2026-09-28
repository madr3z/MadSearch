# Contributing

These guidelines apply to [madrez's personal fork of Search](https://github.com/madr3z/MadSearch), based on [Office Commun's original project](https://github.com/driceroland/Search). Contributions are welcome; keep changes small and focused.

## Before writing code

For anything beyond a small fix, [open an issue in this fork](https://github.com/madr3z/MadSearch/issues) first describing what you want to change and why. It saves a rewritten pull request later if the direction doesn't fit.

## New features: off until someone turns them on

Search stays small by default. Anything new that changes how the browser
looks or behaves — spaces, groups, a visible address bar, a new panel — is:

- **minimal**: the smallest version that does the job, in the app's own quiet style;
- **optional, and off by default**: someone who never asks for it never sees it;
- **findable**: a switch in Settings, and a mention in the welcome screens if it's a big one, so people know it's there to turn on.

Fixes and things every browser is expected to do (Tab moving between a form's fields, ⌘1–⌘9) don't need a switch. Before building a bigger feature, look at how other browsers do it and read what people asked for on its issue; [ROADMAP.md](ROADMAP.md) lists where each request came from.

## Where things are tracked

- [This fork's issues](https://github.com/madr3z/MadSearch/issues): ideas, bug reports and proposed changes for my take on Search.
- [ROADMAP.md](ROADMAP.md): the inherited upstream roadmap, kept as a reference. The upstream project's current plans are at [officecommun.com/search/roadmap](https://officecommun.com/search/roadmap).
- [CHANGELOG.md](CHANGELOG.md): fork additions alongside the inherited upstream history. A pull request that fixes or adds something also adds its line under **Unreleased** and identifies it as a fork change.

## What tends to get merged

- **Small, focused changes.** One thing per pull request, easy to read start to finish.
- **No new dependencies.** The whole point of this app is staying small; a browser this size doesn't need a package for something Foundation or WebKit already does.
- **Matches the existing style.** Comments here explain *why*, not *what the next line does* — read a couple of existing files before adding a new one. No force-unwraps on anything that can plausibly fail (a network response, a file read, a keychain lookup).
- **Builds clean.** `swift build` with zero warnings you introduced.

## What doesn't

- Rewrites of things that already work, for style reasons alone.
- Anything that phones home, adds analytics, or changes what leaves the app over the network — see the [privacy page](https://officecommun.com/search/privacy) for what that boundary currently is.
- Vendoring Chromium or any other engine. This is a WebKit browser on purpose.
- A real key or token anywhere: in code, a test, an issue, a pull request or a pasted log. Tests use keys that are obviously made up. `gitleaks git --pre-commit --staged` with the repo's `.gitleaks.toml` catches most of them before a commit; it is worth running as a pre-commit hook.

## Review

Pull requests to this fork are reviewed by madrez. Explain what changed and why, and keep each pull request focused on one thing.

## Reporting a bug

[Open an issue in this fork](https://github.com/madr3z/MadSearch/issues) with: what you did, what you expected, what happened instead, and your macOS version. A crash log, if there is one, lives at `~/Library/Application Support/Search/crash.log` — it only ever stays on your Mac unless you paste it into the issue yourself.
