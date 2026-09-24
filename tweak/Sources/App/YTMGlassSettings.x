#import "../Core/YTMGlassCore.h"
#import "../Core/YTMGlassMaterial.h"

// Mod Settings, v1: defensive by necessity.
//
// YTM's settings screen structure varies by version, so instead of guessing
// its table classes we expose a standalone page and wire it where proven:
//   - YTMGlassPresentSettingsFromVC() is the entry point any proven hook
//     (pivot long-press, settings row, URL scheme) can call.
//   - The %ctor below attempts nothing until a settings host is confirmed
//     against trees/recorded/ -- see TODO.
// The redesign switch defaults ON (glass where available); turning it off
// takes effect on next launch (switches are read at launch).

@interface YTMGlassSettingsController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *table;
@end

@implementation YTMGlassSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Glass";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.table.delegate = self;
    self.table.dataSource = self;
    self.table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.table];
    if (@available(iOS 26.0, *)) {
        // Real glass header card for the settings page itself.
        UIVisualEffectView *card = YTMGlassEffectView(YTMGlassStyleRegular, 20.0, NO);
        card.frame = CGRectMake(16, 100, self.view.bounds.size.width - 32, 120);
        card.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        card.userInteractionEnabled = NO;
        [self.view addSubview:card];
        [self.view bringSubviewToFront:self.table];
        self.table.backgroundColor = [UIColor clearColor];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return YTMGlassAvailable() ? 1 : 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YTMGlassCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"YTMGlassCell"];
    }
    if (!YTMGlassAvailable() && indexPath.row == 0) {
        cell.textLabel.text = @"Needs iOS 26";
        cell.detailTextLabel.text = @"Liquid Glass is drawn by the system from iOS 26 on";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    cell.textLabel.text = @"Redesigned UI";
    cell.detailTextLabel.text = YTMGlassAvailable() ? @"Liquid Glass look (restart to apply)" : @"Unavailable on this OS";
    UISwitch *sw = [[UISwitch alloc] init];
    sw.on = YTMGlassRedesignedUIStored();
    sw.enabled = YTMGlassAvailable();
    [sw addTarget:self action:@selector(glassSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)glassSwitchChanged:(UISwitch *)sender {
    YTMGlassSetRedesignedUIStored(sender.isOn);
    YTMGlassLog([NSString stringWithFormat:@"redesign %@", sender.isOn ? @"ON" : @"OFF"]);
}

@end

void YTMGlassPresentSettingsFromVC(UIViewController *host) {
    if (!host) return;
    YTMGlassSettingsController *vc = [[YTMGlassSettingsController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [host presentViewController:nav animated:YES completion:nil];
}

// TODO(device): confirm the YTM 9.34 settings host class from a recorded
// tree, then hook it to push YTMGlassSettingsController (native look keeps
// YTM's own settings untouched).
