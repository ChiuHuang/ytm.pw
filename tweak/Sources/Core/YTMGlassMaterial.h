#ifndef YTMGlassMaterial_h
#define YTMGlassMaterial_h

#import <UIKit/UIKit.h>

// Glass material factory. Still Core: no YTM classes here, UIKit only.
//
// On iOS 26+ this returns a UIVisualEffectView carrying a real
// UIGlassEffect (created via runtime lookup, so no iOS 26 SDK is needed to
// build). Below 26 it returns the same view with a system material blur,
// which reads as frosted glass next to the real thing.
// The returned view is container-ready: put foreground content in
// .contentView and pin the view itself with Auto Layout or frames.

typedef NS_ENUM(NSInteger, YTMGlassStyle) {
    YTMGlassStyleRegular = 0, // adaptive, default for bars and cards
    YTMGlassStyleClear = 1,   // stronger background show-through
};

// glassEffectViewWithStyle:cornerRadius:interactive:
//   cornerRadius < 0 -> capsule-ish (half the smaller side, resolved per
//   layout in layoutGlassView:cornerRadius:).
UIVisualEffectView *YTMGlassEffectView(YTMGlassStyle style, CGFloat cornerRadius, BOOL interactive);

// Re-resolve dynamic corner radius after a frame change.
void YTMGlassLayoutView(UIVisualEffectView *view, CGFloat cornerRadius);

// YES when view.effect is a real UIGlassEffect (vs the blur fallback).
BOOL YTMGlassIsRealGlass(UIVisualEffectView *view);

#endif
