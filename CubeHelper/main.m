//
//  main.m
//  CubeHelper
//
//  Created by Dave Tong on 22/03/12.
//  Copyright 2012 David Tong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <launch.h>
#import "PrivilegedActions.h"
#import <syslog.h>

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    syslog(LOG_NOTICE, "CubeHelper launched (uid: %d, euid: %d, pid: %d)", getuid(), geteuid(), getpid());
    
    launch_data_t req = launch_data_new_string(LAUNCH_KEY_CHECKIN);
    launch_data_t resp = launch_msg(req);
    launch_data_t machData = launch_data_dict_lookup(resp, LAUNCH_JOBKEY_MACHSERVICES);
    launch_data_t machPortData = launch_data_dict_lookup(machData, "com.InterSystems.CubeHelper.mach");
    
    mach_port_t mp = launch_data_get_machport(machPortData);
    launch_data_free(req);
    launch_data_free(resp);
    
    NSMachPort *rp = [[NSMachPort alloc] initWithMachPort:mp];
    NSConnection *c = [NSConnection connectionWithReceivePort:rp sendPort:nil];
    
    PrivilegedActions *obj = [PrivilegedActions new];
    [c setRootObject:obj];
    
    [[NSRunLoop currentRunLoop] run];

    [pool drain];
    return 0;
}

