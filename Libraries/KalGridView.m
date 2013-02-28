/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <CoreGraphics/CoreGraphics.h>

#import "KalDate.h"
#import "KalGridView.h"
#import "KalLogic.h"
#import "KalMonthView.h"
#import "KalPrivate.h"
#import "KalTileView.h"
#import "KalView.h"

const CGSize KalGridViewTileSize = { 46.0, 44.0 };
static NSString *const KalGridViewSlideAnimationID = @"KalSwitchMonths";

@interface KalGridView ()

@property (nonatomic, readwrite, getter = isTransitioning) BOOL transitioning;
@property (nonatomic, strong) KalTileView *selectedTile;
@property (nonatomic, strong) KalTileView *highlightedTile;
@property (nonatomic, strong) KalLogic *logic;
@property (nonatomic, strong) KalMonthView *frontMonthView;
@property (nonatomic, strong) KalMonthView *backMonthView;

- (void) swapMonthViews;

@end

@implementation KalGridView

- (id) initWithFrame: (CGRect) frame logic: (KalLogic *) theLogic
{
	// MobileCal uses 46px wide tiles, with a 2px inner stroke
	// along the top and right edges. Since there are 7 columns,
	// the width needs to be 46*7 (322px). But the iPhone's screen
	// is only 320px wide, so we need to make the
	// frame extend just beyond the right edge of the screen
	// to accomodate all 7 columns. The 7th day's 2px inner stroke
	// will be clipped off the screen, but that's fine because
	// MobileCal does the same thing.
	frame.size.width = 7 * KalGridViewTileSize.width;
	
	if ((self = [super initWithFrame:frame]))
	{
		self.clipsToBounds = YES;
		self.logic = theLogic;
		
		CGRect monthRect = CGRectMake(0, 0, frame.size.width, frame.size.height);
		self.frontMonthView = [[KalMonthView alloc] initWithFrame: monthRect];
		[self addSubview: self.frontMonthView];
		
		self.backMonthView = [[KalMonthView alloc] initWithFrame: monthRect];
		self.backMonthView.hidden = YES;
		[self addSubview: self.backMonthView];
        
		[self slide: KalGridViewSlideTypeNone];
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

- (UIColor *) gridBackgroundColor
{
	return _gridBackgroundColor ?: [UIColor colorWithRed: 0.63 green: 0.65 blue: 0.68 alpha: 1.0];
}

- (UIImage *) gridBackgroundImage
{
	return _gridBackgroundImage ?: [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_grid_background.png"]];
}

- (void) drawRect: (CGRect) rect
{
	[self.gridBackgroundImage drawInRect: rect];
	[self.gridBackgroundColor setFill];
	
	UIRectFill(CGRectMake(0, self.height - 1.0, self.width, 1.0));
}
- (void) sizeToFit
{
	self.height = self.frontMonthView.height;
}

#pragma mark - Highlighted/Selected Tile

- (void) setHighlightedTile: (KalTileView *) tile
{
	if (_highlightedTile == tile)
		return;
	
	_highlightedTile.highlighted = NO;
	_highlightedTile = tile;
	tile.highlighted = YES;
	[tile setNeedsDisplay];
}
- (void) setSelectedTile: (KalTileView *) tile
{
	if (_selectedTile == tile)
		return;
	
	_selectedTile.selected = NO;
	_selectedTile = tile;
	tile.selected = YES;
	
	[self.delegate didSelectDate: tile.date];
}

#pragma mark - Touches

- (void) receivedTouches: (NSSet *) touches withEvent: (UIEvent *) event
{
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView: self];
	UIView *hitView = [self hitTest: location withEvent: event];
    
	if (!hitView || ![hitView isKindOfClass: [KalTileView class]]) return;
    
	KalTileView *tile = (KalTileView*)hitView;
	if (tile.belongsToAdjacentMonth)
	{
		self.highlightedTile = tile;
	}
	else
	{
		self.highlightedTile = nil;
		self.selectedTile = tile;
	}
}
- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
	[super touchesBegan: touches withEvent: event];
        
    [self performSelector:@selector(selectDateLong)
               withObject:nil
               afterDelay:0.5];
    
	[self receivedTouches:touches withEvent:event];
}

- (void)selectDateLong {
    [_delegate didSelectDateLong:self.selectedTile.date];
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super touchesEnded: touches withEvent: event];
	
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	UIView *hitView = [self hitTest:location withEvent:event];
	
	if ([hitView isKindOfClass: [KalTileView class]])
	{
		KalTileView *tile = (KalTileView*)hitView;
		if (tile.belongsToAdjacentMonth)
		{
			if ([tile.date compare: [KalDate dateWithDate:self.logic.baseDate]] == NSOrderedDescending)
				[self.delegate showFollowingMonth];
			else
				[self.delegate showPreviousMonth];
			
			self.selectedTile = [self.frontMonthView tileForDate: tile.date];
		}
		else
		{
			self.selectedTile = tile;
		}
	}
	
	self.highlightedTile = nil;
}
- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
	[super touchesMoved: touches withEvent: event];
	[self receivedTouches: touches withEvent: event];
}

