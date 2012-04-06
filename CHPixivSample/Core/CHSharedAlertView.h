//
//  SharedAlertView.h
//  girls pic
//
//  Created by nya on 11/07/04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CHSharedAlertView : NSObject<UIAlertViewDelegate> {
    BOOL isPresent;
}

+ (CHSharedAlertView *) sharedInstance;

- (void) showWithTitle:(NSString *)title message:(NSString *)msg cancelButtonTitle:(NSString *)cancel okButtonTitle:(NSString *)ok;
- (void) showError:(NSError *)err withTitle:(NSString *)title;

@end
