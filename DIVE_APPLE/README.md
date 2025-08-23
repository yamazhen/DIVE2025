# Instructions
read this to know how to run the project

## if you plan to use neovim
there are a few things you need

1. xcode editor
2. watchos runtime
3. ios runtime
4. xcodebuild.nvim plugin
5. xcode-build-server

### steps
1. install xcode
```
brew install Xcode
```
2. install watchos and ios runtime through xcode
3. vim.lsp.enable("sourcekit-lsp")
4. install xcodebuild.nvim on neovim
[xcodebuild.nvim](https://github.com/wojciech-kulik/xcodebuild.nvim)
5. set up buildServer.json with
```
xcode-build-server config -scheme "DIVE_APPLE Watch App" -project DIVE_APPLE.xcodeproj
```
5. use the neovim command
```
XcodebuildSetup
XcodebuildBuildRun
```
6. profit

## if you use xcode editor
just download watchOS runtime through xcode editor and press the run button in the editor bruh


Bada time
Views
Tide info
Weather info 
Fish points
Alert settings

Functionalities
Automatic responsibilities 
Typhoon and weather even warning
Manual responsibilities 
Tide info
Weather info
Temp info
Fish points info
Water level warning
Tide level worning


Tide info and view
Date : month.day.short week in korean
Location | moon/sun cycle | tide phase 
Rest is the same


Weather info and view
Location small with bg gray
Weather condition icon big | temp air
Pago 
Humidity
Sea temp

Fish points info and view
Image card with point name list vertical scroll
Press open 
Detailed view:
Point name small with boxed gray
Region name
Image
Depth | sea bed material 
Fish species 
Distance | address
Tide time


