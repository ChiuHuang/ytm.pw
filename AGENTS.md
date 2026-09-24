# AGENTS.md — ytm.pw session handoff

YouTube Music in glass: a Theos/Logos tweak (ObjC) that restyles YTM 9.34
with Liquid Glass. All code here is original; the style reference is
Apple's own iOS 26 material, reached via runtime lookup only.

## How we talk
- Short, concise, facts-first. No emojis anywhere.
- Reference code as `file_path:line_number`.
- Verify through execution when possible; commit + push when done.

## Environment traps (Windows host, PowerShell 5.1)
- No `&&` chaining, no `head`/`grep`/`cat`. Use `;`, `Select-String`,
  `Get-Content`. The `bash` tool runs PowerShell, not bash.
- `gh` CLI is authenticated as ChiuHuang. Repo: ChiuHuang/ytm.pw.
- PowerShell `>` redirect writes UTF-16 -- never redirect command output
  into source files; write files with the Write tool.
- New files: UTF-8 without BOM, LF only.
- `check-layers.sh` is sh (runs on Mac/CI), keep it POSIX.

## Architecture
- Layers: `Core <- Shared <- Native | Redesigned <- App`, `Headers/`
  anywhere. Enforced by `scripts/check-layers.sh` before every build.
- Gates: `YTMGlassAvailable()` (iOS 26 runtime class check),
  `YTMGlassRedesignedUI()` (available + stored switch, default ON).
- Glass factory: `YTMGlassEffectView(style, radius, interactive)` in
  Core -- real `UIGlassEffect` on 26+, system-material blur below.
- Prefs key: `YTMGlass` (`redesignedUI`, read at launch).
- Pinned YTM: 9.34. Bundle filter: `com.google.ios.youtubemusic`.
- Proven trees: `trees/recorded/UI_DUMP_*.txt` (real device dumps:
  YTMPivotBarViewController, YTMWatchViewController,
  YTMNowPlayingViewController, YTMMiniPlayerViewController,
  YTMPlayerViewController, YTMBrowseViewController...).
- First slice: glass pivot bar (`Redesigned/YTMGlassPivotBar.x`, tag
  9001). Player/lyrics/settings-host are stubs with TODOs.

## Open / pending
- Confirm YTM 9.34 settings host class from a recorded tree, then wire
  `YTMGlassPresentSettingsFromVC`.
- Device test the pivot bar slice (alpha-fade of YTM bg slabs unverified).
- Glass now-playing + player + lyrics screens (stubs).
- Hosted auto-compile inject step (workflow currently uploads the .deb;
  the cyan/azule inject command is a TODO for the hosted runner).
