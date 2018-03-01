//
//  TTWheelView.h
//  wheelView
//
//  Created by simp on 2018/2/28.
//  Copyright © 2018年 yiyou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTWheelCell.h"
@class TTWheelView;

@protocol TTWheelDataSource <NSObject>


/**
 当前cell的大小

 @param index cell的Index
 @return TTWheelCell
 */
- (CGSize)sizeForItemAtIndex:(NSInteger)index;


/**
 当前cell所处的半径

 @param index index
 @return haf
 */
- (CGFloat)radiuForIndex:(NSInteger)index;

/** each cell at index*/
@required

- (TTWheelCell *)cellAtIndex:(NSInteger)index forWheel:(TTWheelView *)wheel;

- (NSUInteger)dataCountForWheel:(TTWheelView *)wheel;


@end

@interface TTWheelView : UIView

- (instancetype)init __unavailable;

@property (nonatomic, weak) id<TTWheelDataSource> dataSource;

/**当前旋转的角度*/
@property (nonatomic, assign, readonly) CGFloat currentAngel;

/**翻页的弧度 0 表示不翻页*/
@property (nonatomic, assign) CGFloat pageArc;

/**是否停止在某个cell上*/
@property (nonatomic, assign) BOOL stopInCell;

/**轮盘半径*/
@property (nonatomic, assign, readonly) CGFloat radiu;

/**
 初始化方法
 
 @param radiu 半径
 @param divitionCount 轮盘被分为几个部分
 @return 轮盘
 */
- (instancetype)initWithradiu:(CGFloat)radiu divitionCount:(NSUInteger)divitionCount;

/**根据宽度 和最大高度线来生成轮子*/
+ (instancetype)wheelWithCrossWidth:(CGFloat)width widthCrossHeight:(CGFloat)height withPartNumber:(NSInteger)number;

- (TTWheelCell *)dequeenCellForIdentifire:(NSString *)identifire;

/**计算子视图的中心点位置*/
- (CGPoint)pointForAngel:(CGFloat)angel andSubRadiu:(CGFloat)radiu;

- (void)scrollToDataIndex:(NSInteger)dataIndex;

- (void)scrollToCell:(TTWheelCell *)cell;

@end
