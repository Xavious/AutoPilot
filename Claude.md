# AutoPilot - Claude Code Development Guide

## Project Overview

AutoPilot is a Mudlet plugin for the LOTJ (Legends of the Jedi) MUD that automates space travel and cargo hauling. Built using Lua, it provides both command-line interface and a comprehensive GUI for managing ships, routes, manifests, and automated flight.

**Key Technologies:**
- Mudlet MUD Client
- Lua scripting language
- Geyser GUI framework
- Muddler development paradigm

**GitHub Repository:** https://github.com/Xavious/AutoPilot

## Architecture Overview

### Core Data Model

All persistent data is stored in a global `autopilot` table that is saved to disk using Mudlet's `table.save()` function:

```lua
autopilot = {
  ships = {},           -- Array of ship templates
  ship = {},            -- Currently loaded ship configuration
  routes = {},          -- Array of route templates (old cargo system)
  manifests = {},       -- Array of manifest templates (new cargo system)
  currentRoute = nil,   -- Currently loaded route
  currentManifest = nil,-- Currently loaded manifest
  preferredPads = {},   -- Table mapping planet names to preferred landing pads
  runningCargo = false, -- Boolean flag for cargo automation
  useContraband = false,-- Boolean flag for contraband hauling

  -- Flight state
  destination = {},     -- Current destination planet/sector info
  waypoints = {},       -- Array of remaining waypoints

  -- Cargo tracking
  expense = 0,
  revenue = 0,
  fuelCost = 0,
  startTime = 0,
  profit = 0
}
```

**Persistence:** All changes to `autopilot.ships`, `autopilot.routes`, `autopilot.manifests`, and `autopilot.preferredPads` must be followed by:
```lua
table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
```

### File Structure

```
/src/
  /scripts/
    autopilot.script.lua          # Main script file (~2750+ lines)
  /aliases/
    autopilot.alias.*.lua         # Individual alias command files
  /triggers/
    triggers.json                 # Top-level trigger group definitions
    /autopilot.flight/
      triggers.json               # Flight automation triggers
    /autopilot.cargo/
      triggers.json               # Cargo automation triggers

/build/filtered/                  # Build output (mirrors src/ structure)
```

**Key File:** Nearly all functionality is in [src/scripts/autopilot.script.lua](src/scripts/autopilot.script.lua). This contains:
- All GUI code
- Core flight/cargo automation logic
- Helper functions
- Command-line alias implementations

### GUI Architecture

The GUI uses the **Geyser framework** with a view stack navigation pattern:

#### Main GUI Components

```lua
autopilot.gui = {
  window = nil,           -- Main Geyser.Label container
  header = nil,           -- Tab navigation bar
  content = nil,          -- Main Geyser.MiniConsole for content display
  formContainer = nil,    -- Geyser.Label for forms (hidden when not in use)

  -- View stack
  viewStack = {},         -- Navigation history

  -- Form state
  formData = nil,         -- Current form's input data
  workingManifest = nil,  -- Temporary manifest being edited
  workingManifestIndex = nil, -- Index in autopilot.manifests if editing existing
  manifestEditor = nil,   -- Flag/state object indicating manifest editor is active

  -- Configuration
  config = {
    window = {x, y, width, height},
    header = {x, y, width, height},
    content = {x, y, width, height}
  },

  colors = {
    background = "#1a1a1a",
    border = "#333333",
    header_bg = "#2a2a2a",
    -- etc.
  }
}
```

#### View Stack Pattern

Navigation works via push/pop:

```lua
autopilot.pushView(viewFunc)  -- Add new view to stack, execute it
autopilot.popView()           -- Go back to previous view
```

When `popView()` is called, it calls `refreshGUI()` which checks for active manifest editor:

```lua
function autopilot.refreshGUI()
  if autopilot.gui.workingManifest and autopilot.gui.manifestEditor then
    autopilot.refreshManifestEditor()
  else
    autopilot.popView()
  end
end
```

**CRITICAL:** The `refreshGUI()` function is used extensively. Be careful not to break the manifest editor check logic.

### Working Copy Pattern (Critical)

The GUI uses a **working copy pattern** for editing manifests:

