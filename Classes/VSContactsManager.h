//
//  VSContactsManager.h
//  linphone
//
//  Created by Karen Muradyan on 2/26/16.
//
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

#include "linphone/linphonecore.h"
#include "linphone/linphone_tunnel.h"

@interface VSContactsManager : NSObject

+ (VSContactsManager *)sharedInstance;

- (NSString*)exportContact:(ABRecordRef)abRecord;
- (LinphoneFriend*)createFriendFromContactBySipURI:(ABRecordRef)abRecord;
- (NSString*)exportAllContacts;
-(NSString*)checkContactHasSipURI;
- (int)addressBookContactsCount;

@end
