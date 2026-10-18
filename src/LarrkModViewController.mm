//
//  LarrkModViewController.mm
//  LarrkMod
//
//  Created for Swiftgram (app.swiftgram.ios)
//  Copyright © 2026 LarrkMod. All rights reserved.
//

#import "LarrkModViewController.h"
#import "LarrkConfig.h"
#import <QuartzCore/QuartzCore.h>

#define LARRK_BG_COLOR         [UIColor colorWithRed:0.06 green:0.07 blue:0.10 alpha:1.0]
#define LARRK_CARD_COLOR       [UIColor colorWithRed:0.12 green:0.14 blue:0.19 alpha:1.0]
#define LARRK_ACCENT_PURPLE    [UIColor colorWithRed:0.55 green:0.32 blue:0.96 alpha:1.0]
#define LARRK_ACCENT_CYAN      [UIColor colorWithRed:0.00 green:0.85 blue:0.92 alpha:1.0]
#define LARRK_TEXT_PRIMARY     [UIColor whiteColor]
#define LARRK_TEXT_MUTED       [UIColor colorWithRed:0.62 green:0.65 blue:0.72 alpha:1.0]
#define LARRK_DANGER_RED       [UIColor colorWithRed:0.95 green:0.25 blue:0.35 alpha:1.0]
#define LARRK_BORDER_COLOR     [UIColor colorWithRed:0.22 green:0.25 blue:0.35 alpha:0.4]

@interface LarrkModViewController ()

@property (nonatomic, strong) UITextField *patternEmojiField;
@property (nonatomic, strong) UITextField *starsInputField;
@property (nonatomic, strong) UIImageView *nftThumbnailView;
@property (nonatomic, strong) UISegmentedControl *nftSegmentControl;
@property (nonatomic, strong) UISegmentedControl *gradientSegmentControl;
@property (nonatomic, strong) UILabel *starsBalanceLabel;

@end

@implementation LarrkModViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"LarrkMod";
    self.view.backgroundColor = LARRK_BG_COLOR;
    
    // Navigation Bar styling
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = LARRK_BG_COLOR;
    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: LARRK_TEXT_PRIMARY,
        NSFontAttributeName: [UIFont systemFontOfSize:17.5 weight:UIFontWeightBold]
    };
    self.navigationController.navigationBar.standardAppearance = appearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = LARRK_ACCENT_PURPLE;
    
    // Done / Close button
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Готово"
                                                                style:UIBarButtonItemStyleDone
                                                               target:self
                                                               action:@selector(dismissAction)];
    doneBtn.tintColor = LARRK_ACCENT_PURPLE;
    self.navigationItem.rightBarButtonItem = doneBtn;
    
    // Setup TableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = LARRK_BG_COLOR;
    self.tableView.separatorColor = LARRK_BORDER_COLOR;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tableView];
    
    [self setupHeaderView];
    
    // Tap to dismiss keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)setupHeaderView {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 110)];
    
    // Gradient Badge icon
    CGFloat iconSize = 48.0;
    UIView *iconContainer = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - iconSize) / 2.0, 10, iconSize, iconSize)];
    iconContainer.layer.cornerRadius = 14.0;
    iconContainer.layer.masksToBounds = YES;
    
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = iconContainer.bounds;
    grad.colors = @[(id)LARRK_ACCENT_PURPLE.CGColor, (id)LARRK_ACCENT_CYAN.CGColor];
    grad.startPoint = CGPointMake(0, 0);
    grad.endPoint = CGPointMake(1, 1);
    [iconContainer.layer addSublayer:grad];
    
    UILabel *badgeEmoji = [[UILabel alloc] initWithFrame:iconContainer.bounds];
    badgeEmoji.text = @"⚡";
    badgeEmoji.font = [UIFont systemFontOfSize:26];
    badgeEmoji.textAlignment = NSTextAlignmentCenter;
    [iconContainer addSubview:badgeEmoji];
    [header addSubview:iconContainer];
    
    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 64, self.view.bounds.size.width - 32, 22)];
    titleLabel.text = @"LarrkMod for Swiftgram";
    titleLabel.textColor = LARRK_TEXT_PRIMARY;
    titleLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightHeavy];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [header addSubview:titleLabel];
    
    // Subtitle
    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 88, self.view.bounds.size.width - 32, 16)];
    subLabel.text = @"Reverse-Engineered by Senior iOS Engineer • v1.0.0";
    subLabel.textColor = LARRK_TEXT_MUTED;
    subLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightMedium];
    subLabel.textAlignment = NSTextAlignmentCenter;
    [header addSubview:subLabel];
    
    self.tableView.tableHeaderView = header;
}

