#import "YTMGlassLyricsService.h"
#import "../Core/YTMGlassCore.h"
#import "YTMGlassPlayback.h"

@implementation YTMGlassLyricLine

+ (instancetype)lineWithStart:(double)start text:(NSString *)text translated:(NSString *)translated {
    YTMGlassLyricLine *line = [[self alloc] init];
    line.start = start;
    line.text = text ?: @"";
    line.translated = translated;
    return line;
}

@end

NSArray<YTMGlassLyricLine *> *YTMGlassParseLyricsPayload(NSDictionary *payload) {
    id raw = [payload isKindOfClass:[NSDictionary class]] ? payload[@"lyrics"] : nil;
    if (![raw isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray<YTMGlassLyricLine *> *out = [NSMutableArray arrayWithCapacity:[raw count]];
    for (id entry in raw) {
        if (![entry isKindOfClass:[NSDictionary class]]) continue;
        double start = -1;
        id t = entry[@"time"];
        if ([t respondsToSelector:@selector(doubleValue)]) start = [t doubleValue];
        if (start < 0) {
            id startMs = entry[@"startTimeMs"];
            if ([startMs respondsToSelector:@selector(doubleValue)]) start = [startMs doubleValue] / 1000.0;
        }
        NSString *text = entry[@"text"];
        if (![text isKindOfClass:[NSString class]]) text = @"";
        NSString *translated = entry[@"translated"];
        if (![translated isKindOfClass:[NSString class]]) translated = nil;
        if (text.length == 0 && (translated == nil || translated.length == 0)) continue;
        [out addObject:[YTMGlassLyricLine lineWithStart:start text:text translated:translated]];
    }
    return [out copy];
}

void YTMGlassFetchLyrics(NSString *videoID, NSString *lang,
                         void (^completion)(NSArray<YTMGlassLyricLine *> *lines, NSError *error)) {
    void (^done)(NSArray<YTMGlassLyricLine *> *, NSError *) = ^(NSArray<YTMGlassLyricLine *> *lines, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(lines, error);
        });
    };
    if (!videoID.length) {
        done(@[], [NSError errorWithDomain:@"YTMGlass" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"missing video ID"}]);
        return;
    }
    NSString *endpoint = YTMGlassStringPreference(@"lyricsEndpoint", YTMGlassDefaultLyricsEndpoint);
    while ([endpoint hasSuffix:@"/"]) endpoint = [endpoint substringToIndex:endpoint.length - 1];
    NSString *queryLang = lang.length ? lang : YTMGlassStringPreference(@"lyricsLang", YTMGlassDefaultLyricsLang);
    NSString *allowed = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~";
    NSString *encLang = [queryLang stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:allowed]] ?: queryLang;
    NSString *urlStr = [NSString stringWithFormat:@"%@/api/lyrics?v=%@&lang=%@", endpoint, videoID, encLang];
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) {
        done(@[], [NSError errorWithDomain:@"YTMGlass" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"bad lyrics URL"}]);
        return;
    }
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (err || !data) {
            done(@[], err ?: [NSError errorWithDomain:@"YTMGlass" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"network error"}]);
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray<YTMGlassLyricLine *> *lines = YTMGlassParseLyricsPayload(json);
        YTMGlassLog([NSString stringWithFormat:@"lyrics fetched: %lu lines", (unsigned long)lines.count]);
        done(lines, nil);
    }] resume];
}
