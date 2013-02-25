/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalDataSource.h"
#import "KalDate.h"
#import "KalLogic.h"
#import "KalPrivate.h"
#import "KalViewController.h"

NSString *const KalDataSourceChangedNotification = @"KalDataSourceChangedNotification";

@interface KalViewController ()

@property (nonatomic) BOOL wantsTableView;
@property (nonatomic, strong) KalLogic *logic;
@property (nonatomic, strong, readwrite) NSDate *initialDate;
@property (nonatomic, strong, readwrite) NSDate *selectedDate;
@property (nonatomic, strong, readwrite) UITableView *tableView;

- (KalView *) calendarView;

@end

@implementation KalViewController

- (id) init
{
  return [self initWithSelectedDate: [NSDate date] wantsTableView: YES];
}
- (id) initWithSelectedDate: (NSDate *) date wantsTableView: (BOOL) flag
{
  if ((self = [super init]))
  {
    self.logic = [[KalLogic alloc] initWithDate: date];
    self.initialDate = date;
    self.selectedDate = date;
    self.wantsTableView = flag;
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(significantTimeChangeOccurred) name: UIApplicationSignificantTimeChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reloadData) name: KalDataSourceChangedNotification object:nil];
  }
  
  return self;
}

- (KalView *) calendarView
{
  return (KalView *) self.view;
}

- (NSDate *) selectedDate
{
  return self.calendarView.selectedDate.date;
}

- (void) clearTable
{
  [self.dataSource removeAllItems];
  [self.tableView reloadData];
}
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self name: UIApplicationSignificantTimeChangeNotification object: nil];
  [[NSNotificationCenter defaultCenter] removeObserver: self name: KalDataSourceChangedNotification object: nil];
}
- (void) reloadData
{
  [self.dataSource presentingDatesFrom: self.logic.fromDate to: self.logic.toDate delegate: self];
}
- (void) significantTimeChangeOccurred
{
  [self.calendarView slide: KalGridViewSlideTypeNone];
  [self reloadData];
}
- (void) showAndSelectDate: (NSDate *) date
{
  if (self.calendarView.isSliding)
    return;
  
  [self.logic moveToMonthForDate: date];
  [self.calendarView slide: KalGridViewSlideTypeNone];
  
  [self.calendarView selectDate: [KalDate dateWithDate: date]];
  [self reloadData];
}

#pragma mark Kal View Delegate

- (void) didSelectDate: (KalDate *) _date
{
  NSDate *date = _date.date;
  self.selectedDate = date;
  [self clearTable];
  
  NSDate *from = [date cc_dateByMovingToBeginningOfDay];
  NSDate *to = [date cc_dateByMovingToEndOfDay];
  [self.dataSource loadItemsFromDate: from toDate: to];
  
  [self.tableView reloadData];
  [self.tableView flashScrollIndicators];
}
- (void) showFollowingMonth
{
  [self clearTable];
  [self.logic advanceToFollowingMonth];
  [self.calendarView slide: KalGridViewSlideTypeUp];
  [self reloadData];
}
- (void) showPreviousMonth
{
  [self clearTable];
  [self.logic retreatToPreviousMonth];
  [self.calendarView slide: KalGridViewSlideTypeDown];
  [self reloadData];
}

#pragma mark Kal Data Source Callbacks

- (void) loadedDataSource: (id <KalDataSource>) aDataSource
{
  NSArray *markedDates = [aDataSource markedDatesFrom: self.logic.fromDate to: self.logic.toDate];
  NSMutableArray *dates = [markedDates mutableCopy];
  NSUInteger i, count = dates.count;
  for (i = 0; i < count; i++)
    dates[i] = [KalDate dateWithDate: dates[i]];
  
  [self.calendarView markTilesForDates: dates];
  [self didSelectDate: self.calendarView.selectedDate];
}

#pragma mark View Lifecycle

- (void) didReceiveMemoryWarning
{
  // Must be done before calling super
  self.initialDate = self.selectedDate;
  
  [super didReceiveMemoryWarning];
}
- (void) loadView
{
  if (!self.title) self.title = @"Calendar";
  
  KalView *kalView = [[KalView alloc] initWithFrame: [UIScreen mainScreen].bounds logic: self.logic wantsTableView: self.wantsTableView];
  kalView.delegate = self;
  
  self.view = kalView;
  self.tableView = kalView.tableView;
  [kalView selectDate: [KalDate dateWithDate: self.initialDate]];
  [self reloadData];
}
- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];
  [self.tableView flashScrollIndicators];
}
- (void) viewDidUnload
{
  self.tableView = nil;
  [super viewDidUnload];
}
- (void) viewWillAppear: (BOOL) animated
{
  [super viewWillAppear: animated];
  [self.tableView reloadData];
}

@end
