//
//  ViewController.m
//  wheelView
//
//  Created by simp on 2018/2/28.
//  Copyright © 2018年 yiyou. All rights reserved.
//

#import "ViewController.h"
#import "TTWheelView.h"
#import <Masonry.h>

@interface ViewController ()<TTWheelDataSource>

@property (nonatomic, strong) TTWheelView * wheel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialUI];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)initialUI {
//    self.wheel = [[TTWheelView alloc] initWithradiu:230 divitionCount:10];
    self.wheel = [TTWheelView wheelWithCrossWidth:self.view.frame.size.width widthCrossHeight:50 withPartNumber:5];
    [self.view addSubview:self.wheel];
    
    CGFloat off = self.wheel.radiu - 150;
    [self.wheel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.centerY.equalTo(self.view.mas_bottom).offset(off);
    }];
    
//    self.wheel.pageArc = M_PI * 2/3;
    self.wheel.stopInCell = YES;
    self.wheel.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (CGSize)sizeForItemAtIndex:(NSInteger)index {
    return CGSizeMake(50, 80);
}


- (CGFloat)radiuForIndex:(NSInteger)index {
    return self.wheel.radiu - 40;
}


- (TTWheelCell *)cellAtIndex:(NSInteger)index forWheel:(TTWheelView *)wheel {
    TTWheelCell *cell = [wheel dequeenCellForIdentifire:@"fuck"];
    if (!cell) {
        cell = [[TTWheelCell alloc] initWithReuserIdentifire:@"fuck"];
        cell.backgroundColor = [UIColor blueColor];
    }
    return cell;
}

- (NSUInteger)dataCountForWheel:(TTWheelView *)wheel {
    return 20;
}

@end
