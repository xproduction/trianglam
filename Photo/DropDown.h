//
//  DropDown.h
//  Trianglam
//
//  Created by Matěj Kašpar Jirásek on 11.01.13.
//  Copyright (c) 2013 X Production s.r.o. All rights reserved.
//

#define DROPDOWN_DEFAULT_PADDING 0.0
#define DROPDOWN_DEFAULT_ANIMATION_TIME 0.15

#import <UIKit/UIKit.h>

@protocol DropDownDelegate <NSObject>

-(void)dropDownShut:(id)dropDown;
-(void)dropDownOpened:(id)dropDown;

@end

@interface DropDown : UIControl
{
    NSArray *buttons;
    NSUInteger selectedButtonIndex;
    BOOL isOpen;
    CGSize size;
    CGFloat padding;
    double animationTime;
}

@property (weak) id<DropDownDelegate> delegate;
@property (nonatomic, strong) NSArray *buttons;
@property (atomic) NSUInteger selectedButtonIndex;
@property (atomic) CGFloat padding;
@property (atomic) double animationTime;

- (void)shut;
- (void)open;

@end
