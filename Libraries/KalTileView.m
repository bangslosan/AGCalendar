/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalDate.h"
#import "KalPrivate.h"
#import "KalTileView.h"

extern const CGSize KalGridViewTileSize;
static NSDictionary *KalTileViewDefaultAppearance;

@interface KalTileView ()

@property (nonatomic) CGPoint origin;
@property (nonatomic, strong) NSMutableDictionary *appearanceStorage;

@end

@implementation KalTileView

- (BOOL) belongsToAdjacentMonth
{
	return self.type == KalTileViewTypeAdjacent;
}
- (BOOL) isToday
{
	return self.type == KalTileViewTypeToday;
}

- (id) initWithFrame: (CGRect) frame
{
	if ((self = [super initWithFrame: frame]))
	{
		self.accessibilityTraits = UIAccessibilityTraitButton;
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = NO;
		self.isAccessibilityElement = YES;
		self.opaque = NO;
		self.origin = frame.origin;
		
		[self resetState];
	}
	
	return self;
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

- (KalTileViewState) state
{
	KalTileViewState state = 0;
	
	if (self.belongsToAdjacentMonth)
		state |= KalTileViewStateAdjacent;
	
	if (self.isToday)
		state |= KalTileViewStateToday;
	
	if (self.selected)
		state |= KalTileViewStateSelected;
	
	if (self.highlighted)
		state |= KalTileViewStateHighlighted;
	
	if (self.marked)
		state |= KalTileViewStateMarked;
	
	return state;
};

- (NSInteger) getWeekOfDate:(KalDate*)thisDate
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:thisDate.day];
    [components setMonth:thisDate.month];
    [components setYear:thisDate.year];
    NSDate *newDate = [cal dateFromComponents:components];
    
    NSDateComponents *comp = [cal components:NSYearForWeekOfYearCalendarUnit |NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekdayCalendarUnit fromDate:newDate];
    NSInteger week = [comp week];
    
    [comp setWeekday:1];
    NSDate *firstDay = [cal dateFromComponents:comp];
    
    if ([firstDay isEqualToDate:newDate]) {
        return week;
    } else {
        return 0;
    }
}

