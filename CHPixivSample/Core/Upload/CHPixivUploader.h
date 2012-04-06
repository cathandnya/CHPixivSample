//
//  PixivUploader.h
//  PixiSample
//
//  Created by Naomoto nya on 12/03/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	PixivUploaderDataType_JPEG = 0,
	PixivUploaderDataType_PNG,
} PixivUploaderDataType;

@interface CHPixivUploader : NSObject

@property(readwrite, nonatomic, retain) NSString *tt;
@property(readwrite, nonatomic, retain) NSData *data;
@property(readwrite, nonatomic, assign) PixivUploaderDataType dataType;
@property(readwrite, nonatomic, retain) NSDictionary *params;

- (BOOL) upload:(void (^)(NSString *illustID, NSError *))completionBlock progress:(void (^)(float progress))progressBlock;

@end
