# Hack on ytm.pw

A Theos tweak (Objective-C + Logos) injected into your own decrypted
YouTube Music 9.34 IPA. Built and pinned against **YTM 9.34** -- the mod
hooks YTM's own classes, which move between releases, so another version
may build and then break.

Original work. The look is inspired by Liquid Glass redesigns; no code is
taken from other projects. Apple's own `UIGlassEffect` (iOS 26+) does the
drawing, reached only through runtime lookup so the tweak links on older
SDKs and idles on older OS versions.

## Two looks

`YTMGlassRedesignedUI()` picks one look, read at launch:

- **Native**: YTM's own screens, untouched. Below iOS 26 this is the only
  look: the switch becomes informational and the tweak idles.
- **Redesigned**: the glass look. Floating glass pivot bar, glass player
  chrome, Apple-Music-style lyrics page. Needs iOS 26.

Switches live under the `YTMGlass` defaults key (`redesignedUI` defaults
ON) and need a restart -- they are read at launch.

## Where code goes (`tweak/Sources/`)

| Layer | What | Gate |
|---|---|---|
| `Core/` | mode, prefs, glass material, logging | none |
| `Headers/` | proven YTM class stubs | none |
| `Shared/` | behaviour both looks share | none |
| `Native/` | YTM's screens lightly tweaked | `if (!YTMGlassRedesignedUI()) return;` inverted: run only in native |
| `Redesigned/` | the glass look | `if (!YTMGlassRedesignedUI()) return;` |
| `App/` | settings page + entry points | none |

Rules:

- Imports run one way: `Core <- Shared <- Native | Redesigned <- App`.
  Native and Redesigned never import each other.
  `scripts/check-layers.sh` fails the build on a violation.
- Prove every hooked class and selector against `trees/recorded/` (real
  screenshot UI dumps) or the 9.34 binary before writing the hook.
- Never `hidden = YES` inside YTM's stack views -- fade with alpha.
- Glass panes outside YTM's navigation stacks pin dark
  (`overrideUserInterfaceStyle`), or they flip light in light mode.
- Device log: `make log` (`[ytmglass]` lines).

## Build it

No IPA is distributed. Bring a decrypted **YTM 9.34** IPA.

- Every push compiles the tweak on Actions (the `tweak` job uploads the
  `.deb`), so breakage shows up without a device.
- Hosted IPA: Actions -> "Build" -> "Run workflow", paste a direct link
  to the decrypted `.ipa` as `ipa_url`. The link is masked in logs, the
  unsigned IPA stays in your fork as an artifact.
- Mac: Theos in `~/theos`, decrypted IPA in `ipa/`, then `make release`.
