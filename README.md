HP Omen special feature control for Linux (with macro key support)
------------------------------------------------------------------

This is a fork of [pointzerotwo/hp-omen-linux-module](https://github.com/pointzerotwo/hp-omen-linux-module)
with **P1-P6 macro key support** ported from [xddxdd/hp-omen-linux-module](https://github.com/xddxdd/hp-omen-linux-module).

The original xddxdd module added macro key support but no longer compiles on
kernels 6.17+. The pointzerotwo fork fixed kernel compatibility but didn't
include macro keys. This fork combines both.

### What was changed

- Enlarged `bios_args.data` buffer from 128 to 4096 bytes to fit the macro profile
- Added `HPWMI_MACRO_PROFILE_SET` and `HPWMI_MACRO_MODE_SET` WMI commands
- Added `HPWMI_GM` command type for gaming WMI queries
- Switched `hp_wmi_perform_query` from stack to heap allocation (`kzalloc`) since the struct is now ~4KB
- Added `macro_profile_bytes[4096]` that programs P1-P6 to emit `Ctrl+Shift+Alt+F1-F6`
- Added `macro_key_setup()` / `macro_key_remove()` called on module load/unload

### Why Ctrl+Shift+Alt combos?

The HP EC only supports PS/2 Scan Code Set 1 (codes 0x01-0x58). Keys like
F13-F18 don't exist in this set, and codes above 0x58 get mangled by the EC's
internal translation. Using combos of real modifier keys + F-keys gives unique
bindings that won't conflict with any physical key, while staying within the
EC's supported range.

This is AI slop coded just to quickly get it working so
**USE AT YOUR OWN RISK**

Currently working:

- FourZone keyboard colour control (`/sys/devices/platforms/hp-wmi/rgb-zones/zone0[0-3]`)
- Omen hotkeys
- **P1-P6 macro keys** (emit Ctrl+Shift+Alt+F1-F6)

## Installation

```bash
git clone https://github.com/pointzerotwo/hp-omen-linux-module.git
cd hp-omen-linux-module
sudo ./install.sh
```

This will automatically install dependencies, build the kernel module via DKMS, and set up the `omen-rgb` CLI tool.

Supports: Debian/Ubuntu, Arch, Fedora, and openSUSE.

To uninstall:
```bash
sudo ./install.sh --uninstall
```

## Usage

### Using the omen-rgb CLI Tool

#### Basic Usage

```bash
# Set a single zone to a color
sudo omen-rgb --zone 0 --color FF0000          # Red using hex
sudo omen-rgb --zone 1 --color red             # Red using color name

# Set multiple zones to the same color
sudo omen-rgb --zones 0,1,2 --color cyan

# Set all zones to the same color
sudo omen-rgb --all --color blue

# Set different colors for different zones
sudo omen-rgb 0:FF0000 1:00FF00 2:0000FF 3:FFFF00

# Get current color of a zone
omen-rgb --get 0

# Get all zone colors
omen-rgb --get-all

# Save current configuration
sudo omen-rgb --save-config my-scheme

# Load saved configuration
sudo omen-rgb --load-config my-scheme

# List saved configurations
omen-rgb --list-configs

# List available color presets
omen-rgb --list-colors

# Show help
omen-rgb --help
```

#### Available Color Presets

The tool supports named colors: `red`, `green`, `blue`, `cyan`, `magenta`, `yellow`, `white`, `orange`, `purple`, `pink`, `lime`, `teal`, `off`, `black`

#### Keyboard Animations

The tool supports three animation effects that can run in foreground or as a background daemon.

**Animation Types:**
- `breathe` - Fades zones in and out smoothly (breathing/pulse effect)
- `cycle` - Smoothly transitions through a color palette
- `wave` - Colors ripple across zones from left to right

**Basic Usage:**

```bash
# Breathing animation (foreground, Ctrl+C to stop)
sudo omen-rgb --animate breathe --colors cyan

# Color cycle with custom colors
sudo omen-rgb --animate cycle --colors red orange yellow green blue purple

# Wave animation with slower speed (2 seconds per cycle)
sudo omen-rgb --animate wave --colors cyan magenta --speed 2.0
```

**Daemon Mode (Background):**

```bash
# Start animation as background daemon
sudo omen-rgb --animate breathe --colors blue --daemon

# Check daemon status
omen-rgb --status

# Stop the daemon
sudo omen-rgb --stop
```

**Animation Options:**
- `--speed SECONDS` - Animation speed in seconds per cycle (default: 1.0)
- `--colors COLOR...` - One or more colors (hex or named). Defaults vary by animation type.
- `--daemon` - Run animation in background

### Direct sysfs Access (Advanced)

The module creates four files in `/sys/devices/platform/hp-wmi/rgb_zones/` named `zone00 - zone03`.

To change zone highlight color, just print hex colour value in RGB format to the respective file. e.g:

`sudo bash -c 'echo 00FFFF > /sys/devices/platform/hp-wmi/rgb_zones/zone00'` to get sky-blue zone 0.

### Hotkeys

Omen and other hotkeys are bound to regular X11 keysyms, use your chosen desktop's hotkey manager to assign them to functions like any other key.

## To do:

- [x] FourZone keyboard animations (breathing, cycle, wave)
- [ ] FourZone brightness control (hardware)
- [ ] Hardware animation support (reverse engineer WMI)
- [ ] Fan control

