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

#define IMAGE_SIZE 93.0
#define IMAGE_PADDING 10.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 44.0

@interface GalleryViewController ()

@end

@implementation GalleryViewController

- (id)init
{
    self = [super init];
    if(self)
    {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(IMAGE_SIZE, IMAGE_SIZE);
        layout.minimumInteritemSpacing = IMAGE_PADDING;
        layout.minimumLineSpacing = IMAGE_PADDING;
        layout.sectionInset = UIEdgeInsetsMake(IMAGE_PADDING, IMAGE_PADDING, IMAGE_PADDING, IMAGE_PADDING);
        CGRect collectionFrame = CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT - STATUS_BAR_HEIGHT);
        collectionView = [[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:layout];
        [collectionView registerClass:[GalleryCollectionCell class] forCellWithReuseIdentifier:@"imagecell"];
        collectionView.scrollsToTop = YES;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [self.view addSubview:collectionView];
        
        UIButton *shootButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT - STATUS_BAR_HEIGHT, BOTTOM_BAR_HEIGHT, BOTTOM_BAR_HEIGHT)];
        [shootButton setImage:[UIImage imageNamed:@"trianglam_camera.png"] forState:UIControlStateNormal];
        [shootButton addTarget:self action:@selector(goToCamera:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:shootButton];
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
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    ImageViewController *controller = [[ImageViewController alloc] initWithImageAtIndex:[[Gallery getImageArray] count] - index - 1];
    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:controller animated:YES completion:nil];
}

@end
