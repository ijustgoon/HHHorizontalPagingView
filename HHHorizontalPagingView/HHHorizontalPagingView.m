//
//  HHHorizontalPagingView.m
//  HHHorizontalPagingView
//
//  Created by Huanhoo on 15/7/16.
//  Copyright (c) 2015年 Huanhoo. All rights reserved.
//

#import "HHHorizontalPagingView.h"

@interface HHHorizontalPagingView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UIView             *headerView;
@property (nonatomic, strong) NSArray            *segmentButtons;
@property (nonatomic, strong) NSArray            *contentViews;

@property (nonatomic, strong) UIView             *segmentView;

@property (nonatomic, strong) UICollectionView   *horizontalCollectoinView;

@property (nonatomic, strong) UIScrollView       *currentScrollView;
@property (nonatomic, strong) NSLayoutConstraint *headerOriginYConstraint;
@property (nonatomic, assign) CGFloat            headerViewHeight;
@property (nonatomic, assign) CGFloat            segmentBarHeight;
@property (nonatomic, assign) BOOL               isSwitching;

@end

@implementation HHHorizontalPagingView

static void *HHHorizontalPagingViewScrollContext = &HHHorizontalPagingViewScrollContext;
static void *HHHorizontalPagingViewPanContext    = &HHHorizontalPagingViewPanContext;
static NSString *pagingCellIdentifier            = @"PagingCellIdentifier";
static NSInteger pagingButtonTag                 = 1000;

+ (HHHorizontalPagingView *)pagingViewWithHeaderView:(UIView *)headerView
                                        headerHeight:(CGFloat)headerHeight
                                      segmentButtons:(NSArray *)segmentButtons
                                       segmentHeight:(CGFloat)segmentHeight
                                        contentViews:(NSArray *)contentViews {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing          = 0.0;
    layout.minimumInteritemSpacing     = 0.0;
    layout.scrollDirection             = UICollectionViewScrollDirectionHorizontal;
    
    HHHorizontalPagingView *pagingView = [[HHHorizontalPagingView alloc] initWithFrame:CGRectMake(0., 0., [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    
    pagingView.horizontalCollectoinView = [[UICollectionView alloc] initWithFrame:pagingView.frame collectionViewLayout:layout];
    [pagingView.horizontalCollectoinView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:pagingCellIdentifier];
    pagingView.horizontalCollectoinView.backgroundColor                = [UIColor clearColor];
    pagingView.horizontalCollectoinView.dataSource                     = pagingView;
    pagingView.horizontalCollectoinView.delegate                       = pagingView;
    pagingView.horizontalCollectoinView.pagingEnabled                  = YES;
    pagingView.horizontalCollectoinView.showsHorizontalScrollIndicator = NO;
    pagingView.headerView                     = headerView;
    pagingView.segmentButtons                 = segmentButtons;
    pagingView.contentViews                   = contentViews;
    pagingView.headerViewHeight               = headerHeight;
    pagingView.segmentBarHeight               = segmentHeight;
    
    UICollectionViewFlowLayout *tempLayout = (id)pagingView.horizontalCollectoinView.collectionViewLayout;
    tempLayout.itemSize = pagingView.horizontalCollectoinView.frame.size;
    
    [pagingView addSubview:pagingView.horizontalCollectoinView];
    [pagingView configureHeaderView];
    [pagingView configureSegmentView];
    [pagingView configureContentView];
    
    return pagingView;
}

- (void)configureHeaderView {
    if(self.headerView) {
        self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.headerView];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.headerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.headerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
        self.headerOriginYConstraint = [NSLayoutConstraint constraintWithItem:self.headerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];
        [self addConstraint:self.headerOriginYConstraint];
        
        [self.headerView addConstraint:[NSLayoutConstraint constraintWithItem:self.headerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:self.headerViewHeight]];
    }
}

- (void)configureSegmentView {
    
    if(self.segmentView) {
        self.segmentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.segmentView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.segmentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.segmentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.segmentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.headerView ? : self attribute:self.headerView ? NSLayoutAttributeBottom : NSLayoutAttributeTop multiplier:1 constant:0]];
        [self.segmentView addConstraint:[NSLayoutConstraint constraintWithItem:self.segmentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:self.segmentBarHeight]];
    }
}

