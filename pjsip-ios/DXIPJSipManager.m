//
//  PJSipWrapper.m
//  SimpleSoftPhone
//
//  Created by Otavio Zabaleta on 14/05/2014.
//  Copyright (c) 2014 Otavio Zabaleta. All rights reserved.
//


#import "DXIPJSipManager.h"

// pjsip
#import <pjsua-lib/pjsua.h>
#import <pjsua-lib/pjsua_internal.h>
#import <pjsip/sip_msg.h>

static int kPJSUA_LOG_LEVEL = 1;

// Singletone instance of this class
DXIPJSipManager *_instance;

// Pointer for calling Obj-C methods from inside C/C++ functions
id selfRef;

// PJSip properties
static pj_status_t status;
static pjsua_acc_id acc_id;
static pjsua_config cfg;
static pjsua_logging_config log_cfg;
static pjsua_transport_config transport_cfg;
static pjsua_acc_config acc_cfg;
static pjsua_acc_info acc_info;
static pjsua_call_info call_info;
static pjsua_call_id call_id;



@interface DXIPJSipManager()
@property (atomic) BOOL isSoundEnabled;
@property (atomic) BOOL isInited;
@property (atomic) BOOL isAddedAccount;
@property (atomic) BOOL isRegistered;
@property (atomic) BOOL isLogged;
@property (strong, nonatomic) NSTimer *statusTimer;
@end

@implementation DXIPJSipManager

#pragma mark - Lifecycle
// Instance accessor
+ (DXIPJSipManager *)getInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(_instance == nil) {
            _instance = [[DXIPJSipManager alloc] initPrivate];
        }
    });
    // Update Credentials
    //_instance.sipCredentials = [[DXIPreferencesManager getInstance] getSipCredentials];
    return _instance;
}

// Throws exception as this class is a Singleton all access should go through [PJSipWrapper getInstance] method.
- (id)init {
    @throw [NSException exceptionWithName:@"InvalidOperation" reason:@"Cannot invoke init." userInfo:nil];
}

// Private instance initiator
- (id)initPrivate {
    self = [super init];
    if(self) {
        selfRef = self;
        self.sipState = kSIP_STATE_IDLE;
        self.isSoundEnabled = NO;
        self.isRegistered = NO;
        self.isInited = NO;
        self.isAddedAccount = NO;
        self.isLogged = NO;
        self.contactCentreNumber = @"3851000";
        self.agentNumber = @"501406";
        self.agentPasscode = @"501406";
        self.sipDomain = @"sip.easycontactnow.com";
        self.sipUser = @"dxi";
        self.sipPasscode = @"dxi";
        
    }
    return self;
}

- (void)setDelegate:(id<DXIPJSipManagerDelegate>)delegate {
    _delegate = delegate;
}