- (void) drawRect: (CGRect) rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGFloat fontSize = 24.0;
	UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
	CGContextSelectFont(ctx, [font.fontName cStringUsingEncoding:NSUTF8StringEncoding], fontSize, kCGEncodingMacRoman);
    
	CGContextTranslateCTM(ctx, 0, KalGridViewTileSize.height);
	CGContextScaleCTM(ctx, 1, -1);
    
	KalTileViewState state = self.state;
	UIColor *textColor = [self textColorForState: state];
	UIColor *shadowColor = [self shadowColorForState: state];
	UIImage *backgroundImage = [self backgroundImageForState: state];
	UIImage *markerImage = [self markerImageForState: state];
	
	[backgroundImage drawInRect: CGRectMake(0, -1, KalGridViewTileSize.width + 1, KalGridViewTileSize.height + 1)];
	
	if (self.marked)
		[markerImage drawInRect: CGRectMake(21.0, 5.0, 4.0, 5.0)];
    
        
    NSInteger week = [self getWeekOfDate:self.date];
    
	NSInteger n = self.date.day;
	NSString *dayText = [NSString stringWithFormat: @"%lu", (unsigned long) n];
    
    if (week != 0) {
        UIColor *weekColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        NSString *weekNum = [NSString stringWithFormat: @"%lu", (unsigned long) week];
        const char *wek = [weekNum cStringUsingEncoding: NSUTF8StringEncoding];
        
        CGSize weekSize = [weekNum sizeWithFont:[UIFont systemFontOfSize:5.0]];
        CGFloat textX = roundf(0.5 * (KalGridViewTileSize.width - weekSize.width))-19;
        CGFloat textY = roundf(0.5 * (KalGridViewTileSize.height - weekSize.height))+12;
        textX += (week >= 10) ? 1 : 0;
        
        [weekColor setFill];
        CGContextSetFontSize(ctx, 11.0);
        CGContextShowTextAtPoint(ctx, textX, textY, wek, week >= 10 ? 2 : 1);
        CGContextSetFontSize(ctx, fontSize);
    }
    
	const char *day = [dayText cStringUsingEncoding: NSUTF8StringEncoding];
	CGSize textSize = [dayText sizeWithFont: font];
	
	CGFloat textX = roundf(0.5 * (KalGridViewTileSize.width - textSize.width));
	CGFloat textY = 6.0 + roundf(0.5 * (KalGridViewTileSize.height - textSize.height));
	if (shadowColor)
	{
		[shadowColor setFill];
		NSInteger sign = [self reversesShadowForState: state] ? -1 : 1;
		CGContextShowTextAtPoint(ctx, textX + self.shadowOffset.width, textY - sign * self.shadowOffset.height, day, n >= 10 ? 2 : 1);
        //		textY += 1.0;
	}
	
	[textColor setFill];
	CGContextShowTextAtPoint(ctx, textX, textY, day, n >= 10 ? 2 : 1);
    
	if (self.highlighted)
	{
		[[UIColor colorWithWhite: 0.25 alpha: 0.3] setFill];
		CGContextFillRect(ctx, CGRectMake(0, 0, KalGridViewTileSize.width, KalGridViewTileSize.height));
	}
}
+ (void) initialize
{
	if (self == [KalTileView class])
	{
		KalTileViewDefaultAppearance = @{
        @(KalTileViewStateAdjacent): @{
            @"markerImage": [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_marker_dim.png"]],
            @"shadowColor": [NSNull null],
            @"textColor": [UIColor colorWithPatternImage: [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_tile_dim_text_fill.png"]]]
        },
        @(KalTileViewStateNormal): @{
            @"markerImage": [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_marker.png"]],
            @"shadowColor": [UIColor whiteColor],
            @"textColor": [UIColor colorWithPatternImage: [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_tile_text_fill.png"]]]
        },
        @(KalTileViewStateSelected): @{
            @"backgroundImage": [[UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_tile_selected.png"]] resizableImageWithCapInsets: UIEdgeInsetsMake(0, 1, 0, 1)],
            @"markerImage": [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_marker_selected.png"]],
            @"shadowColor": [UIColor blackColor],
            @"textColor": [UIColor whiteColor]
        },
        @(KalTileViewStateToday): @{
            @"backgroundImage": [[UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_tile_today.png"]] resizableImageWithCapInsets: UIEdgeInsetsMake(0, 6, 0, 6)],
            @"markerImage": [UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_marker_today.png"]],
            @"shadowColor": [UIColor blackColor],
            @"textColor": [UIColor whiteColor]
        },
        @(KalTileViewStateToday | KalTileViewStateSelected): @{
            @"backgroundImage": [[UIImage imageWithContentsOfFile:[self getPathToModuleAsset:@"kal_tile_today_selected.png"]] resizableImageWithCapInsets: UIEdgeInsetsMake(0, 6, 0, 6)],
            @"textColor": [UIColor whiteColor]
        }
		};
	}
}
- (void) resetState
{
	// Realign to the grid
	CGRect frame = self.frame;
	frame.origin = self.origin;
	frame.size = KalGridViewTileSize;
	self.frame = frame;
    
	self.date = nil;
	self.highlighted = NO;
	self.marked = NO;
	self.selected = NO;
	self.shadowOffset = CGSizeMake(0, 1);
	self.type = KalTileViewTypeRegular;
}
- (void) setDate: (KalDate *) aDate
{
	if (_date == aDate)
		return;
    
	_date = aDate;
	[self setNeedsDisplay];
}
- (void) setHighlighted: (BOOL) highlighted
{
	if (_highlighted == highlighted)
		return;
	
	_highlighted = highlighted;
	[self setNeedsDisplay];
}
- (void) setMarked: (BOOL) marked
{
	if (_marked == marked)
		return;
    
	_marked = marked;
	[self setNeedsDisplay];
}
- (void) setSelected:(BOOL)selected
{
	if (_selected == selected)
		return;
	
	// Workaround since I cannot draw outside of the frame in drawRect:
	if (!self.isToday)
	{
		CGRect rect = self.frame;
		if (selected)
		{
			rect.origin.x--;
			rect.size.width++;
			rect.size.height++;
		}
		else
		{
			rect.origin.x++;
			rect.size.width--;
			rect.size.height--;
		}
		self.frame = rect;
	}
	
	_selected = selected;
	[self setNeedsDisplay];
}
- (void) setType: (KalTileViewType) tileType
{
	if (_type == tileType)
		return;
    
	// Workaround since I cannot draw outside of the frame in drawRect:
	CGRect rect = self.frame;
	if (tileType == KalTileViewTypeToday)
	{
		rect.origin.x--;
		rect.size.width++;
		rect.size.height++;
	}
	else if (_type == KalTileViewTypeToday)
	{
		rect.origin.x++;
		rect.size.width--;
		rect.size.height--;
	}
	self.frame = rect;
    
	_type = tileType;
	[self setNeedsDisplay];
}

#pragma mark - Appearance Customization

- (id) valueForAppearanceKey: (NSString *) key forState: (KalTileViewState) state
{
	// Returns the attribtue with the highest number of common bits with `state`.
	__block id bestValue = nil;
	__block NSInteger maximumNumberOfBits = -1;
	
	void (^block)(id, id, BOOL*) = ^(NSNumber *_storedState, NSDictionary *stateStorage, BOOL *stop) {
		if (!stateStorage[key])
			return;
		
		KalTileViewState storedState;
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
		[KalTileViewDefaultAppearance enumerateKeysAndObjectsUsingBlock: block];
	
	if (bestValue == [NSNull null])
		return nil;
	
	return bestValue;
}

- (NSUInteger) reversesShadowForState: (KalTileViewState) state
{
	return [[self valueForAppearanceKey: @"reversesShadow" forState: state] boolValue];
}

- (UIColor *) textColorForState: (KalTileViewState) state
{
	return [self valueForAppearanceKey: @"textColor" forState: state];
}
- (UIColor *) shadowColorForState: (KalTileViewState) state
{
	return [self valueForAppearanceKey: @"shadowColor" forState: state];
}

- (UIImage *) backgroundImageForState: (KalTileViewState) state
{
	return [self valueForAppearanceKey: @"backgroundImage" forState: state];
}
- (UIImage *) markerImageForState: (KalTileViewState) state
{
	return [self valueForAppearanceKey: @"markerImage" forState: state];
}

- (void) setBackgroundImage: (UIImage *) image forState: (KalTileViewState) state
{
	[self setValue: image forAppearanceKey: @"backgroundImage" forState: state];
}
- (void) setMarkerImage: (UIImage *) image forState: (KalTileViewState) state
{
	[self setValue: image forAppearanceKey: @"markerImage" forState: state];
}
- (void) setReversesShadow: (NSUInteger) flag forState: (KalTileViewState) state
{
	[self setValue: @(flag) forAppearanceKey: @"reversesShadow" forState: state];
}
- (void) setShadowColor: (UIColor *) color forState: (KalTileViewState) state
{
	[self setValue: color forAppearanceKey: @"shadowColor" forState: state];
}
- (void) setTextColor: (UIColor *) color forState: (KalTileViewState) state
{
	[self setValue: color forAppearanceKey: @"textColor" forState: state];
}
- (void) setValue: (id) value forAppearanceKey: (NSString *) key forState: (KalTileViewState) state
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

@end
