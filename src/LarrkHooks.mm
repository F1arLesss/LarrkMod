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

#pragma mark - 1. Third-Party Ad & Banner Blocker (FCAlertView / iOSGods / ArmConverter)

static BOOL LarrkIsAdOrBannerClass(const char *className) {
    if (!className) return NO;
    return (strstr(className, "FCAlert") != NULL ||
            strstr(className, "iOSGods") != NULL ||
            strstr(className, "ArmConverter") != NULL ||
            strstr(className, "JHBanner") != NULL ||
            strstr(className, "IGBanner") != NULL ||
            strstr(className, "ACBanner") != NULL ||
            strstr(className, "Watermark") != NULL ||
            strstr(className, "KamoHack") != NULL ||
            strstr(className, "FloatingBanner") != NULL ||
            strstr(className, "BannerView") != NULL);
}

// 1. Intercept UIWindow addSubview: to prevent banner attachment
static IMP orig_UIWindow_addSubview = NULL;
static void hooked_UIWindow_addSubview(UIWindow *self, SEL _cmd, UIView *view) {
    if (view) {
        const char *name = object_getClassName(view);
        if (LarrkIsAdOrBannerClass(name)) {
            NSLog(@"[LarrkMod] [AdBlock] Prevented adding banner '%s' to UIWindow.", name);
            view.hidden = YES;
            view.alpha = 0.0f;
            return;
        }
    }
    if (orig_UIWindow_addSubview) {
        ((void(*)(id, SEL, UIView *))orig_UIWindow_addSubview)(self, _cmd, view);
    }
}

// 2. Intercept UIView didMoveToWindow to remove banner if already added
static IMP orig_UIView_didMoveToWindow = NULL;
static void hooked_UIView_didMoveToWindow(UIView *self, SEL _cmd) {
    if (orig_UIView_didMoveToWindow) {
        ((void(*)(id, SEL))orig_UIView_didMoveToWindow)(self, _cmd);
    }
    if (self) {
        const char *name = object_getClassName(self);
        if (LarrkIsAdOrBannerClass(name)) {
            NSLog(@"[LarrkMod] [AdBlock] Removed banner '%s' from window.", name);
            self.hidden = YES;
            self.alpha = 0.0f;
            [self removeFromSuperview];
        }
    }
}

// 3. Intercept UIViewController presentViewController:animated:completion: to block ad dialogs
static IMP orig_UIViewController_presentViewController = NULL;
static void hooked_UIViewController_presentViewController(UIViewController *self, SEL _cmd, UIViewController *vc, BOOL flag, void (^comp)(void)) {
    if (vc) {
        const char *name = object_getClassName(vc);
        if (LarrkIsAdOrBannerClass(name)) {
            NSLog(@"[LarrkMod] [AdBlock] Suppressed modal presentation of '%s'.", name);
            if (comp) comp();
            return;
        }
    }
    if (orig_UIViewController_presentViewController) {
        ((void(*)(id, SEL, UIViewController *, BOOL, void (^)(void)))orig_UIViewController_presentViewController)(self, _cmd, vc, flag, comp);
    }
}

// Bundle nil crash prevention
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

// FCAlertView dummy stubs
static void dummy_FCAlertView_showAlert(id self, SEL _cmd, ...) {
    NSLog(@"[LarrkMod] [FCAlertViewFix] Blocked FCAlertView presentation.");
}

static void dummy_FCAlertView_drawRect(id self, SEL _cmd, CGRect rect) {
    // Suppress drawing
}

static UIImage *dummy_FCAlertView_loadImage(id self, SEL _cmd, NSString *name) {
    return nil;
}

