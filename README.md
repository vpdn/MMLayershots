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

In the Application Delegate, initialize the MMLayershots shared instance:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[[MMLayershots sharedInstance] setDelegate:self];
    return YES;
}
```

then implement the delegate methods:

```objc
// Delegate callback before psd starts rendering
- (void)willCreatePSDDataForApplication:(UIApplication *)application {
	// Show HUD or other means of blocking the UI, e.g. with MBProgressHUD
	[MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];    	
}

// Delegate callback after psd has been generated
- (void)didCreatePSDDataForApplication:(UIApplication *)application data:(NSData *)data {
#if (TARGET_IPHONE_SIMULATOR)
	[data writeToFile:@"/tmp/your/location/of/choice/screen.psd" atomically:NO];
#else
	// Send zipped psd via email
#endif
    [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
}
```

The iPhone Simulator doesn't trigger the screenshot notification when a screenshot is saved. You can trigger it manually by assigning a custom shortcut. Add this in your root viewcontroller or anywhere else along the responder chain:

```objc
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
	// save
    UIKeyCommand *command = [UIKeyCommand keyCommandWithInput:@"s" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift action:@selector(didRequestPSDCreationFromCurrentViewState)];
    return @[command];
}

- (void)didRequestPSDCreationFromCurrentViewState {
	[[MMLayershots sharedInstance] triggerPSDCreation];
}
```


##Notes
- The generated psd file is currently bigger than it needs to be. There isn't any bounds calculation in yet, so every layer is rendered in full screen.
- Layers are currently not grouped and all named "Layer".
- The rendered psd is not pixel perfect, there <strike>might be</strike> are glitches. I've only tested it with [Clockshots][] so far. The psd contains a (flattened) screenshot as the bottom layer of the psd, you can always fall back on that in case things screw up. Even better, fix the issue and submit a pull request, that way everyone benefits.


##Thanks
- Layershots uses Ben Gotow's PSDWriter implementation to write out the psd files, author of the awesome [Spark Inspector](http://sparkinspector.com).
- The first implementation was born during the [UIKonf](http://uikonf.com) Hackathon and written up by [@ndfred](http://twitter.com/ndfred).

[color animation]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_color_variation.gif
[icon animation]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_icons_variation.gif
[framer.js sample]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_animation.gif
[Framer.js]: http://framerjs.com
[Clockshots]: http://clockshots.com