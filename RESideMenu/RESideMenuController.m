//
// REFrostedViewController.m
// RESideMenu
//
// Copyright (c) 2013-2014 Roman Efimov (https://github.com/romaonthego)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "RESideMenuController.h"
#import "UIViewController+RESideMenu.h"
#import "RECommonFunctions.h"
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSInteger, RESideMenuControllerDirection)
{
    RESideMenuControllerDirectionLeft,
    RESideMenuControllerDirectionRight
};

@interface RESideMenuController ()

@property (strong, readwrite, nonatomic) UIImageView *backgroundImageView;
@property (assign, readwrite, nonatomic) BOOL visible;
@property (assign, readwrite, nonatomic) BOOL leftMenuVisible;
@property (assign, readwrite, nonatomic) BOOL rightMenuVisible;
@property (assign, readwrite, nonatomic) CGPoint originalPoint;
@property (strong, readwrite, nonatomic) UIButton *contentButton;
@property (strong, readwrite, nonatomic) UIView *menuViewContainer;
@property (strong, readwrite, nonatomic) UIView *contentViewContainer;
@property (assign, readwrite, nonatomic) BOOL didNotifyDelegate;
@property (strong, nonatomic) CALayer *perspectiveAnimationLayer;
@property (strong, nonatomic) CALayer *perspectiveShadowLayer;
@property (strong, nonatomic) UIImage *contentViewImageSnapshot;

@end

@implementation RESideMenuController

#pragma mark -
#pragma mark Instance lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

#if __IPHONE_8_0
- (void)awakeFromNib
{
    if (self.contentViewStoryboardID) {
        self.contentViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.contentViewStoryboardID];
    }
    if (self.leftMenuViewStoryboardID) {
        self.leftMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.leftMenuViewStoryboardID];
    }
    if (self.rightMenuViewStoryboardID) {
        self.rightMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.rightMenuViewStoryboardID];
    }
}
#endif

- (void)commonInit
{
    _menuViewContainer = [[UIView alloc] init];
    _contentViewContainer = [[UIView alloc] init];

    _animationDuration = 0.35f;
    _interactivePopGestureRecognizerEnabled = YES;

    _menuViewControllerTransformation = CGAffineTransformMakeScale(1.5f, 1.5f);

    _scaleContentView = YES;
    _scaleBackgroundImageView = YES;
    _scaleMenuView = YES;
    _fadeMenuView = YES;

    _parallaxEnabled = NO;
    _parallaxMenuMinimumRelativeValue = -15;
    _parallaxMenuMaximumRelativeValue = 15;
    _parallaxContentMinimumRelativeValue = -25;
    _parallaxContentMaximumRelativeValue = 25;

    _bouncesHorizontally = YES;

    _panGestureEnabled = YES;
    _panFromEdge = YES;
    _panMinimumOpenThreshold = 60.0;

    _contentViewShadowEnabled = NO;
    _contentViewShadowColor = [UIColor blackColor];
    _contentViewShadowOffset = CGSizeZero;
    _contentViewShadowOpacity = 0.4f;
    _contentViewShadowRadius = 8.0f;
    _contentViewFadeOutAlpha = 1.0f;
    _contentViewInLandscapeOffsetCenterX = 30.f;
    _contentViewInPortraitOffsetCenterX = 30.f;
    _contentViewScaleValue = 0.7f;

    _perspectiveRotationAmountRadians = 0.75;
    _perspectiveShadowOpacity = 0.5f;
}

#pragma mark -
#pragma mark Public methods

- (id)initWithContentViewController:(UIViewController *)contentViewController leftMenuViewController:(UIViewController *)leftMenuViewController rightMenuViewController:(UIViewController *)rightMenuViewController
{
    self = [self init];
    if (self) {
        _contentViewController = contentViewController;
        _leftMenuViewController = leftMenuViewController;
        _rightMenuViewController = rightMenuViewController;
    }
    return self;
}

- (void)presentLeftMenuViewController
{
    [self presentMenuViewContainerWithMenuViewController:self.leftMenuViewController];
    [self showLeftMenuViewController];
}

- (void)presentRightMenuViewController
{
    [self presentMenuViewContainerWithMenuViewController:self.rightMenuViewController];
    [self showRightMenuViewController];
}

- (void)hideMenuViewController
{
    [self hideMenuViewControllerAnimated:YES];
}

-(UIImage *)contentViewImageSnapshot {
    if (!_contentViewImageSnapshot) {
        UIEdgeInsets edgeInsets = UIEdgeInsetsZero;
        _contentViewImageSnapshot = [self renderImageFromView:self.contentViewContainer withRect:self.contentViewContainer.bounds transparentInsets:edgeInsets];
    }

    return _contentViewImageSnapshot;
}

- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated
{
    if (_contentViewController == contentViewController) {
        return;
    }

    if (!animated) {
        [self setContentViewController:contentViewController];
    } else {
        [self addChildViewController:contentViewController];
        contentViewController.view.alpha = 0;
        contentViewController.view.frame = self.contentViewContainer.bounds;
        [self.contentViewContainer addSubview:contentViewController.view];
        [UIView animateWithDuration:self.animationDuration animations:^{
            contentViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [self hideViewController:self.contentViewController];
            [contentViewController didMoveToParentViewController:self];
            _contentViewController = contentViewController;

            [self statusBarNeedsAppearanceUpdate];
            [self updateContentViewShadow];
            
            if (self.visible) {
                [self addContentViewControllerMotionEffects];
            }
        }];
    }
}

