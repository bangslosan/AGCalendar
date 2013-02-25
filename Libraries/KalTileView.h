/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, KalTileViewType)
{
	KalTileViewTypeRegular   = 0,
	KalTileViewTypeAdjacent  = 1 << 0,
	KalTileViewTypeToday     = 1 << 1,
};

typedef NS_OPTIONS(NSUInteger, KalTileViewState)
{
	KalTileViewStateNormal      = 0,
	KalTileViewStateAdjacent    = 1 << 0,
	KalTileViewStateToday       = 1 << 1,
	KalTileViewStateSelected    = 1 << 2,
	KalTileViewStateHighlighted = 1 << 3,
	KalTileViewStateMarked      = 1 << 4
};

@class KalDate;

@interface KalTileView : UIView

@property (nonatomic) BOOL belongsToAdjacentMonth;
@property (nonatomic) KalTileViewState state;
@property (nonatomic) KalTileViewType type;
@property (nonatomic, getter = isHighlighted) BOOL highlighted;
@property (nonatomic, getter = isMarked) BOOL marked;
@property (nonatomic, getter = isSelected) BOOL selected;
@property (nonatomic, getter = isToday) BOOL today;
@property (nonatomic, strong) KalDate *date;

- (void) resetState;

#pragma mark - Appearance Customization

@property (nonatomic) CGSize shadowOffset;

- (NSUInteger) reversesShadowForState: (KalTileViewState) state;

- (UIColor *) textColorForState: (KalTileViewState) state;
- (UIColor *) shadowColorForState: (KalTileViewState) state;

- (UIImage *) backgroundImageForState: (KalTileViewState) state;
- (UIImage *) markerImageForState: (KalTileViewState) state;

- (void) setBackgroundImage: (UIImage *) image forState: (KalTileViewState) state; // An image that will be drawn at size {47, 45}
- (void) setMarkerImage: (UIImage *) image forState: (KalTileViewState) state; // An image that will be drawn at size {4, 5}
- (void) setReversesShadow: (NSUInteger) flag forState: (KalTileViewState) state; // NSInteger instead of BOOL, in order to comply with the UIAppearanceContainer constraints.
- (void) setShadowColor: (UIColor *) color forState: (KalTileViewState) state;
- (void) setTextColor: (UIColor *) color forState: (KalTileViewState) state;

@end
