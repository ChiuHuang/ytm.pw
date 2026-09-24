#import "../Core/YTMGlassCore.h"
#import "../Core/YTMGlassMaterial.h"
#import "../Headers/YTMGlassHeaders.h"
#import "../Shared/YTMGlassPlayback.h"
#import "../Shared/YTMGlassLyricsService.h"

@interface UIView (YTMGlassAncestor)
- (UIViewController *)_viewControllerForAncestor;
@end

// Glass lyrics sheet: artwork-blurred backdrop, line table with
// translations, time-driven highlight + center scroll, tap-to-seek.
// Data comes from the lyrics endpoint (Shared service); timing from the
// playback tap. Presented fullscreen from the glass Lyrics pill below.

@interface YTMGlassLyricsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSArray<YTMGlassLyricLine *> *lines;
@property (nonatomic, strong) UIImageView *artwork;
@property (nonatomic, strong) UIVisualEffectView *blur;
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, copy) NSString *videoID;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation YTMGlassLyricsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.currentIndex = -1;

    self.artwork = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.artwork.contentMode = UIViewContentModeScaleAspectFill;
    self.artwork.clipsToBounds = YES;
    self.artwork.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.artwork];

    self.blur = YTMGlassEffectView(YTMGlassStyleRegular, 0, NO);
    self.blur.frame = self.view.bounds;
    self.blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.blur];

    UIView *dim = [[UIView alloc] initWithFrame:self.view.bounds];
    dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    dim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    dim.userInteractionEnabled = NO;
    [self.view addSubview:dim];

    self.table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.table.delegate = self;
    self.table.dataSource = self;
    self.table.backgroundColor = [UIColor clearColor];
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.table.rowHeight = UITableViewAutomaticDimension;
    self.table.estimatedRowHeight = 76.0;
    self.table.contentInset = UIEdgeInsetsMake(80, 0, 200, 0);
    [self.view addSubview:self.table];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, self.view.bounds.size.width, 30)];
    self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.statusLabel];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(self.view.bounds.size.width - 52, 54, 36, 36);
    close.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    close.tintColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        UIImage *x = [UIImage systemImageNamed:@"xmark"];
        if (x) [close setImage:x forState:UIControlStateNormal];
        else [close setTitle:@"X" forState:UIControlStateNormal];
    } else {
        [close setTitle:@"X" forState:UIControlStateNormal];
    }
    close.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.18];
    close.layer.cornerRadius = 18;
    [close addTarget:self action:@selector(closeSheet) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:close];

    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songChanged:) name:YTMGlassSongChangedNotification object:nil];
    [self loadForCurrentVideo];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.link invalidate];
}

- (void)closeSheet {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)songChanged:(NSNotification *)note {
    [self loadForCurrentVideo];
}

- (void)loadForCurrentVideo {
    NSString *vid = YTMGlassCurrentVideoID();
    if (!vid.length) {
        self.statusLabel.text = @"No video playing";
        return;
    }
    self.videoID = vid;
    self.currentIndex = -1;
    self.lines = @[];
    [self.table reloadData];
    self.statusLabel.text = @"Loading...";
    [self loadArtwork:vid];
    NSString *lang = YTMGlassStringPreference(@"lyricsLang", YTMGlassDefaultLyricsLang);
    YTMGlassFetchLyrics(vid, lang, ^(NSArray<YTMGlassLyricLine *> *lines, NSError *error) {
        if (![vid isEqualToString:self.videoID]) return;
        if (error || lines.count == 0) {
            self.statusLabel.text = @"No lyrics found";
            return;
        }
        self.statusLabel.text = @"";
        self.lines = lines;
        [self.table reloadData];
    });
}

- (void)loadArtwork:(NSString *)vid {
    NSString *urlStr = YTMGlassArtworkURL(vid);
    if (!urlStr.length) return;
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:urlStr] completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (err || !data) return;
        UIImage *img = [UIImage imageWithData:data];
        if (!img) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([vid isEqualToString:self.videoID]) self.artwork.image = img;
        });
    }] resume];
}

