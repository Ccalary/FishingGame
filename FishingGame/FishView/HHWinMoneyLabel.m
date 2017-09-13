//
//  HHWinMoneyLabel.m
//  HHFramework
//
//  Created by chh on 2017/9/12.
//  Copyright © 2017年 chh. All rights reserved.
//

#import "HHWinMoneyLabel.h"

@interface HHWinMoneyLabel()<CAAnimationDelegate>

@end
@implementation HHWinMoneyLabel

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]){
        self.font = [UIFont boldSystemFontOfSize:25];
        self.textAlignment = NSTextAlignmentCenter;
        self.textColor = [UIColor blueColor];
        [self startAnimation];
    }
    return self;
}

- (void)startAnimation{
    //位移动画
    CAKeyframeAnimation *ani = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    //移动路径
    NSValue *p1 = [NSValue valueWithCGPoint:self.center];
    NSValue *p2 = [NSValue valueWithCGPoint:CGPointMake(self.center.x, self.center.y - 100)];
    ani.duration = 1;
    ani.values = @[p1,p2];
    ani.keyTimes = @[@0,@1];//动画分段时间
    
    CABasicAnimation *opacityAni = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAni.duration = 1;
    opacityAni.fromValue = [NSNumber numberWithFloat:1.0];
    opacityAni.toValue = [NSNumber numberWithFloat:0.3];
    
    CAAnimationGroup *groupAni = [CAAnimationGroup animation];
    groupAni.animations = @[ani,opacityAni];
    groupAni.duration = 1;
    groupAni.delegate = self;
    groupAni.removedOnCompletion = NO;
    groupAni.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:groupAni forKey:@"groupAni"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    [self removeFromSuperview];
}
@end
