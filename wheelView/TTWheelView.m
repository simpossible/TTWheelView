//
//  TTWheelView.m
//  wheelView
//
//  Created by simp on 2018/2/28.
//  Copyright © 2018年 yiyou. All rights reserved.
//

#import "TTWheelView.h"
#import "TTWheelCell.h"
#import <Masonry.h>

@interface TTWheelView()<TTWheelInnerProtocol,UIScrollViewDelegate>

/**轮盘的滚动控制*/
@property (nonatomic, strong) UIScrollView * scrollView;

/**轮盘试图*/
@property (nonatomic, strong) UIView * wheel;

/**轮盘半径*/
@property (nonatomic, assign) CGFloat radiu;

/**轮盘被分为啦多少个部分*/
@property (nonatomic, assign) NSUInteger divitionCount;

/**每个cell 所占用的弧度*/
@property (nonatomic, assign) CGFloat angelPerCell;

/**cell的缓存-重用机制*/
@property (nonatomic, strong) NSDictionary * cellCache;

/**当前的索引位置*/
@property (nonatomic, assign) NSInteger indexFlas;

/** 周长*/
@property (nonatomic, assign) CGFloat perimeter;

@property (nonatomic, strong) TTWheelCell * cell;

@property (nonatomic, strong) NSMutableArray * visibleCells;

@property (nonatomic, strong) NSMutableArray * unvisibleCells;

@property (nonatomic, assign) NSInteger leftAppearIndex;

@property (nonatomic, assign) NSInteger rightAppearIndex;

/**是否可以从缓存拿数据*/
@property (nonatomic, assign) BOOL isCanDequeen;

@property (nonatomic, strong) NSMutableArray * allCells;

@property (nonatomic, assign) CGPoint lastOffset;;
@end

@implementation TTWheelView

- (instancetype)initWithradiu:(CGFloat)radiu divitionCount:(NSUInteger)divitionCount {
    if (self = [super init]) {
        self.radiu = radiu;
        self.divitionCount = divitionCount;
        self.angelPerCell = M_PI * 2 / divitionCount;
        _pageArc = 0;
        
        [self initialData];
        [self initialUI];
    }
    return self;
}

- (void)initialData {
    self.perimeter =  M_PI * self.radiu * 2;
    self.cellCache = [NSMutableDictionary dictionary];
    self.visibleCells = [NSMutableArray array];
    self.unvisibleCells = [NSMutableArray array];
    self.allCells = [NSMutableArray array];
}

- (void)initialUI {
//    [self initialScrollView];
    [self initialWheelView];
    
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.radiu * 2);
        make.height.mas_equalTo(self.radiu * 2);
    }];
}

- (void)initialScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    [self insertSubview:self.scrollView atIndex:0];
//    [self addSubview:self.scrollView];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self addGestureRecognizer:self.scrollView.panGestureRecognizer];
    self.scrollView.contentSize = CGSizeMake(self.perimeter * 3, self.frame.size.height);
    self.scrollView.contentOffset = CGPointMake(self.perimeter, self.frame.size.height);
    self.scrollView.delegate = self;
    
}

