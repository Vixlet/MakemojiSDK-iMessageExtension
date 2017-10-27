//
//  MEStickerCollectionViewCell.h
//  MakemojiSDKDemo
//
//  Created by steve on 11/9/16.
//  Copyright © 2016 Makemoji. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Messages/Messages.h>


@interface MEStickerCollectionViewCell : UICollectionViewCell <UIGestureRecognizerDelegate>
@property (nonatomic, strong) MSStickerView * stickerView;
@property (nonatomic, weak) NSString * emojiId;
@property (nonatomic, strong) UIImageView * lockView;
@property (nonatomic, weak) NSString * emojiName;
@property (nonatomic, weak) NSString * categoryName;

-(void) setLocked:(BOOL) isLocked;
@end
