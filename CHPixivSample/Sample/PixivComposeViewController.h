//
//  PixivComposeViewController.h
//  PixiSample
//
//  Created by Naomoto nya on 12/03/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CHPixivUploader;

@interface PixivComposeViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate> {
	CHPixivUploader *uploader;
}

@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UITextField *titleField;
@property (retain, nonatomic) IBOutlet UITextField *captionField;
@property (retain, nonatomic) IBOutlet UITextField *tagsField;

@property(readwrite, nonatomic, retain) NSString *titleValue;
@property(readwrite, nonatomic, retain) NSString *caption;
@property(readwrite, nonatomic, retain) NSString *tags;
@property(readwrite, nonatomic, retain) UIImage *image;

@end
