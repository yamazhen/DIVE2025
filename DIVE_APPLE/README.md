# Instructions
read this to know how to run the project

## if you plan to use neovim
there are a few things you need

1. install xcode
2. watchos runtime
4. tuist cli
5. xcodes cli (to install the runtimes)

install commands (one by one)
```
brew install Xcode
brew install xcodesorg/made/xcodes
brew install tuist
brew install xcode-build-server
sudo xcode-select -s /Applications/Xcode.app/
sudo xcodebuild -license accept
xcodes runtimes install "watchOS 11.5"
```

then you need to cd into DIVE_APPLE/ and run
```
tuist generate
xcode-build-server config -scheme DIVE_APPLE -workspace *.xcworkspace
```

and run with
```
tuist run DIVE_APPLE
```

## if you use xcode editor
just download watchOS runtime through xcode editor and press the run button in the editor bruh
