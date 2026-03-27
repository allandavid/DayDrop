# DayDrop Icons

## App Icon — DayDrop-AppIcon.svg

**Design:** Deep indigo-to-amber dawn gradient background, scattered stars,
a white teardrop "window" shape revealing a purple-to-orange sky with a golden
sun rising above a dark horizon. The teardrop is the central motif — a photo
"dropping" into your day.

**Note:** The SVG has no rounded corners. macOS applies the squircle mask
automatically via the `.icns` / `AppIcon.appiconset` pipeline.

### Exporting to .icns (macOS required)

1. Open `DayDrop-AppIcon.svg` in Sketch, Figma, or Pixelmator Pro.
2. Export as PNG at these sizes:
   - `icon_512x512@2x.png` → 1024×1024
   - `icon_512x512.png`    → 512×512
   - `icon_256x256@2x.png` → 512×512
   - `icon_256x256.png`    → 256×256
   - `icon_128x128@2x.png` → 256×256
   - `icon_128x128.png`    → 128×128
   - `icon_32x32@2x.png`   → 64×64
   - `icon_32x32.png`      → 32×32
   - `icon_16x16@2x.png`   → 32×32
   - `icon_16x16.png`      → 16×16
3. Drag all PNGs into your Xcode `AppIcon.appiconset`.

Or run from the Terminal (requires Inkscape CLI):
```bash
for s in 16 32 64 128 256 512 1024; do
  inkscape DayDrop-AppIcon.svg --export-png=icon_${s}.png -w $s -h $s
done
```

---

## Menu Bar Icon — DayDrop-MenuBarIcon-Template.svg

**Design:** Pure monochrome. Teardrop outline (stroke only) with a horizontal
horizon line and a rising sun arc inside. Solid black — macOS colours it white
or black depending on menu bar appearance via the template image system.

**Icon size:** 22×22pt (44×44px @2x Retina)

### Adding to Xcode

1. In Xcode, open `Assets.xcassets`.
2. Create a new Image Set named `StatusBarIcon`.
3. Export this SVG as two PNGs:
   - `StatusBarIcon.png`   → 22×22px  (1x)
   - `StatusBarIcon@2x.png` → 44×44px  (2x)
4. Drag both into the image set slots.
5. In the image set Attributes Inspector, set **Render As → Template Image**.

Or export as a single vector PDF instead of PNGs:
1. Export `DayDrop-MenuBarIcon-Template.svg` as a PDF (Sketch, Figma, or Inkscape).
2. Drop the PDF into a "1x Universal" image set slot in Xcode.
3. Set **Render As → Template Image**.

### Using it in code

```swift
// MenuBarManager.swift — already wired up
button.image = NSImage(named: "StatusBarIcon")
button.image?.isTemplate = true   // ← critical, makes macOS recolour it
```