- (void)dismissAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2; // Anti-Delete: Toggle, Clear Cache
        case 1: return 8; // Ghost Mode: 8 Toggles
        case 2: return 1; // Telegram Premium: Toggle
        case 3: return 7; // NFT Profile: Toggle, Preset, Custom Image, Gradient, Pattern Emoji, Apply Btn, Reset Btn
        case 4: return 5; // Stars: Toggle, Balance, Input, Quick Buttons, Action Buttons
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"АНТИ-УДАЛЕНИЕ СООБЩЕНИЙ";
        case 1: return @"ПРИВАТНОСТЬ И СТАТУСЫ (GHOST MODE)";
        case 2: return @"TELEGRAM PREMIUM";
        case 3: return @"ЛОКАЛЬНЫЙ NFT-ПОДАРОК И ПРОФИЛЬ";
        case 4: return @"ЛОКАЛЬНЫЕ TELEGRAM STARS ⭐";
        default: return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Удаленные сообщения не исчезают из переписки и отображаются полупрозрачными (alpha = 0.45).";
        case 1: return @"Блокирует отправку MTProto-экшенов на сервер Telegram. Вы остаетесь скрытым в сети.";
        case 2: return @"Активирует все клиентские возможности Telegram Premium без привязки к серверной подписке.";
        case 3: return @"Устанавливает локальный бейдж NFT-подарка, градиентный фон и паттерн в ваш профиль.";
        case 4: return @"Отображает локальный баланс Telegram Stars во всех интерфейсах клиента.";
        default: return nil;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.textColor = LARRK_ACCENT_PURPLE;
        header.textLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightBold];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        footer.textLabel.textColor = LARRK_TEXT_MUTED;
        footer.textLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightRegular];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LarrkConfig *config = [LarrkConfig shared];
    
    // SECTION 0: Anti-Delete
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return [self createSwitchCellWithTitle:@"Сохранять удаленные сообщения"
                                          subtitle:@"Полупрозрачный вид (alpha = 0.45)"
                                              icon:@"trash.slash.fill"
                                            isOn:config.antiDelete
                                          action:@selector(onAntiDeleteChanged:)];
        } else {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
            cell.backgroundColor = LARRK_CARD_COLOR;
            cell.textLabel.text = @"История удаленных сообщений";
            cell.textLabel.textColor = LARRK_TEXT_PRIMARY;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu сообщ.", (unsigned long)config.deletedMessageIds.count];
            cell.detailTextLabel.textColor = LARRK_ACCENT_CYAN;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
    }
    
    // SECTION 1: Ghost Mode (8 Privacy Toggles)
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:@"Отключить Онлайн-Статус"
                                              subtitle:@"Принудительный offline в MTProto"
                                                  icon:@"eye.slash.fill"
                                                isOn:config.disableOnline
                                              action:@selector(onDisableOnlineChanged:)];
            case 1:
                return [self createSwitchCellWithTitle:@"Отключить статус ввода текста"
                                              subtitle:@"Скрывать 'печатает...'"
                                                  icon:@"pencil.slash"
                                                isOn:config.disableTyping
                                              action:@selector(onDisableTypingChanged:)];
            case 2:
                return [self createSwitchCellWithTitle:@"Отключить запись Видео"
                                              subtitle:@"Скрывать 'записывает видео...'"
                                                  icon:@"video.slash.fill"
                                                isOn:config.disableRecordVideo
                                              action:@selector(onDisableRecordVideoChanged:)];
            case 3:
                return [self createSwitchCellWithTitle:@"Отключить Загрузку Видео"
                                              subtitle:@"Скрывать 'отправляет видео...'"
                                                  icon:@"arrow.up.doc.fill"
                                                isOn:config.disableUploadVideo
                                              action:@selector(onDisableUploadVideoChanged:)];
            case 4:
                return [self createSwitchCellWithTitle:@"Отключить Запись Голосового"
                                              subtitle:@"Скрывать 'записывает голос...'"
                                                  icon:@"mic.slash.fill"
                                                isOn:config.disableRecordVoice
                                              action:@selector(onDisableRecordVoiceChanged:)];
            case 5:
                return [self createSwitchCellWithTitle:@"Отключить Загрузку Голосового"
                                              subtitle:@"Скрывать 'отправляет голос...'"
                                                  icon:@"waveform.slash"
                                                isOn:config.disableUploadVoice
                                              action:@selector(onDisableUploadVoiceChanged:)];
            case 6:
                return [self createSwitchCellWithTitle:@"Отключить Загрузку Фото"
                                              subtitle:@"Скрывать 'отправляет фото...'"
                                                  icon:@"photo.fill"
                                                isOn:config.disableUploadPhoto
                                              action:@selector(onDisableUploadPhotoChanged:)];
            case 7:
                return [self createSwitchCellWithTitle:@"Отключить Загрузку Файлов"
                                              subtitle:@"Скрывать 'отправляет документ...'"
                                                  icon:@"doc.fill"
                                                isOn:config.disableUploadFile
                                              action:@selector(onDisableUploadFileChanged:)];
        }
    }
    
    // SECTION 2: Telegram Premium
    if (indexPath.section == 2) {
        return [self createSwitchCellWithTitle:@"Локальный Telegram Premium"
                                      subtitle:@"Клиентская разблокировка звездочки и фич"
                                          icon:@"star.circle.fill"
                                        isOn:config.localPremium
                                      action:@selector(onLocalPremiumChanged:)];
    }
    
    // SECTION 3: NFT-Подарок и Профиль
    if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            return [self createSwitchCellWithTitle:@"Кастомный NFT-профиль"
                                          subtitle:@"Активировать оформление профиля"
                                              icon:@"sparkles"
                                            isOn:config.customProfileEnabled
                                          action:@selector(onCustomProfileChanged:)];
        } else if (indexPath.row == 1) {
            // Preset picker segment
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.backgroundColor = LARRK_CARD_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, cell.contentView.bounds.size.width - 32, 20)];
            lbl.text = @"Выбор NFT-подарка:";
            lbl.textColor = LARRK_TEXT_PRIMARY;
            lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
            [cell.contentView addSubview:lbl];
            
            NSArray *items = [LarrkConfig nftPresetTitles];
            _nftSegmentControl = [[UISegmentedControl alloc] initWithItems:items];
            _nftSegmentControl.frame = CGRectMake(16, 34, cell.contentView.bounds.size.width - 32, 32);
            _nftSegmentControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            _nftSegmentControl.selectedSegmentTintColor = LARRK_ACCENT_PURPLE;
            [_nftSegmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:11 weight:UIFontWeightBold]} forState:UIControlStateSelected];
            [_nftSegmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName: LARRK_TEXT_MUTED, NSFontAttributeName: [UIFont systemFontOfSize:10.5]} forState:UIControlStateNormal];
            
            NSInteger selIndex = 0;
            for (NSInteger i = 0; i < items.count; i++) {
                if ([items[i] containsString:config.nftPresetName]) {
                    selIndex = i;
                    break;
                }
            }
            _nftSegmentControl.selectedSegmentIndex = selIndex;
            [_nftSegmentControl addTarget:self action:@selector(onNftPresetChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.contentView addSubview:_nftSegmentControl];
            return cell;
        } else if (indexPath.row == 2) {
            // Custom NFT Image picker
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
            cell.backgroundColor = LARRK_CARD_COLOR;
            cell.textLabel.text = @"Кастомное изображение NFT";
            cell.textLabel.textColor = LARRK_TEXT_PRIMARY;
            
            _nftThumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
            _nftThumbnailView.layer.cornerRadius = 8;
            _nftThumbnailView.layer.masksToBounds = YES;
            _nftThumbnailView.contentMode = UIViewContentModeScaleAspectFill;
            _nftThumbnailView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
            
            UIImage *img = [config customNFTImage];
            if (img) {
                _nftThumbnailView.image = img;
            } else {
                _nftThumbnailView.image = [UIImage systemImageNamed:@"photo.badge.plus"];
                _nftThumbnailView.tintColor = LARRK_ACCENT_CYAN;
            }
            cell.accessoryView = _nftThumbnailView;
            return cell;
        } else if (indexPath.row == 3) {
            // Gradient selector
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.backgroundColor = LARRK_CARD_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, cell.contentView.bounds.size.width - 32, 20)];
            lbl.text = @"Градиент фона профиля:";
            lbl.textColor = LARRK_TEXT_PRIMARY;
            lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
            [cell.contentView addSubview:lbl];
            
            NSArray *items = [LarrkConfig gradientPresetTitles];
            _gradientSegmentControl = [[UISegmentedControl alloc] initWithItems:items];
            _gradientSegmentControl.frame = CGRectMake(16, 34, cell.contentView.bounds.size.width - 32, 32);
            _gradientSegmentControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            _gradientSegmentControl.selectedSegmentTintColor = LARRK_ACCENT_PURPLE;
            [_gradientSegmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:10.5 weight:UIFontWeightBold]} forState:UIControlStateSelected];
            [_gradientSegmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName: LARRK_TEXT_MUTED, NSFontAttributeName: [UIFont systemFontOfSize:10.0]} forState:UIControlStateNormal];
            _gradientSegmentControl.selectedSegmentIndex = config.bgGradientIndex;
            [_gradientSegmentControl addTarget:self action:@selector(onGradientChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.contentView addSubview:_gradientSegmentControl];
            return cell;
        } else if (indexPath.row == 4) {
            // Pattern emoji input
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
            cell.backgroundColor = LARRK_CARD_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = @"Паттерн-эмодзи фона:";
            cell.textLabel.textColor = LARRK_TEXT_PRIMARY;
            
            _patternEmojiField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 80, 32)];
            _patternEmojiField.text = config.patternEmoji;
            _patternEmojiField.textColor = [UIColor whiteColor];
            _patternEmojiField.font = [UIFont systemFontOfSize:18];
            _patternEmojiField.textAlignment = NSTextAlignmentRight;
            _patternEmojiField.delegate = self;
            cell.accessoryView = _patternEmojiField;
            return cell;
        } else if (indexPath.row == 5) {
            // Apply button
            return [self createButtonCellWithTitle:@"🚀 Загрузить в профиль локально"
                                             color:LARRK_ACCENT_PURPLE
                                            action:@selector(applyProfileCustomizationAction)];
        } else {
            // Reset button
            return [self createButtonCellWithTitle:@"🗑 Сбросить NFT и оформление профиля"
                                             color:LARRK_DANGER_RED
                                            action:@selector(resetProfileCustomizationAction)];
        }
    }
    
    // SECTION 4: Локальные Telegram Stars ⭐
    if (indexPath.section == 4) {
        if (indexPath.row == 0) {
            return [self createSwitchCellWithTitle:@"Кастомные Telegram Stars"
                                          subtitle:@"Подмена баланса в интерфейсе"
                                              icon:@"star.fill"
                                            isOn:config.customStarsEnabled
                                          action:@selector(onCustomStarsChanged:)];
        } else if (indexPath.row == 1) {
            // Current balance label
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
            cell.backgroundColor = LARRK_CARD_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = @"Текущий локальный баланс:";
            cell.textLabel.textColor = LARRK_TEXT_PRIMARY;
            
            _starsBalanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 140, 32)];
            _starsBalanceLabel.text = [NSString stringWithFormat:@"%ld ⭐", (long)config.localStarsAmount];
            _starsBalanceLabel.textColor = [UIColor colorWithRed:1.0 green:0.82 blue:0.1 alpha:1.0];
            _starsBalanceLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
            _starsBalanceLabel.textAlignment = NSTextAlignmentRight;
            cell.accessoryView = _starsBalanceLabel;
            return cell;
        } else if (indexPath.row == 2) {
            // Amount Input Field
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.backgroundColor = LARRK_CARD_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, 120, 24)];
            lbl.text = @"Число звезд:";
            lbl.textColor = LARRK_TEXT_PRIMARY;
            lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
            [cell.contentView addSubview:lbl];
            
            _starsInputField = [[UITextField alloc] initWithFrame:CGRectMake(cell.contentView.bounds.size.width - 160, 8, 144, 32)];
            _starsInputField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            _starsInputField.keyboardType = UIKeyboardTypeNumberPad;
            _starsInputField.text = [NSString stringWithFormat:@"%ld", (long)config.localStarsAmount];
            _starsInputField.textColor = [UIColor whiteColor];
            _starsInputField.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.8];
            _starsInputField.layer.cornerRadius = 8.0;
            _starsInputField.textAlignment = NSTextAlignmentCenter;
            _starsInputField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
            _starsInputField.delegate = self;
            [cell.contentView addSubview:_starsInputField];
            return cell;
        } else if (indexPath.row == 3) {
            // Quick add buttons
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.backgroundColor = LARRK_CARD_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            CGFloat btnWidth = (cell.contentView.bounds.size.width - 48) / 3.0;
            NSArray *amounts = @[@1000, @10000, @50000];
            NSArray *titles = @[@"+1 000 ⭐", @"+10 000 ⭐", @"+50 000 ⭐"];
            
            for (NSInteger i = 0; i < 3; i++) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                btn.frame = CGRectMake(16 + i * (btnWidth + 8), 6, btnWidth, 34);
                btn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
                [btn setTitle:titles[i] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                btn.backgroundColor = [UIColor colorWithRed:0.20 green:0.23 blue:0.32 alpha:1.0];
                btn.layer.cornerRadius = 8.0;
                btn.tag = [amounts[i] integerValue];
                [btn addTarget:self action:@selector(quickAddStarsAction:) forControlEvents:UIControlEventTouchUpInside];
                [cell.contentView addSubview:btn];
            }
            return cell;
        } else {
            // Set balance & Reset balance buttons inside a single action cell or split
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.backgroundColor = LARRK_CARD_COLOR;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            CGFloat halfW = (cell.contentView.bounds.size.width - 40) / 2.0;
            
            UIButton *setBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            setBtn.frame = CGRectMake(16, 6, halfW, 36);
            setBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
            [setBtn setTitle:@"⭐ Установить" forState:UIControlStateNormal];
            setBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
            setBtn.backgroundColor = [UIColor colorWithRed:0.85 green:0.65 blue:0.05 alpha:1.0];
            setBtn.layer.cornerRadius = 8.0;
            [setBtn addTarget:self action:@selector(applyStarsAmountAction) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:setBtn];
            
            UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            resetBtn.frame = CGRectMake(cell.contentView.bounds.size.width - 16 - halfW, 6, halfW, 36);
            resetBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
            [resetBtn setTitle:@"🗑 Сбросить" forState:UIControlStateNormal];
            resetBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
            resetBtn.backgroundColor = LARRK_DANGER_RED;
            resetBtn.layer.cornerRadius = 8.0;
            [resetBtn addTarget:self action:@selector(resetStarsAction) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:resetBtn];
            
            return cell;
        }
    }
    
    return [UITableViewCell new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3 && (indexPath.row == 1 || indexPath.row == 3)) {
        return 74.0; // Segment control rows
    }
    if (indexPath.section == 4 && indexPath.row == 3) {
        return 48.0; // Quick add row
    }
    if (indexPath.section == 4 && indexPath.row == 4) {
        return 50.0; // Action buttons row
    }
    return 50.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 && indexPath.row == 1) {
        // Clear deleted messages
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Очистить историю"
                                                                       message:@"Вы действительно хотите очистить список сохраненных удаленных сообщений?"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Очистить" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [[LarrkConfig shared] clearDeletedMessages];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self showToast:@"История сообщений очищена" isError:NO];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    if (indexPath.section == 3 && indexPath.row == 2) {
        // Pick custom image
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

#pragma mark - Helper Cell Creators

- (UITableViewCell *)createSwitchCellWithTitle:(NSString *)title subtitle:(NSString *)subtitle icon:(NSString *)iconName isOn:(BOOL)isOn action:(SEL)action {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.backgroundColor = LARRK_CARD_COLOR;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.text = title;
    cell.textLabel.textColor = LARRK_TEXT_PRIMARY;
    cell.textLabel.font = [UIFont systemFontOfSize:14.5 weight:UIFontWeightMedium];
    
    cell.detailTextLabel.text = subtitle;
    cell.detailTextLabel.textColor = LARRK_TEXT_MUTED;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:11.0];
    
    if (iconName.length > 0) {
        UIImage *img = [UIImage systemImageNamed:iconName];
        cell.imageView.image = img;
        cell.imageView.tintColor = LARRK_ACCENT_PURPLE;
    }
    
    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.on = isOn;
    toggle.onTintColor = LARRK_ACCENT_PURPLE;
    [toggle addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    
    return cell;
}

- (UITableViewCell *)createButtonCellWithTitle:(NSString *)title color:(UIColor *)color action:(SEL)action {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = LARRK_CARD_COLOR;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(16, 6, cell.contentView.bounds.size.width - 32, 38);
    btn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = color;
    btn.layer.cornerRadius = 9.0;
    btn.layer.masksToBounds = YES;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:btn];
    
    return cell;
}

