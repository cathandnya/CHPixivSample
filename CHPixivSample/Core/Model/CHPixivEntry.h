//
//  Entry.h
//  pview
//
//  Created by Naomoto nya on 12/03/18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface CHPixivEntry : NSObject

@property(readwrite, nonatomic, retain) NSString *illustID;
@property(readwrite, nonatomic, retain) NSString *userName;
@property(readwrite, nonatomic, retain) NSString *userID;
@property(readwrite, nonatomic, retain) NSString *title;
@property(readwrite, nonatomic, retain) NSString *comment;
@property(readwrite, nonatomic, retain) NSString *thumbnailImageURL;
@property(readwrite, nonatomic, retain) NSString *mediumImageURL;
@property(readwrite, nonatomic, retain) NSString *bigImageURL;
@property(readwrite, nonatomic, retain) NSArray *mangaImages;
@property(readwrite, nonatomic, retain) NSDictionary *formInfo;
@property(readwrite, nonatomic, retain) NSString *eid;
@property(readwrite, nonatomic, retain) NSString *qr;
@property(readwrite, nonatomic, assign) int pageCount;
@property(readonly, nonatomic, assign) BOOL isManga;
@property(readonly, nonatomic, assign) BOOL isGIF;
@property(readonly, nonatomic, assign) NSString *link;
@property(readwrite, nonatomic, assign) BOOL needsLoad;
@property(readwrite, nonatomic, assign) BOOL isLoading;
@property(readwrite, nonatomic, assign) BOOL isBookmarked;
@property(readwrite, nonatomic, assign) BOOL isBookmarking;
@property(readwrite, nonatomic, assign) BOOL isRated;
@property(readwrite, nonatomic, assign) BOOL isRating;

+ (CHPixivEntry *) entryWithIllustID:(NSString *)ID;
- (id) initWithIllustID:(NSString *)ID;

- (NSError *) load;
- (void) load:(void (^)(NSError *))completionBlock;
- (void) loadAsync;

- (BOOL) thumbnailIsLoaded;
- (UIImage *) thumbnailImage;
- (void) loadThumbnailImage;

- (BOOL) mediumIsLoaded;
- (BOOL) mediumIsLoading;
- (UIImage *) mediumImage;
- (void) loadMediumImage;

- (BOOL) bigIsLoaded;
- (BOOL) bigIsLoading;
- (UIImage *) bigImage;
- (void) loadBigImage;

- (BOOL) mangaIsLoadedAt:(int)idx;
- (UIImage *) mangaImageAt:(int)idx;
- (void) loadMangaImageAt:(int)idx;

+ (void) addThumbnailImageLoadedObserver:(id)obj selector:(SEL)sel;
+ (void) removeThumbnailImageLoadedObserver:(id)obj;
+ (void) addMediumImageLoadedObserver:(id)obj selector:(SEL)sel;
+ (void) removeMediumImageLoadedObserver:(id)obj;
+ (void) addBigImageLoadedObserver:(id)obj selector:(SEL)sel;
+ (void) removeBigImageLoadedObserver:(id)obj;

- (void) addToBookmark:(BOOL)private block:(void (^)(NSError *))completionBlock;

- (void) rating:(int)value block:(void (^)(NSError *))completionBlock;

@end
