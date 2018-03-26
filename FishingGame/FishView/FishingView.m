//
//  FishingView.m
//  HHFramework
//
//  Created by chh on 2017/9/13.
//  Copyright © 2017年 chh. All rights reserved.
//

#import "FishingView.h"
#import "FishHookView.h"
#import "FishModelImageView.h"
#import "UIView+Extension.h"
#import "HHShootButton.h"
#import "HHWinMoneyLabel.h"
#import "GlobalDefine.h"
typedef NS_OPTIONS(NSUInteger, FishHookState) {//鱼钩的状态
    FishHookStateShake       = 0,  //摇晃
    FishHookStateDown        = 1,  //下钩
    FishHookStateStop        = 2,  //垂钓
    FishHookStateUp          = 3,  //升钩
};

NSString *const kLineDownAnimationKey = @"LineDownAnimationKey"; //下钩
NSString *const kLineDownAnimationValue = @"LineDownAnimationValue";

NSString *const kLineUpAnimationKey = @"LineUpAnimationKey";//上钩
NSString *const kLineUpAnimationValue = @"LineUpAnimationValue";

#define FishSeaHeight  215.0f                                //鱼塘的高度
#define FishLineHeigth (ScreenFullHeight - FishSeaHeight - 40.0f) //鱼线的高度
#define FishHookHeight 85.0f    //鱼钩的长度

@interface FishingView()<CAAnimationDelegate,FishModelImageViewDelegate>
@property (nonatomic, strong) FishHookView *fishHookView; //鱼钩
@property (nonatomic, assign) CGFloat angle; //鱼钩摆动角度
@property (nonatomic, assign) CGFloat lineOffsetX, hookBottomX, hookBottomY; //鱼线的x坐标，鱼钩底部x,y
@property (nonatomic, strong) UIImageView *bgImageView;//鱼塘背景
@property (nonatomic, strong) NSTimer *fishTimer;

@property (nonatomic, assign) int stopDuration; //鱼钩停留时间
@property (nonatomic, assign) BOOL isCatched;//是否钓到了鱼
@property (nonatomic, assign) FishHookState fishHookState; //鱼钩的状态

@property (nonatomic, strong) CAKeyframeAnimation *hookAnimation;//钩的动画
@property (nonatomic, strong) CAShapeLayer *linePathLayer;//画鱼线

@property (nonatomic, assign) CGFloat catchedHeight; //上钩鱼的y坐标
@property (nonatomic, strong) UILabel *moneyLabel; //金币数量
@property (nonatomic, assign) int totalMoney; //总钱数
@property (nonatomic, assign) int winMoney; //赢得钱数
@end

@implementation FishingView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]){
    
        [self initView];
    }
    return self;
}

- (void)initView{
    
    [self initBgImageView];
    
    [self initHookView];
    
    [self initFishView];
}

- (void)removeFishViewResource{
    //解决鱼钩上钩动画循环引用的问题
    _linePathLayer = nil;
    //钓鱼计时器关闭
    [_fishTimer invalidate];
    _fishTimer = nil;
    //释放鱼钩的计时器
    [self.fishHookView hoolTimerInvalidate];
    //发送通知释放小雨资源
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationRemoveFishModelTimer object:nil];
}

