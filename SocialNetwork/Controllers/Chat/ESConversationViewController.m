//
//  ESConversationViewController.m
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

#import "ESConversationViewController.h"
#import "ESTabBarController.h"
#import "ESMessageCell.h"
#import "ESMessengerView.h"
#import "ESSelectRecipientsViewController.h"
#import "ESPhoneContacts.h"
#import "SCLAlertView.h"
#import "AppDelegate.h"

@interface ESConversationViewController()
//@property NSTimer* timer;
@end

@implementation ESConversationViewController

#pragma mark - UIViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    conversations = [[NSMutableArray alloc] init];
    
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeNewMessage)];
    [self.navigationItem.rightBarButtonItem setTintColor:def_Golden_Color];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ESMessageCell" bundle:nil] forCellReuseIdentifier:@"ESMessageCell"];
    [self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background_splash"]]];
    self.tableView.separatorColor = def_Golden_Color8;
//    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar"]];
    self.navigationItem.title = NSLocalizedString(@"VIP Billionaires", nil);
  	self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = def_Golden_Color;
    self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
	[self.refreshControl addTarget:self action:@selector(loadChatRooms) forControlEvents:UIControlEventValueChanged];
    
    MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(tapBtn)];
    [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
    [self.navigationItem.leftBarButtonItem setTintColor:def_Golden_Color];

}

