/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>

@class KalTileView, KalMonthView, KalLogic, KalDate;
@protocol KalViewDelegate;

/*
 *    KalGridView
 *    ------------------
 *
 *    Private interface
 *
 *  As a client of the Kal system you should not need to use this class directly
 *  (it is managed by KalView).
 *
 */

typedef NS_ENUM(NSUInteger, KalGridViewSlideType) {
	KalGridViewSlideTypeNone = 0,
	KalGridViewSlideTypeUp = 1,
	KalGridViewSlideTypeDown = 2
};

@interface KalGridView : UIView

@property (nonatomic, readonly, getter = isTransitioning) BOOL transitioning;
@property (nonatomic, strong, readonly) KalDate *selectedDate;
@property (nonatomic, strong) UIColor *gridBackgroundColor;
@property (nonatomic, strong) UIImage *gridBackgroundImage;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) id <KalViewDelegate> delegate;

- (id) initWithFrame:(CGRect)frame logic:(KalLogic *)logic;

- (void) selectDate:(KalDate *)date;
- (void) slide:(KalGridViewSlideType)slideType; // This method should be called *after* the KalLogic has moved to the previous or following month.
- (void) markTilesForDates:(NSArray *)dates;

@end