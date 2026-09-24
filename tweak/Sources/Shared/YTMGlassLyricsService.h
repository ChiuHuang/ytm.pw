#ifndef YTMGlassLyricsService_h
#define YTMGlassLyricsService_h

#import <UIKit/UIKit.h>

// Shared lyrics fetch + parse. Talks to a lyrics JSON endpoint shaped like
// GET {endpoint}/api/lyrics?v={videoID}&lang={lang} ->
//   {"lyrics": [{"time": 12.3, "text": "...", "translated": "..."}], ...}
// and maps it onto YTMGlassLyricLine objects. Plain NSObject parsing, no
// hooks, no UI -- safe to unit-reason about without a device.

// One lyric line. start < 0 means unsynced/plain.
@interface YTMGlassLyricLine : NSObject
@property (nonatomic, assign) double start;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *translated;
+ (instancetype)lineWithStart:(double)start text:(NSString *)text translated:(NSString *)translated;
@end

// Async fetch. Completion always runs on the main queue. Lyrics are
// translated server-side for lang; translated may be nil per line.
void YTMGlassFetchLyrics(NSString *videoID, NSString *lang,
                         void (^completion)(NSArray<YTMGlassLyricLine *> *lines, NSError *error));

// Parse one /api/lyrics payload dict into lines (nil-safe, testable).
NSArray<YTMGlassLyricLine *> *YTMGlassParseLyricsPayload(NSDictionary *payload);

#endif
