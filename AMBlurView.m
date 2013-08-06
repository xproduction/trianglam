//
//  AMBlurView.m
//  blur
//
//  Created by Cesar Pinto Castillo on 7/1/13.
//  Copyright (c) 2013 Arctic Minds Inc. All rights reserved.
//

#import "AMBlurView.h"
#import <QuartzCore/QuartzCore.h>

@interface AMBlurView ()

@property (nonatomic, strong) UIToolbar *toolBar;
@property (nonatomic, strong) CALayer *blurLayer;

@end

@implementation AMBlurView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [self setToolBar:[[UIToolbar alloc] initWithFrame:[self bounds]]];
        [self setBlurLayer:[[self toolBar] layer]];
        UIView *blurView = [UIView new];
        [blurView setUserInteractionEnabled:NO];
        [blurView.layer addSublayer:[self blurLayer]];
        [blurView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [blurView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self addSubview:blurView];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[blurView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(blurView)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-1)-[blurView]-(-1)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(blurView)]];
        [self setBackgroundColor:[UIColor clearColor]];
    } else {
        self.alpha = 0.9;
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    }
}

- (void) setBlurTintColor:(UIColor *)blurTintColor {
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [self.toolBar setBarTintColor:blurTintColor];
    } else {
        self.backgroundColor = blurTintColor;
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self.blurLayer setFrame:[self bounds]];
}

@end
