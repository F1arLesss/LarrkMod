//
//  LarrkModViewController.h
//  LarrkMod
//
//  Created for Swiftgram (app.swiftgram.ios)
//  Copyright © 2026 LarrkMod. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LarrkModViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;

- (void)showToast:(NSString *)message isError:(BOOL)isError;

@end

NS_ASSUME_NONNULL_END