static void LarrkInstallAdAndBundleFix(void) {
    Class bundleClass = [NSBundle class];
    LarrkSwizzleClassMethod(bundleClass, @selector(bundleWithURL:), (IMP)hooked_NSBundle_bundleWithURL, &orig_NSBundle_bundleWithURL);
    LarrkSwizzleClassMethod(bundleClass, @selector(bundleWithPath:), (IMP)hooked_NSBundle_bundleWithPath, &orig_NSBundle_bundleWithPath);
    LarrkSwizzle(bundleClass, @selector(initWithURL:), (IMP)hooked_NSBundle_initWithURL, &orig_NSBundle_initWithURL);
    LarrkSwizzle(bundleClass, @selector(initWithPath:), (IMP)hooked_NSBundle_initWithPath, &orig_NSBundle_initWithPath);
    
    // Window and View Banner Interceptors
    Class windowClass = [UIWindow class];
    LarrkSwizzle(windowClass, @selector(addSubview:), (IMP)hooked_UIWindow_addSubview, &orig_UIWindow_addSubview);
    
    Class viewClass = [UIView class];
    LarrkSwizzle(viewClass, @selector(didMoveToWindow), (IMP)hooked_UIView_didMoveToWindow, &orig_UIView_didMoveToWindow);
    
    Class vcClass = [UIViewController class];
    LarrkSwizzle(vcClass, @selector(presentViewController:animated:completion:), (IMP)hooked_UIViewController_presentViewController, &orig_UIViewController_presentViewController);
    
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
    }
    NSLog(@"[LarrkMod] [AdBlock] Banner & Bundle crash protections installed.");
}

#pragma mark - 2. AppGroup & NSUserDefaults Sideload Fix

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

#pragma mark - 3. Keychain Fix & Persistent Fallback Subsystem

static OSStatus (*orig_SecItemAdd)(CFDictionaryRef attributes, CFTypeRef *result) = NULL;
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef query, CFTypeRef *result) = NULL;
static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) = NULL;
static OSStatus (*orig_SecItemDelete)(CFDictionaryRef query) = NULL;

static NSString *LarrkKeychainFallbackPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs = paths.firstObject;
    return [docs stringByAppendingPathComponent:@"keychain_fallback.plist"];
}

static NSMutableDictionary *LarrkLoadKeychainFallback(void) {
    NSString *path = LarrkKeychainFallbackPath();
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
        if (dict) return [dict mutableCopy];
    }
    return [NSMutableDictionary dictionary];
}

static void LarrkSaveKeychainFallback(NSDictionary *dict) {
    if (!dict) return;
    NSString *path = LarrkKeychainFallbackPath();
    [dict writeToFile:path atomically:YES];
}

static NSString *LarrkKeyForItem(NSDictionary *dict) {
    id secClass = dict[(__bridge id)kSecClass] ?: @"kSecClassGenericPassword";
    id service = dict[(__bridge id)kSecAttrService] ?: @"";
    id account = dict[(__bridge id)kSecAttrAccount] ?: @"";
    id generic = dict[(__bridge id)kSecAttrGeneric] ?: @"";
    return [NSString stringWithFormat:@"%@_%@_%@_%@", secClass, service, account, generic];
}

static void LarrkStoreKeychainFallback(NSDictionary *attrs) {
    if (!attrs) return;
    NSData *data = attrs[(__bridge id)kSecValueData];
    if (!data) return;
    
    static dispatch_queue_t fallbackQueue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fallbackQueue = dispatch_queue_create("com.larrkmod.keychain.fallback", DISPATCH_QUEUE_SERIAL);
    });
    
    dispatch_sync(fallbackQueue, ^{
        NSMutableDictionary *fallback = LarrkLoadKeychainFallback();
        NSString *key = LarrkKeyForItem(attrs);
        fallback[key] = @{
            @"data": data,
            @"service": attrs[(__bridge id)kSecAttrService] ?: @"",
            @"account": attrs[(__bridge id)kSecAttrAccount] ?: @"",
            @"class": attrs[(__bridge id)kSecClass] ?: @"kSecClassGenericPassword"
        };
        LarrkSaveKeychainFallback(fallback);
        NSLog(@"[LarrkMod] [KeychainFallback] Backed up session key '%@' (bytes: %lu) to keychain_fallback.plist", key, (unsigned long)data.length);
    });
}

