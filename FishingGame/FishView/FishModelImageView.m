//
//  FishModelImageView.m
//  HHFramework
//
//  Created by chh on 2017/9/8.
//  Copyright © 2017年 chh. All rights reserved.
//  鱼的模型（不可抓取）

#import "FishModelImageView.h"
#import "UIView+Extension.h"
#import "GlobalDefine.h"

#define YuTangHeight  215 //鱼塘的高度
#define OffSetYRange  30 //波动范围

NSString *const kFishCatchedMoveUpKey = @"kFishCatchedMoveUpKey"; //被捉到的鱼往上游
NSString *const kFishCatchedMoveUpValue = @"kFishCatchedMoveUpValue";

NSString *const kModelFishAnimationKey = @"kModelFishAnimationKey"; //模型鱼
NSString *const kModelFishAnimationValue = @"kModelFishAnimationValue";

@interface FishModelImageView()<CAAnimationDelegate>

@property (nonatomic, assign) FishModelImageViewType fishType;
@property (nonatomic, assign) FishModelImageViewDirection direction;
@property (nonatomic, strong) UIBezierPath *fishPath;//游走路径
@property (nonatomic, strong) CAKeyframeAnimation *animation;
@property (nonatomic, assign) CGFloat mOffsetX,mOffsetY;//模型鱼的xy偏移量
@property (nonatomic, assign) double duration;
@property (nonatomic, assign) double speed; //速度
@property (nonatomic, assign) int randomRange;
@property (nonatomic, assign) CGFloat fishWidth; //自身的宽度

@property (nonatomic, strong) CADisplayLink *linkTimer;
@property (nonatomic, assign) CGFloat offsetX, offsetY;//可垂钓的鱼的xy偏移量
@property (nonatomic, assign) CGFloat hookX, hookY;//鱼钩的X,Y坐标
@property (nonatomic, assign) BOOL isCanCatch; //是否可以上钩
@property (nonatomic, assign) CGFloat changeX; //鱼没1/60秒变化的距离
@property (nonatomic, assign) int moneyCount; //获得的钱数
@property (nonatomic, assign) CGFloat catchedOffsetY; //钓到鱼后，向上移动距离变短
@end

@implementation FishModelImageView

//初始化可以垂钓的鱼
- (instancetype)initCanCatchFishWithType:(FishModelImageViewType)type andDirection:(FishModelImageViewDirection)dir{
    if (self = [super init]){
        
        self.direction = dir;
        [self initViewWithType:type andDuration:1];
        if (dir == FishModelImageViewFromLeft){//从左往右，默认所有的鱼都是从右往左
            self.transform = CGAffineTransformMakeScale(-1, 1); //镜像
        }
        [self initFishView];
    }
    return self;
}

//初始化小鱼模型
- (instancetype)initModelFishWithType:(FishModelImageViewType)type andDirection:(FishModelImageViewDirection)dir{
    if (self = [super init]){
        self.direction = dir;
        [self initViewWithType:type andDuration:1];
        if (dir == FishModelImageViewFromLeft){//从左往右，默认所有的鱼都是从右往左
            self.transform = CGAffineTransformMakeScale(-1, 1); //镜像
        }
        [self initModelView];
    }
    return self;
}

//初始化钓到的小鱼
- (instancetype)initCatchedFishWithType:(FishModelImageViewType)type andDirection:(FishModelImageViewDirection)dir{
    if (self = [super init]){
        self.direction = dir;
        [self initViewWithType:type andDuration:0.5];
        //重制x,y坐标， 30为鱼钩的宽度，85为鱼钩的长度
        self.x = (30 - self.width)/2.0;
        self.y = 85 - 6;
        if (dir == FishModelImageViewFromLeft){//从左往右，默认所有的鱼都是从右往左
            CGAffineTransform transform = CGAffineTransformIdentity;
            transform = CGAffineTransformScale(transform, -1, 1);//镜像
            transform = CGAffineTransformRotate(transform, M_PI_2);//旋转90度
            self.transform = transform;
        }else {
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
        }

    }
    return self;
}

