//
//  PostToFeedViewController.m
//  Epic Vegas IV
//
//  Created by Zach on 8/7/14.
//  Copyright (c) 2014 Zach Kohl. All rights reserved.
//

#import "PostToFeedViewController.h"
#import "UIImage+ResizeAdditions.h"

@interface PostToFeedViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintToAdjust;

@property (strong, nonatomic) IBOutlet UIImagePickerController *photoPicker;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *locationButton;

@property (nonatomic, strong) PFFile *photoFile;
@property (nonatomic, strong) PFFile *thumbnailFile;
@property (nonatomic, assign) UIBackgroundTaskIdentifier fileUploadBackgroundTaskId;
@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;

@property (nonatomic, strong) UIActivityIndicatorView* spinner;
@end

@implementation PostToFeedViewController


NSInteger characterLimit = 300;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [_messageTextView becomeFirstResponder];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    _messageTextView.delegate = self;
    
    // round out profile image
    _profileImageView.clipsToBounds = YES;
    _profileImageView.alpha = 0;
    _profileImageView.layer.cornerRadius = _profileImageView.layer.frame.size.height / 2;
    
    // Load user's photo into the post text box
    if(!_profileImageView.image)
    {
        PFFile *imageFile = [[PFUser currentUser] objectForKey:kUserProfilePicMediumKey];
        if (imageFile) {
            [_profileImageView setFile:imageFile];
            [_profileImageView loadInBackground:^(UIImage *image, NSError *error) {
                if (!error) {
                    [UIView animateWithDuration:1.0f animations:^{
                        _profileImageView.alpha = 1.0f;
                    }];
                }
            }];
        }
    }
    else{
        [UIView animateWithDuration:1.0f animations:^{
            _profileImageView.alpha = 1.0f;
        }];
    }
    
    [self updateCharacterCountString];
    
//    // observe keyboard hide and show notifications to resize the text view appropriately
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardWillShow:)
//                                                 name:UIKeyboardWillShowNotification
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardWillHide:)
//                                                 name:UIKeyboardWillHideNotification
//                                               object:nil];
 
    // start editing text
    [self initMessageAccessoryView];
    
    self.fileUploadBackgroundTaskId = UIBackgroundTaskInvalid;
    self.photoPostBackgroundTaskId = UIBackgroundTaskInvalid;
}

