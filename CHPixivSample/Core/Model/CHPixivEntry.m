//
//  Entry.m
//  pview
//
//  Created by Naomoto nya on 12/03/18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import "CHPixivEntry.h"
#import "PixivMediumParser.h"
#import "CHPixivConstants.h"
#import "CHHtmlParserConnectionNoScript.h"
#import "ImageLoaderManager.h"
#import "CHSharedAlertView.h"
#import "CHPixivService.h"

static UIImage *scaleAndRotatedImage(UIImage *image, int kMaxResolution) {
	CGImageRef imgRef = image.CGImage;
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > kMaxResolution || height > kMaxResolution) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = kMaxResolution;
			bounds.size.height = bounds.size.width / ratio;
		} else {
			bounds.size.height = kMaxResolution;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
	CGFloat boundHeight;
	
	UIImageOrientation orient = image.imageOrientation;
	switch(orient) {
		case UIImageOrientationUp:
			transform = CGAffineTransformIdentity;
			break;
		case UIImageOrientationUpMirrored:
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
		case UIImageOrientationDown:
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
		case UIImageOrientationLeftMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationLeft:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationRightMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		case UIImageOrientationRight:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
	}
	
	UIGraphicsBeginImageContext(bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	} else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	CGContextRestoreGState(context);
	UIGraphicsEndImageContext();
	
	return imageCopy;
}


@implementation CHPixivEntry

@synthesize illustID, userID, userName, comment, needsLoad, mediumImageURL, pageCount, bigImageURL, thumbnailImageURL;
@synthesize title, formInfo, isBookmarked, isBookmarking, isRated, isRating, eid, qr, mangaImages;
@synthesize isLoading;
@dynamic isGIF, link, isManga;

+ (CHPixivEntry *) entryWithIllustID:(NSString *)ID {
	CHPixivEntry *e = [[CHPixivService sharedInstance] cachedEntryWithID:ID];
	if (!e) {
		e = [[[CHPixivEntry alloc] initWithIllustID:ID] autorelease];
		[[CHPixivService sharedInstance] setCachedEntry:e withID:ID];
	}
	return e;
}

- (id) initWithIllustID:(NSString *)ID {
	self = [super init];
	if (self) {
		if (!ID) {
			[self release];
			return nil;
		}
		self.illustID = ID;		
		self.needsLoad = YES;		
	}
	return self;
}

- (void) dealloc {
	self.illustID = nil;
	self.title = nil;
	self.userID = nil;
	self.userName = nil;
	self.comment = nil;
	self.mediumImageURL = nil;
	self.bigImageURL = nil;
	self.thumbnailImageURL = nil;
	self.formInfo = nil;
	self.eid = nil;
	self.qr = nil;
	self.mangaImages = nil;
	[super dealloc];
}

- (BOOL) isEqual:(CHPixivEntry *)object {
	if ([object isKindOfClass:[CHPixivEntry class]]) {
		return [self.illustID isEqual:object.illustID];
	} else {
		return NO;
	}
}

#pragma mark-

- (NSError *) load {
	if ([CHPixivService sharedInstance].needsLogin) {
		NSError *err = [[CHPixivService sharedInstance] login];
		if (err) {
			return err;
		}
	}

	PixivMediumParser *parser = [[[PixivMediumParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
	parser.noComments = YES;
	NSString *fmt = [[CHPixivConstants sharedInstance] valueForKeyPath:@"urls.medium"];
	if (!fmt) {
		fmt = @"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@";
	}
	
	CHHtmlParserConnectionNoScript *con = [[[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:fmt, self.illustID]]] autorelease];
	con.referer = @"http://www.pixiv.net/";
	NSError *err = [con startWithParserSync:parser];
	if (![parser.info objectForKey:@"MediumURLString"]) {
		err = [NSError errorWithDomain:@"MediumParseError" code:-1 userInfo:nil];
	}
	if (err) {
		return err;
	} else {
		self.title = [parser.info objectForKey:@"Title"];
		self.userName = [parser.info objectForKey:@"UserName"];
		self.userID = [parser.info objectForKey:@"UserID"];
		self.mediumImageURL = [parser.info objectForKey:@"MediumURLString"];
		self.pageCount = [[parser.info objectForKey:@"MangaPageCount"] intValue];
		self.formInfo = [parser.info objectForKey:@"FormInfo"];
		self.eid = [parser.info objectForKey:@"EID"];
		self.qr = [parser.info objectForKey:@"QR"];
		
		NSString *urlBase = self.mediumImageURL;
		NSString *ext = [urlBase pathExtension];
		NSString *base = [urlBase stringByDeletingPathExtension];
		base = [base substringToIndex:base.length - 2];
		if (self.pageCount > 0) {			
			NSMutableArray *ary = [NSMutableArray array];
			for (int i = 0; i < self.pageCount; i++) {
				NSString *s = [base stringByAppendingString:[[NSString stringWithFormat:@"_p%d", i] stringByAppendingPathExtension:ext]];
				[ary addObject:s];
			}
			self.mangaImages = ary;
			self.bigImageURL = [ary objectAtIndex:0];
		} else {
			NSString *s = [base stringByAppendingPathExtension:ext];
			self.bigImageURL = s;
		}

		self.needsLoad = NO;
		return err;
	}
}

- (void) load:(void (^)(NSError *))completionBlock {
	if (self.isLoading) {
		return;
	}
	self.isLoading = YES;
	
	void (^block)(NSError *) = (completionBlock ? Block_copy(completionBlock) : nil);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *ret = [[self load] retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.isLoading = NO;
			if (block) {
				block(ret);
				Block_release(block);
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:@"EntryLoadFinishedNotification" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:ret, @"Error", nil]];
			[ret autorelease];
		});
	});
}

