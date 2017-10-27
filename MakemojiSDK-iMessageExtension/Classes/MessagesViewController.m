//
//  MessagesViewController.m
//  EmojiApp
//
//  Created by stephen.schroeder on 6/25/17.
//  Copyright © 2017 Unknown. All rights reserved.
//

#import "MessagesViewController.h"
#import "MessagesViewController.h"
#import "MEStickerAPIManager.h"
#import "MEStickerCollectionReusableView.h"
#import "Analytics.h"

@interface MessagesViewController ()

@end

@implementation MessagesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self vixletInitProcess];
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    return self;
}
-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initializeDataFromMainApp];
}
-(void) initializeDataFromMainApp {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.vixlet.ios"];
    NSString *brandCode = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"brandCode"];;

    NSString *mojiAPIKey = [NSString stringWithFormat:@"%@%@", brandCode, @"mojiAPIKey"];
    NSString *mojiShareLinkKey = [NSString stringWithFormat:@"%@%@", brandCode, @"mojiShareLink"];
    NSString *analyticsAPIKey = [NSString stringWithFormat:@"%@%@", brandCode, @"analyticsAPIKey"];
    NSString *userId = [NSString stringWithFormat:@"%@%@", brandCode, @"userId"];
    NSString *unlockedCode = [NSString stringWithFormat:@"%@%@", brandCode, @"unlockedCategories"];
    NSString *brandColorCode = [NSString stringWithFormat:@"%@%@", brandCode, @"color"];

    _analyiticsAPIKey = [shared valueForKey:analyticsAPIKey];
    if (_analyiticsAPIKey == nil) {
        _analyiticsAPIKey = @"";
    }

    _userId = [shared valueForKey:userId];


    _shareLink = [shared valueForKey:mojiShareLinkKey];
    if (_shareLink == nil) {
        _shareLink = @"";
    }

    _mojiAPIKey = [shared valueForKey:mojiAPIKey];
    if (_mojiAPIKey == nil) {
        _mojiAPIKey = @"178e4219d7a98a3d6ee15438adb61c690ea090af";
    }
    self.unlockedCategories = [shared valueForKey:unlockedCode];
    
    NSData * brandColorData = [shared dataForKey:brandColorCode];

    if(brandColorData){
        self.brandColor = [NSKeyedUnarchiver unarchiveObjectWithData:brandColorData];
    }
}

-(void)initAnalytics {
    SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:_analyiticsAPIKey];
    [SEGAnalytics setupWithConfiguration:configuration];
}

-(void)initEmojiSettings {
    [MEStickerAPIManager setSdkKey:_mojiAPIKey];
    self.shareText = _shareLink;
}

-(void)vixletInitProcess {
    [self initializeDataFromMainApp];
    [self initAnalytics];
    [self initEmojiSettings];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self vixletInitProcess];
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ( !([_userId length] == 0) ) {
        [[SEGAnalytics sharedAnalytics] identify:_userId];
    }
    [[SEGAnalytics sharedAnalytics] track:@"EXTENSION:OPENED"
                               properties:@{ @"extension_type": @"ios_imessage"}];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
