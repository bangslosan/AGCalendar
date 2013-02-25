/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <CoreGraphics/CoreGraphics.h>

#import "KalMonthView.h"
#import "KalTileView.h"
#import "KalView.h"
#import "KalDate.h"
#import "KalPrivate.h"

extern const CGSize KalGridViewTileSize;
static NSDateFormatter *KalMonthViewTileAccessibilityFormatter;

@implementation KalMonthView

- (id) initWithFrame: (CGRect) frame
{
	if ((self = [super initWithFrame: frame]))
	{
		self.opaque = NO;
		self.clipsToBounds = YES;
		for (NSUInteger i=0; i<6; i++)
		{
			for (NSUInteger j=0; j<7; j++)
			{
				CGRect r = CGRectMake(j * KalGridViewTileSize.width, i * KalGridViewTileSize.height, KalGridViewTileSize.width, KalGridViewTileSize.height);
				[self addSubview: [[KalTileView alloc] initWithFrame: r]];
			}
		}
	}
	
	return self;
}

-(NSString*)getPathToModuleAsset:(NSString*) fileName
{
	// The module assets are copied to the application bundle into the folder pattern
	// "module/<moduleid>". One way to access these assets is to build a path from the
	// mainBundle of the application.
	
	NSString *pathComponent = [NSString stringWithFormat:@"modules/%@/%@", @"ag.calendar", fileName];
	NSString *result = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:pathComponent];
	
	return result;
}


- (KalTileView *) firstTileOfMonth
{
	NSUInteger index = [self.subviews indexOfObjectPassingTest: ^BOOL(KalTileView *tile, NSUInteger idx, BOOL *stop) {
		return !tile.belongsToAdjacentMonth;
	}];
	
	if (index == NSNotFound)
		return nil;
	else
		return self.subviews[index];
}
- (KalTileView *) tileForDate: (KalDate *) date
{
	NSUInteger index = [self.subviews indexOfObjectPassingTest: ^BOOL(KalTileView *tile, NSUInteger idx, BOOL *stop) {
		return [tile.date isEqual: date];
	}];
	
	NSAssert1(index != NSNotFound, @"Failed to find corresponding tile for date %@", date);
	return self.subviews[index];
}

- (UIImage *) backgroundImage
{
	return _backgroundImage ?: [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_tile.png"]];
}

- (void) drawRect: (CGRect) rect
{
	CGContextDrawTiledImage(UIGraphicsGetCurrentContext(), (CGRect) { CGPointZero, KalGridViewTileSize }, self.backgroundImage.CGImage);
}
- (void) markTilesForDates: (NSArray *) dates
{
	[self.subviews enumerateObjectsUsingBlock: ^(KalTileView *tile, NSUInteger idx, BOOL *stop) {
		tile.marked = [dates containsObject: tile.date];
		NSString *dayString = [KalMonthViewTileAccessibilityFormatter stringFromDate: tile.date.date];
		if (!dayString)
			return;
		
		NSMutableString *helperText = [[NSMutableString alloc] initWithCapacity: 128];
		if (tile.date.isToday)
			[helperText appendFormat:@"%@, ", NSLocalizedString(@"Today", @"Accessibility text for a day tile that represents today")];
		[helperText appendString: dayString];
		if (tile.marked)
			[helperText appendFormat:@", %@", NSLocalizedString(@"Marked", @"Accessibility text for a day tile which is marked with a small dot")];
		tile.accessibilityLabel = helperText;
	}];
}
- (void) showDates: (NSArray *) mainDates leadingAdjacentDates: (NSArray *) leadingAdjacentDates trailingAdjacentDates: (NSArray *) trailingAdjacentDates
{
	int tileCount = 0;
	NSArray *dates[] = { leadingAdjacentDates, mainDates, trailingAdjacentDates };
	
	for (NSUInteger i = 0; i < 3; i++)
	{
		for (KalDate *d in dates[i])
		{
			KalTileView *tile = self.subviews[tileCount];
			[tile resetState];
			tile.date = d;
			if (dates[i] != mainDates)
			{
				tile.type = KalTileViewTypeAdjacent;
			}
			else
			{
				if (d.isToday)
					tile.type = KalTileViewTypeToday;
				else
					tile.type = KalTileViewTypeRegular;
			}
			
			tileCount++;
		}
	}
	
	self.numberOfWeeks = ceilf(tileCount / 7.0);
	[self sizeToFit];
	[self setNeedsDisplay];
}
- (void) sizeToFit
{
	self.height = 1.0 + KalGridViewTileSize.height * self.numberOfWeeks;
}


@end
