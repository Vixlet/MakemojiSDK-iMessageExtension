//
//  MEMessagesViewController.m
//
//  Created by steve on 10/13/16.
//  Copyright © 2016 Makemoji. All rights reserved.
//

#import "SDWebImage/UIImageView+WebCache.h"
#import "MEMessagesViewController.h"
#import "MEStickerAPIManager.h"
#import "MEStickerFlowLayout.h"
#import "MEStickerCollectionViewCell.h"
#import "MEStickerCollectionReusableView.h"
#import "MSStickerView+WebCache.h"
#import "Analytics.h"
#import "LockCoverView.h"
@interface MEMessagesViewController ()
@property NSURLSessionDataTask * emojiWallTask;

@end

@implementation MEMessagesViewController
@synthesize categories = _categories;
@synthesize allEmoji = _allEmoji;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.shareText = @"Check out the Makemoji SDK: http://makemoji.com";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];


    self.isSearching = NO;
    self.searchResults = [NSMutableArray array];
    self.automaticallyAdjustsScrollViewInsets = YES;
    

    NSURL * placeHolderURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MEPlaceholder@2x" withExtension:@"png"];
    
    self.placeholderSticker = [[MSSticker alloc] initWithContentsOfFileURL:placeHolderURL localizedDescription:@"Placeholder" error:nil];
    
    // setup share button
    self.shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.shareButton setTitle:@"SHARE" forState:UIControlStateNormal];
    [self.shareButton.titleLabel setFont:[UIFont boldSystemFontOfSize:12]];
    [self.shareButton addTarget:self action:@selector(shareKeyboard) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.shareButton];
    [self.shareButton sizeToFit];
    self.shareButton.frame = CGRectMake((self.view.frame.size.width-self.shareButton.frame.size.width-10), 0, self.shareButton.frame.size.width, 24);

    // offline error view
    self.accessLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.accessLabel.backgroundColor = [UIColor colorWithWhite:0.97 alpha:0.95];
    self.accessLabel.text = @"An internet connection is required to use this extension.";
    self.accessLabel.textColor = [UIColor blackColor];
    self.accessLabel.numberOfLines = 2;
    self.accessLabel.font = [UIFont boldSystemFontOfSize:18];
    self.accessLabel.textAlignment = NSTextAlignmentCenter;
    self.accessLabel.hidden = YES;
    self.accessLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.accessLabel];
    [self.view sendSubviewToBack:self.accessLabel];
    [self.view.topAnchor constraintEqualToAnchor:self.accessLabel.topAnchor].active = YES;
    [self.view.bottomAnchor constraintEqualToAnchor:self.accessLabel.bottomAnchor].active = YES;
    [self.view.leftAnchor constraintEqualToAnchor:self.accessLabel.leftAnchor].active = YES;
    [self.view.rightAnchor constraintEqualToAnchor:self.accessLabel.rightAnchor].active = YES;
    
    // setup collection view
    MEStickerFlowLayout * stickerLayout = [[MEStickerFlowLayout alloc] init];
    self.stickerBrowser = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:stickerLayout];
    self.stickerBrowser.delegate = self;
    self.stickerBrowser.dataSource = self;
    
    self.stickerBrowser.translatesAutoresizingMaskIntoConstraints = NO;
    [self.stickerBrowser registerClass:[MEStickerCollectionViewCell class] forCellWithReuseIdentifier:@"Emoji"];
    [self.stickerBrowser registerClass:[MEStickerCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Section"];
    self.stickerBrowser.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    [self.view addSubview:self.stickerBrowser];
    [self.view.topAnchor constraintEqualToAnchor:self.stickerBrowser.topAnchor].active = YES;
    [self.view.bottomAnchor constraintEqualToAnchor:self.stickerBrowser.bottomAnchor].active = YES;
    [self.view.leftAnchor constraintEqualToAnchor:self.stickerBrowser.leftAnchor].active = YES;
    [self.view.rightAnchor constraintEqualToAnchor:self.stickerBrowser.rightAnchor].active = YES;

    self.lockView = [[LockCoverView alloc]initWithFrame:self.inputView.frame];
    [self.lockView setHidden:YES];
    self.lockView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.lockView];
    [self.view.topAnchor constraintEqualToAnchor:self.lockView.topAnchor].active = YES;
    [self.view.bottomAnchor constraintEqualToAnchor:self.lockView.bottomAnchor].active = YES;
    [self.view.leftAnchor constraintEqualToAnchor:self.lockView.leftAnchor].active = YES;
    [self.view.rightAnchor constraintEqualToAnchor:self.lockView.rightAnchor].active = YES;


    [self.view bringSubviewToFront:self.shareButton];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    [self.searchBar setBackgroundColor:[UIColor colorWithWhite:0.97 alpha:1]];
    self.searchBar.placeholder = @"Search";
    self.searchBar.showsCancelButton = NO;
    self.searchBar.hidden = YES;
    self.searchBar.delegate = self;
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    self.searchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
    [self.view addSubview:self.searchBar];

    
    
    [[AFNetworkReachabilityManager sharedManager]setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
        if (status == AFNetworkReachabilityStatusReachableViaWWAN || status == AFNetworkReachabilityStatusReachableViaWiFi) {
            [self.accessLabel setHidden:YES];
            [self.view sendSubviewToBack:self.accessLabel];
        } else {
            if (self.categories.count == 0 && self.allEmoji.allKeys.count == 0) {
                [self.accessLabel setHidden:NO];
                [self.view bringSubviewToFront:self.accessLabel];
            }
        }
    }];
    
    [self loadFromDisk:[[MEStickerAPIManager client] cacheNameWithChannel:@"categories"]];
    [self loadFromDisk:[[MEStickerAPIManager client] cacheNameWithChannel:@"wall"]];
    [self updateData];


    [self.lockView.cancelButton addTarget:self action:@selector(cancelLockView) forControlEvents:UIControlEventTouchUpInside];
    [self.lockView.background addTarget:self action:@selector(cancelLockView) forControlEvents:UIControlEventTouchUpInside];

    [self.lockView.learnMoreButton addTarget:self action:@selector(lockLearnMorePressed) forControlEvents:UIControlEventTouchUpInside];

    [self.view bringSubviewToFront:self.lockView];

    
}


