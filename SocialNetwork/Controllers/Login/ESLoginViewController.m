//
//  ESLoginViewController.m
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

#import "AFNetworking.h"
#import <Parse/Parse.h>
#import "ProgressHUD.h"
#import "ESLoginViewController.h"
#import "AppDelegate.h"
#import "ESUtility.h"
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "PFFacebookUtils.h"
#import "PrivacyPolicyViewController.h"

@implementation ESLoginViewController

@synthesize cellEmail, cellPassword, cellButton;
@synthesize fieldEmail, fieldPassword, cellFacebook, cellForgotPassword, btnAgree, btnPrivacyPolicy, cellPrivacyPolicy;

- (void)viewDidLoad
{
    [super viewDidLoad];
    fieldEmail.delegate = self;
    fieldPassword.delegate = self;
    self.isAgree = YES;
    [[self navigationController] setNavigationBarHidden:YES];
    self.title = NSLocalizedString(@"", nil);
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.tableView addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.cancelsTouchesInView = NO;
    self.navigationController.navigationBar.hidden = NO;
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:def_Golden_Color}];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];//[UIColor colorWithRed:0.3412 green:0.6902 blue:0.9294 alpha:1];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundView.backgroundColor = [UIColor clearColor];
    [self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background_splash"]]];
    
    UIImage *logo = [UIImage imageNamed:@"logo"];
    UIImage *logoText = [UIImage imageNamed:@"logo_text"];
    _logoImage = [[UIImageView alloc] initWithImage:logo];
    _logoTextImage = [[UIImageView alloc] initWithImage:logoText];
    if (_signupView) {
        ESSignUpViewController *registerView = [[ESSignUpViewController alloc] init];
        [self.navigationController pushViewController:registerView animated:NO];
    }
}
- (void) back {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //[fieldEmail becomeFirstResponder];
}

- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}

