//
//  Entries.m
//  pview
//
//  Created by Naomoto nya on 12/03/18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import "CHPixivEntries.h"
#import "PixivMatrixParser.h"
#import "CHPixivConstants.h"
#import "CHHtmlParserConnectionNoScript.h"
#import "CHPixivEntry.h"
#import "CHSharedAlertView.h"
#import "CHPixivService.h"
#import "JSON.h"


@implementation CHPixivEntries

@synthesize list, isLoading, canLoadMore, name;

+ (CHPixivEntries *) entriesWithInfo:(NSDictionary *)dic {
	if (dic) {
		return [[[NSClassFromString([dic objectForKey:@"class"]) alloc] initWithInfo:dic] autorelease];
	} else {
		return nil;
	}
}

- (NSMutableDictionary *) info {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
	
	[mdic setObject:NSStringFromClass([self class]) forKey:@"class"];
	if (name) [mdic setObject:self.name forKey:@"name"];
	
	return mdic;
}

- (id) initWithInfo:(NSDictionary *)dic {
	self = [super init];
	if (self) {
		self.name = [dic objectForKey:@"name"];
	}
	return self;
}

- (void) dealloc {
	[list release];
	[name release];
	[super dealloc];
}

- (void) addEntries:(NSArray *)ary {
	if (!list) {
		list = [[NSMutableArray alloc] init];
	}
	[list addObjectsFromArray:ary];
}

- (id) refreshSync {
	return nil;
}

- (id) moreSync {
	return nil;
}

- (void) refresh:(void (^)(NSError *))completionBlock {
	if (isLoading) {
		return;
	}
	isLoading = YES;
	
	void (^block)(NSError *) = Block_copy(completionBlock);

	[list removeAllObjects];
	block(nil);

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStart" object:self];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		id ret = [[self refreshSync] retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			isLoading = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStop" object:self];
			
			NSError *err = nil;
			if ([ret isKindOfClass:[NSError class]]) {
				err = ret;
			} else if ([ret isKindOfClass:[NSArray class]]) {
				[self addEntries:ret];
			}
			block(err);
			[ret autorelease];
			Block_release(block);
		});
	});
}

- (void) more:(void (^)(NSError *))completionBlock {
	if (isLoading) {
		return;
	}
	isLoading = YES;
	
	void (^block)(NSError *) = Block_copy(completionBlock);

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStart" object:self];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		id ret = [[self moreSync] retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			isLoading = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStop" object:self];
			
			NSError *err = nil;
			if ([ret isKindOfClass:[NSError class]]) {
				err = ret;
			} else if ([ret isKindOfClass:[NSArray class]]) {
				[self addEntries:ret];
			}
			block(err);
			[ret autorelease];
			Block_release(block);
		});
	});
}

- (NSString *) description {
	return self.name ? self.name : @"";
}

@end


@implementation MatrixEntries

@synthesize scrapingInfoKey, method, currentPage;

- (NSMutableDictionary *) info {
	NSMutableDictionary *mdic = [super info];
	
	if (scrapingInfoKey) [mdic setObject:self.scrapingInfoKey forKey:@"scrapingInfoKey"];
	if (method) [mdic setObject:self.method forKey:@"method"];
	
	return mdic;
}

- (id) initWithInfo:(NSDictionary *)dic {
	self = [super initWithInfo:dic];
	if (self) {
		self.scrapingInfoKey = [dic objectForKey:@"scrapingInfoKey"];
		self.method = [dic objectForKey:@"method"];
	}
	return self;
}

- (void) dealloc {
	[method release];
	[scrapingInfoKey release];
	[super dealloc];
}

