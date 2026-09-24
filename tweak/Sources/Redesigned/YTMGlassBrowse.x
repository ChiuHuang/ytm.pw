#import "../Core/YTMGlassCore.h"
#import "../Headers/YTMGlassHeaders.h"

// Browse declutter, strictly opt-in (dump 16-03-31): the Home tab paints a
// large YTLightweightBrowseBackgroundView art header behind the shelves.
// "Reduce home artwork" (default OFF) fades that art so shelves read
// cleaner. Default OFF means zero visual change until the user asks --
// the hook only ever lowers one alpha, never restructures cells.

%hook YTLightweightBrowseBackgroundView

- (void)layoutSubviews {
    %orig;
    if (!YTMGlassRedesignedUI()) return;
    if (!YTMGlassPreference(@"reduceHomeArt", NO)) return;
    @try {
        if (self.alpha > 0.36) self.alpha = 0.35;
    } @catch (NSException *e) {
    }
}

%end
