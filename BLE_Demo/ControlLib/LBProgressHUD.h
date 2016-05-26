//
//  LBProgressHUD.h
//  LuckyBuy
//
//  Created by huangtie on 16/3/9.
//  Copyright © 2016年 Qihoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LBProgressHUD : UIView

@property (nonatomic , copy) NSString *tipText;

@property (nonatomic , strong) UIColor *toastColor;

@property (nonatomic , strong) UIColor *contentColor;

@property (nonatomic , assign) BOOL showMask;

- (void)show:(BOOL)animated;

- (void)hide:(BOOL)animated;


+ (instancetype)showHUDto:(UIView *)view animated:(BOOL)animated;

+ (NSUInteger)hideAllHUDsForView:(UIView *)view animated:(BOOL)animated;

@end
// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com