#pragma mark - User actions
- (BOOL)validateEmailWithString:(NSString*)email
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}
- (void)actionLogin
{
    NSString *email = fieldEmail.text;
    NSString *password = fieldPassword.text;
    
    if ([email length] == 0)	{ [ProgressHUD showError:NSLocalizedString(@"Email must be set.", nil) ]; return; }
    if ([password length] == 0)	{ [ProgressHUD showError:NSLocalizedString(@"Password must be set.", nil)]; return; }
    
    if ([self validateEmailWithString:self.fieldEmail.text] == FALSE) {
        
        [ProgressHUD showError:NSLocalizedString(@"Email is invalid", nil)];
         return;
    }
    if (self.isAgree == FALSE) {
        
        [ProgressHUD showError:NSLocalizedString(@"Please agree with our privacy policy", nil)];
        return;
    }
    [ProgressHUD show:NSLocalizedString(@"Logging in...",nil) Interaction:NO];
    [PFUser logInWithUsernameInBackground:email password:password block:^(PFUser *user, NSError *error)
     {
         if (user != nil)
         {
             NSString *emailVarification = [user objectForKey:@"emailVerified"];
             NSLog(@"%@",emailVarification);
             if([[user objectForKey:@"emailVerified"] boolValue]) {
                 // Email has been verified
                 
                 PFInstallation *installation = [PFInstallation currentInstallation];
                 installation[kESInstallationUserKey] = [PFUser currentUser];
                 [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                     if (error) {
                         [installation saveEventually];
                     }
                 }];
                 
                 NSString *firstName = [[user[kESUserDisplayNameKey] componentsSeparatedByString:@" "] objectAtIndex:0];
                 [ProgressHUD showSuccess:[NSString stringWithFormat:NSLocalizedString(@"Good to see you %@!",nil), firstName]];
                 [(AppDelegate*)[[UIApplication sharedApplication] delegate] presentTabBarController];
                 [self dismissViewControllerAnimated:YES completion:nil];
             }
             else {
                 // Email has not been verified, logout the user
                 
                /* NSString *email = [PFUser currentUser].email;
                 [PFUser currentUser].email = @"temp@temp.com";
                 [[PFUser currentUser] saveInBackground];
                 [[PFUser currentUser] saveEventually];

                 [PFUser currentUser].email = email;
                 [[PFUser currentUser] saveInBackground];
                 [[PFUser currentUser] saveEventually];

                 [PFUser currentUser].email = [PFUser currentUser].email;
                 [[PFUser currentUser] saveInBackground];
                 [[PFUser currentUser] saveEventually];*/
                 
                 [PFUser logOut];
                  [ProgressHUD showError:NSLocalizedString(@"Please verify your email address",nil)];
                 
                
             }
             
         }
         else [ProgressHUD showError:NSLocalizedString(@"Invalid login parameters",nil)];
     }];
}
- (void)actionFacebookLogin {
   
    [ProgressHUD show:NSLocalizedString(@"Logging in...",nil) Interaction:NO];
  
    [PFFacebookUtils logInInBackgroundWithReadPermissions:@[@"public_profile"] block:^(PFUser * _Nullable user, NSError * _Nullable error) {
        
        if (user != nil)
        {
            NSLog(@"%@",user.email);
            NSLog(@"%@",user);
            NSLog(@"%@",user);

            if (user[kESUserFacebookIDKey] == nil)
            {
                [self requestFacebook:user];
            }
            else [self userLoggedIn:user];
        }
        else [ProgressHUD showError:NSLocalizedString(@"Facebook login error.", nil)];
    }];
   /* if ([FBSDKAccessToken currentAccessToken]) {
        
        NSLog(@"%@",[FBSDKAccessToken currentAccessToken]);
    }
    
    if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
        // TODO: publish content.
    } else {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logInWithReadPermissions: nil  handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        
        if (error) {
            
            NSLog(@"%@",[error description]);
        }
        else
        {
            NSLog(@"%@",result);

        }
    }];
        
    }*/
    
    
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}
- (CGFloat) getHeightForListItem {
    if ([UIScreen mainScreen].bounds.size.height < 800) return 60;
    return 70;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        CGFloat defaultHeight = [UIScreen mainScreen].bounds.size.height - 550;
        return defaultHeight < 250 ? 250 : defaultHeight;
    }
    else if (indexPath.section == 1) {
        return [self getHeightForListItem];
    }
    else if (indexPath.section == 2) {
        return [self getHeightForListItem];
    }
    else if (indexPath.section == 3) {
        return [self getHeightForListItem];
    }
    else return [self getHeightForListItem] - 10;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) { // logo
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"logo"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"logo"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [[cell contentView] setBackgroundColor:[UIColor clearColor]];
        [[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell.contentView addSubview:_logoImage];
        [cell.contentView addSubview:_logoTextImage];
        CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
        CGFloat width = screenWidth * 0.7;
        
        CGFloat cellHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
        [_logoImage setFrame:CGRectMake(screenWidth * 0.15, cellHeight / 2 - width * (_logoImage.image.size.height / _logoImage.image.size.width) / 2 - 30, width, width * _logoImage.image.size.height / _logoImage.image.size.width)];
        
        CGPoint centerPointForText = cell.contentView.center;
        centerPointForText.y += _logoImage.frame.size.height / 2;
        [_logoTextImage setFrame:CGRectMake(screenWidth * 0.15, _logoImage.frame.origin.y + _logoImage.frame.size.height + 20, width, width * _logoTextImage.image.size.height / _logoTextImage.image.size.width)];
        return cell;
    }
    if (indexPath.section == 1) { // username
        fieldEmail.frame = CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 40, [self getHeightForListItem]);
        fieldEmail.font = [UIFont fontWithName:@"Montserrat-Light" size:18];
        fieldEmail.textColor = [UIColor blackColor];
        if ([fieldEmail respondsToSelector:@selector(setAttributedPlaceholder:)]) {
            fieldEmail.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Email", nil) attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:197.0 / 255 green:197.0 / 255 blue:197.0 / 255 alpha:1]}];
        }
        CGRect textFieldFrame = fieldEmail.frame;
        textFieldFrame.origin.x = 0;
        textFieldFrame.size.width = 0;
        fieldEmail.leftView = [[UIView alloc]initWithFrame:textFieldFrame];
        fieldEmail.leftViewMode = UITextFieldViewModeAlways;
        
        [[cellEmail contentView] setBackgroundColor:[UIColor clearColor]];
        [[cellEmail backgroundView] setBackgroundColor:[UIColor clearColor]];
        [cellEmail setBackgroundColor:[UIColor clearColor]];
        UIView *borderView = [[UIView alloc] init];
        [borderView.layer setBorderColor:[UIColor colorWithRed:197.0 / 255 green:197.0 / 255 blue:197.0 / 255 alpha:1].CGColor];
        [borderView.layer setCornerRadius: [self getHeightForListItem] / 2];
        [borderView.layer setBorderWidth:1];
        UIImage* imageAvatar = [UIImage imageNamed: @"graycircle"];
        UIImageView* imageIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mail"]];
        UIImageView *bkIcon = [[UIImageView alloc] initWithImage: imageAvatar];
        [bkIcon setFrame:CGRectMake(0, 0, [self getHeightForListItem] - 2, fieldEmail.frame.size.height - 2)];
        [borderView addSubview: bkIcon];
        [bkIcon addSubview:imageIcon];
        [imageIcon setFrame:CGRectMake(bkIcon.frame.size.width * 0.25, bkIcon.frame.size.width * 0.32, bkIcon.frame.size.width * 0.5, bkIcon.frame.size.width * 0.38)];
        
        [borderView setFrame:CGRectMake(20, 1, fieldEmail.frame.size
                                        .width, [self getHeightForListItem] - 2)];
        [cellEmail.contentView addSubview: borderView];
        [cellEmail.contentView bringSubviewToFront:fieldEmail];
        cellEmail.selectionStyle = UITableViewCellSelectionStyleNone;
        [bkIcon removeFromSuperview];
        [cellEmail.contentView addSubview: bkIcon];
        [cellEmail.contentView bringSubviewToFront:bkIcon];
        CGRect rect = bkIcon.frame;
        rect.origin.x = borderView.frame.origin.x;
        rect.origin.y++;
        bkIcon.frame = rect;
        return cellEmail;
    }
    else if (indexPath.section == 2) { // password
        fieldPassword.frame = CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 40, [self getHeightForListItem] - 1);

        //fieldPassword.frame = CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 40, cellPassword.frame.size.height);
        fieldPassword.font = [UIFont fontWithName:@"Montserrat-Light" size:18];
        fieldPassword.textColor = [UIColor blackColor];
        if ([fieldPassword respondsToSelector:@selector(setAttributedPlaceholder:)]) {
            fieldPassword.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", nil) attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:197.0 / 255 green:197.0 / 255 blue:197.0 / 255 alpha:1]}];
        }
        CGRect textFieldFrame = fieldEmail.frame;
        textFieldFrame.origin.x = 0;
        textFieldFrame.size.width = 0;
        fieldPassword.leftView = [[UIView alloc]initWithFrame:textFieldFrame];
        fieldPassword.leftViewMode = UITextFieldViewModeAlways;
        [[cellPassword contentView] setBackgroundColor:[UIColor clearColor]];
        [[cellPassword backgroundView] setBackgroundColor:[UIColor clearColor]];
        [cellPassword setBackgroundColor:[UIColor clearColor]];
        UIView *borderView = [[UIView alloc] init];
        [borderView.layer setBorderColor:[UIColor colorWithRed:197.0 / 255 green:197.0 / 255 blue:197.0 / 255 alpha:1].CGColor];
        [borderView.layer setCornerRadius: [self getHeightForListItem] / 2];
        [borderView.layer setBorderWidth:1];
        UIImage* imageAvatar = [UIImage imageNamed: @"graycircle"];
        UIImageView* imageIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"password"]];
        UIImageView *bkIcon = [[UIImageView alloc] initWithImage: imageAvatar];
        [bkIcon setFrame:CGRectMake(0, 0, fieldPassword.frame.size.height - 2, fieldPassword.frame.size.height - 2)];
        [borderView addSubview: bkIcon];
        [bkIcon addSubview:imageIcon];
        [imageIcon setFrame:CGRectMake(bkIcon.frame.size.width * 0.25, bkIcon.frame.size.width * 0.25, bkIcon.frame.size.width * 0.5, bkIcon.frame.size.width * 0.5)];
        
        [borderView setFrame:CGRectMake(20, 1, fieldPassword.frame.size
                                        .width, [self getHeightForListItem] - 2)];
        [cellPassword addSubview: borderView];
        cellPassword.selectionStyle = UITableViewCellSelectionStyleNone;
        [cellPassword bringSubviewToFront:cellPassword.contentView];
        [bkIcon removeFromSuperview];
        [cellPassword.contentView addSubview: bkIcon];
        [cellPassword.contentView bringSubviewToFront:bkIcon];
        CGRect rect = bkIcon.frame;
        rect.origin.x = borderView.frame.origin.x;
        rect.origin.y++;
        bkIcon.frame = rect;
        return cellPassword;
    }
    
    else if (indexPath.section == 3){ // login
        
        cellButton.backgroundColor = [UIColor blueColor];
        UIButton *loginLabel = [[UIButton alloc]initWithFrame:CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width-40, [self getHeightForListItem])];
        [loginLabel setTitle: NSLocalizedString(@"Login", nil) forState: UIControlStateNormal];
        [loginLabel addTarget:self action:@selector(actionLogin) forControlEvents:UIControlEventTouchUpInside];
        [loginLabel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        loginLabel.layer.cornerRadius = loginLabel.frame.size.height / 2;
        loginLabel.layer.borderColor = [UIColor blackColor].CGColor;
        loginLabel.layer.borderWidth = 2;
        loginLabel.backgroundColor = [UIColor whiteColor]; //[UIColor colorWithRed:189.0f/255.0f green:195.0f/255.0f blue:199.0f/255.0f alpha:1.0f];
        [cellButton addSubview:loginLabel];
        cellButton.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cellButton.backgroundColor = [UIColor clearColor];
        
        return cellButton;
    }
    else if (indexPath.section == 6){ // Forgot password
        
        cellForgotPassword.backgroundColor = [UIColor clearColor];
        UIButton *loginLabel = [[UIButton alloc]initWithFrame:CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width-40, [self getHeightForListItem] - 10)];
        [loginLabel setTitle: NSLocalizedString(@"Forgot Password?",nil) forState: UIControlStateNormal];
        [loginLabel.titleLabel setFont:[UIFont fontWithName:@"Montserrat-Bold" size:16]];
        [loginLabel addTarget:self action:@selector(actionForgotPassword:) forControlEvents:UIControlEventTouchUpInside];
        [loginLabel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        loginLabel.layer.cornerRadius = 4;
        
        loginLabel.backgroundColor = [UIColor clearColor]; //[UIColor colorWithRed:189.0f/255.0f green:195.0f/255.0f blue:199.0f/255.0f alpha:1.0f];
        [cellForgotPassword addSubview:loginLabel];
        cellForgotPassword.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cellForgotPassword.backgroundColor = [UIColor clearColor];

        return cellForgotPassword;
    }
    else if (indexPath.section == 4) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"donthavesignup"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"donthavesignup"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.backgroundColor = [UIColor clearColor];
        UIButton *loginLabel = [[UIButton alloc]initWithFrame:CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width-40, 40)];
        loginLabel.titleLabel.adjustsFontSizeToFitWidth = YES;
        CGFloat boldTextFontSize = 18.0f;
        [loginLabel setTitle:NSLocalizedString(@"Don't have an account? Sign Up", nil) forState:UIControlStateNormal];
        NSRange range1 = [loginLabel.titleLabel.text rangeOfString:NSLocalizedString(@"Sign Up", nil)];

        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:loginLabel.titleLabel.text];

        [attributedText setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Montserrat-Bold" size:boldTextFontSize]}
                                range:range1];
        
        loginLabel.titleLabel.attributedText = attributedText;
        [loginLabel addTarget:self action:@selector(actionSignup:) forControlEvents:UIControlEventTouchUpInside];
        [loginLabel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
        loginLabel.backgroundColor = [UIColor clearColor]; //[UIColor colorWithRed:189.0f/255.0f green:195.0f/255.0f blue:199.0f/255.0f alpha:1.0f];
        [cell addSubview:loginLabel];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [[cell contentView] setBackgroundColor:[UIColor clearColor]];
        [[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
        [cell setBackgroundColor:[UIColor clearColor]];
        return cell;
    } else {
        
        cellFacebook.backgroundColor = [UIColor clearColor];
        UIButton *facebookLogin = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 40 * 3.5, 0, 40 * 7, 40)];
        [facebookLogin setImage:[UIImage imageNamed:@"facebook"] forState:UIControlStateNormal];
        facebookLogin.layer.cornerRadius = [self getHeightForListItem] - 10 / 2;
        [facebookLogin addTarget:self action:@selector(actionFacebookLogin) forControlEvents:UIControlEventTouchUpInside];
    
        cellFacebook.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cellFacebook.backgroundColor = [UIColor clearColor];
        [cellFacebook addSubview:facebookLogin];
        return cellFacebook;

    }
    return nil;
}

