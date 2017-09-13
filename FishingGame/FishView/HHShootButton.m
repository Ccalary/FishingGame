//
//  HHShootButton.m
//  demo
//
//  Created by chh on 2017/9/5.
//  Copyright © 2017年 chh. All rights reserved.
//

#import "HHShootButton.h"
@interface HHShootButton()<CAAnimationDelegate>
@property (nonatomic, strong) NSMutableArray *coinTagArray;
@property (nonatomic, assign) CGPoint point;
@end

@implementation HHShootButton

- (instancetype)initWithFrame:(CGRect)frame andEndPoint:(CGPoint)point{
    if (self = [super initWithFrame:frame]){
        _coinTagArray = [[NSMutableArray alloc] init];
        self.setting = [ShootButtonSetting defaultSetting];
        //目的地的位置
        self.point = CGPointMake(point.x - frame.origin.x, point.y - frame.origin.y);
        [self addTarget:self action:@selector(startAnimation) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)startAnimation{
    for(int i = 0; i < self.setting.totalCount; i ++){
        //延时 注意时间要乘i 这样才会生成一串，要不然就是拥挤在一起的
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i*self.setting.timeSpace * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self initCoinViewWithInt:i];
        });
    }
}

- (void)initCoinViewWithInt:(int)i{
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.setting.iconImage ?: self.imageView.image];
    //设置中心位置
    imageView.center = CGPointMake(self.frame.size.width/2.0, self.frame.size.height/2.0);
    //初始化金币的位置
    imageView.tag = i + 1000; //设置tag时尽量设置大点的数值
    //将tag添加到数组，用于判断移除
    [self.coinTagArray addObject:[NSNumber numberWithInt:(int)imageView.tag]];
    [self addSubview:imageView];
    [self setAnimationWithLayer:imageView];
}

- (void)setAnimationWithLayer:(UIView *)imageView{
    
    UIBezierPath *movePath = [UIBezierPath bezierPath];
    [movePath moveToPoint:CGPointMake(self.frame.size.width/2.0, self.frame.size.height/2.0)];
    
    switch (self.setting.animationType) {
        case ShootButtonAnimationTypeLine://直线
            [movePath addLineToPoint:self.point];
            break;
        case ShootButtonAnimationTypeCurve://曲线
            //抛物线
            [movePath addQuadCurveToPoint:self.point controlPoint:CGPointMake(self.point.x, self.center.y)];
            break;
        default:
            break;
    }
    
    //位移动画
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    //移动路径
    animation.path = movePath.CGPath;
    animation.duration = self.setting.duration;
    animation.autoreverses = NO;
    animation.repeatCount = 1;
    animation.calculationMode = kCAAnimationPaced;
    animation.delegate = self;
    animation.removedOnCompletion = NO;
    animation.fillMode=kCAFillModeForwards;
    [imageView.layer addAnimation:animation forKey:@"position"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if (flag){//动画执行结束移除view
        NSLog(@"动画结束");
        UIView *coinView =(UIView *)[self viewWithTag:[[self.coinTagArray firstObject] intValue]];
        [coinView removeFromSuperview];
        [self.coinTagArray removeObjectAtIndex:0];
    }
}

@end

#pragma mark - Setting Methods
@implementation ShootButtonSetting

+ (ShootButtonSetting *)defaultSetting{
    ShootButtonSetting *defaultSetting = [[ShootButtonSetting alloc] init];
    defaultSetting.totalCount = 10;
    defaultSetting.timeSpace = 0.1;
    defaultSetting.duration = 1;
    defaultSetting.animationType = ShootButtonAnimationTypeCurve;
    return defaultSetting;
}
@end
