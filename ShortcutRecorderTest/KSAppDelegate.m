//
//  KSAppDelegate.m
//  ShortcutRecorderTest
//
//  Created by Keith Smiley on 6/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KSAppDelegate.h"

@implementation KSAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [KSAppDelegate universalAccessNeedsToBeTurnedOn];
    userDefaults = [NSUserDefaults standardUserDefaults];
    
    [shortcutRecorder setCanCaptureGlobalHotKeys:YES];
    [shortcutRecorderTwo setCanCaptureGlobalHotKeys:YES];
    
    id firstKey = [userDefaults objectForKey:@"hi"];
    PTKeyCombo *keys = [[PTKeyCombo alloc] initWithPlistRepresentation:firstKey];
    
    KeyCombo someKeyCombo = SRMakeKeyCombo([keys keyCode], SRCarbonToCocoaFlags([keys modifiers]));
    [shortcutRecorder setKeyCombo:someKeyCombo];
    
    id secondKey = [userDefaults objectForKey:@"hello"];
    keys = [[PTKeyCombo alloc] initWithPlistRepresentation:secondKey];
    someKeyCombo = SRMakeKeyCombo([keys keyCode], SRCarbonToCocoaFlags([keys modifiers]));
    [shortcutRecorderTwo setKeyCombo:someKeyCombo];

}

- (void)sayHI {
    NSLog(@"hiff");
}

- (void)sayBye {
    NSLog(@"byee");
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
        *aReason = @"it's already in use by SRTest";
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
        id firstKey = [userDefaults objectForKey:@"hi"];
        [hotKeyCenter unregisterHotKey:otherHotKey]; // The Key to happiness
        otherHotKey = nil;
        
        otherHotKey = [[PTHotKey alloc] initWithIdentifier:firstKey keyCombo:akeyCombo];
        [userDefaults setObject:[akeyCombo plistRepresentation] forKey:@"hi"];
        [otherHotKey setTarget:self];
        [otherHotKey setAction:@selector(sayBye)];
        [hotKeyCenter registerHotKey:otherHotKey];
    } else if (aRecorder == shortcutRecorderTwo) {
        id secondKey = [userDefaults objectForKey:@"hello"];
        [hotKeyCenter unregisterHotKey:hotKey];
        hotKey = nil;
        
        hotKey = [[PTHotKey alloc] initWithIdentifier:secondKey keyCombo:akeyCombo];
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
        NSString *message = NSLocalizedString(@"QuickCursor requires that you launch the Universal Access preferences pane and turn on \"Enable access for assistive devices\".", nil);
        NSUInteger result = NSRunAlertPanel(message, @"", NSLocalizedString(@"OK", nil), NSLocalizedString(@"Quit QuickCursor", nil), NSLocalizedString(@"Cancel", nil));
        
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