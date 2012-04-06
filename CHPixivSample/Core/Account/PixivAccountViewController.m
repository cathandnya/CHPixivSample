//
//  PixivAccountViewController.m
//  pview
//
//  Created by Naomoto nya on 12/03/18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import "PixivAccountViewController.h"
#import "CHPixivService.h"
#import "CHSharedAlertView.h"


@implementation PixivAccountViewController

- (void) done:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentAccountWillChangeNotification" object:self];
	
	for (TextFieldCell *cell in [self.tableView visibleCells]) {
		if ([cell isKindOfClass:[TextFieldCell class]]) [cell.textField resignFirstResponder];
	}
	
	[CHPixivService sharedInstance].username = self.username;
	[CHPixivService sharedInstance].password = self.password;
	
	[self showProgressWithTitle:NSLocalizedString(@"Login", nil)];	
	[[CHPixivService sharedInstance] login:^(NSError *err) {
		[self hideProgress];
		if (err) {
			[CHPixivService sharedInstance].username = nil;
			[CHPixivService sharedInstance].password = nil;
			[[CHSharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Login failed.", nil)];
		} else {
			[[CHPixivService sharedInstance] saveAccount];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentAccountDidChangeNotification" object:self];
			[self dismissModalViewControllerAnimated:YES];
		}
	}];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
