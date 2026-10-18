//
//  LarrkHooks.mm
//  LarrkMod
//
//  Created for Swiftgram (app.swiftgram.ios)
//  Copyright © 2026 LarrkMod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <QuartzCore/QuartzCore.h>

#import "fishhook.h"
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

#pragma mark - Runtime Swizzling Utilities

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

static BOOL LarrkSwizzleClassMethod(Class cls, SEL origSEL, IMP newIMP, IMP *outOrigIMP) {
    if (!cls || !origSEL || !newIMP) return NO;
    Class metaClass = object_getClass((id)cls);
    return LarrkSwizzle(metaClass, origSEL, newIMP, outOrigIMP);
}

#pragma mark - 1. Bundle & FCAlertView Crash Protection (SIGABRT Fix)

static IMP orig_NSBundle_bundleWithURL = NULL;
static id hooked_NSBundle_bundleWithURL(id self, SEL _cmd, NSURL *url) {
    if (!url) return nil;
    if (orig_NSBundle_bundleWithURL) {
        return ((id(*)(id, SEL, NSURL *))orig_NSBundle_bundleWithURL)(self, _cmd, url);
    }
    return nil;
}

static IMP orig_NSBundle_bundleWithPath = NULL;
static id hooked_NSBundle_bundleWithPath(id self, SEL _cmd, NSString *path) {
    if (!path || path.length == 0) return nil;
    if (orig_NSBundle_bundleWithPath) {
        return ((id(*)(id, SEL, NSString *))orig_NSBundle_bundleWithPath)(self, _cmd, path);
    }
    return nil;
}

static IMP orig_NSBundle_initWithURL = NULL;
static id hooked_NSBundle_initWithURL(id self, SEL _cmd, NSURL *url) {
    if (!url) return nil;
    if (orig_NSBundle_initWithURL) {
        return ((id(*)(id, SEL, NSURL *))orig_NSBundle_initWithURL)(self, _cmd, url);
    }
    return nil;
}

static IMP orig_NSBundle_initWithPath = NULL;
static id hooked_NSBundle_initWithPath(id self, SEL _cmd, NSString *path) {
    if (!path || path.length == 0) return nil;
    if (orig_NSBundle_initWithPath) {
        return ((id(*)(id, SEL, NSString *))orig_NSBundle_initWithPath)(self, _cmd, path);
    }
    return nil;
}

// FCAlertView dummy stubs to prevent third-party alert crashes
static void dummy_FCAlertView_showAlert(id self, SEL _cmd, ...) {
    NSLog(@"[LarrkMod] [FCAlertViewFix] Blocked FCAlertView presentation.");
}

static void dummy_FCAlertView_drawRect(id self, SEL _cmd, CGRect rect) {
    // Suppress drawing
}

static UIImage *dummy_FCAlertView_loadImage(id self, SEL _cmd, NSString *name) {
    return nil;
}

static void LarrkInstallBundleCrashFix(void) {
    Class bundleClass = [NSBundle class];
    
    // Class methods on NSBundle
    LarrkSwizzleClassMethod(bundleClass, @selector(bundleWithURL:), (IMP)hooked_NSBundle_bundleWithURL, &orig_NSBundle_bundleWithURL);
    LarrkSwizzleClassMethod(bundleClass, @selector(bundleWithPath:), (IMP)hooked_NSBundle_bundleWithPath, &orig_NSBundle_bundleWithPath);
    
    // Instance methods on NSBundle
    LarrkSwizzle(bundleClass, @selector(initWithURL:), (IMP)hooked_NSBundle_initWithURL, &orig_NSBundle_initWithURL);
    LarrkSwizzle(bundleClass, @selector(initWithPath:), (IMP)hooked_NSBundle_initWithPath, &orig_NSBundle_initWithPath);
    
    // FCAlertView hook
    Class fcAlertClass = NSClassFromString(@"FCAlertView");
    if (fcAlertClass) {
        SEL sel1 = NSSelectorFromString(@"showAlertInView:withTitle:withSubtitle:withCustomImage:withDoneButtonTitle:andButtons:");
        SEL sel2 = NSSelectorFromString(@"showAlertWithTitle:withSubtitle:withCustomImage:withDoneButtonTitle:andButtons:");
        SEL selDraw = @selector(drawRect:);
        SEL selLoadImg = NSSelectorFromString(@"loadImageFromResourceBundle:");
        
        if (class_getInstanceMethod(fcAlertClass, sel1)) {
            LarrkSwizzle(fcAlertClass, sel1, (IMP)dummy_FCAlertView_showAlert, NULL);
        }
        if (class_getInstanceMethod(fcAlertClass, sel2)) {
            LarrkSwizzle(fcAlertClass, sel2, (IMP)dummy_FCAlertView_showAlert, NULL);
        }
        if (class_getInstanceMethod(fcAlertClass, selDraw)) {
            LarrkSwizzle(fcAlertClass, selDraw, (IMP)dummy_FCAlertView_drawRect, NULL);
        }
        if (class_getInstanceMethod(fcAlertClass, selLoadImg)) {
            LarrkSwizzle(fcAlertClass, selLoadImg, (IMP)dummy_FCAlertView_loadImage, NULL);
        }
        NSLog(@"[LarrkMod] [FCAlertViewFix] Injected FCAlertView neutralizers.");
    }
}

