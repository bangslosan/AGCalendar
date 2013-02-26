/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>
#import "KalView.h"       // for the KalViewDelegate protocol
#import "KalDataSource.h" // for the KalDataSourceCallbacks protocol

@class KalLogic, KalDate;

/*
 *    KalViewController
 *    ------------------------
 *
 *  KalViewController automatically creates both the calendar view
 *  and the events table view for you. The only thing you need to provide
 *  is a KalDataSource so that the calendar system knows which days to
 *  mark with a dot and which events to list under the calendar when a certain
 *  date is selected (just like in Apple's calendar app).
 *
 */

@interface KalViewController : UIViewController <KalViewDelegate, KalDataSourceCallbacks>

@property (nonatomic, strong, readonly) NSDate *selectedDate;
@property (nonatomic, strong) id <KalDataSource> dataSource;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic) id<UITableViewDelegate> delegate;

- (id) initWithSelectedDate: (NSDate *) selectedDate wantsTableView: (BOOL) flag; 
- (void) reloadData; 
- (void) showAndSelectDate: (NSDate *) date;

@end
