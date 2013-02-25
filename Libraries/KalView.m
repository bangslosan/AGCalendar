/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalView.h"
#import "KalGridView.h"
#import "KalLogic.h"
#import "KalPrivate.h"

static const CGFloat KalViewHeaderHeight = 44.0;
static const CGFloat KalViewMonthLabelHeight = 17.0;

static NSDictionary *KalViewDefaultAppearance;

@interface KalView ()

@property (nonatomic) BOOL hasTitleLabelTextColor;
@property (nonatomic) BOOL hasWeekdayLabelTextColor;
@property (nonatomic) BOOL wantsTableView;
@property (nonatomic, strong) KalLogic *logic;
@property (nonatomic, strong) KalGridView *gridView;
@property (nonatomic, strong) NSArray *weekdayLabels;
@property (nonatomic, strong) NSMutableDictionary *appearanceStorage;
@property (nonatomic, strong) UIButton *previousMonthButton;
@property (nonatomic, strong) UIButton *nextMonthButton;
@property (nonatomic, strong) UIImageView *backgroundView;
@property (nonatomic, strong) UIImageView *shadowView;
@property (nonatomic, strong) UILabel *headerTitleLabel;
@property (nonatomic, strong) UITableView *tableView;

- (void) addSubviewsToHeaderView: (UIView *) headerView;
- (void) addSubviewsToContentView: (UIView *) contentView;
- (void) setHeaderTitleText: (NSString *) text;

@end

@implementation KalView

- (BOOL) isSliding
{
	return self.gridView.transitioning;
}