- (void)configureContentView {
    for(UIScrollView *v in self.contentViews) {
        [v  setContentInset:UIEdgeInsetsMake(self.headerViewHeight+self.segmentBarHeight, 0., 0., 0.)];
        v.alwaysBounceVertical = YES;
        v.showsVerticalScrollIndicator = NO;
        v.contentOffset = CGPointMake(0., -self.headerViewHeight-self.segmentBarHeight);
        [v.panGestureRecognizer addObserver:self forKeyPath:NSStringFromSelector(@selector(state)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:HHHorizontalPagingViewPanContext];
        [v addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:&HHHorizontalPagingViewScrollContext];
        
    }
    self.currentScrollView = [self.contentViews firstObject];
}

- (UIView *)segmentView {
    if(!_segmentView) {
        _segmentView = [[UIView alloc] init];
        if([self.segmentButtons count] > 0) {
            CGFloat buttonWidth = [[UIScreen mainScreen] bounds].size.width/(CGFloat)[self.segmentButtons count];
            for(int i = 0; i < [self.segmentButtons count]; i++) {
                UIButton *segmentButton = self.segmentButtons[i];
                segmentButton.tag = pagingButtonTag+i;
                [segmentButton addTarget:self action:@selector(segmentButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
                [_segmentView addSubview:segmentButton];
                
                if(i == 0) {
                    [segmentButton setSelected:YES];
                }
                
                segmentButton.translatesAutoresizingMaskIntoConstraints = NO;
                [_segmentView addConstraint:[NSLayoutConstraint constraintWithItem:segmentButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_segmentView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
                [_segmentView addConstraint:[NSLayoutConstraint constraintWithItem:segmentButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_segmentView attribute:NSLayoutAttributeLeft multiplier:1 constant:i*buttonWidth]];
                [_segmentView addConstraint:[NSLayoutConstraint constraintWithItem:segmentButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_segmentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
                [segmentButton addConstraint:[NSLayoutConstraint constraintWithItem:segmentButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:buttonWidth]];
                
            }
        }
    }
    return _segmentView;
}

- (void)segmentButtonEvent:(UIButton *)segmentButton {
    for(UIButton *b in self.segmentButtons) {
        [b setSelected:NO];
        
    }
    [segmentButton setSelected:YES];
    [self.horizontalCollectoinView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:segmentButton.tag-pagingButtonTag inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    self.currentScrollView = self.contentViews[segmentButton.tag-pagingButtonTag];
}

- (void)adjustContentViewOffset {
    self.isSwitching = YES;
    CGFloat headerViewDisplayHeight = self.headerViewHeight + self.headerView.frame.origin.y;
    if(self.currentScrollView.contentOffset.y < -self.segmentBarHeight) {
        [self.currentScrollView setContentOffset:CGPointMake(0, -headerViewDisplayHeight-self.segmentBarHeight)];
    }
    self.isSwitching = NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    
    if (view == self.headerView) {
        self.horizontalCollectoinView.scrollEnabled = NO;
        return self.currentScrollView;
    }
    return view;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.contentViews count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    self.isSwitching = YES;
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:pagingCellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    for(UIView *v in cell.contentView.subviews) {
        [v removeFromSuperview];
    }
    [cell.contentView addSubview:self.contentViews[indexPath.row]];
    
    UIScrollView *v = self.contentViews[indexPath.row];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:v attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:v attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:v attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:v attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self adjustContentViewOffset];
    
    return cell;
    
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(__unused id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if(context == &HHHorizontalPagingViewPanContext) {
        
        self.horizontalCollectoinView.scrollEnabled = YES;
        
    }else if (context == &HHHorizontalPagingViewScrollContext) {
        
        if (self.isSwitching) {
            return;
        }
        
        CGFloat oldOffsetY          = [change[NSKeyValueChangeOldKey] CGPointValue].y;
        CGFloat newOffsetY          = [change[NSKeyValueChangeNewKey] CGPointValue].y;
        CGFloat deltaY              = newOffsetY - oldOffsetY;
        
        CGFloat headerViewHeight    = self.headerViewHeight;
        CGFloat headerDisplayHeight = self.headerViewHeight+self.headerOriginYConstraint.constant;
        
        if(deltaY > 0) {    //向上滚动
            
            if(headerDisplayHeight - deltaY <= 0) {
                self.headerOriginYConstraint.constant = -headerViewHeight;
                
            }else {
                self.headerOriginYConstraint.constant -= deltaY;
            }
            if(headerDisplayHeight <= 0) {
                self.headerOriginYConstraint.constant = -headerViewHeight;
            }
            
        }else {            //向下滚动
            if (headerDisplayHeight+self.segmentBarHeight < -newOffsetY) {
                self.headerOriginYConstraint.constant -= deltaY;
            }
        }
    }
    
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger currentPage = scrollView.contentOffset.x/[[UIScreen mainScreen] bounds].size.width;
    
    for(UIButton *b in self.segmentButtons) {
        if(b.tag - pagingButtonTag == currentPage) {
            [b setSelected:YES];
        }else {
            [b setSelected:NO];
        }
    }
    self.currentScrollView = self.contentViews[currentPage];
}

- (void)dealloc {
    for(UIScrollView *v in self.contentViews) {
        [v.panGestureRecognizer removeObserver:self forKeyPath:NSStringFromSelector(@selector(state)) context:&HHHorizontalPagingViewPanContext];
        [v removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:&HHHorizontalPagingViewScrollContext];
    }
}

@end