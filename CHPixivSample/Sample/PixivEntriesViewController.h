//
//  PixivEntriesViewController.h
//  PixiSample
//
//  Created by Naomoto nya on 12/03/27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CHPixivEntries;

@interface PixivEntriesViewController : UITableViewController

@property(readwrite, nonatomic, retain) CHPixivEntries *entries;

@end
