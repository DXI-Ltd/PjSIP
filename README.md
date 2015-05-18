# pjsip-ios

This project builds a iOS Static Library that provides sip connection functionalities. It exposes the DXIPJSipManager class that cam be used to connect an iOS App to a sip server.
* [Repo] 

## 1 - Adding to a Project

#####a) Add pspip-ios as a submodule
# 

Open terminal and navigate to your project's folder. Then use the command below to add pjsip-ios as a submodule and download it.
```sh
$ git submodule add __PROJECT_URL__
```
Now use Finder to find the newly created /pjsip-ios folder inside your project's folder. Inside this folder there's a file called "pjsip-ios.xcodeproj". You need to drag it into your App's file tree inside XCode

#####b) Add pjsip-ios.xcodeproj to your workspace
#####c) Add pjsip-ios as a target depencency
#####d) Add the following files to the "Link with Binary Libraries" section of "Build Phases"
* libpjsip-ios.a
* AudioToolbox.framework
* AVFoundation.framework

#####e) Add background capabilities to your app
* Audio and Air Play
* Voice over IP
* Background Fetch

#####f) Import pjsip-ios.h to your project
# 
# 
```c
#import <pjsip-ios/pjsip-ios.h>
```

## 2 - Updating pjsip Version

All pjsip libraries and headers were created using the repo conained in the 
/psip-master folder. It basically contains all the logic needed to build the pjsip libs with the most up to date version of it's source code. 
Download the project
Run build.sh
Replace all the old sources and libs in the pjsip-ios project "Frameworks" folder

## 3 - Related Projects
* [PJSIP]
* [pjsip-lib-generator] 

[Repo]:https://github.com/otaviokz/pjsip
[PJSIP]:http://www.pjsip.org/
[pjsip-lib-generator]:https://github.com/otaviokz/pjsipbrowse