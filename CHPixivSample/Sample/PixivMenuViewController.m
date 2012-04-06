//
//  PixivMenuViewController.m
//  PixiSample
//
//  Created by Naomoto nya on 12/03/27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PixivMenuViewController.h"
#import "PixivAccountViewController.h"
#import "PixivEntriesViewController.h"
#import "PixivComposeViewController.h"
#import "CHPixivEntries.h"

@interface PixivMenuViewController ()

@end

@implementation PixivMenuViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
		rows = [[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"menu" ofType:@"plist"]] retain];
    }
    return self;
}

- (void) dealloc {
	[rows release];
	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Account", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(accountAction:)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeAction:)] autorelease];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return rows.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSDictionary *sec = [rows objectAtIndex:section];
    return [[sec objectForKey:@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	NSDictionary *sec = [rows objectAtIndex:indexPath.section];
	NSDictionary *row = [[sec objectForKey:@"rows"] objectAtIndex:indexPath.row];
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	cell.textLabel.text = [row objectForKey:@"name"];	
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary *sec = [rows objectAtIndex:indexPath.section];
	NSDictionary *row = [[sec objectForKey:@"rows"] objectAtIndex:indexPath.row];
	
	NSString *className = [row objectForKey:@"class"];
	Class cls = [MatrixEntries class];
	if (className) {
		cls = NSClassFromString(className);
	}
	
	MatrixEntries *e = [[[cls alloc] init] autorelease];
	e.method = [row objectForKey:@"method"];
	e.scrapingInfoKey = [row objectForKey:@"parser"];
	e.name = [row objectForKey:@"name"];
	
	PixivEntriesViewController *vc = [[[PixivEntriesViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
	vc.entries = e;
	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark-

- (void) accountAction:(id)sender {
	PixivAccountViewController *vc = [[[PixivAccountViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
	[self presentModalViewController:nc animated:YES];
}

- (void) composeAction:(id)sender {
	PixivComposeViewController *vc = [[[PixivComposeViewController alloc] initWithNibName:@"PixivComposeViewController" bundle:nil] autorelease];
	UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
	[self presentModalViewController:nc animated:YES];
}

@end