#pragma mark - 2 & 4. AppGroup & NSUserDefaults Sideload Fix (Black Screen Fix)

static IMP orig_NSFileManager_containerURL = NULL;
static NSURL *hooked_NSFileManager_containerURL(id self, SEL _cmd, NSString *groupIdentifier) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = paths.firstObject;
    NSString *appGroupPath = [documentsPath stringByAppendingPathComponent:@"AppGroup/telegram-data"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:appGroupPath isDirectory:&isDir]) {
        [fm createDirectoryAtPath:appGroupPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [NSURL fileURLWithPath:appGroupPath isDirectory:YES];
}

static IMP orig_NSUserDefaults_initWithSuiteName = NULL;
static id hooked_NSUserDefaults_initWithSuiteName(id self, SEL _cmd, NSString *suiteName) {
    if (suiteName != nil) {
        NSString *lower = [suiteName lowercaseString];
        if ([lower hasPrefix:@"group."] || [lower containsString:@"swiftgram"] || [lower containsString:@"telegram"]) {
            return [NSUserDefaults standardUserDefaults];
        }
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
    Class fmClass = [NSFileManager class];
    LarrkSwizzle(fmClass, @selector(containerURLForSecurityApplicationGroupIdentifier:), (IMP)hooked_NSFileManager_containerURL, &orig_NSFileManager_containerURL);
    
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
    NSLog(@"[LarrkMod] [SideloadFix] AppGroup & NSUserDefaults fixes installed.");
}

#pragma mark - 3. Keychain Fix via Fishhook (NO MSHookFunction)

static OSStatus (*orig_SecItemAdd)(CFDictionaryRef attributes, CFTypeRef *result) = NULL;
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef query, CFTypeRef *result) = NULL;
static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) = NULL;
static OSStatus (*orig_SecItemDelete)(CFDictionaryRef query) = NULL;

static CFDictionaryRef LarrkCleanKeychainDictionary(CFDictionaryRef dictRef) {
    if (!dictRef) return NULL;
    NSDictionary *dict = (__bridge NSDictionary *)dictRef;
    if (![dict isKindOfClass:[NSDictionary class]]) return (CFDictionaryRef)CFRetain(dictRef);
    
    id accessGroupKey = (__bridge id)kSecAttrAccessGroup;
    if ([dict objectForKey:accessGroupKey] != nil || [dict objectForKey:@"agrp"] != nil) {
        NSMutableDictionary *mutableDict = [dict mutableCopy];
        [mutableDict removeObjectForKey:accessGroupKey];
        [mutableDict removeObjectForKey:@"agrp"];
        return (__bridge_retained CFDictionaryRef)mutableDict;
    }
    return (CFDictionaryRef)CFRetain(dictRef);
}

static OSStatus hooked_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    if (attributes) {
        CFDictionaryRef clean = LarrkCleanKeychainDictionary(attributes);
        OSStatus status = orig_SecItemAdd ? orig_SecItemAdd(clean, result) : errSecSuccess;
        if (clean) CFRelease(clean);
        return status;
    }
    return orig_SecItemAdd ? orig_SecItemAdd(attributes, result) : errSecParam;
}

