//
//  Image.h
//  triangleFilterApp
//
//  Created by Matěj Kašpar Jirásek on 16.10.12.
//  Copyright (c) 2012 Matěj Kašpar Jirásek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Triangles)

- (NSDictionary *)triangleImageWithWidth:(float)width ratio:(NSUInteger)ratio;
- (NSDictionary *)squareImageWithWidth:(float)width ratio:(NSUInteger)ratio;
- (NSDictionary *)hexagonImageWithWidth:(float)width ratio:(NSUInteger)ratio;

@end
