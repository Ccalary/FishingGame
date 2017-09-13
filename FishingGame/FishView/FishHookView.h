//
//  FishHookView.h
//  HHFramework
//
//  Created by chh on 2017/9/8.
//  Copyright © 2017年 chh. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^fishHookAngleBlock)(CGFloat angle);

@interface FishHookView : UIView

@property (nonatomic, strong) fishHookAngleBlock angleBlock;//获得鱼钩角度
//计时器暂停
- (void)hookTimerPause;
//计时器继续
- (void)hoolTimerGoOn;

//计时器释放
- (void)hoolTimerInvalidate;
@end