- (void) loadAsync {
	if (self.needsLoad) {
		[self load:^(NSError *err) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"EntryLoadedNotification" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:err, @"Error", nil]];
		}];
	}
}

#pragma mark-

- (NSString *) link {
	return [NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@", self.illustID];
}

- (BOOL) isGIF {
	return [[thumbnailImageURL pathExtension] caseInsensitiveCompare:@"gif"] == NSOrderedSame;
}

- (BOOL) isManga {
	return self.pageCount > 1;
}

- (BOOL) thumbnailIsLoaded {
	return [[ImageLoaderManager loaderWithType:ImageLoaderType_PixivThumbnail] imageIsLoadedForID:self.illustID];
}

- (UIImage *) thumbnailImage {
	return [[ImageLoaderManager loaderWithType:ImageLoaderType_PixivThumbnail] imageForID:self.illustID];
}

- (void) loadThumbnailImage {
	if (self.thumbnailImageURL) {
		[[ImageLoaderManager loaderWithType:ImageLoaderType_PixivThumbnail] loadImageForID:self.illustID url:self.thumbnailImageURL];
	}
}

- (BOOL) mediumIsLoaded {
	return [[ImageLoaderManager loaderWithType:ImageLoaderType_PixivMedium] imageIsLoadedForID:self.illustID];
}

- (BOOL) mediumIsLoading {
	return [[ImageLoaderManager loaderWithType:ImageLoaderType_PixivMedium] imageIsLoadingForID:self.illustID];
}

- (UIImage *) mediumImage {
	return [[ImageLoaderManager loaderWithType:ImageLoaderType_PixivMedium] imageForID:self.illustID];
}

- (void) loadMediumImage {
	if (self.mediumImageURL) {
		[[ImageLoaderManager loaderWithType:ImageLoaderType_PixivMedium] loadImageForID:self.illustID url:self.mediumImageURL];
	}
}

- (BOOL) bigIsLoaded {
	return [[ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig] imageIsLoadedForID:self.illustID];
}

- (BOOL) bigIsLoading {
	return [[ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig] imageIsLoadingForID:self.illustID];
}

- (UIImage *) bigImage {
	UIImage *img = [[ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig] imageForID:self.illustID];
	if (img.size.width * img.size.height > 2048 * 2048) {
		img = scaleAndRotatedImage(img, 2048);
	}
	return img;
}

- (void) loadBigImage {
	if (self.bigImageURL) {
		[[ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig] loadImageForID:self.illustID url:self.bigImageURL];
	}
}

- (BOOL) mangaIsLoadedAt:(int)idx {
	return [[ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig] imageIsLoadedForID:[self.illustID stringByAppendingFormat:@"_%d", idx]];
}

- (UIImage *) mangaImageAt:(int)idx {
	UIImage *img = [[ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig] imageForID:[self.illustID stringByAppendingFormat:@"_%d", idx]];
	if (img.size.width * img.size.height > 2048 * 2048) {
		img = scaleAndRotatedImage(img, 2048);
	}
	return img;
}

- (void) loadMangaImageAt:(int)idx {
	if (idx < self.mangaImages.count) {
		[[ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig] loadImageForID:[self.illustID stringByAppendingFormat:@"_%d", idx] url:[self.mangaImages objectAtIndex:idx]];
	}
}

#pragma mark-

+ (void) addThumbnailImageLoadedObserver:(id)obj selector:(SEL)sel {
	[[NSNotificationCenter defaultCenter] addObserver:obj selector:sel name:@"ImageLoaderManagerFinishedNotification" object:[ImageLoaderManager loaderWithType:ImageLoaderType_PixivThumbnail]];
}

+ (void) removeThumbnailImageLoadedObserver:(id)obj {
	[[NSNotificationCenter defaultCenter] removeObserver:obj name:@"ImageLoaderManagerFinishedNotification" object:[ImageLoaderManager loaderWithType:ImageLoaderType_PixivThumbnail]];
}

+ (void) addMediumImageLoadedObserver:(id)obj selector:(SEL)sel {
	[[NSNotificationCenter defaultCenter] addObserver:obj selector:sel name:@"ImageLoaderManagerFinishedNotification" object:[ImageLoaderManager loaderWithType:ImageLoaderType_PixivMedium]];
}

+ (void) removeMediumImageLoadedObserver:(id)obj {
	[[NSNotificationCenter defaultCenter] removeObserver:obj name:@"ImageLoaderManagerFinishedNotification" object:[ImageLoaderManager loaderWithType:ImageLoaderType_PixivMedium]];
}

+ (void) addBigImageLoadedObserver:(id)obj selector:(SEL)sel {
	[[NSNotificationCenter defaultCenter] addObserver:obj selector:sel name:@"ImageLoaderManagerFinishedNotification" object:[ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig]];
}

+ (void) removeBigImageLoadedObserver:(id)obj {
	[[NSNotificationCenter defaultCenter] removeObserver:obj name:@"ImageLoaderManagerFinishedNotification" object:[ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig]];
}

#pragma mark-

- (NSError *) addToBookmark:(BOOL)private {
	if ([CHPixivService sharedInstance].needsLogin) {
		NSError *err = [[CHPixivService sharedInstance] login];
		if (err) {
			return err;
		}
	}

	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.pixiv.net/bookmark_add.php"]];
	NSMutableString			*body = [NSMutableString string];
	[req autorelease];

	[body appendString:[NSString stringWithFormat:@"mode=add&type=%@&tt=%@", @"illust", [self.formInfo objectForKey:@"tt"]]];		// type=user
	[body appendString:[NSString stringWithFormat:@"&id=%@", self.illustID]];
	[body appendString:[NSString stringWithFormat:@"&restrict=%d", private ? 1 : 0]];
	
	[req setValue:@"http://www.pixiv.net/" forHTTPHeaderField:@"Referer"];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	[NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	return err;
}

- (void) addToBookmark:(BOOL)private block:(void (^)(NSError *))completionBlock {
	if (![self.formInfo objectForKey:@"tt"]) {
		return;
	}
	if (self.isBookmarked) {
		return;
	}
	if (self.isBookmarking) {
		return;
	}
	self.isBookmarking = YES;
	
	void (^block)(NSError *) = (completionBlock ? Block_copy(completionBlock) : nil);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *ret = [[self addToBookmark:private] retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.isBookmarking = NO;
			if (!ret) {
				self.isBookmarked = YES;
			}
			if (block) {
				block(ret);
				Block_release(block);
			}
			[ret autorelease];
		});
	});
}

#pragma mark-

- (NSError *) rating:(int)value {
	if ([CHPixivService sharedInstance].needsLogin) {
		NSError *err = [[CHPixivService sharedInstance] login];
		if (err) {
			return err;
		}
	}

	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.pixiv.net/rpc_rating.php"]];
	NSString				*body = nil;
	[req autorelease];
	
	body = [NSString stringWithFormat:@"mode=save&i_id=%@&u_id=%@&qr=%@&score=%d", self.illustID, self.eid, self.qr, value];
	
	[req setValue:@"http://www.pixiv.net/" forHTTPHeaderField:@"Referer"];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	[NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	return err;
}

- (void) rating:(int)value block:(void (^)(NSError *))completionBlock {
	if (!self.eid || !self.qr) {
		return;
	}
	if (self.isRated) {
		return;
	}
	if (self.isRating) {
		return;
	}
	self.isRating = YES;
	
	void (^block)(NSError *) = (completionBlock ? Block_copy(completionBlock) : nil);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *ret = [[self rating:value] retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			self.isRating = NO;
			if (!ret) {
				self.isRated = YES;
			}
			if (block) {
				block(ret);
				Block_release(block);
			}
			[ret autorelease];
		});
	});
}

@end