-(void)tapBtn
{
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
        //[self setupMenuBarButtonItems];
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [self.tabBarController.view bringSubviewToFront:delegate.vipButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [self.tabBarController.view bringSubviewToFront:delegate.vipButton];
    delegate.vipButton.hidden = NO;
    
    self.navigationItem.title = NSLocalizedString(@"VIP Billionaires", nil);
}

-(void)viewWillDisappear:(BOOL)animated {
//    [self.timer invalidate];
    self.navigationItem.title = NSLocalizedString(@"", nil);
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [self.tabBarController.view bringSubviewToFront:delegate.vipButton];
    delegate.vipButton.hidden = YES;
    
}
- (void)viewWillAppear:(BOOL)animated {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.container.panMode = MFSideMenuPanModeNone;
    
    /*if ([[PFUser currentUser] objectForKey:@"profileColor"]) {
        NSArray *components = [[[PFUser currentUser] objectForKey:@"profileColor"] componentsSeparatedByString:@","];
        CGFloat r = [[components objectAtIndex:0] floatValue];
        CGFloat g = [[components objectAtIndex:1] floatValue];
        CGFloat b = [[components objectAtIndex:2] floatValue];
        CGFloat a = [[components objectAtIndex:3] floatValue];
        UIColor *color = [UIColor colorWithRed:r green:g blue:b alpha:a];
        self.navigationController.navigationBar.barTintColor = color;
    }
    else {*/
        self.navigationController.navigationBar.barTintColor = def_TopBar_Color;
   // }
    
    [self.tableView reloadData];
    
    [self loadChatRooms];
}

- (void)loadChatRooms {
    /*
	PFQuery *messagesQuery = [PFQuery queryWithClassName:kESChatClassNameKey];
	[messagesQuery whereKey:kESChatUserKey equalTo:[PFUser currentUser]];
	[messagesQuery includeKey:kESChatLastUserKey];
    [messagesQuery whereKey:kESChatBlockedUserKey notEqualTo:[PFUser currentUser].objectId];
	[messagesQuery orderByDescending:kESChatUpdateRoomKey];

    [messagesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (error == nil) {
			[conversations removeAllObjects];
			[conversations addObjectsFromArray:objects];
			[self.tableView reloadData];
			[self updateBadgeTabbar];
		}
        else {
            SCLAlertView *alert = [[SCLAlertView alloc]init];
            [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil) subTitle:NSLocalizedString(@"It seems that you're connection is down", nil) closeButtonTitle:NSLocalizedString(@"Aw, snap!", nil) duration:0.0f];
        }
		[self.refreshControl endRefreshing];
	}];
    */
    
    PFUser *user = [PFUser currentUser];
    if ((user != nil) && (firebase == nil))
    {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [Firebase setOption:@"persistence" to:@YES];
        firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Conversations", kESChatFirebaseCredentialKey]];
        FQuery *query = [[firebase queryOrderedByChild:@"userId"] queryEqualToValue:user.objectId];
        [query observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
         {
             [conversations removeAllObjects];
             
             NSMutableArray *unsortedArray = [[NSMutableArray alloc] init];
             
             if (snapshot.value != [NSNull null])
             {
                 self.tableView.tableHeaderView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0.1)];
                 NSArray *sorted = [[snapshot.value allValues] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
                                    {
                                        NSDictionary *recent1 = (NSDictionary *)obj1;
                                        NSDictionary *recent2 = (NSDictionary *)obj2;
                                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                        [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'zzz'"];
                                        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
                                        NSDate *date1 = [formatter dateFromString:recent1[@"date"]];
                                        NSDate *date2 = [formatter dateFromString:recent2[@"date"]];
                                        return [date2 compare:date1];
                                    }];
                 for (NSDictionary *conversation in sorted)
                 {
                     //[conversations addObject:conversation];
                     [unsortedArray addObject:conversation];

                 }
                 
                 NSSortDescriptor *distanceSortDiscriptor = [NSSortDescriptor sortDescriptorWithKey:@"date"
                                                                                          ascending:NO
                                                                                           selector:@selector(localizedStandardCompare:)];
                 
                 [unsortedArray sortUsingDescriptors:@[distanceSortDiscriptor]];
                 
                 [conversations addObjectsFromArray:unsortedArray];
                 
                 self.tableView.delegate = self;
                 self.tableView.dataSource = self;
                 [self.tableView reloadData];
                 [self.refreshControl endRefreshing];
                 [self updateBadgeTabbar];
                 
             }
             [MBProgressHUD hideHUDForView:self.view animated:YES];

            
         }];
    } else {
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
    }

}
#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = UITableViewAutomaticDimension;
    if (section == 0) {
        height = 0.5f;
    }
    return height;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [conversations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ESMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ESMessageCell" forIndexPath:indexPath];
    [cell feedTheCell:conversations[indexPath.row]];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *conversation = conversations[indexPath.row];
    [conversations removeObject:conversation];
    [self updateBadgeTabbar];
    //---------------------------------------------------------------------------------------------------------------------------------------------
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    //---------------------------------------------------------------------------------------------------------------------------------------------
    Firebase *_firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Conversations/%@", kESChatFirebaseCredentialKey, conversation[@"recentId"]]];
    [_firebase removeValueWithCompletionBlock:^(NSError *error, Firebase *ref)
     {
         if (error != nil) NSLog(@"delete error.");
     }];
    
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *message = conversations[indexPath.row];
    NSString *groupId = message[@"groupId"];
    
    if (groupId.length == 20) {
        ESMessengerView *messengerView = [[ESMessengerView alloc] initWith:groupId andName:[message objectForKey:kESChatDescriptionKey]];
        messengerView.hidesBottomBarWhenPushed = YES;
        
        [self.navigationController pushViewController:messengerView animated:YES];
    }
    else {
       // ESMessengerView *messengerView = [[ESMessengerView alloc] initWith:groupId andName:NSLocalizedString(@"Group", nil)];
        //message[@"description"]
        
        //NSDIic conversations[indexPath.row]
        ESMessengerView *messengerView = [[ESMessengerView alloc] initWith:groupId andName:[[conversations objectAtIndex:indexPath.row]objectForKey:@"description"]];
        messengerView.groupMemberList = [[NSMutableArray alloc] init];
        messengerView.groupMemberList = [[conversations objectAtIndex:indexPath.row]objectForKey:@"members"];
        messengerView.groupIcon = [[conversations objectAtIndex:indexPath.row] objectForKey:@"groupIcon"];
        messengerView.recentId = [[conversations objectAtIndex:indexPath.row] objectForKey:@"recentId"];
        messengerView.groupAdminId = [[conversations objectAtIndex:indexPath.row] objectForKey:@"lastUser"];

        messengerView.hidesBottomBarWhenPushed = YES;
        
        [self.navigationController pushViewController:messengerView animated:YES];
    }
   
}
# pragma mark - ()