static OSStatus hooked_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    if (query) {
        CFDictionaryRef clean = LarrkCleanKeychainDictionary(query);
        OSStatus status = orig_SecItemCopyMatching ? orig_SecItemCopyMatching(clean, result) : errSecItemNotFound;
        if (clean) CFRelease(clean);
        return status;
    }
    return orig_SecItemCopyMatching ? orig_SecItemCopyMatching(query, result) : errSecParam;
}

static OSStatus hooked_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    CFDictionaryRef cleanQuery = query ? LarrkCleanKeychainDictionary(query) : NULL;
    CFDictionaryRef cleanAttrs = attributesToUpdate ? LarrkCleanKeychainDictionary(attributesToUpdate) : NULL;
    
    OSStatus status = orig_SecItemUpdate ? orig_SecItemUpdate(cleanQuery ?: query, cleanAttrs ?: attributesToUpdate) : errSecSuccess;
    
    if (cleanQuery) CFRelease(cleanQuery);
    if (cleanAttrs) CFRelease(cleanAttrs);
    return status;
}

static OSStatus hooked_SecItemDelete(CFDictionaryRef query) {
    if (query) {
        CFDictionaryRef clean = LarrkCleanKeychainDictionary(query);
        OSStatus status = orig_SecItemDelete ? orig_SecItemDelete(clean) : errSecSuccess;
        if (clean) CFRelease(clean);
        return status;
    }
    return orig_SecItemDelete ? orig_SecItemDelete(query) : errSecParam;
}

static void LarrkInstallKeychainFishhook(void) {
    struct rebinding rebindings[] = {
        {"SecItemAdd", (void *)hooked_SecItemAdd, (void **)&orig_SecItemAdd},
        {"SecItemCopyMatching", (void *)hooked_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching},
        {"SecItemUpdate", (void *)hooked_SecItemUpdate, (void **)&orig_SecItemUpdate},
        {"SecItemDelete", (void *)hooked_SecItemDelete, (void **)&orig_SecItemDelete}
    };
    rebind_symbols(rebindings, sizeof(rebindings) / sizeof(struct rebinding));
    NSLog(@"[LarrkMod] [KeychainFix] Keychain C functions successfully rebound via fishhook.");
}

#pragma mark - 5. Built-in Bundle ID Spoofer

static IMP orig_NSBundle_bundleIdentifier = NULL;
static NSString *hooked_NSBundle_bundleIdentifier(NSBundle *self, SEL _cmd) {
    NSString *bid = nil;
    if (orig_NSBundle_bundleIdentifier) {
        bid = ((NSString *(*)(id, SEL))orig_NSBundle_bundleIdentifier)(self, _cmd);
    }
    if (bid && [bid hasPrefix:@"app.swiftgram.ios"]) {
        return @"app.swiftgram.ios";
    }
    return bid;
}

static IMP orig_NSBundle_objectForInfoDictionaryKey = NULL;
static id hooked_NSBundle_objectForInfoDictionaryKey(NSBundle *self, SEL _cmd, NSString *key) {
    if ([key isEqualToString:@"CFBundleIdentifier"]) {
        return @"app.swiftgram.ios";
    }
    if (orig_NSBundle_objectForInfoDictionaryKey) {
        return ((id(*)(id, SEL, NSString *))orig_NSBundle_objectForInfoDictionaryKey)(self, _cmd, key);
    }
    return nil;
}

static void LarrkInstallBundleIDSpoofer(void) {
    Class bClass = [NSBundle class];
    LarrkSwizzle(bClass, @selector(bundleIdentifier), (IMP)hooked_NSBundle_bundleIdentifier, &orig_NSBundle_bundleIdentifier);
    LarrkSwizzle(bClass, @selector(objectForInfoDictionaryKey:), (IMP)hooked_NSBundle_objectForInfoDictionaryKey, &orig_NSBundle_objectForInfoDictionaryKey);
    NSLog(@"[LarrkMod] [BundleIDSpoofer] Bundle ID spoofer installed.");
}

#pragma mark - Hook: Anti-Delete & Message Alpha Hook

