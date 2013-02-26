//
//  AgCalendarView.m
//  AgCalendar
//
//  Created by Chris Magnussen on 01.10.11.
//  Copyright 2011 Appgutta DA. All rights reserved.
//

#import "AgCalendarView.h"
#import "TiUtils.h"
#import "Event.h"
#import "SQLDataSource.h"
#import "EventKitDataSource.h"
#import "Kal.h"
#import "KalTileView.h"
#import "KalMonthView.h"
#import "ImageLoader.h"

@implementation AgCalendarView

@synthesize g;

-(KalViewController*)calendar
{
    if (calendar==nil)
    {
        g = [Globals sharedDataManager];
        
        calendar = [[KalViewController alloc] initWithSelectedDate: [NSDate date] wantsTableView: g.showTable];
        calendar.title = @"Theme";

        dataSource = [g.dbSource isEqualToString:@"coredata"] ? [[SQLDataSource alloc] init] : [[EventKitDataSource alloc] init];
        calendar.delegate = self;
        [calendar setDataSource:dataSource];
        [calendar.tableView setDataSource:dataSource];
        [self addSubview:calendar.view];
    }
    return calendar;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.proxy _hasListeners:@"event:clicked"]) {
        NSDictionary *eventDetails;
        if ([g.dbSource isEqualToString:@"coredata"]) {
            Event *event = [dataSource eventAtIndexPath:indexPath];
            eventDetails = [NSDictionary dictionaryWithObjectsAndKeys: 
                                    event.name, @"title", 
                                    event.location, @"location",
                                    event.attendees, @"attendees", 
                                    event.type, @"type",
                                    event.identifier, @"identifier",
                                    event.note, @"note", 
                                    event.startDate, @"startDate", 
                                    event.endDate, @"endDate",
                                    event.organizer, @"organizer",
                            nil];
        } else {
            EKEvent *event = (EKEvent *) [dataSource eventAtIndexPath:indexPath];
            NSString *alarmOffset = [NSString stringWithFormat:@"%f", [[event.alarms objectAtIndex:0] relativeOffset]];
            eventDetails = [NSDictionary dictionaryWithObjectsAndKeys: 
                                    event.title, @"title", 
                                    event.location, @"location",
                                    event.startDate, @"startDate", 
                                    event.endDate, @"endDate",
                                    event.notes, @"notes",
                                    alarmOffset, @"alarmOffset",
                            nil];
        }
        
        NSDictionary *eventSelected = [NSDictionary dictionaryWithObjectsAndKeys: eventDetails, @"event", nil];
		[self.proxy fireEvent:@"event:clicked" withObject:eventSelected];
	}
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    if (calendar!=nil)
    {
        [TiUtils setView:calendar.view positionRect:bounds];
    }
}

-(void)showPreviousMonth
{
    if ([self.proxy _hasListeners:@"month:previous"])
    {
        [self.proxy fireEvent:@"month:previous" withObject:nil];
    }
}

-(void)showFollowingMonth
{
    if ([self.proxy _hasListeners:@"month:next"])
    {
        [self.proxy fireEvent:@"month:next" withObject:nil];
    }
}


// Fires when there's a long press on the date tile.
-(void)didSelectDateLong:(NSDate *)date
{
    if ([self.proxy _hasListeners:@"date:longpress"])
    {
        NSDictionary *returnDate = [NSDictionary dictionaryWithObjectsAndKeys:date, @"date", nil];
        NSDictionary *dateSelected = [NSDictionary dictionaryWithObjectsAndKeys: returnDate, @"event", nil];
        [self.proxy fireEvent:@"date:longpress" withObject:dateSelected];
    }
}

-(void)showPreviousMonth:(id)args
{
    if ([self.proxy _hasListeners:@"month:previous"])
    {
        [self.proxy fireEvent:@"month:previous" withObject:nil];
    }
}

-(void)showFollowingMonth:(id)args
{
    if ([self.proxy _hasListeners:@"month:next"])
    {
        [self.proxy fireEvent:@"month:next" withObject:nil];
    }
}

-(void)didSelectDate:(NSDate *)date
{
    if ([self.proxy _hasListeners:@"date:clicked"])
    {
        NSDictionary *returnDate = [NSDictionary dictionaryWithObjectsAndKeys:date, @"date", nil];
        NSDictionary *dateSelected = [NSDictionary dictionaryWithObjectsAndKeys: returnDate, @"event", nil];
        [self.proxy fireEvent:@"date:clicked" withObject:dateSelected];
    }
}

- (void)showAndSelectToday:(id)args
{
    [[self calendar] showAndSelectDate:[NSDate date]];
}

- (void)selectDate:(id)args
{
    [[self calendar] showAndSelectDate:[args objectAtIndex:0]];
}


-(void)setColor_:(id)color
{
    UIColor *c = [[TiUtils colorValue:color] _color];
    KalViewController *s = [self calendar];
    s.view.backgroundColor = c;
}

-(UIImage*)getImageFromUrl:(NSString*)path
{
	return [[ImageLoader sharedLoader] loadImmediateImage:[TiUtils toURL:path proxy:self.proxy]];
}

-(UIColor*)getColor:(NSString*)color
{
	UIColor *c = [[TiUtils colorValue:color] _color];
    return c;
}