-(void)cancelLockView {
    [UIView transitionWithView:self.lockView
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.lockView.hidden = YES;
                    }
                    completion:NULL];

}


-(void)lockLearnMorePressed {
    [self cancelLockView];
    if(self.lastSharedEmoji) {
        [self sendToStore];
    }
}

-(void)loadLockView
{
    if( self.brandColor != nil) {
        self.lockView.learnMoreButton.backgroundColor = self.brandColor;
    }
    [UIView transitionWithView:self.lockView
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.lockView.hidden = NO;
                    }
                    completion:NULL];

}

-(void) sendToStore  {
    UIResponder *responder = self;
    while(responder){
        if ([responder respondsToSelector: @selector(openURL:)]){
            NSString *urlscheme = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"urlscheme"];;

            NSString* encodedCategory = [_lastSharedEmoji stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            NSString * url = [NSString stringWithFormat:@"%1$@://vixlet/purchase/%2$@", urlscheme, encodedCategory];
            [responder performSelector: @selector(openURL:) withObject: [NSURL URLWithString:url ]];
        }
        responder = [responder nextResponder];
    }
}



- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    return YES;
    
}                      // return NO to not become first responder
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.isSearching = YES;
    self.searchBar.showsCancelButton = YES;
}// called when text starts editing

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
    
}// return NO to not resign first responder

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.isSearching = NO;
    if (self.searchBar.text.length > 0) {
        self.searchBar.showsCancelButton = YES;
        self.isSearching = YES;
    } else {
        self.searchBar.showsCancelButton = NO;

    }
    [self.stickerBrowser reloadData];
}
// called when text ends editing

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    NSLog(@"%@", scrollView);
//}


