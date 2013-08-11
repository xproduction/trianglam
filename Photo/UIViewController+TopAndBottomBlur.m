//
//  UIViewController+TopAndBottomBlur.m
//  Trianglam
//
//  Created by Matěj Kašpar Jirásek on 07.08.13.
//  Copyright (c) 2013 X Production s.r.o. All rights reserved.
//

#import "UIViewController+TopAndBottomBlur.h"

#import "AMBlurView.h"

@implementation UIViewController (TopAndBottomBlur)

-(void)addTopAndBottomBlur
{
    CGRect topBlurFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.center.y - self.view.frame.size.width / 2.0);
    CGRect bottomBlurFrame = CGRectMake(0.0, self.view.center.y + self.view.frame.size.width / 2.0, self.view.frame.size.width, self.view.center.y - self.view.frame.size.width / 2.0);
    UIColor *blurTintColor = [UIColor colorWithWhite:0.2 alpha:0.6];
    
    AMBlurView *topBlurView = [[AMBlurView alloc] initWithFrame:topBlurFrame];
    topBlurView.tag = 2;
    topBlurView.blurTintColor = blurTintColor;
    
    UIImageView *trianglam = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Trianglam.png"]];
    [topBlurView addSubview:trianglam];
    float trianglamSize = 30.0;
    trianglam.frame = CGRectMake(topBlurView.center.x - trianglamSize / 2.0, 20.0 + (topBlurView.frame.size.height - 20.0) / 2.0 - trianglamSize / 2.0, trianglamSize, trianglamSize);
    
    [self.view addSubview:topBlurView];
    
    AMBlurView *bottomBlurView = [[AMBlurView alloc] initWithFrame:bottomBlurFrame];
    bottomBlurView.tag = 3;
    bottomBlurView.blurTintColor = blurTintColor;
    
    [self.view addSubview:bottomBlurView];
}

-(void)setBlurAlpha:(CGFloat)alpha
{
    UIView* top = [self.view viewWithTag:2];
    UIView* bottom = [self.view viewWithTag:3];
    
    top.alpha = alpha;
    bottom.alpha = alpha;
}

@end
