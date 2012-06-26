//
//  KSAppDelegate.m
//  ShortcutRecorderTest
//
//  Created by Keith Smiley on 6/26/12.
//  Copyright (c) 2012 Keith Smiley. All rights reserved.
//

#import "KSAppDelegate.h"

@implementation KSAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [KSAppDelegate universalAccessNeedsToBeTurnedOn];
    userDefaults = [NSUserDefaults standardUserDefaults];

//    [shortcutRecorder setCanCaptureGlobalHotKeys:YES]; // Defined in interface builder
//    [shortcutRecorderTwo setCanCaptureGlobalHotKeys:YES];

    PTKeyCombo *keys = [[PTKeyCombo alloc] initWithPlistRepresentation:[userDefaults objectForKey:@"hi"]];
    KeyCombo someKeyCombo = SRMakeKeyCombo([keys keyCode], SRCarbonToCocoaFlags([keys modifiers]));
    [shortcutRecorder setKeyCombo:someKeyCombo];
    
    keys = [[PTKeyCombo alloc] initWithPlistRepresentation:[userDefaults objectForKey:@"hello"]];
    someKeyCombo = SRMakeKeyCombo([keys keyCode], SRCarbonToCocoaFlags([keys modifiers]));
    [shortcutRecorderTwo setKeyCombo:someKeyCombo];

}

- (void)sayHI {
    NSLog(@"Shortcutrecordertwo");
}

- (void)sayBye {
    NSLog(@"Shortcutrecorder");
}

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason {
    KeyCombo kc;
    BOOL isTaken = NO;
	if (aRecorder == shortcutRecorder) {
		kc = [shortcutRecorderTwo keyCombo];
	} else if (aRecorder == shortcutRecorderTwo) {
        kc = [shortcutRecorder keyCombo];
    }
    if (kc.code == keyCode && kc.flags == flags) {
        isTaken = YES;
        *aReason = @"it's already in use by ShortcutRecorderTest";
        return isTaken;
    }
    
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo {
    userDefaults = [NSUserDefaults standardUserDefaults];
    hotKeyCenter = [PTHotKeyCenter sharedCenter];
    
    signed short code = newKeyCombo.code;
    unsigned int flags = [aRecorder cocoaToCarbonFlags:newKeyCombo.flags];
    akeyCombo = [[PTKeyCombo alloc] initWithKeyCode:code modifiers:flags];
    
    if (aRecorder == shortcutRecorder) {
        [hotKeyCenter unregisterHotKey:otherHotKey]; // The Key to happiness
        
        otherHotKey = [[PTHotKey alloc] initWithIdentifier:[userDefaults objectForKey:@"hi"] keyCombo:akeyCombo];
        [userDefaults setObject:[akeyCombo plistRepresentation] forKey:@"hi"];
        [otherHotKey setTarget:self];
        [otherHotKey setAction:@selector(sayBye)];
        [hotKeyCenter registerHotKey:otherHotKey];
    } else if (aRecorder == shortcutRecorderTwo) {
        [hotKeyCenter unregisterHotKey:hotKey];
        
        hotKey = [[PTHotKey alloc] initWithIdentifier:[userDefaults objectForKey:@"hello"] keyCombo:akeyCombo];
        [userDefaults setObject:[akeyCombo plistRepresentation] forKey:@"hello"];
        [hotKey setTarget:self];
        [hotKey setAction:@selector(sayHI)];
        [hotKeyCenter registerHotKey:hotKey];
    }

//    if (newKeyCombo.code == ShortcutRecorderEmptyCode & newKeyCombo.flags == ShortcutRecorderEmptyFlags) {
//    }
    
    [userDefaults synchronize];
}


+ (BOOL)universalAccessNeedsToBeTurnedOn {
    if (!AXAPIEnabled()) {
        NSString *message = NSLocalizedString(@"To use global hotkeys you must \"Enable access for assistive devices\" in the Universal Access preferences pane.", nil);
        NSUInteger result = NSRunAlertPanel(message, @"", NSLocalizedString(@"OK", nil), NSLocalizedString(@"Quit", nil), NSLocalizedString(@"Cancel", nil));
        
        switch (result) {
            case NSAlertDefaultReturn:
                [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
                break;
                
            case NSAlertAlternateReturn:
                [NSApp terminate:self];
                break;
        }
        return YES;
    } else {
        return NO;
    }
}

@end