-(IBAction)actionSignup:(id)sender {
    ESSignUpViewController *registerView = [[ESSignUpViewController alloc] init];
    [self.navigationController pushViewController:registerView animated:YES];

}

-(IBAction)actionForgotPassword:(id)sender
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Forgot Password", nil)
                                                                              message: NSLocalizedString(@"Input Email Address", nil)
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Email", nil);
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
   
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * namefield = textfields[0];
        NSLog(@"%@",namefield.text);
        
        if (namefield.text.length > 0) {
           
            [self resetPassword:namefield.text];
        }
        
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}
-(void)resetPassword:(NSString*)email
{
    NSString *emailToLowerCase = [email lowercaseString];
    emailToLowerCase = [emailToLowerCase stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (email.length > 0) {
        
        [ProgressHUD show:NSLocalizedString(@"Sending request...",nil) Interaction:NO];

        [PFUser requestPasswordResetForEmailInBackground:email block:^(BOOL succeeded, NSError * _Nullable error) {
           
            if (error == nil) {
                
                [ProgressHUD showSuccess:NSLocalizedString(@"Email request has been sent successfully! Check your email!", nil)];
            }
            else
            {
                NSLog(@"%@",error);
                NSLog(@"%@",error.userInfo[@"error"]);

                [ProgressHUD showError:error.userInfo[@"error"]];
            }
            
        }];
    }
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == fieldEmail)
    {
        [fieldPassword becomeFirstResponder];
    }
    if (textField == fieldPassword)
    {
        [self actionLogin];
    }
    return YES;
}