-(void)dealloc{
    DLog(@"钓鱼界面释放了");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 鱼钩
- (void)initHookView{
    
    _fishHookView = [[FishHookView alloc] initWithFrame:CGRectMake((ScreenWidth - 30)/2.0, 5, 30, 85)];
    __weak typeof (self) weakSelf = self;
    _fishHookView.angleBlock = ^(CGFloat angle) {
        weakSelf.angle = angle;
    };
    [self addSubview:_fishHookView];
    
    UIImageView *yuGanImageView = [[UIImageView alloc] initWithFrame:CGRectMake(ScreenWidth/2.0 - 2, 0, ScreenWidth/2.0, 50)];
    yuGanImageView.image = [UIImage imageNamed:@"fish_gan_tong"];
    [self addSubview:yuGanImageView];
}

#pragma mark - 鱼塘
- (void)initBgImageView{
    _bgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, ScreenFullHeight - FishSeaHeight, ScreenWidth, FishSeaHeight)];
    _bgImageView.image = [UIImage imageNamed:@"fish_bg2"];
    _bgImageView.clipsToBounds = YES;
    _bgImageView.userInteractionEnabled = YES;
    [self addSubview:_bgImageView];
    
    UIImageView *coinImageView = [[UIImageView alloc] initWithFrame:CGRectMake(3, FishSeaHeight - 23 , 22, 20)];
    coinImageView.image = [UIImage imageNamed:@"coin"];
    [_bgImageView addSubview:coinImageView];
    
    _moneyLabel = [[UILabel alloc] initWithFrame:CGRectMake(27, CGRectGetMinY(coinImageView.frame), 100, 20)];
    _moneyLabel.font = [UIFont systemFontOfSize:15];
    _moneyLabel.textColor = [UIColor whiteColor];
    _moneyLabel.text = @"0";
    [_bgImageView addSubview:_moneyLabel];
    
    UITapGestureRecognizer *aTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fishBtnAction)];
    [_bgImageView addGestureRecognizer:aTap];
    
    _fishTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(hookStop:) userInfo:nil repeats:YES];
    //关闭计时器
    [_fishTimer setFireDate:[NSDate distantFuture]];
    
    //初始化鱼钩状态
    _fishHookState = FishHookStateShake;
}

#pragma mark - 初始化鱼类
- (void)initFishView{
    
    //小黄鱼
    for (int i = 0; i < 8; i++){
        FishModelImageView *model1 = [[FishModelImageView alloc] initCanCatchFishWithType:FishModelImageViewTypeXHY andDirection: (i%2 == 0) ? FishModelImageViewFromRight : FishModelImageViewFromLeft];
        model1.delegate = self;
        [self.bgImageView addSubview:model1];
    }
   
    //石斑鱼
    for (int i = 0; i < 2; i++){
        FishModelImageView *model1 = [[FishModelImageView alloc] initCanCatchFishWithType:FishModelImageViewTypeSBY andDirection: (i%2 == 0) ? FishModelImageViewFromRight : FishModelImageViewFromLeft];
        model1.delegate = self;
        [self.bgImageView addSubview:model1];
    }
    //红杉鱼
    for (int i = 0; i < 2; i++){
        FishModelImageView *model1 = [[FishModelImageView alloc] initCanCatchFishWithType:FishModelImageViewTypeHSY andDirection: (i%2 == 0) ? FishModelImageViewFromRight : FishModelImageViewFromLeft];
        model1.delegate = self;
        [self.bgImageView addSubview:model1];
    }
    //斑纹鱼
    for (int i = 0; i < 2; i++){
        FishModelImageView *model1 = [[FishModelImageView alloc] initCanCatchFishWithType:FishModelImageViewTypeBWY andDirection: (i%2 == 0) ? FishModelImageViewFromRight : FishModelImageViewFromLeft];
        model1.delegate = self;
        [self.bgImageView addSubview:model1];
    }
    //珊瑚鱼
    for (int i = 0; i < 2; i++){
        FishModelImageView *model1 = [[FishModelImageView alloc] initCanCatchFishWithType:FishModelImageViewTypeSHY andDirection: (i%2 == 0) ? FishModelImageViewFromRight : FishModelImageViewFromLeft];
        model1.delegate = self;
        [self.bgImageView addSubview:model1];
    }
    //鲨鱼
    for (int i = 0; i < 2; i++){
        FishModelImageView *model1 = [[FishModelImageView alloc] initCanCatchFishWithType:FishModelImageViewTypeSY andDirection: (i%2 == 0) ? FishModelImageViewFromRight : FishModelImageViewFromLeft];
        model1.delegate = self;
        [self.bgImageView addSubview:model1];
    }
}