#pragma mark - Switch Actions

- (void)onAntiDeleteChanged:(UISwitch *)sender {
    [LarrkConfig shared].antiDelete = sender.isOn;
    [self showToast:sender.isOn ? @"Анти-удаление включено" : @"Анти-удаление выключено" isError:NO];
}

- (void)onDisableOnlineChanged:(UISwitch *)sender {
    [LarrkConfig shared].disableOnline = sender.isOn;
}

- (void)onDisableTypingChanged:(UISwitch *)sender {
    [LarrkConfig shared].disableTyping = sender.isOn;
}

- (void)onDisableRecordVideoChanged:(UISwitch *)sender {
    [LarrkConfig shared].disableRecordVideo = sender.isOn;
}

- (void)onDisableUploadVideoChanged:(UISwitch *)sender {
    [LarrkConfig shared].disableUploadVideo = sender.isOn;
}

- (void)onDisableRecordVoiceChanged:(UISwitch *)sender {
    [LarrkConfig shared].disableRecordVoice = sender.isOn;
}

- (void)onDisableUploadVoiceChanged:(UISwitch *)sender {
    [LarrkConfig shared].disableUploadVoice = sender.isOn;
}

- (void)onDisableUploadPhotoChanged:(UISwitch *)sender {
    [LarrkConfig shared].disableUploadPhoto = sender.isOn;
}