#pragma mark - (Facebook Methods)
- (void)requestFacebook:(PFUser *)user
{
    NSString *access_token=[FBSDKAccessToken currentAccessToken].tokenString;
    [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:@"fb_token"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{ @"fields": @"id,picture,name,email,friends"} tokenString:[[NSUserDefaults standardUserDefaults] objectForKey:@"fb_token"] version:nil HTTPMethod:@"GET"]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error)
     {
         if (error == nil)
         {
             NSDictionary *userData = (NSDictionary *)result;
             [self processFacebook:user UserData:userData];
         }
         else
         {
             [PFUser logOut];
             [ProgressHUD showError:NSLocalizedString(@"Failed to fetch Facebook user data.", nil)];
         }
     }];
    
    /*[[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
        if (error) {
            NSLog(@"error:%@",error);
        }
        else
        {
            // retrive user's details at here as shown below
            NSLog(@"FB user first name:%@",user.first_name);
            NSLog(@"FB user last name:%@",user.last_name);
            NSLog(@"FB user birthday:%@",user.birthday);
            NSLog(@"FB user location:%@",user.location);
            NSLog(@"FB user username:%@",user.username);
            NSLog(@"FB user gender:%@",[user objectForKey:@"gender"]);
            NSLog(@"email id:%@",[user objectForKey:@"email"]);
            
        }
    }];*/
     
    
    /*FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
     {
         if (error == nil)
         {
             NSDictionary *userData = (NSDictionary *)result;
             [self processFacebook:user UserData:userData];
         }
         else
         {
             [PFUser logOut];
             [ProgressHUD showError:@"Failed to fetch Facebook user data."];
         }
     }];*/
}
- (IBAction)btnAgreeAction:(UIButton*)sender
{
    if(sender.selected == TRUE)
    {
        [sender setSelected:FALSE];
        self.isAgree = FALSE;
    }
    else
    {
        [sender setSelected:TRUE];
        self.isAgree = TRUE;


    }
}
- (IBAction)btnPrivacyAction:(UIButton*)sender
{
    self.objPrivacyPolicyViewController = [[PrivacyPolicyViewController alloc] init];
    [self.navigationController pushViewController:self.objPrivacyPolicyViewController animated:TRUE];
}