static OSStatus LarrkHandleKeychainCopyMatchingFallback(NSDictionary *query, CFTypeRef *result) {
    NSString *service = query[(__bridge id)kSecAttrService];
    NSString *account = query[(__bridge id)kSecAttrAccount];
    NSString *secClass = query[(__bridge id)kSecClass] ?: (__bridge id)kSecClassGenericPassword;
    
    NSDictionary *fallback = LarrkLoadKeychainFallback();
    if (!fallback || fallback.count == 0) {
        return errSecItemNotFound;
    }
    
    NSString *targetKey = LarrkKeyForItem(query);
    NSDictionary *item = fallback[targetKey];
    
    if (!item) {
        for (NSString *key in fallback) {
            NSDictionary *entry = fallback[key];
            if (![entry isKindOfClass:[NSDictionary class]]) continue;
            
            BOOL matchService = (!service || [entry[@"service"] isEqualToString:service]);
            BOOL matchAccount = (!account || [entry[@"account"] isEqualToString:account]);
            
            if (matchService && matchAccount) {
                item = entry;
                break;
            }
        }
    }
    
    if (!item && service.length > 0) {
        for (NSString *key in fallback) {
            NSDictionary *entry = fallback[key];
            if ([entry[@"service"] containsString:service] || [service containsString:entry[@"service"]]) {
                item = entry;
                break;
            }
        }
    }
    
    if (item) {
        NSData *data = item[@"data"];
        if (data) {
            if (result != NULL) {
                BOOL returnData = [query[(__bridge id)kSecReturnData] boolValue];
                BOOL returnAttributes = [query[(__bridge id)kSecReturnAttributes] boolValue];
                
                if (returnAttributes && returnData) {
                    NSMutableDictionary *resDict = [NSMutableDictionary dictionary];
                    resDict[(__bridge id)kSecClass] = item[@"class"] ?: secClass;
                    if (item[@"service"]) resDict[(__bridge id)kSecAttrService] = item[@"service"];
                    if (item[@"account"]) resDict[(__bridge id)kSecAttrAccount] = item[@"account"];
                    resDict[(__bridge id)kSecValueData] = data;
                    *result = (__bridge_retained CFTypeRef)resDict;
                } else if (returnAttributes) {
                    NSMutableDictionary *resDict = [NSMutableDictionary dictionary];
                    resDict[(__bridge id)kSecClass] = item[@"class"] ?: secClass;
                    if (item[@"service"]) resDict[(__bridge id)kSecAttrService] = item[@"service"];
                    if (item[@"account"]) resDict[(__bridge id)kSecAttrAccount] = item[@"account"];
                    *result = (__bridge_retained CFTypeRef)resDict;
                } else {
                    *result = (__bridge_retained CFTypeRef)data;
                }
            }
            NSLog(@"[LarrkMod] [KeychainFallback] Resolved item from fallback plist with errSecSuccess!");
            return errSecSuccess;
        }
    }
    
    return errSecItemNotFound;
}

static OSStatus hooked_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    if (!attributes) return orig_SecItemAdd ? orig_SecItemAdd(attributes, result) : errSecParam;
    
    NSDictionary *attrDict = (__bridge NSDictionary *)attributes;
    NSMutableDictionary *mutableAttrs = [attrDict mutableCopy];
    
    // 1. Strip Access Group to prevent -34018
    [mutableAttrs removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    [mutableAttrs removeObjectForKey:@"agrp"];
    
    // 2. Override Accessible attribute for jailed compatibility
    [mutableAttrs setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];
    
    // 3. Always store to local persistent fallback plist
    LarrkStoreKeychainFallback(mutableAttrs);
    
    OSStatus status = errSecSuccess;
    if (orig_SecItemAdd) {
        status = orig_SecItemAdd((__bridge CFDictionaryRef)mutableAttrs, result);
    } else {
        status = errSecItemNotFound;
    }
    
    // Handle duplicate item by updating it
    if (status == errSecDuplicateItem) {
        NSMutableDictionary *query = [NSMutableDictionary dictionary];
        if (mutableAttrs[(__bridge id)kSecClass]) query[(__bridge id)kSecClass] = mutableAttrs[(__bridge id)kSecClass];
        if (mutableAttrs[(__bridge id)kSecAttrService]) query[(__bridge id)kSecAttrService] = mutableAttrs[(__bridge id)kSecAttrService];
        if (mutableAttrs[(__bridge id)kSecAttrAccount]) query[(__bridge id)kSecAttrAccount] = mutableAttrs[(__bridge id)kSecAttrAccount];
        
        NSMutableDictionary *updateAttrs = [mutableAttrs mutableCopy];
        [updateAttrs removeObjectForKey:(__bridge id)kSecClass];
        
        if (orig_SecItemUpdate) {
            status = orig_SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)updateAttrs);
        }
    }
    
    // If keychain returned error (-34018 or other jailed Keychain issue), override to errSecSuccess!
    if (status != errSecSuccess) {
        NSLog(@"[LarrkMod] [KeychainFix] SecItemAdd returned error %d. Overriding to errSecSuccess via fallback plist!", (int)status);
        if (result != NULL && mutableAttrs[(__bridge id)kSecReturnData]) {
            *result = (__bridge_retained CFTypeRef)mutableAttrs[(__bridge id)kSecValueData];
        }
        return errSecSuccess;
    }
    
    return status;
}

