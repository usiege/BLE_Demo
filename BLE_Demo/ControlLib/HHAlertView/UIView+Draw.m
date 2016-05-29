//
//  UIView+Draw.m
//  HHAlertView
//
//  Created by ChenHao on 6/17/15.
//  Copyright (c) 2015 AEXAIR. All rights reserved.
//

#import "UIView+Draw.h"

@implementation UIView (Draw)

- (void)hh_drawCheckmark
{
    [self cleanLayer:self];
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(KLogoView_Size/2, KLogoView_Size/2) radius:KLogoView_Size/2 startAngle:0 endAngle:M_PI*2 clockwise:YES];
    
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineCapRound;
    
    [path moveToPoint:CGPointMake(KLogoView_Size/4, KLogoView_Size/2)];
    CGPoint p1 = CGPointMake(KLogoView_Size/4+10, KLogoView_Size/2+10);
    [path addLineToPoint:p1];
    
    CGPoint p2 = CGPointMake(KLogoView_Size/4*3, KLogoView_Size/4);
    [path addLineToPoint:p2];
    
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.fillColor = [UIColor clearColor].CGColor;
    
    layer.strokeColor = SUCCESS_COLOR.CGColor;
    layer.lineWidth = 5;
    layer.path = path.CGPath;
    [self.layer addSublayer:layer];
    
}

- (void)hh_drawCheckWarning
{
    [self cleanLayer:self];
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(KLogoView_Size/2, KLogoView_Size/2) radius:KLogoView_Size/2 startAngle:0 endAngle:M_PI*2 clockwise:YES];
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineCapRound;
    
    [path moveToPoint:CGPointMake(KLogoView_Size/2, KLogoView_Size/6)];
    CGPoint p1 = CGPointMake(KLogoView_Size/2, KLogoView_Size/6*3.8);
    [path addLineToPoint:p1];
    
    [path moveToPoint:CGPointMake(KLogoView_Size/2, KLogoView_Size/6*4.5)];
    [path addArcWithCenter:CGPointMake(KLogoView_Size/2, KLogoView_Size/6*4.5) radius:2 startAngle:0 endAngle:M_PI*2 clockwise:YES];
    
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = WARNING_COLOR.CGColor;
    layer.lineWidth = 5;
    layer.path = path.CGPath;
    
    [self.layer addSublayer:layer];
    
}

- (void)hh_drawCheckError
{
    [self cleanLayer:self];
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(KLogoView_Size/2, KLogoView_Size/2) radius:KLogoView_Size/2 startAngle:0 endAngle:M_PI*2 clockwise:YES];
    
    CGPoint p1 =  CGPointMake(KLogoView_Size/4, KLogoView_Size/4);
    [path moveToPoint:p1];
    
    CGPoint p2 =  CGPointMake(KLogoView_Size/4*3, KLogoView_Size/4*3);
    [path addLineToPoint:p2];
    
    CGPoint p3 =  CGPointMake(KLogoView_Size/4*3, KLogoView_Size/4);
    [path moveToPoint:p3];
    
    CGPoint p4 =  CGPointMake(KLogoView_Size/4, KLogoView_Size/4*3);
    [path addLineToPoint:p4];
    
    
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.lineWidth = 5;
    layer.path = path.CGPath;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = ERROR_COLOR.CGColor;
    
    [self.layer addSublayer:layer];
}

- (void)hh_drawCustomeView:(UIView *)customView
{
    [self cleanLayer:self];
    customView.frame = self.frame;
    [self addSubview:customView];
}

- (void)cleanLayer:(UIView *)view
{
    for (CALayer *layer in view.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
}
@end
