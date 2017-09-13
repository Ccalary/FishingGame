//
//  FishHookView.m
//  HHFramework
//
//  Created by chh on 2017/9/8.
//  Copyright © 2017年 chh. All rights reserved.
//  鱼杆的View

#import "FishHookView.h"
#import "GlobalDefine.h"

@interface FishHookView()
@property (nonatomic, strong) CADisplayLink *linkTimer;
@property (nonatomic, assign) BOOL isReduce;//改变方向
@property (nonatomic, assign) CGFloat angle;//摆动的角度
@end

@implementation FishHookView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]){
        
        [self initView];
    }
    return self;
}

- (void)initView{
    
    [self setAnchorPoint:CGPointMake(0.5, 0) forView:self];
    
    UIImageView *gouImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 35 , 30, 35)];
    gouImageView.image = [UIImage imageNamed:@"fish_catcher_tong"];
    [self addSubview:gouImageView];

    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake((self.frame.size.width - 3)/2.0, 0, 3, self.frame.size.height - 35)];
    lineView.backgroundColor = HEXCOLOR(0x9e664a);
    
    [self addSubview:lineView];
    
    //  创建一个对象计时器
    _linkTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(hookMove)];
    //启动这个link
    [_linkTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

//设置锚点后重新设置frame
- (void) setAnchorPoint:(CGPoint)anchorpoint forView:(UIView *)view{
    CGRect oldFrame = view.frame;
    view.layer.anchorPoint = anchorpoint;
    view.frame = oldFrame;
}

#pragma mark - 鱼钩摆动
- (void)hookMove{
    
    if (self.isReduce){
        _angle-=1.8*cos(1.5*_angle)*0.01;//计算角度,利用cos模拟上升过程中减慢，下降加快
        if (_angle < -M_PI/180*45){
            self.isReduce = NO;
        }
    }else {
        _angle+=1.8*cos(1.5*_angle)*0.01;
        if (_angle > M_PI/180*45){
            self.isReduce = YES;
        }
    }
    if (self.angleBlock){
        self.angleBlock(_angle);
    }
//    DLog(@"鱼钩角度%f",_angle);
    self.transform = CGAffineTransformMakeRotation(_angle);
}

//计时器暂停
- (void)hookTimerPause{
    self.linkTimer.paused = YES;
}

//计时器继续
- (void)hoolTimerGoOn{
    self.linkTimer.paused = NO;
}

//计时器释放
- (void)hoolTimerInvalidate{
    [self.linkTimer invalidate];
}
@end