- (void)onDisableUploadFileChanged:(UISwitch *)sender {
    [LarrkConfig shared].disableUploadFile = sender.isOn;
}

- (void)onLocalPremiumChanged:(UISwitch *)sender {
    [LarrkConfig shared].localPremium = sender.isOn;
    [self showToast:sender.isOn ? @"Локальный Premium активирован ⭐" : @"Premium деактивирован" isError:NO];
}

- (void)onCustomProfileChanged:(UISwitch *)sender {
    [LarrkConfig shared].customProfileEnabled = sender.isOn;
}

- (void)onNftPresetChanged:(UISegmentedControl *)sender {
    NSArray *titles = [LarrkConfig nftPresetTitles];
    if (sender.selectedSegmentIndex < titles.count) {
        [LarrkConfig shared].nftPresetName = titles[sender.selectedSegmentIndex];
    }
}

- (void)onGradientChanged:(UISegmentedControl *)sender {
    [LarrkConfig shared].bgGradientIndex = sender.selectedSegmentIndex;
}

#pragma mark - Profile & Stars Actions

- (void)applyProfileCustomizationAction {
    [self.view endEditing:YES];
    LarrkConfig *config = [LarrkConfig shared];
    config.customProfileEnabled = YES;
    if (self.patternEmojiField.text.length > 0) {
        config.patternEmoji = self.patternEmojiField.text;
    }
    [self.tableView reloadData];
    [self showToast:@"NFT-оформление применено к профилю! ✨" isError:NO];
}

