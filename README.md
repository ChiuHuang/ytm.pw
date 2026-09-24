# ytm.pw

YouTube Music, in glass.

A no-jailbreak Theos tweak that restyles YouTube Music for iOS in Liquid
Glass, injected into your own decrypted IPA and signed with your own
certificate. Original implementation built on Apple's iOS 26
`UIGlassEffect` -- no code taken from any other project.

Built and pinned against **YouTube Music 9.34** -- use that version's IPA.
The tweak hooks YTM's own classes, which change between releases, so
another version may build and then break.

## The looks

**iOS 26+**

- Redesigned: floating glass pivot bar, glass player chrome,
  Apple-Music-style lyrics page.
- Native: YTM's own screens, untouched.

**Below iOS 26**

The tweak idles and YTM runs as stock -- Liquid Glass is drawn by the
system and no older OS can be given it.

## Build it

No IPA is distributed. Bring a decrypted **YTM 9.34** IPA.

- Hosted: Actions -> "Build IPA from your own YTM IPA", paste a direct
  link to the decrypted `.ipa`. The artifact stays in your fork.
- Mac: Theos in `~/theos`, decrypted IPA in `ipa/`, then `make release`.
  Sign the result with SideStore, Feather or any certificate signer.

See `docs/tweaks.md` to hack on it.

## License

MIT. Not affiliated with YouTube or Google.
