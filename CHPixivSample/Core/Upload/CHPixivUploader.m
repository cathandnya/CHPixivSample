//
//  PixivUploader.m
//  PixiSample
//
//  Created by Naomoto nya on 12/03/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CHPixivUploader.h"
#import "ASIFormDataRequest.h"
#import "CHPixivConstants.h"
#import "RegexKitLite.h"


static NSString* encodeURIComponent(NSString* s) {
    return [((NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																(CFStringRef)s,
																NULL,
																(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																kCFStringEncodingUTF8)) autorelease];
}


@implementation CHPixivUploader

@synthesize data, params, dataType, tt;

- (void) dealloc {
	self.data = nil;
	self.params = nil;
	self.tt = nil;
	[super dealloc];
}

- (void) addValue:(id)val forKey:(NSString *)key toBody:(NSMutableData *)body withBoundary:(NSString *)boundary {
	if ([val isKindOfClass:[NSNumber class]]) {
		val = [val stringValue];
	}
	if ([val isKindOfClass:[NSString class]]) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([val isKindOfClass:[NSData class]]) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: file; name=\"%@\"; filename=\"file.jpg\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"image/jpeg"] dataUsingEncoding:NSUTF8StringEncoding]];
		//DLog(@"tumblr data: %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
		[body appendData:val];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([val isKindOfClass:[NSArray class]]) {
		for (id v in val) {
			[self addValue:v forKey:key toBody:body withBoundary:boundary];
		}
	} else {
		assert(0);
	}
}

- (NSData *) multipartBodyData:(NSDictionary *)dic boundary:(NSString *)boundary {	
	NSMutableData	*body = [NSMutableData data];
	
	if ([dic count] > 0) {			
		NSArray *keys = [[dic allKeys] sortedArrayUsingSelector:@selector(compare:)];
		for (NSString *key in keys) {
			id val = [dic objectForKey:key];
			[self addValue:val forKey:key toBody:body withBoundary:boundary];
		}
	}
	[body appendData:[[NSString stringWithFormat:@"%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	return body;
}

- (NSString *) paramString:(NSDictionary *)dic {
	NSMutableString *str = [NSMutableString string];
	if ([dic count] > 0) {			
		NSArray *keys = [[dic allKeys] sortedArrayUsingSelector:@selector(compare:)];
		for (NSString *key in keys) {
			[str appendFormat:@"%@=%@", encodeURIComponent(key), encodeURIComponent([dic objectForKey:key])];
			if (key != [keys lastObject]) {
				[str appendString:@"&"];
			}
		}
	}
	return str;
}

- (void) contentUpload:(void (^)(NSString *illustID, NSError *))completionBlock {
	ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.upload_url_2"]]];
	[req addRequestHeader:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.upload_url_2"] value:@"Referer"];
	[req setPostValue:self.tt forKey:@"tt"];
	
	NSDictionary *dic = [[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.upload_param_2"];
	for (NSString *key in [dic allKeys]) {
		NSString *val = [dic objectForKey:key];
		[req setPostValue:val forKey:key];
	}
	for (NSString *key in [self.params allKeys]) {
		NSString *val = [self.params objectForKey:key];
		[req setPostValue:val forKey:key];
	}
	
	[req setCompletionBlock:^{
		NSString *str = [[[NSString alloc] initWithData:req.responseData encoding:NSUTF8StringEncoding] autorelease];
		DLog(@"up2: %@", str);
		str = [str stringByReplacingOccurrencesOfRegex:@"(\r\n|\n\r|\n|\r)" withString:@""];
		
		NSError *err = nil;
		NSString *iid = nil;
		NSArray *ary = [str captureComponentsMatchedByRegex:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.upload_finish_regex"]];
		if (ary.count != 2) {
			// failed.
			err = [NSError errorWithDomain:@"PixivUploader" code:-1 userInfo:nil];
		} else {
			iid = [ary objectAtIndex:1];
		}
		DLog(@"uploaded: %@", iid);
		
		if (completionBlock) {
			completionBlock(iid, err);
		}
	}];
	[req setFailedBlock:^{
		if (completionBlock) {
			NSError *err = [req.error retain];
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock(nil, err);
				[err release];
			});
		}
	}];
	[req startSynchronous];
	
	/*
	 NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.pixiv.net/content_upload.php"]];
	 [req setHTTPMethod:@"POST"];
	 [req setValue:@"http://www.pixiv.net/" forHTTPHeaderField:@"Referer"];
	 
	 NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:self.params];
	 [mdic setObject:@"move" forKey:@"mode"];
	 [mdic setObject:@"illust" forKey:@"uptype"];
	 [mdic setObject:[PixivService sharedInstance].tt forKey:@"tt"];
	 [req setHTTPBody:[[self paramString:mdic] dataUsingEncoding:NSUTF8StringEncoding]];
	 
	 NSURLResponse *res = nil;
	 NSError *err = nil;
	 NSData *retData = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	 [err retain];
	 dispatch_async(dispatch_get_main_queue(), ^{
	 [err autorelease];
	 if (err) {
	 if (completionBlock) {
	 completionBlock(err);
	 }
	 } else {
	 NSString *str = [[[NSString alloc] initWithData:retData encoding:NSUTF8StringEncoding] autorelease];
	 DLog(@"up2: %@", str);
	 if (completionBlock) {
	 completionBlock(err);
	 }
	 }
	 });
	 */
}

- (BOOL) upload:(void (^)(NSString *illustID, NSError *))completionBlock progress:(void (^)(float progress))progressBlock {
	if (self.tt == nil) {
		return NO;
	}
	if (self.data == nil) {
		return NO;
	}
	if (self.params == nil) {
		return NO;
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		//NSError *err = nil;
		
		ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.upload_url_1"]]];
		[req addRequestHeader:[[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.upload_url_1"] value:@"Referer"];
		switch (self.dataType) {
			case PixivUploaderDataType_JPEG:
				[req addData:data withFileName:@"file.jpg" andContentType:@"image/jpeg" forKey:@"upfile"];
				break;
			case PixivUploaderDataType_PNG:
				[req addData:data withFileName:@"file.png" andContentType:@"image/png" forKey:@"upfile"];
				break;
			default:
				assert(0);
				break;
		}
		NSDictionary *dic = [[CHPixivConstants sharedInstance] valueForKeyPath:@"constants.upload_param_1"];
		for (NSString *key in [dic allKeys]) {
			NSString *val = [dic objectForKey:key];
			[req setPostValue:val forKey:key];
		}
		
		[req setCompletionBlock:^{
			NSString *str = [[[NSString alloc] initWithData:req.responseData encoding:NSUTF8StringEncoding] autorelease];
			DLog(@"up: %@", str);
			
			if (progressBlock) {
				dispatch_async(dispatch_get_main_queue(), ^{
					progressBlock(1.0f);
				});
			}
			[self contentUpload:completionBlock];
		}];
		[req setFailedBlock:^{
			if (completionBlock) {
				NSError *err = [req.error retain];
				dispatch_async(dispatch_get_main_queue(), ^{
					completionBlock(nil, err);
					[err release];
				});
			}
		}];
		if (progressBlock) {
			__block unsigned long long sent = 0;
			[req setBytesSentBlock:^(unsigned long long size, unsigned long long total) {
				dispatch_async(dispatch_get_main_queue(), ^{
					sent += size;
					progressBlock((float)sent / (float)total);
				});
			}];
		}
		[req startSynchronous];
		
		/*
		 NSString *boundary = @"------------0xKhTmLbOuNdArY";
		 NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.pixiv.net/content_upload.php"]];
		 [req setHTTPMethod:@"POST"];
		 [req setValue:@"http://www.pixiv.net/" forHTTPHeaderField:@"Referer"];
		 
		 NSMutableDictionary *param = [NSMutableDictionary dictionary];
		 [param setObject:@"upload" forKey:@"mode"];
		 [param setObject:data forKey:@"upfile"];
		 
		 [req setHTTPBody:[self multipartBodyData:param boundary:boundary]];
		 
		 NSURLResponse *res = nil;
		 NSData *retData = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
		 if (err) {
		 if (completionBlock) {
		 [err retain];
		 dispatch_async(dispatch_get_main_queue(), ^{
		 completionBlock(err);
		 [err release];
		 });
		 }
		 } else {			
		 NSString *str = [[[NSString alloc] initWithData:retData encoding:NSUTF8StringEncoding] autorelease];
		 DLog(@"up: %@", str);
		 
		 [NSThread sleepForTimeInterval:5];
		 [self contentUpload:completionBlock];
		 }
		 */
	});
	return YES;
}

@end