- (void)resetProfileCustomizationAction {
    [[LarrkConfig shared] resetProfileCustomization];
    [self.tableView reloadData];
    [self showToast:@"Оформление профиля сброшено 🗑" isError:NO];
}

- (void)onCustomStarsChanged:(UISwitch *)sender {
    [LarrkConfig shared].customStarsEnabled = sender.isOn;
    [self showToast:sender.isOn ? @"Кастомные Telegram Stars включены" : @"Кастомные Telegram Stars выключены" isError:NO];
}

- (void)quickAddStarsAction:(UIButton *)sender {
    LarrkConfig *config = [LarrkConfig shared];
    config.localStarsAmount += sender.tag;
    self.starsBalanceLabel.text = [NSString stringWithFormat:@"%ld ⭐", (long)config.localStarsAmount];
    self.starsInputField.text = [NSString stringWithFormat:@"%ld", (long)config.localStarsAmount];
    [self showToast:[NSString stringWithFormat:@"+%ld ⭐ добавлено к балансу!", (long)sender.tag] isError:NO];
}

- (void)applyStarsAmountAction {
    [self.view endEditing:YES];
    NSInteger val = [self.starsInputField.text integerValue];
    if (val < 0) val = 0;
    [LarrkConfig shared].localStarsAmount = val;
    [LarrkConfig shared].customStarsEnabled = YES;
    self.starsBalanceLabel.text = [NSString stringWithFormat:@"%ld ⭐", (long)val];
    [self.tableView reloadData];
    [self showToast:[NSString stringWithFormat:@"Баланс Stars установлен на %ld ⭐", (long)val] isError:NO];
}

