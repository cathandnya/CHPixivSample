//
//  PixivEntriesViewController.m
//  PixiSample
//
//  Created by Naomoto nya on 12/03/27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PixivEntriesViewController.h"
#import "CHPixivEntry.h"
#import "CHPixivEntries.h"
#import "CHSharedAlertView.h"


@interface PixivEntryCell : UITableViewCell

@end

@implementation PixivEntryCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	}
	return self;
}
			
- (void) layoutSubviews {
	[super layoutSubviews];
	
	CGRect r = self.frame;
	r.origin = CGPointZero;
	self.imageView.frame = CGRectInset(r, 5, 5);
}

@end


@interface PixivEntriesViewController ()

@end

@implementation PixivEntriesViewController

@synthesize entries;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc {
	[CHPixivEntry removeThumbnailImageLoadedObserver:self];
	[CHPixivEntry removeMediumImageLoadedObserver:self];

	self.entries = nil;
	
	[super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.tableView.rowHeight = 320;

	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshAction:)] autorelease];

	[CHPixivEntry addThumbnailImageLoadedObserver:self selector:@selector(thumbnailLoaded:)];
	[CHPixivEntry addMediumImageLoadedObserver:self selector:@selector(imageLoaded:)];
}

- (void)viewDidUnload
{
	[CHPixivEntry removeThumbnailImageLoadedObserver:self];
	[CHPixivEntry removeMediumImageLoadedObserver:self];
	
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.tableView reloadData];
	if (entries.list.count == 0) {
		[self refreshAction:nil];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) {
		return entries.list.count;
	} else {
		return 1;
	}
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		return 320;
	} else {
		return 44;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 	if (indexPath.section == 0) {
		static NSString *CellIdentifier = @"ImageCell";
		PixivEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell) {
			cell = [[[PixivEntryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		}
		
		CHPixivEntry *e = [entries.list objectAtIndex:indexPath.row];
		if (e.needsLoad) {
			[e load:^(NSError *err) {
				if (err) {
					[[CHSharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Load failed.", nil)];
				} else {
					if (!e.mediumIsLoaded) {
						[e loadMediumImage];
					}
				}
			}];
		}
		if (e.mediumIsLoaded) {
			cell.imageView.image = e.mediumImage;
		} else {
			[e loadMediumImage];
			if (e.thumbnailIsLoaded) {
				cell.imageView.image = e.thumbnailImage;
			} else {
				[e loadThumbnailImage];
				cell.imageView.image = nil;
			}
		}
		
		return cell;
	} else {
		static NSString *CellIdentifier = @"Cell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (!cell) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.textLabel.text = NSLocalizedString(@"More", nil);
			cell.textLabel.textAlignment = UITextAlignmentCenter;
		}
		return cell;
	}
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == 1) {
		[entries more:^(NSError *err) {
			if (err) {
				[[CHSharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Load failed.", nil)];
			}
			[self.tableView reloadData];
		}];
	}
}

- (void) refreshAction:(id)sender {
	[entries refresh:^(NSError *err) {
		if (err) {
			[[CHSharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Load failed.", nil)];
		}
		[self.tableView reloadData];
	}];
}

- (void) imageLoaded:(NSNotification *)notif {
	NSString *ID = [[notif userInfo] objectForKey:@"ID"];
	for (UITableViewCell *cell in [self.tableView visibleCells]) {
		NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
		if (indexPath.section == 0) {
			CHPixivEntry *e = [entries.list objectAtIndex:indexPath.row];
			if ([e.illustID isEqualToString:ID]) {
				[self.tableView reloadData];
				//cell.imageView.image = e.mediumImage;
				//[cell setNeedsDisplay];
				break;
			}
		}
	}
}

- (void) thumbnailLoaded:(NSNotification *)notif {
	NSString *ID = [[notif userInfo] objectForKey:@"ID"];
	for (UITableViewCell *cell in [self.tableView visibleCells]) {
		NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
		if (indexPath.section == 0) {
			CHPixivEntry *e = [entries.list objectAtIndex:indexPath.row];
			if ([e.illustID isEqualToString:ID]) {
				[self.tableView reloadData];
				//cell.imageView.image = e.mediumImage;
				//[cell setNeedsDisplay];
				break;
			}
		}
	}
}

@end
