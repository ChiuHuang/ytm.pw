#import "../Core/YTMGlassCore.h"
#import "../Core/YTMGlassMaterial.h"
#import "../Headers/YTMGlassHeaders.h"

// Search goes glass (dump 16-03-33): YTMSearchBarViewV2 (388x56) holds a
// 48pt container with the back button + query field. We slide one glass
// view (tag 9006) behind that container and round the container itself.
// The text field, buttons and gestures are never touched, only the
// backdrop -- typing, focus and cancel keep working pixel-identical.

static const NSInteger kYTMGlassSearchTag = 9006;

%hook YTMSearchBarViewV2

- (void)layoutSubviews {
    %orig;
    if (!YTMGlassRedesignedUI()) return;
    @try {
        // The field container is the single large plain UIView child.
        UIView *container = nil;
        for (UIView *sub in self.subviews) {
            if (![sub isKindOfClass:[UIVisualEffectView class]] &&
                sub.bounds.size.height >= 44.0 && sub.subviews.count > 0) {
                container = sub;
                break;
            }
        }
        if (!container) return;
        UIVisualEffectView *glass = (UIVisualEffectView *)[container viewWithTag:kYTMGlassSearchTag];
        if (![glass isKindOfClass:[UIVisualEffectView class]]) {
            glass = YTMGlassEffectView(YTMGlassStyleClear, 24.0, NO);
            glass.tag = kYTMGlassSearchTag;
            glass.userInteractionEnabled = NO;
            glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [container insertSubview:glass atIndex:0];
            // One-time: thin the container's own flat fill so the glass
            // reads through. Done only here so layout passes never stack.
            if ([container.backgroundColor alphaComponent] > 0.01) {
                container.backgroundColor = [container.backgroundColor colorWithAlphaComponent:0.25];
            }
            YTMGlassLog(@"search field glass installed");
        }
        glass.frame = container.bounds;
        YTMGlassLayoutView(glass, 24.0);
    } @catch (NSException *e) {
        YTMGlassLog([NSString stringWithFormat:@"search restyle skipped: %@", e]);
    }
}

%end