//初始化小鱼 git动画时长
- (void)initViewWithType:(FishModelImageViewType)type andDuration:(double)time{
    
    self.fishType = type;
    switch (type) {
        case FishModelImageViewTypeXHY://小黄鱼
            self.duration = 6.0;
            self.frame = CGRectMake(-100, 0, 35, 40); //鱼的大小要定义好
            self.image = [UIImage animatedImageNamed:@"xhy" duration:time];
            break;
        case FishModelImageViewTypeSBY://石斑鱼
            self.duration = 7.0;
            self.frame = CGRectMake(-100, 0, 50, 50);
            self.image = [UIImage animatedImageNamed:@"sby" duration:time];
            break;
        case FishModelImageViewTypeHSY://红杉鱼
            self.duration = 8.0;
            self.frame = CGRectMake(-100, 0, 50, 40);
            self.image = [UIImage animatedImageNamed:@"hsy" duration:time];
            break;
        case FishModelImageViewTypeBWY://斑纹鱼
            self.duration = 8.5;
            self.frame = CGRectMake(-100, 0, 65, 53);
            self.image = [UIImage animatedImageNamed:@"bwy" duration:time];
            break;
        case FishModelImageViewTypeSHY://珊瑚鱼
            self.duration = 9.0;
            self.frame = CGRectMake(-100, 0, 55, 55);
            self.image = [UIImage animatedImageNamed:@"shy" duration:time];
            break;
        case FishModelImageViewTypeSY://鲨鱼
            self.duration = 11.0;
            self.frame = CGRectMake(-200, 0, 145, 90);
            self.image = [UIImage animatedImageNamed:@"sy" duration:time];
            break;
    }
}
/*****************第一种*********************/
#pragma mark - 可以垂钓的鱼（计时器）
- (void)initFishView{
    
    //接收可以垂钓的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationCanCatch:) name:NotificationFishHookStop object:nil];
    //接收不可垂钓的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationCannotCatch) name:NotificationFishHookMove object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeTimer) name:NotificationRemoveFishModelTimer object:nil];
    //创建计时器
    _linkTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(fishMove)];
    //启动这个link(加入到线程池)
    [_linkTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    _offsetX = ScreenWidth;
    _offsetY = 100;
    _fishWidth = self.frame.size.width;
    //Y可变高度范围
    _randomRange = (int) (YuTangHeight - self.frame.size.height - OffSetYRange);
    self.speed = (ScreenWidth + _fishWidth)/self.duration;//游动速度
    self.changeX = self.speed/60.0;//计时器每秒60次
    DLog(@"鱼游动的速度：%f,每次位移:%f", self.speed,self.changeX);
}

//移除通知
- (void)dealloc{
    DLog(@"小鱼释放了");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)removeTimer{
    [self.linkTimer invalidate];
}

- (void)fishMove{
    
    if (self.direction == FishModelImageViewFromLeft){//从左至右
        if (_offsetX > ScreenWidth + _fishWidth){
            _offsetY = arc4random()%_randomRange + OffSetYRange;
            _offsetX = - _fishWidth - _offsetY;
        }
        _offsetX+=self.changeX;
        
        self.frame = [self resetFrameOrigin:CGPointMake(_offsetX, _offsetY)];
        
        if ([self fishCanBeCatchedWithOffsetX:_offsetX + _fishWidth]){
            NSLog(@"钓到从左到右的鱼了:%ld",(long)self.fishType);
            CGAffineTransform transform = CGAffineTransformIdentity;
            transform = CGAffineTransformScale(transform, -1, 1);//镜像
            transform = CGAffineTransformRotate(transform, M_PI_2);//旋转90度
            self.transform = transform;
            
            self.frame = [self resetFrameOrigin:CGPointMake(ScreenWidth*2, 0)];
            [self fishCatchedMoveUpWithOffsetX:_offsetX + _fishWidth];
            _offsetX = ScreenWidth + _fishWidth + 1;//重置起点
            _linkTimer.paused = YES;//计时器暂停
        }
        
    }else {//从右到左
        
        if (_offsetX < -_fishWidth){
            _offsetY = arc4random()%_randomRange + OffSetYRange;
            _offsetX = ScreenWidth + _offsetY;
        }
        _offsetX-=self.changeX;
        self.frame = [self resetFrameOrigin:CGPointMake(_offsetX, _offsetY)];
        
        if ([self fishCanBeCatchedWithOffsetX:_offsetX]){
            NSLog(@"钓到从右到左的鱼了:%ld",(long)self.fishType);
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.frame = [self resetFrameOrigin:CGPointMake(ScreenWidth*2, 0)];
            
            [self fishCatchedMoveUpWithOffsetX:_offsetX];
            _offsetX = -_fishWidth-1;//重置起点
            _linkTimer.paused = YES;//计时器暂停
        }
    }
}

