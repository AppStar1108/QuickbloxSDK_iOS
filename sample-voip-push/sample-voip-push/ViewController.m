//
//  ViewController.m
//  sample-voip-push
//
//  Created by Vitaliy Gurkovsky on 6/6/16.
//  Copyright © 2016 quickblox. All rights reserved.
//

#import <Quickblox/Quickblox.h>
#import <SVProgressHUD.h>
#import "SAMTextView.h"
#import "ViewController.h"
#import <PushKit/PushKit.h>

@interface ViewController() <UITableViewDelegate, UITableViewDataSource, PKPushRegistryDelegate>

@property (weak, nonatomic) IBOutlet SAMTextView *pushMessageTextView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendPushButton;

@property (nonatomic, strong) NSMutableArray *pushMessages;

@property (nonatomic, strong) PKPushRegistry* voipRegistry;

@end


@implementation ViewController

#pragma mark - View life cyle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary* attributes = @{NSFontAttributeName : [UIFont systemFontOfSize:17.0f],
                                 NSForegroundColorAttributeName : [UIColor colorWithWhite:0.0f alpha:0.3f]};
    self.pushMessageTextView.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter push message here" attributes:attributes];
    self.pushMessageTextView.textContainerInset = (UIEdgeInsets){10.0f, 10.0f, 0.0f, 0.0f};
    
    self.pushMessages = [NSMutableArray array];
    
    __weak typeof(self) weakSelf = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    [self checkCurrentUserWithCompletion:^(NSError *authError) {
        
        if (!authError) {
            weakSelf.sendPushButton.enabled = YES;
            [weakSelf voipRegistration];
        } else {
           [SVProgressHUD showErrorWithStatus:authError.localizedDescription];
        }
        
    }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark IBActions
- (IBAction)sendAction:(UIBarButtonItem *)sender {
    
    NSString *message = self.pushMessageTextView.text;
    NSString *userID = [NSString stringWithFormat:@"%zd",[[QBSession currentSession] currentUser].ID];
    
    [QBRequest sendVOIPPushWithText:message toUsers:userID
                       successBlock:^(QBResponse * _Nonnull response, NSArray<QBMEvent *> * _Nullable events) {
                           
                       } errorBlock:^(QBError * _Nullable error) {
                           
                       }];
    

 
}

#pragma mark -
#pragma mark TableViewDataSource & TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.pushMessages count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PushMessageCellIdentifier"];
    
    cell.textLabel.text = self.pushMessages[indexPath.row];
    
    return cell;
}

#pragma mark -
#pragma PKPushRegistryDelegate

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    //push received
    NSDictionary *dictPayload = payload.dictionaryPayload;
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type
{
    NSString *deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // subscribing for push notifications
    QBMSubscription *subscription = [QBMSubscription subscription];
    subscription.notificationChannel = QBMNotificationChannelAPNS;
    subscription.deviceUDID = deviceIdentifier;
    subscription.deviceToken = credentials.token;
    
    [QBRequest createSubscription:subscription successBlock:^(QBResponse * _Nonnull response, NSArray<QBMSubscription *> * _Nullable objects) {
        [SVProgressHUD showInfoWithStatus:@"Subscription created"];
    } errorBlock:^(QBResponse * _Nonnull response) {
        [SVProgressHUD showErrorWithStatus:response.error.error.localizedDescription];
    }];
}
- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(NSString *)type {
    
}
#pragma mark -
#pragma mark Helpers

// Register for VoIP notifications
- (void) voipRegistration {
    
    // Create a push registry object
    _voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    _voipRegistry.delegate = self;
    _voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)checkCurrentUserWithCompletion:(void(^)(NSError *authError))completion
{
    if ([[QBSession currentSession] currentUser] != nil) {
        
        if (completion) completion(nil);
        
    } else {
        
        [SVProgressHUD showWithStatus:@"Initialising"];
        
        [QBRequest logInWithUserLogin:@"qbpushios" password:@"qbpushios" successBlock:^(QBResponse *response, QBUUser *user) {
            
            [SVProgressHUD dismiss];
            
            if (completion) completion(nil);
            
        } errorBlock:^(QBResponse *response) {
            
            [SVProgressHUD dismiss];
            
            if (completion) completion(response.error.error);
        }];
    }
}



@end
