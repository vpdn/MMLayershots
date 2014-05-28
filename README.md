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


##Designer's Preamble

If you are a designer who doesn't write code yourself, the next few sections might look to you like a message written by E.T.'s parents to guide him home. Rest assured, it's pretty simple to plug Layershots into your app and whoever you're developing your app with, can get it integrated with just a few lines of code. If there are questions, feel free to ping me up on twitter ([@vpdn](http://twitter.com/vpdn)) and I'm glad to help out if I can.


##How to use Layershots?

The preferred way to install is via Cocoapods. Add this to your Podfile:
	
	pod 'MMLayershots'


In the Application delegate, initialize the MMLayershots shared instance:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[[MMLayershots sharedInstance] setDelegate:self];
    return YES;
}
```

There's only on then mandatory delegate method, that tells Layershots what to do when a screenshot is taken:

```objc
- (MMLayershotsCreatePolicy)shouldCreateLayershotForScreen:(UIScreen *)screen {
    return MMLayershotsCreateOnUserRequestPolicy;
}
```

Return ``MMLayershotsCreateNeverPolicy`` to disable Layershots, ``MMLayershotsCreateOnUserRequestPolicy`` to pass on the request to the user (popup) or ``MMLayershotsCreateNowPolicy`` to trigger the generation of a psd immediately.

There are two optional delegate methods, one called before (``willCreateLayershotForScreen:``) and one after (``didCreateLayershotForScreen:data:``) the psd has been generated. Use the latter to save the data into a file or present 'Open in...' options to the user.

```objc
- (void)willCreateLayershotForScreen:(UIScreen *)screen {
    NSLog(@"Creating psd now...");
}

- (void)didCreateLayershotForScreen:(UIScreen *)screen data:(NSData *)data {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"layershots.psd"];
    [data writeToFile:filePath atomically:NO];
    NSLog(@"Saving psd to %@", filePath);
}
```

The iPhone Simulator doesn't trigger the screenshot notification when a screenshot is saved. However, you can easily trigger it manually by assigning a custom shortcut. To do so, add the following code to your root viewcontroller or anywhere else along the responder chain:

```objc
#if TARGET_IPHONE_SIMULATOR
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray *)keyCommands {
	// save on ⇧⌘+S
    UIKeyCommand *command = [UIKeyCommand keyCommandWithInput:@"s" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift action:@selector(didRequestPSDCreationFromCurrentViewState)];
    return @[command];
}

- (void)didRequestPSDCreationFromCurrentViewState {
    // simulate a screenshot notification
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationUserDidTakeScreenshotNotification object:nil];
    });
}
#endif
```


##Notes/Contribute
- The generated psd file is currently bigger than it needs to be. There isn't any bounds calculation in yet, so every layer is rendered in full screen. ([Issue #1](https://github.com/vpdn/MMLayershots/issues/1))
- Layers are currently not grouped and all named "Layer". ([Issue #2](https://github.com/vpdn/MMLayershots/issues/2))
- The rendered psd is not pixel perfect, there <strike>might be</strike> are glitches. I've only tested it with [Clockshots][] so far. If things don't look quite right, you can always fall back onto the screenshot (png). But also file an issue and submit a pull request, that way everyone benefits.
- <strike>Currently Layershots only supports portrait mode. ([Issue #5](https://github.com/vpdn/MMLayershots/issues/5))</strike> *✓ Added by [@jwalapr](http://twitter.com/jwalapr)*

For a list of outstanding / missing features, check out the [next up page](https://github.com/vpdn/MMLayershots/wiki). Would be awesome if you could help out!


##Thanks
- Layershots uses Ben Gotow's PSDWriter implementation to write out the psd files, author of the awesome [Spark Inspector](http://sparkinspector.com).
- The first implementation was born during the [UIKonf](http://uikonf.com) Hackathon and written up by [@ndfred](http://twitter.com/ndfred).

[color animation]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_color_variation.gif
[icon animation]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_icons_variation.gif
[framer.js sample]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_animation.gif
[Framer.js]: http://framerjs.com
[Clockshots]: http://clockshots.com
[Cocoapods Trunk]: http://blog.cocoapods.org/CocoaPods-Trunk/#trunk
