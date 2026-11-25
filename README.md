# Custom skies

**English** | **[Русский](https://github.com/Nord1cWarr1or/Custom-skies/blob/master/README.ru.md)**

Custom skies is an AMX Mod X plugin for Counter-Strike 1.6 on ReHLDS that sets a custom skybox on every map: a random one from a list, a fixed or random one from a per-map list, or no custom sky at all, so the skybox built into the map stays. It is aimed at server owners who want custom skies without editing the maps.

## Features

- A random sky from the `[list random skies]` list on every map.
- Per-map settings in `[map settings]`: one sky, or several skies of which one is picked at random on each map load.
- `none` for a map: the plugin changes nothing and the skybox built into the map is used.
- Only the six textures of the chosen sky are precached, so players download one sky, not the whole list.
- Skies with missing texture files are skipped and the missing file is written to the AMXX log.

## Requirements

- AMX Mod X 1.8.3 or higher (tested on 1.10.0.5484)
- No additional modules

## Installation

1. Download `custom_skies.sma`.
2. Compile the plugin:
   - locally (recommended): put the `.sma` into `scripting/` and run the compiler;
   - via a web compiler.
3. Copy `custom_skies.amxx` to `addons/amxmodx/plugins/`.
4. Copy `addons/amxmodx/configs/custom_skies.ini` to `addons/amxmodx/configs/`.
5. Copy the sky textures to `cstrike/gfx/env/`. The repository ships two skies, `nebulous` and `plume`, in `gfx/env/`.
6. Add `custom_skies.amxx` to `addons/amxmodx/configs/plugins.ini`.
7. Change the map or restart the server.

### Upgrading from 0.1.0

- The plugin and the config were renamed: `CustomSkies.amxx` → `custom_skies.amxx`, `CustomSkies.ini` → `custom_skies.ini`. Replace the line in `plugins.ini` and delete the old files.
- The config format changed. The old plain list of names goes under `[list random skies]`.
- The `#` comment character is gone, use `;`.

## Configuration

The plugin reads `addons/amxmodx/configs/custom_skies.ini` at map start. A sky is named by its texture prefix, without the side suffix: the name `nebulous` stands for `gfx/env/nebulousbk.tga`, `nebulousdn.tga`, `nebulousft.tga`, `nebulouslf.tga`, `nebulousrt.tga` and `nebulousup.tga`. A name may include a subfolder, for example `skyservers/milky`.

| Section | Content |
|---------|---------|
| `[list random skies]` | One sky name per line. Used on every map that has no valid line in `[map settings]`. |
| `[map settings]` | Lines of the form `mapname = sky` or `mapname = sky1, sky2, ...`. |

| Value of `mapname = ...` | Result |
|--------------------------|--------|
| `sky` | This sky is always set on the map. |
| `sky1, sky2, ...` | One of the listed skies is picked at random on each map load. |
| `none` | No sky is set, the skybox built into the map is used. |
| `none, sky1, ...` | `none` is one of the random options. |

Example:

```ini
[list random skies]
nebulous
plume

[map settings]
de_dust2 = none
de_inferno = nebulous
de_nuke = nebulous, plume
```

Rules:

- `;` starts a comment, including at the end of a line. `#` is not a comment character.
- Map names are compared case-insensitively.
- If a map is listed several times, the last line wins.
- If no sky in a map's line is valid (texture files are missing), the plugin falls back to `[list random skies]`.
- If no valid sky is left at all, the built-in sky of the map stays and the AMXX log says so.
- Sections with other names, and sections without a closing bracket, are ignored and logged.

## Technical notes

- The sky is chosen and `sv_skyname` is set in `plugin_precache`. The plugin registers the read-only cvar `CustomSkies_version`.
- The six textures of the chosen sky are added to the resource list with `precache_generic`, so clients download them from the server.
- A texture with an uppercase side suffix (`nebulousBK.tga`) is renamed to lowercase on the server, because the file lookup on Linux is case-sensitive.
- The config is read once per map. Changes apply on the next map load.
- Map names are matched exactly: there are no wildcards or prefixes.
- If `custom_skies.ini` cannot be opened, the plugin stops with the error `Unable to open file`.

## Credits

- **Nordic Warrior** — author.

## License

Distributed under the MIT License. See `LICENSE` for more information.
