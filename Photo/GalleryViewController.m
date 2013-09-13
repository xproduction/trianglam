//
//  GalleryViewController.m
//  Photo
//
//  Created by Matěj Kašpar Jirásek on 28.11.12.
//  Copyright (c) 2012 X Production s.r.o. All rights reserved.
//

#import "GalleryViewController.h"
#import "AppDelegate.h"
#import "Gallery.h"
#import "GalleryCollectionCell.h"
#import "ImageViewController.h"
#import "UIViewController+TopAndBottomBlur.h"

#import "Flurry.h"

#define IMAGE_SIZE 104.0
#define IMAGE_PADDING 4.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 44.0

#define BUTTON_PADDING 0.0

@interface GalleryViewController (TopAndBottomBlur)

@end

@implementation GalleryViewController

- (id)init
{
    self = [super init];
    if(self)
    {
        self.wantsFullScreenLayout = YES;

        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(IMAGE_SIZE, IMAGE_SIZE);
        layout.minimumInteritemSpacing = IMAGE_PADDING;
        layout.minimumLineSpacing = IMAGE_PADDING;
        layout.sectionInset = UIEdgeInsetsMake(IMAGE_PADDING + self.view.center.y - self.view.center.x, 0.0, IMAGE_PADDING + self.view.center.y - self.view.center.x, 0.0);
        collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
        [collectionView registerClass:[GalleryCollectionCell class] forCellWithReuseIdentifier:@"imagecell"];
        collectionView.scrollsToTop = YES;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [self.view addSubview:collectionView];
        
        // ui sweetness
        [self addTopAndBottomBlur];
        
        float buttonSize = self.view.center.y - self.view.center.x - 2.0 * BUTTON_PADDING;
        UIButton *shootButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, self.view.center.y + self.view.center.x + BUTTON_PADDING, 60.0 + BUTTON_PADDING, buttonSize)];
        [shootButton setImage:[UIImage imageNamed:@"CameraIcon.png"] forState:UIControlStateNormal];
        [shootButton setImage:[UIImage imageNamed:@"CameraIconTouched.png"] forState:UIControlStateHighlighted];
        [shootButton addTarget:self action:@selector(goToCamera:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:shootButton];
        
        [Gallery checkImagesIntegrity];
    }
    return self;
}

- (IBAction)goToCamera:(id)sender
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate transitionToCamera];
}

- (void)viewWillAppear:(BOOL)animated
{
    [collectionView reloadData];
    if([[Gallery getImageArray] count] > 0)
        [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UIScrollViewIndicatorStyleDefault animated:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - CollectionViewDataSource delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[Gallery getImageArray] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collection cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GalleryCollectionCell *cell = [collection dequeueReusableCellWithReuseIdentifier:@"imagecell" forIndexPath:indexPath];
    cell.imageView.image = [Gallery getThumbAtIndex:[[Gallery getImageArray] count] - indexPath.row - 1];
    return cell;
}

#pragma mar - CollectionViewDElegate

- (void)collectionView:(UICollectionView *)collection didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self viewPhotoAtIndex:indexPath.row];
}

#pragma mark - Options

- (void)viewPhotoAtIndex:(NSUInteger)index
{
    [Flurry logEvent:@"Viewed detail of a photo"];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    ImageViewController *controller = [[ImageViewController alloc] initWithImageAtIndex:[[Gallery getImageArray] count] - index - 1];
    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:controller animated:YES completion:nil];
}

@end