#pragma mark - Action
//钓鱼动作
- (void)fishBtnAction{
    
    if (self.fishHookState != FishHookStateShake) return; //不是摇摆状态不可出杆
    
    [self.fishHookView hookTimerPause];//暂停鱼钩的计时器
    
    double degree = _angle*180/M_PI;//度数
    double rate = tan(_angle);//比列
    DLog(@"degree:%f---rate:%f",degree,rate);
    //计算出来线终点x的位置 , 钩到水里的深度不变，即y是固定的
    _lineOffsetX = ScreenWidth/2.0 - (FishLineHeigth)*rate;
    
    //钩子底部xy值
    _hookBottomX = ScreenWidth/2.0 - (FishLineHeigth + FishHookHeight)*rate;
    _hookBottomY = FishLineHeigth + FishHookHeight;
    
    //动画时间
    double aniDuration = [self hookOutOfRiver] ? 0.5 : 1;
    
    //绘制路径
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(ScreenWidth/2.0 ,5)];
    [path addLineToPoint:CGPointMake(_lineOffsetX, FishLineHeigth)];
    
    //图形设置
    _linePathLayer = [CAShapeLayer layer];
    _linePathLayer.frame = self.bounds;
    _linePathLayer.path = path.CGPath;
    _linePathLayer.strokeColor = [HEXCOLOR(0x9e664a) CGColor];
    _linePathLayer.fillColor = nil;
    _linePathLayer.lineWidth = 3.0f;
    _linePathLayer.lineJoin = kCALineJoinBevel;
    [self.layer addSublayer:_linePathLayer];
    
    //下钩动画
    CAKeyframeAnimation *ani = [CAKeyframeAnimation animationWithKeyPath:@"strokeEnd"];
    ani.duration = aniDuration;
    ani.values = @[@0,@0.8,@1];
    ani.keyTimes = @[@0,@0.6,@1];
    ani.delegate = self;
    [ani setValue:kLineDownAnimationValue forKey:kLineDownAnimationKey];
    [_linePathLayer addAnimation:ani forKey:kLineDownAnimationKey];
    
    //位移动画
    _hookAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    //移动路径
    CGFloat tempOffsetX =  ScreenWidth/2.0 - (FishLineHeigth*0.8)*rate;
    NSValue *p1 = [NSValue valueWithCGPoint:CGPointMake(ScreenWidth/2.0 ,5)];
    NSValue *p2 = [NSValue valueWithCGPoint:CGPointMake(tempOffsetX, FishLineHeigth*0.8)];
    NSValue *p3 = [NSValue valueWithCGPoint:CGPointMake(_lineOffsetX, FishLineHeigth)];
    _hookAnimation.duration = aniDuration;
    _hookAnimation.values = @[p1,p2,p3];
    _hookAnimation.keyTimes = @[@0,@0.7,@1];//动画分段时间
    //设置这两句动画结束会停止在结束位置
    _hookAnimation.removedOnCompletion = NO;
    _hookAnimation.fillMode=kCAFillModeForwards;
    [_fishHookView.layer addAnimation:_hookAnimation forKey:@"goukey"];
    
}

//钩子停在底部
- (void)hookStop:(NSTimer *)timer{
    _stopDuration-=1;
    
    //最后一秒不可上钩
    if (_stopDuration == 1){
        //发送不可垂钓的通知
        self.fishHookState = FishHookStateUp;
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationFishHookMove object:nil];
    }
    if (_stopDuration <= 0){
        //关闭计时器
        [timer setFireDate:[NSDate distantFuture]];
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(_lineOffsetX, FishLineHeigth)];
        [path addLineToPoint:CGPointMake(ScreenWidth/2.0 ,5)];
        _linePathLayer.path = path.CGPath;
        
        //动画时间
        double aniDuration = [self hookOutOfRiver] ? 0.5 : 1;
        
        //上钩
        CABasicAnimation *ani = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        ani.duration = aniDuration;
        ani.fromValue = [NSNumber numberWithFloat:0];
        ani.toValue = [NSNumber numberWithFloat:1];
        ani.delegate = self;
        ani.removedOnCompletion = NO;
        ani.fillMode=kCAFillModeForwards;
        [ani setValue:kLineUpAnimationValue forKey:kLineUpAnimationKey];
        [_linePathLayer addAnimation:ani forKey:kLineUpAnimationKey];
        
        [_fishHookView.layer removeAllAnimations];
        
        NSValue *p1 = [NSValue valueWithCGPoint:CGPointMake(ScreenWidth/2.0 ,5)];
        NSValue *p2 = [NSValue valueWithCGPoint:CGPointMake(_lineOffsetX, FishLineHeigth)];
        _hookAnimation.duration = aniDuration;
        _hookAnimation.values = @[p2,p1];
        _hookAnimation.keyTimes = @[@0,@1];
        [_fishHookView.layer addAnimation:_hookAnimation forKey:@"goukey"];
    }
}

