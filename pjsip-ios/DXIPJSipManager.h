//
//  DXIPJSipManager.h
//  pjsip-ios
//
//  Created by Otavio Zabaleta on 13/05/2015.
//  Copyright (c) 2015 DXI. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kSIP_STATE_IDLE = @"SIP_STATE_IDLE";
static NSString *kSIP_STATE_REGISTERING = @"SIP_STATE_REGISTERING";
static NSString *kSIP_STATE_REGISTERED = @"SIP_STATE_REGISTERED";
static NSString *kSIP_STATE_CALLING_COTACT_CENTRE = @"SIP_STATE_CALLING_COTACT_CENTRE";
static NSString *kSIP_STATE_DIALING_AGENT_CODE = @"SIP_STATE_DIALING_AGENT_CODE";
static NSString *kSIP_STATE_DIALING_AGEND_PASSWORD = @"SIP_STATE_DIALING_AGEND_PASSWORD";
static NSString *kSIP_STATE_LOGGED = @"SIP_STATE_LOGGED";
static int kPJSUA_DEFAULT_PORT = 5060;

@protocol DXIPJSipManagerDelegate <NSObject>
- (void)onRegisterToSipServerAndLogAgentDidFinish;
//- (void)onRegisterToSipServerAndLogAgentDidFailWithResponse:(DXISipResponse *)sipResponse;
@end

@interface DXIPJSipManager : NSObject

@property (strong, nonatomic) NSString *sipState;
@property (strong, nonatomic) NSString *agentName;
@property (strong, nonatomic) NSString *agentPassword;
@property (strong, nonatomic) NSString *agentNumber;
@property (strong, nonatomic) NSString *agentPasscode;
@property (strong, nonatomic) NSString *sipUser;
@property (strong, nonatomic) NSString *sipPasscode;
@property (strong, nonatomic) NSString *contactCentre;
@property (strong, nonatomic) NSString *contactCentreNumber;
@property (strong, nonatomic) NSString *sipDomain;
//@property (strong, nonatomic) DXISipCredentials *sipCredentials;
@property (weak, nonatomic) id<DXIPJSipManagerDelegate> delegate;

+ (DXIPJSipManager *)getInstance;
- (void)setDelegate:(id<DXIPJSipManagerDelegate>)delegate;
- (void)registerToSipServerAndDoAgentLogin;
- (void)callContactCenter;
- (void)unregisterFromSipServer;
- (void)checkSoundStatus;

@end