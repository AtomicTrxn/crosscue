# Crosscue Android Icon Files

## File Structure

```
mipmap-mdpi/
  ic_launcher.png          (48×48)
  ic_launcher_round.png    (48×48)
  ic_launcher_foreground.png (108×108)

mipmap-hdpi/
  ic_launcher.png          (72×72)
  ic_launcher_round.png    (72×72)
  ic_launcher_foreground.png (162×162)

mipmap-xhdpi/
  ic_launcher.png          (96×96)
  ic_launcher_round.png    (96×96)
  ic_launcher_foreground.png (216×216)

mipmap-xxhdpi/
  ic_launcher.png          (144×144)
  ic_launcher_round.png    (144×144)
  ic_launcher_foreground.png (324×324)

mipmap-xxxhdpi/
  ic_launcher.png          (192×192)
  ic_launcher_round.png    (192×192)
  ic_launcher_foreground.png (432×432)

mipmap-anydpi-v26/
  ic_launcher.xml          (adaptive icon descriptor)
  ic_launcher_round.xml    (adaptive icon descriptor)

values/
  colors.xml               (background color #0D1A30)
```

## Installation

1. Copy all `mipmap-*` folders into `app/src/main/res/`
2. Copy `values/colors.xml` contents into your existing `res/values/colors.xml`
   (or create it if it doesn't exist)
3. Your `AndroidManifest.xml` should already reference:
   ```xml
   android:icon="@mipmap/ic_launcher"
   android:roundIcon="@mipmap/ic_launcher_round"
   ```

## Adaptive Icon (API 26+)
On Android 8.0+, the system uses `mipmap-anydpi-v26/ic_launcher.xml` which
layers `ic_launcher_foreground.png` over the `#0D1A30` background color.
The system then applies the device's icon shape (circle, squircle, etc.).

On older Android versions, `ic_launcher.png` (pre-drawn round icon) is used directly.
