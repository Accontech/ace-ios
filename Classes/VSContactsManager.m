//
//  VSContactsManager.m
//  linphone
//
//  Created by Karen Muradyan on 2/26/16.
//
//

#import "VSContactsManager.h"
#import "LinphoneManager.h"

//typedef struct _LinphoneCardDAVStats {
//    int sync_done_count;
//    int new_contact_count;
//    int removed_contact_count;
//    int updated_contact_count;
//} LinphoneCardDAVStats;

@interface VSContactsManager () {
    //LinphoneCardDAVStats cardDavStats;
}

@end

@implementation VSContactsManager

+ (VSContactsManager *)sharedInstance {
    static VSContactsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[VSContactsManager alloc] init];
    });
    
    return sharedInstance;
}

- (NSString*)exportContact:(ABRecordRef)abRecord {
    
    [self resetDefaultFrinedList];
    NSMutableArray *phoneNumbers = [self contactPhoneNumbersFrom:abRecord];
    NSMutableArray *sipURIs = [self contactSipURIsFrom:abRecord];
    NSString *nameSurnameOrg = [self contactNameSurnameOrganizationFrom:abRecord];
    //LinphoneFriend *friend = [self createFriendFromContactBySipURI:abRecord];
    LinphoneFriend *friend = [self createFriendFromName:nameSurnameOrg withPhoneNumbers:phoneNumbers andSipURIs:sipURIs];
    if (friend == NULL) {
        return @"";
    }
    NSString *documtensDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *exportedContactFilePath = [documtensDirectoryPath stringByAppendingString:[NSString stringWithFormat:@"/%@%@.vcard", @"ACE_", @"Contacts"]];
    
    LinphoneFriendList *friendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_friend_list_export_friends_as_vcard4_file(friendList, [exportedContactFilePath UTF8String]);
    
    return exportedContactFilePath;
}

- (NSString*)exportAllContacts {
    
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFArrayRef allContacts = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    [self resetDefaultFrinedList];
    //[self createFriendListWithAllContacts:allContacts];
    [self createListWithAllContacts:allContacts];
    
    NSString *exportedContactsFilePath = [[self documentsDirectoryPath] stringByAppendingString:[NSString stringWithFormat:@"/%@%@.vcard", @"ACE_", @"Contacts"]];
    LinphoneFriendList *defaultFriendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_friend_list_export_friends_as_vcard4_file(defaultFriendList, [exportedContactsFilePath UTF8String]);
    
    return exportedContactsFilePath;
}

-(void)createListWithAllContacts:(CFArrayRef)allContacts{
    ABAddressBookRef addressBook = ABAddressBookCreate();
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);

    for ( int i = 0; i < nPeople; i++ ) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allContacts, i);
        NSMutableArray *phoneNumbers = [self contactPhoneNumbersFrom:ref];
        NSMutableArray *sipURIs = [self contactSipURIsFrom:ref];
        NSString *contactNameSurnameOrg = [self contactNameSurnameOrganizationFrom:ref];
        
        if(sipURIs.count == 0){

        }else{
            LinphoneFriend *friend = [self createFriendFromName:contactNameSurnameOrg withPhoneNumbers:phoneNumbers andSipURIs:sipURIs];
#pragma unused(friend)
        }
    }
}

-(void)errorMessage{
    NSLog(@"No phone number or sip adress");
}

- (NSString*)documentsDirectoryPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
}

- (LinphoneFriend*)createFriendFromContactBySipURI:(ABRecordRef)abRecord {
    
    LinphoneFriend *linphoneFriend = NULL;
    NSString *contactNameSurnameOrganization = [self contactNameSurnameOrganizationFrom:abRecord];
    NSString *contactSipURI = [self contactSipURIFrom:abRecord];
    NSString *appendSIP = [@"sip:" stringByAppendingString:contactSipURI];
    
    linphoneFriend = [self createFriendFromName:contactNameSurnameOrganization andSipURI:appendSIP];
    
    NSMutableArray *sipURIs = [self contactSipURIsFrom:abRecord];
    NSMutableArray *phoneNumbers = [self contactPhoneNumbersFrom:abRecord];
    
    NSLog(@"sipURIs= %@", sipURIs);
    NSLog(@"phoneNumbers= %@", phoneNumbers);
    
    return linphoneFriend;
}

- (LinphoneFriend*)createFriendFromContactByPhoneNumber:(ABRecordRef)abRecord {
    
    LinphoneFriend *linphoneFriend = NULL;
    NSString *contactNameSurnameOrganization = [self contactNameSurnameOrganizationFrom:abRecord];
    NSString *contactPhoneNumber = [self contactPhoneNumberFrom:abRecord];
    if (![contactPhoneNumber isEqualToString:@""]) {
        linphoneFriend = [self createFriendFromName:contactNameSurnameOrganization andSipURI:[self phoneNumberWithDefaultSipDomain:contactPhoneNumber]];
    }
    
    return linphoneFriend;
}

