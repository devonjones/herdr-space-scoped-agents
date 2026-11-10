# 006 — Distribution: build from source only

Supersedes [003](003-distribution.md).

## Context

003 chose fetch-or-build: at `herdr plugin install`, download a prebuilt binary
from the GitHub release `v<version>` and verify its SHA-256, falling back to
`go build`. The download URL was hard-coded to the original upstream repository,
so installing this fork still pulled a binary built and published by someone
else. The checksum came from that same release, so it only proved the download
wasn't corrupted, not that it matched this source. On Windows a failed checksum
was caught and logged as a warning, and the binary was installed anyway.

A plugin runs with access to the herdr API socket and every agent pane's
context, so the code that runs has to be the code that was reviewed.

## Decision

- `[[build]]` runs `scripts/build.sh` (unix) or `scripts/build.ps1` (Windows),
  which only run `go build`. No binary is fetched at install time. Go still
  fetches the modules in `go.mod` from the module proxy and checks them against
  `go.sum`, and the scripts set `GOTOOLCHAIN=local` so Go never downloads a
  toolchain.
- Go 1.26+ is a hard requirement for installing; the scripts fail with a clear
  error when it's missing, and Go itself refuses an older version.
- CI runs `build.sh` on Linux and macOS and `build.ps1` on Windows, with
  `HERDR_PLUGIN_ROOT` set as Herdr sets it. It checks the binary reports the
  manifest's version plus the short commit SHA, and that a missing Go fails
  with a clear error, since nothing else exercises the scripts before install.
- The version is stamped as `<manifest version>+<short sha>` (for example
  `0.6.0+892cdd6`) when the plugin root is itself a git checkout, so a box's build can
  be matched to a commit; otherwise it's the manifest version alone.
- Releases are still cut by release-please for versioning and the changelog,
  but no binaries are attached (005's build-and-upload step is removed).
- The Go module path is the bare `herdr-space-scoped-agents`, so the source no
  longer names any hosting account. It's a `main` package, so nothing imports it.

## Rationale / alternatives

- **Keep fetch-or-build, point it at our own releases (rejected):** still runs a
  binary nobody built locally, and the checksum would still come from the same
  place as the binary. It would also need a release pipeline per fork.
- **Download and verify against a checksum committed in the repo (rejected for
  now):** sound, but more machinery than a small plugin needs when `go build`
  takes seconds.
- **Cost:** every user needs Go. The team that uses this already has it.
