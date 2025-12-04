# AutoPilot

A comprehensive Mudlet package for Legends of the Jedi (LOTJ) that automates space travel and cargo hauling with an intuitive GUI interface.

## Features

- **Automated Space Travel** - Fly to single planets or multi-planet routes with full autopilot
- **Cargo Management** - Create and manage cargo manifests with delivery tracking
- **Ship Templates** - Save and load multiple ship configurations
- **Route Planning** - Create reusable flight routes for efficient travel
- **Preferred Landing Pads** - Set preferred landing pads for specific planets
- **Profit Tracking** - Monitor cargo run expenses, revenue, and credits per hour
- **Modern GUI** - Easy-to-use interface for all functionality
- **Command-Line Support** - All features also accessible via console commands

## Installation

1. Download the latest `AutoPilot.mpackage` from [Releases](https://github.com/Xavious/AutoPilot/releases)
2. In Mudlet, go to **Packages** → **Install**
3. Select the downloaded `AutoPilot.mpackage` file
4. The package will install and be ready to use

## Quick Start

### Opening the GUI

Type `ap help` or `ap gui` to open the AutoPilot control panel.

The GUI has four main tabs:
- **Status** - View autopilot status, current ship, route, and manifest
- **Ships** - Manage ship templates
- **Routes** - Create and manage flight routes
- **Manifests** - Create and manage cargo delivery manifests

### Basic Flight

1. **Set up a ship:**
   - Open GUI (`ap`)
   - Go to **Ships** tab
   - Click **[Add New Ship]**
   - Enter ship name (required)
   - If your ship requires walking to cockpit, add enter/exit paths
   - Click **[Save]**

2. **Fly somewhere:**
   - Command-line: `ap fly tatooine`
   - Or use GUI routes with **[Fly To]** button

### Running Cargo

1. **Create a manifest:**
   - Open GUI → **Manifests** tab
   - Click **[Add New Manifest]**
   - Set a name for your manifest
   - Click **[Add Delivery]**
   - Enter planet and resource
   - Optionally select a route to follow
   - Add more deliveries as needed
   - Click **[Save]**

2. **Start cargo run:**
   - Command-line: `ap start cargo`
   - AutoPilot will loop through deliveries, buying and selling automatically

3. **View profit:**
   - Command-line: `ap profit`

## GUI Guide

### Status Tab

The Status tab shows:
- **AutoPilot Status** - Enable/disable flight triggers with toggle button
- **Contraband Status** - Enable/disable contraband hauling with toggle button
- **Current Ship** - Currently loaded ship details
- **Flight Progress** - Current destination and remaining waypoints
- **Current Route** - Active route information
- **Current Manifest** - Active manifest deliveries

### Ships Tab

Manage your ship templates:
- **List View** - Shows all saved ships with **[Load]**, **[Edit]**, and **[Delete]** buttons
- **Add/Edit Form:**
  - **Ship Name** - The ship's name (required)
  - **Enter Path** - Comma-separated path to cockpit (e.g., `n,n,u`)
  - **Exit Path** - Comma-separated path from cockpit to hatch (e.g., `d,s,s`)
  - **Hatch Code** - For rented/borrowed ships
  - **Capacity** - Cargo hold capacity

### Routes Tab

Create reusable flight paths:
- **List View** - Shows all saved routes with **[Fly To]**, **[Edit]**, and **[Delete]** buttons
- **Add/Edit Form:**
  - **Route Name** - Descriptive name
  - **Planets** - Comma-separated list of waypoints (e.g., `corellia,coruscant,tatooine`)
  - Displays as: `corellia → coruscant → tatooine`
- **Fly To** - Immediately loads and flies the route

### Manifests Tab

Create cargo delivery manifests:
- **List View** - Shows all saved manifests with **[Load]**, **[Edit]**, and **[Delete]** buttons
- **Manifest Editor:**
  - **Manifest Name** - Set/edit name
  - **Deliveries** - List of planet/resource pairs
  - **Add Delivery** - Add new delivery stop
  - **Edit Delivery** - Modify existing delivery
    - Planet name
    - Resource to sell/buy
    - Optional route to follow (or fly direct)

## Command-Line Reference

All commands start with `ap`:

### Core Commands

| Command | Description |
|---------|-------------|
| `ap` or `ap gui` | Open AutoPilot GUI |
| `ap status` | Show current autopilot status |
| `ap on` | Enable autopilot triggers |
| `ap off` | Disable autopilot triggers |
| `ap help` | Show help index with available sections |
| `ap help <section>` | Show help for a specific section |

### Help Sections

Use `ap help <section>` to view help for a specific topic:

| Section | Description |
|---------|-------------|
| `ap help general` | General flight commands (status, fly, on, off, clear) |
| `ap help pad` | Landing pad preferences (set, clear, list) |
| `ap help ship` | Ship attribute commands (set ship, enter, exit, hatch, capacity) |
| `ap help shipmanage` | Ship management (save, load, delete ship templates) |
| `ap help route` | Route commands (add, save, load, delete, fly) |
| `ap help manifest` | Cargo/manifest commands (add delivery, start/stop/pause cargo, profit) |
| `ap help gui` | GUI and update commands |

**Example:**
```
ap help manifest
ap help route
ap help general
```

### Flight Commands

| Command | Description |
|---------|-------------|
| `ap fly <planet>` | Fly to a single planet |
| `ap fly <p1>,<p2>,<p3>` | Fly to multiple waypoints |

**Examples:**
```
ap fly tatooine
ap fly ithor,kashyyyk,coruscant
ap fly kashyyyk,corellia,kashyyyk,corellia  (leveling loop)
```

For more flight-related help, use: `ap help general`

### Ship Commands

| Command | Description |
|---------|-------------|
| `ap set ship <name>` | Set ship name |
| `ap set enter <path>` | Set cockpit entry path (comma-separated) |
| `ap set exit <path>` | Set hatch exit path (comma-separated) |
| `ap set hatch <code>` | Set hatch code |
| `ap set capacity <amount>` | Set cargo capacity |
| `ap save ship` | Save current ship as template |
| `ap load ship [#]` | Load ship template (no # shows list) |

**Examples:**
```
ap set ship "My Freighter"
ap set enter n,n,u
ap set exit d,s,s
ap set hatch 1234
ap set capacity 500
ap save ship
```

For more ship-related help:
- `ap help ship` - Ship attribute commands
- `ap help shipmanage` - Ship management commands

### Route Commands

| Command | Description |
|---------|-------------|
| `ap route add <planets>` | Create a reusable route |
| `ap route save [name]` | Save current route as template |
| `ap route load [#]` | Load route template (no # shows list) |
| `ap route delete <#>` | Delete a route by ID |
| `ap fly route` | Fly using the currently loaded route |

For more route-related help, use: `ap help route`

### Manifest/Cargo Commands

| Command | Description |
|---------|-------------|
| `ap add delivery <planet>:<resource>` | Add delivery to current manifest |
| `ap manifest view` | Show current manifest details |
| `ap manifest save [name]` | Save manifest to list |
| `ap manifest load <#>` | Load a manifest by ID |
| `ap manifest delete <#>` | Delete a manifest by ID |
| `ap cargo start` | Start cargo automation |
| `ap cargo stop` | Stop cargo automation |
| `ap cargo pause` | Pause and save current run |
| `ap cargo resume` | Resume paused cargo run |
| `ap profit` | Show profit report |
| `ap contraband <on/off>` | Toggle contraband mode |

**Examples:**
```
ap add delivery coruscant:electronics
ap add delivery corellia:food
ap cargo start
ap profit
```

For more manifest and cargo help, use: `ap help manifest`

### Landing Pad Commands

| Command | Description |
|---------|-------------|
| `ap pad set <planet> "<pad>"` | Set preferred landing pad for planet |
| `ap pad clear <planet>` | Clear preferred landing pad |
| `ap pad list` | List all configured landing pads |

**Examples:**
```
ap pad set coruscant "Eastport Station"
ap pad set kashyyyk "Cargo Bay 3"
ap pad list
```

For more landing pad help, use: `ap help pad`

## How It Works

### Flight Automation

AutoPilot monitors game output with triggers that automatically:
1. Launch your ship when you enter cockpit
2. Engage autopilot to destination
3. Wait for hyperspace travel
4. Land on arrival (using preferred pad if set)
5. Exit ship and continue to next waypoint if any

### Cargo Automation

When running cargo with a manifest:
1. AutoPilot visits each delivery in sequence
2. Sells cargo hold contents at destination planet
3. Buys the resource specified for that delivery
4. Flies to next delivery (using specified route or direct)
5. Tracks expenses, revenue, and fuel costs
6. Loops back to first delivery when complete

**Important:** Start cargo runs with an empty cargo hold.

### Routes vs Manifests

- **Routes** - Simple planet waypoint lists for flying only
- **Manifests** - Cargo delivery lists with planet/resource pairs
  - Each delivery can optionally use a route or fly direct
  - Manifests are for cargo automation

## Tips and Best Practices

1. **Ship Setup** - Single-seater ships only need a name; larger ships need enter/exit paths
2. **Save Templates** - Create ship/route/manifest templates for quick reuse
3. **Preferred Pads** - Set preferred landing pads for busy planets to avoid queues
4. **Empty Holds** - Always start cargo runs with empty cargo holds
5. **Kill Switch** - Use `ap off` to immediately disable all automation
6. **Profit Tracking** - Run `ap profit` during cargo runs to monitor credits/hour

## Troubleshooting

**AutoPilot not responding?**
- Check if triggers are enabled: `ap status`
- Enable triggers: `ap on`
- Verify ship is loaded: `ap status`

**Ship won't launch/land?**
- Check ship name matches exactly: `ap set ship <name>`
- Verify you're at the correct location (hatch/cockpit)

**Cargo not buying/selling?**
- Ensure manifest is loaded
- Verify cargo hold is empty when starting
- Check resource names match game exactly

**GUI not showing?**
- Type `ap gui` to open
- Check for Mudlet errors in console

## Development

This package is built using [Muddler](https://github.com/demonnic/muddler) development paradigm.

**For Developers:**
- Source code: `/src/` directory
- Main script: `src/scripts/autopilot.script.lua`
- Triggers: `src/triggers/`
- See [CLAUDE.md](CLAUDE.md) for comprehensive development documentation

## Future Enhancements

Potential features being considered:
- Turbolift support for ground navigation
- Enhanced route optimization
- More intuitive first-time setup flow
- Cargo marketplace price tracking

## Contributing

Issues and pull requests welcome at [GitHub Issues](https://github.com/Xavious/AutoPilot/issues)

## License

See repository for license information.

## Credits

Created by Xavious for the LOTJ community.
