//
//  LarrkGestureOverlay.mm
//  LarrkMod
//
//  Created for Swiftgram (app.swiftgram.ios)
//  Copyright © 2026 LarrkMod. All rights reserved.
//

#import "LarrkGestureOverlay.h"
#import "LarrkModViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

#pragma mark - LarrkHoldHUDView

@interface LarrkHoldHUDView : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *progressTrackView;
@property (nonatomic, strong) CAGradientLayer *progressGradient;
@property (nonatomic, assign) CGFloat progress; // 0.0 - 1.0
@end

@implementation LarrkHoldHUDView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.08 green:0.09 blue:0.12 alpha:0.92];
        self.layer.cornerRadius = 16.0;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor colorWithRed:0.55 green:0.35 blue:0.95 alpha:0.6].CGColor;
        
        // Shadow for neon glow
        self.layer.shadowColor = [UIColor colorWithRed:0.60 green:0.25 blue:1.0 alpha:0.5].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 12.0;
        self.layer.shadowOpacity = 0.8;
        
        // Blur background
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.frame = self.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:blurView];
        
        // Title Label
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, frame.size.width - 24, 20)];
        _titleLabel.text = @"Удерживайте еще 3 сек для LarrkMod...";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightSemibold];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];
        
        // Progress Track
        _progressTrackView = [[UIView alloc] initWithFrame:CGRectMake(16, 36, frame.size.width - 32, 6)];
        _progressTrackView.backgroundColor = [UIColor colorWithWhite:0.25 alpha:0.6];
        _progressTrackView.layer.cornerRadius = 3.0;
        _progressTrackView.layer.masksToBounds = YES;
        [self addSubview:_progressTrackView];
        
        // Progress Gradient Fill
        _progressGradient = [CAGradientLayer layer];
        _progressGradient.colors = @[
            (id)[UIColor colorWithRed:0.75 green:0.25 blue:1.00 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.00 green:0.90 blue:0.95 alpha:1.0].CGColor
        ];
        _progressGradient.startPoint = CGPointMake(0.0, 0.5);
        _progressGradient.endPoint = CGPointMake(1.0, 0.5);
        _progressGradient.frame = CGRectMake(0, 0, 0, _progressTrackView.bounds.size.height);
        _progressGradient.cornerRadius = 3.0;
        [_progressTrackView.layer addSublayer:_progressGradient];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    _progress = MAX(0.0, MIN(1.0, progress));
    CGFloat width = _progressTrackView.bounds.size.width * _progress;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _progressGradient.frame = CGRectMake(0, 0, width, _progressTrackView.bounds.size.height);
    [CATransaction commit];
    
    // Countdown text update
    CGFloat remaining = 3.0 * (1.0 - _progress);
    if (remaining < 0.05) remaining = 0.0;
    _titleLabel.text = [NSString stringWithFormat:@"Удерживайте еще %.1f сек для LarrkMod...", remaining];
}

@end

#pragma mark - LarrkHoldGestureRecognizer

@interface LarrkHoldGestureRecognizer : UIGestureRecognizer <UIGestureRecognizerDelegate>
@property (nonatomic, assign) CGPoint touchStartPoint;
@property (nonatomic, strong, nullable) NSTimer *initialDelayTimer;
@property (nonatomic, strong, nullable) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval progressStartTime;
@property (nonatomic, strong, nullable) LarrkHoldHUDView *hudView;
@property (nonatomic, assign) BOOL isHoldingActive;
@end

@implementation LarrkHoldGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    self = [super initWithTarget:target action:action];
    if (self) {
        self.delegate = self;
        self.cancelsTouchesInView = YES;
        self.delaysTouchesBegan = NO;
        self.delaysTouchesEnded = NO;
    }
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Before 1.0s, allow other gestures so normal taps work; once active, we take over
    return !self.isHoldingActive;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer {
    return self.isHoldingActive;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    if (!touch || !self.view) return;
    
    CGPoint loc = [touch locationInView:self.view];
    CGSize bounds = self.view.bounds.size;
    
    // Target area: Bottom 85pt (tabbar area) AND left/center area (Chats tab, x < 45% of width)
    BOOL inBottomBar = (loc.y >= bounds.height - 85.0);
    BOOL inChatsTabX = (loc.x >= 0.0 && loc.x <= bounds.width * 0.45);
    
    if (!inBottomBar || !inChatsTabX) {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    
    self.touchStartPoint = loc;
    self.isHoldingActive = NO;
    
    // Schedule 1.0-second delay timer
    [self.initialDelayTimer invalidate];
    __weak typeof(self) weakSelf = self;
    self.initialDelayTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [weakSelf didPassInitialSecond];
    }];
}

