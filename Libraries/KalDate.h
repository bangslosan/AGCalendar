/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <Foundation/Foundation.h>

@interface KalDate : NSObject

@property (nonatomic, readonly) NSUInteger day;
@property (nonatomic, readonly) NSUInteger month;
@property (nonatomic, readonly) NSUInteger year;
@property (nonatomic, readonly, getter = isToday) BOOL today;
@property (nonatomic, strong, readonly) NSDate *date;

- (NSComparisonResult) compare: (KalDate *) otherDate;

- (id) initWithDay: (NSUInteger) day month: (NSUInteger) month year: (NSUInteger) year;

+ (KalDate *) dateWithDate: (NSDate *) date;
+ (KalDate *) dateWithDay: (NSUInteger) day month: (NSUInteger) month year: (NSUInteger) year;

@end
