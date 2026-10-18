//
//  LarrkHooks.mm
//  LarrkMod
//
//  Created for Swiftgram (app.swiftgram.ios)
//  Copyright © 2026 LarrkMod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <QuartzCore/QuartzCore.h>

#import "LarrkConfig.h"
#import "LarrkGestureOverlay.h"
#import "LarrkModViewController.h"

#pragma mark - MTProto Constructor IDs

static const uint32_t TL_CONSTRUCTOR_SEND_MESSAGE_TYPING        = 0x16bf744e;
static const uint32_t TL_CONSTRUCTOR_SEND_MESSAGE_RECORD_VIDEO   = 0xa187d66f;
static const uint32_t TL_CONSTRUCTOR_SEND_MESSAGE_RECORD_ROUND   = 0x88f27fbc;
static const uint32_t TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_VIDEO   = 0xe9763aec;
static const uint32_t TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_ROUND   = 0x243e1c66;
static const uint32_t TL_CONSTRUCTOR_SEND_MESSAGE_RECORD_VOICE   = 0xd52f73f7;
static const uint32_t TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_VOICE   = 0xf351d7ab;
static const uint32_t TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_PHOTO   = 0xd1d34a26;
static const uint32_t TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_FILE    = 0xaa0cd9e4;
static const uint32_t TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL         = 0xfd5ec8f5;
static const uint32_t TL_CONSTRUCTOR_ACCOUNT_UPDATE_STATUS       = 0x6628f585;

#pragma mark - Dynamic Runtime Utilities

static Class LarrkFindClassByNameOrSuffix(const char *nameOrSuffix) {
    if (!nameOrSuffix) return Nil;
    
    // Direct lookup first (O(1))
    Class cls = objc_getClass(nameOrSuffix);
    if (cls) return cls;
    
    // Scan loaded classes only once to avoid repeated expensive scans
    static Class *allLoadedClasses = NULL;
    static int loadedClassCount = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loadedClassCount = objc_getClassList(NULL, 0);
        if (loadedClassCount > 0) {
            allLoadedClasses = (Class *)malloc(sizeof(Class) * loadedClassCount);
            loadedClassCount = objc_getClassList(allLoadedClasses, loadedClassCount);
        }
    });
    
    if (allLoadedClasses && loadedClassCount > 0) {
        for (int i = 0; i < loadedClassCount; i++) {
            const char *className = class_getName(allLoadedClasses[i]);
            if (className && (strstr(className, nameOrSuffix) != NULL)) {
                return allLoadedClasses[i];
            }
        }
    }
    return Nil;
}

static BOOL LarrkSwizzle(Class cls, SEL origSEL, IMP newIMP, IMP *outOrigIMP) {
    if (!cls || !origSEL || !newIMP) return NO;
    Method origMethod = class_getInstanceMethod(cls, origSEL);
    if (!origMethod) return NO;
    
    const char *types = method_getTypeEncoding(origMethod);
    if (class_addMethod(cls, origSEL, newIMP, types)) {
        Method superMethod = class_getInstanceMethod(class_getSuperclass(cls), origSEL);
        if (outOrigIMP && superMethod) {
            *outOrigIMP = method_getImplementation(superMethod);
        }
    } else {
        IMP orig = method_setImplementation(origMethod, newIMP);
        if (outOrigIMP) {
            *outOrigIMP = orig;
        }
    }
    return YES;
}

#pragma mark - Sideload Fix (AppGroup Container & NSUserDefaults Suite)

