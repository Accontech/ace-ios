//
//  InCallNewCallNotificationView.m
//  linphone
//
//  Created by Misha Torosyan on 3/3/16.
//
//

#import "SecondIncomingCallView.h"
#import "LinphoneManager.h"
#import "UILinphone.h"


#define kAnimationDuration 0.5f
static NSString *BackgroundAnimationKey = @"animateBackground";


@interface SecondIncomingCallView ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *ringCountLabel;
@property (nonatomic, assign) LinphoneCall *call;

@end


@implementation SecondIncomingCallView

#pragma mark - Life Cycle
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}


#pragma mark - Private Methods
- (void)setupView {
    
    self.profileImageView.layer.cornerRadius = CGRectGetHeight(self.profileImageView.frame)/2;
    self.profileImageView.layer.borderWidth = 1.f;
    self.profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void)startBackgroundColorAnimation {
    
    CABasicAnimation *theAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    theAnimation.duration = 0.7f;
    theAnimation.repeatCount = HUGE_VAL;
    theAnimation.autoreverses = YES;
    theAnimation.toValue = (id)[UIColor colorWithRed:0.1843 green:0.1961 blue:0.1961 alpha:1.0].CGColor;
    [self.backgroundView.layer addAnimation:theAnimation forKey:BackgroundAnimationKey];
}

- (void)stopBackgroundColorAnimation {
    
    [self.backgroundView.layer removeAnimationForKey:BackgroundAnimationKey];
}

- (void)update {
    
    [_profileImageView setImage:[UIImage imageNamed:@"avatar_unknown.png"]];
    
    NSString *address = nil;
    const LinphoneAddress *addr = linphone_call_get_remote_address([[LinphoneManager instance] currentCall]);
    if (addr != NULL) {
        BOOL useLinphoneAddress = true;
        // contact name
        char *lAddress = linphone_address_as_string_uri_only(addr);
        if (lAddress) {
            NSString *normalizedSipAddress = [FastAddressBook normalizeSipURI:[NSString stringWithUTF8String:lAddress]];
            ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:normalizedSipAddress];
            if (contact) {
                UIImage *tmpImage = [FastAddressBook getContactImage:contact thumbnail:false];
                if (tmpImage != nil) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL),
                                   ^(void) {
                                       UIImage *tmpImage2 = [UIImage decodedImageWithImage:tmpImage];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           _profileImageView.image = tmpImage2;
                                       });
                                   });
                }
                address = [FastAddressBook getContactDisplayName:contact];
                useLinphoneAddress = false;
            }
            ms_free(lAddress);
        }
        if (useLinphoneAddress) {
            const char *lDisplayName = linphone_address_get_display_name(addr);
            const char *lUserName = linphone_address_get_username(addr);
            if (lDisplayName)
                address = [NSString stringWithUTF8String:lDisplayName];
            else if (lUserName)
                address = [NSString stringWithUTF8String:lUserName];
        }
    }
    
    // Set Address
    if (address == nil) {
        address = @"Unknown";
    }
    [_nameLabel setText:address];
}


#pragma mark - Action Methods
- (IBAction)notificationViewAction:(UIButton *)sender {
    
    if (self.notificationViewActionBlock) {
        self.notificationViewActionBlock(self.call);
    }
}


#pragma mark - Instance Methods
- (void)fillWithCallModel:(LinphoneCall *)linphoneCall {
    //TODO: Fill with passed method's param
    
    self.call = linphoneCall;
    
    [[LinphoneManager instance] fetchProfileImageWithCall:linphoneCall withCompletion:^(UIImage *image) {
        
        _profileImageView.image = image;
    }];
    _nameLabel.text = [[LinphoneManager instance] fetchAddressWithCall:linphoneCall];
}

- (void)showNotificationWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    self.alpha = 1;
    [self startBackgroundColorAnimation];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         
                         self.backgroundViewTopConstraint.constant = 0;
                         [self layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         
                         self.viewState = VS_Opened;
                         if (completion && finished) {
                             completion();
                         }
                     }];
}

- (void)hideNotificationWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    [self stopBackgroundColorAnimation];
    if (animation) {
        [UIView animateWithDuration:duration
                         animations:^{
                             self.backgroundViewTopConstraint.constant = -CGRectGetHeight(self.frame);
                             [self layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             self.alpha = 0;
                             self.viewState = VS_Closed;
                             if (completion && finished) {
                                 completion();
                             }
                         }];
    } else {
        self.alpha = 0;
    }
}

@end
