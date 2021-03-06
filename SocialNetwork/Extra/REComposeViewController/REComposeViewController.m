//
// REComposeViewController.m
// REComposeViewController
//
// Copyright (c) 2013 Roman Efimov (https://github.com/romaonthego)
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

#import "REComposeViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface REComposeViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate>

@property (strong, readonly, nonatomic) REComposeBackgroundView *backgroundView;
@property (strong, readonly, nonatomic) UIView *containerView;
@property (strong, readonly, nonatomic) REComposeSheetView *sheetView;
@property (assign, readwrite, nonatomic) BOOL userUpdatedAttachment;

@end

@implementation REComposeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _cornerRadius = (REUIKitIsFlatMode()) ? 6 : 10;
        _sheetView = [[REComposeSheetView alloc] initWithFrame:CGRectMake(0, 0, self.currentWidth, SCR_H / 2)];
        self.tintColor = [UIColor whiteColor]; //[UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1.0];
    }
    return self;
}

- (int)currentWidth
{
    UIScreen *screen = [UIScreen mainScreen];
    return (!UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) ? screen.bounds.size.width : screen.bounds.size.height;
}

- (void)loadView
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    self.view = [[UIView alloc] initWithFrame:rootViewController.view.bounds];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _backgroundView = [[REComposeBackgroundView alloc] initWithFrame:self.view.bounds];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _backgroundView.centerOffset = CGSizeMake(0, - self.view.frame.size.height / 2);
    _backgroundView.alpha = 1;
    _backgroundView.backgroundColor = [UIColor blackColor];
    UIView* whiteView = [[UIView alloc] initWithFrame:CGRectMake(0, 64 + (SCR_H > 800 ? 20 : 0), SCR_W, SCR_H)];
    whiteView.backgroundColor = [UIColor whiteColor];
    [_backgroundView addSubview:whiteView];
    if (REUIKitIsFlatMode()) {
        _backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
    }
    [self.view addSubview:_backgroundView];
    
    _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, SCR_H / 2)];
    _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.currentWidth, SCR_H / 2)];
    _backView.layer.cornerRadius = _cornerRadius;
    if (!REUIKitIsFlatMode()) {
        _backView.layer.shadowOpacity = 0.7;
        _backView.layer.shadowColor = [UIColor blackColor].CGColor;
        _backView.layer.shadowOffset = CGSizeMake(3, 5);
        _backView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_backView.frame cornerRadius:_cornerRadius].CGPath;
        _backView.layer.shouldRasterize = YES;
    }
    _backView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    _sheetView.frame = _backView.bounds;
    _sheetView.layer.cornerRadius = _cornerRadius;
    _sheetView.clipsToBounds = YES;
    _sheetView.delegate = self;
    if (REUIKitIsFlatMode()) {
        _sheetView.backgroundColor = self.tintColor;
    }
    
    [_containerView addSubview:_backView];
    [self.view addSubview:_containerView];
    [_backView addSubview:_sheetView];
    
    if (!REUIKitIsFlatMode()) {
        _paperclipView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 77, 60, 79, 34)];
        _paperclipView.image = [UIImage imageNamed:@"REComposeViewController.bundle/PaperClip"];
        [_containerView addSubview:_paperclipView];
        [_paperclipView setHidden:YES];
    }
        
    if (!_attachmentImage)
        _attachmentImage = [UIImage imageNamed:@"REComposeViewController.bundle/URLAttachment"];
    
    _sheetView.attachmentImageView.image = _attachmentImage;
    [_sheetView.attachmentViewButton addTarget:self
                                        action:@selector(didTapAttachmentView:)
                              forControlEvents:UIControlEventTouchUpInside];
    
    _sheetView.textView.layer.borderColor = [UIColor colorWithWhite:0.6 alpha:1].CGColor;
    _sheetView.textView.layer.borderWidth = 1;
    _sheetView.textView.layer.cornerRadius = 5;
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];

    _backgroundView.frame = _rootViewController.view.bounds;
    
    if (REUIKitIsFlatMode()) {
        [self layoutWithOrientation:self.interfaceOrientation width:self.view.frame.size.width height:self.view.frame.size.height];
        self.containerView.alpha = 0;
        [self.sheetView.textView becomeFirstResponder];
    } else {
        [UIView animateWithDuration:0.4 animations:^{
            [self.sheetView.textView becomeFirstResponder];
            [self layoutWithOrientation:self.interfaceOrientation width:self.view.frame.size.width height:self.view.frame.size.height];
        }];
    }
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                        if (REUIKitIsFlatMode()) {
                            self.containerView.alpha = 1;
                        }
                        self.backgroundView.alpha = 1;
    } completion:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewOrientationDidChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [self.navigationBar setTintColor:[UIColor blackColor]];
    [self.navigationBar setBarTintColor:[UIColor blackColor]];
}

- (void)presentFromRootViewController
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [self presentFromViewController:rootViewController];
    
}