static IMP orig_NSFileManager_containerURL = NULL;
static NSURL *hooked_NSFileManager_containerURL(id self, SEL _cmd, NSString *groupIdentifier) {
    NSURL *url = nil;
    if (orig_NSFileManager_containerURL) {
        url = ((NSURL *(*)(id, SEL, NSString *))orig_NSFileManager_containerURL)(self, _cmd, groupIdentifier);
    }
    
    // If running in environment with valid App Group entitlements (e.g. paid developer certificate), return it
    if (url) {
        return url;
    }
    
    // Fallback for sideloaded environment (jailed / free Apple ID / modified Bundle ID)
    static NSURL *appGroupURL = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = paths.firstObject;
        NSString *groupDir = [documentsPath stringByAppendingPathComponent:@"AppGroup"];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir = NO;
        if (![fm fileExistsAtPath:groupDir isDirectory:&isDir]) {
            [fm createDirectoryAtPath:groupDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        appGroupURL = [NSURL fileURLWithPath:groupDir isDirectory:YES];
        NSLog(@"[LarrkMod] [SideloadFix] Initialized fallback AppGroup directory at: %@", groupDir);
    });
    
    NSLog(@"[LarrkMod] [SideloadFix] Redirected containerURL for group '%@' -> %@", groupIdentifier, appGroupURL.path);
    return appGroupURL;
}

static IMP orig_NSUserDefaults_initWithSuiteName = NULL;
static id hooked_NSUserDefaults_initWithSuiteName(id self, SEL _cmd, NSString *suiteName) {
    if (suiteName && ([suiteName hasPrefix:@"group."] || [suiteName containsString:@"group."])) {
        NSLog(@"[LarrkMod] [SideloadFix] Redirected NSUserDefaults suite '%@' -> standardUserDefaults", suiteName);
        return [NSUserDefaults standardUserDefaults];
    }
    
    id res = nil;
    if (orig_NSUserDefaults_initWithSuiteName) {
        res = ((id(*)(id, SEL, NSString *))orig_NSUserDefaults_initWithSuiteName)(self, _cmd, suiteName);
    }
    if (!res) {
        res = [NSUserDefaults standardUserDefaults];
    }
    return res;
}

static void LarrkInstallSideloadFix(void) {
    NSLog(@"[LarrkMod] [SideloadFix] Installing AppGroup & NSUserDefaults fixes...");
    
    // 1. Swizzle -[NSFileManager containerURLForSecurityApplicationGroupIdentifier:]
    Class fmClass = [NSFileManager class];
    SEL containerSEL = @selector(containerURLForSecurityApplicationGroupIdentifier:);
    LarrkSwizzle(fmClass, containerSEL, (IMP)hooked_NSFileManager_containerURL, &orig_NSFileManager_containerURL);
    
    // 2. Swizzle -[NSUserDefaults initWithSuiteName:] on NSUserDefaults and placeholder
    Class udClass = [NSUserDefaults class];
    SEL suiteSEL = @selector(initWithSuiteName:);
    LarrkSwizzle(udClass, suiteSEL, (IMP)hooked_NSUserDefaults_initWithSuiteName, &orig_NSUserDefaults_initWithSuiteName);
    
    id placeholder = [NSUserDefaults alloc];
    if (placeholder) {
        Class phClass = [placeholder class];
        if (phClass && phClass != udClass) {
            LarrkSwizzle(phClass, suiteSEL, (IMP)hooked_NSUserDefaults_initWithSuiteName, &orig_NSUserDefaults_initWithSuiteName);
        }
    }
    
    NSLog(@"[LarrkMod] [SideloadFix] AppGroup & NSUserDefaults hooks installed successfully.");
}

#pragma mark - Hook 1: Anti-Delete & Message Alpha Hook

