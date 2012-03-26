//
//  PrivilegedActions.h
//  Cube
//
//  Created by Dave Tong on 22/03/12.
//  Copyright 2012 David Tong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InterSystemsInstance.h"
#import <syslog.h>

@interface PrivilegedActions : NSObject {
@private
    
}

- (void)toggleInstanceAutoStart:(InterSystemsInstance *)instance:(BOOL)toggle;
- (void)createAutoStartFiles:(InterSystemsInstance *)instance;

- (BOOL)startStopInstance:(InterSystemsInstance *)instance;
- (void)restartInstance:(InterSystemsInstance *)instance;

@end
