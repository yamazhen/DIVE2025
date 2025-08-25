# Instructions
read this to know how to run the project

## if you plan to use neovim
there are a few things you need

1. xcode editor
2. watchos runtime
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

## if you use xcode editor
just download watchOS runtime through xcode editor and press the run button in the editor bruh