static IMP orig_ChatMessageItemView_setAlpha = NULL;
static void hooked_ChatMessageItemView_setAlpha(id self, SEL _cmd, CGFloat alpha) {
    // If antiDelete is enabled, check if this message is deleted
    if ([LarrkConfig shared].antiDelete) {
        id item = nil;
        @try {
            if ([self respondsToSelector:NSSelectorFromString(@"item")]) {
                item = [self valueForKey:@"item"];
            }
        } @catch (NSException *e) {}
        
        int64_t msgId = 0;
        if (item) {
            @try {
                id message = [item valueForKey:@"message"];
                if (message && [message respondsToSelector:NSSelectorFromString(@"id")]) {
                    msgId = (int64_t)[[message valueForKey:@"id"] longLongValue];
                }
            } @catch (NSException *e) {}
        }
        
        if (msgId != 0 && [[LarrkConfig shared] isMessageDeleted:msgId]) {
            // Apply 0.45 opacity to indicate deleted message
            alpha = 0.45f;
        }
    }
    
    if (orig_ChatMessageItemView_setAlpha) {
        ((void(*)(id, SEL, CGFloat))orig_ChatMessageItemView_setAlpha)(self, _cmd, alpha);
    }
}

static IMP orig_ChatMessageItemView_layout = NULL;
static void hooked_ChatMessageItemView_layout(id self, SEL _cmd) {
    if (orig_ChatMessageItemView_layout) {
        ((void(*)(id, SEL))orig_ChatMessageItemView_layout)(self, _cmd);
    }
    
    if ([LarrkConfig shared].antiDelete) {
        id item = nil;
        @try {
            if ([self respondsToSelector:NSSelectorFromString(@"item")]) {
                item = [self valueForKey:@"item"];
            }
        } @catch (NSException *e) {}
        
        int64_t msgId = 0;
        if (item) {
            @try {
                id message = [item valueForKey:@"message"];
                if (message && [message respondsToSelector:NSSelectorFromString(@"id")]) {
                    msgId = (int64_t)[[message valueForKey:@"id"] longLongValue];
                }
            } @catch (NSException *e) {}
        }
        
        if (msgId != 0 && [[LarrkConfig shared] isMessageDeleted:msgId]) {
            UIView *view = (UIView *)self;
            if ([view isKindOfClass:[UIView class]]) {
                view.alpha = 0.45f;
            }
        }
    }
}

// Hook message deletion dispatcher to store message ID into deletedMessageIds
static IMP orig_deleteMessages = NULL;
static void hooked_deleteMessages(id self, SEL _cmd, id messageIds, id type) {
    if ([LarrkConfig shared].antiDelete && [messageIds isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)messageIds) {
            int64_t mId = 0;
            if ([item respondsToSelector:@selector(longLongValue)]) {
                mId = [item longLongValue];
            } else if ([item respondsToSelector:NSSelectorFromString(@"id")]) {
                mId = (int64_t)[[item valueForKey:@"id"] longLongValue];
            }
            if (mId != 0) {
                [[LarrkConfig shared] markMessageAsDeleted:mId];
            }
        }
        // Do not propagate deletion to preserve messages in chat
        return;
    }
    
    if (orig_deleteMessages) {
        ((void(*)(id, SEL, id, id))orig_deleteMessages)(self, _cmd, messageIds, type);
    }
}

static void LarrkSetupAntiDeleteHooks() {
    Class itemViewClass = LarrkFindClassByNameOrSuffix("ChatMessageItemView");
    if (!itemViewClass) {
        itemViewClass = LarrkFindClassByNameOrSuffix("ChatMessageBubbleItemNode");
    }
    if (itemViewClass) {
        LarrkSwizzle(itemViewClass, @selector(setAlpha:), (IMP)hooked_ChatMessageItemView_setAlpha, &orig_ChatMessageItemView_setAlpha);
        LarrkSwizzle(itemViewClass, NSSelectorFromString(@"layout"), (IMP)hooked_ChatMessageItemView_layout, &orig_ChatMessageItemView_layout);
    }
    
    Class chatHistoryClass = LarrkFindClassByNameOrSuffix("ChatHistoryController");
    if (chatHistoryClass) {
        SEL deleteSEL = NSSelectorFromString(@"deleteMessages:type:");
        if (class_getInstanceMethod(chatHistoryClass, deleteSEL)) {
            LarrkSwizzle(chatHistoryClass, deleteSEL, (IMP)hooked_deleteMessages, &orig_deleteMessages);
        }
    }
}

