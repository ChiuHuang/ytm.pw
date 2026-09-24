#ifndef YTMGlassCore_h
#define YTMGlassCore_h

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Lowest layer: mode gates, preference storage, logging.
// Nothing in Core imports Shared, Native, Redesigned or App (see
// scripts/check-layers.sh). Higher layers import Core only.

// NSUserDefaults suite key for every ytm.pw preference.
#define YTMGlassDefaultsKey @"YTMGlass"

// True when the OS can draw Liquid Glass (iOS 26+). Uses a runtime class
// lookup so the tweak links and runs on older SDKs and OS versions.
BOOL YTMGlassAvailable(void);

// True when the full glass redesign should run: available OS + enabled.
// Read once at launch semantics: call sites cache the value in their %ctor.
BOOL YTMGlassRedesignedUI(void);

// Stored switch (Settings page). Defaults to YES so a fresh install on a
// supported OS gets the redesign without a settings visit.
BOOL YTMGlassRedesignedUIStored(void);
void YTMGlassSetRedesignedUIStored(BOOL enabled);

// Generic bool preference under YTMGlassDefaultsKey.
BOOL YTMGlassPreference(NSString *key, BOOL fallback);
void YTMGlassSetPreference(NSString *key, BOOL value);

// Generic string preference under YTMGlassDefaultsKey.
NSString *YTMGlassStringPreference(NSString *key, NSString *fallback);
void YTMGlassSetStringPreference(NSString *key, NSString *value);

// Alpha of a UIColor via its CGColor (UIColor has no alphaComponent).
CGFloat YTMGlassColorAlpha(UIColor *color);

// Device log line, always prefixed so `make log` can filter it.
void YTMGlassLog(NSString *msg);

#endif
