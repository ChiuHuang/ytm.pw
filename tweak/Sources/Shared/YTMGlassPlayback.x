#import "YTMGlassPlayback.h"
#import "../Core/YTMGlassCore.h"
#import "../Headers/YTMGlassHeaders.h"

NSString *const YTMGlassSongChangedNotification = @"YTMGlassSongChanged";

static __weak YTPlayerViewController *glassActivePlayer = nil;
static NSString *glassVideoID = nil;
static double glassPlaybackTime = 0.0;

NSString *YTMGlassCurrentVideoID(void) {
    if (glassVideoID.length) return glassVideoID;
    @try {
        NSString *vid = nil;
        if ([glassActivePlayer respondsToSelector:@selector(currentVideoID)]) {
            vid = [glassActivePlayer currentVideoID];
        }
        if (vid.length) {
            glassVideoID = [vid copy];
            return glassVideoID;
        }
    } @catch (NSException *e) {
    }
    return nil;
}

double YTMGlassCurrentTime(void) {
    return glassPlaybackTime;
}

CGFloat YTMGlassTotalTime(void) {
    @try {
        if ([glassActivePlayer respondsToSelector:@selector(currentVideoTotalMediaTime)]) {
            return [glassActivePlayer currentVideoTotalMediaTime];
        }
    } @catch (NSException *e) {
    }
    return 0;
}

static NSString *YTMGlassVideoDetail(NSString *key) {
    @try {
        YTPlayerViewController *player = glassActivePlayer;
        if (!player || ![player respondsToSelector:@selector(playerResponse)]) return nil;
        YTPlayerResponse *resp = player.playerResponse;
        if (!resp || ![resp respondsToSelector:@selector(playerData)]) return nil;
        YTIPlayerResponse *data = resp.playerData;
        if (!data || ![data respondsToSelector:@selector(videoDetails)]) return nil;
        YTIVideoDetails *details = data.videoDetails;
        if (!details) return nil;
        if ([key isEqualToString:@"title"] && [details respondsToSelector:@selector(title)]) return details.title;
        if ([key isEqualToString:@"author"] && [details respondsToSelector:@selector(author)]) return details.author;
    } @catch (NSException *e) {
    }
    return nil;
}

NSString *YTMGlassCurrentTitle(void) {
    return YTMGlassVideoDetail(@"title");
}

NSString *YTMGlassCurrentArtist(void) {
    return YTMGlassVideoDetail(@"author");
}

NSString *YTMGlassArtworkURL(NSString *videoID) {
    if (!videoID.length) return nil;
    return [NSString stringWithFormat:@"https://i.ytimg.com/vi/%@/hqdefault.jpg", videoID];
}

void YTMGlassSeekTo(double seconds) {
    @try {
        YTPlayerViewController *player = glassActivePlayer;
        if ([player respondsToSelector:@selector(seekToTime:)]) {
            [player seekToTime:(CGFloat)seconds];
        }
    } @catch (NSException *e) {
    }
}

void YTMGlassTogglePlayPause(void) {
    @try {
        YTPlayerViewController *player = glassActivePlayer;
        if ([player respondsToSelector:@selector(togglePlayPause)]) {
            [player togglePlayPause];
        }
    } @catch (NSException *e) {
    }
}

%hook YTPlayerViewController

- (void)playbackController:(id)controller didActivateVideo:(id)video withPlaybackData:(id)data {
    %orig;
    glassActivePlayer = self;
    glassPlaybackTime = 0.0;
    @try {
        if ([self respondsToSelector:@selector(currentVideoID)]) {
            NSString *vid = [self currentVideoID];
            if (vid.length && ![vid isEqualToString:glassVideoID]) {
                glassVideoID = [vid copy];
                [[NSNotificationCenter defaultCenter] postNotificationName:YTMGlassSongChangedNotification object:glassVideoID];
            }
        }
    } @catch (NSException *e) {
    }
}

- (void)playbackController:(id)controller didReceivePlaybackPositionTime:(double)time {
    %orig;
    glassPlaybackTime = time;
}

%end

%ctor {
    YTMGlassLog(@"playback tap installed");
}