#pragma mark - CAAnimationDelegate 动画代理
//动画开始
- (void)animationDidStart:(CAAnimation *)anim{
    
    //下钩动画开始
    if ([[anim valueForKey:kLineDownAnimationKey] isEqualToString:kLineDownAnimationValue]){
        self.fishHookState = FishHookStateDown;//下钩状态
        //钱数
        self.moneyLabel.text = [NSString stringWithFormat:@"%d", _totalMoney-=10];
        self.winMoney = 0;
        
    }else if ([[anim valueForKey:kLineUpAnimationKey] isEqualToString:kLineUpAnimationValue]){//上钩动画开始
        self.fishHookState = FishHookStateUp;//上钩状态
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationFishHookMove object:nil];
    }
    
    if (self.isCatched){//钓到鱼后落金币
        HHShootButton *button = [[HHShootButton alloc] initWithFrame:CGRectMake(_lineOffsetX, 0, 10, 10) andEndPoint:CGPointMake(15, 200)];
        button.setting.iconImage = [UIImage imageNamed:@"coin"];
        button.setting.animationType = ShootButtonAnimationTypeLine;
        [self.bgImageView addSubview:button];
        [self bringSubviewToFront:button];
        [button startAnimation];
        
        HHWinMoneyLabel *winLabel = [[HHWinMoneyLabel alloc] initWithFrame:CGRectMake(_lineOffsetX - 100/2, ScreenFullHeight - FishSeaHeight, 100, 30)];
        winLabel.text = [NSString stringWithFormat:@"+%d",_winMoney];
        [self addSubview:winLabel];
        
        self.isCatched = !self.isCatched;
        //金币总数
        self.moneyLabel.text = [NSString stringWithFormat:@"%d", _totalMoney+=self.winMoney];
    }
}

//动画结束
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if (flag){
        
        if ([[anim valueForKey:kLineDownAnimationKey] isEqualToString:kLineDownAnimationValue]){//下钩动画结束
            
            self.fishHookState = FishHookStateStop;//垂钓状态
            //钩的位置
            NSDictionary *dic = @{@"offsetX":[NSString stringWithFormat:@"%.2f",_hookBottomX],@"offsetY":[NSString stringWithFormat:@"%.2f",_hookBottomY]};
            //发送可以垂钓的通知,钩的位置传过去
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationFishHookStop object:nil userInfo:dic];
            
            _stopDuration = [self hookOutOfRiver] ? 1 : arc4random()%3 + 3; //默认时间[3,5),抛到岸上1s
            //开启上钩定时器
            [_fishTimer setFireDate:[NSDate distantPast]];
            
        }else if ([[anim valueForKey:kLineUpAnimationKey] isEqualToString:kLineUpAnimationValue]){//上钩动画结束
            
            self.fishHookState = FishHookStateShake;//摇摆状态
            [_linePathLayer removeFromSuperlayer];
            [_fishHookView hoolTimerGoOn];//鱼钩计时器继续
            _catchedHeight = 0;
            //移除钓上来的鱼
            [self removeTheCatchedFishes];
        }
    }
}

#pragma mark - FishModelImageViewDelegate  钓到鱼后的代理
- (void)catchTheFishWithType:(FishModelImageViewType)type andDirection:(FishModelImageViewDirection)dir andWinCount:(int)count{
    self.isCatched = YES;
    
    FishModelImageView *fishImageView = [[FishModelImageView alloc] initCatchedFishWithType:type andDirection:dir];
    [self.fishHookView addSubview:fishImageView];
    
    fishImageView.y = fishImageView.y + _catchedHeight;
    _catchedHeight += 8;//每钓到一个y坐标往下移
    
    //赢得钱数
    self.winMoney += count;
}

//移除鱼钩上的鱼
- (void)removeTheCatchedFishes{
    
    for (UIView *view in [self.fishHookView subviews]){
        if ([view isKindOfClass:[FishModelImageView class]]){
            [view removeFromSuperview];
        }
    }
}
//鱼钩是否抛到岸上去了
- (BOOL)hookOutOfRiver{
    //鱼钩抛到岸上去了
    if (_hookBottomX < - 20 || _hookBottomX > self.frame.size.width + 20){
        return YES;
    }
    return NO;
}
@end
