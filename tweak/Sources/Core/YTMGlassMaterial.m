#import "YTMGlassMaterial.h"
#import "YTMGlassCore.h"

// Everything UIGlassEffect goes through runtime lookup: the class does not
// exist in older SDKs, and static references would fail the link for the
// deployment target. expo's GlassView applies the same trick on the Swift
// side (NSClassFromString + effectWithStyle: probe).

static UIVisualEffect *YTMGlassRealEffect(YTMGlassStyle style, BOOL interactive) {
    Class glassCls = NSClassFromString(@"UIGlassEffect");
    if (!glassCls) return nil;
    @try {
        UIVisualEffect *effect = nil;
        // effectWithStyle: exists where UIGlassEffectStyle does (iOS 26+).
        // Regular = 0, Clear = 1. Fall back to plain -init when absent.
        SEL styleSel = NSSelectorFromString(@"effectWithStyle:");
        if ([glassCls respondsToSelector:styleSel]) {
            NSMethodSignature *sig = [glassCls methodSignatureForSelector:styleSel];
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            [inv setSelector:styleSel];
            [inv setTarget:glassCls];
            NSInteger styleValue = (style == YTMGlassStyleClear) ? 1 : 0;
            [inv setArgument:&styleValue atIndex:2];
            [inv invoke];
            __unsafe_unretained UIVisualEffect *out = nil;
            [inv getReturnValue:&out];
            effect = out;
        } else {
            effect = [[glassCls alloc] init];
        }
        if (!effect) return nil;
        if (interactive) {
            // setIsInteractive: only exists on iOS 26+; reach it through
            // NSInvocation so older SDKs still compile (-Werror forbids an
            // undeclared message send even to id).
            SEL interactiveSel = NSSelectorFromString(@"setIsInteractive:");
            if ([effect respondsToSelector:interactiveSel]) {
                NSMethodSignature *sig = [effect methodSignatureForSelector:interactiveSel];
                NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                [inv setSelector:interactiveSel];
                [inv setTarget:effect];
                BOOL flag = YES;
                [inv setArgument:&flag atIndex:2];
                [inv invoke];
            }
        }
        return effect;
    } @catch (NSException *e) {
        YTMGlassLog([NSString stringWithFormat:@"glass effect create failed: %@", e]);
        return nil;
    }
}

static UIVisualEffect *YTMGlassFallbackEffect(void) {
    UIBlurEffectStyle blurStyle = UIBlurEffectStyleSystemMaterial;
    if (@available(iOS 13.0, *)) {
        // SystemMaterial tracks light/dark like glass does.
    }
    return [UIBlurEffect effectWithStyle:blurStyle];
}

UIVisualEffectView *YTMGlassEffectView(YTMGlassStyle style, CGFloat cornerRadius, BOOL interactive) {
    UIVisualEffect *effect = nil;
    if (YTMGlassAvailable()) {
        effect = YTMGlassRealEffect(style, interactive);
    }
    if (!effect) effect = YTMGlassFallbackEffect();
    UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
    view.backgroundColor = [UIColor clearColor];
    // Outside YTM's navigation stacks the inherited appearance is the
    // system's: pin dark so glass never flips light in light mode.
    if (@available(iOS 13.0, *)) {
        view.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    YTMGlassLayoutView(view, cornerRadius);
    return view;
}

void YTMGlassLayoutView(UIVisualEffectView *view, CGFloat cornerRadius) {
    if (!view) return;
    CGFloat radius = cornerRadius;
    if (radius < 0) {
        CGFloat side = MIN(view.bounds.size.width, view.bounds.size.height);
        radius = (side > 0) ? side / 2.0 : 20.0;
    }
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = YES;
}

BOOL YTMGlassIsRealGlass(UIVisualEffectView *view) {
    if (!view || !YTMGlassAvailable()) return NO;
    Class glassCls = NSClassFromString(@"UIGlassEffect");
    return glassCls && [view.effect isKindOfClass:glassCls];
}
