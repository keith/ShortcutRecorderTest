## What's this?

This is an implementation of [ShortcutRecorder](http://wafflesoftware.net/shortcut/) an awesome widely used framework for allowing user defined global hotkeys. This **does** work with Apple's sandbox with ARC enabled. **Note:** This test application is Code signed. If you don't have a developer account uncheck the code signing box by clicking on the Summary options under your Target applications.

## Configuration

Configuring ShortcutRecorder, once you figure it out, is actually quite easy.

+ Start your new project, or if you're implementing it in an existing project configure it's sandbox requirements as necessary. I recommend you make a small test application similar to this before implementing it in an existing project. Or be sure you have committed your changes so you can revert if it breaks.
+ Import `Carbon.framework` and `ShortcutRecorder.framework` into your project. For `ShortcutRecorder.framework` you can either download this project and put it in your own, or you can clone the original source from the [official ShortcutRecorder home](http://code.google.com/p/shortcutrecorder/source/checkout) and compile it yourself.
+ Make sure to create a Build Phase to copy `ShortcutRecorder.framework` into your project. Do this by selecting your Target Application -> Build Phases -> Add Build Phase -> Add Copy Files then choose Frameworks from the Destination drop down and then drag `ShortcutRecorder.framework` into the action.
+ Next import the [PTHotKey files](https://github.com/Keithbsmiley/PTHotKey-Class) into your project **if you receive an initwithidentifier error be sure your PTHotKey class matches your calls as far as ": "(with the spaces) or ":" (the spacing is the difference)**. Make sure to add them to the applicable Target. If you have ARC enabled in your project then you need to mark these files with the `-fno-objc-arc` compiler flag under your Compiler Sources. Do this by selecting your Target Applications -> Build Phases -> Compile Sources then double click each of the PT files and add `-fno-objc-arc` in the Compiler Flags box.
+ Now add these headers to the necessary class in your project.

		#import <ShortcutRecorder/ShortcutRecorder.h>
		#import "PTHotKey.h"
		#import "PTHotKeyCenter.h"
		
You should also add some IBOutlets (I would recommend using IBOutlets rather than @property but I'm sure if you know more about it then me it would probably work. Try a nonatomic variation) to your project for later use. They should look something like this. (This setup is for 2 independent hotkeys)

	IBOutlet SRRecorderControl *shortcutRecorder;
    IBOutlet SRRecorderControl *shortcutRecorderTwo;
    
    PTHotKey *globalHotKey;
    PTKeyCombo *akeyCombo;
    PTHotKey *hotKey;
    PTHotKey *otherHotKey;
    PTHotKeyCenter *hotKeyCenter;
    NSUserDefaults *userDefaults;

And a great function like this `+ (BOOL)universalAccessNeedsToBeTurnedOn;` that will be used to make sure that "Enable Access for Assistive devices" is enabled

+ Now go the applicable .xib file for your project. Drag a Custom View object in, you will configure this one and then duplicated as needed.
+ First choose the File Inspector (the first utility pane) and **uncheck Use Auto Layout** if you do not do this, nothing will work.
+ Now go to the Identity Inspector (the third utility pane) and change the view's class to `SRRecorderControl` this should autocomplete for you and you should be able to choose it from the drop down *if you cannot you may not have saved your header file or you may have put the statements in the wrong one*.
+ To make your life slightly easier on the code side of this you can add some elements to the User Defined Runtime Attributes pane. If nothing else I would recommend you add `canCaptureGlobalHotKeys` as a boolean with a checked value. You can also use other keys such as `style` `allowsKeyOnly` `allowedFlags` and `escapeKeysRecord` see the [official ShortcutRecorder project](http://code.google.com/p/shortcutrecorder/source/checkout) to see how those work.
+ Lastly from the Connections Inspector (the third from the right) bind the ShortcutRecorder's delegate to the class you will be controlling it from. **This is required** and then bind it to one of the `SRRecorderControl` IBOutlets you created previously.
+ First we will implement some of the delegate methods for the ShortcutRecorder. If your delegate is elsewhere go to that class there are 2 important functions we must implement 

			(void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
			(BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
			
the first function gets called every time the key combination within a ShortcutRecorder is changed. This is where you need some code to deal with the new key combinations. For me, and 2 ShortcutRecorders, this is what mine looked like.

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
	
		//    if (newKeyCombo.code == ShortcutRecorderEmptyCode & newKeyCombo.flags == ShortcutRecorderEmptyFlags) {}
	    
	    [userDefaults synchronize];

Firstly you make sure to setup your `userDefaults` so that you can save the key combinations, and your `hotKeyCenter` which is where you register and unregister your shortcuts. As you can see in this code you grab the key code and flags from the new combination that you then create a PTKeyCombo object with. The rest of this function will vary depending on your implementation. In this setup I check to see which ShortcutRecorder is calling the delegate. Then make sure to call `unregisterHotKey` using your `hotKeyCenter` and the `PTHotKey` object you want associated with this ShortcutRecorder, this ensures that if the user wants no hot key then it will be immediately removed. Then allocate your associated `PTHotKey` by calling `initWithIdentifier` with an `id` typically an object stored in your `userDefaults` and the new `akeyCombo`. After that you save the new `akeyCombo` into your `userDefaults` using a statement like `[userDefaults setObject:[akeyCombo plistRepresentation] forKey:@"hi"];`. Next call `setTarget` with the associated target (most likely `self`) and `setAction` with a selector pointing towards the function you would like to call. **NOTE:** I've had trouble calling methods from other classes. Lastly call `registerHotKey` through your `hotKeyCenter` passing the newly configured `PTHotKey`. You can do this separately for your different recorders. If you have some code you want to run when the passed ShortcutRecorder is empty using this if statement `if (newKeyCombo.code == ShortcutRecorderEmptyCode & newKeyCombo.flags == ShortcutRecorderEmptyFlags)`. Lastly I synchronized my userDefaults.

+ After you've implemented that heavy lifting as needed head over to your `(BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason` function. This function is called to check if the hotkey a user is trying to register is already taken. **NOTE:** This is just for checking within your own application, the framework takes care of this globally. If you don't care about implementing this (which you should) you can always just use `return NO;`. Otherwise what you need to do is check between your shortcuts, this method works fine when you just have 2 ShortcutRecorders when you have more you will want to come up with something else.

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

This code checks to see which recorder is being changed, and gets the key code and flags stored in the other recorder to make sure they don't overlap. If they are exactly the same an NSAlert is called incorporating the `aReason` string telling the user why they cannot use it. Be sure to read the wording of this to make sure it makes sense.

+ Now head over to your `(void)applicationDidFinishLaunching:(NSNotification *)aNotification` or comparable function. First I would recommend calling `+ (BOOL)universalAccessNeedsToBeTurnedOn;`. Your implementation should look something like this. (thanks to [QuickCursor](https://github.com/jessegrosjean/quickcursor) for this code)

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
		
+ If you chose not to implement User Runtime Attributes in Interface Builder you need to call `[shortcutRecorder setCanCaptureGlobalHotKeys:YES];` for each of your recorders.
+ Lastly you need to make sure to load your shortcuts when your application is launched. Your implementation may vary.

		userDefaults = [NSUserDefaults standardUserDefaults];
		PTKeyCombo *keys = [[PTKeyCombo alloc] initWithPlistRepresentation:[userDefaults objectForKey:@"hi"]];
	    KeyCombo someKeyCombo = SRMakeKeyCombo([keys keyCode], SRCarbonToCocoaFlags([keys modifiers]));
	    [shortcutRecorder setKeyCombo:someKeyCombo];
	    
	    keys = [[PTKeyCombo alloc] initWithPlistRepresentation:[userDefaults objectForKey:@"hello"]];
	    someKeyCombo = SRMakeKeyCombo([keys keyCode], SRCarbonToCocoaFlags([keys modifiers]));
	    [shortcutRecorderTwo setKeyCombo:someKeyCombo];
	    
This grabs the key codes you previously stored in your userDefaults and loads them back into the recorders.

+ Test test test. Ship.