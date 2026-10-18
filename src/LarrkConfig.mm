//
//  LarrkConfig.mm
//  LarrkMod
//
//  Created for Swiftgram (app.swiftgram.ios)
//  Copyright © 2026 LarrkMod. All rights reserved.
//

#import "LarrkConfig.h"

static NSString *const kLarrkAntiDeleteKey          = @"LarrkMod_antiDelete";
static NSString *const kLarrkDeletedMessagesKey     = @"LarrkMod_deletedMessages";

static NSString *const kLarrkDisableOnlineKey       = @"LarrkMod_disableOnline";
static NSString *const kLarrkDisableTypingKey       = @"LarrkMod_disableTyping";
static NSString *const kLarrkDisableRecordVideoKey  = @"LarrkMod_disableRecordVideo";
static NSString *const kLarrkDisableUploadVideoKey  = @"LarrkMod_disableUploadVideo";
static NSString *const kLarrkDisableRecordVoiceKey  = @"LarrkMod_disableRecordVoice";
static NSString *const kLarrkDisableUploadVoiceKey  = @"LarrkMod_disableUploadVoice";
static NSString *const kLarrkDisableUploadPhotoKey  = @"LarrkMod_disableUploadPhoto";
static NSString *const kLarrkDisableUploadFileKey   = @"LarrkMod_disableUploadFile";

static NSString *const kLarrkLocalPremiumKey        = @"LarrkMod_localPremium";

static NSString *const kLarrkCustomProfileKey       = @"LarrkMod_customProfileEnabled";
static NSString *const kLarrkNFTPresetNameKey       = @"LarrkMod_nftPresetName";
static NSString *const kLarrkBgGradientIndexKey     = @"LarrkMod_bgGradientIndex";
static NSString *const kLarrkPatternEmojiKey        = @"LarrkMod_patternEmoji";

static NSString *const kLarrkCustomStarsKey         = @"LarrkMod_customStarsEnabled";
static NSString *const kLarrkLocalStarsAmountKey    = @"LarrkMod_localStarsAmount";

@interface LarrkConfig () {
    NSMutableSet<NSNumber *> *_deletedMessageIds;
    dispatch_queue_t _syncQueue;
}
@end

@implementation LarrkConfig

+ (instancetype)shared {
    static LarrkConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LarrkConfig alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _syncQueue = dispatch_queue_create("com.larrkmod.config.sync", DISPATCH_QUEUE_SERIAL);
        [self loadDeletedMessages];
    }
    return self;
}

#pragma mark - Anti-Delete

- (BOOL)antiDelete {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkAntiDeleteKey];
}