- (void)composeNewMessage {
//    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
//                                                    otherButtonTitles:NSLocalizedString(@"Friends", nil), NSLocalizedString(@"Phone Contacts", nil), nil];
//    [actionSheet showFromTabBar:self.tabBarController.tabBar];
    

    ESSelectRecipientsViewController *selectMultipleView = [[ESSelectRecipientsViewController alloc] init];
    selectMultipleView.delegate = self;
    selectMultipleView.isFromGroupInfoView = FALSE;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:selectMultipleView];
    [self presentViewController:navController animated:YES completion:nil];
    
}

- (void)selectedRecipients:(NSMutableArray *)users groupName:(NSString *)groupName image:(UIImage *)image
{
    NSString *groupId = [ESUtility createConversation:users groupName:groupName image:image];
    NSString *description = [[NSString alloc]init];
    
    if (groupId.length == 20)
    {
        for (PFUser *user in users)
        {
            if (![user.objectId isEqualToString:[PFUser currentUser].objectId])
            {
                description = [user objectForKey:kESUserDisplayNameKey];
                break;
            }
        }
        
        ESMessengerView *messengerView = [[ESMessengerView alloc] initWith:groupId andName:description];
        messengerView.hidesBottomBarWhenPushed = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.navigationController pushViewController:messengerView animated:YES];
        });
    }
    else
    {
        //ESMessengerView *messengerView = [[ESMessengerView alloc] initWith:groupId andName:NSLocalizedString(@"Group", nil)];
        
        [self loadChatRooms];
        
       /* ESMessengerView *messengerView = [[ESMessengerView alloc] initWith:groupId andName:groupName];

        messengerView.hidesBottomBarWhenPushed = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:messengerView animated:YES];
        });*/
    }
}


- (void)selectedFromContacts:(PFUser *)secondUser {
    PFUser *firstUser = [PFUser currentUser];
    NSMutableArray *users = [[NSMutableArray alloc]initWithObjects:firstUser,secondUser, nil];
    NSString *groupId = [ESUtility createConversation:users groupName:@"" image:nil];
    ESMessengerView *messengerView = [[ESMessengerView alloc] initWith:groupId andName:[secondUser objectForKey:kESUserDisplayNameKey]];
    messengerView.hidesBottomBarWhenPushed = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController pushViewController:messengerView animated:YES];
    });
}
- (void)updateBadgeTabbar {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    int count = 0;
    for (NSDictionary *conversation in conversations)
    {
        count += [conversation[@"counter"] intValue];
    }
    UITabBarItem *item = self.tabBarController.tabBar.items[3];
    if (count == 0) {
        currentInstallation.badge = 0;
        item.badgeValue = nil;
    } else {
        item.badgeValue = [NSString stringWithFormat:@"%i", count];
        currentInstallation.badge = count;
    }
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [currentInstallation saveEventually];
        }
    }];}

# pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex != actionSheet.cancelButtonIndex) {
		if (buttonIndex == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ESSelectRecipientsViewController *selectMultipleView = [[ESSelectRecipientsViewController alloc] init];
                selectMultipleView.delegate = self;
                selectMultipleView.isFromGroupInfoView = FALSE;

                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:selectMultipleView];
                [self presentViewController:navController animated:YES completion:nil];
            });
		}
		if (buttonIndex == 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ESPhoneContacts *addressBookView = [[ESPhoneContacts alloc] init];
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:addressBookView];
                [self presentViewController:navController animated:YES completion:nil];
            });
		}
	}
}

@end
