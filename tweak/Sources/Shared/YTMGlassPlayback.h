#ifndef YTMGlassPlayback_h
#define YTMGlassPlayback_h

#import <UIKit/UIKit.h>

// Shared playback state. A small hook on YTPlayerViewController captures
// the active player, video ID and position; every consumer (mini player
// extras, lyrics sheet, progress UI) reads through these -- nobody touches
// YTM's player classes directly.

extern NSString *const YTMGlassSongChangedNotification;

// Defaults used when the endpoint / lang prefs were never set.
#define YTMGlassDefaultLyricsEndpoint @"https://ytmtranslate.chiuhuang.dev"
#define YTMGlassDefaultLyricsLang @"zh-TW"

NSString *YTMGlassCurrentVideoID(void);
double YTMGlassCurrentTime(void);
CGFloat YTMGlassTotalTime(void);
NSString *YTMGlassCurrentTitle(void);
NSString *YTMGlassCurrentArtist(void);
NSString *YTMGlassArtworkURL(NSString *videoID);
void YTMGlassSeekTo(double seconds);
void YTMGlassTogglePlayPause(void);

#endif
