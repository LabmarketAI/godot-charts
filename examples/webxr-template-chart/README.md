# Godot Charts WebXR Template Baseline

This project is a tracked Quest/WebXR baseline derived from
<https://github.com/GodotVR/godot-xr-template>. It keeps the template player,
camera, controllers, lighting, floor, and movement setup, then adds one
`godot-charts` analytical frame in the outside zone.

Run it from the repo root:

```bash
scripts/run-webxr-template-chart.sh --port 8457
```

The script builds a single-threaded Godot Web export, serves it over HTTPS on
the fixed headset test port, and prints the LAN endpoints. Keep the terminal
open while testing on the Quest.

Notes:

- Left joystick locomotion is the current verified baseline on Quest 3.
- Right joystick is configured for 30 degree snap-turns on Quest 3.
- The right hand does not have direct locomotion attached; this keeps the
  right thumbstick dedicated to turning.
- The chart exposes two lower front controls: cyan moves the chart, orange
  rotates it around the vertical axis. They support both near grab and
  controller pointer selection with the trigger.
- The chart also exposes six smaller endpoint controls outside the X/Y/Z plot
  bounds. These are experimental axis-domain handles. Drag an endpoint along
  its axis with ray/select or near grab to preview a linear scale-domain change;
  release to commit. The server log prints `chart-domain-preview` and
  `chart-domain-commit` lines with the resulting domain values.
- The axis-domain handles are deliberately separate from frame manipulation:
  frame handles move or rotate the whole chart object, while endpoint handles
  mutate retained scale domains and re-render the chart content/guides.
- Use the Meta browser to open the printed `https://<LAN-IP>:8457/` URL.

Troubleshooting:

- If only a red handle appears near the chart center, rebuild/reload the served
  export. Current handles use XR Tools handle-origin nodes and should sit
  outside the axis endpoints.
- If endpoint handles are visible but cannot be selected, try the controller ray
  plus trigger first, then close grip. The endpoint controls include pointer
  targets and larger near-grab colliders, but Quest Browser input profiles can
  vary by runtime.
- If the script refuses to start because port `8457` is in use, stop the old
  host terminal before rerunning; the script intentionally keeps this fixed port
  for headset bookmarks.

## Upstream Template README

# Godot XR Template

![GitHub forks](https://img.shields.io/github/forks/godotvr/godot-xr-template?style=plastic)
![GitHub Repo stars](https://img.shields.io/github/stars/godotvr/godot-xr-template?style=plastic)
![GitHub contributors](https://img.shields.io/github/contributors/godotvr/godot-xr-template?style=plastic)
![GitHub](https://img.shields.io/github/license/godotvr/godot-xr-template?style=plastic)

This repository contains a template Godot project for building a simple VR game.


## Versions

Official releases are tagged and can be found [here](https://github.com/GodotVR/godot-xr-template/releases).

The following branches are in active development:
|  Branch  |  Description                  |  Godot version  |
|----------|-------------------------------|-----------------|
|   main   | Current development branch    |  Godot 4.6+     |
|    4.2   | Godot 4.2 development branch  |  Godot 4.2-4.5  |
|    4.1   | Godot 4.1 development branch  |  Godot 4.1      |
|    3.x   | Godot 3.x development branch  |  Godot 3.5+     |


# Assets

This project uses the following assets:
 - [Godot XR Tools](https://godotengine.org/asset-library/asset/1515)
 - [OpenXR Vendors](https://github.com/GodotVR/godot_openxr_vendors)

> [!NOTE]
> OpenXR Vendors is not included in the repo but will be downloaded by CI scripts.
> When cloning this repository, manually download the version correct for the version of
> Godot you are using.

# Getting Started

Start by downloading this asset from github; or by installing it from the Godot
Asset Library.

The game should be playable with a splash screen and two example scenes the player
can move between.

The game should be customized by:
 - Modifying the splash-screen texture to represent the game
 - Modifying the icon.png for the game
 - Add game state variables to the game_state.gd singleton class
 - Replacing the demo zones with zones suitable to the game


# Exporting to Android

The template contains a copy of the XR loaders plugin
and preconfigured exports for android based headsets that support OpenXR.

Before this can be used you do need to install the android build template.
Select the menu `Editor->Manage Export Templates...` to download the templates.
Select the menu `Project->Install Android Build Template...` to install the template.

Make sure you set the correct entry in the export templates to runable
if you want to use one click deploy to your device.

Please refer to the official documentation for Godots prerequisits for exporting to android:
https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

# Recommended Asset Locations

Common areas to find assets are:
 - [Godot Asset Library](https://godotengine.org/asset-library/asset)
 - [AmbientCG](https://ambientcg.com/) for object and sky textures
 - [FreePD.com](https://freepd.com/) for sound tracks
 - [FreeSound](https://freesound.org/) for sound effects
 - [Kenney.nl](https://kenney.nl/) 


# More Information

Information on the Godot XR Tools can be found on [the website](https://godotvr.github.io/godot-xr-tools/).
