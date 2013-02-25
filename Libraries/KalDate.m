/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalDate.h"
#import "KalPrivate.h"

static KalDate *today;

@interface KalDate ()

@property (nonatomic, readwrite) NSUInteger day;
@property (nonatomic, readwrite) NSUInteger month;
@property (nonatomic, readwrite) NSUInteger year;

@end

@implementation KalDate

- (BOOL)isEqual:(id)anObject
{
	if (![anObject isKindOfClass: [KalDate class]])
		return NO;
	
	KalDate *aDate = anObject;
	return self.hash == aDate.hash;
}
- (BOOL)isToday
{
	return [self isEqual: today];
}

+ (KalDate *) dateWithDate: (NSDate *) date
{
	NSDateComponents *parts = [date cc_componentsForMonthDayAndYear];
	return [KalDate dateWithDay: parts.day month: parts.month year: parts.year];
}
+ (KalDate *)dateWithDay:(NSUInteger)day month:(NSUInteger)month year:(NSUInteger)year
{
	return [[KalDate alloc] initWithDay:day month:month year:year];
}

- (id) initWithDay:(NSUInteger)day month:(NSUInteger)month year:(NSUInteger)year;
{
    if ((self = [super init]))
    {
        self.day = day;
        self.month = month;
        self.year = year;
	}
	
	return self;
}

- (NSComparisonResult)compare:(KalDate *)otherDate
{
	return [@(self.hash) compare:@(otherDate.hash)];
}

- (NSDate *)date
{
	NSDateComponents *components = [[NSDateComponents alloc] init];
	components.day = self.day;
	components.month = self.month;
	components.year = self.year;
	return [[NSCalendar currentCalendar] dateFromComponents: components];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p; %d/%02d/%04d>", NSStringFromClass(self.class), self, self.month, self.day, self.year];
}

- (NSUInteger)hash
{
	return self.year * 10000 + self.month * 100 + self.day;
}

+ (void)cacheTodaysDate
{
	today = [KalDate dateWithDate: [NSDate date]];
}
+ (void)initialize
{
	if (self == [KalDate class])
	{
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cacheTodaysDate) name:UIApplicationSignificantTimeChangeNotification object: nil];
		[self cacheTodaysDate];
	}
}

@end