#pragma mark View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.image = self.backgroundImage;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView;
    });
    self.contentButton = ({
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectNull];
        [button addTarget:self action:@selector(hideMenuViewController) forControlEvents:UIControlEventTouchUpInside];
        button;
    });

    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.menuViewContainer];
    [self.view addSubview:self.contentViewContainer];

    self.menuViewContainer.frame = self.view.bounds;
    self.menuViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    if (self.leftMenuViewController) {
        [self addChildViewController:self.leftMenuViewController];
        self.leftMenuViewController.view.frame = self.view.bounds;
        self.leftMenuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.menuViewContainer addSubview:self.leftMenuViewController.view];
        [self.leftMenuViewController didMoveToParentViewController:self];
    }

    if (self.rightMenuViewController) {
        [self addChildViewController:self.rightMenuViewController];
        self.rightMenuViewController.view.frame = self.view.bounds;
        self.rightMenuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.menuViewContainer addSubview:self.rightMenuViewController.view];
        [self.rightMenuViewController didMoveToParentViewController:self];
    }

    self.contentViewContainer.frame = self.view.bounds;
    self.contentViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self addChildViewController:self.contentViewController];
    self.contentViewController.view.frame = self.view.bounds;
    [self.contentViewContainer addSubview:self.contentViewController.view];
    [self.contentViewController didMoveToParentViewController:self];

    self.menuViewContainer.alpha = !self.fadeMenuView ?: 0;
    if (self.scaleBackgroundImageView)
        self.backgroundImageView.transform = CGAffineTransformMakeScale(1.7f, 1.7f);

    [self addMenuViewControllerMotionEffects];

    if (self.panGestureEnabled) {
        self.view.multipleTouchEnabled = NO;
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
        panGestureRecognizer.delegate = self;
        [self.view addGestureRecognizer:panGestureRecognizer];
    }

    [self updateContentViewShadow];
    
    [self performInitialAppearanceTransitionCallsForControllerIfRequired:self.leftMenuViewController];
    [self performInitialAppearanceTransitionCallsForControllerIfRequired:self.rightMenuViewController];
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.leftMenuVisible) {
        [self.leftMenuViewController beginAppearanceTransition:YES animated:animated];
    } else if (self.rightMenuVisible) {
        [self.rightMenuViewController beginAppearanceTransition:YES animated:animated];
    } else {
        [self.contentViewController beginAppearanceTransition:YES animated:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.leftMenuVisible) {
        [self.leftMenuViewController endAppearanceTransition];
    } else if (self.rightMenuVisible) {
        [self.rightMenuViewController endAppearanceTransition];
    } else {
        [self.contentViewController endAppearanceTransition];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.leftMenuVisible) {
        [self.leftMenuViewController beginAppearanceTransition:NO animated:animated];
    } else if (self.rightMenuVisible) {
        [self.rightMenuViewController beginAppearanceTransition:NO animated:animated];
    } else {
        [self.contentViewController beginAppearanceTransition:NO animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.leftMenuVisible) {
        [self.leftMenuViewController endAppearanceTransition];
    } else if (self.rightMenuVisible) {
        [self.rightMenuViewController endAppearanceTransition];
    } else {
        [self.contentViewController endAppearanceTransition];
    }
}

#pragma mark - CALayer animation methods (private)

/**
 * Render an image from a given view with transparent edges. This is useful for
 * CALayer 3d transforms, as it will give a nice anti-aliased edge to edges that
 * are not perfectly horizontal or vertical.
 *
 *  @param view   The view to render
 *  @param frame  Frame you wish to render. Pass the view's bounds to render the entire view, or a smaller rect to render a portion of the view.
 *  @param insets The size of the transparent margins to create.
 *
 *  @return The rendered image with specified transparent edges.
 */
- (UIImage *)renderImageFromView:(UIView *)view withRect:(CGRect)frame transparentInsets:(UIEdgeInsets)insets
{
    CGSize imageSizeWithBorder = CGSizeMake(frame.size.width + insets.left + insets.right, frame.size.height + insets.top + insets.bottom);

    UIGraphicsBeginImageContextWithOptions(imageSizeWithBorder, UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero), 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToRect(context, (CGRect){{insets.left, insets.top}, frame.size});
    CGContextTranslateCTM(context, -frame.origin.x + insets.left, -frame.origin.y + insets.top);
    [view.layer renderInContext:context];
    UIImage *renderedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return renderedImage;
}

/**
 *  Render a duplicate of an image with transparent edges. This is useful for
 * CALayer 3d transforms, as it will give a nice anti-aliased edge to edges that
 * are not perfectly horizontal or vertical.

 *
 *  @param image  The source image to render
 *  @param insets The size of the transparent margins to create.
 *
 *  @return The rendered image with specified transparent edges.
 */
- (UIImage *)renderImageForAntialiasing:(UIImage *)image withTransparentInsets:(UIEdgeInsets)insets
{
    CGSize imageSizeWithBorder = CGSizeMake([image size].width + insets.left + insets.right, [image size].height + insets.top + insets.bottom);
    UIGraphicsBeginImageContextWithOptions(imageSizeWithBorder, UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero), 0);
    [image drawInRect:(CGRect){{insets.left, insets.top}, [image size]}];
    UIImage *renderedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return renderedImage;
}