1. When editing starts, create deep copy: `autopilot.gui.workingManifest = table.deepcopy(autopilot.manifests[index])`
2. All edits modify `workingManifest` only
3. Final "Save" button writes `workingManifest` to `autopilot.manifests` and disk

**Dual Save Pattern:**
- **Editing EXISTING manifest:** Changes save immediately to both `autopilot.manifests[index]` AND disk
- **Creating NEW manifest:** Changes only update `workingManifest`, save to disk happens when final Save clicked

Example from editing delivery in existing manifest:
```lua
local manifestIndex = autopilot.gui.workingManifestIndex
if manifestIndex then
  -- Editing existing manifest - update saved copy and save to disk
  autopilot.manifests[manifestIndex].deliveries[deliveryIndex] = updatedDelivery
  autopilot.gui.workingManifest.deliveries[deliveryIndex] = updatedDelivery
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
else
  -- Editing delivery in new manifest - only update working copy
  autopilot.gui.workingManifest.deliveries[deliveryIndex] = updatedDelivery
end
```

### Geyser Framework Components

#### Geyser.Label
General-purpose container and button element:
```lua
local label = Geyser.Label:new({
  name = "unique_name",
  x = "10%", y = "5%",      -- Percentage-based positioning
  width = "80%", height = "10%",
}, parent)

label:setStyleSheet([[background-color: #1a1a1a;]])
label:setClickCallback(function() ... end)  -- For buttons
```

#### Geyser.MiniConsole
Scrollable text display with color support:
```lua
local console = Geyser.MiniConsole:new({
  name = "unique_name",
  x = "5%", y = "10%",
  width = "90%", height = "80%",
  autoWrap = true,
  scrollBar = true,
  fontSize = 12
}, parent)

console:clear()
console:cecho("<white>Text with <cyan>colors<reset>\n")
console:fg("yellow")
console:echoLink("[Click Me]", [[send("command")]], "Tooltip text", true)
console:resetFormat()
```

**IMPORTANT:** Always specify `fontSize = 12` for consistency.

#### Geyser.CommandLine
Text input widget:
```lua
local input = Geyser.CommandLine:new({
  name = "unique_name",
  x = "5%", y = "50%",
  width = "90%", height = "5%",
  fontSize = 12
}, parent)
```

**IMPORTANT:** Always use percentage-based positioning (never pixels) for responsive scaling.

### Forms System

Forms use `autopilot.gui.formContainer` which is created/destroyed via `autopilot.cleanupFormUI()`:

```lua
function autopilot.cleanupFormUI()
  -- Destroy the entire formContainer (and all its children)
  if autopilot.gui.formContainer then
    autopilot.gui.formContainer:hide()
    autopilot.gui.formContainer = nil
  end

  -- Recreate a fresh formContainer
  autopilot.gui.formContainer = Geyser.Label:new({...})
  autopilot.gui.formContainer:hide()

  -- Clear form data
  autopilot.gui.formData = nil

  -- NOTE: Don't clear manifestEditor or workingManifest here!
  -- They're needed by manifest editor callbacks
}
```

**CRITICAL:** Do NOT clear `manifestEditor` or `workingManifest` in `cleanupFormUI()` - this was a major bug.

### Manifest Editor System

The manifest editor has special handling because it's not a simple form:

```lua
function autopilot.showManifestEditor(manifestIndex)
  autopilot.cleanupFormUI()  -- Clean up first

  local isEdit = manifestIndex ~= nil

  -- Always create a fresh working manifest (CRITICAL: no conditional preservation)
  local manifest = manifestIndex and table.deepcopy(autopilot.manifests[manifestIndex]) or {name = "", deliveries = {}}
  autopilot.gui.workingManifest = manifest
  autopilot.gui.workingManifestIndex = manifestIndex

  -- Store references
  autopilot.gui.manifestEditor = {
    isEdit = isEdit,
    manifestIndex = manifestIndex
  }

  -- Display in main content area (not formContainer)
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()

  autopilot.refreshManifestEditor()
end
```