- (void)presentFromViewController:(UIViewController *)controller
{
    _rootViewController = controller;
    [controller addChildViewController:self];
    [controller.view addSubview:self.view];
    [self didMoveToParentViewController:controller];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear: animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)layoutWithOrientation:(UIInterfaceOrientation)interfaceOrientation width:(NSInteger)width height:(NSInteger)height
{
    NSInteger offset = 0; //UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 60 : 4;
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        CGRect frame = _containerView.frame;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            offset *= 2;
        }
        
        NSInteger verticalOffset = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 316 : 216;
        
        NSInteger containerHeight = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? _containerView.frame.size.height : _containerView.frame.size.height;
        frame.origin.y = (height - verticalOffset - containerHeight) / 2;
        if (frame.origin.y < 20) frame.origin.y = 20;
        _containerView.frame = frame;
        
        _containerView.clipsToBounds = YES;
        _backView.frame = CGRectMake(offset, 0, width, 250);
        _sheetView.frame = _backView.bounds;
        
        CGRect paperclipFrame = _paperclipView.frame;
        paperclipFrame.origin.x = width - 73 - offset;
        _paperclipView.frame = paperclipFrame;
    } else {
        CGRect frame = _containerView.frame;
        frame.origin.y = 0; //(height - 216 - _containerView.frame.size.height) / 2;
        if (frame.origin.y < 20) frame.origin.y = 20;
        if (SCR_H > 800) frame.origin.y = 44;
        _containerView.frame = frame;
        _backView.frame = CGRectMake(offset, 0, width - offset*2, SCR_H / 2);
        _sheetView.frame = _backView.bounds;
        
        
        CGRect paperclipFrame = _paperclipView.frame;
        paperclipFrame.origin.x = width - 73 - offset;
        _paperclipView.frame = paperclipFrame;
    }
    
    _paperclipView.hidden = !_hasAttachment;
    _sheetView.attachmentView.hidden = !_hasAttachment;
    
    [_sheetView.navigationBar sizeToFit];
    
    CGRect attachmentViewFrame = _sheetView.attachmentView.frame;
    attachmentViewFrame.origin.x = _sheetView.frame.size.width - 84;
    attachmentViewFrame.origin.y = _sheetView.navigationBar.frame.size.height + 10;
    _sheetView.attachmentView.frame = attachmentViewFrame;
    
    CGRect textViewFrame = _sheetView.textView.frame;
    textViewFrame.size.width = !_hasAttachment ? _sheetView.textViewContainer.frame.size.width : _sheetView.textViewContainer.frame.size.width - 84;
    textViewFrame.size.width -= REUIKitIsFlatMode() ? 14 : 0;
    _sheetView.textView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, _hasAttachment ? -85 : 0);
    textViewFrame.size.height = _sheetView.frame.size.height - _sheetView.navigationBar.frame.size.height - 3;
    _sheetView.textView.frame = CGRectMake(10,10,SCR_W- 20,200);
    
    CGRect textViewContainerFrame = _sheetView.textViewContainer.frame;
    textViewContainerFrame.origin.y = _sheetView.navigationBar.frame.size.height;
    textViewContainerFrame.size.height = _sheetView.frame.size.height - _sheetView.navigationBar.frame.size.height;
    _sheetView.textViewContainer.frame = CGRectMake(0,70, SCR_W, SCR_H); //textViewContainerFrame;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [_sheetView.textView resignFirstResponder];
    __typeof(&*self) __weak weakSelf = self;
    
    [UIView animateWithDuration:0.4 animations:^{
        if (REUIKitIsFlatMode()) {
            self.containerView.alpha = 0;
        } else {
            CGRect frame = weakSelf.containerView.frame;
            frame.origin.y =  weakSelf.rootViewController.view.frame.size.height;
            weakSelf.containerView.frame = frame;
        }
    }];
    
    [UIView animateWithDuration:0.4
                          delay:0.1
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         weakSelf.backgroundView.alpha = 0;
                     } completion:^(BOOL finished) {
                         [weakSelf.view removeFromSuperview];
                         [weakSelf removeFromParentViewController];
                         if (completion)
                             completion();
                     }];
}

#pragma mark -
#pragma mark Accessors

- (UINavigationItem *)navigationItem
{
    return _sheetView.navigationItem;
}

- (UINavigationBar *)navigationBar
{
    return _sheetView.navigationBar;
}

- (void)setAttachmentImage:(UIImage *)attachmentImage
{
    _attachmentImage = attachmentImage;
    _sheetView.attachmentImageView.image = _attachmentImage;
}

- (NSString *)text
{
    return _sheetView.textView.text;
}

- (void)setText:(NSString *)text
{
    _sheetView.textView.text = text;
}

- (NSString *)placeholderText
{
    return _sheetView.textView.placeholder;
}

- (void)setPlaceholderText:(NSString *)placeholderText
{
    _sheetView.textView.placeholder = placeholderText;
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
    self.sheetView.backgroundColor = tintColor;
}

#pragma mark -
#pragma mark REComposeSheetViewDelegate

- (void)cancelButtonPressed
{
    id<REComposeViewControllerDelegate> localDelegate = _delegate;
    if (localDelegate && [localDelegate respondsToSelector:@selector(composeViewController:didFinishWithResult:)]) {
        [localDelegate composeViewController:self didFinishWithResult:REComposeResultCancelled];
    }
    if (_completionHandler)
        _completionHandler(self, REComposeResultCancelled);
}

- (void)postButtonPressed
{
    id<REComposeViewControllerDelegate> localDelegate = _delegate;
    if (localDelegate && [localDelegate respondsToSelector:@selector(composeViewController:didFinishWithResult:)]) {
        [localDelegate composeViewController:self didFinishWithResult:REComposeResultPosted];
    }
    if (_completionHandler)
        _completionHandler(self, REComposeResultPosted);
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)didTapAttachmentView:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    // If our device has a cmera, we want to take a picture, otherwise we just pick from the library
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    } else {
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }

    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self setAttachmentImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    self.userUpdatedAttachment = YES;
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.sheetView.textView becomeFirstResponder];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.sheetView.textView becomeFirstResponder];
}

#pragma mark -
#pragma mark Orientation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)viewOrientationDidChanged:(NSNotification *)notification
{
    [self layoutWithOrientation:self.interfaceOrientation width:self.view.frame.size.width height:self.view.frame.size.height];
}

@end