- (NSString*)contactNameSurnameOrganizationFrom:(ABRecordRef)abRecord {
    
    NSString *contactFullName = @"";
    NSString *contactFirstName = @"";
    NSString *contactLastName = @"";
    NSString *contactOrganizationName = @"";
    
    @try {
        contactFirstName = (__bridge NSString*)ABRecordCopyValue(abRecord, kABPersonFirstNameProperty);
        contactLastName = (__bridge NSString*)ABRecordCopyValue(abRecord, kABPersonLastNameProperty);
        contactOrganizationName = (__bridge NSString*)ABRecordCopyValue(abRecord, kABPersonOrganizationProperty);
    }
    @catch (NSException *exception) {
    }
    
    if (contactFirstName == nil && contactLastName == nil) {
        contactFullName = contactOrganizationName;
    } else if (contactFirstName == nil) {
        contactFullName = contactLastName;
    } else if (contactLastName == nil) {
        contactFullName = contactFirstName;
    } else {
        contactFullName = [NSString stringWithFormat:@"%@ %@", contactFirstName, contactLastName];
    }
    contactFullName = [contactFullName stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
    
    return contactFullName;
}

- (NSString*)contactSipURIFrom:(ABRecordRef)abRecord {
    NSString *contactSipURI = @"";
    
    ABMultiValueRef instantMessageProperties = ABRecordCopyValue(abRecord, kABPersonInstantMessageProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(instantMessageProperties); ++i) {
        CFDictionaryRef emailRef = ABMultiValueCopyValueAtIndex(instantMessageProperties, i);
        NSDictionary *emailDict = (__bridge NSDictionary*)emailRef;
        CFRelease(emailRef);
        if ([emailDict objectForKey:@"service"] && [[emailDict objectForKey:@"service"] isEqualToString:@"SIP"]) {
            contactSipURI = [emailDict objectForKey:@"username"];
            break;
        }
    }
    
    return contactSipURI;
}

- (NSMutableArray*)contactSipURIsFrom:(ABRecordRef)abRecord {
    NSString *contactSipURI = @"";
    NSMutableArray *sipURIs = [NSMutableArray new];
    
    ABMultiValueRef instantMessageProperties = ABRecordCopyValue(abRecord, kABPersonInstantMessageProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(instantMessageProperties); ++i) {
        CFDictionaryRef emailRef = ABMultiValueCopyValueAtIndex(instantMessageProperties, i);
        NSDictionary *emailDict = (__bridge NSDictionary*)emailRef;
        CFRelease(emailRef);
        if ([emailDict objectForKey:@"service"] && [[emailDict objectForKey:@"service"] isEqualToString:@"SIP"]) {
            contactSipURI = [emailDict objectForKey:@"username"];
            [sipURIs addObject:[@"sip:" stringByAppendingString:contactSipURI]];
        }
    }
    
    return sipURIs;
}

- (NSString*)contactPhoneNumberFrom:(ABRecordRef)abRecord {
    NSString *phoneNumber = @"";
    
    ABMultiValueRef multiPhones = ABRecordCopyValue(abRecord, kABPersonPhoneProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); ++i) {
        CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
        CFRelease(multiPhones);
        NSString *abPhoneNumber = (__bridge NSString *) phoneNumberRef;
        CFRelease(phoneNumberRef);
        if (abPhoneNumber) {
            phoneNumber = abPhoneNumber;
            break;
        }
    }
    
    return phoneNumber;
}

- (NSMutableArray*)contactPhoneNumbersFrom:(ABRecordRef)abRecord {
    NSMutableArray *phoneNumbers = [NSMutableArray new];
    
    ABMultiValueRef multiPhones = ABRecordCopyValue(abRecord, kABPersonPhoneProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); ++i) {
        CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
        NSString *abPhoneNumber = (__bridge NSString *) phoneNumberRef;
        CFRelease(phoneNumberRef);
        if (abPhoneNumber) {
            [phoneNumbers addObject:abPhoneNumber];
        }
    }
    
    CFRelease(multiPhones);
    
    return phoneNumbers;
}

- (LinphoneFriend*)createFriendFromName:(NSString*)name andSipURI:(NSString*)sipURI {
    LinphoneFriend *newFriend = linphone_friend_new_with_addr([sipURI  UTF8String]);
    if (newFriend) {
        linphone_friend_edit(newFriend);
        linphone_friend_set_name(newFriend, [name  UTF8String]);
        linphone_friend_done(newFriend);
        linphone_core_add_friend([LinphoneManager getLc], newFriend);
    }
    
    return newFriend;
}