#pragma mark - Public Interface
- (void)registerToSipServerAndDoAgentLogin {
    [self.statusTimer invalidate];
    self.statusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkSoundStatus) userInfo:nil repeats:YES];
    [self.statusTimer fire];
    [self unregisterFromSipServer];
    
    //self.sipCredentials = [[DXIPreferencesManager getInstance] getSipCredentials];
    //DDLogDebug(@"Calling cc with number: %@\nAgent number: %@\nAgend passcode: %@", self.sipCredentials.easycallContactCentreNumber, self.sipCredentials.easycallAgentNumber, self.sipCredentials.easycallAgentPassword);
    self.sipState = kSIP_STATE_REGISTERING;
    
    /* Create pjsua first! */
    status = pjsua_create();
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d @status = pjsua_create()\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        [self failWithMessage:[NSString stringWithFormat:@"Error in pjsua_create(): %d", status]];
        return;
    }
    
    /* If URL is a valid SIP URL */
    //char *sipUrl = [DXIConvertionUtils cStringFromNSString:[NSString stringWithFormat:@"sip:%@@%@", self.contactCentreNumber, self.sipDomain]];
    char *sipUrl = [self cStringFromNSString:[NSString stringWithFormat:@"%@",@"sip:3851000@sip.easycontactnow.com"]];
    status = pjsua_verify_url(sipUrl);
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d @status = pjsua_verify_url(%s)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, sipUrl, status);
        [self failWithMessage:[NSString stringWithFormat:@"Invalid URL: %d", status]];
        return;
    }
    
    /* Init pjsua */
    pjsua_config_default(&cfg);
    cfg.cb.on_reg_state = &on_reg_state;
    cfg.cb.on_call_state = &on_call_state;
    cfg.cb.on_incoming_call = &on_incoming_call;
    cfg.cb.on_call_media_state = &on_call_media_state;
    
    pjsua_logging_config_default(&log_cfg);
    log_cfg.console_level = kPJSUA_LOG_LEVEL;
    log_cfg.level = kPJSUA_LOG_LEVEL;
    
    status = pjsua_init(&cfg, &log_cfg, NULL);
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d @pjsua_init(&cfg, &log_cfg, NULL)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        [self failWithMessage:[NSString stringWithFormat:@"Error in pjsua_init(): %d", status]];
        return;
    }
    
    self.isInited = YES;
    
    /* Add UDP transport. */
    pjsua_transport_config_default(&transport_cfg);
    transport_cfg.port = kPJSUA_DEFAULT_PORT;
    status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &transport_cfg, NULL);
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d @pjsua_transport_create(PJSIP_TRANSPORT_UDP, &transport_cfg, NULL)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        [self failWithMessage:[NSString stringWithFormat:@"Error creating transport: %d", status]];
        return;
    }
    
    /* Initialization is done, now start pjsua */
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d @pjsua_start()\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        [self failWithMessage:[NSString stringWithFormat:@"Error starting pjsua: %d", status]];
        return;
    }
    
    /* Register to SIP server by creating SIP account. */
    pjsua_acc_config_default(&acc_cfg);
    //char *sipID = [DXIConvertionUtils cStringFromNSString:[NSString stringWithFormat:@"sip:%@@%@", self.sipUser, self.sipDomain]];
    char *sipID = [self cStringFromNSString:[NSString stringWithFormat:@"%@",@"sip:dxi@sip.easycontactnow.com"]];
    
    //acc_cfg.id = pj_str("sip:" SIP_USER "@" SIP_DOMAIN);
    acc_cfg.id = pj_str(sipID);
    
    //char *regUri = [DXIConvertionUtils cStringFromNSString:[NSString stringWithFormat:@"sip:%@", self.sipDomain]];
    char *regUri = [self cStringFromNSString:[NSString stringWithFormat:@"%@",@"sip:sip.easycontactnow.com"]];
    acc_cfg.reg_uri = pj_str(regUri);
    acc_cfg.cred_count = 1;
    acc_cfg.cred_info[0].realm = pj_str("*");
    acc_cfg.cred_info[0].scheme = pj_str("Digest");
    acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    acc_cfg.cred_info[0].data = pj_str([self cStringFromNSString:self.sipPasscode]);
    acc_cfg.cred_info[0].username = pj_str([self cStringFromNSString:self.sipUser]);
    
    status = pjsua_acc_add(&acc_cfg, PJ_SUCCESS, &acc_id);
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d pjsua_acc_add(&acc_cfg, PJ_SUCCESS, &acc_id)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        [self failWithMessage:[NSString stringWithFormat:@"Error adding account: %d", status]];
    }
    else {
        self.isRegistered = YES;
        self.isAddedAccount = YES;
        self.sipState = kSIP_STATE_REGISTERED;
        [self callContactCenter];
    }
}

- (void)failWithMessage:(NSString *)message {
    //DXISipResponse *error = [DXISipResponse new];
    //error.errorMessage = message;
    [self unregisterFromSipServer];
    //[self.delegate onRegisterToSipServerAndLogAgentDidFailWithResponse:error];
}

