#import "../Core/YTMGlassCore.h"
#import "../Core/YTMGlassMaterial.h"
#import "../Headers/YTMGlassHeaders.h"
#import "../Shared/YTMGlassPlayback.h"
#import "../Shared/YTMGlassPlayback.h"

// Mod Settings: look switch, lyrics endpoint + language, about.
// Entry point is the account menu (avatar tap -> YTMAvatarAccountView hook
// appends a Glass button -- the proven YTM settings anchor). Sections read
// live prefs; text rows edit through alerts; the redesign switch needs a
// restart (switches are read at launch).

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
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                     target:self
                                                     action:@selector(closeSettings)];
}

- (void)closeSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return YTMGlassAvailable() ? 1 : 2;
    if (section == 1) return 2;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Look";
    if (section == 1) return @"Lyrics";
    return @"About";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YTMGlassCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"YTMGlassCell"];
    }
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.section == 0) {
        if (!YTMGlassAvailable() && indexPath.row == 0) {
            cell.textLabel.text = @"Needs iOS 26";
            cell.detailTextLabel.text = @"Liquid Glass is drawn by the system from iOS 26 on";
            return cell;
        }
        cell.textLabel.text = @"Redesigned UI";
        cell.detailTextLabel.text = @"Liquid Glass look (restart to apply)";
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = YTMGlassRedesignedUIStored();
        sw.enabled = YTMGlassAvailable();
        [sw addTarget:self action:@selector(glassSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        return cell;
    }
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Lyrics endpoint";
            cell.detailTextLabel.text = YTMGlassStringPreference(@"lyricsEndpoint", YTMGlassDefaultLyricsEndpoint);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        } else {
            cell.textLabel.text = @"Lyrics language";
            cell.detailTextLabel.text = YTMGlassStringPreference(@"lyricsLang", YTMGlassDefaultLyricsLang);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        return cell;
    }
    cell.textLabel.text = @"ytm.pw 0.1.0";
    cell.detailTextLabel.text = @"YouTube Music in glass (YTM 9.34)";
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        BOOL isEndpoint = (indexPath.row == 0);
        NSString *key = isEndpoint ? @"lyricsEndpoint" : @"lyricsLang";
        NSString *current = isEndpoint ? YTMGlassStringPreference(@"lyricsEndpoint", YTMGlassDefaultLyricsEndpoint)
                                       : YTMGlassStringPreference(@"lyricsLang", YTMGlassDefaultLyricsLang);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:isEndpoint ? @"Lyrics endpoint" : @"Lyrics language"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
            field.text = current;
            field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            NSString *value = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (value.length) {
                YTMGlassSetStringPreference(key, value);
                [self.table reloadData];
            }
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
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

%hook YTMAvatarAccountView

- (void)setAccountMenuUpperButtons:(id)upper lowerButtons:(id)lower {
    @try {
        Class btnCls = objc_getClass("YTMAccountButton");
        if (btnCls && [lower isKindOfClass:[NSArray class]]) {
            UIImage *icon = nil;
            if (@available(iOS 13.0, *)) {
                icon = [UIImage systemImageNamed:@"sparkles"];
            }
            UIView *selfRef = self;
            YTMAccountButton *button = [(YTMAccountButton *)[btnCls alloc] initWithTitle:@"Glass"
                                                                             identifier:@"ytmglass"
                                                                                   icon:icon
                                                                            actionBlock:^(BOOL finished) {
                UIViewController *host = nil;
                @try {
                    if ([selfRef respondsToSelector:@selector(_viewControllerForAncestor)]) {
                        host = [(YTMAvatarAccountView *)selfRef _viewControllerForAncestor];
                    }
                } @catch (NSException *e) {
                }
                YTMGlassPresentSettingsFromVC(host);
            }];
            if (button) {
                NSMutableArray *arr = [NSMutableArray arrayWithArray:lower];
                [arr addObject:button];
                %orig(upper, arr);
                return;
            }
        }
    } @catch (NSException *e) {
        YTMGlassLog([NSString stringWithFormat:@"account menu hook skipped: %@", e]);
    }
    %orig;
}

%end
