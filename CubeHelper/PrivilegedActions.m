//
//  PrivilegedActions.m
//  Cube
//
//  Created by Dave Tong on 22/03/12.
//  Copyright 2012 David Tong. All rights reserved.
//

#import "PrivilegedActions.h"


@implementation PrivilegedActions

NSString * const Started = @"running";
NSString * const Stopped = @"down";

- (void)toggleInstanceAutoStart:(InterSystemsInstance *)instance:(BOOL)toggle {
    NSError *error = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *disableFile = [NSString stringWithFormat:@"/Library/StartupItems/%@/.disabled", instance.name];

    // rwxr-xr-x 755
    NSMutableDictionary *attr = [NSMutableDictionary dictionary]; 
    [attr setObject:@"root" forKey:NSFileOwnerAccountName];
    [attr setObject:@"wheel" forKey:NSFileGroupOwnerAccountName]; 
    [attr setObject:[NSNumber numberWithInt:0444] forKey:NSFilePosixPermissions];
    
    if (toggle == TRUE) {
        [fileManager removeItemAtPath:disableFile error:&error];
        syslog(LOG_NOTICE, "Enabled StartupItem '%s'", [instance.name UTF8String]);
    }
    else {
        [fileManager createFileAtPath:disableFile contents:nil attributes:attr];
        if (error == nil) {
            syslog(LOG_NOTICE, "Disabled StartupItem '%s'", [instance.name UTF8String]);
        }
        else {
            syslog(LOG_ERR, "Error toggling StartupItem '%s': %s", [instance.name UTF8String], [[error localizedDescription] UTF8String]);
        }
    }
}

- (void)createAutoStartFiles:(InterSystemsInstance *)instance {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *dir = [NSString stringWithFormat:@"/Library/StartupItems/%@", instance.name];
    NSString *instanceFile = [NSString stringWithFormat:@"/Library/StartupItems/%@/%@", instance.name, instance.name];
    NSString *plistFile = [NSString stringWithFormat:@"/Library/StartupItems/%@/StartupParameters.plist", instance.name];
    NSData *instanceContents = [NSString stringWithFormat:
                                @"#!/bin/sh\n"
                                @"##############################################################\n"
                                @"# Copyright (c) 2012, InterSystems Corporation               #\n"
                                @"# All rights reserved.                                       #\n"
                                @"##############################################################\n"
                                @"# Starts/Stops Cache when the OS requests it to.\n"
                                @"\n"
                                @". /etc/rc.common # Use common startup params and settings.\n"
                                @"\n"
                                @"# Get the MacOS X version number.\n"
                                @"os_vers=`sw_vers | grep ProductVersion | awk '{ print $2 }'`\n"
                                @"os1=`echo $os_vers | cut -d. -f1`\n"
                                @"os2=`echo $os_vers | cut -d. -f2`\n"
                                @"os3=`echo $os_vers | cut -d. -f3`\n"
                                @"IS_SUPPORTED=0  # Host is running a supported version of MACOSX.\n"
                                @"\n"
                                @"# Parse each portion of the version.  We only run on systems starting\n"
                                @"# with 10.3 and later (Jaguar).\n"
                                @"if [ $os1 -ge 10 ]; then\n"
                                @"\tif [ ${os2:=0} -ge 3 ]; then\n"
                                @"\t\t# Jaguar\n"
                                @"\t\tIS_SUPPORTED=1\n"
                                @"\telse\n"
                                @"\t\tConsoleMessage \"Cache requires MacOS 10.3 or newer\"\n"
                                @"\tfi\n"
                                @"fi\n"
                                @"\n"
                                @"# Location of executables.\n"
                                @"DEVNULL=/dev/null\n"
                                @"LOGFILE=/tmp/Cache.$$\n"
                                @"\n"
                                @"# Starts Cache.\n"
                                @"StartService() {\n"
                                @"\tif [ $IS_SUPPORTED -gt 0 ]; then\n"
                                @"\t\tConsoleMessage \"Starting %@\"\n"
                                @"\t\ttouch $LOGFILE\n"
                                @"\t\tif [ -d %@/mgr -a -x %@/bin/cstart ]\n"
                                @"\t\tthen\n"
                                @"\t\t\t%@/cstart > $LOGFILE < $DEVNULL&\n"
                                @"\t\tfi\n"
                                @"\t\tConsoleMessage -s \"%@\"\n"
                                @"\telse\n"
                                @"\t\tConsoleMessage -f \"%@\"\n"
                                @"\tfi\n"
                                @"}\n"
                                @"\n"
                                @"\n"
                                @"# Stops Cache.\n"
                                @"StopService() {\n"
                                @"\tConsoleMessage \"Stopping Cache\"\n"
                                @"\t\tCURDIR=`pwd`\n"
                                @"\t\tif [ -d %@/mgr -a -x %@/bin/cstart ]\n"
                                @"\t\tthen\n"
                                @"\t\t\tcd %@/mgr\n"
                                @"\t\t\t../bin/cstop quietly\n"
                                @"\t\tfi\n"
                                @"\tcd $CURDIR\n"
                                @"}\n"
                                @"\n"
                                @"# Restarts Cache.\n"
                                @"RestartService() {\n"
                                @"\tConsoleMessage \"Restarting Cache\"\n"
                                @"\tCURDIR=`pwd`\n"
                                @"\tif [ -d %@/mgr -a -x %@/bin/cstart ]\n"
                                @"\tthen\n"
                                @"\t\tcd %@/mgr\n"
                                @"\t\t../bin/cstop quietly\n"
                                @"\t\t../bin/cstart > $LOGFILE < $DEVNULL&\n"
                                @"\tfi\n"
                                @"\tcd $CURDIR\n"
                                @"}\n"
                                @"\n"
                                @"\n"
                                @"##############################\n"
                                @"# Here's the main code.\n"
                                @"##############################\n"
                                @"RunService \"$1\"\n"
                                @"exit 0\n"
                                , instance.name
                                , instance.dir
                                , instance.dir
                                , instance.dir
                                , instance.name
                                , instance.name
                                , instance.dir
                                , instance.dir
                                , instance.dir
                                , instance.dir
                                , instance.dir
                                , instance.dir];
    
    NSData *plistContents = [NSString stringWithFormat:
                             @"{\n"
                             @"\tDescription\t\t\t= \"%@\";\n"
                             @"\tProvides\t\t\t\t= (\"%@\");\n"
                             @"\tOrderPreference\t= \"Late\";\n"
                             @"\tMessages\t\t\t\t=\n"
                             @"\t{\n"
                             @"\t\tstart\t\t\t\t\t= \"Starting %@\";\n"
                             @"\t\tstop\t\t\t\t\t= \"Stopping %@\";\n"
                             @"\t};\n"
                             @"}\n"
                             , instance.name, instance.name, instance.name, instance.name];
    
    // rwxr-xr-x 755
    NSMutableDictionary *attr = [NSMutableDictionary dictionary]; 
    [attr setObject:@"root" forKey:NSFileOwnerAccountName];
    [attr setObject:@"wheel" forKey:NSFileGroupOwnerAccountName]; 
    [attr setObject:[NSNumber numberWithInt:0755] forKey:NSFilePosixPermissions];
    
    [fileManager createDirectoryAtPath:dir withIntermediateDirectories:TRUE attributes:attr error:&error];
    
    if (error == nil) {
        syslog(LOG_NOTICE, "Created StartupItem for '%s'", [instance.name UTF8String]);
    }
    else {
        syslog(LOG_ERR, "Error creating StartupItem '%s': %s", [instance.name UTF8String], [[error localizedDescription] UTF8String]);
    }
    
    
    [fileManager createFileAtPath:instanceFile contents:instanceContents attributes:attr];
    
    [attr setObject:[NSNumber numberWithInt:0644] forKey:NSFilePosixPermissions];
    [fileManager createFileAtPath:plistFile contents:plistContents attributes:attr];
    
}

