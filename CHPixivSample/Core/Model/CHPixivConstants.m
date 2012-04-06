//
//  PixitailConstants.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/21.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//


#import "CHPixivConstants.h"


#define VERS		(10)


@implementation CHPixivConstants

+ (ConstantsManager *) sharedInstance {
	static ConstantsManager *obj = nil;
	if (obj == nil) {
		obj = [[CHPixivConstants alloc] init];
	}
	return obj;
}

- (NSString *) defaultConstantsPath {
	return [[NSBundle mainBundle] pathForResource:@"pixiv" ofType:@"plist"];
}

- (id) init {
	self = [super init];
	if (self) {
		if (VERS > self.vers) {
			[self setConstants:[NSDictionary dictionaryWithContentsOfFile:[self defaultConstantsPath]]];
			[self setVers:VERS];
		}
	}
	return self;
}

/*
 Pixitailと同じスクレイピング定義を参照しています。
 */

- (NSString *) versURL {
	//return nil;
	return @"http://dl.dropbox.com/u/7748830/pixiv.vers";
}

- (NSString *) constantsURL {
	return @"http://dl.dropbox.com/u/7748830/pixiv.plist";
}

@end
