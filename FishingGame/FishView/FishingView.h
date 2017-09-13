//
//  FishingView.h
//  HHFramework
//
//  Created by chh on 2017/9/13.
//  Copyright © 2017年 chh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FishingView : UIView

//释放钓鱼游戏资源，在VC-viewDidDisappear后调用
- (void)removeFishViewResource;
@end
