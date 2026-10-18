//
//  LarrkConfig.h
//  LarrkMod
//
//  Created for Swiftgram (app.swiftgram.ios)
//  Copyright © 2026 LarrkMod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LarrkConfig : NSObject

+ (instancetype)shared;

#pragma mark - Anti-Delete
@property (nonatomic, assign) BOOL antiDelete;
@property (nonatomic, strong, readonly) NSMutableSet<NSNumber *> *deletedMessageIds;

- (void)markMessageAsDeleted:(int64_t)messageId;
- (BOOL)isMessageDeleted:(int64_t)messageId;
- (void)clearDeletedMessages;

#pragma mark - Ghost Mode (8 Privacy Toggles)
@property (nonatomic, assign) BOOL disableOnline;
@property (nonatomic, assign) BOOL disableTyping;
@property (nonatomic, assign) BOOL disableRecordVideo;
@property (nonatomic, assign) BOOL disableUploadVideo;
@property (nonatomic, assign) BOOL disableRecordVoice;
@property (nonatomic, assign) BOOL disableUploadVoice;
@property (nonatomic, assign) BOOL disableUploadPhoto;
@property (nonatomic, assign) BOOL disableUploadFile;

#pragma mark - Local Telegram Premium
@property (nonatomic, assign) BOOL localPremium;

#pragma mark - Local NFT Profile
@property (nonatomic, assign) BOOL customProfileEnabled;
@property (nonatomic, copy) NSString *nftPresetName;
@property (nonatomic, assign) NSInteger bgGradientIndex;
@property (nonatomic, copy) NSString *patternEmoji;

- (nullable UIImage *)customNFTImage;
- (BOOL)saveCustomNFTImage:(UIImage *)image;
- (NSString *)customNFTImagePath;
- (void)resetProfileCustomization;

#pragma mark - Local Telegram Stars
@property (nonatomic, assign) BOOL customStarsEnabled;
@property (nonatomic, assign) NSInteger localStarsAmount;

- (void)resetStars;

#pragma mark - Gradients Helper
- (NSArray<UIColor *> *)currentGradientColors;
+ (NSArray<NSString *> *)gradientPresetTitles;
+ (NSArray<NSString *> *)nftPresetTitles;

@end

NS_ASSUME_NONNULL_END