- (id) loadSync:(int)page {
	NSError *err = nil;
	if ([CHPixivService sharedInstance].needsLogin) {
		err = [[CHPixivService sharedInstance] login];
		if (err) {
			return err;
		}
	}
	
	[tmpList release];
	tmpList = [[NSMutableArray alloc] init];
	
	PixivMatrixParser *parser = [[[PixivMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO] autorelease];
	parser.delegate = (id)self;
	if (scrapingInfoKey) {
		NSDictionary *d = [[CHPixivConstants sharedInstance] valueForKeyPath:scrapingInfoKey];
		if (d) {
			parser.scrapingInfo = d;
		}
	}
	CHHtmlParserConnectionNoScript *con = [[[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixiv.net/%@p=%d", self.method, page]]] autorelease];
	con.referer = @"http://www.pixiv.net/mypage.php";
	err = [con startWithParserSync:parser];
	if (err) {
		[tmpList release];
		tmpList = nil;
		return err;
	} else {
		NSArray *ary = [NSArray arrayWithArray:tmpList];
		[tmpList autorelease];
		tmpList = nil;
		
		if ([self.method hasPrefix:@"ranking"]) {
			self.canLoadMore = (page < 6);
		} else {
			self.canLoadMore = (page < parser.maxPage);
		}
		return ary;
	}
}

- (id) refreshSync {
	NSError *err = [self loadSync:1];
	if ([err isKindOfClass:[NSArray class]]) {
		currentPage = 1;
	}
	return err;
}

- (id) moreSync {
	NSError *err = [self loadSync:self.currentPage + 1];
	if ([err isKindOfClass:[NSArray class]]) {
		currentPage++;
	}
	return err;
}

- (void) matrixParser:(id)parser foundPicture:(NSDictionary *)pic {
	CHPixivEntry *e = [CHPixivEntry entryWithIllustID:[pic objectForKey:@"IllustID"]];
	if (e) {
		e.thumbnailImageURL = [pic objectForKey:@"ThumbnailURLString"];
		/*
		[e load:^(NSError *err) {
			if (!err) {
				[e loadThumbnailImage];
				[e loadMediumImage];
				//[e loadBigImage];
			} else {
				[[SharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Load failed.", nil)];
			}
		}];
		 */
		//[e loadAsync];
		[tmpList addObject:e];
	}
}

- (void) matrixParser:(id)parser finished:(long)err {
}

@end


@implementation StaccEntries

@synthesize scrapingInfoKey, method, nextMaxSID;

- (NSMutableDictionary *) info {
	NSMutableDictionary *mdic = [super info];
	
	if (scrapingInfoKey) [mdic setObject:self.scrapingInfoKey forKey:@"scrapingInfoKey"];
	if (method) [mdic setObject:self.method forKey:@"method"];
	
	return mdic;
}

- (id) initWithInfo:(NSDictionary *)dic {
	self = [super initWithInfo:dic];
	if (self) {
		self.scrapingInfoKey = [dic objectForKey:@"scrapingInfoKey"];
		self.method = [dic objectForKey:@"method"];
	}
	return self;
}

- (void) dealloc {
	[method release];
	[scrapingInfoKey release];
	[nextMaxSID release];
	[super dealloc];
}

- (id) loadSync:(BOOL)more {
	NSError *err = nil;
	if ([CHPixivService sharedInstance].needsLogin) {
		err = [[CHPixivService sharedInstance] login];
		if (err) {
			return err;
		}
	}
	
	NSString *url;
	if (more && nextMaxSID) {
		url = [NSString stringWithFormat:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_url_format"], self.method, self.nextMaxSID, [CHPixivService sharedInstance].tt];
	} else {
		url = [NSString stringWithFormat:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_url_format"], self.method, @"", [CHPixivService sharedInstance].tt];
	}
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[req setValue:@"http://www.pixiv.net/mypage.php" forHTTPHeaderField:@"Referer"];
	DLog(@"load: %@", url);
	
	NSURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	} else {
		NSMutableArray *mary = [NSMutableArray array];
		
		NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		DLog(@"%@", str);
		id json = [str JSONValue];
		
		self.nextMaxSID = [json valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_next_max_id_key"]];
		self.canLoadMore = ([[json valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_is_last_page_key"]] intValue] == 0);
		
		id status = [json valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_status_key"]];
		id illust = [json valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_illust_key"]];
		id user = [json valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_user_key"]];
		for (NSString *key in [[status allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			return [[NSNumber numberWithInt:[obj2 intValue]] compare:[NSNumber numberWithInt:[obj1 intValue]]];
		}]) {
			NSDictionary *d = [status objectForKey:key];
			NSString *iid = [d valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_illust_id_key"]];
			if (iid) {
				if ([iid isKindOfClass:[NSNumber class]]) {
					iid = [(NSNumber *)iid stringValue];
				}
				NSDictionary *i = [illust valueForKeyPath:iid];
				if (i) {
					NSString *uid = [i valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_user_id_key"]];
					if ([uid isKindOfClass:[NSNumber class]]) {
						uid = [(NSNumber *)uid stringValue];
					}
					NSDictionary *u = [user valueForKeyPath:uid];
					CHPixivEntry *e = [CHPixivEntry entryWithIllustID:iid];
					if (e) {
						e.title = [i valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_entry_title_key"]];
						e.comment = [i valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_entry_comment_key"]];
						e.userID = [u valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_entry_user_id_key"]];
						e.userName = [u valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_entry_user_name_key"]];
						
						e.thumbnailImageURL = [i valueForKeyPath:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.stacc_thumbnail_url_key"]];
						NSString *base = [e.thumbnailImageURL stringByDeletingPathExtension];
						NSString *ext = [e.thumbnailImageURL pathExtension];
						e.mediumImageURL = [[[base substringToIndex:base.length - 1] stringByAppendingString:@"m"] stringByAppendingPathExtension:ext];
						//e.bigImageURL = [[base substringToIndex:base.length - 2] stringByAppendingPathExtension:ext];
						
						//[e load];
						//[e loadAsync];
						
						//e.needsLoad = NO;
						[mary addObject:e];
					}
				}
			}
		}
		
		return mary;
	}
}

- (id) refreshSync {
	NSError *err = [self loadSync:NO];
	if ([err isKindOfClass:[NSArray class]]) {
		
	}
	return err;
}

- (id) moreSync {
	NSError *err = [self loadSync:YES];
	if ([err isKindOfClass:[NSArray class]]) {

	}
	return err;
}

@end
