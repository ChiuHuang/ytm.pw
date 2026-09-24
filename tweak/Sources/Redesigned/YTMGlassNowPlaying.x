#import "../Core/YTMGlassCore.h"
#import "../Core/YTMGlassMaterial.h"
#import "../Headers/YTMGlassHeaders.h"

// TODO(device): glass now-playing bar + fullscreen player + lyrics.
// Planned approach, proven per screen against trees/recorded/ first:
//   1. Mini player (YTMMiniPlayerViewController view): floating glass pill
//      with artwork thumb, title, play/pause -- same tag-once pattern as
//      YTMGlassPivotBar.x.
//   2. Full player (YTMNowPlayingViewController): ambient artwork blur
//      stays, transport becomes glass circle buttons, progress gets the
//      glass knob treatment.
//   3. Lyrics: reuse the Apple-Music-style renderer approach (word-run
//      coloring on the native timing) inside a glass sheet.
// None of the three hooks exist yet; this file only holds the gate so the
// target compiles and the native player is untouched until each screen is
// proven on-device.

%ctor {
    if (!YTMGlassRedesignedUI()) return;
    YTMGlassLog(@"now-playing redesign: pending device trees (stub)");
}