static IMP orig_ChatMessageItemView_setAlpha = NULL;
static void hooked_ChatMessageItemView_setAlpha(id self, SEL _cmd, CGFloat alpha) {
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
                if ([item respondsToSelector:NSSelectorFromString(@"message")]) {
                    id message = [item valueForKey:@"message"];
                    if (message && [message respondsToSelector:NSSelectorFromString(@"id")]) {
                        msgId = (int64_t)[[message valueForKey:@"id"] longLongValue];
                    }
                }
            } @catch (NSException *e) {}
        }
        
        if (msgId != 0 && [[LarrkConfig shared] isMessageDeleted:msgId]) {
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
                if ([item respondsToSelector:NSSelectorFromString(@"message")]) {
                    id message = [item valueForKey:@"message"];
                    if (message && [message respondsToSelector:NSSelectorFromString(@"id")]) {
                        msgId = (int64_t)[[message valueForKey:@"id"] longLongValue];
                    }
                }
            } @catch (NSException *e) {}
        }
        
        if (msgId != 0 && [[LarrkConfig shared] isMessageDeleted:msgId]) {
            if ([self isKindOfClass:[UIView class]]) {
                ((UIView *)self).alpha = 0.45f;
            }
        }
    }
}

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
        return;
    }
    
    if (orig_deleteMessages) {
        ((void(*)(id, SEL, id, id))orig_deleteMessages)(self, _cmd, messageIds, type);
    }
}

static void LarrkSetupAntiDeleteHooks() {
    Class itemViewClass = NSClassFromString(@"ChatMessageItemView");
    if (!itemViewClass) {
        itemViewClass = NSClassFromString(@"ChatMessageBubbleItemNode");
    }
    if (itemViewClass) {
        LarrkSwizzle(itemViewClass, @selector(setAlpha:), (IMP)hooked_ChatMessageItemView_setAlpha, &orig_ChatMessageItemView_setAlpha);
        LarrkSwizzle(itemViewClass, NSSelectorFromString(@"layout"), (IMP)hooked_ChatMessageItemView_layout, &orig_ChatMessageItemView_layout);
    }
    
    Class chatHistoryClass = NSClassFromString(@"ChatHistoryController");
    if (chatHistoryClass) {
        SEL deleteSEL = NSSelectorFromString(@"deleteMessages:type:");
        if (class_getInstanceMethod(chatHistoryClass, deleteSEL)) {
            LarrkSwizzle(chatHistoryClass, deleteSEL, (IMP)hooked_deleteMessages, &orig_deleteMessages);
        }
    }
}

#pragma mark - Hook: Ghost Mode (8 MTProto Actions & Online Status)

static uint32_t LarrkFilterMTProtoActionConstructor(uint32_t constructorId) {
    LarrkConfig *config = [LarrkConfig shared];
    if (constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_TYPING && config.disableTyping) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    if ((constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_RECORD_VIDEO || constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_RECORD_ROUND) && config.disableRecordVideo) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    if ((constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_VIDEO || constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_ROUND) && config.disableUploadVideo) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    if (constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_RECORD_VOICE && config.disableRecordVoice) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    if (constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_VOICE && config.disableUploadVoice) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    if (constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_PHOTO && config.disableUploadPhoto) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    if (constructorId == TL_CONSTRUCTOR_SEND_MESSAGE_UPLOAD_FILE && config.disableUploadFile) {
        return TL_CONSTRUCTOR_SEND_MESSAGE_CANCEL;
    }
    return constructorId;
}

static IMP orig_MTBuffer_writeInt32 = NULL;
static void hooked_MTBuffer_writeInt32(id self, SEL _cmd, int32_t value) {
    uint32_t uValue = (uint32_t)value;
    uint32_t filtered = LarrkFilterMTProtoActionConstructor(uValue);
    
    if (uValue == TL_CONSTRUCTOR_ACCOUNT_UPDATE_STATUS && [LarrkConfig shared].disableOnline) {
        filtered = TL_CONSTRUCTOR_ACCOUNT_UPDATE_STATUS;
    }
    
    if (orig_MTBuffer_writeInt32) {
        ((void(*)(id, SEL, int32_t))orig_MTBuffer_writeInt32)(self, _cmd, (int32_t)filtered);
    }
}

static IMP orig_ChatActivity_sendActivity = NULL;
static void hooked_ChatActivity_sendActivity(id self, SEL _cmd, id activity) {
    LarrkConfig *config = [LarrkConfig shared];
    if (config.disableTyping || config.disableRecordVoice || config.disableRecordVideo) {
        return;
    }
    if (orig_ChatActivity_sendActivity) {
        ((void(*)(id, SEL, id))orig_ChatActivity_sendActivity)(self, _cmd, activity);
    }
}