- (void)buildLayersForAnimation
{
    UIView *contentView = self.contentViewContainer;
    UIEdgeInsets edgeInsets = UIEdgeInsetsZero;

    UIImage *contentViewSnapshot = nil;
    if ([self.delegate respondsToSelector:@selector(contentSnapshotImageForSideMenu:)]) {
        UIImage *sourceImage = [self.delegate contentSnapshotImageForSideMenu:self];
        contentViewSnapshot = [self renderImageForAntialiasing:sourceImage withTransparentInsets:edgeInsets];
    } else {
        contentViewSnapshot = self.contentViewImageSnapshot;
    }
    CALayer *animationLayer = [CALayer layer];
    animationLayer.frame = contentView.frame;
    animationLayer.anchorPoint = CGPointZero;
    animationLayer.position = contentView.frame.origin;
    animationLayer.contents = (id)contentViewSnapshot.CGImage;
    [animationLayer setMasksToBounds:YES];
    animationLayer.cornerRadius = 6.0f;

    // m34 on the transform dictates perspective depth. We make it proportional
    // to the height of the original view being transformed for best effect.
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0 / (contentView.bounds.size.height * 4.6666667);

    self.perspectiveAnimationLayer = animationLayer;
    self.perspectiveAnimationLayer.shouldRasterize = YES;
    self.perspectiveAnimationLayer.rasterizationScale = [UIScreen mainScreen].scale;
    [contentView.layer addSublayer:self.perspectiveAnimationLayer];
    [self.contentViewController.view setHidden:YES];

    contentView.layer.sublayerTransform = transform;

    self.perspectiveShadowLayer = [self createShadowLayer];
    [self.perspectiveAnimationLayer addSublayer:self.perspectiveShadowLayer];
}

- (CALayer *)createShadowLayer
{
    CAGradientLayer *shadowLayer = [[CAGradientLayer alloc] init];
    shadowLayer.frame = self.perspectiveAnimationLayer.frame;
    shadowLayer.startPoint = CGPointMake(0.0, 0.5);
    shadowLayer.endPoint = CGPointMake(1.0, 0.5);
    shadowLayer.opacity = 0.0f;

    shadowLayer.colors = @[ (id)[UIColor clearColor].CGColor, (id)[UIColor blackColor].CGColor, (id)[UIColor blackColor].CGColor ];
    return shadowLayer;
}

- (void)cleanupAnimationLayers
{
    [self.contentViewController.view setHidden:NO];
    [self.perspectiveAnimationLayer removeFromSuperlayer];
    self.perspectiveAnimationLayer = nil;
    [self.perspectiveShadowLayer removeFromSuperlayer];
    self.perspectiveShadowLayer = nil;
}

#pragma mark - Private methods

- (void)presentMenuViewContainerWithMenuViewController:(UIViewController *)menuViewController
{
    self.menuViewContainer.transform = CGAffineTransformIdentity;
    if (self.scaleBackgroundImageView) {
        self.backgroundImageView.transform = CGAffineTransformIdentity;
        self.backgroundImageView.frame = self.view.bounds;
    }
    self.menuViewContainer.frame = self.view.bounds;
    if (self.scaleMenuView) {
        self.menuViewContainer.transform = self.menuViewControllerTransformation;
    }
    self.menuViewContainer.alpha = !self.fadeMenuView ?: 0;
    if (self.scaleBackgroundImageView)
        self.backgroundImageView.transform = CGAffineTransformMakeScale(1.7f, 1.7f);

    if ([self.delegate conformsToProtocol:@protocol(RESideMenuControllerDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:willShowMenuViewController:)]) {
        [self.delegate sideMenu:self willShowMenuViewController:menuViewController];
    }
}

