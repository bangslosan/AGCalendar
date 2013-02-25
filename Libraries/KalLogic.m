/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalLogic.h"
#import "KalDate.h"
#import "KalPrivate.h"

static NSDateFormatter *KalLogicMonthAndYearFormatter;

@interface KalLogic ()

@property (nonatomic, strong, readwrite) NSDate *fromDate;
@property (nonatomic, strong, readwrite) NSDate *toDate;
@property (nonatomic, strong, readwrite) NSArray *daysInSelectedMonth;
@property (nonatomic, strong, readwrite) NSArray *daysInFinalWeekOfPreviousMonth;
@property (nonatomic, strong, readwrite) NSArray *daysInFirstWeekOfFollowingMonth;

- (NSUInteger) numberOfDaysInPreviousPartialWeek;
- (NSUInteger) numberOfDaysInFollowingPartialWeek;

- (void) recalculateVisibleDays;

@end

@implementation KalLogic

- (id) init
{
	return [self initWithDate: [NSDate date]];
}
- (id) initWithDate: (NSDate *) date
{
	if ((self = [super init]))
	{
		[self moveToMonthForDate:date];
	}
	
	return self;
}

+ (NSSet *) keyPathsForValuesAffectingLocalizedMonthAndYear
{
	return [NSSet setWithObject: @"baseDate"];
}

- (NSString *) localizedMonthAndYear
{
	return [KalLogicMonthAndYearFormatter stringFromDate: self.baseDate];
}

- (void) advanceToFollowingMonth
{
	[self moveToMonthForDate: [self.baseDate cc_dateByMovingToFirstDayOfTheFollowingMonth]];
}
+ (void) initialize
{
	if (self == [KalLogic class])
	{
		KalLogicMonthAndYearFormatter = [[NSDateFormatter alloc] init];
		KalLogicMonthAndYearFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate: @"LLLL yyyy" options: kNilOptions locale: [NSLocale currentLocale]];
	}
}
- (void) moveToMonthForDate: (NSDate *) date
{
	self.baseDate = [date cc_dateByMovingToFirstDayOfTheMonth];
	[self recalculateVisibleDays];
}
- (void) retreatToPreviousMonth
{
	[self moveToMonthForDate: [self.baseDate cc_dateByMovingToFirstDayOfThePreviousMonth]];
}

#pragma mark Low-level implementation details

- (NSUInteger) numberOfDaysInFollowingPartialWeek
{
	NSDateComponents *c = [self.baseDate cc_componentsForMonthDayAndYear];
	c.day = [self.baseDate cc_numberOfDaysInMonth];
	
	NSDate *lastDayOfTheMonth = [[NSCalendar currentCalendar] dateFromComponents: c];
	return 7 - [lastDayOfTheMonth cc_weekday];
}
- (NSUInteger) numberOfDaysInPreviousPartialWeek
{
	return [self.baseDate cc_weekday] - 1;
}

- (NSArray *) calculateDaysInFinalWeekOfPreviousMonth
{
	NSMutableArray *days = [NSMutableArray array];
	
	NSDate *beginningOfPreviousMonth = [self.baseDate cc_dateByMovingToFirstDayOfThePreviousMonth];
	NSUInteger n = [beginningOfPreviousMonth cc_numberOfDaysInMonth];
	NSUInteger numPartialDays = [self numberOfDaysInPreviousPartialWeek];
	NSDateComponents *c = [beginningOfPreviousMonth cc_componentsForMonthDayAndYear];
	for (NSUInteger i = n - (numPartialDays - 1); i < n + 1; i++)
		[days addObject: [KalDate dateWithDay: i month: c.month year: c.year]];
    
	return days;
}
- (NSArray *) calculateDaysInFirstWeekOfFollowingMonth
{
	NSMutableArray *days = [NSMutableArray array];
	
	NSDateComponents *c = [[self.baseDate cc_dateByMovingToFirstDayOfTheFollowingMonth] cc_componentsForMonthDayAndYear];
	NSUInteger numPartialDays = [self numberOfDaysInFollowingPartialWeek];
	
	for (NSUInteger i = 1; i < numPartialDays + 1; i++)
		[days addObject:[KalDate dateWithDay:i month:c.month year:c.year]];
	
	return days;
}
- (NSArray *) calculateDaysInSelectedMonth
{
	NSMutableArray *days = [NSMutableArray array];
    
	NSUInteger numDays = [self.baseDate cc_numberOfDaysInMonth];
	NSDateComponents *c = [self.baseDate cc_componentsForMonthDayAndYear];
	for (NSUInteger i = 1; i < numDays + 1; i++)
		[days addObject:[KalDate dateWithDay:i month:c.month year:c.year]];
    
	return days;
}

- (void) recalculateVisibleDays
{
	self.daysInSelectedMonth = [self calculateDaysInSelectedMonth];
	self.daysInFinalWeekOfPreviousMonth = [self calculateDaysInFinalWeekOfPreviousMonth];
	self.daysInFirstWeekOfFollowingMonth = [self calculateDaysInFirstWeekOfFollowingMonth];
	
	KalDate *from = self.daysInFinalWeekOfPreviousMonth.count > 0
    ? self.daysInFinalWeekOfPreviousMonth[0]
    : self.daysInSelectedMonth[0];
	self.fromDate = [[from date] cc_dateByMovingToBeginningOfDay];
	
	KalDate *to = self.daysInFirstWeekOfFollowingMonth.count > 0
    ? self.daysInFirstWeekOfFollowingMonth.lastObject
    : self.daysInSelectedMonth.lastObject;
	self.toDate = [[to date] cc_dateByMovingToEndOfDay];
}

@end
