//
//  PixivService.m
//  pview
//
//  Created by Naomoto nya on 12/03/18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import "CHPixivService.h"
#import "CHPixivConstants.h"
#import "RegexKitLite.h"
#import "ImageLoaderManager.h"


static NSString* encodeURIComponent(NSString* s) {
    return [((NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																(CFStringRef)s,
																NULL,
																(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																kCFStringEncodingUTF8)) autorelease];
}


@implementation CHPixivService

@synthesize username, password, tt;
@dynamic available, needsLogin;
@synthesize loginDate;

+ (CHPixivService *) sharedInstance {
	static CHPixivService *obj = nil;
	if (!obj) {
		obj = [[CHPixivService alloc] init];
	}
	return obj;
}

- (id) init {
	self = [super init];
	if (self) {
		[ImageLoaderManager loaderWithType:ImageLoaderType_PixivThumbnail].referer = @"http://www.pixiv.net/";
		[ImageLoaderManager loaderWithType:ImageLoaderType_PixivMedium].referer = @"http://www.pixiv.net/";
		[ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig].referer = @"http://www.pixiv.net/";

		entries = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc {
	self.username = nil;
	self.password = nil;
	self.loginDate = nil;
	self.tt = nil;
	[entries release];
	[super dealloc];
}

- (BOOL) available {
	return self.username.length > 0 && self.password.length > 0;
}

- (void) loadAccount {
	self.username = [[NSUserDefaults standardUserDefaults] stringForKey:@"PixivUsername"];
	self.password = [[NSUserDefaults standardUserDefaults] stringForKey:@"PixivPassword"];
}

- (void) saveAccount {
	if (self.username) {
		[[NSUserDefaults standardUserDefaults] setObject:self.username forKey:@"PixivUsername"];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PixivUsername"];
	}

	if (self.password) {
		[[NSUserDefaults standardUserDefaults] setObject:self.password forKey:@"PixivPassword"];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PixivPassword"];
	}

	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSTimeInterval) loginExpiredTimeInterval {
	//return DBL_MAX;
	if ([[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.expired_seconds"]) {
		return [[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.expired_seconds"] doubleValue];
	} else {
		return DBL_MAX;
	}
}

- (BOOL) needsLogin {
	if (loginDate) {
		return -[loginDate timeIntervalSinceNow] > [self loginExpiredTimeInterval] - 3 * 60;
	} else {
		return YES;
	}
}

#pragma mark-

- (NSError *) login {
	[[CHPixivConstants sharedInstance] reloadSync];
	
	[self removeAllCache];
	
	NSString *url = [[CHPixivConstants sharedInstance] valueForKeyPath:@"urls.login"];
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
	NSString				*body;
	[req autorelease];
	
	body = [NSString stringWithFormat:@"mode=login&pixiv_id=%@&pass=%@&skip=1", encodeURIComponent(self.username), encodeURIComponent(self.password)];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	} else {
		NSString *retstr = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		
		NSRange	range = {-1, 0};
		if (retstr) range = [retstr rangeOfString:@"action=\"/login.php\""];
		if (range.location != NSNotFound && range.length > 0) {
			// ログイン失敗
			return [NSError errorWithDomain:@"PixivService" code:-1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Load failed.", NSLocalizedDescriptionKey, nil]];
		} else {
			NSString *regex = [[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.tt_regex"];
			NSArray *ary = [retstr captureComponentsMatchedByRegex:regex];
			if (ary.count > 1) {
				self.tt = [ary objectAtIndex:1];
				self.loginDate = [NSDate date];
				return nil;
			} else {
				return [NSError errorWithDomain:@"PixivService" code:-1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Load failed.", NSLocalizedDescriptionKey, nil]];
			}			
		}
	}
}

- (void) login:(void (^)(NSError *))completionBlock {
	void (^block)(NSError *) = Block_copy(completionBlock);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *ret = [[self login] retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			block(ret);
			[ret autorelease];
			Block_release(block);
		});
	});
}

#pragma amrk-

- (void) removeAllCache {
	[entries removeAllObjects];
}

- (CHPixivEntry *) cachedEntryWithID:(NSString *)ID {
	return [entries objectForKey:ID];
}

- (void) setCachedEntry:(CHPixivEntry *)e withID:(NSString *)ID {
	[entries setObject:e forKey:ID];
}

@end