- (void)didPassInitialSecond {
    self.isHoldingActive = YES;
    self.state = UIGestureRecognizerStateBegan;
    
    // 1. Medium haptic feedback
    UIImpactFeedbackGenerator *impact = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [impact prepare];
    [impact impactOccurred];
    
    // 2. Present HUD View above the tabbar
    [self showHUD];
    
    // 3. Start CADisplayLink for 3.0 seconds filling
    [self.displayLink invalidate];
    self.progressStartTime = CACurrentMediaTime();
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)showHUD {
    if (!self.view) return;
    
    if (!self.hudView) {
        CGFloat hudWidth = 280.0;
        CGFloat hudHeight = 54.0;
        CGFloat hudX = (self.view.bounds.size.width - hudWidth) / 2.0;
        CGFloat hudY = self.view.bounds.size.height - 85.0 - hudHeight - 12.0;
        
        self.hudView = [[LarrkHoldHUDView alloc] initWithFrame:CGRectMake(hudX, hudY, hudWidth, hudHeight)];
        self.hudView.alpha = 0.0;
        self.hudView.transform = CGAffineTransformMakeScale(0.85, 0.85);
        [self.view addSubview:self.hudView];
    }
    
    [self.hudView setProgress:0.0];
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.hudView.alpha = 1.0;
        self.hudView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hideHUDAnimated:(BOOL)animated {
    if (!self.hudView) return;
    
    if (animated) {
        [UIView animateWithDuration:0.20 animations:^{
            self.hudView.alpha = 0.0;
            self.hudView.transform = CGAffineTransformMakeScale(0.85, 0.85);
        } completion:^(BOOL finished) {
            [self.hudView removeFromSuperview];
            self.hudView = nil;
        }];
    } else {
        [self.hudView removeFromSuperview];
        self.hudView = nil;
    }
}

- (void)displayLinkTick:(CADisplayLink *)link {
    CFTimeInterval elapsed = CACurrentMediaTime() - self.progressStartTime;
    CGFloat duration = 3.0; // 3 seconds
    CGFloat progress = (CGFloat)(elapsed / duration);
    
    [self.hudView setProgress:progress];
    
    if (progress >= 1.0) {
        // Complete!
        [self.displayLink invalidate];
        self.displayLink = nil;
        [self.initialDelayTimer invalidate];
        self.initialDelayTimer = nil;
        
        self.state = UIGestureRecognizerStateEnded;
        self.isHoldingActive = NO;
        
        // Success haptic
        UINotificationFeedbackGenerator *notifier = [[UINotificationFeedbackGenerator alloc] init];
        [notifier prepare];
        [notifier notificationOccurred:UINotificationFeedbackTypeSuccess];
        
        [self hideHUDAnimated:YES];
        
        // Open LarrkModViewController
        [[LarrkGestureOverlay shared] presentModMenu];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    if (!touch || !self.view) return;
    
    CGPoint loc = [touch locationInView:self.view];
    CGFloat distance = hypot(loc.x - self.touchStartPoint.x, loc.y - self.touchStartPoint.y);
    
    // If moved more than 28pt from initial touch point, cancel
    if (distance > 28.0) {
        [self cancelHolding];
        self.state = UIGestureRecognizerStateCancelled;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self cancelHolding];
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self cancelHolding];
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)cancelHolding {
    [self.initialDelayTimer invalidate];
    self.initialDelayTimer = nil;
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    if (self.isHoldingActive) {
        self.isHoldingActive = NO;
        [self hideHUDAnimated:YES];
    } else {
        [self hideHUDAnimated:NO];
    }
}

- (void)reset {
    [super reset];
    [self cancelHolding];
}

@end

#pragma mark - LarrkGestureOverlay

@interface LarrkGestureOverlay ()
@property (nonatomic, weak) UIWindow *targetWindow;
@property (nonatomic, strong) LarrkHoldGestureRecognizer *holdGesture;
@end

@implementation LarrkGestureOverlay

+ (instancetype)shared {
    static LarrkGestureOverlay *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LarrkGestureOverlay alloc] init];
    });
    return instance;
}

- (void)startListening {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)handleAppDidBecomeActive:(NSNotification *)notification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupOverlayOnActiveWindow];
    });
}

- (UIWindow *)findKeyWindow {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) {
                        return w;
                    }
                    if (!window) window = w;
                }
            }
        }
    }
    if (!window) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    if (!window) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    return window;
}

- (void)setupOverlayOnActiveWindow {
    UIWindow *window = [self findKeyWindow];
    if (window) {
        [self attachToWindow:window];
    }
}

- (void)attachToWindow:(UIWindow *)window {
    if (!window) return;
    if (self.targetWindow == window && self.holdGesture != nil) {
        return; // already attached
    }
    
    self.targetWindow = window;
    if (self.holdGesture) {
        [self.holdGesture.view removeGestureRecognizer:self.holdGesture];
    }
    
    self.holdGesture = [[LarrkHoldGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureTriggered:)];
    [window addGestureRecognizer:self.holdGesture];
}

- (void)handleGestureTriggered:(LarrkHoldGestureRecognizer *)gesture {
    // Handled internally in recognizer upon 100% completion
}

- (UIViewController *)topViewControllerFrom:(UIViewController *)rootVC {
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)rootVC;
        return [self topViewControllerFrom:nav.visibleViewController];
    }
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)rootVC;
        return [self topViewControllerFrom:tab.selectedViewController];
    }
    if (rootVC.presentedViewController) {
        return [self topViewControllerFrom:rootVC.presentedViewController];
    }
    return rootVC;
}

- (void)presentModMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [self findKeyWindow];
        UIViewController *rootVC = window.rootViewController;
        UIViewController *topVC = [self topViewControllerFrom:rootVC];
        if (!topVC) return;
        
        // Don't present if already presented
        if ([topVC isKindOfClass:[LarrkModViewController class]]) return;
        if ([topVC.presentedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)topVC.presentedViewController;
            if ([nav.viewControllers.firstObject isKindOfClass:[LarrkModViewController class]]) {
                return;
            }
        }
        
        LarrkModViewController *modVC = [[LarrkModViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:modVC];
        nav.modalPresentationStyle = UIModalPresentationPageSheet;
        [topVC presentViewController:nav animated:YES completion:nil];
    });
}

@end
