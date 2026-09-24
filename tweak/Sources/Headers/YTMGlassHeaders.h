#ifndef YTMGlassHeaders_h
#define YTMGlassHeaders_h

#import <UIKit/UIKit.h>

// Minimal YTM class stubs proven against the recorded view trees in
// trees/recorded/ (screenshot UI dumps from a real device) plus the class
// set used by the YTMusicUltimate tweak. Extend only from a recorded tree
// or the 9.34 binary -- never guess selectors.

// --- Pivot (tab) bar ---
// VC hierarchy: YTMPivotBarViewController (sibling of YTMWatchViewController
// under YTMContentViewController). Confirmed in UI_DUMP_15-42-11.txt:16.
@interface YTMPivotBarViewController : UIViewController
@end

@interface YTPivotBarView : UIView
@property (nonatomic, strong, readwrite) id renderer;
@end

// --- Watch / now playing ---
// YTMWatchViewController -> YTMNowPlayingViewController,
// YTMMiniPlayerViewController, YTMPlayerViewController. Same dump:17-30.
@interface YTMWatchViewController : UIViewController
@property (nonatomic, weak, readwrite) id playerViewController;
@end

@interface YTMNowPlayingViewController : UIViewController
- (void)didTapNextButton;
- (void)didTapPrevButton;
- (void)didTapPlayPauseButton;
- (void)togglePlayPause;
@end

@interface YTPlayerViewController : UIViewController
- (NSString *)currentVideoID;
- (CGFloat)currentVideoMediaTime;
- (CGFloat)currentVideoTotalMediaTime;
- (void)seekToTime:(CGFloat)time;
- (void)play;
- (void)pause;
- (void)togglePlayPause;
@end

// --- Browse (Home / Search / Library tabs) ---
// YTMBrowseViewController -> YTMTabViewController. Same dump:12-15.
@interface YTMBrowseViewController : UIViewController
@end

@interface YTMTabViewController : UIViewController
@end

#endif
