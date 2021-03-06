/*
 *  Copyright (c) 2014, Parse, LLC. All rights reserved.
 *
 *  You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
 *  copy, modify, and distribute this software in source code or binary form for use
 *  in connection with the web services and APIs provided by Parse.
 *
 *  As with any software that integrates with the Parse platform, your use of
 *  this software is subject to the Parse Terms of Service
 *  [https://www.parse.com/about/terms]. This copyright notice shall be
 *  included in all copies or substantial portions of the software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 *  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 *  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 *  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#import <UIKit/UIKit.h>

// #ifdef COCOAPODS
#import "ParseUIConstants.h"
#import "PFImageView.h"
/* #else
#import <ParseUI/ParseUIConstants.h>
#import <ParseUI/PFImageView.h>
#endif*/

NS_ASSUME_NONNULL_BEGIN

/**
 The `PFTableViewCell` class represents a table view cell which can download and display remote images stored on Parse.

 When used in a `PFQueryTableViewController` - downloading and
 displaying of the remote images are automatically managed by the controller.
 */
@interface PFTableViewCell : UITableViewCell

/**
 The imageView of the table view cell.

 @see `PFImageView`
 */
@property (nullable, nonatomic, strong, readonly) PFImageView *imageView;

@end

NS_ASSUME_NONNULL_END
