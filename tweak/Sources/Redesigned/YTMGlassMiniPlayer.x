#import "../Core/YTMGlassCore.h"
#import "../Core/YTMGlassMaterial.h"
#import "../Headers/YTMGlassHeaders.h"

// Mini player goes glass: YTMMiniPlayerView (428x64, dump:265) keeps its
// queue carousel and MDCFloatingButtons working untouched; we only restyle
// the backdrop. One glass view (tag 9002) inserted at the back, corners
// rounded, YTM's own flat background slabs faded (never hidden -- hiding
// views inside YTM's stacks crashes, alpha is safe).

static const NSInteger kYTMGlassMiniTag = 9002;

%hook YTMMiniPlayerView

- (void)layoutSubviews {
    %orig;
    if (!YTMGlassRedesignedUI()) return;
    @try {
        UIVisualEffectView *glass = (UIVisualEffectView *)[self viewWithTag:kYTMGlassMiniTag];
        if (![glass isKindOfClass:[UIVisualEffectView class]]) {
            glass = YTMGlassEffectView(YTMGlassStyleRegular, 16.0, NO);
            glass.tag = kYTMGlassMiniTag;
            glass.userInteractionEnabled = NO;
            [self insertSubview:glass atIndex:0];
            YTMGlassLog(@"mini player glass installed");
        }
        // Float inside the view bounds with side margins; keep the bottom
        // edge flush so the queue swipe area stays where YTM expects it.
        glass.frame = CGRectMake(8.0, 4.0, self.bounds.size.width - 16.0, self.bounds.size.height - 8.0);
        YTMGlassLayoutView(glass, 16.0);
        for (UIView *sub in self.subviews) {
            if (sub == glass) continue;
            if ([sub isKindOfClass:[UIVisualEffectView class]]) {
                sub.alpha = 0.0;
            } else if (sub.subviews.count == 0 && [sub.backgroundColor alphaComponent] > 0.01) {
                sub.alpha = 0.0;
            }
        }
    } @catch (NSException *e) {
        YTMGlassLog([NSString stringWithFormat:@"mini player restyle skipped: %@", e]);
    }
}

%end
