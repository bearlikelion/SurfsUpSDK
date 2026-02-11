# SurfsUp SDK

<p align="center">
  <img src="docs/assets/img/sdk_logo.png" alt="SurfsUp SDK Logo" width="200"/>
</p>

The official SDK for creating custom levels for [SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/) on Steam.

SurfsUp is a **free-to-play multiplayer game** inspired by Counter-Strike surf.

## Documentation

**[View Full Documentation](https://bearlikelion.github.io/SurfsUpSDK/)**

## Features

- Easy level creation with pre-built ramp prefabs
- Built on Godot 4.5+ game engine
- Import and port Source engine BSP maps
- Custom texturing with included materials
- Hot reload testing with in-game developer console
- One-click export to SurfsUp installation

## Requirements

- **[Godot 4.5.1+](https://godotengine.org/download/archive/4.5.1-stable/)** - Game engine (required)
- **[Blender LTS](https://www.blender.org/download/lts/)** - For advanced BSP porting (optional)
- **SurfsUp** - Installed on [Steam](https://store.steampowered.com/app/3454830/SurfsUp/)

## Getting Started

### Installation

```bash
git clone https://github.com/bearlikelion/SurfsUpSDK.git
cd SurfsUpSDK
```

Or download and extract the [latest release](https://github.com/bearlikelion/SurfsUpSDK/releases/) from GitHub.

### Setup

1. Download and install [Godot v4.5.1](https://godotengine.org/download/archive/4.5.1-stable/) or newer
2. Launch Godot and click "Import"
3. Navigate to the `SurfsUpSDK` folder and select `project.godot`
4. Click "Import & Edit"

### Create Your First Map

1. Duplicate `Levels/test_level.tscn` and rename it
2. Drag ramp prefabs from `Levels/Ramps/Parts/` into the Level node
3. Position, rotate, and scale your ramps
4. Apply textures from `Assets/Textures/`

### Export and Test

1. Go to `Project → Tools → [SurfsUp] SDK Tools → Set Maps Directory`
2. Point to your SurfsUp installation's `Maps` folder
3. Click the **Export Map** button in the top-right corner
4. Launch SurfsUp and press **~** to open the console
5. Type: `map <your_map_name>`

**Note:** The exported PCK filename must match your scene path: `/Levels/<map_name>.tscn`

## Workflow

### Using Ramp Prefabs
Pre-made ramp GLB files are in `Levels/Ramps/Parts/`. Drag them into your scene's Level node.

[Ramp Prefabs Documentation](https://bearlikelion.github.io/SurfsUpSDK/prefabs/)

### Texturing
1. Right-click on a ramp prefab and enable **Editable Children**
2. Drag a StandardMaterial from `Assets/Textures/` onto the ramp mesh

[Texturing Documentation](https://bearlikelion.github.io/SurfsUpSDK/texturing/)

### Porting BSP Maps
1. Decompile BSP to VMF with [bspsrc](https://github.com/ata4/bspsrc/releases)
2. Import VMF into Blender using [Plumber](https://github.com/lasa01/Plumber)
3. Export as GLB to `Levels/<level>/` folder
4. Import into Godot and scale to (2.5, 2.5, 2.5)

[BSP Files Documentation](https://bearlikelion.github.io/SurfsUpSDK/bsp/)

## Project Structure

```
SurfsUpSDK/
├── Assets/
│   ├── Characters/      # Y-Bot reference character for scale
│   └── Textures/        # Standard materials
├── Levels/
│   ├── Ramps/Parts/     # Pre-made ramp prefab GLB files
│   └── test_level.tscn  # Example level template
├── docs/                # Documentation site
└── project.godot        # Godot project file
```

## Support

Join the [SurfsUp Discord Server](https://surfsup.website/discord) and ask your questions in the **[#mapping-help](https://discord.com/channels/1243644214105997373/1368970221733417090)** channel, share your custom maps, download others, and receive feebdack from the community on your creation in the **[#custom-maps](https://discord.com/channels/1243644214105997373/1394094598195777568)** channel.

## Contributing

Contributions are welcome:
- Submit bug reports and feature requests via [GitHub Issues](https://github.com/bearlikelion/SurfsUpSDK/issues)
- Fork the repository and submit pull requests
- Share custom prefabs and textures with the community

## License

This project is provided as-is for creating custom maps for SurfsUp. Please respect map creators' work when porting or modifying existing content.

**When porting BSP files, always ask for the original map maker's permission.**

## Links

- **Game:** [SurfsUp on Steam](https://store.steampowered.com/app/3454830/SurfsUp/)
- **Website:** [surfsup.website](https://surfsup.website)
- **Documentation:** [bearlikelion.github.io/SurfsUpSDK](https://bearlikelion.github.io/SurfsUpSDK/)
- **Discord:** [surfsup.website/discord](https://surfsup.website/discord)