#pragma mark - Slide Animation

- (void) animationDidStop: (NSString *) animationID finished: (NSNumber *) finished context: (void *) context
{
	self.transitioning = NO;
	self.backMonthView.hidden = YES;
}
- (void) slide: (KalGridViewSlideType) direction
{
	self.transitioning = YES;
	
	[self.backMonthView showDates:self.logic.daysInSelectedMonth leadingAdjacentDates:self.logic.daysInFinalWeekOfPreviousMonth trailingAdjacentDates:self.logic.daysInFirstWeekOfFollowingMonth];
	
	// At this point, the calendar logic has already been advanced or retreated to the
	// following/previous month, so in order to determine whether there are
	// any cells to keep, we need to check for a partial week in the month
	// that is sliding offscreen.
	
	BOOL keepOneRow = (direction == KalGridViewSlideTypeUp && self.logic.daysInFinalWeekOfPreviousMonth.count > 0)
	|| (direction == KalGridViewSlideTypeDown && self.logic.daysInFirstWeekOfFollowingMonth.count > 0);
	[self swapMonthsAndSlide: direction keepOneRow: keepOneRow];
	
	self.selectedTile = [self.frontMonthView firstTileOfMonth];
}
- (void) swapMonthsAndSlide: (KalGridViewSlideType) direction keepOneRow: (BOOL) keepOneRow
{
	self.backMonthView.hidden = NO;
	
	// set initial positions before the slide
	if (direction == KalGridViewSlideTypeUp)
	{
		self.backMonthView.top = keepOneRow
        ? self.frontMonthView.bottom - KalGridViewTileSize.height
        : self.frontMonthView.bottom;
	}
	else if (direction == KalGridViewSlideTypeDown)
	{
		NSUInteger numWeeksToKeep = !!keepOneRow;
		NSInteger numWeeksToSlide = self.backMonthView.numberOfWeeks - numWeeksToKeep;
		self.backMonthView.top = -numWeeksToSlide * KalGridViewTileSize.height;
	}
	else
	{
		self.backMonthView.top = 0;
	}
    
	// trigger the slide animation
	BOOL areAnimationsEnabled = [UIView areAnimationsEnabled];
	
	[UIView beginAnimations: KalGridViewSlideAnimationID context: NULL];
	[UIView setAnimationsEnabled: (direction != KalGridViewSlideTypeNone)];
	[UIView setAnimationDuration: 0.5];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector: @selector(animationDidStop:finished:context:)];
	
	self.frontMonthView.top = -self.backMonthView.top;
	self.backMonthView.top = 0;
    
	self.frontMonthView.alpha = 0;
	self.backMonthView.alpha = 1.0;
	
	self.height = self.backMonthView.height;
	
	[self swapMonthViews];
    
	[UIView commitAnimations];
	[UIView setAnimationsEnabled: areAnimationsEnabled];
}

#pragma mark -

- (KalDate *) selectedDate
{
	return self.selectedTile.date;
}

- (void) markTilesForDates: (NSArray *) dates
{
	[self.frontMonthView markTilesForDates: dates];
}
- (void) selectDate: (KalDate *) date
{
	self.selectedTile = [self.frontMonthView tileForDate: date];
}
- (void) swapMonthViews
{
	KalMonthView *tmp = self.backMonthView;
	self.backMonthView = self.frontMonthView;
	self.frontMonthView = tmp;
	[self exchangeSubviewAtIndex: [self.subviews indexOfObject:self.frontMonthView] withSubviewAtIndex: [self.subviews indexOfObject:self.backMonthView]];
}

@end