- (void)resetStarsAction {
    [[LarrkConfig shared] resetStars];
    self.starsBalanceLabel.text = @"50000 ⭐";
    self.starsInputField.text = @"50000";
    [self.tableView reloadData];
    [self showToast:@"Баланс Stars сброшен 🗑" isError:NO];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    if (image) {
        [[LarrkConfig shared] saveCustomNFTImage:image];
        [LarrkConfig shared].nftPresetName = @"Custom Image 🖼";
        self.nftThumbnailView.image = image;
        [self.tableView reloadData];
        [self showToast:@"Кастомное изображение NFT сохранено!" isError:NO];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Toast Helper

- (void)showToast:(NSString *)message isError:(BOOL)isError {
    UIView *toast = [[UIView alloc] initWithFrame:CGRectMake(24, 70, self.view.bounds.size.width - 48, 44)];
    toast.backgroundColor = isError ? LARRK_DANGER_RED : [UIColor colorWithRed:0.12 green:0.14 blue:0.20 alpha:0.95];
    toast.layer.cornerRadius = 12.0;
    toast.layer.masksToBounds = YES;
    toast.layer.borderWidth = 1.0;
    toast.layer.borderColor = (isError ? LARRK_DANGER_RED : LARRK_ACCENT_PURPLE).CGColor;
    toast.alpha = 0.0;
    toast.transform = CGAffineTransformMakeTranslation(0, -20);
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:toast.bounds];
    lbl.text = message;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    lbl.textAlignment = NSTextAlignmentCenter;
    [toast addSubview:lbl];
    [self.view addSubview:toast];
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toast.alpha = 1.0;
        toast.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:1.8 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toast.alpha = 0.0;
            toast.transform = CGAffineTransformMakeTranslation(0, -10);
        } completion:^(BOOL fin) {
            [toast removeFromSuperview];
        }];
    }];
}

@end
