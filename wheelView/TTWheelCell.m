//
//  TTWheelCell.m
//  wheelView
//
//  Created by simp on 2018/2/28.
//  Copyright © 2018年 yiyou. All rights reserved.
//

#import "TTWheelCell.h"
#import "TTWheelView.h"
#import <Masonry.h>

@interface TTWheelCell ()

@property (nonatomic, copy) NSString * identifre;

@end

@implementation TTWheelCell

static int a = 0;

- (instancetype)initWithReuserIdentifire:(NSString *)identiFire {
    if (self = [super init]) {
        self.identifre = identiFire;
        NSLog(@"新建cell%d",++a);
        _direction = TTWheelCellDirectionVerticle;
        [self initialUI];
    }
    return self;
}

- (void)initialUI {
    self.textlabel = [[UILabel alloc] init];
    [self addSubview:self.textlabel];
    [self.textlabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
    }];
}

- (void)didMoveToWindow {
    if (self.window == nil) {
        [self.inderDelegate wheelCellDisAppeared:self];
    }else {
      
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (BOOL)visible {
    return [self.inderDelegate wheelCellVisible:self];
}

- (void)setText:(NSString *)text {
    self.textlabel.text = text;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@-angel:%f",self.textlabel.text,self.currentAngel];
}


- (void)setCurrentAngel:(CGFloat)currentAngel {
    
    _currentAngel = currentAngel;
    [self resetAngel];
}

- (void)resetAngel {
    if (_direction == TTWheelCellDirectionCenter) {
        self.transform = CGAffineTransformMakeRotation(_currentAngel);
    }else if (_direction == TTWheelCellDirectionVerticle) {
        CGFloat sAnger = [self.inderDelegate currentAngel];
        self.transform = CGAffineTransformMakeRotation(-sAnger);
    }
    if (self.hidden ) {
        if (![self.inderDelegate isStoppingRotate]) {
            self.hidden = NO;
        }
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self.inderDelegate scrollToDataIndex:self.dataIndex];
    [self.inderDelegate scrollToCell:self];
}

@end
