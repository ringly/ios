//
//  DFUCompleteView.m
//  Ringly
//
//  Created by Nate Stedman on 7/17/15.
//  Copyright (c) 2015 Ringly. All rights reserved.
//

#import "DFUCompleteView.h"
#import "DFUSetupView.h"
#import "RLYPeripheral+Ringly.h"

@implementation DFUCompleteView

#pragma mark - Initialization
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UILabel *title = [UILabel newAutoLayoutView];
        title.attributedText = @"You did it!".rly_DFUTitleString;
        [self addSubview:title];
        
        UIView *underline = [UIView newAutoLayoutView];
        underline.backgroundColor = [UIColor whiteColor];
        [self addSubview:underline];
        
        UILabel *body = [UILabel newAutoLayoutView];
        body.attributedText = @"Your Ringly ring has been successfully updated.\nTime to celebrate!".rly_DFUBodyString;
        body.numberOfLines = 0;
        [self addSubview:body];
        
        UIView *ringContainer = [UIView newAutoLayoutView];
        [self addSubview:ringContainer];
        
        UIImageView *ring = [UIImageView newAutoLayoutView];
        RAC(ring, image) = [RACObserve(self, peripheralStyle) map:^id(id value) {
            return RLYDFUImageForPeripheralStyle([value integerValue]);
        }];
        
        [ringContainer addSubview:ring];
        
        // layout
        [title autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:[DFUSetupView topPadding]];
        [title autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        [underline autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:title];
        [underline autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:title];
        [underline autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:title withOffset:0];
        [underline autoSetDimension:ALDimensionHeight toSize:1];
        
        [body autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:title withOffset:29];
        [body autoSetDimension:ALDimensionWidth toSize:300];
        [body autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        [ringContainer autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:body withOffset:20];
        [ringContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
        
        [ring autoCenterInSuperview];
        [ring autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [ring autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    }
    
    return self;
}

@end