- (void)tick {
    if (self.lines.count == 0) return;
    double t = YTMGlassCurrentTime();
    if (t <= 0) return;
    NSInteger idx = -1;
    for (NSInteger i = 0; i < self.lines.count; i++) {
        if (self.lines[i].start >= 0 && t >= self.lines[i].start) idx = i;
        else if (self.lines[i].start >= 0) break;
    }
    if (idx != self.currentIndex) {
        self.currentIndex = idx;
        [self.table reloadData];
        if (idx >= 0) {
            [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]
                              atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.lines.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuse = @"YTMGlassLyricCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuse];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    }
    YTMGlassLyricLine *line = self.lines[indexPath.row];
    BOOL active = (indexPath.row == self.currentIndex);
    cell.textLabel.text = line.text;
    cell.textLabel.textColor = active ? [UIColor whiteColor] : [[UIColor whiteColor] colorWithAlphaComponent:0.35];
    cell.detailTextLabel.text = line.translated;
    cell.detailTextLabel.textColor = active ? [[UIColor whiteColor] colorWithAlphaComponent:0.75]
                                           : [[UIColor whiteColor] colorWithAlphaComponent:0.25];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    YTMGlassLyricLine *line = self.lines[indexPath.row];
    if (line.start >= 0) YTMGlassSeekTo(line.start);
}

@end

void YTMGlassPresentLyricsFromVC(UIViewController *host) {
    if (!host) return;
    YTMGlassLyricsViewController *vc = [[YTMGlassLyricsViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [host presentViewController:vc animated:YES completion:nil];
}

// Trigger: a glass Lyrics pill inside the fullscreen player. Anchored below
// the transport controls when found, else bottom-center of the player view.
// Additive only -- YTM's own controls are never moved or hidden.

static const NSInteger kYTMGlassLyricsPillTag = 9004;

%hook YTMNowPlayingView

- (void)layoutSubviews {
    %orig;
    if (!YTMGlassRedesignedUI()) return;
    @try {
        UIButton *pill = (UIButton *)[self viewWithTag:kYTMGlassLyricsPillTag];
        if (![pill isKindOfClass:[UIButton class]]) {
            pill = [UIButton buttonWithType:UIButtonTypeCustom];
            pill.tag = kYTMGlassLyricsPillTag;
            UIVisualEffectView *bg = YTMGlassEffectView(YTMGlassStyleClear, 18.0, YES);
            bg.frame = pill.bounds;
            bg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            bg.userInteractionEnabled = NO;
            [pill insertSubview:bg atIndex:0];
            UILabel *label = [[UILabel alloc] initWithFrame:pill.bounds];
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            label.text = @"Lyrics";
            label.font = [UIFont boldSystemFontOfSize:14];
            label.textColor = [UIColor whiteColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.userInteractionEnabled = NO;
            [pill addSubview:label];
            [pill addTarget:self action:@selector(ytmglass_openLyrics) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:pill];
            YTMGlassLog(@"lyrics pill installed");
        }
        // Anchor: below YTMPlayerControlsView, else bottom-center.
        UIView *anchor = nil;
        for (UIView *sub in self.subviews) {
            for (UIView *inner in sub.subviews) {
                if ([inner isKindOfClass:[YTMPlayerControlsView class]]) { anchor = inner; break; }
            }
            if (anchor) break;
        }
        CGFloat pillW = 120.0, pillH = 36.0;
        CGFloat cx = self.bounds.size.width / 2.0;
        CGFloat y = self.bounds.size.height - 90.0;
        if (anchor) y = CGRectGetMaxY([self convertRect:anchor.frame fromView:anchor.superview]) + 10.0;
        if (y + pillH > self.bounds.size.height - 20.0) y = self.bounds.size.height - 20.0 - pillH;
        pill.frame = CGRectMake(cx - pillW / 2.0, y, pillW, pillH);
    } @catch (NSException *e) {
        YTMGlassLog([NSString stringWithFormat:@"lyrics pill skipped: %@", e]);
    }
}

%new
- (void)ytmglass_openLyrics {
    UIViewController *host = nil;
    @try {
        if ([self respondsToSelector:@selector(_viewControllerForAncestor)]) {
            host = [self _viewControllerForAncestor];
        }
    } @catch (NSException *e) {
    }
    if (!host) {
        YTMGlassLog(@"lyrics pill: no host VC");
        return;
    }
    YTMGlassPresentLyricsFromVC(host);
}

%end