-(BOOL)isCategoryLocked:(NSString *)categoryName {
    for (NSDictionary * cat in self.categories) {
        if ([cat objectForKey:@"locked"] && [[cat objectForKey:@"locked"] boolValue] == YES && [[cat objectForKey:@"name"] isEqualToString:categoryName]) {
            if (self.unlockedCategories && [self.unlockedCategories containsObject: [cat objectForKey:@"name"]]){
                return NO;
            }
            return YES;
        }
    }
    return NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.isSearching = YES;
    if (searchText.length > 0) {

        NSString * searchStringTrim = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        __weak MEMessagesViewController *weakSelf = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"flashtag contains[c] %@", searchStringTrim];
            NSMutableArray * newResults;
            weakSelf.searchResults = [NSMutableArray array];
            
            for (NSString * section in weakSelf.allEmoji.allKeys) {
                if (![section isEqualToString:@"Osemoji"]
                    && ![section isEqualToString:@"Trending"]
                    && ![section isEqualToString:@"Audio Emoji"]
                    && ![section isEqualToString:@"Gifs"]
                    && ![section isEqualToString:@"Used"] && ![weakSelf isCategoryLocked:section]) {
                    
                    newResults = [NSMutableArray arrayWithArray:[[weakSelf.allEmoji objectForKey:section] filteredArrayUsingPredicate:predicate]];
                    
                    if (newResults.count > 0) {
                        [newResults enumerateObjectsUsingBlock:^(id x, NSUInteger index, BOOL *stop){
                            
                            if ([[[x objectForKey:@"flashtag"] lowercaseString] hasPrefix:[searchStringTrim lowercaseString]]) {
                                [weakSelf.searchResults insertObject:x atIndex:0];
                            } else {
                                [weakSelf.searchResults addObject:x];
                            }
                            
                        }];
                    }
                }
                
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.stickerBrowser reloadData];
            });
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.searchResults.count > 0) {
                [weakSelf.stickerBrowser scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
                }
            });
        });
        
        return;
    } else {
        self.isSearching = NO;
        [self.stickerBrowser reloadData];
    }
    

}// called when text changes (including clear)

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchBar:searchBar textDidChange:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.isSearching = NO;
    self.searchBar.text = nil;
    [self.searchBar resignFirstResponder];
    [self.stickerBrowser reloadData];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.presentationStyle == MSMessagesAppPresentationStyleCompact) {
        [self.stickerBrowser setContentInset:UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)];
    } else {
        CGRect searchFrame = self.searchBar.frame;
        searchFrame.origin.y = self.topLayoutGuide.length;
        self.searchBar.frame = searchFrame;

    }
}

- (void)updateData {
    NSString * url = @"emoji/categories";
    MEStickerAPIManager * manager = [MEStickerAPIManager client];
    
    __weak MEMessagesViewController * weakSelf = self;
    
    [manager GET:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSError * error;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:kNilOptions error:&error];
        NSString *path = [[self applicationDocumentsDirectory].path
                          stringByAppendingPathComponent:[[MEStickerAPIManager client] cacheNameWithChannel:@"categories"]];
        [[NSFileManager defaultManager] createFileAtPath:path
                                                contents:jsonData
                                              attributes:nil];
        weakSelf.categories = responseObject;
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];
    
    self.emojiWallTask = [manager GET:@"emoji/emojiWall/imex" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSError * error;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:kNilOptions error:&error];
        NSString *path = [[weakSelf applicationDocumentsDirectory].path
                          stringByAppendingPathComponent:[[MEStickerAPIManager client] cacheNameWithChannel:@"wall"]];
        [[NSFileManager defaultManager] createFileAtPath:path
                                                contents:jsonData
                                              attributes:nil];
        
        weakSelf.allEmoji = responseObject;
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}


- (NSMutableArray *)categories {
    if (_categories == nil) {
        _categories = [NSMutableArray array];
    }
    return _categories;
}

- (void)setCategories:(NSMutableArray *)categories {
    _categories = [NSMutableArray arrayWithArray:categories];
    [_categories insertObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Trending",@"name", nil] atIndex:0];
}

- (NSDictionary *)allEmoji {
    if (_allEmoji == nil) {
        _allEmoji = [NSDictionary dictionary];
    }
    return _allEmoji;
}

- (void)setAllEmoji:(NSDictionary *)allEmoji {
    _allEmoji = allEmoji;
    BOOL animationsEnabled = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:NO];
    [self.stickerBrowser reloadData];
    [UIView setAnimationsEnabled:animationsEnabled];
}

