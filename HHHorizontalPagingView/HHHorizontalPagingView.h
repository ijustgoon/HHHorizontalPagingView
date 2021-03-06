//
//  HHHorizontalPagingView.h
//  HHHorizontalPagingView
//
//  Created by Huanhoo on 15/7/16.
//  Copyright (c) 2015年 Huanhoo. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HHSegmentView;

@interface HHHorizontalPagingView : UIView

/**
 *  segment据顶部的距离
 */
@property (nonatomic, assign) CGFloat segmentTopSpace;

/**
 *  实例化横向分页控件
 *
 *  @param headerView     tableHeaderView
 *  @param headerHeight   tableHeaderView高度
 *  @param segmentButtons 切换按钮的数组
 *  @param segmentHeight  切换视图高度
 *  @param contentViews   内容视图的数组
 *
 *  @return  控件对象
 */
+ (HHHorizontalPagingView *)pagingViewWithHeaderView:(UIView *)headerView
                                        headerHeight:(CGFloat)headerHeight
                                      segmentButtons:(NSArray *)segmentButtons
                                       segmentHeight:(CGFloat)segmentHeight
                                        contentViews:(NSArray *)contentViews;

@end