- (void)setAntiDelete:(BOOL)antiDelete {
    [[NSUserDefaults standardUserDefaults] setBool:antiDelete forKey:kLarrkAntiDeleteKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadDeletedMessages {
    NSArray *saved = [[NSUserDefaults standardUserDefaults] arrayForKey:kLarrkDeletedMessagesKey];
    if (saved) {
        _deletedMessageIds = [NSMutableSet setWithArray:saved];
    } else {
        _deletedMessageIds = [NSMutableSet set];
    }
}

- (void)saveDeletedMessages {
    dispatch_async(_syncQueue, ^{
        NSArray *array = [self->_deletedMessageIds allObjects];
        // Keep within last 5000 messages to save memory
        if (array.count > 5000) {
            array = [array subarrayWithRange:NSMakeRange(array.count - 5000, 5000)];
            self->_deletedMessageIds = [NSMutableSet setWithArray:array];
        }
        [[NSUserDefaults standardUserDefaults] setObject:array forKey:kLarrkDeletedMessagesKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
}

- (NSMutableSet<NSNumber *> *)deletedMessageIds {
    return _deletedMessageIds;
}

- (void)markMessageAsDeleted:(int64_t)messageId {
    if (messageId == 0) return;
    dispatch_sync(_syncQueue, ^{
        [_deletedMessageIds addObject:@(messageId)];
    });
    [self saveDeletedMessages];
}

- (BOOL)isMessageDeleted:(int64_t)messageId {
    if (messageId == 0) return NO;
    __block BOOL contains = NO;
    dispatch_sync(_syncQueue, ^{
        contains = [_deletedMessageIds containsObject:@(messageId)];
    });
    return contains;
}

- (void)clearDeletedMessages {
    dispatch_sync(_syncQueue, ^{
        [_deletedMessageIds removeAllObjects];
    });
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLarrkDeletedMessagesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Ghost Mode (8 Privacy Toggles)

- (BOOL)disableOnline {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkDisableOnlineKey];
}

- (void)setDisableOnline:(BOOL)disableOnline {
    [[NSUserDefaults standardUserDefaults] setBool:disableOnline forKey:kLarrkDisableOnlineKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)disableTyping {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkDisableTypingKey];
}

- (void)setDisableTyping:(BOOL)disableTyping {
    [[NSUserDefaults standardUserDefaults] setBool:disableTyping forKey:kLarrkDisableTypingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)disableRecordVideo {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkDisableRecordVideoKey];
}

- (void)setDisableRecordVideo:(BOOL)disableRecordVideo {
    [[NSUserDefaults standardUserDefaults] setBool:disableRecordVideo forKey:kLarrkDisableRecordVideoKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)disableUploadVideo {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkDisableUploadVideoKey];
}

- (void)setDisableUploadVideo:(BOOL)disableUploadVideo {
    [[NSUserDefaults standardUserDefaults] setBool:disableUploadVideo forKey:kLarrkDisableUploadVideoKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)disableRecordVoice {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkDisableRecordVoiceKey];
}

- (void)setDisableRecordVoice:(BOOL)disableRecordVoice {
    [[NSUserDefaults standardUserDefaults] setBool:disableRecordVoice forKey:kLarrkDisableRecordVoiceKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)disableUploadVoice {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkDisableUploadVoiceKey];
}

- (void)setDisableUploadVoice:(BOOL)disableUploadVoice {
    [[NSUserDefaults standardUserDefaults] setBool:disableUploadVoice forKey:kLarrkDisableUploadVoiceKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)disableUploadPhoto {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkDisableUploadPhotoKey];
}

- (void)setDisableUploadPhoto:(BOOL)disableUploadPhoto {
    [[NSUserDefaults standardUserDefaults] setBool:disableUploadPhoto forKey:kLarrkDisableUploadPhotoKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)disableUploadFile {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkDisableUploadFileKey];
}

- (void)setDisableUploadFile:(BOOL)disableUploadFile {
    [[NSUserDefaults standardUserDefaults] setBool:disableUploadFile forKey:kLarrkDisableUploadFileKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Local Telegram Premium

- (BOOL)localPremium {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkLocalPremiumKey];
}

- (void)setLocalPremium:(BOOL)localPremium {
    [[NSUserDefaults standardUserDefaults] setBool:localPremium forKey:kLarrkLocalPremiumKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Local NFT Profile

- (BOOL)customProfileEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkCustomProfileKey];
}

- (void)setCustomProfileEnabled:(BOOL)customProfileEnabled {
    [[NSUserDefaults standardUserDefaults] setBool:customProfileEnabled forKey:kLarrkCustomProfileKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)nftPresetName {
    NSString *val = [[NSUserDefaults standardUserDefaults] stringForKey:kLarrkNFTPresetNameKey];
    return val ?: @"Pool Float";
}

- (void)setNftPresetName:(NSString *)nftPresetName {
    [[NSUserDefaults standardUserDefaults] setObject:nftPresetName forKey:kLarrkNFTPresetNameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)bgGradientIndex {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kLarrkBgGradientIndexKey];
}

- (void)setBgGradientIndex:(NSInteger)bgGradientIndex {
    [[NSUserDefaults standardUserDefaults] setInteger:bgGradientIndex forKey:kLarrkBgGradientIndexKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)patternEmoji {
    NSString *val = [[NSUserDefaults standardUserDefaults] stringForKey:kLarrkPatternEmojiKey];
    return val ?: @"⚡";
}

- (void)setPatternEmoji:(NSString *)patternEmoji {
    [[NSUserDefaults standardUserDefaults] setObject:patternEmoji forKey:kLarrkPatternEmojiKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)customNFTImagePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    return [documentsDirectory stringByAppendingPathComponent:@"larrk_nft.png"];
}

- (nullable UIImage *)customNFTImage {
    NSString *path = [self customNFTImagePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return [UIImage imageWithContentsOfFile:path];
    }
    return nil;
}

- (BOOL)saveCustomNFTImage:(UIImage *)image {
    if (!image) return NO;
    NSData *data = UIImagePNGRepresentation(image);
    if (!data) return NO;
    return [data writeToFile:[self customNFTImagePath] atomically:YES];
}

- (void)resetProfileCustomization {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLarrkCustomProfileKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLarrkNFTPresetNameKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLarrkBgGradientIndexKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLarrkPatternEmojiKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *path = [self customNFTImagePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

#pragma mark - Local Telegram Stars

- (BOOL)customStarsEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLarrkCustomStarsKey];
}

- (void)setCustomStarsEnabled:(BOOL)customStarsEnabled {
    [[NSUserDefaults standardUserDefaults] setBool:customStarsEnabled forKey:kLarrkCustomStarsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)localStarsAmount {
    NSInteger val = [[NSUserDefaults standardUserDefaults] integerForKey:kLarrkLocalStarsAmountKey];
    return val > 0 ? val : 50000;
}

- (void)setLocalStarsAmount:(NSInteger)localStarsAmount {
    [[NSUserDefaults standardUserDefaults] setInteger:localStarsAmount forKey:kLarrkLocalStarsAmountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)resetStars {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLarrkCustomStarsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLarrkLocalStarsAmountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Gradients & Presets

+ (NSArray<NSString *> *)gradientPresetTitles {
    return @[
        @"Cyber Purple 🟣",
        @"Ocean Blue 🔵",
        @"Golden Star 🟡",
        @"Emerald Neon 🟢"
    ];
}

+ (NSArray<NSString *> *)nftPresetTitles {
    return @[
        @"Pool Float 🛟",
        @"Plush Pepe 🐸",
        @"Durov's Cap 🧢",
        @"Astral Shard 💎",
        @"Custom Image 🖼"
    ];
}

- (NSArray<UIColor *> *)currentGradientColors {
    switch (self.bgGradientIndex) {
        case 1: // Ocean Blue
            return @[
                [UIColor colorWithRed:0.05 green:0.40 blue:0.95 alpha:1.0],
                [UIColor colorWithRed:0.02 green:0.18 blue:0.55 alpha:1.0]
            ];
        case 2: // Golden Star
            return @[
                [UIColor colorWithRed:0.95 green:0.75 blue:0.10 alpha:1.0],
                [UIColor colorWithRed:0.70 green:0.40 blue:0.05 alpha:1.0]
            ];
        case 3: // Emerald Neon
            return @[
                [UIColor colorWithRed:0.05 green:0.85 blue:0.55 alpha:1.0],
                [UIColor colorWithRed:0.02 green:0.45 blue:0.30 alpha:1.0]
            ];
        case 0: // Cyber Purple
        default:
            return @[
                [UIColor colorWithRed:0.55 green:0.20 blue:0.95 alpha:1.0],
                [UIColor colorWithRed:0.20 green:0.05 blue:0.55 alpha:1.0]
            ];
    }
}

@end