//鱼被抓到后往上游
- (void)fishCatchedMoveUpWithOffsetX:(CGFloat) offsetX{
    
    //钩沉到鱼塘的高度为45
    //位移动画
    CABasicAnimation *ani = [CABasicAnimation animationWithKeyPath:@"position"];
    ani.duration = 0.7;
    if (self.fishType == FishModelImageViewTypeSY){//鲨鱼由于太长，所以不进行上游动画了
        ani.fromValue = [NSValue valueWithCGPoint:CGPointMake(offsetX,45 + _fishWidth/2.0)];
        ani.toValue = [NSValue valueWithCGPoint:CGPointMake(_hookX, 45 + _fishWidth/2.0)];
    }else {
        ani.fromValue = [NSValue valueWithCGPoint:CGPointMake(offsetX, (_offsetY < 60) ? 45 + _fishWidth/2.0 : _offsetY)];//离钩子近的话则不进行动画
        ani.toValue = [NSValue valueWithCGPoint:CGPointMake(_hookX, 45 + _fishWidth/2.0)];
    }
    ani.delegate = self;
    //设置这两句动画结束会停止在结束位置
    [ani setValue:kFishCatchedMoveUpValue forKey:kFishCatchedMoveUpKey];
    [self.layer addAnimation:ani forKey:kFishCatchedMoveUpKey];
}

//鱼是否可以被钓上来（根据概率计算）
- (BOOL)fishCanBeCatchedWithOffsetX:(CGFloat)offsetX{
    
    if (!self.isCanCatch) return NO;
    if (fabs(offsetX - self.hookX) > self.changeX/2.0) return NO; //判断是否到达了可以垂钓的点
    int random = arc4random()%100; //[0,99]
    
    DLog(@"random:%d", random);
    switch (self.fishType) {
        case FishModelImageViewTypeXHY://小黄鱼 80% 金币2
            if (random < 80){
                self.moneyCount = 2;
                return YES;
            }
            break;
        case FishModelImageViewTypeSBY://石斑鱼 50% 金币5
            if (random < 50) {
                self.moneyCount = 5;
                return YES;
            }
            break;
        case FishModelImageViewTypeHSY://红杉鱼 30% 金币10
            if (random < 30) {
                self.moneyCount = 10;
                return YES;
            }
            break;
        case FishModelImageViewTypeBWY://斑纹鱼 15% 金币20
            if (random < 15)  {
                self.moneyCount = 20;
                return YES;
            }
            break;
        case FishModelImageViewTypeSHY://珊瑚鱼 5% 金币50
            if (random < 5)  {
                self.moneyCount = 50;
                return YES;
            }
            break;
        case FishModelImageViewTypeSY://鲨鱼 1% 金币100
            if (random < 1)  {
                self.moneyCount = 100;
                return YES;
            }
            break;
    }
    self.moneyCount = 0;
    return NO;
}

//重置起点
- (CGRect)resetFrameOrigin:(CGPoint)point{
    return CGRectMake(point.x, point.y, self.frame.size.width, self.frame.size.height);
}

#pragma mark  收到通知
//可以垂钓
- (void)notificationCanCatch:(NSNotification *)notificaton{
    self.isCanCatch = YES;
    //鱼钩X,Y坐标
    self.hookX = [notificaton.userInfo[@"offsetX"] doubleValue];
    self.hookY = [notificaton.userInfo[@"offsetY"] doubleValue];
}
//鱼钩上升
- (void)notificationCannotCatch{
    self.isCanCatch = NO;
    _linkTimer.paused = NO;
}
/**********************第二种*****************************/

