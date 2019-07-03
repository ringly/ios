#import "RLYPeripheralEnumerations.h"

#pragma mark - Battery State
NSString *RLYPeripheralBatteryStateToString(RLYPeripheralBatteryState state)
{
    switch (state)
    {
        case RLYPeripheralBatteryStateError:
            return @"Error";
        case RLYPeripheralBatteryStateCharged:
            return @"Charged";
        case RLYPeripheralBatteryStateCharging:
            return @"Charging";
        case RLYPeripheralBatteryStateNotCharging:
            return @"Not Charging";
    }
}

#pragma mark - Pair State
NSString *RLYPeripheralPairStateToString(RLYPeripheralPairState pairState)
{
    switch (pairState)
    {
        case RLYPeripheralPairStatePaired:
            return @"Paired";
        
        case RLYPeripheralPairStateAssumedPaired:
            return @"Assumed Paired";
        
        case RLYPeripheralPairStateUnpaired:
            return @"Unpaired";
        
        case RLYPeripheralPairStateAssumedUnpaired:
            return @"Assumed Unpaired";
    }
}

BOOL RLYPeripheralPairStateIsPaired(RLYPeripheralPairState pairState)
{
    switch (pairState)
    {
        case RLYPeripheralPairStateAssumedPaired:
        case RLYPeripheralPairStatePaired:
            return YES;
        
        case RLYPeripheralPairStateAssumedUnpaired:
        case RLYPeripheralPairStateUnpaired:
            return NO;
    }
}


RLYPeripheralStyle RLYPeripheralStyleFromShortName(NSString *shortName)
{
    if (shortName == nil)
    {
        return RLYPeripheralStyleUndetermined;
    }

    // rings
    if ([shortName isEqualToString:@"DAYD"])
    {
        return RLYPeripheralStyleDaydream;
    }
    
    if ([shortName isEqualToString:@"DIVE"])
    {
        return RLYPeripheralStyleDiveBar;
    }
    
    if ([shortName isEqualToString:@"WOOD"])
    {
        return RLYPeripheralStyleIntoTheWoods;
    }
    
    if ([shortName isEqualToString:@"STAR"])
    {
        return RLYPeripheralStyleStargaze;
    }
    
    if ([shortName isEqualToString:@"WINE"])
    {
        return RLYPeripheralStyleWineBar;
    }
    
    if ([shortName isEqualToString:@"2SEA"])
    {
        return RLYPeripheralStyleOutToSea;
    }
    
    if ([shortName isEqualToString:@"DAYB"])
    {
        return RLYPeripheralStyleDaybreak;
    }
    
    if ([shortName isEqualToString:@"NITE"])
    {
        return RLYPeripheralStyleOpeningNight;
    }
    
    if ([shortName isEqualToString:@"LUST"])
    {
        return RLYPeripheralStyleWanderlust;
    }

    // disrupt rings
    if ([shortName isEqualToString:@"GDIS"])
    {
        return RLYPeripheralStyleDisruptGold;
    }

    if ([shortName isEqualToString:@"DISR"])
    {
        return RLYPeripheralStyleDisruptRhodium;
    }

    // bracelets
    if ([shortName isEqualToString:@"LAKE"])
    {
        return RLYPeripheralStyleLakeside;
    }

    if ([shortName isEqualToString:@"FOTO"])
    {
        return RLYPeripheralStylePhotoBooth;
    }

    if ([shortName isEqualToString:@"VOUS"])
    {
        return RLYPeripheralStyleRendezvous;
    }

    if ([shortName isEqualToString:@"BACK"])
    {
        return RLYPeripheralStyleBackstage;
    }

    if ([shortName isEqualToString:@"WALK"])
    {
        return RLYPeripheralStyleBoardwalk;
    }

    if ([shortName isEqualToString:@"ROAD"])
    {
        return RLYPeripheralStyleRoadTrip;
    }
    
    if ([shortName isEqualToString:@"LOVE"])
    {
        return RLYPeripheralStyleGo01;
    }
    
    if ([shortName isEqualToString:@"GO01"])
    {
        return RLYPeripheralStyleGo01;
    }
    
    if ([shortName isEqualToString:@"GO02"])
    {
        return RLYPeripheralStyleGo02;
    }
    
    if ([shortName isEqualToString:@"ROSE"])
    {
        return RLYPeripheralStyleRose;
    }
    
    if ([shortName isEqualToString:@"JETS"])
    {
        return RLYPeripheralStyleJets;
    }
    
    if ([shortName isEqualToString:@"RIDE"])
    {
        return RLYPeripheralStyleRide;
    }
    
    if ([shortName isEqualToString:@"BONV"])
    {
        return RLYPeripheralStyleBonv;
    }
    
    if ([shortName isEqualToString:@"DATE"])
    {
        return RLYPeripheralStyleDate;
    }
    
    if ([shortName isEqualToString:@"HOUR"])
    {
        return RLYPeripheralStyleHour;
    }
    
    if ([shortName isEqualToString:@"MOON"])
    {
        return RLYPeripheralStyleMoon;
    }
    
    if ([shortName isEqualToString:@"TIDE"])
    {
        return RLYPeripheralStyleTide;
    }
    
    if ([shortName isEqualToString:@"DAY2"])
    {
        return RLYPeripheralStyleDay2;
    }
    
    return RLYPeripheralStyleInvalid;
}