- (void)shareKeyboard {
    [[SEGAnalytics sharedAnalytics] track:@"EXTENSION:SHARE:CLICKED"
                               properties:@{ @"extension_type": @"ios_imessage"}];
    [[MEStickerAPIManager manager] trackShareWithEmojiId:@"0"];
    [self.activeConversation insertText:self.shareText completionHandler:nil];
}


#pragma mark - Collection View data source

- (CGSize)collectionView:(UICollectionView* )collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath* )indexPath {
    CGRect frame = [[UIScreen mainScreen] bounds];

    CGFloat width = frame.size.width;
    if (width > frame.size.height) { width = frame.size.height; }

    if (collectionView == self.stickerBrowser) {
        return CGSizeMake(width/3,110);
    }

    return CGSizeMake(width/5,71);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    NSDictionary * lastCategory = [self.categories objectAtIndex:indexPath.section];
    self.lastSharedEmoji = [lastCategory valueForKey:@"name"];

        [self loadLockView];



    // not called
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.isSearching == YES) {
        return 1;
    }
    return [self.categories count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.isSearching == YES) {
        return [self.searchResults count];
    }
    return  [[self.allEmoji objectForKey:[self categoryNameForSection:section]] count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        MEStickerCollectionReusableView * headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Section" forIndexPath:indexPath];
        NSMutableParagraphStyle *style =  [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentJustified;
        style.firstLineHeadIndent = 10.0f;
        style.headIndent = 10.0f;
        NSString * headerText = [[self categoryNameForSection:indexPath.section] uppercaseString];
        if (self.isSearching == YES && self.searchResults.count > 0) {
            headerText = @"SEARCH RESULTS";
        }
        NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:headerText attributes:@{ NSParagraphStyleAttributeName : style}];
        headerView.sectionLabel.attributedText = attrText;
        reusableview = headerView;
    }
    
    return reusableview;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEStickerCollectionViewCell *collectionCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Emoji" forIndexPath:indexPath];
    NSDictionary * emoji;
    if (self.isSearching == YES && self.searchResults.count > 0) {
      emoji = [self.searchResults objectAtIndex:indexPath.item];
    } else {
      emoji = [[self emojiArrayForSection:indexPath.section] objectAtIndex:indexPath.item];
    }

    NSMutableDictionary *blendedDict = [NSMutableDictionary dictionaryWithDictionary:emoji];

    NSDictionary* category = [self.categories objectAtIndex:indexPath.section];
    if(category[@"locked"]){
        blendedDict[@"locked"] = category[@"locked"];
    }
    if(category[@"name"]){
        collectionCell.categoryName = category[@"name"];
        blendedDict[@"category"] = category[@"name"];
        [collectionCell setLocked:[self isCategoryLocked:category[@"name"]]];
    } else{
        [collectionCell setLocked:NO];
    }
    emoji = blendedDict;

    [collectionCell.stickerView stopAnimating];


    NSString * imageUrl = [emoji objectForKey:@"image_url"];
    NSString * emojiName = [emoji objectForKey:@"name"];


    [collectionCell.stickerView sd_setStickerWithURL:[NSURL URLWithString:imageUrl] placeholderSticker:self.placeholderSticker options:0 progress:nil completed:nil];
    [[MEStickerAPIManager manager] imageViewWithId:[emoji objectForKey:@"id"]];
    collectionCell.emojiId = [emoji objectForKey:@"id"];
    collectionCell.emojiName = emojiName;

    return collectionCell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (section == 0) { return UIEdgeInsetsMake(0, 0, 14, 0); }
    return UIEdgeInsetsMake(4, 0, 14, 0);
}

#pragma mark - Conversation Handling