- (BOOL)startStopInstance:(InterSystemsInstance *)instance {
    NSString *action;
    NSString *parameter = nil;
    
    if ([instance.status isEqualToString:Started]) {
        action = @"stop";
        parameter = @"quietly";
    }
    else if ([instance.status isEqualToString:Stopped]) {
        action = @"start";
    }
    else {
        action = @"force";
    }
    
    //Setup the task execution
    NSPipe *output = [NSPipe pipe];
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:@"/usr/bin/ccontrol"];
    [task setArguments:[NSArray arrayWithObjects:action, instance.name, parameter, nil]];
    [task setStandardOutput:output];
    
    //launch task and wait for completion
    [task launch];
    [task waitUntilExit];
    int status = [task terminationStatus];
    
    if (status == 0) {
        if ([instance.status isEqualToString:Started]) {
            instance.status = Stopped;
            syslog(LOG_NOTICE, "Stopped '%s'", [instance.name UTF8String]);
        }
        else if ([instance.status isEqualToString:Stopped]) {
            instance.status = Started;
            syslog(LOG_NOTICE, "Started '%s'", [instance.name UTF8String]);
        }
        return TRUE;
    }
    else {
        syslog(LOG_NOTICE, "Attempted to %s %s but failed!", [action UTF8String], [instance.name UTF8String]);
        return FALSE;
    }
}

- (void)restartInstance:(InterSystemsInstance *)instance {
    
    //Setup the task execution
    NSPipe *output = [NSPipe pipe];
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:@"/usr/bin/ccontrol"];
    [task setArguments:[NSArray arrayWithObjects:@"stop", instance.name, @"quietly", @"restart", nil]];
    [task setStandardOutput:output];
    
    //launch task and wait for completion
    [task launch];
    [task waitUntilExit];
    int status = [task terminationStatus];
    
    if (status == 0) {
        syslog(LOG_NOTICE, "Restarted '%s'", [instance.name UTF8String]);
    }
    else {
        syslog(LOG_NOTICE, "Error restarting %s!", [instance.name UTF8String]);
    }
}


@end