-(void)showMenuControllerFromDirection:(RESideMenuControllerDirection)menuDirection
{
    if(menuDirection == RESideMenuControllerDirectionLeft) {
        self.leftMenuViewController.view.hidden = NO;
        self.rightMenuViewController.view.hidden = YES;
    } else {
        self.leftMenuViewController.view.hidden = YES;
        self.rightMenuViewController.view.hidden = NO;
    }
    
    [self.view.window endEditing:YES];

    if (CGAffineTransformIsIdentity(self.contentViewContainer.transform)) {
        [self cleanupAnimationLayers];
        [self buildLayersForAnimation];
    }

    [self addContentButton];
    [self updateContentViewShadow];
    [self resetContentViewScale];
    [self.leftMenuViewController beginAppearanceTransition:YES animated:YES];
    [self.contentViewController beginAppearanceTransition:NO animated:YES];
    
    if(menuDirection == RESideMenuControllerDirectionRight) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    
    [UIView animateWithDuration:self.animationDuration animations:^{
        if (self.scaleContentView) {
            self.contentViewContainer.transform = CGAffineTransformMakeScale(self.contentViewScaleValue, self.contentViewScaleValue);
        } else {
            self.contentViewContainer.transform = CGAffineTransformIdentity;
        }
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            if(menuDirection == RESideMenuControllerDirectionLeft) {
                self.contentViewContainer.center = CGPointMake((UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? self.contentViewInLandscapeOffsetCenterX + CGRectGetWidth(self.view.frame) : self.contentViewInPortraitOffsetCenterX + CGRectGetWidth(self.view.frame)), self.contentViewContainer.center.y);
            } else {
                self.contentViewContainer.center = CGPointMake((UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? -self.contentViewInLandscapeOffsetCenterX : -self.contentViewInPortraitOffsetCenterX), self.contentViewContainer.center.y);
            }
        } else {
            self.contentViewContainer.center = CGPointMake((UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? self.contentViewInLandscapeOffsetCenterX + CGRectGetHeight(self.view.frame) : self.contentViewInPortraitOffsetCenterX + CGRectGetWidth(self.view.frame)), self.contentViewContainer.center.y);
        }
        
        self.menuViewContainer.alpha = !self.fadeMenuView ?: 1.0f;
        self.contentViewContainer.alpha = self.contentViewFadeOutAlpha;
        self.menuViewContainer.transform = CGAffineTransformIdentity;
        if (self.scaleBackgroundImageView) {
            self.backgroundImageView.transform = CGAffineTransformIdentity;
        }
        
    } completion:^(BOOL finished) {
        if(menuDirection == RESideMenuControllerDirectionLeft) {
            [self addContentViewControllerMotionEffects];
        }
        
        if (!self.visible && [self.delegate conformsToProtocol:@protocol(RESideMenuControllerDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:didShowMenuViewController:)]) {
            if(menuDirection == RESideMenuControllerDirectionLeft) {
                [self.delegate sideMenu:self didShowMenuViewController:self.leftMenuViewController];
            } else {
                [self.delegate sideMenu:self didShowMenuViewController:self.rightMenuViewController];
            }
        }
        if(menuDirection == RESideMenuControllerDirectionRight) {
            self.visible = !(self.contentViewContainer.frame.size.width == self.view.bounds.size.width && self.contentViewContainer.frame.size.height == self.view.bounds.size.height && self.contentViewContainer.frame.origin.x == 0 && self.contentViewContainer.frame.origin.y == 0);
            self.rightMenuVisible = self.visible;
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            [self.rightMenuViewController endAppearanceTransition];
        } else {
            self.visible = YES;
            self.leftMenuVisible = YES;
            [self.leftMenuViewController endAppearanceTransition];
        }
        [self.contentViewController endAppearanceTransition];
    }];
    
    // Perspective rotation animation
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];

    animation.fromValue = [(NSNumber *)self.perspectiveAnimationLayer valueForKeyPath:@"transform.rotation.y"];
    
    if(menuDirection == RESideMenuControllerDirectionLeft) {
        animation.toValue = @(self.perspectiveRotationAmountRadians);
    } else {
        animation.toValue = @(-self.perspectiveRotationAmountRadians);
    }

    animation.duration = self.animationDuration;
    [self.perspectiveAnimationLayer setValue:animation.toValue forKeyPath:@"transform.rotation.y"];
    [self.perspectiveAnimationLayer addAnimation:animation forKey:@"transform"];
    
    // Perspective shadow animation
    CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    shadowAnimation.fromValue = (NSNumber *)[self.perspectiveShadowLayer valueForKeyPath:@"opacity"];
    shadowAnimation.toValue = @(self.perspectiveShadowOpacity);
    shadowAnimation.duration = self.animationDuration;
    self.perspectiveShadowLayer.opacity = self.perspectiveShadowOpacity;
    [self.perspectiveShadowLayer addAnimation:shadowAnimation forKey:@"opacity"];
    
    [self statusBarNeedsAppearanceUpdate];
}

- (void)showRightMenuViewController
{
    [self showMenuControllerFromDirection:RESideMenuControllerDirectionRight];
}

- (void)showLeftMenuViewController
{
    [self showMenuControllerFromDirection:RESideMenuControllerDirectionLeft];
}

