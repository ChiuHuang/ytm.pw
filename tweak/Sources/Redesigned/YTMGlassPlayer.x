#import "../Core/YTMGlassCore.h"
#import "../Core/YTMGlassMaterial.h"
#import "../Headers/YTMGlassHeaders.h"
#import "../Shared/YTMGlassPlayback.h"

// Fullscreen player restyle, additive only (dump:576):
//   - a glass card behind the transport row (tag 9003), sized from the
//     real YTMPlayerControlsView frame, so play/pause/prev/next keep
//     working pixel-identical;
//   - the storyboard scrubber track gets rounded ends;
//   - title/artist/scroll labels are left alone (fonts stay YTM's).
// Nothing is re-parented, nothing is hidden, no frames are moved.

static const NSInteger kYTMGlassTransportTag = 9003;

static void YTMGlassRoundScrubber(UIView *root) {
    @try {
        for (UIView *sub in root.subviews) {
            if ([sub isKindOfClass:[YTMStoryboardScrubber class]]) {
                for (UIView *track in sub.subviews) {
                    for (UIView *bar in track.subviews) {
                        if (bar.bounds.size.height > 0 && bar.bounds.size.height <= 6.0) {
                            bar.layer.cornerRadius = bar.bounds.size.height / 2.0;
                            bar.layer.masksToBounds = YES;
                        }
                    }
                }
                return;
            }
        }
    } @catch (NSException *e) {
    }
}

%hook YTMNowPlayingView

- (void)layoutSubviews {
    %orig;
    if (!YTMGlassRedesignedUI()) return;
    @try {
        // Find the transport controls; the glass card wraps them.
        YTMPlayerControlsView *controls = nil;
        for (UIView *sub in self.subviews) {
            for (UIView *inner in sub.subviews) {
                if ([inner isKindOfClass:[YTMPlayerControlsView class]]) {
                    controls = (YTMPlayerControlsView *)inner;
                    break;
                }
            }
            if (controls) break;
        }
        if (controls && controls.superview) {
            UIView *host = controls.superview;
            UIVisualEffectView *glass = (UIVisualEffectView *)[host viewWithTag:kYTMGlassTransportTag];
            if (![glass isKindOfClass:[UIVisualEffectView class]]) {
                glass = YTMGlassEffectView(YTMGlassStyleRegular, 22.0, NO);
                glass.tag = kYTMGlassTransportTag;
                glass.userInteractionEnabled = NO;
                [host insertSubview:glass belowSubview:controls];
                YTMGlassLog(@"player transport glass installed");
            }
            CGRect f = controls.frame;
            glass.frame = CGRectInset(f, -14.0, -10.0);
            YTMGlassLayoutView(glass, 22.0);
        }
        YTMGlassRoundScrubber(self);
    } @catch (NSException *e) {
        YTMGlassLog([NSString stringWithFormat:@"player restyle skipped: %@", e]);
    }
}

%end
