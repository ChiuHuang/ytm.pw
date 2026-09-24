#import "../Core/YTMGlassCore.h"
#import "../Core/YTMGlassMaterial.h"
#import "../Headers/YTMGlassHeaders.h"

// First redesign slice: the tab bar goes glass.
//
// Strategy (defensive by design): YTM draws the pivot bar itself; we only
// restyle its backdrop. On layout we insert one YTMGlassEffectView (tag
// 9001) as the backmost subview and fade out YTM's own background views,
// never hiding container stacks (hiding views inside YTM's stack views
// crashes -- use alpha instead). If anything is missing we bail silently
// and the native bar stays.

static const NSInteger kYTMGlassPivotTag = 9001;

%hook YTPivotBarView

- (void)layoutSubviews {
    %orig;
    if (!YTMGlassRedesignedUI()) return;
    @try {
        UIVisualEffectView *glass = (UIVisualEffectView *)[self viewWithTag:kYTMGlassPivotTag];
        if (![glass isKindOfClass:[UIVisualEffectView class]]) {
            glass = YTMGlassEffectView(YTMGlassStyleRegular, 24.0, NO);
            glass.tag = kYTMGlassPivotTag;
            glass.userInteractionEnabled = NO;
            [self insertSubview:glass atIndex:0];
            YTMGlassLog(@"pivot bar glass installed");
        }
        // Inset like a floating glass bar: 12pt margins, sits above the
        // bottom safe area instead of edge-to-edge.
        CGFloat bottomInset = 8.0;
        if (@available(iOS 11.0, *)) {
            bottomInset += self.safeAreaInsets.bottom;
        }
        CGFloat barH = 64.0;
        glass.frame = CGRectMake(12.0, self.bounds.size.height - bottomInset - barH,
                                 self.bounds.size.width - 24.0, barH);
        YTMGlassLayoutView(glass, 24.0);
        // Fade YTM's own bar background; keep the item stack untouched.
        for (UIView *sub in self.subviews) {
            if (sub == glass) continue;
            if ([sub isKindOfClass:[UIVisualEffectView class]]) {
                sub.alpha = 0.0;
            } else if (sub.subviews.count == 0 && YTMGlassColorAlpha(sub.backgroundColor) > 0.01) {
                // Flat background slab (no children = not the item stack).
                sub.alpha = 0.0;
            }
        }
    } @catch (NSException *e) {
        YTMGlassLog([NSString stringWithFormat:@"pivot bar restyle skipped: %@", e]);
    }
}

%end
