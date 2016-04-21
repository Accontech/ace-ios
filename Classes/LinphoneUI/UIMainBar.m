/* UIMainBar.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "UIMainBar.h"
#import "PhoneMainView.h"
#import "CAAnimation+Blocks.h"
#import "LinphoneCoreSettingsStore.h"
#import "CRToast.h"
#import "CustomBarButton.h"
#import "ResourcesViewController.h"
#define kAnimationDuration 0.5f

@interface UIMainBar ()

@property (nonatomic, weak) IBOutlet CustomBarButton *historyButton;
@property (nonatomic, weak) IBOutlet CustomBarButton *contactsButton;
@property (nonatomic, weak) IBOutlet CustomBarButton *dialpadButton;
@property (nonatomic, weak) IBOutlet CustomBarButton *settingsButton;
@property (nonatomic, weak) IBOutlet CustomBarButton *chatButton;
@property (weak, nonatomic) IBOutlet CustomBarButton *moreButton;
@property (weak, nonatomic) IBOutlet UIView *moreMenuContainer;
@property (weak, nonatomic) IBOutlet UILabel *videomailCountLabel;
@property (weak, nonatomic) IBOutlet UIView *videomailIndicatorView;
@property (weak, nonatomic) IBOutlet UIView *messageIndicatorView;

@end

@implementation UIMainBar

static NSString *const kBounceAnimation = @"bounce";
static NSString *const kAppearAnimation = @"appear";
static NSString *const kDisappearAnimation = @"disappear";

@synthesize historyButton;
@synthesize contactsButton;
@synthesize dialpadButton;
@synthesize settingsButton;
@synthesize chatButton;
//@synthesize historyNotificationView;
//@synthesize historyNotificationLabel;
//@synthesize chatNotificationView;
//@synthesize chatNotificationLabel;

#pragma mark - Lifecycle Functions

- (id)init {
    return [super initWithNibName:@"UIMainBar" bundle:[NSBundle mainBundle]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeViewEvent:)
                                                 name:kLinphoneMainViewChange
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdate:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];

    [self updateVidoemailState];
    [self checkVideomailIndicator];
    
    
    //Remove Unread Messages Count on iPhone
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textReceived:)
                                                 name:kLinphoneTextReceived
                                               object:nil];
    
    
    
    //	[[NSNotificationCenter defaultCenter] addObserver:self
    //											 selector:@selector(settingsUpdate:)
    //												 name:kLinphoneSettingsUpdate
    //											   object:nil];
    //
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(kAppSettingChanged:)
    //                                                 name:kIASKAppSettingChanged
    //                                               object:nil];

    
    
    
//	[[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(settingsUpdate:)
//												 name:kLinphoneSettingsUpdate
//											   object:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(kAppSettingChanged:)
//                                                 name:kIASKAppSettingChanged
//                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notifyReceived:)
                                                 name:kLinphoneNotifyReceived
                                               object:nil];
    [self update:FALSE];
    //    [self changeForegroundColor];
//    [self changeForegroundColor];
}

- (void)viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneMainViewChange object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneTextReceived object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneSettingsUpdate object:nil];
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneMainViewChange object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneTextReceived object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneSettingsUpdate object:nil];
}
//
//- (void)flipImageForButton:(UIButton *)button {
//	UIControlState states[] = {UIControlStateNormal, UIControlStateDisabled, UIControlStateSelected,
//							   UIControlStateHighlighted, -1};
//	UIControlState *state = states;
//
//	while (*state != -1) {
//		UIImage *bgImage = [button backgroundImageForState:*state];
//
//		UIImage *flippedImage =
//			[UIImage imageWithCGImage:bgImage.CGImage scale:bgImage.scale orientation:UIImageOrientationUpMirrored];
//		[button setBackgroundImage:flippedImage forState:*state];
//		state++;
//	}
//}

- (void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    
    self.videomailCountLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    self.videomailCountLabel.layer.borderWidth = 1.f;
    self.videomailCountLabel.layer.cornerRadius = CGRectGetHeight(self.videomailCountLabel.frame)/2;
    
    //	{
    //		UIButton *historyButtonLandscape = (UIButton *)[landscapeView viewWithTag:[historyButton tag]];
    //		// Set selected+over background: IB lack !
    //		[historyButton setBackgroundImage:[UIImage imageNamed:@"history_selected_new.png"]
    //								 forState:(UIControlStateHighlighted | UIControlStateSelected)];
    //
    //		// Set selected+over background: IB lack !
    //		[historyButtonLandscape setBackgroundImage:[UIImage imageNamed:@"history_selected_landscape.png"]
    //										  forState:(UIControlStateHighlighted | UIControlStateSelected)];
    //
    //		[LinphoneUtils buttonFixStatesForTabs:historyButton];
    //		[LinphoneUtils buttonFixStatesForTabs:historyButtonLandscape];
    //	}
    //
    //	{
    //		UIButton *contactsButtonLandscape = (UIButton *)[landscapeView viewWithTag:[contactsButton tag]];
    //		// Set selected+over background: IB lack !
    //		[contactsButton setBackgroundImage:[UIImage imageNamed:@"contacts_selected_new.png"]
    //								  forState:(UIControlStateHighlighted | UIControlStateSelected)];
    //
    //		// Set selected+over background: IB lack !
    //		[contactsButtonLandscape setBackgroundImage:[UIImage imageNamed:@"contacts_selected_landscape.png"]
    //										   forState:(UIControlStateHighlighted | UIControlStateSelected)];
    //
    //		[LinphoneUtils buttonFixStatesForTabs:contactsButton];
    //		[LinphoneUtils buttonFixStatesForTabs:contactsButtonLandscape];
    //	}
    //	{
    //		UIButton *dialerButtonLandscape = (UIButton *)[landscapeView viewWithTag:[dialpadButton tag]];
    //		// Set selected+over background: IB lack !
    //		[dialpadButton setBackgroundImage:[UIImage imageNamed:@"dialer_selected_new.png"]
    //								forState:(UIControlStateHighlighted | UIControlStateSelected)];
    //
    //		// Set selected+over background: IB lack !
    //		[dialerButtonLandscape setBackgroundImage:[UIImage imageNamed:@"dialer_selected_landscape.png"]
    //										 forState:(UIControlStateHighlighted | UIControlStateSelected)];
    //
    //		[LinphoneUtils buttonFixStatesForTabs:dialpadButton];
    //		[LinphoneUtils buttonFixStatesForTabs:dialerButtonLandscape];
    //	}
    //	{
    //		UIButton *settingsButtonLandscape = (UIButton *)[landscapeView viewWithTag:[settingsButton tag]];
    //		// Set selected+over background: IB lack !
    //		[settingsButton setBackgroundImage:[UIImage imageNamed:@"settings_selected_new.png"]
    //								  forState:(UIControlStateHighlighted | UIControlStateSelected)];
    //
    //		// Set selected+over background: IB lack !
    //		[settingsButtonLandscape setBackgroundImage:[UIImage imageNamed:@"settings_selected_landscape.png"]
    //										   forState:(UIControlStateHighlighted | UIControlStateSelected)];
    //
    //		[LinphoneUtils buttonFixStatesForTabs:settingsButton];
    //		[LinphoneUtils buttonFixStatesForTabs:settingsButtonLandscape];
    //	}
    //
    //	{
    //		UIButton *chatButtonLandscape = (UIButton *)[landscapeView viewWithTag:[chatButton tag]];
    //		// Set selected+over background: IB lack !
    //		[chatButton setBackgroundImage:[UIImage imageNamed:@"resources_selected_new.png"]
    //							  forState:(UIControlStateHighlighted | UIControlStateSelected)];
    //
    //		// Set selected+over background: IB lack !
    //		[chatButtonLandscape setBackgroundImage:[UIImage imageNamed:@"resources_selected~ipad.png"]
    //									   forState:(UIControlStateHighlighted | UIControlStateSelected)];
    //
    //		[LinphoneUtils buttonFixStatesForTabs:chatButton];
    //		[LinphoneUtils buttonFixStatesForTabs:chatButtonLandscape];
    //	}
    //	if ([LinphoneManager langageDirectionIsRTL]) {
    //		[self flipImageForButton:historyButton];
    //		[self flipImageForButton:settingsButton];
    //		[self flipImageForButton:dialpadButton];
    //		[self flipImageForButton:chatButton];
    //		[self flipImageForButton:contactsButton];
    //	}
    
    [super viewDidLoad]; // Have to be after due to TPMultiLayoutViewController
    //    [self setColorChnageObservers];
    //    [self changeBackgroundColor];
    
    if([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"mwi_uri_preference"]){
        @try{
            NSString *mwi_uri = [[NSUserDefaults standardUserDefaults] objectForKey:@"mwi_uri_preference"];
            LinphoneAddress *mwiAddress = linphone_address_new([mwi_uri UTF8String]);
            linphone_core_subscribe([LinphoneManager getLc], mwiAddress, "message-summary", 1800, NULL);
        }
        @catch(NSError *e){
            NSLog(@"%@", [e description]);
        }
    }
    
    //    if(![[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"mwi_count"]){
    //        [self.chatNotificationView setHidden:YES];
    //    }
    //    else{
    //        NSInteger mwiCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"mwi_count"];
    //        if(mwiCount > 0){
    //            [self.chatNotificationView setHidden:NO];
    //            [self.chatNotificationLabel setText: [NSString stringWithFormat:@"%ld", (long)mwiCount]];
    //        }
    //    }
}
//
//- (void)setColorChnageObservers {
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(changeBackgroundColor)
//                                                 name:@"backgroundColorChanged"
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(changeForegroundColor)
//                                                 name:@"foregroundColorChanged"
//                                               object:nil];
//}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}


- (void)notifyReceived:(NSNotification *)notif {
    const LinphoneContent *content = [[notif.userInfo objectForKey:@"content"] pointerValue];
    if ((content == NULL) || (strcmp("application", linphone_content_get_type(content)) != 0) ||
        (strcmp("simple-message-summary", linphone_content_get_subtype(content)) != 0) ||
        (linphone_content_get_buffer(content) == NULL)) {
        return;
    }
    
    NSInteger mwiCount;
    if(![[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"mwi_count"]){
        mwiCount = 0;
    }
    else{
        mwiCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"mwi_count"];
    }
    mwiCount++;
    [[NSUserDefaults standardUserDefaults] setInteger:mwiCount forKey:@"mwi_count"];
    //    [self.chatNotificationView setHidden:NO];
    //    [self.chatNotificationLabel setText: [NSString stringWithFormat:@"%ld", (long)mwiCount]];
    
    const char *body = linphone_content_get_buffer(content);
    if ((body = strstr(body, "voice-message: ")) == NULL) {
        LOGW(@"Received new NOTIFY from voice mail but could not find 'voice-message' in BODY. Ignoring it.");
        return;
    }
}


//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
//								duration:(NSTimeInterval)duration {
//	// Force the animations
//	[[self.view layer] removeAllAnimations];
//	[historyNotificationView.layer setTransform:CATransform3DIdentity];
//	[chatNotificationView.layer setTransform:CATransform3DIdentity];
//}
//
//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//	//[chatNotificationView setHidden:TRUE];
//	[historyNotificationView setHidden:TRUE];
//	[self update:FALSE];
//}

#pragma mark - Event Functions

- (void)applicationWillEnterForeground:(NSNotification *)notif {
    // Force the animations
    [[self.view layer] removeAllAnimations];
    //	[historyNotificationView.layer setTransform:CATransform3DIdentity];
    //	[chatNotificationView.layer setTransform:CATransform3DIdentity];
    //[chatNotificationView setHidden:TRUE];
    //	[historyNotificationView setHidden:TRUE];
    [self update:FALSE];
}

- (void)callUpdate:(NSNotification *)notif {
    // LinphoneCall *call = [[notif.userInfo objectForKey: @"call"] pointerValue];
    // LinphoneCallState state = [[notif.userInfo objectForKey: @"state"] intValue];
    //	[self updateMissedCall:linphone_core_get_missed_calls_count([LinphoneManager getLc]) appear:TRUE];
}

- (void)changeViewEvent:(NSNotification *)notif {
    // UICompositeViewDescription *view = [notif.userInfo objectForKey: @"view"];
    // if(view != nil)
    [self updateView:[[PhoneMainView instance] firstView]];
    [self updateUnreadMessagesIndicator];
}
//
//- (void)settingsUpdate:(NSNotification *)notif {
//	if ([[LinphoneManager instance] lpConfigBoolForKey:@"animations_preference"] == false) {
//		[self stopBounceAnimation:kBounceAnimation target:chatNotificationView];
//		chatNotificationView.layer.transform = CATransform3DIdentity;
//		[self stopBounceAnimation:kBounceAnimation target:historyNotificationView];
//		historyNotificationView.layer.transform = CATransform3DIdentity;
//	} else {
//		if (![chatNotificationView isHidden] && [chatNotificationView.layer animationForKey:kBounceAnimation] == nil) {
//			[self startBounceAnimation:kBounceAnimation target:chatNotificationView];
//		}
//		if (![historyNotificationView isHidden] &&
//			[historyNotificationView.layer animationForKey:kBounceAnimation] == nil) {
//			[self startBounceAnimation:kBounceAnimation target:historyNotificationView];
//		}
//	}
//
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"force508"]) {
//        [self setBackgroundColor:[UIColor colorWithRed:0.0 green:32.0/255.0 blue:42.0/255.0 alpha:1.0]];
//        [self setForegroundColor:[UIColor colorWithRed:0.0 green:181.0/255.0 blue:241.0/255.0 alpha:1.0]];
//    } else {
//        [self changeBackgroundColor];
//        [self changeForegroundColor];
//    }
//}

//- (void)kAppSettingChanged:(NSNotification *)notif {
//    NSString *nobj = notif.object;
//
//    if (nobj && [nobj isEqualToString:@"force_508_preference"]) {
//        UICompositeViewDescription *c = [SettingsViewController compositeViewDescription];
//        SettingsViewController *settingsViewController = (SettingsViewController*)[[PhoneMainView instance].mainViewController getCachedController:c.content];
//        LinphoneCoreSettingsStore *settingsStore;
//
//        if (settingsViewController) {
//            settingsStore = [settingsViewController getLinphoneCoreSettingsStore];
//        }
//
//        if ([settingsStore boolForKey:@"force_508_preference"]) {
//            [self setBackgroundColor:[UIColor colorWithRed:0.0 green:32.0/255.0 blue:42.0/255.0 alpha:1.0]];
//            [self setForegroundColor:[UIColor colorWithRed:0.0 green:181.0/255.0 blue:241.0/255.0 alpha:1.0]];
//        } else {
//            [self changeBackgroundColor];
//            [self changeForegroundColor];
//        }
//    }
//}

- (void)kAppSettingChanged:(NSNotification *)notif {
    NSString *nobj = notif.object;
    
    if (nobj && [nobj isEqualToString:@"force_508_preference"]) {
        UICompositeViewDescription *c = [SettingsViewController compositeViewDescription];
        SettingsViewController *settingsViewController = (SettingsViewController*)[[PhoneMainView instance].mainViewController getCachedController:c.content];
        LinphoneCoreSettingsStore *settingsStore;
        
        if (settingsViewController) {
            settingsStore = [settingsViewController getLinphoneCoreSettingsStore];
        }

//        if ([settingsStore boolForKey:@"force_508_preference"]) {
//            [self setBackgroundColor:[UIColor colorWithRed:0.0 green:32.0/255.0 blue:42.0/255.0 alpha:1.0]];
//            [self setForegroundColor:[UIColor colorWithRed:0.0 green:181.0/255.0 blue:241.0/255.0 alpha:1.0]];
//        } else {
//            [self changeBackgroundColor];
//            [self changeForegroundColor];
//        }
    }
}

- (void)textReceived:(NSNotification *)notif {
    
    [self updateUnreadMessagesIndicatorState:YES];
    [self updateUnreadMessagesIndicator];
    
    NSDictionary *messageInfo = notif.userInfo;
    NSString *userName = [messageInfo objectForKey:@"userName"];
    NSString *message = [messageInfo objectForKey:@"simpleMessage"];
    
    if (![message hasPrefix:@"!@$%#CALL_DECLINE_MESSAGE#"]) {
        NSString *messageFullText = [[userName stringByAppendingString:@": "] stringByAppendingString:message];
        NSMutableDictionary *options = [@{
                                  kCRToastTextKey : messageFullText,
                                  kCRToastTextAlignmentKey : @(0),
                                  kCRToastBackgroundColorKey : [UIColor colorWithRed:228.0/255.0 green:92.0/255.0 blue:50.0/255.0 alpha:1.0],
                                  kCRToastAnimationInTypeKey : @(0),
                                  kCRToastAnimationOutTypeKey : @(0),
                                  kCRToastAnimationInDirectionKey : @(0),
                                  kCRToastAnimationOutDirectionKey : @(0),
                                  kCRToastImageAlignmentKey : @(0),
                                  kCRToastNotificationPreferredPaddingKey : @(0),
                                  kCRToastNotificationPresentationTypeKey : @(0),
                                  kCRToastNotificationTypeKey : @(1),
                                  kCRToastTimeIntervalKey : @(3),
                                  kCRToastUnderStatusBarKey : @(0)} mutableCopy];
        options[kCRToastImageKey] = [UIImage imageNamed:@"app_icon_29.png"];
        options[kCRToastImageAlignmentKey] = @(0);
        options[kCRToastInteractionRespondersKey] = @[[CRToastInteractionResponder interactionResponderWithInteractionType:CRToastInteractionTypeAll
                                                                                                      automaticallyDismiss:YES
                                                                                                                     block:^(CRToastInteractionType interactionType) {
                                                                                                                         if (interactionType == CRToastInteractionTypeTapOnce) {
                                                                                                                             NSString *remoteContact = (NSString *)[notif.userInfo objectForKey:@"contactURI"];
                                                                                                                             // Go to ChatRoom view
                                                                                                                             [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
                                                                                                                             LinphoneChatRoom *room = [self findChatRoomForContact:remoteContact];
                                                                                                                             ChatRoomViewController *controller = DYNAMIC_CAST(
                                                                                                                                                                               [[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE],
                                                                                                                                                                               ChatRoomViewController);
                                                                                                                             if (controller != nil && room != nil) {
                                                                                                                                 [controller setChatRoom:room];
                                                                                                                             }
                                                                                                                         }
                                                                                                                     }]];
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            [CRToastManager dismissNotification:YES];
            [CRToastManager showNotificationWithOptions:options
                                        completionBlock:^{
                                        }];
        }
    }
}

#pragma mark -

- (void)update:(BOOL)appear {
    [self updateView:[[PhoneMainView instance] firstView]];
    //	[self updateMissedCall:linphone_core_get_missed_calls_count([LinphoneManager getLc]) appear:appear];
    
    //Remove Unread Messages Count on iPhone
    
    //[self updateUnreadMessage:appear];
}

- (void)updateUnreadMessagesIndicator {
    
    
    if ([self unreadMessagesIndicatorState]) {
        
        self.messageIndicatorView.hidden = ![self unreadMessagesIndicatorState];
        [self appearAnimation:kAppearAnimation target:self.messageIndicatorView
         							   completion:^(BOOL finished) {
                                           [self startBounceAnimation:kBounceAnimation target:self.messageIndicatorView];
                                       }];
    }
    else {
        
        [self stopBounceAnimation:kBounceAnimation target:self.messageIndicatorView];
        [self disappearAnimation:kDisappearAnimation target:self.messageIndicatorView
                      completion:^(BOOL finished) {
                          self.messageIndicatorView.hidden = ![self unreadMessagesIndicatorState];
                      }];
    }
}

//- (void)updateMissedCall:(int)missedCall appear:(BOOL)appear {
//	if (missedCall > 0) {
//		if ([historyNotificationView isHidden]) {
//			[historyNotificationView setHidden:FALSE];
//			if ([[LinphoneManager instance] lpConfigBoolForKey:@"animations_preference"] == true) {
//				if (appear) {
//					[self appearAnimation:kAppearAnimation
//								   target:historyNotificationView
//							   completion:^(BOOL finished) {
//								 [self startBounceAnimation:kBounceAnimation target:historyNotificationView];
//								 [historyNotificationView.layer removeAnimationForKey:kAppearAnimation];
//							   }];
//				} else {
//					[self startBounceAnimation:kBounceAnimation target:historyNotificationView];
//				}
//			}
//		}
//		[historyNotificationLabel setText:[NSString stringWithFormat:@"%i", missedCall]];
//	} else {
//		if (![historyNotificationView isHidden]) {
//			[self stopBounceAnimation:kBounceAnimation target:historyNotificationView];
//			if (appear) {
//				[self disappearAnimation:kDisappearAnimation
//								  target:historyNotificationView
//							  completion:^(BOOL finished) {
//								[historyNotificationView setHidden:TRUE];
//								[historyNotificationView.layer removeAnimationForKey:kDisappearAnimation];
//							  }];
//			} else {
//				[historyNotificationView setHidden:TRUE];
//			}
//		}
//	}
//}
- (void)appearAnimation:(NSString *)animationID target:(UIView *)target completion:(void (^)(BOOL finished))completion {
    
    CABasicAnimation *appear = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    appear.duration = 0.4;
    appear.fromValue = [NSNumber numberWithDouble:0.0f];
    appear.toValue = [NSNumber numberWithDouble:1.0f];
    appear.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    appear.fillMode = kCAFillModeForwards;
    appear.removedOnCompletion = NO;
    [appear setCompletion:completion];
    [target.layer addAnimation:appear forKey:animationID];
}

- (void)disappearAnimation:(NSString *)animationID
                    target:(UIView *)target
                completion:(void (^)(BOOL finished))completion {
    
    CABasicAnimation *disappear = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    disappear.duration = 0.4;
    disappear.fromValue = [NSNumber numberWithDouble:1.0f];
    disappear.toValue = [NSNumber numberWithDouble:0.0f];
    disappear.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    disappear.fillMode = kCAFillModeForwards;
    disappear.removedOnCompletion = NO;
    [disappear setCompletion:completion];
    [target.layer addAnimation:disappear forKey:animationID];
}

- (void)startBounceAnimation:(NSString *)animationID target:(UIView *)target {
    CABasicAnimation *bounce = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    bounce.duration = 0.3;
    bounce.fromValue = [NSNumber numberWithDouble:0.0f];
    bounce.toValue = [NSNumber numberWithDouble:8.0f];
    bounce.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    bounce.autoreverses = TRUE;
    bounce.repeatCount = HUGE_VALF;
    [target.layer addAnimation:bounce forKey:animationID];
}

- (void)stopBounceAnimation:(NSString *)animationID target:(UIView *)target {
    [target.layer removeAnimationForKey:animationID];
}

- (void)updateView:(UICompositeViewDescription *)view {
	// Update buttons
	if ([view equal:[HistoryViewController compositeViewDescription]]) {
		historyButton.selected = TRUE;
	} else {
		historyButton.selected = FALSE;
	}
	if ([view equal:[ContactsViewController compositeViewDescription]]) {
		contactsButton.selected = TRUE;
	} else {
		contactsButton.selected = FALSE;
	}
	if ([view equal:[DialerViewController compositeViewDescription]]) {
		dialpadButton.selected = TRUE;
	} else {
		dialpadButton.selected = FALSE;
	}
	if ([view equal:[SettingsViewController compositeViewDescription]]) {
		settingsButton.selected = TRUE;
	} else {
		settingsButton.selected = FALSE;
	}
    if ([view equal:[ChatViewController compositeViewDescription]]) {
        chatButton.selected = TRUE;
        [self updateUnreadMessagesIndicatorState:NO];
        [self updateUnreadMessagesIndicator];
    } else {
        chatButton.selected = FALSE;
    }
}


#pragma mark - Action Methods
- (IBAction)onHistoryClick:(id)event {
    [[PhoneMainView instance] changeCurrentView:[HistoryViewController compositeViewDescription]];
}

- (IBAction)onContactsClick:(id)event {
    [ContactSelection setSelectionMode:ContactSelectionModeNone];
    [ContactSelection setAddAddress:nil];
    [ContactSelection setSipFilter:nil];
    [ContactSelection enableEmailFilter:FALSE];
    [ContactSelection setNameOrEmailFilter:nil];
    [[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription]];
}

- (IBAction)onDialerClick:(id)event {
    [[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
}

- (IBAction)onSettingsClick:(id)event {
    [[PhoneMainView instance] changeCurrentView:[SettingsViewController compositeViewDescription]];
}

- (IBAction)onChatClick:(id)event {
    [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
}

- (IBAction)moreButtonAction:(UIButton *)sender {
    
    if (self.moreMenuContainer.tag == 0) {
        
        [self showMoreMenu];
        [self resetVideomailState];
    }
    else {
        
        [self hideMoreMenu];
    }
}

- (IBAction)selfPreviewButtonAction:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"preview_pref_toggle" object:nil];
    [self hideMoreMenu];
}

- (IBAction)videomailButtonAction:(UIButton *)sender {
    NSString *address = [[NSUserDefaults standardUserDefaults] objectForKey:@"video_mail_uri_preference"];
    if(address){
        [[LinphoneManager instance] call:address displayName:@"Videomail" transfer:FALSE];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mwi_count"];
    }
    [self hideMoreMenu];
}

- (IBAction)resourcesButtonAction:(UIButton *)sender {
//    ResourcesViewController *resourcesController = [[ResourcesViewController alloc] init];
//    float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
//    
//    if (sysVer >= 8.0) {
//        [self showViewController:resourcesController sender:self];
//    }
//    else{
//        [self presentViewController:resourcesController animated:YES completion:nil];
//    }
    [[PhoneMainView instance] changeCurrentView:[HelpViewController compositeViewDescription]];
    [self hideMoreMenu];
}

- (IBAction)settingsButtonAction:(UIButton *)sender {
    
    [self hideMoreMenu];
}


#pragma mark - TPMultiLayoutViewController Functions

- (NSDictionary *)attributesForView:(UIView *)view {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
    [attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
    [attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [LinphoneUtils buttonMultiViewAddAttributes:attributes button:button];
    }
    [attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];
    
    return attributes;
}

- (void)applyAttributes:(NSDictionary *)attributes toView:(UIView *)view {
    view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
    view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [LinphoneUtils buttonMultiViewApplyAttributes:attributes button:button];
    }
    view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}

//- (void)changeBackgroundColor {
//    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"main_bar_background_color_preference"];
//    if(colorData){
//        UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
//        [self setBackgroundColor:color];
//    }
//}
//
//- (void)changeForegroundColor {
//    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"foreground_color_preference"];
//
//    if(colorData){
//        UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
//        [self setForegroundColor:color];
//    }
//}

//- (void) setBackgroundColor:(UIColor*)color {
//    [self.historyButton setBackgroundColor:color];
//    [self.contactsButton setBackgroundColor:color];
//    [self.dialpadButton setBackgroundColor:color];
//    [self.chatButton setBackgroundColor:color];
//    [self.settingsButton setBackgroundColor:color];
//}
//
//- (void) setForegroundColor:(UIColor*)color {
//    UIImage *imageNormal = [[UIImage imageNamed:@"history_new.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    [self.historyButton setTitleColor:color forState:UIControlStateNormal];
//    self.historyButton.tintColor = color;
//    [self.historyButton setBackgroundImage:imageNormal forState:UIControlStateNormal];
//
//    imageNormal = [[UIImage imageNamed:@"contacts_new.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    [self.contactsButton setTitleColor:color forState:UIControlStateNormal];
//    self.contactsButton.tintColor = color;
//    [self.contactsButton setBackgroundImage:imageNormal forState:UIControlStateNormal];
//
//    imageNormal = [[UIImage imageNamed:@"dialer_new.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    [self.dialpadButton setTitleColor:color forState:UIControlStateNormal];
//    self.dialpadButton.tintColor = color;
//    [self.dialpadButton setBackgroundImage:imageNormal forState:UIControlStateNormal];
//
//    imageNormal = [[UIImage imageNamed:@"resources_new.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    [self.chatButton setTitleColor:color forState:UIControlStateNormal];
//    self.chatButton.tintColor = color;
//    [self.chatButton setBackgroundImage:imageNormal forState:UIControlStateNormal];
//
//    imageNormal = [[UIImage imageNamed:@"settings_new.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    [self.settingsButton setTitleColor:color forState:UIControlStateNormal];
//    self.settingsButton.tintColor = color;
//    [self.settingsButton setBackgroundImage:imageNormal forState:UIControlStateNormal];
//}

#pragma mark - Animation
- (void)showMoreMenu {
    
    self.moreMenuContainer.hidden = NO;
    self.moreMenuContainer.tag = 1;
    // Automatic hiding
    [UIView animateWithDuration:kAnimationDuration
                     animations:^{
                         self.moreMenuContainer.alpha = 1;
                         [self.moreButton setSelected:YES];
                     }];
}

- (void)hideMoreMenu {
    
    if (self.moreMenuContainer.tag != 0) {
        self.moreMenuContainer.tag = 0;
        
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             self.moreMenuContainer.alpha = 0;
                             [self.moreButton setSelected:NO];
                         }];
    }
}



#pragma mark - Indicators State
- (void)updateVidoemailState{
    
    NSDictionary *dict = @{@"viewed" : @0,
                           @"count" : @3};
    
    [[NSUserDefaults standardUserDefaults] setValue:dict forKey:@"videomail_notification"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)checkVideomailIndicator {
    
    NSDictionary *videomailDict = [[NSUserDefaults standardUserDefaults] valueForKey:@"videomail_notification"];
    
    if (videomailDict) {
        
        BOOL viewed = [videomailDict[@"viewed"] boolValue];
        NSInteger count = [videomailDict[@"count"] integerValue];
        
        self.videomailIndicatorView.hidden = viewed;
        
        if (count > 0) {
            self.videomailCountLabel.hidden = NO;
            self.videomailCountLabel.text = [NSString stringWithFormat:@"%li", (long)count];
        }
    }
    else {
        
        self.videomailCountLabel.hidden = YES;
        self.videomailIndicatorView.hidden = YES;
        [self updateVidoemailState];
    }
}

- (void)resetVideomailState {
    
    NSDictionary *dict = @{@"viewed" : @1,
                           @"count" : @3};
    
    [[NSUserDefaults standardUserDefaults] setValue:dict forKey:@"videomail_notification"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self checkVideomailIndicator];
}

- (LinphoneChatRoom *)findChatRoomForContact:(NSString *)contact {
    const MSList *rooms = linphone_core_get_chat_rooms([LinphoneManager getLc]);
    const char *from = [contact UTF8String];
    while (rooms) {
        const LinphoneAddress *room_from_address = linphone_chat_room_get_peer_address((LinphoneChatRoom *)rooms->data);
        char *room_from = linphone_address_as_string_uri_only(room_from_address);
        if (room_from && strcmp(from, room_from) == 0) {
            return rooms->data;
        }
        rooms = rooms->next;
    }
    return NULL;
}


- (void)updateUnreadMessagesIndicatorState:(BOOL)state {
    
    [[NSUserDefaults standardUserDefaults] setBool:state forKey:@"unread_message_indicator_state"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)unreadMessagesIndicatorState {
    
    BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:@"unread_message_indicator_state"] && [[LinphoneManager instance] unreadMessagesCount];
    
    return state;
}

//- (NSDictionary*)options {
//    
//    
//    NSDictionary *options = @{
//                              kCRToastTextKey : @"Hello World!",
//                              kCRToastTextAlignmentKey : @(0),
//                              kCRToastBackgroundColorKey : [UIColor redColor],
//                              kCRToastAnimationInTypeKey : @(0),
//                              kCRToastAnimationOutTypeKey : @(0),
//                              kCRToastAnimationInDirectionKey : @(0),
//                              kCRToastAnimationOutDirectionKey : @(0),
//                              kCRToastImageAlignmentKey : @(0),
//                              kCRToastNotificationPreferredPaddingKey : @(0),
//                              kCRToastNotificationPresentationTypeKey : @(0),
//                              kCRToastNotificationTypeKey : @(1),
//                              kCRToastTimeIntervalKey : @(1),
//                              kCRToastUnderStatusBarKey : @(0)
//                              };
//    
//    // if (_dismissibleWithTapSwitch.on) {
//    options[kCRToastInteractionRespondersKey] = @[[CRToastInteractionResponder interactionResponderWithInteractionType:CRToastInteractionTypeTap
//                                                                                                  automaticallyDismiss:YES
//                                                                                                                 block:^(CRToastInteractionType interactionType){
//                                                                                                                     NSLog(@"Dismissed with %@ interaction", NSStringFromCRToastInteractionType(interactionType));
//                                                                                                                 }]];
//    //  }
//    
//    return [NSDictionary dictionaryWithDictionary:options];
//}

@end
