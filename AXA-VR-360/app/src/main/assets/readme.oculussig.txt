switch on developer mode
 - settings / general / software info
 - click 5 times on build
go to settings / develoepr settings
 - switch on USB-debugging
 - connect phone with USB
 - trust this computer

download Android studio
install SDK
in SDK folder $HOME/Library/Android/sdk/platform-tools
run
 ./adb devices
 copy  device ID

 example
 ce10160a0d36242405 device

open https://dashboard.oculus.com/tools/osig-generator/
paste in field and press "download"

goto Android Studio /app/asset folder
copy / paste this file into /asset folder of App


------
you see the Gear VR icon
------
now switch on Gear VR debugger mode

- settings / Applications
- application manager
- Gear VR Service
- Storage
- Manager storage
- click 10 times on "VR Service version"
- now 2 new menu will appear
- switch on both
  - developer mode / have to be switzched on after restart
  - add symbol to App-list