NSString *__nullable RLYPeripheralStyleName(RLYPeripheralStyle style)
{
    switch (style)
    {
        case RLYPeripheralStyleDaydream:
            return @"Daydream";
            
        case RLYPeripheralStyleDiveBar:
            return @"Dive Bar";
            
        case RLYPeripheralStyleIntoTheWoods:
            return @"Into the Woods";
            
        case RLYPeripheralStyleStargaze:
            return @"Stargaze";
            
        case RLYPeripheralStyleWineBar:
            return @"Wine Bar";
            
        case RLYPeripheralStyleOutToSea:
            return @"Out to Sea";
            
        case RLYPeripheralStyleDaybreak:
            return @"Daybreak";
            
        case RLYPeripheralStyleOpeningNight:
            return @"Opening Night";
            
        case RLYPeripheralStyleWanderlust:
            return @"Wanderlust";

        case RLYPeripheralStyleDisruptGold:
        case RLYPeripheralStyleDisruptRhodium:
            return @"Disrupt";

        case RLYPeripheralStyleLakeside:
            return @"Lakeside";

        case RLYPeripheralStyleRoadTrip:
            return @"Road Trip";

        case RLYPeripheralStyleBoardwalk:
            return @"Boardwalk";

        case RLYPeripheralStyleBackstage:
            return @"Backstage";

        case RLYPeripheralStylePhotoBooth:
            return @"Photo Booth";

        case RLYPeripheralStyleRendezvous:
            return @"Rendezvous";
            
        case RLYPeripheralStyleGo01:
        case RLYPeripheralStyleGo02:
            return @"Ringly GO";
        case RLYPeripheralStyleRose:
            return @"Rosé All Day";
        case RLYPeripheralStyleJets:
            return @"Jet Set";
        case RLYPeripheralStyleRide:
            return @"Joy Ride";
        case RLYPeripheralStyleBonv:
            return @"Bon Voyage";
        case RLYPeripheralStyleDate:
            return @"First Date";
        case RLYPeripheralStyleHour:
            return @"After Hours";
        case RLYPeripheralStyleMoon:
            return @"Full Moon";
        case RLYPeripheralStyleTide:
            return @"High Tide";
        case RLYPeripheralStyleDay2:
            return @"Daydream";
            
        case RLYPeripheralStyleUndetermined:
            return nil;
            
        case RLYPeripheralStyleInvalid:
            return nil;
    }
}

NSString *__nullable RLYPeripheralShortNameFromName(NSString *__nullable name)
{
    NSArray *nameComponents = [name componentsSeparatedByString:@" "];
    return nameComponents.count == 4 ? nameComponents[2] : nil;
}


RLYPeripheralBand RLYPeripheralBandFromStyle(RLYPeripheralStyle style)
{
    switch (style)
    {
        case RLYPeripheralStyleDaydream:
        case RLYPeripheralStyleIntoTheWoods:
        case RLYPeripheralStyleOutToSea:
        case RLYPeripheralStyleStargaze:
        case RLYPeripheralStyleWineBar:
        case RLYPeripheralStyleDisruptGold:
        case RLYPeripheralStyleBackstage:
        case RLYPeripheralStylePhotoBooth:
        case RLYPeripheralStyleRendezvous:
        case RLYPeripheralStyleLakeside:
            return RLYPeripheralBandGold;

        case RLYPeripheralStyleDaybreak:
        case RLYPeripheralStyleDiveBar:
        case RLYPeripheralStyleOpeningNight:
        case RLYPeripheralStyleWanderlust:
        case RLYPeripheralStyleDisruptRhodium:
            return RLYPeripheralBandRhodium;

        case RLYPeripheralStyleRoadTrip:
        case RLYPeripheralStyleBoardwalk:
            return RLYPeripheralBandSilver;
            
        case RLYPeripheralStyleInvalid:
            return RLYPeripheralBandInvalid;

        case RLYPeripheralStyleRose:
        case RLYPeripheralStyleJets:
        case RLYPeripheralStyleRide:
        case RLYPeripheralStyleBonv:
        case RLYPeripheralStyleDate:
        case RLYPeripheralStyleHour:
        case RLYPeripheralStyleMoon:
        case RLYPeripheralStyleTide:
        case RLYPeripheralStyleDay2:
        case RLYPeripheralStyleGo01:
        case RLYPeripheralStyleGo02:
        case RLYPeripheralStyleUndetermined:
            return RLYPeripheralBandUndetermined;
    }
}