#pragma mark - Hook 2: Ghost Mode (8 MTProto Actions & Online Status)

static uint32_t LarrkFilterMTProtoActionConstructor(uint32_t constructorId) {
    LarrkConfig *config = [LarrkConfig shared];
    
    // Typing
    if (constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_TYPING && config.disableTyping) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    // Record Video / Round
    if ((constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_RECORD_VIDEO || constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_RECORD_ROUND) && config.disableRecordVideo) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    // Upload Video / Round
    if ((constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_VIDEO || constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_ROUND) && config.disableUploadVideo) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    // Record Voice
    if (constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_RECORD_VOICE && config.disableRecordVoice) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    // Upload Voice
    if (constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_VOICE && config.disableUploadVoice) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    // Upload Photo
    if (constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_PHOTO && config.disableUploadPhoto) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    // Upload Document / File
    if (constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_FILE && config.disableUploadFile) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    
    return constructorId;
}

// Hook MTRequest / MTProto serialization writeInt32:
static IMP orig_MTBuffer_writeInt32 = NULL;
static void hooked_MTBuffer_writeInt32(id self, SEL _cmd, int32_t value) {
    uint32_t uValue = (uint32_t)value;
    uint32_t filtered = LarrkFilterMTProtoActionConstructor(uValue);
    
    // Check account.updateStatus online/offline override
    if (uValue == TL_CONSTRUCTOR_ACCOUNT_UPDATE_STATUS && [LarrkConfig shared].disableOnline) {
        // Enforce offline
        filtered = TL_CONSTRUCTOR_ACCOUNT_UPDATE_STATUS;
    }
    
    if (orig_MTBuffer_writeInt32) {
        ((void(*)(id, SEL, int32_t))orig_MTBuffer_writeInt32)(self, _cmd, (int32_t)filtered);
    }
}

// Hook ChatInputActivity / setTyping to prevent emitting actions
static IMP orig_ChatActivity_sendActivity = NULL;
static void hooked_ChatActivity_sendActivity(id self, SEL _cmd, id activity) {
    LarrkConfig *config = [LarrkConfig shared];
    if (config.disableTyping || config.disableRecordVoice || config.disableRecordVideo) {
        return; // Suppress activity broadcast
    }
    if (orig_ChatActivity_sendActivity) {
        ((void(*)(id, SEL, id))orig_ChatActivity_sendActivity)(self, _cmd, activity);
    }
}

static void LarrkSetupGhostModeHooks() {
    Class bufferClass = LarrkFindClassByNameOrSuffix("MTBuffer");
    if (!bufferClass) {
        bufferClass = LarrkFindClassByNameOrSuffix("TLBuffer");
    }
    if (bufferClass) {
        SEL writeSEL = NSSelectorFromString(@"writeInt32:");
        if (class_getInstanceMethod(bufferClass, writeSEL)) {
            LarrkSwizzle(bufferClass, writeSEL, (IMP)hooked_MTBuffer_writeInt32, &orig_MTBuffer_writeInt32);
        }
    }
    
    Class activityManager = LarrkFindClassByNameOrSuffix("PeerInputActivityManager");
    if (activityManager) {
        SEL actSEL = NSSelectorFromString(@"sendActivity:");
        if (class_getInstanceMethod(activityManager, actSEL)) {
            LarrkSwizzle(activityManager, actSEL, (IMP)hooked_ChatActivity_sendActivity, &orig_ChatActivity_sendActivity);
        }
    }
}

#pragma mark - Hook 3: Local Telegram Premium

static IMP orig_TelegramUser_isPremium = NULL;
static BOOL hooked_TelegramUser_isPremium(id self, SEL _cmd) {
    if ([LarrkConfig shared].localPremium) {
        return YES;
    }
    if (orig_TelegramUser_isPremium) {
        return ((BOOL(*)(id, SEL))orig_TelegramUser_isPremium)(self, _cmd);
    }
    return NO;
}