- (void)hideViewController:(UIViewController *)viewController
{
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

- (void)hideMenuViewControllerAnimated:(BOOL)animated
{
    BOOL isHidingRightMenu = self.rightMenuVisible;
    if ([self.delegate conformsToProtocol:@protocol(RESideMenuControllerDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:willHideMenuViewController:)]) {
        [self.delegate sideMenu:self willHideMenuViewController:isHidingRightMenu ? self.rightMenuViewController : self.leftMenuViewController];
    }

    self.visible = NO;
    self.leftMenuVisible = NO;
    self.rightMenuVisible = NO;
    [self.contentButton removeFromSuperview];
    UIViewController *menu = isHidingRightMenu ? self.rightMenuViewController : self.leftMenuViewController;
    [menu beginAppearanceTransition:NO animated:animated];
    [self.contentViewController beginAppearanceTransition:YES animated:animated];

    __typeof(self) __weak weakSelf = self;
    void (^animationBlock)(void) = ^{
        __typeof (weakSelf) __strong strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.contentViewContainer.transform = CGAffineTransformIdentity;
        strongSelf.contentViewContainer.frame = strongSelf.view.bounds;
        if (strongSelf.scaleMenuView) {
            strongSelf.menuViewContainer.transform = strongSelf.menuViewControllerTransformation;
        }
        strongSelf.menuViewContainer.alpha = !self.fadeMenuView ?: 0;
        strongSelf.contentViewContainer.alpha = 1;

        if (strongSelf.scaleBackgroundImageView) {
            strongSelf.backgroundImageView.transform = CGAffineTransformMakeScale(1.7f, 1.7f);
        }
        if (strongSelf.parallaxEnabled) {
            IF_IOS7_OR_GREATER(
               for (UIMotionEffect *effect in strongSelf.contentViewContainer.motionEffects) {
                   [strongSelf.contentViewContainer removeMotionEffect:effect];
               }
            );
        }
        [menu endAppearanceTransition];
        [self.contentViewController endAppearanceTransition];
    };
    void (^completionBlock)(void) = ^{
        __typeof (weakSelf) __strong strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (!strongSelf.visible && [strongSelf.delegate conformsToProtocol:@protocol(RESideMenuControllerDelegate)] && [strongSelf.delegate respondsToSelector:@selector(sideMenu:didHideMenuViewController:)]) {
            [strongSelf.delegate sideMenu:strongSelf didHideMenuViewController:isHidingRightMenu ? strongSelf.rightMenuViewController : strongSelf.leftMenuViewController];
        }
    };

    if (animated) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [UIView animateWithDuration:self.animationDuration animations:^{
            animationBlock();
        } completion:^(BOOL finished) {
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            completionBlock();
        }];
    } else {
        animationBlock();
        completionBlock();
    }

    NSNumber *rotationFromValue = @(0.0);
    if (isHidingRightMenu) {
        rotationFromValue = @(-self.perspectiveRotationAmountRadians);
    } else {
        rotationFromValue = @(self.perspectiveRotationAmountRadians);
    }

    // Reverse perspective rotation and shadow animations
    [CATransaction begin];
    {
        [CATransaction setCompletionBlock:^{
            self.contentViewContainer.layer.transform = CATransform3DIdentity;
            [self cleanupAnimationLayers];
            self.contentViewImageSnapshot = nil;
        }];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
        animation.fromValue = (NSNumber *)[self.perspectiveAnimationLayer valueForKeyPath:@"transform.rotation.y"];
        animation.toValue = @0.0;
        animation.duration = self.animationDuration;
        [self.perspectiveAnimationLayer setValue:@0.0 forKeyPath:@"transform.rotation.y"];
        [self.perspectiveAnimationLayer addAnimation:animation forKey:@"transform"];

        // Perspective shadow animation
        CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        shadowAnimation.fromValue = @(self.perspectiveShadowLayer.opacity);
        shadowAnimation.toValue = @0.0;
        shadowAnimation.duration = self.animationDuration;
        self.perspectiveShadowLayer.opacity = 0.0;
        [self.perspectiveShadowLayer addAnimation:shadowAnimation forKey:@"opacity"];
    }
    [CATransaction commit];

    [self statusBarNeedsAppearanceUpdate];
}

- (void)addContentButton
{
    if (self.contentButton.superview)
        return;

    self.contentButton.autoresizingMask = UIViewAutoresizingNone;
    self.contentButton.frame = self.contentViewContainer.bounds;
    self.contentButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentViewContainer addSubview:self.contentButton];
}

- (void)statusBarNeedsAppearanceUpdate
{
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [UIView animateWithDuration:0.3f animations:^{
            [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
        }];
    }
}

- (void)updateContentViewShadow
{
    if (self.contentViewShadowEnabled) {
        CALayer *layer = self.contentViewContainer.layer;
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:layer.bounds];
        layer.shadowPath = path.CGPath;
        layer.shadowColor = self.contentViewShadowColor.CGColor;
        layer.shadowOffset = self.contentViewShadowOffset;
        layer.shadowOpacity = self.contentViewShadowOpacity;
        layer.shadowRadius = self.contentViewShadowRadius;
    }
}

- (void)resetContentViewScale
{
    CGAffineTransform t = self.contentViewContainer.transform;
    CGFloat scale = sqrt(t.a * t.a + t.c * t.c);
    CGRect frame = self.contentViewContainer.frame;
    self.contentViewContainer.transform = CGAffineTransformIdentity;
    self.contentViewContainer.transform = CGAffineTransformMakeScale(scale, scale);
    self.contentViewContainer.frame = frame;
}

