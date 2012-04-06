//
//  PixivComposeViewController.m
//  PixiSample
//
//  Created by Naomoto nya on 12/03/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PixivComposeViewController.h"
#import "CHPixivUploader.h"
#import "CHSharedAlertView.h"

@interface PixivComposeViewController ()

@end

@implementation PixivComposeViewController

@synthesize imageView;
@synthesize titleField;
@synthesize captionField;
@synthesize tagsField;
@synthesize titleValue, caption, tags, image;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		uploader = [[CHPixivUploader alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", nil) style:UIBarButtonItemStyleDone target:self action:@selector(sendAction:)] autorelease];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancelAction:)] autorelease];
	
	[self updateDisplay];
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setTitleField:nil];
    [self setCaptionField:nil];
    [self setTagsField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [imageView release];
    [titleField release];
    [captionField release];
    [tagsField release];
	self.titleValue = nil;
	self.caption = nil;
	self.tags = nil;
	self.image = nil;
	[uploader release];
    [super dealloc];
}

#pragma mark-

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == titleField) {
		self.titleValue = textField.text;
	} else if (textField == captionField) {
		self.caption = textField.text;
	} else if (textField == tagsField) {
		self.tags = textField.text;
	}
	[self updateDisplay];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

- (NSArray *) tagsArray {
	return [self.tags componentsSeparatedByString:@" "];
}

- (void) updateDisplay {
	self.imageView.image = image;
	self.titleField.text = titleValue;
	self.captionField.text = caption;
	self.tagsField.text = tags;
	
	self.navigationItem.rightBarButtonItem.enabled = (self.image != nil && self.titleValue.length > 0 && self.caption.length > 0 && [self tagsArray].count > 0);
}

- (IBAction)imageAction:(id)sender {
	UIImagePickerController *picker = [[[UIImagePickerController alloc] init] autorelease];
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.delegate = self;
	[self presentModalViewController:picker animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
	[self updateDisplay];
	
	[self dismissModalViewControllerAnimated:YES];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) cancelAction:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) sendAction:(id)sender {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
	[mdic setObject:self.titleValue forKey:@"title[]"];		// タイトル
	[mdic setObject:self.caption forKey:@"comment[]"];		// キャプション
	[mdic setObject:self.tags forKey:@"tag[]"];				// タグ(スペース区切り)
	[mdic setObject:@"0" forKey:@"taglock[0]"];
	[mdic setObject:@"0" forKey:@"x_restrict[0]"];
	[mdic setObject:@"0" forKey:@"restrict[0]"];
	[mdic setObject:@"0" forKey:@"resopen[0]"];
	[mdic setObject:@"0" forKey:@"qrsopen[0]"];
	
	uploader.params = mdic;
	uploader.data = UIImageJPEGRepresentation(self.image, 0.8);
	
	self.navigationItem.rightBarButtonItem.enabled = NO;
	self.navigationItem.leftBarButtonItem.enabled = NO;
	BOOL b = [uploader upload:^(NSString *illustID, NSError *err) {
		self.navigationItem.rightBarButtonItem.enabled = YES;
		self.navigationItem.leftBarButtonItem.enabled = YES;
		if (err) {
			[[CHSharedAlertView sharedInstance] showError:err withTitle:@"Failed."];
		} else {
			[self dismissModalViewControllerAnimated:YES];
		}
	} progress:nil];
	if (!b) {
		[[CHSharedAlertView sharedInstance] showWithTitle:@"Needs login" message:nil cancelButtonTitle:nil okButtonTitle:@"OK"];
	}
}

@end
