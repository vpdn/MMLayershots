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

For more info, watch [Koen present the framework](http://vimeo.com/74712901) and make sure to [check out the examples](http://examples.framerjs.com/#Google Now - Overview.framer) on their website too.


##Designer's Preamble

If you are a designer who doesn't write code yourself, the next few sections might look to you like a message written by E.T.'s parents to guide him home. Rest assured, it's pretty simple to plug Layershots into your app and whoever you're developing your app with, can get it integrated with just a few lines of code. If there are questions, feel free to ping me up on twitter ([@vpdn](http://twitter.com/vpdn)) and I'm glad to help out if I can.


##Sample project

The sample project links to the SFPSDWriter library via a git submodule. To run the sample, first clone the project.

    git clone https://github.com/vpdn/MMLayershots.git

The run the following command to initialize the submodule:

    git submodule update --init --recursive


##How to use Layershots?

The preferred way to install is via CocoaPods. Add this to your Podfile:
	
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
    NSLog(@"Creating psd now..."); // you could hide away stuff such as user info, that you don't want to be in the psd
}

- (void)didCreateLayershotForScreen:(UIScreen *)screen data:(NSData *)data {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"layershots.psd"];
    [data writeToFile:filePath atomically:NO];
    NSLog(@"Saving psd to %@", filePath);
}
```

## iPhone simulator
The iPhone Simulator doesn't trigger a notification when a screenshot is saved ([rdar://17077229](http://openradar.appspot.com/17077229)). As a work around, use the key command ⇧⌘+S.


##Notes
- The generated psd file is currently bigger than it needs to be. There isn't any bounds calculation in yet, so every layer is rendered in full screen. ([Issue #1](https://github.com/vpdn/MMLayershots/issues/1))
- <strike>Layers are currently not grouped</strike>
- <strike>Layer are all named "Layer". ([Issue #2](https://github.com/vpdn/MMLayershots/issues/2))</strike>
- The rendered psd is not pixel perfect, there <strike>might be</strike> are glitches. Test suite upcoming. ([Issue #8](https://github.com/vpdn/MMLayershots/issues/8))
- <strike>Currently Layershots only supports portrait mode. ([Issue #5](https://github.com/vpdn/MMLayershots/issues/5))</strike>

For a list of outstanding / missing features, check out the github issues page. Would be awesome if you could help out!


##Thanks :star2:
- Layershots uses [SFPSDWriter](https://github.com/shinyfrog/SFPSDWriter) by [@shinyfrog]( https://github.com/shinyfrog), a psd generation library with layer groups support, based on [@bengotow](https://github.com/bengotow)'s [PSDWriter](https://github.com/bengotow/PSDWriter).
- Layer group support was added by [@ashikase](https://github.com/ashikase).
- [@nicolasgoutaland](https://github.com/nicolasgoutaland) added layer naming.
- Support for landscape mode was added by [@jwalapr](https://github.com/jwalapr).
- The [first implementation](https://github.com/ndfred/Snapshot) of the idea was built during the [UIKonf](http://uikonf.com) Hackathon and written up by [@ndfred](http://twitter.com/ndfred).

[color animation]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_color_variation.gif
[icon animation]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_icons_variation.gif
[framer.js sample]: http://vpdn.github.io/images/2014-05-18_Layershots/clockshots_animation.gif
[Framer.js]: http://framerjs.com
[Clockshots]: http://clockshots.com
[CocoaPods Trunk]: http://blog.cocoapods.org/CocoaPods-Trunk/#trunk
