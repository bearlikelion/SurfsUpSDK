---
title: "BSP Files"
permalink: /bsp/
nav_order: 6
---

# Porting BSP Files
*You should always ask for the map maker's permission before porting their BSP file*

## Requirements
First, download and decompile the BSP to VFM with [bspsrc](https://github.com/ata4/bspsrc/releases)
In bspsrc, under **Other** make sure to enable **Extract embedded files**

Download [Blender 4.2 LTS](https://www.blender.org/download/lts/4-2/)
Install the [Plumber](https://github.com/lasa01/Plumber) Blender plugin

### Blender Import
* Create a new "General" Blender file (Ctrl+N)
* Press A -> Press Delete key to remove the default objects
* File -> Import -> Plumber -> Valve Map Format (VMF) -> Your BSP's decompiled VMF file
* Under the Import settings, **deselect** Lights, Sky, Sky Camera

![Blender Import Options](https://raw.githubusercontent.com/bearlikelion/SurfsUpSDK/refs/heads/main/docs/assets/img/bspfiles/vmf_import_blender.png)

Your VMF file should now be viewable in Blender!

### Blender Controls
* Mouse Wheel to Zoom
* Shift+Middle Click to Pan
* Shift+tilde (~) to enter "Fly" mode
	* Space to speed up
	* Left click to stop

### Blender Process
Press `A` and Join all meshes so a single object
![Join All](https://raw.githubusercontent.com/bearlikelion/SurfsUpSDK/refs/heads/main/docs/assets/img/bspfiles/join_blender.png)

Rename the object and add `-col` to the name
![Collision Hinting](https://raw.githubusercontent.com/bearlikelion/SurfsUpSDK/refs/heads/main/docs/assets/img/bspfiles/col_name.png)

Export using: `File -> Export -> glTF 2.0 (.glb/gltf)` directly to `SurfsUpSDK\Levels\<level>\level_name.glb`
![GLB Export Settings](https://raw.githubusercontent.com/bearlikelion/SurfsUpSDK/refs/heads/main/docs/assets/img/bspfiles/glb_export.png)

### Loading the GLB in Godot
* Open `SurfsUpSDK\Levels\TestLevel.tscn`
* Drag your new GLB file into the `Level` node
* Set the GLB's node scale to (2.5, 2.5, 2.5)
* Set the Level's spawn point marker
* Retexture any missing textures (**source engine textures cannot be ported**)
* Export & Test

![GLB Godot](https://raw.githubusercontent.com/bearlikelion/SurfsUpSDK/refs/heads/main/docs/assets/img/bspfiles/glb_godot.png)
