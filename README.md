MMLayershots
============

**Layershots takes your iOS app and converts the view hierarchy into a layered photoshop file. It's screenshots on steroids.**

Iterating on the design of an existing app can be tedious. Oftentimes the original design assets aren't available anymore or have become outdated. Taking a flattened screenshot (png) of the current app gives an up to date view, but slicing out parts of the UI and reconstructing occluded areas is time consuming.

Layershots eases the pain a little: Whenever you take a screenshot of your app, it generates a Photoshop(PSD) file from your entire app view hierarchy. You can then take the psd file and dump it into your psd editing tool of choice (Photoshop, Pixelmator, Acorn and yes, even GIMP) and adjust the layers as you like.


##(Static) usecases

Visual changes can often be iterated much faster in a graphical tool such as Photoshop because it doesn't require the compile/run/navigate cycle. The ultimate goal is to [increase experimentation](http://vimeo.com/36579366).

*"How would the icon look like if it were in another color?"*

![color animation][]

*"How would the app look like if we'd replaced the chat icon?"*

![icon animation][]

##Animation

*“Most people make the mistake of thinking design is what it looks like. People think it’s this veneer – that the designers are handed this box and told, ‘Make it look good!’ That’s not what we think design is. It’s not just what it looks like and feels like. Design is how it works.” – Steve Jobs*

Framer.js is one of the best tools we currently have out there to quickly prototype out animations and interactions. Take the psd, load it up with with Framer.js and bring your UI to life, with just a few lines of javascript.

![framer.js sample][]

For more infos, watch [Koen present the framework](http://vimeo.com/74712901) and make sure to [check out the examples](http://examples.framerjs.com/#Google Now - Overview.framer) on their website too.

##How to use Layershots?

The preferred way to install is via Cocoapods. Add this to your Podfile:
	
	pod 'MMLayershots'

*Note (20.05.2014): There's a problem with the spec I pushed yesterday to Cocoapods/Specs. Unfortunately this comes exactly at the time, where Cocoapods is transitioning to [Cocoapods Trunk][]. Pods are 'frozen' during the transitioning period (around a week), so I won't be able to push a fix to the official Cocoapods repository until then. For now, you'll need to reference the podspec in this repository directly (or download the files manually):*

	pod 'MMLayershots', :podspec => 'https://raw.githubusercontent.com/vpdn/MMLayershots/master/MMLayershots.podspec'


In the Application Delegate, initialize the MMLayershots shared instance:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[[MMLayershots sharedInstance] setDelegate:self];
    return YES;
}
```

then implement the delegate methods:

```objc
- (CGFloat)shouldCreatePSDDataAfterDelay {
	// set a delay, e.g. to show a notification before starting the capture.
	// During the capture, the screen currently doesn't support showing any
	// progress indication. Everything that is shown will just simply be rendered
	// as well.
	CGFloat delay = 3.0;
    return delay;
}

- (void)willCreatePSDDataForScreen:(UIScreen *)screen {
    //Creating psd now...
}

- (void)didCreatePSDDataForScreen:(UIScreen *)screen data:(NSData *)data {
#if TARGET_IPHONE_SIMULATOR
    [data writeToFile:@"/tmp/layershotsDemo.psd" atomically:NO];
    NSLog(@"Saving psd to /tmp/layershotsDemo.psd");
#else
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailVC = [MFMailComposeViewController new];
        [mailVC addAttachmentData:data mimeType:@"image/vnd.adobe.photoshop" fileName:@"layershots.psd"];
        mailVC.delegate = self;
        [self presentViewController:mailVC animated:YES completion:nil];
    }
#endif
}
```

The iPhone Simulator doesn't trigger the screenshot notification when a screenshot is saved. You can trigger it manually by assigning a custom shortcut. Add this in your root viewcontroller or anywhere else along the responder chain:

```objc
#if TARGET_IPHONE_SIMULATOR
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
	// save
    UIKeyCommand *command = [UIKeyCommand keyCommandWithInput:@"s" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift action:@selector(didRequestPSDCreationFromCurrentViewState)];
    return @[command];
}

- (void)didRequestPSDCreationFromCurrentViewState {
    // simulate a screenshot notification
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationUserDidTakeScreenshotNotification object:nil];
    });
}
#endif
```


##Notes
- The generated psd file is currently bigger than it needs to be. There isn't any bounds calculation in yet, so every layer is rendered in full screen.
- Layers are currently not grouped and all named "Layer".
- The rendered psd is not pixel perfect, there <strike>might be</strike> are glitches. I've only tested it with [Clockshots][] so far. If things don't look quite right, you can always fall back onto the screenshot (png). But also file an issue and submit a pull request, that way everyone benefits.


##Thanks
- Layershots uses Ben Gotow's PSDWriter implementation to write out the psd files, author of the awesome [Spark Inspector](http://sparkinspector.com).
- The first implementation was born during the [UIKonf](http://uikonf.com) Hackathon and written up by [@ndfred](http://twitter.com/ndfred).

[color animation]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_color_variation.gif
[icon animation]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_icons_variation.gif
[framer.js sample]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_animation.gif
[Framer.js]: http://framerjs.com
[Clockshots]: http://clockshots.com
[Cocoapods Trunk]: http://blog.cocoapods.org/CocoaPods-Trunk/#trunk