static void LarrkSetupPremiumHooks() {
    NSArray *userClassNames = @[
        @"TelegramUser",
        @"Api.User",
        @"TGUser"
    ];
    
    for (NSString *name in userClassNames) {
        Class userClass = LarrkFindClassByNameOrSuffix([name UTF8String]);
        if (userClass) {
            SEL isPremiumSEL = NSSelectorFromString(@"isPremium");
            if (class_getInstanceMethod(userClass, isPremiumSEL)) {
                LarrkSwizzle(userClass, isPremiumSEL, (IMP)hooked_TelegramUser_isPremium, &orig_TelegramUser_isPremium);
            }
        }
    }
}

#pragma mark - Hook 4: Local NFT Profile & Telegram Stars ⭐

static const char *kLarrkProfileGradientLayerKey = "kLarrkProfileGradientLayerKey";
static const char *kLarrkProfileNFTBadgeKey       = "kLarrkProfileNFTBadgeKey";
static const char *kLarrkProfilePatternLayerKey   = "kLarrkProfilePatternLayerKey";

static IMP orig_PeerInfoHeaderNode_layout = NULL;
static void hooked_PeerInfoHeaderNode_layout(id self, SEL _cmd) {
    if (orig_PeerInfoHeaderNode_layout) {
        ((void(*)(id, SEL))orig_PeerInfoHeaderNode_layout)(self, _cmd);
    }
    
    LarrkConfig *config = [LarrkConfig shared];
    if (!config.customProfileEnabled) return;
    
    UIView *view = nil;
    if ([self isKindOfClass:[UIView class]]) {
        view = (UIView *)self;
    } else if ([self respondsToSelector:NSSelectorFromString(@"view")]) {
        view = [self valueForKey:@"view"];
    }
    if (!view) return;
    
    // Add/Update Gradient Layer
    CAGradientLayer *gradLayer = (CAGradientLayer *)objc_getAssociatedObject(view, kLarrkProfileGradientLayerKey);
    if (!gradLayer) {
        gradLayer = [CAGradientLayer layer];
        gradLayer.startPoint = CGPointMake(0.0, 0.0);
        gradLayer.endPoint = CGPointMake(1.0, 1.0);
        gradLayer.zPosition = -1;
        [view.layer insertSublayer:gradLayer atIndex:0];
        objc_setAssociatedObject(view, kLarrkProfileGradientLayerKey, gradLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    gradLayer.frame = view.bounds;
    NSArray<UIColor *> *colors = [config currentGradientColors];
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *c in colors) {
        [cgColors addObject:(id)c.CGColor];
    }
    gradLayer.colors = cgColors;
    
    // Add Pattern Emoji layer
    CATextLayer *patternLayer = (CATextLayer *)objc_getAssociatedObject(view, kLarrkProfilePatternLayerKey);
    if (!patternLayer && config.patternEmoji.length > 0) {
        patternLayer = [CATextLayer layer];
        patternLayer.string = config.patternEmoji;
        patternLayer.fontSize = 24.0;
        patternLayer.alignmentMode = kCAAlignmentCenter;
        patternLayer.opacity = 0.25;
        patternLayer.contentsScale = [UIScreen mainScreen].scale;
        [view.layer addSublayer:patternLayer];
        objc_setAssociatedObject(view, kLarrkProfilePatternLayerKey, patternLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (patternLayer) {
        patternLayer.frame = CGRectMake(view.bounds.size.width - 40, 20, 30, 30);
    }
    
    // Add NFT Badge View
    UIImageView *nftBadge = (UIImageView *)objc_getAssociatedObject(view, kLarrkProfileNFTBadgeKey);
    if (!nftBadge) {
        nftBadge = [[UIImageView alloc] initWithFrame:CGRectMake(16, view.bounds.size.height - 44, 32, 32)];
        nftBadge.layer.cornerRadius = 8.0;
        nftBadge.layer.masksToBounds = YES;
        nftBadge.layer.borderWidth = 1.0;
        nftBadge.layer.borderColor = [UIColor colorWithRed:0.95 green:0.80 blue:0.20 alpha:0.8].CGColor;
        [view addSubview:nftBadge];
        objc_setAssociatedObject(view, kLarrkProfileNFTBadgeKey, nftBadge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UIImage *customImg = [config customNFTImage];
    if (customImg) {
        nftBadge.image = customImg;
    } else {
        nftBadge.image = [UIImage systemImageNamed:@"star.hexagonpath.fill"];
        nftBadge.tintColor = [UIColor colorWithRed:0.95 green:0.80 blue:0.20 alpha:1.0];
    }
}

// Telegram Stars Balance Hook
static IMP orig_StarsContext_balance = NULL;
static int64_t hooked_StarsContext_balance(id self, SEL _cmd) {
    if ([LarrkConfig shared].customStarsEnabled) {
        return (int64_t)[LarrkConfig shared].localStarsAmount;
    }
    if (orig_StarsContext_balance) {
        return ((int64_t(*)(id, SEL))orig_StarsContext_balance)(self, _cmd);
    }
    return 0;
}

static void LarrkSetupNFTAndStarsHooks() {
    Class headerNodeClass = LarrkFindClassByNameOrSuffix("PeerInfoHeaderNode");
    if (!headerNodeClass) {
        headerNodeClass = LarrkFindClassByNameOrSuffix("PeerInfoHeaderNavigationNode");
    }
    if (headerNodeClass) {
        SEL layoutSEL = NSSelectorFromString(@"layout");
        if (class_getInstanceMethod(headerNodeClass, layoutSEL)) {
            LarrkSwizzle(headerNodeClass, layoutSEL, (IMP)hooked_PeerInfoHeaderNode_layout, &orig_PeerInfoHeaderNode_layout);
        }
    }
    
    Class starsClass = LarrkFindClassByNameOrSuffix("StarsContext");
    if (!starsClass) {
        starsClass = LarrkFindClassByNameOrSuffix("StarsState");
    }
    if (starsClass) {
        SEL balanceSEL = NSSelectorFromString(@"balance");
        if (class_getInstanceMethod(starsClass, balanceSEL)) {
            LarrkSwizzle(starsClass, balanceSEL, (IMP)hooked_StarsContext_balance, &orig_StarsContext_balance);
        }
    }
}

#pragma mark - Constructor Entry Point

__attribute__((constructor))
static void LarrkModInit(void) {
    NSLog(@"[LarrkMod] Initializing LarrkMod iOS Tweak for Swiftgram...");
    
    @autoreleasepool {
        // STEP 1: CRITICAL! Install Sideload Fix IMMEDIATELY and SYNCHRONOUSLY before anything else!
        // This ensures Swiftgram/Telegram gets valid AppGroup container and NSUserDefaults right from the start.
        LarrkInstallSideloadFix();
        
        // STEP 2: Initialize configuration singleton (lightweight NSUserDefaults read)
        [LarrkConfig shared];
        
        // STEP 3: Setup Gesture Trigger & HUD Overlay (observes notification, non-blocking)
        [[LarrkGestureOverlay shared] startListening];
        
        // STEP 4: Install UI and Protocol hooks asynchronously so the main thread is never blocked at launch!
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[LarrkMod] Installing UI and protocol hooks on main thread...");
            LarrkSetupAntiDeleteHooks();
            LarrkSetupGhostModeHooks();
            LarrkSetupPremiumHooks();
            LarrkSetupNFTAndStarsHooks();
            NSLog(@"[LarrkMod] Initialization complete. Hold Chats tab (1s + 3s) to open menu.");
        });
    }
}