#pragma mark - 模型鱼(路径动画)
- (void)initModelView{
    
    //Y可变高度范围
    _randomRange = (int) (YuTangHeight - self.frame.size.height - OffSetYRange);
    
    _mOffsetX = self.frame.size.width;
    _mOffsetY = arc4random()%_randomRange + OffSetYRange;
    
    //计算速度
    self.speed = (ScreenWidth + _mOffsetX)/self.duration;
    
    //位移动画
    _animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    _fishPath = [UIBezierPath bezierPath];
    
    if (self.direction == FishModelImageViewFromLeft){
        CGFloat fromX = -_mOffsetX - arc4random()%100;//随机开始位置，避免鱼同时出现
        [_fishPath moveToPoint:CGPointMake(fromX, _mOffsetY)];
        [_fishPath addLineToPoint:CGPointMake(ScreenWidth + _mOffsetX, _mOffsetY)];
        
        _animation.duration = (ScreenWidth + _mOffsetX - fromX)/self.speed;
    }else {
        CGFloat fromX = ScreenWidth + arc4random()%100;
        [_fishPath moveToPoint:CGPointMake(fromX, _mOffsetY)];
        [_fishPath addLineToPoint:CGPointMake(-_mOffsetX, _mOffsetY)];
        _animation.duration = (fromX + _mOffsetX)/self.speed;
    }
    
    //移动路径
    _animation.path = _fishPath.CGPath;
    _animation.autoreverses = NO;
    _animation.delegate = self;
    _animation.repeatCount = 1;
    _animation.calculationMode = kCAAnimationPaced;
    [_animation setValue:kModelFishAnimationValue forKey:kModelFishAnimationKey];
    [self.layer addAnimation:_animation forKey:kModelFishAnimationKey];
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if (flag){
        
        if ([[anim valueForKey:kModelFishAnimationKey] isEqualToString:kModelFishAnimationValue]){//模型鱼动画结束
            {
                _mOffsetY = arc4random()%_randomRange + OffSetYRange;
                [_fishPath removeAllPoints];
                if (self.direction == FishModelImageViewFromLeft){
                    [_fishPath moveToPoint:CGPointMake(-_mOffsetX - _mOffsetY , _mOffsetY)];
                    [_fishPath addLineToPoint:CGPointMake(ScreenWidth + _mOffsetX + _mOffsetY, _mOffsetY)];
                    //根据速度调整动画时长
                    _animation.duration = (ScreenWidth + 2*_mOffsetX + 2*_mOffsetY)/self.speed;
                    
                }else {
                    [_fishPath moveToPoint:CGPointMake(ScreenWidth + _mOffsetY, _mOffsetY)];
                    [_fishPath addLineToPoint:CGPointMake(-_mOffsetX - _mOffsetY, _mOffsetY)];
                    
                    _animation.duration = (ScreenWidth + _mOffsetX + 2*_mOffsetY)/self.speed;
                }
                
                _animation.path = _fishPath.CGPath;
                [self.layer addAnimation:_animation forKey:@"fishPosition"];
            }
        
        }else if ([[anim valueForKey:kFishCatchedMoveUpKey] isEqualToString:kFishCatchedMoveUpValue]){//鱼上游
            
            if (self.direction == FishModelImageViewFromLeft){
                CGAffineTransform transform = CGAffineTransformIdentity;
                transform = CGAffineTransformScale(transform, -1, 1);//镜像
                transform = CGAffineTransformRotate(transform, 0);//旋转90度
                self.transform = transform;

            }else {
                self.transform = CGAffineTransformMakeRotation(0);
            }
            if ([self.delegate respondsToSelector:@selector(catchTheFishWithType:andDirection:andWinCount:)]){
                [self.delegate catchTheFishWithType:self.fishType andDirection:self.direction andWinCount:self.moneyCount];
            }
        }
   }
}

@end