- (void)processFacebook:(PFUser *)user UserData:(NSDictionary *)userData
{
    NSString *link = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", userData[@"id"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:link]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         UIImage *image = (UIImage *)responseObject;
         [ESUtility processProfilePictureData:UIImageJPEGRepresentation(image, 1.0)];
         if (![user objectForKey:@"usernameFix"]) {
             NSString *name = [[NSString alloc]init];
             name = userData[@"name"];
             NSString *nameWithoutSpaces = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
             NSString *finalName = [nameWithoutSpaces lowercaseString];
             [self checkUserExistance:finalName withZusatz:0 withCopy:finalName];
             
         }
         if (userData[@"email"]) {
             user[kESUserEmailKey] = userData[@"email"];
         }
         else {
             NSString *name = [[userData[@"name"] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
             user[kESUserEmailKey] = [NSString stringWithFormat:@"%@@facebook.com",name];
         }
         user[kESUserDisplayNameKey] = userData[@"name"];
         user[kESUserDisplayNameLowerKey] = [userData[@"name"] lowercaseString];
         user[kESUserFacebookIDKey] = userData[@"id"];
         [user setObject:@"YES" forKey:@"pushnotification"];
         [user setObject:@"YES" forKey:@"readreceipt"];
         [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"readreceipt"];
         [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"pushnotification"];
         [[NSUserDefaults standardUserDefaults]synchronize];

         
         [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
          {
              if (error != nil)
              {
                  [PFUser logOut];
                  [ProgressHUD showError:error.userInfo[@"error"]];
              }
              else [self userLoggedIn:user];
          }];
     }
     
    failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         [PFUser logOut];
         [ProgressHUD showError:NSLocalizedString(@"Failed to fetch Facebook profile picture.", nil)];
     }];
    
    [[NSOperationQueue mainQueue] addOperation:operation];
}

