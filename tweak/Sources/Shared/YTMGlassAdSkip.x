#import "../Core/YTMGlassCore.h"

// Shared ad skip: video + banner ad plumbing is neutered at the response
// level, so it works identically under both looks (no UI gate). Toggle:
// "Block ads" (`noAds`, default YES). Every hook fails open -- when the
// switch is off, or a selector is missing on 9.34, the original runs.

static BOOL YTMGlassAdSkip(void) {
    return YTMGlassPreference(@"noAds", YES);
}

%hook YTAdsInnerTubeContextDecorator
- (void)decorateContext:(id)arg1 {
    if (!YTMGlassAdSkip()) return %orig;
}
%end

%hook YTDataUtils
- (id)spamSignalsDictionary {
    return YTMGlassAdSkip() ? nil : %orig;
}
%end

%hook YTAdShieldUtils
- (id)spamSignalsDictionary {
    return YTMGlassAdSkip() ? nil : %orig;
}
- (id)spamSignalsDictionaryWithoutIDFA {
    return YTMGlassAdSkip() ? nil : %orig;
}
%end

%hook YTIPlayerResponse
- (BOOL)isMonetized {
    return YTMGlassAdSkip() ? NO : %orig;
}
- (id)paidContentOverlayElementRendererOptions {
    return YTMGlassAdSkip() ? nil : %orig;
}
- (BOOL)isCuepointAdsEnabled {
    return YTMGlassAdSkip() ? NO : %orig;
}
- (id)adIntroRenderer {
    return YTMGlassAdSkip() ? nil : %orig;
}
- (BOOL)isDAIEnabledPlayback {
    return YTMGlassAdSkip() ? YES : %orig;
}
%end