-(void)initMessageAccessoryView
{
    UIToolbar* keyboardToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    //numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    
    _cameraButton =[[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(cameraButtonClicked:)];
    _cameraButton.image = [UIImage imageNamed:@"full__0000s_0122_camera.png"];
    _cameraButton.tintColor = [UIColor darkGrayColor];
    _cameraButton.width = 25;
    
    _locationButton = [[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(locationButtonClicked:)];
    _locationButton.image = [UIImage imageNamed:@"Location Black.png"];
    _locationButton.tintColor = [UIColor darkGrayColor];
    _locationButton.width = 30;
    
    keyboardToolbar.items = [NSArray arrayWithObjects:_cameraButton,_locationButton, nil];
    [keyboardToolbar sizeToFit];
    
    [keyboardToolbar addSubview:_characterCountLabel];
    [_characterCountLabel setFrame:CGRectMake(250, 3, 50, 40)];
    _messageTextView.inputAccessoryView = keyboardToolbar;
}

- (IBAction)cameraButtonClicked:(id)sender {
    if(_attachedImageView.image)
    {
        // if already has photo then show the photo and see if they want to remove
    }
    else
    {
        _photoPicker = [[UIImagePickerController alloc] init];
        _photoPicker.delegate = self;
        _photoPicker.allowsEditing = NO;

        // if not, then ask if they want to choose existing photo or take a new photo
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Take photo", @"Choose Existing", nil];
        actionSheet.tag = 7431;
        [actionSheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // action sheet for camera button press
    if(actionSheet.tag == 7431)
    {
        if (buttonIndex == 0) {
            // new photo
            _photoPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:_photoPicker animated:YES completion:NULL];
            [_messageTextView resignFirstResponder];
        } else if (buttonIndex == 1) {
            // existing photo
            _photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:_photoPicker animated:YES completion:NULL];
            [_messageTextView resignFirstResponder];
        }
    }
}

#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    // save image to camera roll!
    UIImage* originalImage=info[UIImagePickerControllerOriginalImage];
    UIImageWriteToSavedPhotosAlbum(originalImage, nil, nil, nil);
    
    [self attachImage:originalImage];    
}

-(void)attachImage:(UIImage*)image
{
    _attachedImageView.image = image;
    _attachedImageView.layer.borderColor = [UIColor blackColor].CGColor;
    _attachedImageView.layer.borderWidth = .1f;
    _cameraButton.tintColor = [UIColor redColor];
    
    // fade in picture
    _attachedImageView.alpha = 0;
    [UIView animateWithDuration:1.0f delay:1.5f options:UIViewAnimationOptionCurveLinear animations:^{
        _attachedImageView.alpha = 1.0f;
    } completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)locationButtonClicked:(id)sender {
    
    
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


- (BOOL)textViewShouldEndEditing:(UITextView *)aTextView {
    [aTextView resignFirstResponder];
    return YES;
}

- (void)textViewDidChange:(UITextView *)txtView
{
    _placeholderTextField.hidden = ([txtView.text length] > 0);
    [self updateCharacterCountString];
}

- (void)textViewDidEndEditing:(UITextView *)txtView
{
    _placeholderTextField.hidden = ([txtView.text length] > 0);
    [self updateCharacterCountString];
}

-(void)updateCharacterCountString
{
    NSString* text = [self getTruncatedText];
    
    _characterCountLabel.text = [NSString stringWithFormat:@"%d", characterLimit - text.length];
    
    if(text.length > characterLimit || text.length < 1)
    {
        // only color red if over max char limit
        if(text.length > characterLimit)
            _characterCountLabel.textColor = [UIColor redColor];
        else
            _characterCountLabel.textColor = [UIColor blackColor];
        
        _postButton.enabled = NO;
    }
    else
    {
        _postButton.enabled = YES;
        _characterCountLabel.textColor = [UIColor blackColor];
    }
}

-(NSString*)getTruncatedText
{
    NSString* text = _messageTextView.text;
    while([text characterAtIndex:text.length - 1] == ' ')
    {
        text = [text substringToIndex:text.length - 1];
    }
    return  text;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)cancelButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)postButtonPressed:(id)sender {
    // show spinner
    _spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 40,self.view.frame.size.height / 2 - 125,80,80)];

    //spinner.color = [UIColor darkGrayColor];
    _spinner.backgroundColor = [UIColor darkGrayColor];
    _spinner.layer.cornerRadius = 5;
    _spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [_spinner startAnimating];
    [self.view addSubview:_spinner];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // lots of code run in the background
        
        // Create Photo if there is a photo
        PFObject *photo = nil;
        if(_attachedImageView.image)
        {
            // FIX THIS
            UIImage *resizedImage = [_attachedImageView.image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
            UIImage *thumbnailImage = [_attachedImageView.image thumbnailImage:86.0f transparentBorder:0.0f cornerRadius:10.0f interpolationQuality:kCGInterpolationDefault];
            
            // JPEG to decrease file size and enable faster uploads & downloads
            NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
            NSData *thumbnailImageData = UIImagePNGRepresentation(thumbnailImage);
            
            self.photoFile = [PFFile fileWithData:imageData];
            self.thumbnailFile = [PFFile fileWithData:thumbnailImageData];
            
            if (!self.photoFile || !self.thumbnailFile) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
                return;
            }
            
            // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
            self.fileUploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
            }];
            
            [self.photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [self.thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
                    }];
                } else {
                    [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
                }
            }];
        
            
            // create a photo object
            photo = [PFObject objectWithClassName:kPhotoClassKey];
            
            NSLog(@"photo with object id created: %@", photo.objectId);
            [photo setObject:[PFUser currentUser] forKey:kPhotoUserKey];
            [photo setObject:self.photoFile forKey:kPhotoPictureKey];
            [photo setObject:self.thumbnailFile forKey:kPhotoThumbnailKey];
            
            // photos are public, but may only be modified by the user who uploaded them
            PFACL *photoACL = [PFACL ACLWithUser:[PFUser currentUser]];
            [photoACL setPublicReadAccess:YES];
            photo.ACL = photoACL;
            
            // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
            self.photoPostBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
            }];
            
            // Save the Photo PFObject
            [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [[Cache sharedCache] setAttributesForPhoto:photo likers:[NSArray array] commenters:[NSArray array] likedByCurrentUser:NO];
                    
                    NSLog(@"photo with object id saved: %@", photo.objectId);
                    
                    [self createPostWithPhoto:photo];
//                    // userInfo might contain any caption which might have been posted by the uploader
//                    if (userInfo) {
//                        NSString *commentText = [userInfo objectForKey:kEditPhotoViewControllerUserInfoCommentKey];
//                        
//                        if (commentText && commentText.length != 0) {
//                            // create and save photo caption
//                            PFObject *comment = [PFObject objectWithClassName:kActivityClassKey];
//                            [comment setObject:kActivityTypeComment forKey:kActivityTypeKey];
//                            [comment setObject:photo forKey:kActivityPhotoKey];
//                            [comment setObject:[PFUser currentUser] forKey:kActivityFromUserKey];
//                            [comment setObject:[PFUser currentUser] forKey:kActivityToUserKey];
//                            [comment setObject:commentText forKey:kActivityContentKey];
//                            
//                            PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
//                            [ACL setPublicReadAccess:YES];
//                            comment.ACL = ACL;
//                            
//                            [comment saveEventually];
//                            [[Cache sharedCache] incrementCommentCountForPhoto:photo];
//                        }
//                    }
                    
                    //[[NSNotificationCenter defaultCenter] postNotificationName:PAPTabBarControllerDidFinishEditingPhotoNotification object:photo];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                    [alert show];
                }
                [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
            }];
        }
        else{
            // Create Post without image
            [self createPostWithPhoto:nil];
        }
    });
}

-(void)createPostWithPhoto:(PFObject*)photo
{
    PFObject *post = [PFObject objectWithClassName:@"Post"];
    [post setObject:[self getTruncatedText] forKey:@"message"];
    PFUser *user = [PFUser currentUser];
    [post setObject:user forKey:@"user"];
    
    if(photo)
    {
        NSLog(@"saving photo with object id to post: %@", photo.objectId);
        [post setObject:photo forKey:@"photo"];
    }
    [post save];
    
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // stop and remove the spinner on the background when done
            [_spinner removeFromSuperview];
            
            // dismiss view
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }];

}


@end