- (void)callContactCenter {
    self.sipState = kSIP_STATE_CALLING_COTACT_CENTRE;
    NSString *agentNumber = [NSString stringWithString:self.agentNumber];
    while(agentNumber.length < 6) {
        agentNumber = [NSString stringWithFormat:@"0%@", agentNumber];
    }
    NSString *agentPassword = [NSString stringWithString:self.agentPasscode];
    while(agentPassword.length < 6) {
        agentPassword = [NSString stringWithFormat:@"0%@", agentPassword];
    }
    //char *sipUrl = [DXIConvertionUtils cStringFromNSString:[NSString stringWithFormat:@"sip:%@@%@", self.sipCredentials.easycallContactCentreNumber, self.sipCredentials.sipDomain]];
    //char *sipUrl = [DXIConvertionUtils cStringFromNSString:[NSString stringWithFormat:@"sip:485%@%@@%@", self.agentNumber, self.agentPasscode, self.sipDomain]];
    char *sipUrl = [self cStringFromNSString:[NSString stringWithFormat:@"%@",@"sip:485501406501406@sip.easycontactnow.com"]];
    
    /* Make call to the URL. */
    pj_str_t uri = pj_str(sipUrl);
    status = pjsua_call_make_call(acc_id, &uri, 0, NULL, NULL, NULL);
    if (status != PJ_SUCCESS) {
        NSLog(@"%s - %d @pjsua_call_make_call(acc_id, &[%s], 0, NULL, NULL, NULL)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, sipUrl, status);
        [self failWithMessage:[NSString stringWithFormat:@"Error calling contact centre: %d", status]];
        //[self disableSound];
        return;
    }
    
    self.sipState = kSIP_STATE_LOGGED;
    self.isLogged = YES;
    
    [self.delegate onRegisterToSipServerAndLogAgentDidFinish];
}

- (void)enableSound {
    status = pjsua_conf_connect(0, call_info.conf_slot);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        return;
    }
    
    status = pjsua_conf_connect(call_info.conf_slot, 0);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        // If outbound channel creation fails, destroy inbound channel
        pjsua_conf_disconnect(0, call_info.conf_slot);
        return;
    }
    
    self.isSoundEnabled = YES;
}

- (void)disableSound {
    NSLog(@"Disabling sound");
    status = pjsua_conf_disconnect(0, call_info.conf_slot);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        self.isSoundEnabled = YES;
        return;
    }
    
    status = pjsua_conf_disconnect(call_info.conf_slot, 0);
    if(status != PJ_SUCCESS) {
        self.isSoundEnabled = YES;
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        return;
    }
}

// TODO: implement/use
- (void)unregisterFromSipServer {
    if(self.isInited) {
        if(self.isSoundEnabled) {
            [self disableSound];
        }
        
        if(self.isAddedAccount) {
            status = pjsua_acc_del(acc_id);
            if(status != PJ_SUCCESS) {
                NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
            }
        }
        
        status = pjsua_destroy();
        if(status != PJ_SUCCESS) {
            NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        }
    }
    
    //    if(self.isAddedAccount) {
    //        status = pjsua_acc_del(acc_id);
    //        if(status != PJ_SUCCESS) {
    //            DDLogError(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
    //        }
    //    }
    
    
    
    self.isRegistered = NO;
    self.isSoundEnabled = NO;
    self.isInited = NO;
    self.isAddedAccount = NO;
    self.isLogged = NO;
}

// TODO: implement/use
- (void)hungUp {
    NSLog(@"[DXIPJSipManager hungUp]");
    pjsua_call_hangup_all();
}

- (void)checkSoundStatus {
    if (call_info.media_status == PJSUA_CALL_MEDIA_ACTIVE && self.sipState == kSIP_STATE_LOGGED) {
        if(self.isSoundEnabled == NO && self.isRegistered == YES && self.isInited == YES && self.isAddedAccount == YES  && self.isLogged == YES) {
            [self enableSound];
        }
    }
    else {
        self.isSoundEnabled = NO;
    }
}

#pragma mark - Other Methods

#pragma mark - C/C++ callback wrapping methods
/* Obj-C method that implements logic for on_incoming_call(pjsua_acc_id, pjsua_call_id, pjsip_rx_data) */
- (void)onIncommingCallAccId:(pjsua_acc_id)accId callId:(pjsua_call_id)callId rxData:(pjsip_rx_data *)rdata {
    // Assign parameter values to static variables
    acc_id = accId;
    call_id = callId;
    
    // Update call_info variable
    status = pjsua_call_get_info(call_id, &call_info);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
    }
    
    //PJ_LOG(3,(FILE, "Incoming call from %.*s!!", (int)call_info.remote_info.slen, call_info.remote_info.ptr));
    
    /* Automatically answer incoming calls with 200/OK */
    status = pjsua_call_answer(call_id, 200, NULL, NULL);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
    }
}