- (LinphoneFriend*)createFriendFromName:(NSString*)name withPhoneNumbers:(NSMutableArray*)phoneNumbers andSipURIs:(NSMutableArray*)sipURIs {
    
    LinphoneFriend *newFriend = linphone_core_create_friend([LinphoneManager getLc]);
    linphone_friend_set_name(newFriend, [name UTF8String]);
    
    for (int i = 0; i < sipURIs.count; ++i) {
        const LinphoneAddress *addr = linphone_core_create_address([LinphoneManager getLc], [sipURIs[i] UTF8String]);
            linphone_friend_set_address(newFriend, addr);
            linphone_friend_add_address(newFriend, addr);
    }
    
    for (int i = 0; i < phoneNumbers.count; ++i) {
        linphone_friend_add_phone_number(newFriend, [phoneNumbers[i] UTF8String]);
    }
    
    LinphoneFriendList *friendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_friend_list_add_friend(friendList, newFriend);
    
    return newFriend;
}

- (void)createFriendListWithAllContacts:(CFArrayRef)allContacts {
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
    for ( int i = 0; i < nPeople; i++ ) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allContacts, i);
#pragma unused(ref)
        LinphoneFriend *friendByPhoneNumber = [self createFriendFromContactByPhoneNumber:ref];
        if (friendByPhoneNumber == NULL) {
            LinphoneFriend *friendBySipURI = [self createFriendFromContactBySipURI:ref];
#pragma unused(friendBySipURI)
        }
    }
}

- (NSString*)phoneNumberWithDefaultSipDomain:(NSString*)phoneNumber {
    LinphoneProxyConfig *proxyConfig = linphone_core_get_default_proxy_config([LinphoneManager getLc]);
    const char *domain = linphone_proxy_config_get_domain(proxyConfig);
    NSString *phoneNumberWithDefaultDomain = [NSString stringWithFormat:@"sip:%@@%s", phoneNumber, domain];
    return phoneNumberWithDefaultDomain;
}

- (void)resetDefaultFrinedList {
    LinphoneFriendList *oldFriendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_core_remove_friend_list ([LinphoneManager getLc], oldFriendList);
    LinphoneFriendList *friendListNew = linphone_core_create_friend_list([LinphoneManager getLc]);
    linphone_core_add_friend_list([LinphoneManager getLc], friendListNew);
}

- (int)addressBookContactsCount {
    int count = 0;
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
    count = (int)nPeople;
    return count;
}
//
//- (void)syncContactsWithCardDavServer {
//
//    const char *cardDavUser = "dood";
//    const char *cardDavPass = "topsecret";
//    const char *cardDavRealm = "vatrp.org";
//    const char *cardDavServer = "http://ace-carddav-sabredav.vatrp.org";
//    const char *cardDavDomain = "ace-carddav-sabredav.vatrp.org";
//
//    const LinphoneAuthInfo * carddavAuth;
//
//    LinphoneFriendList * cardDAVFriends = linphone_core_get_default_friend_list([LinphoneManager getLc]);
//
//    carddavAuth = linphone_auth_info_new(cardDavUser, nil, cardDavPass, nil, cardDavRealm, cardDavDomain);
//
//    linphone_core_add_auth_info([LinphoneManager getLc], carddavAuth);
//
//    LinphoneFriendListCbs * cbs = linphone_friend_list_get_callbacks(cardDAVFriends);
//    linphone_friend_list_cbs_set_user_data(cbs, &cardDavStats);
//    linphone_friend_list_cbs_set_sync_status_changed(cbs, carddav_sync_status_changed);
//    linphone_friend_list_cbs_set_contact_created(cbs, carddav_contact_created);
//    linphone_friend_list_cbs_set_contact_deleted(cbs, carddav_contact_deleted);
//    linphone_friend_list_cbs_set_contact_updated(cbs, carddav_contact_updated);
//
//    linphone_friend_list_set_uri(cardDAVFriends, cardDavServer);
//
//    linphone_friend_list_synchronize_friends_from_server(cardDAVFriends);
//}
//
//static void carddav_sync_status_changed(LinphoneFriendList *list, LinphoneFriendListSyncStatus status, const char *msg) {
//    NSLog(@"");
//}
//
//static void carddav_contact_created(LinphoneFriendList *list, LinphoneFriend *lf) {
//    NSLog(@"");
//}
//
//static void carddav_contact_deleted(LinphoneFriendList *list, LinphoneFriend *lf) {
//    NSLog(@"");
//}
//
//static void carddav_contact_updated(LinphoneFriendList *list, LinphoneFriend *new_friend, LinphoneFriend *old_friend) {
//    NSLog(@"");
//}

@end
