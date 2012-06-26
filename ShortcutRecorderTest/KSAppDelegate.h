//
//  KSAppDelegate.h
//  ShortcutRecorderTest
//
//  Created by Keith Smiley on 6/26/12.
//  Copyright (c) 2012 Keith Smiley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import "PTHotKey.h"
#import "PTHotKeyCenter.h"

//@class PTHotKey; Not particularly necessary

@interface KSAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet SRRecorderControl *shortcutRecorder;
    IBOutlet SRRecorderControl *shortcutRecorderTwo;
    
    PTHotKey *globalHotKey;
    PTKeyCombo *akeyCombo;
    PTHotKey *hotKey;
    PTHotKey *otherHotKey;
    PTHotKeyCenter *hotKeyCenter;
    NSUserDefaults *userDefaults;
}

@property (assign) IBOutlet NSWindow *window;

+ (BOOL)universalAccessNeedsToBeTurnedOn;

@end