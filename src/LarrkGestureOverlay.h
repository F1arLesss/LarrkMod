//
//  LarrkGestureOverlay.h
//  LarrkMod
//
//  Created for Swiftgram (app.swiftgram.ios)
//  Copyright © 2026 LarrkMod. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LarrkGestureOverlay : NSObject

+ (instancetype)shared;

/// Starts listening to application state and attaches trigger to key window
- (void)startListening;

/// Directly attaches gesture overlay to a specific window
- (void)attachToWindow:(UIWindow *)window;

/// Presents the LarrkMod settings modal from the topmost view controller
- (void)presentModMenu;

@end

NS_ASSUME_NONNULL_END
