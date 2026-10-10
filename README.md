<div align="center">
  <img src="assets/icon.png" width="72" />
  <h1>Canvas</h1>
  <p>A small UI toolkit that floats over the Roblox Studio viewport.</p>
</div>

Canvas doesn't live in a dock. Select a Frame, TextLabel or any other UI and a small window appears over the viewport. Deselect it and the window goes away. Click a tool and the window grows into that tool's panel. Click the tool again, or press Esc, to shrink it back.

To move the window, drag its header, or the **::** grip in the Modern theme. When you let go, it springs to the nearest corner or edge and stays fully on screen. Panels open away from the edge, so a window parked at the bottom grows upward.

## Tools

**Builder Icons.** Every icon in the Builder Icons font that ships with Studio, with search and a Regular or Filled style. Clicking an icon adds it to the selected TextLabels, TextButtons and TextBoxes as RichText, so one label can hold an icon and text, like a gear next to "Settings". The **In text** option decides where it goes. Swap icon replaces the icons already in the label, or adds one at the start if there aren't any. The other two options add at the start or the end. With no text object selected, the click inserts a new icon label instead. The name field shows the icon's name, ready to copy into a script.

**Scale ↔ Offset.** Converts Position, Size or both to Scale or to Offset, on one axis or both. Nothing moves on screen. The math takes the parent's UIPadding and any UIScale into account.

**Layout.** One click adds UICorner, UIStroke, UIPadding, UIListLayout, UIGridLayout or UIAspectRatioConstraint, and a second click removes it. The anchor picker changes AnchorPoint and adjusts Position so the object stays put. There are also buttons to center in the parent, fill the parent and toggle AutomaticSize.

**Reclass.** Turns the selection into another class, like a TextLabel into an ImageLabel. Type part of a class name and pick from the list. Tab completes the highlighted class and Enter converts. Each row shows the class's Explorer icon and how many properties survive the switch. Below the list, Canvas names the properties that will be dropped.

The new instance keeps every saved property both classes share, plus its name, children, attributes and tags. Scripts keep their source. ObjectValues, NextSelection properties and constraint parts that pointed at the old instance get repointed, but only inside the same ScreenGui or model. To reclass Parts or Scripts, set **Show** to Always first, since the window hides when no UI is selected.

**Color & Style.** Sets the fill, the text or image color, or the stroke color from swatches or a hex code. Click the color square next to the hex code for a full picker, ported from Prism, with a hue bar, hex and RGB fields and recent colors. Colors apply live while you drag, and Ctrl+Z undoes the whole pick in one step. It also copies one object's fill, corner, stroke and text style and pastes it onto others.

Ctrl+Z undoes any of these edits. The toolbar button turns Canvas on and off.

## Settings

The cog opens Settings. **Theme** picks Classic, the default, or Modern. Classic copies Photon: a header with the logo, title and tab buttons, square corners, and you drag it by the header. Modern is a compact rounded bar with a **::** grip.

The other settings:

- **Show** the window only while UI is selected, or always.
- **Motion** can be bouncy, smooth or off.
- **Placement** snaps to corners and edges, or leaves the window wherever you drop it.
- **Size** scales the window from 90% to 125%.
- **Tooltips** turns button labels on hover on or off.
- **On deselect** closes the open panel when you deselect everything, or keeps it open.
- **Icon size** sets the size of icon labels that Builder Icons inserts.

Two buttons at the bottom reset the window's position and reset every setting.

## Development

Install [Rokit](https://github.com/rojo-rbx/rokit), then run:

```sh
rokit install
wally install
./scripts/build.bash  # builds build/Canvas.rbxm and the Studio install chunks
./scripts/test.bash   # lint and tests
./scripts/dev.bash    # rebuilds Canvas-dev.rbxm into your Plugins folder when files change
```

Dev builds expose the window's state as `shared.CanvasDev`. From the command bar, `shared.CanvasDev.active("icons")` opens a panel and `shared.CanvasDev.slot("TopRight")` moves the window.

The build also writes `build/studio-install.luau`. Run it through the Studio MCP or the command bar and it rebuilds the plugin as `workspace.Canvas`. Large builds split into `studio-install-2.luau` and so on, which you run in order. `build/studio-install.json` holds the same tree as JSON.

After a Studio update, run `python3 scripts/generate-builder-icons.py` to pick up new icons. It reads the BuilderIcons package bundled with Studio and rewrites `src/BuilderIcons/Names.luau`.

[RELEASING.md](RELEASING.md) has the publishing steps.

## License

MIT © Twisted Signal. Lucide icons use the [ISC license](third_party/lucide-LICENSE). Builder Icons ship with Roblox Studio, so this repository doesn't include them.