- (void)userLoggedIn:(PFUser *)user
{
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation[kESInstallationUserKey] = [PFUser currentUser];
    [installation saveInBackground]; //   PostNotification(NOTIFICATION_USER_LOGGED_IN);
    if (![user objectForKey:kESUserAlreadyAutoFollowedFacebookFriendsKey]) {
        PFObject *sensitiveData = [PFObject objectWithClassName:@"SensitiveData"];
        [sensitiveData setObject:user forKey:@"user"];
        PFACL *sensitive = [PFACL ACLWithUser:user];
        [sensitive setReadAccess:YES forUser:user];
        [sensitive setWriteAccess:YES forUser:user];
        sensitiveData.ACL = sensitive;
        [sensitiveData saveEventually];
        
        [user setObject:@YES forKey:kESUserAlreadyAutoFollowedFacebookFriendsKey];
        [self performSelector:@selector(eventuallyLogin) withObject:self afterDelay:2.5];
        NSMutableArray *netzwierkEmployees = [[NSMutableArray alloc] initWithArray:kESNetzwierkEmployeeAccounts];
        PFQuery *netzwierkEmployeeQuery = [PFUser query];
        [netzwierkEmployeeQuery whereKey:kESUserFacebookIDKey containedIn:netzwierkEmployees];
        [netzwierkEmployeeQuery findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
            if (!error) {
                NSArray *netzwierkFriends = results;
                if ([netzwierkFriends count] > 0) {
                    [netzwierkFriends enumerateObjectsUsingBlock:^(PFUser *newFriend, NSUInteger idx, BOOL *stop) {
                        PFObject *joinActivity = [PFObject objectWithClassName:kESActivityClassKey];
                        [joinActivity setObject:user forKey:kESActivityFromUserKey];
                        [joinActivity setObject:newFriend forKey:kESActivityToUserKey];
                        [joinActivity setObject:kESActivityTypeJoined forKey:kESActivityTypeKey];
                        
                        PFACL *joinACL = [PFACL ACL];
                        [joinACL setPublicReadAccess:YES];
                        [joinACL setWriteAccess:YES forUser:[PFUser currentUser]];
                        joinActivity.ACL = joinACL;
                        
                        // make sure our join activity is always earlier than a follow
                        [joinActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            [ESUtility followUserInBackground:newFriend block:^(BOOL succeeded, NSError *error) {
                                // This block will be executed once for each friend that is followed.
                                // We need to refresh the timeline when we are following at least a few friends
                                // Use a timer to avoid refreshing innecessarily
                                
                            }];
                        }];
                    }];
                }
                
            }
            else [ProgressHUD showError:NSLocalizedString(@"Internet connection failed", nil)];
        }];
    }
    else {
        
        NSString *emailVarification = [user objectForKey:@"emailVerified"];
        NSLog(@"%@",emailVarification);
        
        if([[user objectForKey:@"emailVerified"] boolValue]) {

        NSString *firstName = [[user[kESUserDisplayNameKey] componentsSeparatedByString:@" "] objectAtIndex:0];
        [ProgressHUD showSuccess:[NSString stringWithFormat:NSLocalizedString(@"Good to see you %@!",nil), firstName]];
        [(AppDelegate*)[[UIApplication sharedApplication] delegate] presentTabBarController];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            
        }
        else
        {
            /*NSString *email = [PFUser currentUser].email;
            [PFUser currentUser].email = @"temp@temp.com";
            [[PFUser currentUser] saveInBackground];
            [[PFUser currentUser] saveEventually];

            [PFUser currentUser].email = email;
            [[PFUser currentUser] saveInBackground];
            [[PFUser currentUser] saveEventually];
            
            [PFUser currentUser].email = [PFUser currentUser].email;
            [[PFUser currentUser] saveInBackground];
            [[PFUser currentUser] saveEventually];*/

            [PFUser logOut];
            [ProgressHUD showError:NSLocalizedString(@"Please verify your email address",nil)];
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            
            
        }
    }
    
}
- (void) eventuallyLogin {
    [[PFUser currentUser] saveInBackground];
    PFUser *user = [PFUser currentUser];
    
    NSString *emailVarification = [user objectForKey:@"emailVerified"];
    NSLog(@"%@",emailVarification);
    
    if([[user objectForKey:@"emailVerified"] boolValue]) {

        NSString *firstName = [[user[kESUserDisplayNameKey] componentsSeparatedByString:@" "] objectAtIndex:0];
        [ProgressHUD showSuccess:[NSString stringWithFormat:NSLocalizedString(@"Good to see you %@!",nil), firstName]];
        [(AppDelegate*)[[UIApplication sharedApplication] delegate] presentTabBarController];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    }
    else
    {
       /* NSString *email = [PFUser currentUser].email;
        [PFUser currentUser].email = @"temp@temp.com";
        [[PFUser currentUser] saveInBackground];
        [[PFUser currentUser] saveEventually];

        [PFUser currentUser].email = email;
        [[PFUser currentUser] saveInBackground];
        [[PFUser currentUser] saveEventually];
        
        [PFUser currentUser].email = [PFUser currentUser].email;
        [[PFUser currentUser] saveInBackground];
        [[PFUser currentUser] saveEventually];*/

        
        [PFUser logOut];
        [ProgressHUD showError:NSLocalizedString(@"Please verify your email address",nil)];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        
        
    }
    
}

