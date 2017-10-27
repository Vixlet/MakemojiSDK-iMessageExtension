//
//  MEStickerCollectionViewCell.m
//  MakemojiSDKDemo
//
//  Created by steve on 11/9/16.
//  Copyright © 2016 Makemoji. All rights reserved.
//

#import "MEStickerCollectionViewCell.h"
#import "MEStickerAPIManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Analytics.h"
#import "MEStickerCollectionViewCell.h"
@implementation MEStickerCollectionViewCell


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(void)commonInit {

    self.stickerView = [[MSStickerView alloc] initWithFrame:CGRectZero];
    
    self.lockView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.lockView.center = self.contentView.center;
    [self.lockView setImage:[UIImage imageNamed:@"categoryLockedLite"]];
    [self.lockView setContentMode:UIViewContentModeScaleAspectFill];
    
    [self.contentView addSubview:self.stickerView];
    [self.contentView addSubview:self.lockView];
    
    self.lockView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stickerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stickerView.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapSticker:)];
    tapGesture.delegate = self;
    [self.stickerView addGestureRecognizer:tapGesture];


    [self.contentView.topAnchor constraintEqualToAnchor:self.stickerView.topAnchor].active = YES;
    [self.contentView.bottomAnchor constraintEqualToAnchor:self.stickerView.bottomAnchor].active = YES;
    [self.contentView.leftAnchor constraintEqualToAnchor:self.stickerView.leftAnchor].active = YES;
    [self.contentView.rightAnchor constraintEqualToAnchor:self.stickerView.rightAnchor].active = YES;
    
    [self.contentView.topAnchor constraintEqualToAnchor:self.lockView.topAnchor].active = YES;
    [self.contentView.bottomAnchor constraintEqualToAnchor:self.lockView.bottomAnchor].active = YES;
    [self.contentView.leftAnchor constraintEqualToAnchor:self.lockView.leftAnchor].active = YES;
    [self.contentView.rightAnchor constraintEqualToAnchor:self.lockView.rightAnchor].active = YES;
}


-(void)didTapSticker:(UITapGestureRecognizer *)recognizer {
    
    if( _lockView.hidden){
        [[SEGAnalytics sharedAnalytics] track:@"EXTENSION:EMOJI_ITEM:CLICKED"
                                   properties:@{ @"emoji_id": self.emojiName,
                                                 @"extension_type": @"ios_keyboard"
                                                 }];
        
        [[MEStickerAPIManager manager] trackShareWithEmojiId:self.emojiId];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
-(void) setLocked:(BOOL) isLocked {
    if (isLocked){
        [self.stickerView setUserInteractionEnabled:NO];


    }
            [self.stickerView setUserInteractionEnabled:!isLocked];
    _lockView.hidden = !isLocked;
}

-(void)prepareForReuse {
    self.stickerView.sticker = nil;
    self.emojiId = nil;
}

@end