- (id) initWithFrame: (CGRect) frame
{
	[NSException raise: @"Incomplete Initializer" format: @"KalView must be initialized with a KalLogic. Use the initWithFrame:logic:wantsTableView: method."];
	return nil;
}
- (id) initWithFrame: (CGRect) frame logic: (KalLogic *) theLogic wantsTableView: (BOOL) flag
{
	if ((self = [super initWithFrame: frame]))
	{
		self.logic = theLogic;
		[self.logic addObserver: self forKeyPath: @"localizedMonthAndYear" options: NSKeyValueObservingOptionNew context: NULL];
		self.wantsTableView = flag;
		
		self.autoresizesSubviews = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
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

+(NSString*)getPathToModuleAsset:(NSString*) fileName
{
	// The module assets are copied to the application bundle into the folder pattern
	// "module/<moduleid>". One way to access these assets is to build a path from the
	// mainBundle of the application.
	
	NSString *pathComponent = [NSString stringWithFormat:@"modules/%@/%@", @"ag.calendar", fileName];
	NSString *result = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:pathComponent];
	
	return result;
}

- (KalDate *) selectedDate
{
	return self.gridView.selectedDate;
}

- (void) addSubviewsToContentView: (UIView *) contentView
{
	// Both the tile grid and the list of events will automatically lay themselves
	// out to fit the # of weeks in the currently displayed month.
	// So the only part of the frame that we need to specify is the width.
	CGRect fullWidthAutomaticLayoutFrame = CGRectMake(0, 0, self.width, 0);
	
	// The tile grid (the calendar body)
	self.gridView = [[KalGridView alloc] initWithFrame: fullWidthAutomaticLayoutFrame logic: self.logic];
	self.gridView.delegate = self.delegate;
	[self.gridView addObserver: self forKeyPath: @"frame" options: NSKeyValueObservingOptionNew context: NULL];
	[contentView addSubview: self.gridView];
	
	// The list of events for the selected day
	if (self.wantsTableView)
	{
		self.tableView = [[UITableView alloc] initWithFrame: fullWidthAutomaticLayoutFrame style:UITableViewStylePlain];
		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[contentView addSubview: self.tableView];
		
		// Drop shadow below tile grid and over the list of events for the selected day
		self.shadowView = [[UIImageView alloc] initWithFrame: fullWidthAutomaticLayoutFrame];
		self.shadowView.image = self.gridDropShadowImage;
		self.shadowView.height = self.shadowView.image.size.height;
		[contentView addSubview: self.shadowView];
	}
	
	// Trigger the initial KVO update to finish the contentView layout
	[self.gridView sizeToFit];
}
- (void) addSubviewsToHeaderView: (UIView *) headerView
{
	const CGFloat KalViewChangeMonthButtonWidth = 46;
	const CGFloat KalViewChangeMonthButtonHeight = 30;
	const CGFloat KalViewMonthLabelWidth = 200;
	const CGFloat KalViewHeaderVerticalAdjust = 3;
	
	// Header background gradient
	self.backgroundView = [[UIImageView alloc] initWithImage: self.gridBackgroundImage];
	CGRect imageFrame = headerView.frame;
	imageFrame.origin = CGPointZero;
	self.backgroundView.frame = imageFrame;
	[headerView addSubview: self.backgroundView];
	
	// Create the previous month button on the left side of the view
	CGRect previousMonthButtonFrame = CGRectMake(self.left, KalViewHeaderVerticalAdjust, KalViewChangeMonthButtonWidth, KalViewChangeMonthButtonHeight);
	UIButton *previousMonthButton = [[UIButton alloc] initWithFrame: previousMonthButtonFrame];
	previousMonthButton.accessibilityLabel = NSLocalizedString(@"Previous month", nil);
	previousMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	previousMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	
	[previousMonthButton addTarget: self action: @selector(showPreviousMonth) forControlEvents: UIControlEventTouchUpInside];
	[headerView addSubview: previousMonthButton];
	self.previousMonthButton = previousMonthButton;
	
	// Draw the selected month name centered and at the top of the view
	CGRect monthLabelFrame = CGRectMake(0.5 * (self.width - KalViewMonthLabelWidth), KalViewHeaderVerticalAdjust, KalViewMonthLabelWidth, KalViewMonthLabelHeight);
	self.headerTitleLabel = [[UILabel alloc] initWithFrame:monthLabelFrame];
	self.headerTitleLabel.backgroundColor = [UIColor clearColor];
	self.headerTitleLabel.font = [UIFont boldSystemFontOfSize:22.0];
	self.headerTitleLabel.textAlignment = UITextAlignmentCenter;
	self.headerTitleLabel.textColor = self.titleLabelTextColor;
	self.headerTitleLabel.shadowColor = [UIColor whiteColor];
	self.headerTitleLabel.shadowOffset = CGSizeMake(0, 1);
	
	[self setHeaderTitleText: self.logic.localizedMonthAndYear];
	[headerView addSubview: self.headerTitleLabel];
	
	// Create the next month button on the right side of the view
	CGRect nextMonthButtonFrame = CGRectMake(self.width - KalViewChangeMonthButtonWidth, KalViewHeaderVerticalAdjust, KalViewChangeMonthButtonWidth, KalViewChangeMonthButtonHeight);
	UIButton *nextMonthButton = [[UIButton alloc] initWithFrame: nextMonthButtonFrame];
	nextMonthButton.accessibilityLabel = NSLocalizedString(@"Next month", nil);
	nextMonthButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	nextMonthButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	
	[nextMonthButton addTarget: self action: @selector(showFollowingMonth) forControlEvents: UIControlEventTouchUpInside];
	[headerView addSubview: nextMonthButton];
	self.nextMonthButton = nextMonthButton;
	
	NSMutableOrderedSet *monthButtonStates = [NSMutableOrderedSet orderedSet];
	[monthButtonStates addObjectsFromArray: KalViewDefaultAppearance.allKeys];
	if (self.appearanceStorage)
		[monthButtonStates addObjectsFromArray: self.appearanceStorage.allKeys];
    
	[monthButtonStates enumerateObjectsUsingBlock: ^(NSNumber *_state, NSUInteger idx, BOOL *stop) {
		UIControlState state;
		[_state getValue: &state];
		
		UIImage *leftArrowImage = [self leftArrowImageForState: state];
		if (leftArrowImage) [previousMonthButton setImage: leftArrowImage forState: state];
		
		UIImage *rightArrowImage = [self rightArrowImageForState: state];
		if (rightArrowImage) [nextMonthButton setImage: rightArrowImage forState: state];
	}];
    
	// Add column labels for each weekday (adjusting based on the current locale's first weekday)
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.locale = [NSLocale currentLocale];
	NSArray *weekdayNames = dateFormatter.shortWeekdaySymbols;
	NSArray *fullWeekdayNames = dateFormatter.standaloneWeekdaySymbols;
	NSUInteger firstWeekday = [[NSCalendar currentCalendar] firstWeekday];
	NSUInteger i = firstWeekday - 1;
	NSMutableArray *weekdayLabels = [NSMutableArray arrayWithCapacity: 7];
	for (CGFloat xOffset = 0; xOffset < headerView.width; xOffset += 46.0, i = (i + 1) % 7)
	{
		CGRect weekdayFrame = CGRectMake(xOffset, 30, 46.0, KalViewHeaderHeight - 29.0);
		UILabel *weekdayLabel = [[UILabel alloc] initWithFrame:weekdayFrame];
		weekdayLabel.backgroundColor = [UIColor clearColor];
		weekdayLabel.font = [UIFont boldSystemFontOfSize:10];
		weekdayLabel.textAlignment = UITextAlignmentCenter;
		weekdayLabel.textColor = self.weekdayLabelTextColor;
		weekdayLabel.shadowColor = [UIColor whiteColor];
		weekdayLabel.shadowOffset = CGSizeMake(0, 1.0);
		weekdayLabel.text = weekdayNames[i];
		
		[weekdayLabel setAccessibilityLabel: fullWeekdayNames[i]];
		[headerView addSubview: weekdayLabel];
		[weekdayLabels addObject: weekdayLabel];
	}
	self.weekdayLabels = weekdayLabels;
}
- (void) dealloc
{
	[self.logic removeObserver: self forKeyPath: @"localizedMonthAndYear"];
	[self.gridView removeObserver: self forKeyPath: @"frame"];
}

- (void) markTilesForDates: (NSArray *) dates
{
	[self.gridView markTilesForDates: dates];
}
+ (void) initialize
{
	if (self == [KalView class])
	{
		KalViewDefaultAppearance = @{
        @(UIControlStateNormal): @{
        @"leftArrowImage": [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_left_arrow.png"]],
        @"rightArrowImage": [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_right_arrow.png"]]
        }
		};
	}
}
- (void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object change: (NSDictionary *) change context: (void *) context
{
	if ([object isEqual: self.gridView] && [keyPath isEqualToString: @"frame"])
	{
		/* Animate tableView filling the remaining space after the
		 * gridView expanded or contracted to fit the # of weeks
		 * for the month that is being displayed.
		 *
		 * This observer method will be called when gridView's height
		 * changes, which we know to occur inside a Core Animation
		 * transaction. Hence, when I set the "frame" property on
		 * tableView here, I do not need to wrap it in a
		 * [UIView beginAnimations:context:].
		 */
		CGFloat gridBottom = self.gridView.top + self.gridView.height;
		CGRect frame = self.tableView.frame;
		frame.origin.y = gridBottom;
		frame.size.height = self.tableView.superview.height - gridBottom;
		self.tableView.frame = frame;
		self.shadowView.top = gridBottom;
	}
	else if ([keyPath isEqualToString:@"localizedMonthAndYear"])
	{
		[self setHeaderTitleText: change[NSKeyValueChangeNewKey]];
	}
	else
	{
		[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
	}
}
- (void) redrawEntireMonth
{
	[self slide: KalGridViewSlideTypeNone];
}
- (void) selectDate: (KalDate *) date
{
	[self.gridView selectDate: date];
}
- (void) setDelegate: (id <KalViewDelegate>) aDelegate
{
	if (_delegate == aDelegate)
		return;
	
	[self.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	_delegate = aDelegate;
    
	UIView *headerView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.frame.size.width, KalViewHeaderHeight)];
	headerView.backgroundColor = [UIColor grayColor];
	[self addSubviewsToHeaderView: headerView];
	[self addSubview: headerView];
    
	UIView *contentView = [[UIView alloc] initWithFrame: CGRectMake(0, KalViewHeaderHeight, self.frame.size.width, self.frame.size.height - KalViewHeaderHeight)];
	contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	[self addSubviewsToContentView: contentView];
	[self addSubview: contentView];
}
- (void) setHeaderTitleText: (NSString *) text
{
	self.headerTitleLabel.text = text;
	[self.headerTitleLabel sizeToFit];
	
	self.headerTitleLabel.left = floorf(0.5 * (self.width - self.headerTitleLabel.width));
}
- (void) showFollowingMonth
{
	if (!self.gridView.transitioning)
		[self.delegate showFollowingMonth];
}
- (void) showPreviousMonth
{
	if (!self.gridView.transitioning)
		[self.delegate showPreviousMonth];
}
- (void) slide: (KalGridViewSlideType) slideType
{
	[self.gridView slide: slideType];
}

#pragma mark - Appearance Customization

- (id) valueForAppearanceKey: (NSString *) key forState: (UIControlState) state
{
	// Returns the attribtue with the highest number of common bits with `state`.
	__block id bestValue = nil;
	__block NSInteger maximumNumberOfBits = -1;
	
	void (^block)(id, id, BOOL*) = ^(NSNumber *_storedState, NSDictionary *stateStorage, BOOL *stop) {
		if (!stateStorage[key])
			return;
		
		UIControlState storedState;
		[_storedState getValue: &storedState];
		
		if ((storedState & state) != storedState)
			return;
		
		NSInteger numberOfBits;
		for (numberOfBits = 0; storedState; numberOfBits++)
			storedState &= storedState - 1;
		
		if (numberOfBits <= maximumNumberOfBits)
			return;
		
		// Best resule so far
		maximumNumberOfBits = numberOfBits;
		bestValue = stateStorage[key];
	};
	
	if (self.appearanceStorage)
		[self.appearanceStorage enumerateKeysAndObjectsUsingBlock: block];
	
	if (!bestValue)
		[KalViewDefaultAppearance enumerateKeysAndObjectsUsingBlock: block];
	
	if (bestValue == [NSNull null])
		return nil;
	
	return bestValue;
}

- (UIColor *) titleLabelTextColor
{
	if (self.hasTitleLabelTextColor)
		return self.headerTitleLabel.textColor;
	
	return [UIColor colorWithPatternImage: [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_header_text_fill.png"]]];
}
- (UIColor *) weekdayLabelTextColor
{
	if (self.hasWeekdayLabelTextColor)
		return [self.weekdayLabels[0] textColor];
	
	return [UIColor colorWithWhite: 0.298 alpha: 1];
}

- (UIImage *) gridBackgroundImage
{
	return self.backgroundView.image ?: [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_grid_background.png"]];
}
- (UIImage *) gridDropShadowImage
{
	return self.shadowView.image ?: [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_grid_shadow.png"]];
}
- (UIImage *) leftArrowImageForState: (UIControlState) state
{
	return [self valueForAppearanceKey: @"leftArrowImage" forState: state];
}
- (UIImage *) rightArrowImageForState: (UIControlState) state
{
	return [self valueForAppearanceKey: @"rightArrowImage" forState: state];
}

- (void) setGridBackgroundImage: (UIImage *) gridBackgroundImage
{
	self.backgroundView.image = gridBackgroundImage;
}
- (void) setGridDropShadowImage: (UIImage *) gridDropShadowImage
{
	self.shadowView.image = gridDropShadowImage;
}
- (void) setLeftArrowImage: (UIImage *) image forState: (UIControlState) state
{
	[self setValue: image forAppearanceKey: @"leftArrowImage" forState: state];
	[self.previousMonthButton setImage: image forState: state];
}
- (void) setRightArrowImage: (UIImage *) image forState: (UIControlState) state
{
	[self setValue: image forAppearanceKey: @"rightArrowImage" forState: state];
	[self.nextMonthButton setImage: image forState: state];
}
- (void) setTitleLabelTextColor: (UIColor *) titleLabelTextColor
{
	self.hasTitleLabelTextColor = YES;
	self.headerTitleLabel.textColor = titleLabelTextColor;
}
- (void) setValue: (id) value forAppearanceKey: (NSString *) key forState: (UIControlState) state
{
	if (!self.appearanceStorage)
		self.appearanceStorage = [NSMutableDictionary dictionary];
	
	id stateKey = @(state);
	NSMutableDictionary *stateStorage = self.appearanceStorage[stateKey];
	
	if (!stateStorage)
	{
		stateStorage = [NSMutableDictionary dictionary];
		self.appearanceStorage[stateKey] = stateStorage;
	}
	
	if (value)
		stateStorage[key] = value;
	else
		[stateStorage removeObjectForKey: key];
}
- (void) setWeekdayLabelTextColor: (UIColor *) color
{
	self.hasWeekdayLabelTextColor = YES;
	[self.weekdayLabels makeObjectsPerformSelector: @selector(setTextColor:) withObject: color];
}

@end
