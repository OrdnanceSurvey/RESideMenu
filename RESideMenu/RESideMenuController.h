//
// REFrostedViewController.h
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

#import <UIKit/UIKit.h>
#import "UIViewController+RESideMenu.h"

#ifndef IBInspectable
#define IBInspectable
#endif

@protocol RESideMenuControllerDelegate;

@interface RESideMenuController : UIViewController<UIGestureRecognizerDelegate>

#if __IPHONE_8_0
@property (strong, readwrite, nonatomic) IBInspectable NSString *contentViewStoryboardID;
@property (strong, readwrite, nonatomic) IBInspectable NSString *leftMenuViewStoryboardID;
@property (strong, readwrite, nonatomic) IBInspectable NSString *rightMenuViewStoryboardID;
#endif

@property (strong, readwrite, nonatomic) UIViewController *contentViewController;
@property (strong, readwrite, nonatomic) UIViewController *leftMenuViewController;
@property (strong, readwrite, nonatomic) UIViewController *rightMenuViewController;
@property (weak, readwrite, nonatomic) id<RESideMenuControllerDelegate> delegate;

@property (assign, readwrite, nonatomic) NSTimeInterval animationDuration;
@property (strong, readwrite, nonatomic) IBInspectable UIImage *backgroundImage;
@property (assign, readwrite, nonatomic) BOOL panGestureEnabled;
@property (assign, readwrite, nonatomic) BOOL panFromEdge;
@property (assign, readwrite, nonatomic) NSUInteger panMinimumOpenThreshold;
@property (assign, readwrite, nonatomic) IBInspectable BOOL interactivePopGestureRecognizerEnabled;
@property (assign, readwrite, nonatomic) IBInspectable BOOL fadeMenuView;
@property (assign, readwrite, nonatomic) IBInspectable BOOL scaleContentView;
@property (assign, readwrite, nonatomic) IBInspectable BOOL scaleBackgroundImageView;
@property (assign, readwrite, nonatomic) IBInspectable BOOL scaleMenuView;
@property (assign, readwrite, nonatomic) IBInspectable BOOL contentViewShadowEnabled;
@property (strong, readwrite, nonatomic) IBInspectable UIColor *contentViewShadowColor;
@property (assign, readwrite, nonatomic) IBInspectable CGSize contentViewShadowOffset;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat contentViewShadowOpacity;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat contentViewShadowRadius;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat contentViewFadeOutAlpha;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat contentViewScaleValue;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat contentViewInLandscapeOffsetCenterX;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat contentViewInPortraitOffsetCenterX;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat parallaxMenuMinimumRelativeValue;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat parallaxMenuMaximumRelativeValue;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat parallaxContentMinimumRelativeValue;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat parallaxContentMaximumRelativeValue;
@property (assign, readwrite, nonatomic) CGAffineTransform menuViewControllerTransformation;
@property (assign, readwrite, nonatomic) IBInspectable BOOL parallaxEnabled;
@property (assign, readwrite, nonatomic) IBInspectable BOOL bouncesHorizontally;
@property (assign, readwrite, nonatomic) UIStatusBarStyle menuPreferredStatusBarStyle;
@property (assign, readwrite, nonatomic) IBInspectable BOOL menuPrefersStatusBarHidden;
@property (assign, readwrite, nonatomic) IBInspectable double perspectiveRotationAmountRadians;
@property (assign, readwrite, nonatomic) IBInspectable float perspectiveShadowOpacity;

- (id)initWithContentViewController:(UIViewController *)contentViewController
             leftMenuViewController:(UIViewController *)leftMenuViewController
            rightMenuViewController:(UIViewController *)rightMenuViewController;
- (void)presentLeftMenuViewController;
- (void)presentRightMenuViewController;
- (void)hideMenuViewController;
- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated;

@end

@protocol RESideMenuControllerDelegate<NSObject>

@optional
- (void)sideMenu:(RESideMenuController *)sideMenu didRecognizePanGesture:(UIPanGestureRecognizer *)recognizer;
- (void)sideMenu:(RESideMenuController *)sideMenu willShowMenuViewController:(UIViewController *)menuViewController;
- (void)sideMenu:(RESideMenuController *)sideMenu didShowMenuViewController:(UIViewController *)menuViewController;
- (void)sideMenu:(RESideMenuController *)sideMenu willHideMenuViewController:(UIViewController *)menuViewController;
- (void)sideMenu:(RESideMenuController *)sideMenu didHideMenuViewController:(UIViewController *)menuViewController;

- (UIImage *)contentSnapshotImageForSideMenu:(RESideMenuController *)sideMenu;

@end
