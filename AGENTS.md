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
- v0.2: glass mini player (tag 9002, `YTMGlassMiniPlayer.x`), player
  transport glass + scrubber rounding (`YTMGlassPlayer.x`, tag 9003),
  full lyrics sheet with fetch/highlight/seek (`YTMGlassLyrics.x`, pill
  tag 9004, endpoint prefs `lyricsEndpoint`/`lyricsLang`), settings page
  via avatar account-menu hook (`App/YTMGlassSettings.x`), playback tap
  (`Shared/YTMGlassPlayback.x`), lyrics service (`Shared/`).
  CI injects with cyan (`-i decrypted -o out -f deb`).
- v0.4: push compiles the tweak on Actions (`tweak` job: theos +
  `gmake package`, deb artifact); IPA job is manual with `ipa_url`.
  Shared ad skip (`Shared/YTMGlassAdSkip.x`, `noAds` default YES +
  settings switch) covering InnerTube context, spam signals and player
  response monetization. Lyrics stack confirmed present: fetch + parse
  (`Shared/YTMGlassLyricsService`), highlight/seek sheet
  (`Redesigned/YTMGlassLyrics.x`), endpoint/lang prefs.
- v0.3 (from 16-03 device dumps): glass search field
  (`YTMGlassSearch.x`, tag 9006, one-time bg thin), browse declutter
  opt-in (`YTMGlassBrowse.x`, `reduceHomeArt` pref default OFF +
  settings switch). Library rows untouched (cell internals unproven).

## Open / pending
- Device test every screen (all hooks are additive + try/caught, but the
  pill position, card insets and scrubber rounding are unverified).
- Confirm cyan flags against its README on the hosted runner.
- Home/Search/Library/queue restyle (not started; needs recorded trees
  of those screens first).
