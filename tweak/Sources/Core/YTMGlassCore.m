#import "YTMGlassCore.h"

BOOL YTMGlassAvailable(void) {
    static BOOL checked = NO;
    static BOOL available = NO;
    if (!checked) {
        checked = YES;
        @try {
            available = (NSClassFromString(@"UIGlassEffect") != Nil);
        } @catch (NSException *e) {
            available = NO;
        }
    }
    return available;
}

BOOL YTMGlassRedesignedUIStored(void) {
    NSDictionary *settings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:YTMGlassDefaultsKey];
    id value = settings[@"redesignedUI"];
    if (!value) return YES;
    return [value boolValue];
}

void YTMGlassSetRedesignedUIStored(BOOL enabled) {
    NSMutableDictionary *d = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:YTMGlassDefaultsKey] mutableCopy];
    if (!d) d = [NSMutableDictionary dictionary];
    d[@"redesignedUI"] = @(enabled);
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:YTMGlassDefaultsKey];
}

BOOL YTMGlassRedesignedUI(void) {
    if (!YTMGlassAvailable()) return NO;
    return YTMGlassRedesignedUIStored();
}

BOOL YTMGlassPreference(NSString *key, BOOL fallback) {
    NSDictionary *settings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:YTMGlassDefaultsKey];
    id value = settings[key];
    return value ? [value boolValue] : fallback;
}

void YTMGlassSetPreference(NSString *key, BOOL value) {
    NSMutableDictionary *d = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:YTMGlassDefaultsKey] mutableCopy];
    if (!d) d = [NSMutableDictionary dictionary];
    d[key] = @(value);
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:YTMGlassDefaultsKey];
}

void YTMGlassLog(NSString *msg) {
    NSLog(@"[ytmglass] %@", msg);
}
