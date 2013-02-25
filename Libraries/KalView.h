/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>
#import "KalGridView.h"

@class KalLogic, KalDate;
@protocol KalViewDelegate, KalDataSourceCallbacks;

/*
 *    KalView
 *    ------------------
 *
 *    Private interface
 *
 *  As a client of the Kal system you should not need to use this class directly
 *  (it is managed by KalViewController).
 *
 *  KalViewController uses KalView as its view.
 *  KalView defines a view hierarchy that looks like the following:
 *
 *       +-----------------------------------------+
 *       |                header view              |
 *       +-----------------------------------------+
 *       |                                         |
 *       |                                         |
 *       |                                         |
 *       |                 grid view               |
 *       |             (the calendar grid)         |
 *       |                                         |
 *       |                                         |
 *       +-----------------------------------------+
 *       |                                         |
 *       |           table view (events)           |
 *       |                                         |
 *       +-----------------------------------------+
 *
 */
@interface KalView : UIView

@property (nonatomic, getter = isSliding) BOOL sliding;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong) id <KalViewDelegate> delegate;
@property (nonatomic, weak, readonly) KalDate *selectedDate;

- (id) initWithFrame: (CGRect) frame logic: (KalLogic *) logic wantsTableView: (BOOL) flag;

- (void) markTilesForDates:(NSArray *) dates;
- (void) redrawEntireMonth;
- (void) selectDate: (KalDate *) date;
- (void) slide: (KalGridViewSlideType) slideType; // This method is exposed for the delegate. It should be called *after* the KalLogic has moved to the month specified by the user.

#pragma mark - Appearance Customization

@property (nonatomic, strong) UIImage *gridBackgroundImage;
@property (nonatomic, strong) UIImage *gridDropShadowImage;
@property (nonatomic, strong) UIColor *titleLabelTextColor;
@property (nonatomic, strong) UIColor *weekdayLabelTextColor;

- (UIImage *) leftArrowImageForState: (UIControlState) state;
- (UIImage *) rightArrowImageForState: (UIControlState) state;

- (void) setLeftArrowImage: (UIImage *) image forState: (UIControlState) state;
- (void) setRightArrowImage: (UIImage *) image forState: (UIControlState) state;

@end

@protocol KalViewDelegate <NSObject>

- (void) showPreviousMonth;
- (void) showFollowingMonth;
- (void) didSelectDate: (KalDate *) date;

@end
