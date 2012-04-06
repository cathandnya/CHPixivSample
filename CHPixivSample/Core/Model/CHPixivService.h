//
//  PixivService.h
//  pview
//
//  Created by Naomoto nya on 12/03/18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>


@class CHPixivEntry;


@interface CHPixivService : NSObject {
	NSMutableDictionary *entries;
}

@property(readwrite, nonatomic, retain) NSString *username;
@property(readwrite, nonatomic, retain) NSString *password;
@property(readwrite, nonatomic, assign) BOOL available;
@property(readwrite, nonatomic, assign) BOOL needsLogin;
@property(readwrite, nonatomic, retain) NSDate *loginDate;
@property(readwrite, nonatomic, retain) NSString *tt;

+ (CHPixivService *) sharedInstance;

- (void) loadAccount;
- (void) saveAccount;

- (NSError *) login;
- (void) login:(void (^)(NSError *))completionBlock;

- (void) removeAllCache;
- (CHPixivEntry *) cachedEntryWithID:(NSString *)ID;
- (void) setCachedEntry:(CHPixivEntry *)e withID:(NSString *)ID;

@end
