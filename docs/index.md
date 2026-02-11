---
title: "Overview"
---

# SurfsUp SDK Overview

This is the documentation site for creating custom levels in [SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/)

## Requirements
* **Godot 4.5.1** - This SDK requires Godot 4.5.1+
* **Blender**  - There are some .blend files from SurfsUp Source Code that need to compile to GLB

## Getting Started
* Download, Fork, or Git Clone the [SurfsUpSDK Project](https://github.com/bearlikelion/SurfsUpSDK)
* Download [Godot v4.5.1](https://godotengine.org/download/archive/4.5.1-stable/) or newer
* Download and Install [Blender LTS](https://www.blender.org/download/lts/)
* Open the `project.godot` filet
* Rename/duplicate `test_level.tscn` to your map's name

## Topics
* [Using the Ramp Prefabs](prefabs.md)
* [Texturing Ramps](texturing.md)
* Zoning
* Changing the Environment
* [Exporting](exporting.md)
* [Testing the Map in Game](testing.md)
* Using Hammer VMF files with Godot
* Using SURGE/Blender to create ramps
* [Decompiling and porting BSP files](bspfiles.md)


## Support
If you are looking for help, having trouble, or just want to show off your creation. Please join the [SurfsUp Discord Server](https://discord.gg/95XmYfPnwV) and post in the **#mapping** channel.


## Testing
Export project as PCK to the game's `/Maps` directory next to the SurfsUp executable
Use the in-game console (tilde) to load your map with the command: `map <pck_name>`
The Exported `PCK Name` and `/Levels/scene_name.tscn` **must match** to load correctly