static OSStatus hooked_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    if (!query) return orig_SecItemCopyMatching ? orig_SecItemCopyMatching(query, result) : errSecParam;
    
    NSDictionary *qDict = (__bridge NSDictionary *)query;
    NSMutableDictionary *mutableQ = [qDict mutableCopy];
    [mutableQ removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    [mutableQ removeObjectForKey:@"agrp"];
    
    OSStatus status = errSecItemNotFound;
    if (orig_SecItemCopyMatching) {
        status = orig_SecItemCopyMatching((__bridge CFDictionaryRef)mutableQ, result);
    }
    
    // If keychain returned success and populated result, return it
    if (status == errSecSuccess && (!result || *result != NULL)) {
        return errSecSuccess;
    }
    
    // If keychain failed or returned errSecItemNotFound / -34018, check fallback plist!
    OSStatus fallbackStatus = LarrkHandleKeychainCopyMatchingFallback(mutableQ, result);
    if (fallbackStatus == errSecSuccess) {
        return errSecSuccess;
    }
    
    return status;
}

static OSStatus hooked_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    if (!query) return orig_SecItemUpdate ? orig_SecItemUpdate(query, attributesToUpdate) : errSecParam;
    
    NSMutableDictionary *cleanQuery = [(__bridge NSDictionary *)query mutableCopy];
    [cleanQuery removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    [cleanQuery removeObjectForKey:@"agrp"];
    
    NSMutableDictionary *cleanAttrs = attributesToUpdate ? [(__bridge NSDictionary *)attributesToUpdate mutableCopy] : nil;
    if (cleanAttrs) {
        [cleanAttrs removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
        [cleanAttrs removeObjectForKey:@"agrp"];
        cleanAttrs[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    }
    
    OSStatus status = errSecSuccess;
    if (orig_SecItemUpdate) {
        status = orig_SecItemUpdate((__bridge CFDictionaryRef)cleanQuery, cleanAttrs ? (__bridge CFDictionaryRef)cleanAttrs : attributesToUpdate);
    }
    
    // Update fallback plist
    NSData *data = cleanAttrs[(__bridge id)kSecValueData];
    if (data) {
        NSMutableDictionary *merged = [cleanQuery mutableCopy];
        [merged addEntriesFromDictionary:cleanAttrs];
        LarrkStoreKeychainFallback(merged);
    }
    
    return errSecSuccess;
}

static OSStatus hooked_SecItemDelete(CFDictionaryRef query) {
    if (!query) return orig_SecItemDelete ? orig_SecItemDelete(query) : errSecParam;
    
    NSMutableDictionary *cleanQuery = [(__bridge NSDictionary *)query mutableCopy];
    [cleanQuery removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    [cleanQuery removeObjectForKey:@"agrp"];
    
    if (orig_SecItemDelete) {
        orig_SecItemDelete((__bridge CFDictionaryRef)cleanQuery);
    }
    
    NSString *key = LarrkKeyForItem(cleanQuery);
    NSMutableDictionary *fallback = LarrkLoadKeychainFallback();
    [fallback removeObjectForKey:key];
    LarrkSaveKeychainFallback(fallback);
    
    return errSecSuccess;
}

static void LarrkInstallKeychainFishhook(void) {
    struct rebinding rebindings[] = {
        {"SecItemAdd", (void *)hooked_SecItemAdd, (void **)&orig_SecItemAdd},
        {"SecItemCopyMatching", (void *)hooked_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching},
        {"SecItemUpdate", (void *)hooked_SecItemUpdate, (void **)&orig_SecItemUpdate},
        {"SecItemDelete", (void *)hooked_SecItemDelete, (void **)&orig_SecItemDelete}
    };
    rebind_symbols(rebindings, sizeof(rebindings) / sizeof(struct rebinding));
    NSLog(@"[LarrkMod] [KeychainFix] Keychain C functions successfully rebound via fishhook with persistent fallback.");
}

#pragma mark - 4. Official Telegram Bundle ID Spoofer (ph.telegra.Telegraph)

static IMP orig_NSBundle_bundleIdentifier = NULL;
static NSString *hooked_NSBundle_bundleIdentifier(NSBundle *self, SEL _cmd) {
    if (self == [NSBundle mainBundle]) {
        return @"ph.telegra.Telegraph";
    }
    NSString *bid = nil;
    if (orig_NSBundle_bundleIdentifier) {
        bid = ((NSString *(*)(id, SEL))orig_NSBundle_bundleIdentifier)(self, _cmd);
    }
    if (bid && ([bid hasPrefix:@"ph.telegra.Telegraph"] || [bid hasPrefix:@"app.swiftgram.ios"])) {
        return @"ph.telegra.Telegraph";
    }
    return bid;
}

static IMP orig_NSBundle_infoDictionary = NULL;
static NSDictionary *hooked_NSBundle_infoDictionary(NSBundle *self, SEL _cmd) {
    NSDictionary *dict = nil;
    if (orig_NSBundle_infoDictionary) {
        dict = ((NSDictionary *(*)(id, SEL))orig_NSBundle_infoDictionary)(self, _cmd);
    }
    if (self == [NSBundle mainBundle]) {
        NSMutableDictionary *mut = dict ? [dict mutableCopy] : [NSMutableDictionary dictionary];
        mut[@"CFBundleIdentifier"] = @"ph.telegra.Telegraph";
        return mut;
    }
    return dict;
}

static IMP orig_NSBundle_objectForInfoDictionaryKey = NULL;
static id hooked_NSBundle_objectForInfoDictionaryKey(NSBundle *self, SEL _cmd, NSString *key) {
    if ([key isEqualToString:@"CFBundleIdentifier"]) {
        if (self == [NSBundle mainBundle] || self == nil) {
            return @"ph.telegra.Telegraph";
        }
    }
    if (orig_NSBundle_objectForInfoDictionaryKey) {
        return ((id(*)(id, SEL, NSString *))orig_NSBundle_objectForInfoDictionaryKey)(self, _cmd, key);
    }
    return nil;
}

static void LarrkInstallBundleIDSpoofer(void) {
    Class bClass = [NSBundle class];
    LarrkSwizzle(bClass, @selector(bundleIdentifier), (IMP)hooked_NSBundle_bundleIdentifier, &orig_NSBundle_bundleIdentifier);
    LarrkSwizzle(bClass, @selector(infoDictionary), (IMP)hooked_NSBundle_infoDictionary, &orig_NSBundle_infoDictionary);
    LarrkSwizzle(bClass, @selector(objectForInfoDictionaryKey:), (IMP)hooked_NSBundle_objectForInfoDictionaryKey, &orig_NSBundle_objectForInfoDictionaryKey);
    NSLog(@"[LarrkMod] [BundleIDSpoofer] Official Telegram bundle ID spoofing (ph.telegra.Telegraph) installed.");
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

#pragma mark - Constructor Entry Point (Jailed iOS 18+ Clean Startup)

__attribute__((constructor))
static void LarrkModInit(void) {
    NSLog(@"[LarrkMod] Initializing LarrkMod iOS Tweak (Jailed iOS 18.7.3 Sideload Engine)...");
    
    @autoreleasepool {
        // STEP 1: Main Thread SIGABRT Protection & Third-Party Ad Blocker (FCAlertView, iOSGods, ArmConverter)
        LarrkInstallAdAndBundleFix();
        
        // STEP 2: AppGroup Container & NSUserDefaults Suite Redirection (Black Screen Fix)
        LarrkInstallSideloadFix();
        
        // STEP 3: Built-in Bundle ID Spoofer (app.swiftgram.ios.XYZ -> app.swiftgram.ios)
        LarrkInstallBundleIDSpoofer();
        
        // STEP 4: Keychain Access Group Interception & Persistent Fallback via Fishhook (No MSHookFunction)
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