-(void)checkUserExistance:(NSString *)usernameFix withZusatz:(int)i withCopy:(NSString *)usernameFixCopy{
    //check if finalname exists
    PFQuery *query=[PFUser query];
    [query whereKey:@"usernameFix" equalTo:usernameFix];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (object) {
            NSString *newFinalName = [NSString stringWithFormat:@"%@%i",usernameFixCopy,(int)i];
            int newInt = i+1;
            [self checkUserExistance:newFinalName withZusatz:newInt withCopy:usernameFixCopy];
            
        }else{
            //name not existant, save that dammit name now
            PFUser *user = [PFUser currentUser];
            [user setObject:usernameFix forKey:@"usernameFix"];
            [user saveEventually];
        }
    }];
    
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange) range replacementString:(NSString*)string {
    CGRect rt = textField.leftView.frame;
    NSString* newText = [textField.text stringByReplacingCharactersInRange:range withString: string];
    CGSize size = [newText sizeWithAttributes:@{NSFontAttributeName: textField.font}];
    rt.size.width = fmin(size.width / textField.frame.size.width * 63, 63);
    
    textField.leftView.frame = rt;
    return YES;
}

- (CGFloat)widthOfString:(NSString *)string withFont:(NSFont *)font {
     NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
     return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size].width;
 }

@end
