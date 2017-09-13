//
//  FishModelImageView.h
//  HHFramework
//
//  Created by chh on 2017/9/8.
//  Copyright © 2017年 chh. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FishModelImageViewDirection) {
    FishModelImageViewFromLeft,  /// 由左往右
    FishModelImageViewFromRight, /// 由右往左
};

typedef NS_ENUM(NSInteger, FishModelImageViewType){
    FishModelImageViewTypeXHY = 0, //小黄鱼
    FishModelImageViewTypeSBY = 1, //石斑鱼
    FishModelImageViewTypeHSY = 2, //红杉鱼
    FishModelImageViewTypeBWY = 3, //斑纹鱼
    FishModelImageViewTypeSHY = 4, //珊瑚鱼
    FishModelImageViewTypeSY  = 5, //鲨鱼
    
};

@protocol FishModelImageViewDelegate <NSObject>
//钓到鱼了
- (void)catchTheFishWithType:(FishModelImageViewType)type
                andDirection:(FishModelImageViewDirection)dir
                 andWinCount:(int)count;
@end


/**
 * 注意计时器一定要移除掉，要不然资源无法释放，这里选择用通知移除，通知名字是NotificationRemoveFishModelTimer，
 * 在持有的ViewController执行willDismiss方法是发送通知即可
 **/
@interface FishModelImageView : UIImageView

@property (nonatomic, weak) id<FishModelImageViewDelegate> delegate;

/**
 初始化可以垂钓的鱼

 @param type 鱼的种类
 @param dir 游动方向
 @return view
 */
- (instancetype)initCanCatchFishWithType:(FishModelImageViewType)type andDirection:(FishModelImageViewDirection)dir;

/**
 初始化模型鱼
 
 @param type 鱼的种类
 @param dir 游动方向
 @return view
 */
- (instancetype)initModelFishWithType:(FishModelImageViewType)type andDirection:(FishModelImageViewDirection)dir;

/**
 初始化被钓到鱼

 @param type 鱼的种类
 @param dir 游动方向
 @return view
 */
- (instancetype)initCatchedFishWithType:(FishModelImageViewType)type andDirection:(FishModelImageViewDirection)dir;
@end