- (void)initialWheelView {
    self.wheel = [[UIView alloc] init];
    [self addSubview:self.wheel];
    
    [self.wheel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    self.wheel.backgroundColor = [UIColor orangeColor];
}


/**初始化 各个Cell*/
- (void)cacluteCenterPointerForCells {
    int i = 0;
    for (; i < self.divitionCount; i ++) {
        TTWheelCell * cell =  [self.dataSource cellAtIndex:i forWheel:self];
        [self addCell:cell forDataIndex:i andPartIndex:i];
        [self.allCells addObject:cell];
        if (!cell.visible) {
            [self.unvisibleCells addObject:cell];
            self.rightAppearIndex = i;
            break;
        }
        [self.visibleCells addObject:cell];
    }
    
    if (i < self.divitionCount -1) {
        NSUInteger count = [self.dataSource dataCountForWheel:self];
        for (int j = (int)self.divitionCount-1; j > i; j --) {
            NSInteger dataindex = count-(self.divitionCount - 1 - j);
            TTWheelCell * cell =  [self.dataSource cellAtIndex:dataindex forWheel:self];
            [self addCell:cell forDataIndex:dataindex andPartIndex:j];
            [self.allCells insertObject:cell atIndex:0];
            if (!cell.visible) {
                [self.unvisibleCells insertObject:cell atIndex:0];
                self.leftAppearIndex = dataindex;
                break;
            }
            [self.visibleCells insertObject:cell atIndex:0];
            self.cell = cell;
        }
    }
    self.isCanDequeen = YES;
}

- (void)addCell:(TTWheelCell *)cell forDataIndex:(NSInteger)dataIndex andPartIndex:(NSInteger)partIndex{
    cell.partIndex = partIndex;
    cell.dataIndex = dataIndex;
    cell.inderDelegate = self;
    CGSize size = [self.dataSource sizeForItemAtIndex:dataIndex];
    CGFloat cellRaiud = [self.dataSource radiuForIndex:dataIndex];
    
    CGFloat angel = self.angelPerCell * partIndex;
    cell.bounds = CGRectMake(0, 0, size.width, size.height);
    CGPoint center = [self pointForAngel:angel andSubRadiu:cellRaiud];
    cell.radiu = cellRaiud;
    cell.currentAngel = angel;
    
    cell.center = center;
    
    [cell setText:[NSString stringWithFormat:@"%ld",dataIndex]];
    if (!cell.superview) {
        [self.wheel addSubview:cell];
    }else {
//        [cell removeFromSuperview];
//        [self.wheel addSubview:cell];
    }
    
}

- (CGPoint)pointForAngel:(CGFloat)angel andSubRadiu:(CGFloat)radiu {
    CGFloat centerX = self.radiu + sin(angel) * radiu;
    CGFloat centerY = self.radiu - cos(angel) * radiu;
    CGPoint center = CGPointMake(centerX, centerY);
    return center;
}


- (void)setDataSource:(id<TTWheelDataSource>)dataSource {
    _dataSource = dataSource;
}


#pragma mark - cell 重用

/**不可见视图 入缓存*/
- (void)wheelCellDisAppeared:(TTWheelCell *)cell {
    [self enqueenCell:cell];
}

- (TTWheelCell *)dequeenCellForIdentifire:(NSString *)identifire {
    if (!_isCanDequeen) {
        return nil;
    }
    NSMutableArray *cells = [self.cellCache objectForKey:identifire];
    if (cells.count > 0) {
        TTWheelCell *cell = [cells objectAtIndex:0];
        NSLog(@"cell 被重用 %@",cell);
        [cells removeObject:cell];
        if (cell) {
        }
        return cell;
    }
    return nil;
}

- (void)enqueenCell:(TTWheelCell *)cell {
    NSMutableArray *cells = [self.cellCache objectForKey:cell.identifre];
    if (!cells) {
        cells = [NSMutableArray array];
    }
    [cells addObject:cell];
    [self.cellCache setValue:cells forKey:cell.identifre];
}

- (void)removeCellFromQueue:(TTWheelCell *)cell {
    NSMutableArray *cells = [self.cellCache objectForKey:cell.identifre];
    if ([cells containsObject:cell]) {
        [cells removeObject:cell];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    CGPoint offset = scrollView.contentOffset;
    CGFloat velocy = offset.x - self.lastOffset.x;
    NSLog(@"velocy is----- %f",velocy);
    
  
    
    CGFloat x = offset.x;
    if (x > self.perimeter * 1.5) {
        x -=self.perimeter;
    }
    if (x < self.perimeter) {
        x += self.perimeter;
    }
    scrollView.contentOffset = CGPointMake(x, 0);
    [self scrollWheelWithLength:x-self.perimeter];
    self.lastOffset = scrollView.contentOffset;
    
    if ((fabs(velocy)<=2) && (velocy != 0) && scrollView.isDecelerating) {
        [self stopForScrollView:scrollView widthVelocy:velocy];
    }
}

- (void)stopForScrollView:(UIScrollView *)scrollView widthVelocy:(CGFloat)velocy{
    if (self.stopInCell) {
        CGFloat widthPerCell = self.perimeter /self.divitionCount;
        CGPoint offSet = scrollView.contentOffset;
        NSInteger muti = offSet.x/widthPerCell;
        CGFloat rest = offSet.x - muti * widthPerCell;
        
        CGFloat x;
        if (velocy<0) {//四舍五入
            x = muti * widthPerCell;
        }else {
            rest = widthPerCell - rest;
            x = (muti + 1) * widthPerCell;
        }
        
        CGFloat shouldTime = 1;
        CGFloat time = shouldTime*fabs((rest/widthPerCell));
        
        [UIView animateWithDuration:time animations:^{
            [scrollView setContentOffset:CGPointMake(x, offSet.y) animated:NO];
            //            scrollView.contentOffset = CGPointMake(x, offSet.y);
        } completion:^(BOOL finished) {
            scrollView.scrollEnabled = YES;
        }];
        
    }
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {//如果结束后直接停止了
        CGFloat widthPerCell = self.perimeter /self.divitionCount;
        CGPoint offSet = scrollView.contentOffset;
        NSInteger muti = offSet.x/widthPerCell;
        CGFloat rest = offSet.x - muti * widthPerCell;
        
        CGFloat x;
        if (rest<widthPerCell/2) {//四舍五入
            x = muti * widthPerCell;
        }else {
            rest = widthPerCell - rest;
            x = (muti + 1) * widthPerCell;
        }
        
        CGFloat shouldTime = 1;
        CGFloat time = shouldTime*fabs((rest/widthPerCell));
        
        [UIView animateWithDuration:time animations:^{
            [scrollView setContentOffset:CGPointMake(x, offSet.y) animated:NO];
            //            scrollView.contentOffset = CGPointMake(x, offSet.y);
        } completion:^(BOOL finished) {
            scrollView.scrollEnabled = YES;
        }];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
  
}

/**  角度计算方式以轮盘周长来做计算 -个周长转一圈 */
- (void)scrollWheelWithLength:(CGFloat)len{
    if (!self.isCanDequeen) {
        return;
    }
    NSInteger round =  (int)(len /self.perimeter);
    len = len - self.perimeter * round;
    CGFloat angel = -(len/self.perimeter)* M_PI *2;
    self.wheel.transform = CGAffineTransformMakeRotation(angel);
    
    if (_currentAngel > angel) {//逆时针
         _currentAngel = angel;
        [self anticlockwiseDeal];
    }else {
        _currentAngel = angel;
        [self clockwiseDeal];
    }
    
    for (TTWheelCell *cell in self.allCells) {
        [cell resetAngel];
    }
}

/**逆时针的重用处理*/
- (void)anticlockwiseDeal {
//    NSUInteger count = [self.dataSource dataCountForWheel:self];
//    TTWheelCell * headerVisibleCell = [self.visibleCells firstObject];
//    if (headerVisibleCell && !headerVisibleCell.visible) { //不可见 添加到不可见数组
//        [self.visibleCells removeObject:headerVisibleCell];
//        [self.unvisibleCells insertObject:headerVisibleCell atIndex:0];
//        [self enqueenCell:headerVisibleCell];
//    }
//
//    //找到右边第一个不可见的cell - 检查是否可见
//    TTWheelCell * tailUnvisibleCell = [self.unvisibleCells lastObject];
//
//    if (tailUnvisibleCell.visible && tailUnvisibleCell) {
//        [self.unvisibleCells removeObject:tailUnvisibleCell];
//        [self removeCellFromQueue:tailUnvisibleCell];
//        [self.visibleCells addObject:tailUnvisibleCell];
//        //移除-并找到下一个
//        TTWheelCell *nextUnVisibleCell = [self.unvisibleCells firstObject];
//        /**寻找下一个不可见的是否是接下来的cell*/
//        if (nextUnVisibleCell && ((nextUnVisibleCell.dataIndex == tailUnvisibleCell.dataIndex + 1) || (tailUnvisibleCell.dataIndex==count-1 && nextUnVisibleCell.dataIndex==0))) {
//            NSLog(@"===");
//        }else {//如果没有，则获取
//            NSInteger index = (tailUnvisibleCell.dataIndex + 1)%count;
//            NSInteger partIndex = (tailUnvisibleCell.partIndex + 1)%self.divitionCount;
//            TTWheelCell * cell =  [self.dataSource cellAtIndex:index forWheel:self];
//            [self addCell:cell forDataIndex:index andPartIndex:partIndex];
//            if (!cell.visible) {
//                [self enqueenCell:cell];
//                [self.unvisibleCells addObject:cell];
//            }else {
//                [self removeCellFromQueue:cell];
//                [self.visibleCells addObject:cell];
//            }
//        }
//    }
    [self anticlockwiseDealVisibleCell];
    [self anticlockwiseDealUNVisibleCell];
    
}

/**一次可能不只一个cell 变得不可见了*/
- (void)anticlockwiseDealVisibleCell {
    TTWheelCell * firstObject = [self.allCells objectAtIndex:1];
    if (firstObject && !firstObject.visible) { //不可见 添加到不可见数组
        TTWheelCell *fist = [self.allCells firstObject];
        NSLog(@"移除%@",fist);
        [self enqueenCell:fist];
        [self.allCells removeObject:fist];
        [self anticlockwiseDealVisibleCell];
    }
}

- (void)anticlockwiseDealUNVisibleCell {
    NSUInteger count = [self.dataSource dataCountForWheel:self];
    TTWheelCell * tailUnvisibleCell = [self.allCells lastObject];
    if (tailUnvisibleCell && tailUnvisibleCell.visible) {
        NSInteger index = (tailUnvisibleCell.dataIndex + 1)%count;
        NSInteger partIndex = (tailUnvisibleCell.partIndex + 1)%self.divitionCount;
        TTWheelCell * cell =  [self.dataSource cellAtIndex:index forWheel:self];
        NSLog(@"beforcell is %@",cell);
        [self addCell:cell forDataIndex:index andPartIndex:partIndex];
        NSLog(@"增加%@",cell);
        if ([self.allCells containsObject:cell]) {
            NSLog(@"error");
        }
        [self.allCells addObject:cell];
        [self anticlockwiseDealUNVisibleCell];
    }
}

/**处理顺时针的重用*/
- (void)clockwiseDeal {
  
    //找到尾巴的地方的可见cell 的最后一个 并实时判断它是否可见
    [self ClockwiseDealVisibleCell];
    
    //找到左边第一个不可见的cell - 检查是否可见
    [self ClockwiseDealUnVisibleCell];
}

/**一次可能不只一个cell 变得不可见了*/
- (void)ClockwiseDealVisibleCell {
    
    TTWheelCell * tailVisibleCell = [self.allCells objectAtIndex:self.allCells.count-2];
    if (tailVisibleCell && !tailVisibleCell.visible) { //不可见 添加到不可见数组
        TTWheelCell *last = [self.allCells lastObject];
        NSLog(@"移除%@",last);
        [self enqueenCell:last];
        
        [self.allCells removeLastObject];
        [self ClockwiseDealVisibleCell];
    }
    if (!tailVisibleCell) {
        NSLog(@"____");
    }

    
}
/**一次可能不只一个cell 变得可见了*/
- (void)ClockwiseDealUnVisibleCell {
    NSUInteger count = [self.dataSource dataCountForWheel:self];
    TTWheelCell * headeUnvisibleCell = [self.allCells firstObject];
    if (headeUnvisibleCell && headeUnvisibleCell.visible) {
        NSInteger index = (headeUnvisibleCell.dataIndex-1 + count)%count;
        NSInteger partIndex = (headeUnvisibleCell.partIndex -1+self.divitionCount)%self.divitionCount;
        TTWheelCell * cell =  [self.dataSource cellAtIndex:index forWheel:self];
        [self addCell:cell forDataIndex:index andPartIndex:partIndex];
        NSLog(@"增加%@",cell);
        if ([self.allCells containsObject:cell]) {
            NSLog(@"error");
        }
        [self.allCells insertObject:cell atIndex:0];
        [self ClockwiseDealUnVisibleCell];
    }
    
    if (!headeUnvisibleCell) {
        NSLog(@"++++");
    }

//    if (headeUnvisibleCell && headeUnvisibleCell) {
//        [self.unvisibleCells removeObject:headeUnvisibleCell];
//        [self removeCellFromQueue:headeUnvisibleCell];
//        [self.visibleCells insertObject:headeUnvisibleCell atIndex:0];
//        //移除-并找到下一个
//        TTWheelCell *nextUnVisibleCell = [self.unvisibleCells firstObject];
//        /**寻找下一个不可见的是否是接下来的cell*/
//        if (nextUnVisibleCell && ((headeUnvisibleCell.dataIndex == headeUnvisibleCell.dataIndex -1) || (headeUnvisibleCell.dataIndex==0 && nextUnVisibleCell.dataIndex==count-1))) {
//
//        }else {//如果没有，则获取
//            NSInteger index = (headeUnvisibleCell.dataIndex-1 + count)%count;
//            NSInteger partIndex = (headeUnvisibleCell.partIndex -1+self.divitionCount)%self.divitionCount;
//            TTWheelCell * cell =  [self.dataSource cellAtIndex:index forWheel:self];
//            [self addCell:cell forDataIndex:index andPartIndex:partIndex];
//            [self enqueenCell:cell];
//            [self.unvisibleCells addObject:cell];
//        }
//        [self ClockwiseDealUnVisibleCell];
//    }
}

- (void)drawRect:(CGRect)rect {
    if (!self.scrollView) {
        [self initialScrollView];
        [self cacluteCenterPointerForCells];
        self.pageArc = self.pageArc;
    }
}

#pragma mark - Cell是否可见

- (BOOL)wheelCellVisible:(TTWheelCell *)cell {
    CGFloat angel = cell.currentAngel + self.currentAngel;
    //旋转的frame 是不会计算的 这里我们需要计算相对frame
    CGPoint newCenter = [self pointForAngel:angel andSubRadiu:cell.radiu];
    CGRect newFrame = CGRectMake(newCenter.x - CGRectGetWidth(cell.bounds)/2, newCenter.y - CGRectGetWidth(cell.bounds)/2, CGRectGetWidth(cell.bounds), CGRectGetHeight(cell.bounds));
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect cellFrame = [self convertRect:newFrame toView:window];
    CGRect selfFrame = [self convertRect:self.bounds toView:window];
    BOOL screenVisible = CGRectIntersectsRect(cellFrame, window.bounds);
    BOOL superVisible = CGRectIntersectsRect(cellFrame, selfFrame);
    return screenVisible && superVisible;
    
}

/**设置翻页*/
- (void)setPageArc:(CGFloat)pageArc {
    //一页不能超过M_PI
    _pageArc = pageArc <= 0?0:pageArc;
    _pageArc = pageArc >= M_PI?M_PI:pageArc;
    
    CGFloat rate = pageArc/(M_PI*2);

    self.scrollView.pagingEnabled = _pageArc > 0;
    
    [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
        make.height.equalTo(self.mas_height);
        make.width.mas_equalTo(self.perimeter*rate);
    }];
}

/*
 
 计算出每个cell 各自所在的角度
 
 
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