#pragma mark - Stones
NSString *__nullable RLYPeripheralStoneName(RLYPeripheralStone stone)
{
    switch (stone)
    {
        case RLYPeripheralStoneBlackOnyx:
            return @"Black Onyx";

        case RLYPeripheralStoneBlueLaceAgate:
            return @"Blue Lace Agate";

        case RLYPeripheralStoneEmerald:
            return @"Emerald";

        case RLYPeripheralStoneLabradorite:
            return @"Labradorite";

        case RLYPeripheralStoneLapis:
            return @"Lapis";

        case RLYPeripheralStonePinkChalecedony:
            return @"Pink Chalecedony";

        case RLYPeripheralStonePinkSapphire:
            return @"Pink Sapphire";

        case RLYPeripheralStoneSnowflakeObsidian:
            return @"Snowflake Obsidian";

        case RLYPeripheralStoneTourmalatedQuartz:
            return @"Tourmalated Quartz";

        case RLYPeripheralStoneRainbowMoonstone:
            return @"Rainbow Moonstone";

        case RLYPeripheralStoneInvalid:
        case RLYPeripheralStoneUndetermined:
            return nil;
    }
}

RLYPeripheralStone RLYPeripheralStoneFromStyle(RLYPeripheralStyle style)
{
    switch (style)
    {
        case RLYPeripheralStyleDaydream:
        case RLYPeripheralStylePhotoBooth:
            return RLYPeripheralStoneRainbowMoonstone;

        case RLYPeripheralStyleIntoTheWoods:
            return RLYPeripheralStoneEmerald;

        case RLYPeripheralStyleOutToSea:
        case RLYPeripheralStyleLakeside:
            return RLYPeripheralStoneLapis;

        case RLYPeripheralStyleStargaze:
        case RLYPeripheralStyleOpeningNight:
            return RLYPeripheralStoneBlackOnyx;

        case RLYPeripheralStyleWineBar:
            return RLYPeripheralStonePinkSapphire;

        case RLYPeripheralStyleDiveBar:
        case RLYPeripheralStyleDisruptGold:
        case RLYPeripheralStyleDisruptRhodium:
        case RLYPeripheralStyleBackstage:
            return RLYPeripheralStoneTourmalatedQuartz;

        case RLYPeripheralStyleWanderlust:
        case RLYPeripheralStyleRendezvous:
            return RLYPeripheralStoneLabradorite;

        case RLYPeripheralStyleDaybreak:
            return RLYPeripheralStonePinkChalecedony;

        case RLYPeripheralStyleRoadTrip:
            return RLYPeripheralStoneSnowflakeObsidian;

        case RLYPeripheralStyleBoardwalk:
            return RLYPeripheralStoneBlueLaceAgate;
            
        case RLYPeripheralStyleGo01:
            return RLYPeripheralStoneTourmalatedQuartz;
        case RLYPeripheralStyleGo02:
            return RLYPeripheralStoneBlackOnyx;
        
        case RLYPeripheralStyleRose:
        case RLYPeripheralStyleJets:
        case RLYPeripheralStyleRide:
        case RLYPeripheralStyleBonv:
        case RLYPeripheralStyleDate:
        case RLYPeripheralStyleHour:
        case RLYPeripheralStyleMoon:
        case RLYPeripheralStyleTide:
        case RLYPeripheralStyleDay2:
            return RLYPeripheralStoneInvalid;
            
        case RLYPeripheralStyleInvalid:
            return RLYPeripheralStoneInvalid;

        case RLYPeripheralStyleUndetermined:
            return RLYPeripheralStoneUndetermined;
    }
}


RLYPeripheralType RLYPeripheralTypeFromStyle(RLYPeripheralStyle style)
{
    switch (style)
    {
        case RLYPeripheralStyleDaybreak:
        case RLYPeripheralStyleDaydream:
        case RLYPeripheralStyleDiveBar:
        case RLYPeripheralStyleIntoTheWoods:
        case RLYPeripheralStyleOpeningNight:
        case RLYPeripheralStyleOutToSea:
        case RLYPeripheralStyleStargaze:
        case RLYPeripheralStyleWanderlust:
        case RLYPeripheralStyleWineBar:
        case RLYPeripheralStyleDisruptGold:
        case RLYPeripheralStyleDisruptRhodium:
        case RLYPeripheralStyleDate:
        case RLYPeripheralStyleHour:
        case RLYPeripheralStyleMoon:
        case RLYPeripheralStyleTide:
        case RLYPeripheralStyleDay2:
            return RLYPeripheralTypeRing;

        case RLYPeripheralStyleLakeside:
        case RLYPeripheralStyleRoadTrip:
        case RLYPeripheralStyleBoardwalk:
        case RLYPeripheralStyleBackstage:
        case RLYPeripheralStylePhotoBooth:
        case RLYPeripheralStyleRendezvous:
        case RLYPeripheralStyleGo01:
        case RLYPeripheralStyleGo02:
        case RLYPeripheralStyleRose:
        case RLYPeripheralStyleJets:
        case RLYPeripheralStyleRide:
        case RLYPeripheralStyleBonv:
            return RLYPeripheralTypeBracelet;

        case RLYPeripheralStyleInvalid:
            return RLYPeripheralTypeInvalid;

        case RLYPeripheralStyleUndetermined:
            return RLYPeripheralTypeUndetermined;
    }
}
