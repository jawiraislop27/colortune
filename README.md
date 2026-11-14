# ColorTune

A small root module that lets you adjust your screen's **contrast** and **saturation** live, from a WebUI or a one-line command.

> **Built for one setup:** a **Tecno Pova 4 Pro** rooted with **KernelSU**. It has never been tested on another device or another root manager. See [Requirements](#requirements).


![ColorTune Banner](https://i.imgur.com/Dl6q7Ky.png)

## Why this exists

My phone originally had a good screen. I replaced it with a cheap screen, and the colors on it are really bad: washed out and flat. The ROM has no setting to fix that, so I wanted to push saturation and contrast up myself.

Because of that, the value ranges and the test chart are built around making a weak screen look better. If you have a good panel, you may not need this much.

## A note on how this was made

This module is fully vibe coded with AI, but the idea is purely human.

## Features

- Configurable screen contrast, saturation, and rgb color balance
- Auto apply after reboot
- Test chart built into the WebUI: grayscale steps, shadow and highlight detail, a 24-patch ColorChecker, and primary/secondary colors. Tap a patch to see its name and RGB value, tap it again to unselect.
- Has dark mode and light mode
- Config can be changed from Termux, just run `su -c colortune`

![Darkmode](https://i.imgur.com/EJOB7Qm.png)

![Lightmode](https://i.imgur.com/CroDZDQ.png)

![TestChart](https://i.imgur.com/YLfWCsm.png)

## Requirements

- A rooted phone that can install modules.

Only tested on **KernelSU** and the **stock Tecno ROM** (Tecno Pova 4 Pro). No other root manager has been tested.

## Install

1. Download the latest `colortune-vX.Y.zip`.
2. Install it from your root manager's module page.
3. **Reboot.**

## Using the command line

```sh
su -c "colortune"
```

| Command | What it does |
| --- | --- |
| `colortune 120 130` | Set contrast and saturation, and save |
| `colortune c 120` | Contrast only |
| `colortune s 130` | Saturation only |
| `colortune r` | Reset to normal |
| `colortune a` | Apply the saved settings |
| `colortune rgb 100 100 100` | set rgb color balance |

If `colortune` is not found in your PATH (this can happen on KernelSU when no metamodule mounts the module's files), call it by its full path. In Termux you can define a function once:

```sh
echo 'colortune(){ su -c "sh /data/adb/modules/colortune/system/bin/colortune $*"; }' >> ~/.bashrc && source ~/.bashrc
```

The WebUI and the boot script always use the full path, so they work either way.

## How it works

ColorTune only calls SurfaceFlinger through `service call`, nothing is patched or flashed to the system.

- **Saturation** uses transaction `1022` with a single float. `colortune s 130` sends `1.30`.
- **Contrast** uses transaction `1015`, which sets a 4x4 color matrix. Contrast `C` scales R, G and B by `C` and shifts them by `0.5 x (1 - C)`, so mid-gray stays where it is while darks get darker and lights get lighter. At `C = 1.5` the shift is `-0.25`.
- **RGB Color Balance** goes through the same matrix. Each channel gets its own gain `g` (0.5 to 1.0), so the diagonal becomes `C x gR`, `C x gG`, `C x gB`. The shift stays the same. Gains never go above 1.0, so RGB Color Balance alone never clips highlights.
- Normal values (contrast 100% and all gains 100%) send `1015 i32 0`, which clears the matrix instead of setting an identity matrix.
- Saturation and the color matrix stack, and they are independent of each other.

On boot, `service.sh` waits for `sys.boot_completed`, then applies the saved values twice, once after 10 seconds and again 20 seconds later. Some ROMs reset the color pipeline on first unlock, and the second pass catches that.

Settings live in `/data/adb/colortune/config`, outside the module folder, so updating or reinstalling does not wipe them.

## Known limitations

- **Contrast and RGB Color Balance share the color matrix slot with other features.** Night Light, color inversion, color correction, and some "eye comfort" modes use the same transaction (`1015`). If one is on, it can overwrite ColorTune, or the reverse.
- **Auto Override wins over those features.** While it is ON, Night Light and similar filters get overwritten within 15 seconds. If you want to use one of them, turn Auto Override OFF in the WebUI. A warm RGB Color Balance (lower blue gain) can replace Night Light.
- Saturation may also be reset by the ROM's own color settings.
- Strong values clip. High contrast crushes shadows and blows out highlights. The built-in test chart exists to help you see that happening.
- This changes how colors are composed, it does not change the physical panel. HDR, wide color gamut, and color mode switching are out of scope, and my panel exposes none of them anyway.

## Credits and license

- Code and documentation: written with Claude (Anthropic)
- The 24-patch chart uses commonly published sRGB values for the ColorChecker Classic layout. It is a visual aid, not a calibration instrument, and it is not affiliated with any calibration vendor.

License: MIT License

## Disclaimer

Use at your own risk. I cannot promise it behaves the same on every device or ROM.
