//
//  ViewController.m
//  FishingGame
//
//  Created by chh on 2017/9/13.
//  Copyright © 2017年 chh. All rights reserved.
//

#import "ViewController.h"
#import "FishViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button1 = [[UIButton alloc] initWithFrame:CGRectMake(0, 120, 100, 50)];
    [button1 setTitle:@"钓鱼🎣" forState:UIControlStateNormal];
    button1.center = self.view.center;
    [button1 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(button1Action) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
}

- (void)button1Action{
    [self.navigationController pushViewController:[[FishViewController alloc] init] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