```lua
function autopilot.refreshManifestEditor()
  if not autopilot.gui.manifestEditor or not autopilot.gui.workingManifest then
    return
  end

  -- CRITICAL: Ensure form container is hidden and content is shown
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()

  local console = autopilot.gui.content
  console:clear()

  -- Display manifest name, deliveries, buttons, etc.
  -- Uses echoLink for interactive elements
}
```

**Key Gotchas:**
1. Always create fresh `workingManifest` without conditional checks
2. Manifest editor uses main `content` console, NOT `formContainer`
3. `refreshManifestEditor()` must hide formContainer and show content
4. Don't clear `manifestEditor` flag in `cleanupFormUI()`

## Trigger System

Triggers are organized into groups:

- **autopilot.flight** - Flight automation triggers (orbit, hyperspace, landing, etc.)
- **autopilot.cargo** - Cargo purchase/sale tracking triggers

Enable/disable with:
```lua
enableTrigger("autopilot.flight")
disableTrigger("autopilot.flight")
```

### Trigger Definitions

Triggers are defined in JSON files with regex patterns:

```json
{
  "name": "autopilot.trigger.orbit",
  "isActive": "yes",
  "patterns": [
    {
      "pattern": "^You are now orbiting (?<planet>\\w+)\\.$",
      "type": "regex"
    }
  ],
  "script": ""
}
```

The actual trigger logic is in [autopilot.script.lua](src/scripts/autopilot.script.lua), e.g.:

```lua
function autopilot.trigger.orbit()
  local planet = matches.planet
  local preferredPad = autopilot.getPreferredPad(planet)

  if preferredPad then
    send("land '"..planet.."' "..preferredPad)
  else
    send("land "..planet)
  end
end
```

**CRITICAL:** When editing regex patterns in JSON:
- Use proper angle brackets `<` and `>` for named groups
- NEVER use Unicode escapes like `\u003c` or `\u003e`
- Pattern format: `(?<groupName>pattern)`

## Key Functionality

### Flight Automation

Located in [autopilot.script.lua](src/scripts/autopilot.script.lua):

**Starting a flight:**
```lua
autopilot.alias.fly("planet1,planet2,planet3")
```

This:
1. Parses comma-separated planet list into `autopilot.waypoints`
2. Sets first waypoint as `autopilot.destination.planet`
3. Enables `autopilot.flight` trigger group
4. Opens ship and enters cockpit

**Trigger flow:**
1. `trigger.inCockpit()` → `launch`
2. `trigger.space()` → `autopilot "planet"`
3. `trigger.hyperspace()` → waits
4. `trigger.orbit()` → `land` (with preferred pad if set)
5. `trigger.land()` → checks for more waypoints, repeats or exits ship

**Preferred Pads:**
- Stored in `autopilot.preferredPads[planetName:lower()] = padNumber`
- Logic fires in `trigger.orbit()` (NOT in `startLanding()`)

### Routes vs Manifests

**Routes** (old system):
- Simple list of planets: `{name = "Route Name", planets = {"planet1", "planet2"}}`
- Used for flying only, no cargo

**Manifests** (new system):
- More complex: `{name = "Manifest Name", deliveries = [...]}`
- Each delivery: `{planet = "...", resource = "...", route = routeIndex}`
- Deliveries can specify a route to follow OR fly direct

### Route Display Helper

Always use this for consistent route display:

```lua
function autopilot.formatRouteText(routeIndex)
  if not routeIndex then
    return " <gray>(direct)"
  end

  local route = autopilot.routes[routeIndex]
  if not route or not route.planets or #route.planets == 0 then
    return " <gray>(route #" .. routeIndex .. ")"
  end

  -- Build route path: planet1 → planet2 → planet3
  local routePath = ""
  for i, planet in ipairs(route.planets) do
    if i > 1 then
      routePath = routePath .. " → "
    end
    routePath = routePath .. planet
  end

  return " <gray>(route: " .. routePath .. ")"
end
```

### GUI Flying Routes

GUI "Fly To" button uses:

```lua
function autopilot.flyRoute(routeIndex)
  local route = autopilot.routes[routeIndex]
  autopilot.currentRoute = table.deepcopy(route)
  autopilot.waypoints = table.deepcopy(route.planets)
  autopilot.destination = {}
  autopilot.destination.planet = table.remove(autopilot.waypoints, 1)

  enableTrigger("autopilot.flight")
  autopilot.openShip()
end
```