/* Obj-C method that implements logic for on_incoming_call() callback */
- (void)onCallStateCallId:(pjsua_call_id)callId event:(pjsip_event *)e {
    // Assign parameter values to static variables
    call_id = callId;
    
    // Update call_info variable
    status = pjsua_call_get_info(call_id, &call_info);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
    }
    
    //PJ_LOG(3,(FILE, "Call %d state=%.*s", call_id, (int)call_info.state_text.slen, call_info.state_text.ptr));
    
    //    if(e->body.tsx_state.src.status != PJ_SUCCESS) {
    //        // TODO: handle error
    //        return;
    //    }
}

- (void)onCallMediaState:(pjsua_call_id)callId {
    // Assign parameter values to static variables
    call_id = callId;
    
    // Update call_info variable
    status = pjsua_call_get_info(callId, &call_info);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
    }
}

- (void)onIncommingCall {
    
}

- (void)onRegState:(pjsua_acc_id)accId {
    acc_id = accId;
    status = pjsua_acc_get_info(acc_id, &acc_info);
    if(status != PJ_SUCCESS) {
        NSLog(@"%s - %d @pjsua_acc_get_info(acc_id, &acc_info)\nstatus = %d", __PRETTY_FUNCTION__, __LINE__, status);
        // TODO: handle error
        return;
    }
    
    if(acc_info.status != PJSIP_SC_OK && acc_info.status != PJSIP_SC_ACCEPTED) {
        // TODO: handle status
        return;
    }
    
    if(self.sipState == kSIP_STATE_REGISTERED) {
        //[self callContactCenter];
    }
}

#pragma mark - C functions
static void on_reg_state(pjsua_acc_id acc_id) {
    [selfRef onRegState:acc_id];
}

/* Callback called by the library upon receiving incoming call */
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    [selfRef onIncommingCallAccId:acc_id callId:call_id rxData:rdata];
}

/* Callback called by the library when call's state has changed */
static void on_call_state(pjsua_call_id call_id, pjsip_event *e) {
    [selfRef onCallStateCallId:call_id event:e];
}

/* Callback called by the library when call's media state has changed */
static void on_call_media_state(pjsua_call_id call_id) {
    [selfRef onCallMediaState:call_id];
}

/* Display error and exit application */
//static void error_exit(const char *title, pj_status_t status)
//{
//    pjsua_perror(FILE, title, status);
//    pjsua_destroy();
//    exit(1);
//}

#pragma mark - Override
- (NSString *)description {
    NSMutableString *description = [NSMutableString new];
    
    [description appendFormat:@"<%@>\n", self.class];
    [description appendFormat:@"    <sipState = %@/>\n", self.sipState];
    [description appendFormat:@"    <sipDomain = %@/\n>", self.sipDomain];
    [description appendFormat:@"    <sipUser = %@/\n>", self.sipUser];
    [description appendFormat:@"</%@>\n", self.class];
    
    return description;
}

#pragma mark - Convertions between NSString and *char (both ways)
- (char *)cStringFromNSString:(NSString *)string {
    if(!string) {
        return nil;
    }
    
    if(string.length == 0) {
        return "";
    }
    
    char *result = calloc([string length] + 1, 1);
    [string getCString:result maxLength:[string length] + 1 encoding:NSUTF8StringEncoding];
    
    return result;
}

- (BOOL)compareCString:(char *)a toCString:(char *)b {
    if(a == nil || b == nil) {
        return NO;
    }
    
    int len = strlen(a);
    if(len != strlen(b)) {
        return NO;
    }
    
    for(int i = 0; i < len; i ++) {
        if(a[i] != b[i]) {
            return NO;
        }
    }
    
    return YES;
}

@end