static void LarrkSetupGhostModeHooks() {
    Class bufferClass = NSClassFromString(@"MTBuffer");
    if (!bufferClass) {
        bufferClass = NSClassFromString(@"TLBuffer");
    }
    if (bufferClass) {
        SEL writeSEL = NSSelectorFromString(@"writeInt32:");
        if (class_getInstanceMethod(bufferClass, writeSEL)) {
            LarrkSwizzle(bufferClass, writeSEL, (IMP)hooked_MTBuffer_writeInt32, &orig_MTBuffer_writeInt32);
        }
    }
    
    Class activityManager = NSClassFromString(@"PeerInputActivityManager");
    if (activityManager) {
        SEL actSEL = NSSelectorFromString(@"sendActivity:");
        if (class_getInstanceMethod(activityManager, actSEL)) {
            LarrkSwizzle(activityManager, actSEL, (IMP)hooked_ChatActivity_sendActivity, &orig_ChatActivity_sendActivity);
        }
    }
}

#pragma mark - Hook: Local Telegram Premium

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
        Class userClass = NSClassFromString(name);
        if (userClass) {
            SEL isPremiumSEL = NSSelectorFromString(@"isPremium");
            if (class_getInstanceMethod(userClass, isPremiumSEL)) {
                LarrkSwizzle(userClass, isPremiumSEL, (IMP)hooked_TelegramUser_isPremium, &orig_TelegramUser_isPremium);
            }
        }
    }
}

#pragma mark - Hook: Local NFT Profile & Telegram Stars

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
    Class headerNodeClass = NSClassFromString(@"PeerInfoHeaderNode");
    if (!headerNodeClass) {
        headerNodeClass = NSClassFromString(@"PeerInfoHeaderNavigationNode");
    }
    if (headerNodeClass) {
        SEL layoutSEL = NSSelectorFromString(@"layout");
        if (class_getInstanceMethod(headerNodeClass, layoutSEL)) {
            LarrkSwizzle(headerNodeClass, layoutSEL, (IMP)hooked_PeerInfoHeaderNode_layout, &orig_PeerInfoHeaderNode_layout);
        }
    }
    
    Class starsClass = NSClassFromString(@"StarsContext");
    if (!starsClass) {
        starsClass = NSClassFromString(@"StarsState");
    }
    if (starsClass) {
        SEL balanceSEL = NSSelectorFromString(@"balance");
        if (class_getInstanceMethod(starsClass, balanceSEL)) {
            LarrkSwizzle(starsClass, balanceSEL, (IMP)hooked_StarsContext_balance, &orig_StarsContext_balance);
        }
    }
}

#pragma mark - 6. Safe Constructor Entry Point (Jailed iOS 18+ Clean Startup)

__attribute__((constructor))
static void LarrkModInit(void) {
    NSLog(@"[LarrkMod] Initializing LarrkMod iOS Tweak (Jailed iOS 18.7.3 Sideload Engine)...");
    
    @autoreleasepool {
        // STEP 1: Main Thread SIGABRT Protection (FCAlertView & NSBundle nil URLs/paths)
        LarrkInstallBundleCrashFix();
        
        // STEP 2: AppGroup Container & NSUserDefaults Suite Redirection (Black Screen Fix)
        LarrkInstallSideloadFix();
        
        // STEP 3: Built-in Bundle ID Spoofer (app.swiftgram.ios.XYZ -> app.swiftgram.ios)
        LarrkInstallBundleIDSpoofer();
        
        // STEP 4: Keychain Access Group Interception via Fishhook (No MSHookFunction)
        LarrkInstallKeychainFishhook();
        
        // STEP 5: Initialize persistent configuration
        [LarrkConfig shared];
        
        // STEP 6: Gesture Overlay Notification Registration (Zero synchronous UIWindow access)
        [[LarrkGestureOverlay shared] startListening];
        
        // STEP 7: Defer all UI and MTProto hooks to after application did finish launching
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"[LarrkMod] UIApplicationDidFinishLaunchingNotification received. Installing UI and MTProto hooks safely...");
            LarrkSetupAntiDeleteHooks();
            LarrkSetupGhostModeHooks();
            LarrkSetupPremiumHooks();
            LarrkSetupNFTAndStarsHooks();
            NSLog(@"[LarrkMod] All UI hooks installed safely.");
        }];
    }
}