## Common Patterns and Best Practices

### 1. Deep Copying Tables

**ALWAYS** use `table.deepcopy()` when copying tables to avoid reference issues:

```lua
local copy = table.deepcopy(original)
```

### 2. Closures in Callbacks

When using variables in echoLink callbacks, ensure they're captured correctly:

```lua
local selectedRoute = deliveryData.route  -- Capture in local variable

console:echoLink("[Save]", function()
  -- selectedRoute is now properly captured in closure
  delivery.route = selectedRoute
end, "Save delivery", true)
```

### 3. Form Navigation

When returning from a form to manifest editor:
1. Form calls callback function with updated data
2. Callback updates `workingManifest` and optionally saves to disk
3. Callback calls `autopilot.refreshGUI()`
4. `refreshGUI()` checks for `workingManifest` and calls `refreshManifestEditor()`

### 4. Route Selection UI

Use MiniConsole with echoLinks (NOT Geyser flyout labels - they're buggy):

```lua
local routeConsole = Geyser.MiniConsole:new({...}, parent)
local selectedRoute = nil  -- Captured in closure

local function refreshRouteConsole()
  routeConsole:clear()
  routeConsole:cecho("<white>Selected: <cyan>" .. (selectedRoute or "Direct") .. "\n")

  -- Direct option
  routeConsole:echoLink("[Direct]", function()
    selectedRoute = nil
    refreshRouteConsole()
  end, "Direct flight", true)

  -- Route options
  for i, route in ipairs(autopilot.routes) do
    routeConsole:echoLink("[Route "..i.."]", function()
      selectedRoute = i
      refreshRouteConsole()
    end, "Select route "..i, true)
  end
end

refreshRouteConsole()  -- Initial display
```

### 5. Percentage-Based Positioning

**ALWAYS** use percentages for GUI positioning:

```lua
-- GOOD
x = "10%", y = "5%", width = "80%", height = "10%"

-- BAD (don't use pixels)
x = 50, y = 100, width = 400, height = 50
```

### 6. Font Size Consistency

**ALWAYS** specify `fontSize = 12` for MiniConsole and CommandLine:

```lua
local console = Geyser.MiniConsole:new({
  fontSize = 12,  -- ALWAYS include this
  ...
})
```

## Common Gotchas and Debugging

### Problem: Manifest Editor Shows Blank on First Load

**Symptom:** First click shows blank form, second click works

**Cause:** Preservation logic interfering with initialization

**Solution:** Always create fresh `workingManifest` without conditionals:
```lua
-- GOOD
local manifest = manifestIndex and table.deepcopy(autopilot.manifests[manifestIndex]) or {name = "", deliveries = {}}
autopilot.gui.workingManifest = manifest

-- BAD (don't preserve existing)
if not autopilot.gui.workingManifest then
  autopilot.gui.workingManifest = ...
end
```

### Problem: Changes Not Persisting After Form Edit

**Symptom:** Edit form, save, return to editor - changes gone

**Common Causes:**
1. `refreshGUI()` calling `showManifestEditor()` instead of `refreshManifestEditor()`
2. `cleanupFormUI()` clearing `manifestEditor` flag
3. Form container not being hidden after edit
4. Saving to disk for NEW manifests (not yet in `autopilot.manifests`)

**Solutions:**
1. Ensure `refreshGUI()` checks for `workingManifest` existence
2. Don't clear `manifestEditor` in `cleanupFormUI()`
3. Add hide/show logic to `refreshManifestEditor()`
4. Implement dual save pattern (see "Working Copy Pattern" above)

### Problem: Trigger Regex Not Matching

**Symptom:** Trigger fires but `matches` table is empty or malformed

**Cause:** JSON regex patterns mangled with Unicode escapes

**Solution:** Check pattern uses proper angle brackets:
```json
// GOOD
"pattern": "^You purchased (?<amount>[\\d]+) units"

// BAD (don't use Unicode escapes)
"pattern": "^You\\x1bpurchased\\x1b(?\u003camount\u003e[\\d]+)"
```

### Problem: GUI Elements Not Scaling

**Symptom:** Window resize causes misalignment

**Cause:** Using pixel-based positioning instead of percentages

**Solution:** Convert all positioning to percentages (see "Percentage-Based Positioning" above)

### Problem: Variable Not Captured in Closure

**Symptom:** Local variable updates in callback but reverts

**Cause:** Variable not properly captured in closure scope

**Solution:** Ensure variable is local to the function creating the callback:
```lua
-- GOOD
local function createForm()
  local selectedValue = initialValue  -- Local to this function

  button:setClickCallback(function()
    selectedValue = newValue  -- Captured correctly
  end)
end

-- BAD (global or outer scope variable)
selectedValue = initialValue  -- Outside closure scope
button:setClickCallback(function()
  selectedValue = newValue  -- May not persist
end)
```

## Status Page Features

The status page ([autopilot.gui.showStatus()](src/scripts/autopilot.script.lua)) displays:

- **Flight Triggers Status** with Enable/Disable toggle
- **Contraband Status** with Enable/Disable toggle
- **Current Ship** details
- **Flight Progress:**
  - Current destination (always shown, even if none)
  - Remaining waypoints with numbered list
  - Final destination marked with star (★)
- **Current Route** details
- **Current Manifest** details

Example flight progress display:
```
Flight Progress:
  Current Destination: ➜ Kashyyyk
  Remaining Waypoints:
    1. Corellia
    2. ★ Coruscant (Final Destination)
```

## Command-Line Interface

All commands start with `ap`:

**Flight:**
- `ap fly planet` - Fly to single planet
- `ap fly planet1,planet2,planet3` - Fly with waypoints

**Ship Management:**
- `ap set ship <name>` - Set ship name
- `ap set enter <path>` - Set cockpit entry path (comma-separated)
- `ap set exit <path>` - Set hatch exit path (comma-separated)
- `ap set hatch <code>` - Set hatch code
- `ap set capacity <amount>` - Set cargo capacity
- `ap save ship` - Save ship template
- `ap load ship [#]` - Load ship template

**Routes:**
- `ap save route` - Save current route
- `ap load route [#]` - Load route template

**Manifests:**
- `ap add delivery <planet>:<resource>` - Add delivery to manifest

**Preferred Pads:**
- `ap set pad <planet> <#>` - Set preferred landing pad
- `ap clear pad <planet>` - Clear preferred landing pad

**Cargo:**
- `ap start cargo` - Start cargo automation
- `ap stop cargo` - Stop cargo automation
- `ap profit` - Show profit report

**Status:**
- `ap status` - Show current configuration
- `ap on` - Enable triggers
- `ap off` - Disable triggers

## Development Workflow

1. **Edit source files** in `/src/`
2. **Package with Muddler** (if using)
3. **Test in Mudlet** by loading package
4. **Save persistent data** with `table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)`

### Debugging

Enable debug output:
```lua
debugc("Debug message")  -- Only shows if debug mode enabled
```

Check trigger status:
```lua
local status = getTriggerInfo("autopilot.flight")
```

Inspect autopilot table:
```lua
display(autopilot.manifests)
display(autopilot.gui.workingManifest)
```

## Auto-Update System

The plugin includes auto-update functionality that checks GitHub for new releases:

**Configuration:**
```lua
autopilot.config = {
  github_repo = "Xavious/AutoPilot",
  update_check_done = false
}
```

**Known Issue:** Auto-update doesn't trigger on session start (pending investigation)

## Future Considerations

From README.md TODO:
- Streamline flow/setup to be more intuitive
- Support for turbolifts
- Support for landing pad preference (partially implemented)

From conversation:
- Consider consolidating command-line aliases to redirect to GUI
- Potential GUI-first approach for all displays
- Code cleanup opportunities

## Testing Checklist

When making changes, verify:

- [ ] Manifest editor displays correctly on first load
- [ ] Route selection persists in delivery forms
- [ ] New manifest changes save only to workingManifest
- [ ] Existing manifest changes save immediately to disk
- [ ] Form container hides after editing
- [ ] Content console shows after returning from form
- [ ] Percentage-based positioning scales correctly
- [ ] Font sizes consistent at 12pt
- [ ] Trigger patterns use proper angle brackets (not Unicode)
- [ ] Preferred pad logic fires in trigger.orbit()
- [ ] Status page shows all required information
- [ ] Enable/Disable toggles work correctly

## Key Files Reference

| File | Purpose | Lines |
|------|---------|-------|
| [src/scripts/autopilot.script.lua](src/scripts/autopilot.script.lua) | Main script - all logic | ~2750+ |
| [src/triggers/triggers.json](src/triggers/triggers.json) | Top-level trigger groups | ~12 |
| [src/triggers/autopilot.flight/triggers.json](src/triggers/autopilot.flight/triggers.json) | Flight triggers | Multiple |
| [src/triggers/autopilot.cargo/triggers.json](src/triggers/autopilot.cargo/triggers.json) | Cargo triggers | ~70 |
| [README.md](README.md) | User documentation | ~237 |

## Important Function Reference

### GUI Functions
- `autopilot.gui.init()` - Initialize GUI
- `autopilot.gui.showStatus()` - Status page (~2550-2650)
- `autopilot.gui.showShips()` - Ships list page (~2650-2700)
- `autopilot.gui.showRoutes()` - Routes list page (~2700-2750)
- `autopilot.gui.showManifests()` - Manifests list page (~2750-2800)
- `autopilot.showManifestEditor(index)` - Manifest editor (~1885-1909)
- `autopilot.refreshManifestEditor()` - Refresh manifest display (~1648-1670)
- `autopilot.cleanupFormUI()` - Clean up form container (~2004-2032)
- `autopilot.pushView(func)` - Push view to stack
- `autopilot.popView()` - Pop view from stack
- `autopilot.refreshGUI()` - Refresh current view

### Form Functions
- `autopilot.showShipForm(index)` - Ship editor form
- `autopilot.showRouteForm(index)` - Route editor form
- `autopilot.showManifestNameDialog(callback)` - Manifest name form
- `autopilot.showDeliveryDialog(data, index, callback)` - Delivery editor form (~1551-1619)

### Flight Functions
- `autopilot.alias.fly(planets)` - Start flight (~300-340)
- `autopilot.flyRoute(index)` - Fly saved route (~312-340)
- `autopilot.trigger.orbit()` - Orbit trigger handler (~855-869)
- `autopilot.trigger.hyperspace()` - Hyperspace trigger handler
- `autopilot.trigger.land()` - Landing trigger handler
- `autopilot.openShip()` - Open ship hatch (~67-74)
- `autopilot.getPreferredPad(planet)` - Get preferred pad (~36-41)

### Helper Functions
- `autopilot.formatRouteText(index)` - Format route display (~1602-1623)
- `autopilot.tableString(s)` - Parse comma-separated string (~26-33)
- `autopilot.displayCurrentRoute()` - Display current route (~43-55)
- `autopilot.displayCurrentManifest()` - Display current manifest (~57-65)

### Cargo Functions
- `autopilot.alias.profit()` - Display profit report (~76-100)
- `autopilot.startCargo()` - Start cargo automation
- `autopilot.stopCargo()` - Stop cargo automation

## Coding Style

- Use `cecho()` for colored console output
- Use `send()` to send MUD commands
- Use `debugc()` for debug messages
- Follow Lua naming: `functionName()`, `variableName`
- Use descriptive variable names
- Comment complex logic
- Keep functions focused and single-purpose

## Final Notes

This is a mature, feature-rich plugin with ~2750+ lines in the main script. Most functionality is concentrated in [autopilot.script.lua](src/scripts/autopilot.script.lua). The GUI uses sophisticated patterns like view stacks, working copies, and dual save logic. Be extremely careful when modifying core systems like `refreshGUI()`, `cleanupFormUI()`, and manifest editor functions.

**When in doubt:**
1. Read the existing code carefully
2. Test changes incrementally
3. Verify persistence with `display(autopilot.manifests)`
4. Check trigger status with GUI or `getTriggerInfo()`
5. Use `debugc()` for troubleshooting

The user has invested significant effort in debugging and refining the GUI patterns. Preserve the established patterns and avoid breaking working functionality.