- (void)performInitialAppearanceTransitionCallsForControllerIfRequired:(UIViewController *)controller {
    if (controller.childViewControllers.count > 0) {
        [controller beginAppearanceTransition:YES animated:NO];
        [controller endAppearanceTransition];
        /**
         *  Must perform the disappear appearance transition in the next runloop
         *  otherwise iOS realises that it doesn't need to calculate anything.
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            [controller beginAppearanceTransition:NO animated:NO];
            [controller endAppearanceTransition];
        });
    }
}

#pragma mark - iOS 7 Motion Effects (Private)

- (void)addMenuViewControllerMotionEffects
{
    if (self.parallaxEnabled) {
        IF_IOS7_OR_GREATER(
            for (UIMotionEffect *effect in self.menuViewContainer.motionEffects) {
               [self.menuViewContainer removeMotionEffect:effect];
            } UIInterpolatingMotionEffect *interpolationHorizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
            interpolationHorizontal.minimumRelativeValue = @(self.parallaxMenuMinimumRelativeValue);
            interpolationHorizontal.maximumRelativeValue = @(self.parallaxMenuMaximumRelativeValue);

            UIInterpolatingMotionEffect *interpolationVertical = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
            interpolationVertical.minimumRelativeValue = @(self.parallaxMenuMinimumRelativeValue);
            interpolationVertical.maximumRelativeValue = @(self.parallaxMenuMaximumRelativeValue);

            [self.menuViewContainer addMotionEffect:interpolationHorizontal];
            [self.menuViewContainer addMotionEffect:interpolationVertical];);
    }
}

- (void)addContentViewControllerMotionEffects
{
    if (self.parallaxEnabled) {
        IF_IOS7_OR_GREATER(
            for (UIMotionEffect *effect in self.contentViewContainer.motionEffects) {
               [self.contentViewContainer removeMotionEffect:effect];
            }
            [UIView animateWithDuration:0.2 animations:^{
                UIInterpolatingMotionEffect *interpolationHorizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
                interpolationHorizontal.minimumRelativeValue = @(self.parallaxContentMinimumRelativeValue);
                interpolationHorizontal.maximumRelativeValue = @(self.parallaxContentMaximumRelativeValue);

                UIInterpolatingMotionEffect *interpolationVertical = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
                interpolationVertical.minimumRelativeValue = @(self.parallaxContentMinimumRelativeValue);
                interpolationVertical.maximumRelativeValue = @(self.parallaxContentMaximumRelativeValue);

                [self.contentViewContainer addMotionEffect:interpolationHorizontal];
                [self.contentViewContainer addMotionEffect:interpolationVertical];
            }];
        );
    }
}

#pragma mark - UIGestureRecognizer Delegate (Private)

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    IF_IOS7_OR_GREATER(
                       if (self.interactivePopGestureRecognizerEnabled && [self.contentViewController isKindOfClass:[UINavigationController class]]) {
                           UINavigationController *navigationController = (UINavigationController *)self.contentViewController;
                           if (navigationController.viewControllers.count > 1 && navigationController.interactivePopGestureRecognizer.enabled) {
                               return NO;
                           }
                       });

    if (self.panFromEdge && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && !self.visible) {
        CGPoint point = [touch locationInView:gestureRecognizer.view];
        if (point.x < 20.0 || point.x > self.view.frame.size.width - 20.0) {
            return YES;
        } else {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Pan gesture recognizer (Private)

- (void)panGestureRecognized:(UIPanGestureRecognizer *)recognizer
{
    if ([self.delegate conformsToProtocol:@protocol(RESideMenuControllerDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:didRecognizePanGesture:)])
        [self.delegate sideMenu:self didRecognizePanGesture:recognizer];

    if (!self.panGestureEnabled) {
        return;
    }

    CGPoint point = [recognizer translationInView:self.view];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self updateContentViewShadow];

        self.originalPoint = CGPointMake(self.contentViewContainer.center.x - CGRectGetWidth(self.contentViewContainer.bounds) / 2.0,
                                         self.contentViewContainer.center.y - CGRectGetHeight(self.contentViewContainer.bounds) / 2.0);
        self.menuViewContainer.transform = CGAffineTransformIdentity;
        if (self.scaleBackgroundImageView) {
            self.backgroundImageView.transform = CGAffineTransformIdentity;
            self.backgroundImageView.frame = self.view.bounds;
        }
        self.menuViewContainer.frame = self.view.bounds;
        [self addContentButton];
        [self.view.window endEditing:YES];
        self.didNotifyDelegate = NO;
    }

    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat delta = 0;
        if (self.visible) {
            delta = self.originalPoint.x != 0 ? (point.x + self.originalPoint.x) / self.originalPoint.x : 0;
        } else {
            delta = point.x / self.view.frame.size.width;
        }
        delta = MIN(fabs(delta), 1.6);

        CGFloat contentViewScale = self.scaleContentView ? 1 - ((1 - self.contentViewScaleValue) * delta) : 1;

        CGFloat backgroundViewScale = 1.7f - (0.7f * delta);
        CGFloat menuViewScale = 1.5f - (0.5f * delta);

        if (!self.bouncesHorizontally) {
            contentViewScale = MAX(contentViewScale, self.contentViewScaleValue);
            backgroundViewScale = MAX(backgroundViewScale, 1.0);
            menuViewScale = MAX(menuViewScale, 1.0);
        }
        
        self.menuViewContainer.alpha = !self.fadeMenuView ?: delta;
        self.contentViewContainer.alpha = 1 - (1 - self.contentViewFadeOutAlpha) * delta;

        if (self.scaleBackgroundImageView) {
            self.backgroundImageView.transform = CGAffineTransformMakeScale(backgroundViewScale, backgroundViewScale);
        }

        if (self.scaleMenuView) {
            self.menuViewContainer.transform = CGAffineTransformMakeScale(menuViewScale, menuViewScale);
        }

        if (self.scaleBackgroundImageView) {
            if (backgroundViewScale < 1) {
                self.backgroundImageView.transform = CGAffineTransformIdentity;
            }
        }

        if (!self.bouncesHorizontally && self.visible) {
            if (self.contentViewContainer.frame.origin.x > self.contentViewContainer.frame.size.width / 2.0)
                point.x = MIN(0.0, point.x);

            if (self.contentViewContainer.frame.origin.x < -(self.contentViewContainer.frame.size.width / 2.0))
                point.x = MAX(0.0, point.x);
        }

        // Limit size
        if (point.x < 0) {
            point.x = MAX(point.x, -[UIScreen mainScreen].bounds.size.height);
        } else {
            point.x = MIN(point.x, [UIScreen mainScreen].bounds.size.height);
        }
        [recognizer setTranslation:point inView:self.view];

        if (!self.didNotifyDelegate) {
            if (point.x > 0) {
                if (!self.visible && [self.delegate conformsToProtocol:@protocol(RESideMenuControllerDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:willShowMenuViewController:)]) {
                    [self.delegate sideMenu:self willShowMenuViewController:self.leftMenuViewController];
                }
            }
            if (point.x < 0) {
                if (!self.visible && [self.delegate conformsToProtocol:@protocol(RESideMenuControllerDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:willShowMenuViewController:)]) {
                    [self.delegate sideMenu:self willShowMenuViewController:self.rightMenuViewController];
                }
            }
            self.didNotifyDelegate = YES;
        }

        if (contentViewScale > 1) {
            CGFloat oppositeScale = (1 - (contentViewScale - 1));
            self.contentViewContainer.transform = CGAffineTransformMakeScale(oppositeScale, oppositeScale);
            self.contentViewContainer.transform = CGAffineTransformTranslate(self.contentViewContainer.transform, point.x, 0);
        } else {
            self.contentViewContainer.transform = CGAffineTransformMakeScale(contentViewScale, contentViewScale);
            self.contentViewContainer.transform = CGAffineTransformTranslate(self.contentViewContainer.transform, point.x, 0);
        }

        self.leftMenuViewController.view.hidden = self.contentViewContainer.frame.origin.x < 0;
        self.rightMenuViewController.view.hidden = self.contentViewContainer.frame.origin.x > 0;

        if (!self.leftMenuViewController && self.contentViewContainer.frame.origin.x > 0) {
            self.contentViewContainer.transform = CGAffineTransformIdentity;
            self.contentViewContainer.frame = self.view.bounds;
            self.visible = NO;
            self.leftMenuVisible = NO;
        } else if (!self.rightMenuViewController && self.contentViewContainer.frame.origin.x < 0) {
            self.contentViewContainer.transform = CGAffineTransformIdentity;
            self.contentViewContainer.frame = self.view.bounds;
            self.visible = NO;
            self.rightMenuVisible = NO;
        }
        
        //3d rotation
        float fractionFromLeftEdge = CGAffineTransformIsIdentity(self.contentViewContainer.transform) ? 0 : 1 - (contentViewScale - self.contentViewScaleValue) / (1.0 - self.contentViewScaleValue);
        float angle = self.perspectiveRotationAmountRadians * fractionFromLeftEdge;
        [CATransaction begin];
        {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
            animation.fromValue = [(NSNumber *)self.perspectiveAnimationLayer valueForKeyPath:@"transform.rotation.y"];
            animation.toValue = @(angle);
            animation.duration = 0;
            [self.perspectiveAnimationLayer setValue:@(angle) forKeyPath:@"transform.rotation.y"];
            [self.perspectiveAnimationLayer addAnimation:animation forKey:@"transform"];

            CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            float fromOpacityValue = self.perspectiveShadowLayer.opacity;
            opacityAnimation.fromValue = @(fromOpacityValue);
            float opacityToValue = fabsf(fractionFromLeftEdge) * self.perspectiveShadowOpacity;
            opacityAnimation.toValue = @(opacityToValue);
            opacityAnimation.duration = 0;
            self.perspectiveShadowLayer.opacity = opacityToValue;
            [self.perspectiveShadowLayer addAnimation:opacityAnimation forKey:@"opacity"];
        } [CATransaction commit];

        [self statusBarNeedsAppearanceUpdate];
    }

    if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.didNotifyDelegate = NO;


        // Determine whether to hide the menu, or which one to transition to if not
        if (self.panMinimumOpenThreshold > 0 && ((self.contentViewContainer.frame.origin.x < 0 \
                                             && self.contentViewContainer.frame.origin.x > -((NSInteger)self.panMinimumOpenThreshold)) \
                                             || (self.contentViewContainer.frame.origin.x > 0 \
                                             && self.contentViewContainer.frame.origin.x < self.panMinimumOpenThreshold))) {
            // Hide menu as we are near the edges or content view is offscreen
            [self hideMenuViewController];
        } else if (self.contentViewContainer.frame.origin.x == 0) {
            // We are right on the edge
            [self hideMenuViewControllerAnimated:NO];
        } else {
            if ([recognizer velocityInView:self.view].x > 0) {
                // Gesture is swiping right
                if (self.contentViewContainer.frame.origin.x < 0) {
                    [self hideMenuViewController];
                } else {
                    if (self.leftMenuViewController) {
                        [self showLeftMenuViewController];
                    }
                }
            } else {
                //Gesture is swiping left
                if (self.contentViewContainer.frame.origin.x < 20) {
                    if (self.rightMenuViewController) {
                        [self showRightMenuViewController];
                    }
                } else {
                    [self hideMenuViewController];
                }
            }
        }
    }
}

#pragma mark - Setters

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    _backgroundImage = backgroundImage;
    if (self.backgroundImageView)
        self.backgroundImageView.image = backgroundImage;
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    if (!_contentViewController) {
        _contentViewController = contentViewController;
        return;
    }
    [self hideViewController:_contentViewController];
    _contentViewController = contentViewController;

    [self addChildViewController:self.contentViewController];
    self.contentViewController.view.frame = self.view.bounds;
    [self.contentViewContainer addSubview:self.contentViewController.view];
    [self.contentViewController didMoveToParentViewController:self];

    [self updateContentViewShadow];

    if (self.visible) {
        [self addContentViewControllerMotionEffects];
    }
}

- (void)setLeftMenuViewController:(UIViewController *)leftMenuViewController
{
    if (!_leftMenuViewController) {
        _leftMenuViewController = leftMenuViewController;
        return;
    }
    [self hideViewController:_leftMenuViewController];
    _leftMenuViewController = leftMenuViewController;

    [self addChildViewController:self.leftMenuViewController];
    self.leftMenuViewController.view.frame = self.view.bounds;
    self.leftMenuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.menuViewContainer addSubview:self.leftMenuViewController.view];
    [self.leftMenuViewController didMoveToParentViewController:self];

    [self addMenuViewControllerMotionEffects];
    [self.view bringSubviewToFront:self.contentViewContainer];
}

- (void)setRightMenuViewController:(UIViewController *)rightMenuViewController
{
    if (!_rightMenuViewController) {
        _rightMenuViewController = rightMenuViewController;
        return;
    }
    [self hideViewController:_rightMenuViewController];
    _rightMenuViewController = rightMenuViewController;

    [self addChildViewController:self.rightMenuViewController];
    self.rightMenuViewController.view.frame = self.view.bounds;
    self.rightMenuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.menuViewContainer addSubview:self.rightMenuViewController.view];
    [self.rightMenuViewController didMoveToParentViewController:self];

    [self addMenuViewControllerMotionEffects];
    [self.view bringSubviewToFront:self.contentViewContainer];
}

#pragma mark - View Controller Rotation handler

- (BOOL)shouldAutorotate
{
    return self.contentViewController.shouldAutorotate;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.visible) {
        self.menuViewContainer.bounds = self.view.bounds;
        self.contentViewContainer.transform = CGAffineTransformIdentity;
        self.contentViewContainer.frame = self.view.bounds;

        if (self.scaleContentView) {
            self.contentViewContainer.transform = CGAffineTransformMakeScale(self.contentViewScaleValue, self.contentViewScaleValue);
        } else {
            self.contentViewContainer.transform = CGAffineTransformIdentity;
        }

        CGPoint center;
        if (self.leftMenuVisible) {
            if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
                center = CGPointMake((UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? self.contentViewInLandscapeOffsetCenterX + CGRectGetWidth(self.view.frame) : self.contentViewInPortraitOffsetCenterX + CGRectGetWidth(self.view.frame)), self.contentViewContainer.center.y);
            } else {
                center = CGPointMake((UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? self.contentViewInLandscapeOffsetCenterX + CGRectGetHeight(self.view.frame) : self.contentViewInPortraitOffsetCenterX + CGRectGetWidth(self.view.frame)), self.contentViewContainer.center.y);
            }
        } else {
            center = CGPointMake((UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? -self.contentViewInLandscapeOffsetCenterX : -self.contentViewInPortraitOffsetCenterX), self.contentViewContainer.center.y);
        }

        self.contentViewContainer.center = center;
    }

    [self updateContentViewShadow];
}

#pragma mark - Status Bar Appearance Management

- (UIStatusBarStyle)preferredStatusBarStyle
{
    UIStatusBarStyle statusBarStyle = UIStatusBarStyleDefault;
    IF_IOS7_OR_GREATER(
        statusBarStyle = self.visible ? self.menuPreferredStatusBarStyle : self.contentViewController.preferredStatusBarStyle;
        if (self.contentViewContainer.frame.origin.y > 10) {
           statusBarStyle = self.menuPreferredStatusBarStyle;
        } else {
           statusBarStyle = self.contentViewController.preferredStatusBarStyle;
        });
    return statusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    BOOL statusBarHidden = NO;
    IF_IOS7_OR_GREATER(
        statusBarHidden = self.visible ? self.menuPrefersStatusBarHidden : self.contentViewController.prefersStatusBarHidden;
        if (self.contentViewContainer.frame.origin.y > 10) {
            statusBarHidden = self.menuPrefersStatusBarHidden;
        } else {
            statusBarHidden = self.contentViewController.prefersStatusBarHidden;
        });
    return statusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    UIStatusBarAnimation statusBarAnimation = UIStatusBarAnimationNone;
    IF_IOS7_OR_GREATER(
        statusBarAnimation = self.visible ? self.leftMenuViewController.preferredStatusBarUpdateAnimation : self.contentViewController.preferredStatusBarUpdateAnimation;
        if (self.contentViewContainer.frame.origin.y > 10) {
            statusBarAnimation = self.leftMenuViewController.preferredStatusBarUpdateAnimation;
        } else {
            statusBarAnimation = self.contentViewController.preferredStatusBarUpdateAnimation;
        });
    return statusBarAnimation;
}

@end