- (void)didBecomeActiveWithConversation:(MSConversation *)conversation {
    [[MEStickerAPIManager manager] beginImageViewSessionWithTag:@"imex"];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)willResignActiveWithConversation:(MSConversation *)conversation {
    [[MEStickerAPIManager manager] endImageViewSession];
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (self.presentationStyle == MSMessagesAppPresentationStyleExpanded) {
    //get the end position keyboard frame
    NSDictionary *keyInfo = [notification userInfo];
    CGRect keyboardFrame = [[keyInfo objectForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    //convert it to the same view coords as the tableView it might be occluding
    keyboardFrame = [self.stickerBrowser convertRect:keyboardFrame fromView:nil];
    //calculate if the rects intersect
    CGRect intersect = CGRectIntersection(keyboardFrame, self.stickerBrowser.bounds);
    if (!CGRectIsNull(intersect)) {
        //yes they do - adjust the insets on tableview to handle it
        //first get the duration of the keyboard appearance animation
        NSTimeInterval duration = [[keyInfo objectForKey:@"UIKeyboardAnimationDurationUserInfoKey"] doubleValue];
        //change the table insets to match - animated to the same duration of the keyboard appearance
        [UIView animateWithDuration:duration animations:^{
            self.stickerBrowser.contentInset = UIEdgeInsetsMake(self.stickerBrowser.contentInset.top, 0, intersect.size.height+44, 0);
            self.stickerBrowser.scrollIndicatorInsets = UIEdgeInsetsMake(self.stickerBrowser.contentInset.top, 0, intersect.size.height+44, 0);
        }];
    }
    }
}

- (void) keyboardWillHide:  (NSNotification *) notification {
    if (self.presentationStyle == MSMessagesAppPresentationStyleExpanded) {
    NSDictionary *keyInfo = [notification userInfo];
    NSTimeInterval duration = [[keyInfo objectForKey:@"UIKeyboardAnimationDurationUserInfoKey"] doubleValue];
    //clear the table insets - animated to the same duration of the keyboard disappearance
    [UIView animateWithDuration:duration animations:^{
        self.stickerBrowser.contentInset = UIEdgeInsetsMake(self.stickerBrowser.contentInset.top, 0, self.bottomLayoutGuide.length, 0);;
        self.stickerBrowser.scrollIndicatorInsets = UIEdgeInsetsMake(self.stickerBrowser.contentInset.top, 0, self.bottomLayoutGuide.length, 0);;
    }];
    }
}

-(void)willTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle {
    if (presentationStyle == MSMessagesAppPresentationStyleExpanded) {

    } else {
        self.searchBar.text = @"";
        self.searchBar.hidden = YES;
        self.isSearching = NO;
        [self.searchBar resignFirstResponder];

    }
}

-(void)didTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle {
    if (presentationStyle == MSMessagesAppPresentationStyleExpanded) {
        [self resetToExpanded];
        self.searchBar.hidden = NO;
    } else {
        self.searchBar.hidden = YES;
        [self resetToCollapsed];
    }
}

-(void)resetToExpanded {
    [self.stickerBrowser setContentInset:UIEdgeInsetsMake(self.topLayoutGuide.length+self.searchBar.frame.size.height, 0, self.bottomLayoutGuide.length, 0)];
    dispatch_async(dispatch_get_main_queue(), ^{
    [self.stickerBrowser scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    });
}

-(void)resetToCollapsed {
    [self.stickerBrowser setContentInset:UIEdgeInsetsMake(0, 0, self.bottomLayoutGuide.length, 0)];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.stickerBrowser reloadData];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
    [self.stickerBrowser scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    });
}


#pragma mark - Utility

- (void)loadFromDisk:(NSString *)filename {
    NSString *path = [[self applicationDocumentsDirectory].path stringByAppendingPathComponent:filename];
    NSError * error;
    NSData * data = [NSData dataWithContentsOfFile:path];
    
    if (data != nil) {
        id jsonResponse = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path]
                                                          options:kNilOptions
                                                            error:&error];
        if (jsonResponse != nil) {
            if ([filename containsString:@"wall"]) {
                self.allEmoji = jsonResponse;
            }
            
            if ([filename containsString:@"categories"]) {
                self.categories = jsonResponse;
            }
            
        }
    }
    
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSString *)categoryNameForSection:(NSInteger)section {
    return [[self.categories objectAtIndex:section] objectForKey:@"name"];
}

- (NSArray *)emojiArrayForSection:(NSInteger)section {
    return [self.allEmoji objectForKey:[self categoryNameForSection:section]];
}

@end
