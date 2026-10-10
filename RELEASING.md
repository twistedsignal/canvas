# Releasing Canvas

## 1. Bump the version

Set the new version in `wally.toml` (`version = "x.y.z"`). The build writes it into `src/Version.luau`, and the grip's tooltip shows it.

## 2. Publish the plugin on Roblox

Roblox's Open Cloud API can't upload plugins, so this step happens in Studio:

1. Run `./scripts/build.bash`.
2. Get the plugin into Studio. Either drag `build/Canvas.rbxm` into the Explorer, or run `build/studio-install.luau` (and any `-2`, `-3` chunks after it) to rebuild it as `workspace.Canvas`.
3. Right-click the `Canvas` script and choose **Save as Local Plugin...** or **Publish as Plugin...**. To update an existing plugin, pick it in the publish dialog instead of creating a new one.
4. Use these details:

   - **Name:** Canvas
   - **Icon:** `assets/icon.png` (already uploaded as `rbxassetid://80551343445821`, Decal 88917487414771)
   - **Description:** the text below. **Change the `Release` line for every release.**

```
A light, floating UI toolkit. Select any UI to bring it up: Builder Icons, Scale/Offset conversion, layout helpers, colors and style copy/paste.

Release v0.1.0 - First release!
```

## Release history

Add the description's `Release` line here each time, newest first.

- `Release v0.1.0 - First release!`