-(void)setTheme_:(id)styling
{
    ENSURE_SINGLE_ARG(styling,NSDictionary);
    
    if ([styling objectForKey:@"tileView"] != nil) {
        KalTileView *tileView = [KalTileView appearance];
        NSDictionary *tile = [styling objectForKey:@"tileView"];
        if ([tile objectForKey:@"background"] != nil) {
            NSDictionary *tileBG = [tile objectForKey:@"background"];
            [tileView setBackgroundImage: [self getImageFromUrl:[tileBG objectForKey:@"normal"]] forState: KalTileViewStateNormal];
            [tileView setBackgroundImage: [self getImageFromUrl:[tileBG objectForKey:@"selected"]] forState: KalTileViewStateSelected];
            [tileView setBackgroundImage: [self getImageFromUrl:[tileBG objectForKey:@"adjacent"]] forState: KalTileViewStateAdjacent];
            [tileView setBackgroundImage: [self getImageFromUrl:[tileBG objectForKey:@"today"]] forState: KalTileViewStateToday];
            [tileView setBackgroundImage: [self getImageFromUrl:[tileBG objectForKey:@"todaySelected"]] forState: KalTileViewStateToday | KalTileViewStateSelected];
            [tileView setReversesShadow:1 forState: KalTileViewStateSelected | KalTileViewStateToday];
            [tileView setShadowColor:[UIColor blackColor] forState:KalTileViewStateNormal];
            [tileView setShadowColor:[UIColor clearColor] forState:KalTileViewStateAdjacent];
        }
        
        if([tile objectForKey:@"text"] != nil) {
            NSDictionary *text = [tile objectForKey:@"text"];
            [tileView setTextColor: [self getColor:[text objectForKey:@"normal"]] forState: KalTileViewStateNormal];
            [tileView setTextColor: [self getColor:[text objectForKey:@"today"]] forState: KalTileViewStateToday];
            [tileView setTextColor: [self getColor:[text objectForKey:@"selected"]] forState: KalTileViewStateSelected];
            [tileView setTextColor: [self getColor:[text objectForKey:@"adjacent"]] forState: KalTileViewStateAdjacent];
        }
    }
    
    if([styling objectForKey:@"monthView"] != nil) {
        KalMonthView *monthView = [KalMonthView appearance];
        NSDictionary *tile = [styling objectForKey:@"monthView"];
        [monthView setBackgroundImage: [self getImageFromUrl:[tile objectForKey:@"backgroundImage"]]];
    }
    
    if([styling objectForKey:@"mainView"] != nil) {
        KalView *view = [KalView appearance];
        NSDictionary *tiles = [styling objectForKey:@"mainView"];
        [view setGridBackgroundImage: [self getImageFromUrl:[tiles objectForKey:@"gridBackgroundImage"]]];
        [view setGridDropShadowImage: [self getImageFromUrl:[tiles objectForKey:@"gridDropShadowImage"]]];
        [view setLeftArrowImage: [self getImageFromUrl:[tiles objectForKey:@"leftArrowImage"]] forState: UIControlStateNormal];
        [view setRightArrowImage: [self getImageFromUrl:[tiles objectForKey:@"rightArrowImage"]] forState: UIControlStateNormal];
        [view setTitleLabelTextColor: [self getColor:[tiles objectForKey:@"titleTextColor"]]];
        [view setWeekdayLabelTextColor: [self getColor:[tiles objectForKey:@"weekdayTextColor"]]];
        
        // Shadows
        if ([tiles objectForKey:@"weekdayShadowOffset"] != nil) {
            NSDictionary *wso = [tiles objectForKey:@"weekdayShadowOffset"];
            view.weekdayShadowColor = [tiles objectForKey:@"weekdayShadowColor"] != nil ? [self getColor:[tiles objectForKey:@"weekdayShadowColor"]] : nil;
            view.weekdayShadowOffset = [tiles objectForKey:@"weekdayShadowOffset"] != nil ? [NSString stringWithFormat:@"{%@, %@}", [wso objectForKey:@"x"], [wso objectForKey:@"y"]] : nil;
        }
        
        if ([tiles objectForKey:@"titleShadowOffset"] != nil) {
            NSDictionary *tso = [tiles objectForKey:@"titleShadowOffset"];
            view.titleShadowColor = [tiles objectForKey:@"titleShadowColor"] != nil ? [self getColor:[tiles objectForKey:@"titleShadowColor"]] : nil;
            view.titleShadowOffset = [tiles objectForKey:@"titleShadowOffset"] != nil ? [NSString stringWithFormat:@"{%@, %@}", [tso objectForKey:@"x"], [tso objectForKey:@"y"]] : nil;
        }
    }
    
    if([styling objectForKey:@"gridView"] != nil) {
        KalGridView *gridView = [KalGridView appearance];
        NSDictionary *tile = [styling objectForKey:@"gridView"];
        [gridView setGridBackgroundColor: [self getColor:[tile objectForKey:@"backgroundColor"]]];
        [gridView setGridBackgroundImage: [self getImageFromUrl:[tile objectForKey:@"backgroundImage"]]];
    }
}

-(void)setShowTable_:(id)value
{
    g = [Globals sharedDataManager];
    BOOL show = [TiUtils boolValue:value];
    g.showTable = show;
}

-(void)setEditable_:(id)value
{
    g = [Globals sharedDataManager];
    BOOL editable = [TiUtils boolValue:value];
    g.viewEditable = editable;
}


@end