if not autopilot and io.exists(getMudletHomeDir().."/AutoPilot.lua") then
  autopilot = {}
  table.load(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  cecho("\n[<cyan>AutoPilot<reset>] Loaded save file.<reset>\n")
end
autopilot = autopilot or {}
autopilot.alias = {}
autopilot.trigger = {}
autopilot.ships = autopilot.ships or {}
autopilot.ship = autopilot.ship or {}
autopilot.routes = autopilot.routes or {}
autopilot.manifests = autopilot.manifests or {}
autopilot.currentRoute = autopilot.currentRoute or nil
autopilot.currentManifest = autopilot.currentManifest or nil
autopilot.runningCargo = autopilot.runningCargo or false
autopilot.useContraband = autopilot.useContraband or false
autopilot.preferredPads = autopilot.preferredPads or {}
autopilot.cargoPaused = autopilot.cargoPaused or false
autopilot.pausedState = autopilot.pausedState or {}

-- Configuration
autopilot.config = autopilot.config or {
  -- Version settings
  github_repo = "Xavious/AutoPilot",
  update_check_done = false
}

function autopilot.tableString(s)
  local t = {}
  for item in string.gmatch(s, '([^,]+)') do
    local trimmed = item:match("^%s*(.-)%s*$")
    table.insert(t, trimmed)
  end
  return t
end

-- Helper function to get preferred landing pad for a planet
function autopilot.getPreferredPad(planetName)
  if not planetName or not autopilot.preferredPads then
    return nil
  end
  return autopilot.preferredPads[planetName:lower()]
end

-- Helper function to display current route
function autopilot.displayCurrentRoute()
  if not autopilot.currentRoute or not autopilot.currentRoute.planets then
    cecho("[<cyan>AutoPilot<reset>] <red>No current route.<reset>\n")
    return
  end

  local routeName = autopilot.currentRoute.name or "Unsaved"
  cecho("-----------------[ <cyan>Current Route<reset> ]----------------\n")
  cecho("<green>Name:<reset> <yellow>"..routeName.."<reset>\n")
  cecho("<green>Planets:<reset> <cyan>"..table.concat(autopilot.currentRoute.planets, "<reset> → <cyan>").."<reset>\n")
  cecho("----------------------------------------------\n")
end

-- Helper function to display current manifest
function autopilot.displayCurrentManifest()
  if not autopilot.currentManifest or not autopilot.currentManifest.deliveries or #autopilot.currentManifest.deliveries == 0 then
    cecho("[<cyan>AutoPilot<reset>] <red>No current manifest.<reset>\n")
    return
  end

  autopilot.alias.viewManifest()
end

function autopilot.openShip()
  debugc("autopilot.openShip()")
  local openString = "open \""..autopilot.ship.name.."\""
  if autopilot.ship.hatchcode then
    openString = openString.." "..autopilot.ship.hatchcode
  end
  send(openString)
end

function autopilot.alias.profit()
  local now = getEpoch()
  local elapsed = now - autopilot.startTime
  
  -- Convert start time to a formatted local string
  local startTimeStr = os.date("%c", autopilot.startTime)
  
  -- Calculate elapsed hours and minutes
  local hours = math.floor(elapsed / 3600)
  local minutes = math.floor((elapsed % 3600) / 60)
  
  autopilot.profit = autopilot.revenue - autopilot.expense - autopilot.fuelCost
  local perHour = (autopilot.profit / elapsed) * 3600
  
  cecho("<white>---------------------------------------------\n")
  cecho("<yellow>Cargo Session Financial Report\n")
  cecho("<white>---------------------------------------------\n")
  cecho("<cyan>Time Started    : <reset>" .. startTimeStr .. "\n")
  cecho("<cyan>Elapsed Time    : <reset>" .. hours .. "h " .. minutes .. "m\n")
  cecho("<cyan>Expense         : <reset>" .. autopilot.expense .. "\n")
  cecho("<cyan>Revenue         : <reset>" .. autopilot.revenue .. "\n")
  cecho("<cyan>Fuel Cost       : <reset>" .. autopilot.fuelCost .. "\n")
  cecho("<cyan>Profit          : <reset>" .. autopilot.profit .. "\n")
  cecho("<cyan>Credits/Hour    : <reset>" .. string.format("%.2f", perHour) .. "\n")
  cecho("<white>---------------------------------------------<reset>\n")
end


function autopilot.alias.helpGeneral()
  debugc("autopilot.alias.helpGeneral()")
  cecho("<cyan>GENERAL FLIGHT COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap status<reset>\n")
  cecho("   Displays current ship attributes, waypoints, and cargo route information.\n\n")
  cecho("<yellow>ap fly <planet/planets><reset>\n")
  cecho("   Initiates flight to the target destination. Use commas to separate multiple planets.\n\n")
  cecho("<yellow>ap on<reset>\n")
  cecho("   Enables autopilot triggers (flight and cargo mode).\n\n")
  cecho("<yellow>ap off<reset>\n")
  cecho("   Disables autopilot triggers.\n\n")
  cecho("<yellow>ap clear<reset>\n")
  cecho("   Clears all autopilot attributes (ship, route, waypoints, destination).\n\n")
  cecho("<gray>Use<reset> <cyan>ap help general<reset> <gray>to see just this section.\n\n")
end

function autopilot.alias.helpPad()
  debugc("autopilot.alias.helpPad()")
  cecho("<cyan>LANDING PAD PREFERENCES<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap pad set <planet> \"<pad>\"<reset>\n")
  cecho("   Sets a preferred landing pad for a planet (pad in quotes).\n\n")
  cecho("<yellow>ap pad clear <planet><reset>\n")
  cecho("   Clears the preferred landing pad for a planet.\n\n")
  cecho("<yellow>ap pad list<reset>\n")
  cecho("   Lists all configured preferred landing pads.\n\n")
  cecho("<gray>Use<reset> <cyan>ap help pad<reset> <gray>to see just this section.\n\n")
end

function autopilot.alias.helpShip()
  debugc("autopilot.alias.helpShip()")
  cecho("<cyan>SHIP ATTRIBUTE COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap ship set <name><reset>\n")
  cecho("   Sets your ship's name (used for open/launch commands).\n\n")
  cecho("<yellow>ap enter set <commands><reset>\n")
  cecho("   Configures the (comma separated) commands to execute upon entering.\n\n")
  cecho("<yellow>ap exit set <commands><reset>\n")
  cecho("   Configures the (comma separated) commands to execute upon landing.\n\n")
  cecho("<yellow>ap hatch set <code><reset>\n")
  cecho("   Sets the hatch code for your ship.\n\n")
  cecho("<yellow>ap capacity set <amount><reset>\n")
  cecho("   Sets your ship's cargo capacity for cargo hauling.\n\n")
  cecho("<gray>Use<reset> <cyan>ap help ship<reset> <gray>to see just this section.\n\n")
end

function autopilot.alias.helpShipManage()
  debugc("autopilot.alias.helpShipManage()")
  cecho("<cyan>SHIP MANAGEMENT COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap ship save<reset>\n")
  cecho("   Saves the current ship to your ship list.\n\n")
  cecho("<yellow>ap ship load <#><reset>\n")
  cecho("   Loads a ship from your saved list by its ID.\n\n")
  cecho("<yellow>ap ship delete <#><reset>\n")
  cecho("   Deletes a ship from your ship list by its ID.\n\n")
  cecho("<gray>Use<reset> <cyan>ap help shipmanage<reset> <gray>to see just this section.\n\n")
end

function autopilot.alias.helpRoute()
  debugc("autopilot.alias.helpRoute()")
  cecho("<cyan>ROUTE COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap route add <planet1,planet2,planet3><reset>\n")
  cecho("   Creates a reusable route (waypoint path for fuel stops).\n\n")
  cecho("<yellow>ap route save [name]<reset>\n")
  cecho("   Saves the current route to your route list.\n\n")
  cecho("<yellow>ap route load <#><reset>\n")
  cecho("   Loads a saved route by its ID. Use with 'ap fly route'.\n\n")
  cecho("<yellow>ap route delete <#><reset>\n")
  cecho("   Deletes a route from your route list by its ID.\n\n")
  cecho("<yellow>ap fly route<reset>\n")
  cecho("   Fly using the currently loaded route.\n\n")
  cecho("<gray>Use<reset> <cyan>ap help route<reset> <gray>to see just this section.\n\n")
end

function autopilot.alias.helpManifest()
  debugc("autopilot.alias.helpManifest()")
  cecho("<cyan>CARGO / MANIFEST COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap delivery add <planet>:<resource> [route#]<reset>\n")
  cecho("   Adds a delivery to current manifest. Optional route# for multi-hop.\n\n")
  cecho("<yellow>ap manifest view<reset>\n")
  cecho("   Shows detailed view of current manifest with all deliveries.\n\n")
  cecho("<yellow>ap manifest clear<reset>\n")
  cecho("   Clears the current unsaved manifest.\n\n")
  cecho("<yellow>ap route clear<reset>\n")
  cecho("   Clears the current unsaved route.\n\n")
  cecho("<yellow>ap manifest save [name]<reset>\n")
  cecho("   Saves the current manifest to your manifest list.\n\n")
  cecho("<yellow>ap manifest load <#><reset>\n")
  cecho("   Loads a saved manifest by its ID (shows full details).\n\n")
  cecho("<yellow>ap manifest delete <#><reset>\n")
  cecho("   Deletes a manifest from your manifest list by its ID.\n\n")
  cecho("<yellow>ap cargo start<reset>\n")
  cecho("   Begins a cargo run (requires ship capacity and loaded manifest).\n\n")
  cecho("<yellow>ap cargo stop<reset>\n")
  cecho("   Stops your cargo run.\n\n")
  cecho("<yellow>ap cargo pause<reset>\n")
  cecho("   Pauses cargo buying/selling. Flight continues normally if mid-flight.\n")
  cecho("   Ship will still arrive at destination, land, and refuel automatically.\n")
  cecho("   Cargo remains in hold for manual handling or use resume.\n\n")
  cecho("<yellow>ap cargo resume<reset>\n")
  cecho("   Resumes paused cargo run. Assumes ship is empty at cargo planet.\n")
  cecho("   Buys next cargo and continues to next destination.\n\n")
  cecho("<yellow>ap cargo resume sell<reset>\n")
  cecho("   Resumes paused cargo run by selling current cargo first.\n")
  cecho("   Use this if cargo is still in hold. Buys next cargo and continues.\n\n")
  cecho("<yellow>ap profit<reset>\n")
  cecho("   Show cargo hauling financial report.\n\n")
  cecho("<yellow>ap contraband <on/off><reset>\n")
  cecho("   Toggle contraband mode (uses buycontraband/sellcontraband commands).\n")
  cecho("   <red>⚠ WARNING: Requires level 120 Smuggling skill. May have in-game consequences.<reset>\n\n")
  cecho("<gray>Use<reset> <cyan>ap help manifest<reset> <gray>to see just this section.\n\n")
end

function autopilot.alias.helpGUI()
  debugc("autopilot.alias.helpGUI()")
  cecho("<cyan>GUI COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap gui<reset>\n")
  cecho("   Show the visual interface\n\n")
  cecho("<yellow>ap show<reset>\n")
  cecho("   Show the visual interface\n\n")
  cecho("<yellow>ap hide<reset>\n")
  cecho("   Hide the visual interface\n\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<cyan>UPDATE COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap update<reset>\n")
  cecho("   Check for updates\n\n")
  cecho("<gray>Use<reset> <cyan>ap help gui<reset> <gray>to see just this section.\n\n")
end

function autopilot.alias.help()
  debugc("autopilot.alias.help()")
  
  local section = (matches.section and matches.section:lower() or ""):match("^%s*(.-)%s*$")
  
  -- If no section specified, show all help sections
  if section == "" then
    cecho("<white>------------------------------------------------------------\n")
    cecho("<cyan>                       AutoPilot Help<reset>\n")
    cecho("<white>------------------------------------------------------------\n\n")
    cecho("<cyan>To view help for a specific section, use:<reset>\n")
    cecho("<yellow>ap help <section><reset>\n\n")
    cecho("<cyan>Available sections:<reset>\n")
    cecho("  <yellow>general<reset>      - General flight commands\n")
    cecho("  <yellow>pad<reset>          - Landing pad preferences\n")
    cecho("  <yellow>ship<reset>         - Ship attribute commands\n")
    cecho("  <yellow>shipmanage<reset>   - Ship management commands\n")
    cecho("  <yellow>route<reset>        - Route commands\n")
    cecho("  <yellow>manifest<reset>     - Cargo/manifest commands\n")
    cecho("  <yellow>gui<reset>          - GUI commands\n\n")
    cecho("<white>------------------------------------------------------------<reset>\n")
    cecho("<cyan>EXAMPLES:<reset>\n")
    cecho("<yellow>ap help general<reset> - Show general flight commands\n")
    cecho("<yellow>ap help manifest<reset> - Show cargo management commands\n")
    cecho("<yellow>ap help<reset> - Show this help (you can also run just \"ap help\" with no section)\n\n")
    return
  end
  
  -- Handle specific sections
  if section == "general" then
    autopilot.alias.helpGeneral()
  elseif section == "pad" then
    autopilot.alias.helpPad()
  elseif section == "ship" then
    autopilot.alias.helpShip()
  elseif section == "shipmanage" then
    autopilot.alias.helpShipManage()
  elseif section == "route" then
    autopilot.alias.helpRoute()
  elseif section == "manifest" then
    autopilot.alias.helpManifest()
  elseif section == "gui" then
    autopilot.alias.helpGUI()
  else
    cecho("<red>Unknown help section: <yellow>"..section.."<reset>\n")
    cecho("<cyan>Available sections:<reset> general, pad, ship, shipmanage, route, manifest, gui\n")
    cecho("<yellow>ap help<reset> for more info\n")
  end
end

function autopilot.alias.status()
  debugc("autopilot.alias.status()")
  cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")

  -- Show autopilot status
  local flightEnabled = isActive("autopilot.flight", "trigger")

  cecho("<green>Flight AutoPilot:<reset> ")
  if flightEnabled > 0 then
    cecho("<green>ENABLED ✓<reset>\n")
  else
    cecho("<red>DISABLED ✗<reset>\n")
  end

  cecho("<green>Cargo Running:<reset> ")
  if autopilot.runningCargo then
    cecho("<green>ACTIVE ✓<reset>\n")
  else
    cecho("<yellow>inactive<reset>\n")
  end

  if autopilot.cargoPaused then
    cecho("<red>Cargo Paused:<reset> <yellow>YES (paused mid-run)<reset>\n")
  end
  cecho("----------------------------------------------\n")

  if next(autopilot.ship) == nil and autopilot.waypoints == nil then
    cecho("<red>No attributes set.\n")
    return
  end

  cecho("Ship\n")
  cecho("----------------------------------------------\n")
  if autopilot.ship then
    for key, value in pairs(autopilot.ship) do
      cecho("<green>"..key.."<reset>: ")
      if type(value) == "table" then
        local string = table.concat(value,",")
        cecho(string.."\n")
      else
        cecho(value.."\n")
      end
    end
  end

  cecho("<green>contraband:<reset> ")
  if autopilot.useContraband then
    cecho("<red>ENABLED ⚠<reset>\n")
  else
    cecho("<green>disabled<reset>\n")
  end
  
  if autopilot.destination then
    cecho("<green>destination:<reset> <cyan>".. autopilot.destination.planet.."<reset>")
    
    -- Show current leg information if running cargo
    if autopilot.runningCargo and autopilot.currentManifest and autopilot.deliveryIndex then
      local delivery = autopilot.currentManifest.deliveries[autopilot.deliveryIndex]
      if delivery then
        cecho("  <gray>(Leg: Buy <magenta>"..delivery.resource.."<reset> for <cyan>"..delivery.planet.."<reset><gray>)<reset>")
      end
    end
    cecho("\n")
  end

  if autopilot.waypoints and next(autopilot.waypoints) then
    cecho("<green>waypoints:<reset>\n")
    for i, waypoint in ipairs(autopilot.waypoints) do
      cecho("<white>"..i.."<reset> - <cyan>"..waypoint.."<reset>\n")
    end
  end
  cecho("----------------------------------------------\n")

  if autopilot.currentRoute and autopilot.currentRoute.planets then
    cecho("Current Route\n")
    cecho("----------------------------------------------\n")
    local routeName = autopilot.currentRoute.name or "Unnamed"
    cecho("<green>Name:<reset> <yellow>"..routeName.."<reset>\n")
    cecho("<green>Planets:<reset>\n")
    for i, planet in ipairs(autopilot.currentRoute.planets) do
      cecho("  <white>"..i.."<reset>. <cyan>"..planet.."<reset>\n")
    end
    cecho("----------------------------------------------\n")
  end

  if autopilot.currentManifest and autopilot.currentManifest.deliveries then
    cecho("Current Manifest\n")
    cecho("----------------------------------------------\n")
    local manifestName = autopilot.currentManifest.name or "Unnamed"
    cecho("<green>Name:<reset> <yellow>"..manifestName.."<reset>")
    if autopilot.runningCargo then
      cecho("  <green>[ACTIVE]<reset>")
    end
    cecho("\n<green>Deliveries:<reset>\n")
    for i, delivery in ipairs(autopilot.currentManifest.deliveries) do
      local routeText = delivery.route and " <gray>(route #<white>"..delivery.route.."<gray>)<reset>" or " <gray>(direct)<reset>"
      local contrabandText = delivery.contraband and " <red>C<reset>" or ""
      local current = ""
      if autopilot.runningCargo and i == autopilot.deliveryIndex then
        current = " <green>◆ CURRENT<reset>"
      end
      cecho("<white>"..i.."<reset>. <cyan>"..delivery.planet.."<reset>:<magenta>"..delivery.resource.."<reset>"..contrabandText..routeText..current.."\n")
    end
    cecho("----------------------------------------------\n")
  end
end

function autopilot.alias.fly()
  debugc("autopilot.alias.fly()")
  if matches.planets == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap fly <planet/planets><reset>\n")
    cecho("<red>ap fly route<reset>\n")
    cecho("----------------Usage Examples----------------\n")
    cecho("<yellow>ap fly planet\n")
    cecho("<yellow>ap fly planet1,planet2,planet3\n")
    cecho("<yellow>ap fly route  (uses loaded route)\n")
    cecho("----------------------------------------------\n\n")
    return
  end

  -- Check if user wants to fly using a loaded route
  if matches.planets:lower() == "route" then
    if not autopilot.currentRoute or not autopilot.currentRoute.planets then
      cecho("[<cyan>AutoPilot<reset>] <red>No route loaded. Use 'ap load route #' first.<reset>\n")
      return
    end
    autopilot.waypoints = table.deepcopy(autopilot.currentRoute.planets)
  else
    autopilot.waypoints = autopilot.tableString(matches.planets)
  end

  autopilot.destination = {}
  autopilot.destination.planet = table.remove(autopilot.waypoints, 1)

  cecho("[<cyan>AutoPilot<reset>] <yellow>Engaged<reset> | <green>Destination:<reset> <cyan>"..autopilot.destination.planet.."<reset>\n")
  enableTrigger("autopilot.flight")
  autopilot.openShip()
end

-- Fly a route by index (used by GUI)
function autopilot.flyRoute(routeIndex)
  if not autopilot.routes or not autopilot.routes[routeIndex] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid route index.<reset>\n")
    return
  end

  local route = autopilot.routes[routeIndex]
  if not route.planets or #route.planets == 0 then
    cecho("[<cyan>AutoPilot<reset>] <red>Route has no planets.<reset>\n")
    return
  end

  -- Load the route as current route
  autopilot.currentRoute = table.deepcopy(route)
  local routeName = route.name or ("Route #" .. routeIndex)
  cecho("[<cyan>AutoPilot<reset>] Route <cyan>" .. routeName .. "<reset> loaded.\n")

  -- Set up waypoints from route
  autopilot.waypoints = table.deepcopy(route.planets)
  autopilot.destination = {}
  autopilot.destination.planet = table.remove(autopilot.waypoints, 1)

  cecho("[<cyan>AutoPilot<reset>] <yellow>Flying route:<reset> <cyan>" .. routeName .. "<reset>\n")
  cecho("[<cyan>AutoPilot<reset>] <yellow>Engaged<reset> | <green>Destination:<reset> <cyan>"..autopilot.destination.planet.."<reset>\n")

  enableTrigger("autopilot.flight")
  autopilot.openShip()
end

function autopilot.alias.setShip()
debugc("autopilot.alias.setShip()")
  if matches.ship == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set ship <name><reset>\n")
    return
  end
  autopilot.ship.name = matches.ship
  autopilot.alias.status()
end

function autopilot.alias.setEnter()
  debugc("autopilot.alias.setEnter()")
  if matches.commands == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set enter <commands><reset>\n")
    return
  end 
  autopilot.ship.enter = autopilot.tableString(matches.commands)
  autopilot.alias.status()
end

function autopilot.alias.setExit()
  debugc("autopilot.alias.setExit()")
  if matches.commands == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set exit <commands><reset>\n")
    return
  end
  autopilot.ship.exit = autopilot.tableString(matches.commands)
  autopilot.alias.status()
end

function autopilot.alias.setHatch()
  debugc("autopilot.alias.setHatch()")
  if matches.code == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set hatch <code><reset>\n")
    return
  end
  autopilot.ship.hatchcode = matches.code
  autopilot.alias.status()
end

function autopilot.alias.setCapacity()
  debugc("autopilot.alias.setCapacity()")
  if matches.capacity == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set capacity <amount><reset>\n")
    return
  end
  
  autopilot.ship.capacity = matches.capacity
  autopilot.alias.status()
end

function autopilot.alias.saveShip()
  debugc("autopilot.alias.saveShip()")
  local shipCopy = table.deepcopy(autopilot.ship)
  table.insert(autopilot.ships, shipCopy)
  cecho("[<cyan>AutoPilot<reset>] Ship added: <yellow>"..autopilot.ship.name.."<reset>\n")
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
end

function autopilot.alias.setPad()
  debugc("autopilot.alias.setPad()")
  if not matches.planet or matches.planet == "" or not matches.pad or matches.pad == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap set pad <planet> \"<pad>\"<reset>\n")
    cecho("----------------Usage Examples----------------\n")
    cecho("<yellow>ap set pad alderaan \"Aldera\"\n")
    cecho("<yellow>ap set pad nar shaddaa \"Red Light Sector Dock 5\"\n")
    return
  end

  local planetKey = matches.planet:lower()
  autopilot.preferredPads[planetKey] = matches.pad
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  cecho("[<cyan>AutoPilot<reset>] Preferred pad set for <cyan>"..matches.planet.."<reset>: <yellow>"..matches.pad.."<reset>\n")
end

function autopilot.alias.clearPad(planetName)
  debugc("autopilot.alias.clearPad()")
  local planet = planetName or (matches and matches.planet)
  if not planet or planet == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap clear pad <planet><reset>\n")
    cecho("----------------Usage Example----------------\n")
    cecho("<yellow>ap clear pad alderaan\n")
    return
  end

  local planetKey = planet:lower()
  if autopilot.preferredPads[planetKey] then
    autopilot.preferredPads[planetKey] = nil
    table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
    cecho("[<cyan>AutoPilot<reset>] Preferred pad cleared for <cyan>"..planet.."<reset>\n")
    if autopilot.refreshGUI then autopilot.refreshGUI() end
  else
    cecho("[<cyan>AutoPilot<reset>] <red>No preferred pad set for <cyan>"..planet.."<reset>\n")
  end
end

function autopilot.alias.listPads()
  debugc("autopilot.alias.listPads()")
  if not autopilot.preferredPads or not next(autopilot.preferredPads) then
    cecho("[<cyan>AutoPilot<reset>] <red>No preferred pads configured.<reset>\n")
    cecho("<gray>Use<reset> <cyan>ap set pad <planet> <pad><reset> <gray>to set a preferred landing pad.\n")
    return
  end

  cecho("-----------------[ <cyan>Preferred Landing Pads<reset> ]----------------\n")
  for planet, pad in pairs(autopilot.preferredPads) do
    cecho("<cyan>"..planet.."<reset>: <yellow>"..pad.."<reset>\n")
  end
  cecho("----------------------------------------------\n")
end

function autopilot.alias.saveRoute()
  debugc("autopilot.alias.saveRoute()")
  if not autopilot.currentRoute or not autopilot.currentRoute.planets then
    cecho("[<cyan>AutoPilot<reset>] <red>No route to save. Use 'ap add route' first.<reset>\n")
    return
  end

  autopilot.routes = autopilot.routes or {}
  if matches.name and matches.name ~= "" then
    autopilot.currentRoute.name = matches.name
  end
  local routeCopy = table.deepcopy(autopilot.currentRoute)
  table.insert(autopilot.routes, routeCopy)
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  local routeName = autopilot.currentRoute.name or "#"..#autopilot.routes
  cecho("[<cyan>AutoPilot<reset>] Route saved: <yellow>"..routeName.."<reset>\n\n")
  autopilot.displayCurrentRoute()
end

function autopilot.alias.saveManifest()
  debugc("autopilot.alias.saveManifest()")
  if not autopilot.currentManifest or not autopilot.currentManifest.deliveries then
    cecho("[<cyan>AutoPilot<reset>] <red>No manifest to save. Use 'ap add delivery' first.<reset>\n")
    return
  end

  autopilot.manifests = autopilot.manifests or {}
  if matches.name and matches.name ~= "" then
    autopilot.currentManifest.name = matches.name
  end
  local manifestCopy = table.deepcopy(autopilot.currentManifest)
  table.insert(autopilot.manifests, manifestCopy)
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  local manifestName = autopilot.currentManifest.name or "#"..#autopilot.manifests
  cecho("[<cyan>AutoPilot<reset>] Manifest saved: <yellow>"..manifestName.."<reset>\n\n")
  autopilot.displayCurrentManifest()
end

function autopilot.alias.loadShip(idx)
  debugc("autopilot.alias.loadShip()")
  local index = idx or tonumber(matches and matches.index)
  if not index then
    cecho("+------------------------------------------------------------+\n")
    cecho("| <white>ID<reset> | <white>Ship<reset>\n")
    cecho("+------------------------------------------------------------+\n")
    for i, ship in ipairs(autopilot.ships) do
      cecho(string.format("| <white>%2d<reset> | %s\n", i, ship.name))
    end
    cecho("+------------------------------------------------------------+\n")
    cecho("<gray>Use<reset> <cyan>ap load ship <#><reset> <gray>to set ship.\n")
    return
  end
  
  if not autopilot.ships[index] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid ID — no such ship in memory.<reset>\n")
    return
  end
  
  autopilot.ship = table.deepcopy(autopilot.ships[index])
  cecho("[<cyan>AutoPilot<reset>] Ship loaded: <yellow>"..autopilot.ship.name.."<reset>\n")
end

function autopilot.alias.loadRoute(idx)
  debugc("autopilot.alias.loadRoute()")
  local index = idx or tonumber(matches and matches.index)
  if not index then
    cecho("+------------------------------------------------------------+\n")
    cecho("| <white>ID<reset> | <white>Route<reset>\n")
    cecho("+------------------------------------------------------------+\n")
    for i, route in ipairs(autopilot.routes) do
      local routeName = route.name or "Unnamed"
      local routeDisplay = table.concat(route.planets, " → ")
      cecho(string.format("| <white>%2d<reset> | <cyan>%s<reset>: %s\n", i, routeName, routeDisplay))
    end
    cecho("+------------------------------------------------------------+\n")
    cecho("<gray>Use<reset> <cyan>ap load route <#><reset> <gray>to select a route.\n")
    return
  end

  if not autopilot.routes[index] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid ID — no such route in memory.<reset>\n")
    return
  end

  autopilot.currentRoute = table.deepcopy(autopilot.routes[index])
  local routeName = autopilot.currentRoute.name or "#"..index
  cecho("[<cyan>AutoPilot<reset>] Route loaded: <yellow>"..routeName.."<reset>\n\n")
  autopilot.displayCurrentRoute()
end

function autopilot.alias.loadManifest(idx)
  debugc("autopilot.alias.loadManifest()")
  local index = idx or tonumber(matches and matches.index)
  if not index then
    cecho("+------------------------------------------------------------+\n")
    cecho("| <white>ID<reset> | <white>Manifest<reset>\n")
    cecho("+------------------------------------------------------------+\n")
    for i, manifest in ipairs(autopilot.manifests) do
      local manifestName = manifest.name or "Unnamed"
      local deliveryCount = #manifest.deliveries
      cecho(string.format("| <white>%2d<reset> | <cyan>%s<reset> (%d deliveries)\n", i, manifestName, deliveryCount))
    end
    cecho("+------------------------------------------------------------+\n")
    cecho("<gray>Use<reset> <cyan>ap load manifest <#><reset> <gray>to select a manifest.\n")
    return
  end

  if not autopilot.manifests[index] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid ID — no such manifest in memory.<reset>\n")
    return
  end

  autopilot.currentManifest = table.deepcopy(autopilot.manifests[index])
  local manifestName = autopilot.currentManifest.name or "#"..index
  cecho("[<cyan>AutoPilot<reset>] Manifest loaded: <yellow>"..manifestName.."<reset>\n\n")

  -- Show full manifest details
  autopilot.alias.viewManifest()
end

function autopilot.alias.deleteShip()
  debugc("autopilot.alias.deleteShip()")
  local index = tonumber(matches.index)
  if not index then
    cecho("+------------------------------------------------------------+\n")
    cecho("| <white>ID<reset> | <white>Ship<reset>\n")
    cecho("+------------------------------------------------------------+\n")
    
    for i, ship in ipairs(autopilot.ships) do
      cecho(string.format("| <white>%2d<reset> | %s\n", i, ship.name))
    end
    cecho("+------------------------------------------------------------+\n")
    cecho("<gray>Use<reset> <cyan>ap delete ship <#><reset> <gray>to delete ship.\n")
    return
  end
  
  if not autopilot.ships[index] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid ID — no such ship in memory.<reset>\n")
    return
  end

  table.remove(autopilot.ships, index)
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  cecho("[<cyan>AutoPilot<reset>] <red>Ship deleted.<reset>\n")
end

function autopilot.alias.deleteRoute()
  debugc("autopilot.alias.deleteRoute()")
  local index = tonumber(matches.index)
  if not index then
    cecho("+------------------------------------------------------------+\n")
    cecho("| <white>ID<reset> | <white>Route<reset>\n")
    cecho("+------------------------------------------------------------+\n")
    for i, route in ipairs(autopilot.routes) do
      local routeName = route.name or "Unnamed"
      local planets = table.concat(route.planets, " → ")
      cecho(string.format("| <white>%2d<reset> | <cyan>%s<reset>: %s\n", i, routeName, planets))
    end
    cecho("+------------------------------------------------------------+\n")
    cecho("<gray>Use<reset> <cyan>ap delete route <#><reset> <gray>to delete a route.\n")
    return
  end

  if not autopilot.routes[index] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid ID — no such route in memory.<reset>\n")
    return
  end

  table.remove(autopilot.routes, index)
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  cecho("[<cyan>AutoPilot<reset>] <red>Route deleted.<reset>\n")
end

function autopilot.alias.deleteManifest()
  debugc("autopilot.alias.deleteManifest()")
  local index = tonumber(matches.index)
  if not index then
    cecho("+------------------------------------------------------------+\n")
    cecho("| <white>ID<reset> | <white>Manifest<reset>\n")
    cecho("+------------------------------------------------------------+\n")
    for i, manifest in ipairs(autopilot.manifests) do
      local manifestName = manifest.name or "Unnamed"
      local deliveryCount = #manifest.deliveries
      cecho(string.format("| <white>%2d<reset> | <cyan>%s<reset> (%d deliveries)\n", i, manifestName, deliveryCount))
    end
    cecho("+------------------------------------------------------------+\n")
    cecho("<gray>Use<reset> <cyan>ap delete manifest <#><reset> <gray>to delete a manifest.\n")
    return
  end

  if not autopilot.manifests[index] then
    cecho("[<cyan>AutoPilot<reset>] <red>Invalid ID — no such manifest in memory.<reset>\n")
    return
  end

  table.remove(autopilot.manifests, index)
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  cecho("[<cyan>AutoPilot<reset>] <red>Manifest deleted.<reset>\n")
end

function autopilot.alias.clear()
  debugc("autopilot.alias.clear()")
  autopilot.ship = {}
  autopilot.waypoints = nil
  autopilot.destination = nil
  autopilot.currentRoute = nil
  autopilot.currentManifest = nil
  cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
  cecho("Cleared all attributes.\n")
end

function autopilot.alias.clearManifest()
  debugc("autopilot.alias.clearManifest()")
  autopilot.currentManifest = nil
  cecho("[<cyan>AutoPilot<reset>] <green>Current manifest cleared.<reset>\n")
end

function autopilot.alias.clearRoute()
  debugc("autopilot.alias.clearRoute()")
  autopilot.currentRoute = nil
  cecho("[<cyan>AutoPilot<reset>] <green>Current route cleared.<reset>\n")
end

function autopilot.alias.on()
  debugc("autopilot.alias.on()")
  cecho("[<cyan>AutoPilot<reset>] <green>Enabled<reset>\n")
  enableTrigger("autopilot.flight")
  enableTrigger("autopilot.cargo")
end

function autopilot.alias.off()
  debugc("autopilot.alias.off()")
  cecho("[<cyan>AutoPilot<reset>] <red>Disabled<reset>\n")
  disableTrigger("autopilot.flight")
  disableTrigger("autopilot.cargo")
end

function autopilot.alias.addRoute()
  debugc("autopilot.alias.addRoute()")
  if matches.planets == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap add route <planet1,planet2,planet3><reset>\n")
    cecho("----------------Usage Example----------------\n")
    cecho("<yellow>ap add route coruscant,corellia,tatooine\n")
    return
  end

  -- Parse simple comma-separated planet list and force lowercase
  local planets = autopilot.tableString(matches.planets)
  for i, planet in ipairs(planets) do
    planets[i] = planet:lower()
  end
  autopilot.currentRoute = {planets = planets}

  -- Display the route
  autopilot.displayCurrentRoute()
end

function autopilot.alias.viewManifest()
  debugc("autopilot.alias.viewManifest()")
  if not autopilot.currentManifest or not autopilot.currentManifest.deliveries or #autopilot.currentManifest.deliveries == 0 then
    cecho("[<cyan>AutoPilot<reset>] <red>No current manifest. Use 'ap delivery add' to create one.<reset>\n")
    return
  end

  cecho("-----------------[ <cyan>Current Manifest<reset> ]----------------\n")
  local manifestName = autopilot.currentManifest.name or "Unsaved"
  cecho("<green>Name:<reset> "..manifestName.."\n")
  cecho("<green>Deliveries:<reset>\n")
  cecho("----------------------------------------------\n")
  for i, delivery in ipairs(autopilot.currentManifest.deliveries) do
    local routeText = ""
    if delivery.route then
      local route = autopilot.routes[delivery.route]
      if route then
        local routeName = route.name or "#"..delivery.route
        local planets = table.concat(route.planets, " → ")
        routeText = "\n   <gray>Route:<reset> "..routeName.." ("..planets..")"
      else
        routeText = "\n   <red>Route #"..delivery.route.." not found!<reset>"
      end
    else
      routeText = "\n   <gray>Route:<reset> Direct flight"
    end
    local contrabandText = delivery.contraband and "\n   <red>Contraband:<reset> <red>ENABLED ⚠<reset>" or ""
    cecho(i..". <cyan>"..delivery.planet.."<reset> ← <magenta>"..delivery.resource.."<reset>"..routeText..contrabandText.."\n")
  end
  cecho("----------------------------------------------\n")
end

function autopilot.alias.addDelivery()
  debugc("autopilot.alias.addDelivery()")
  if matches.planet == "" or matches.resource == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap delivery add <planet>:<resource> [route#] [contraband]<reset>\n")
    cecho("----------------Usage Examples----------------\n")
    cecho("<yellow>ap delivery add coruscant:food\n")
    cecho("<yellow>ap delivery add tatooine:spice 1\n")
    cecho("<yellow>ap delivery add kessel:glitterstim 2 contraband\n")
    return
  end

  local routeIndex = matches.routeIndex and tonumber(matches.routeIndex) or nil
  local useContraband = matches.contraband and matches.contraband:lower() == "contraband" or false
  
  local delivery = {
    planet = matches.planet:lower(),
    resource = matches.resource:lower(),
    route = routeIndex,
    contraband = useContraband
  }

  autopilot.currentManifest = autopilot.currentManifest or {deliveries = {}}
  table.insert(autopilot.currentManifest.deliveries, delivery)

  local routeText = routeIndex and " (via route #"..routeIndex..")" or " (direct)"
  local contrabandText = useContraband and " <red>[CONTRABAND]<reset>" or ""
  cecho("[<cyan>AutoPilot<reset>] Delivery added: <cyan>"..delivery.planet.."<reset> ← <magenta>"..delivery.resource.."<reset>"..routeText..contrabandText.."\n\n")

  -- Show current manifest state
  autopilot.alias.viewManifest()
end

function autopilot.alias.startCargo()
  debugc("autopilot.alias.startCargo()")
  if not autopilot.ship.capacity then
    cecho("[<cyan>AutoPilot<reset>] <red>No cargo capacity set for this ship.\n")
    return
  end

  if not autopilot.currentManifest or not autopilot.currentManifest.deliveries then
    cecho("[<cyan>AutoPilot<reset>] <red>No manifest loaded. Use 'ap manifest load #' or create one with 'ap delivery add'.\n")
    return
  end

  if #autopilot.currentManifest.deliveries < 2 then
    cecho("[<cyan>AutoPilot<reset>] <red>Need at least 2 deliveries in manifest.\n")
    return
  end

  autopilot.runningCargo = true
  autopilot.alias.on()
  autopilot.deliveryIndex = 1
  autopilot.expense = 0
  autopilot.revenue = 0
  autopilot.fuelCost = 0
  autopilot.startTime = getEpoch()

  -- Buy cargo for first delivery
  local firstDelivery = autopilot.currentManifest.deliveries[1]
  -- Use per-delivery contraband flag if set, otherwise fall back to global setting
  local useContraband = firstDelivery.contraband or autopilot.useContraband
  local buyCommand = useContraband and "buycontraband" or "buycargo"
  send(buyCommand.." "..autopilot.ship.name.." '"..firstDelivery.resource.. "' "..autopilot.ship.capacity)
  cecho("[<cyan>AutoPilot<reset>] <yellow>Cargo run started<reset> | Buying <magenta>"..firstDelivery.resource.."<reset> for delivery to <cyan>"..firstDelivery.planet.."<reset>\n")
end

function autopilot.alias.stopCargo()
  debugc("autopilot.alias.stopCargo()")
  autopilot.runningCargo = false
  autopilot.alias.off()
end

function autopilot.alias.pauseCargo()
  debugc("autopilot.alias.pauseCargo()")
  if not autopilot.runningCargo then
    cecho("[<cyan>AutoPilot<reset>] <red>No cargo run in progress to pause.<reset>\n")
    return
  end

  -- Set pause flag - triggers will check this and halt progression
  autopilot.cargoPaused = true
  
  cecho("[<cyan>AutoPilot<reset>] <yellow>Cargo run paused.<reset>\n")
  cecho("[<cyan>AutoPilot<reset>] <gray>Current delivery:<reset> <cyan>"..autopilot.currentManifest.deliveries[autopilot.deliveryIndex].planet.."<reset> ← <magenta>"..autopilot.currentManifest.deliveries[autopilot.deliveryIndex].resource.."<reset>\n")
  cecho("[<cyan>AutoPilot<reset>] <gray>Automation will halt at next trigger checkpoint. Ship will remain landed/paused.<reset>\n\n")
  cecho("[<cyan>AutoPilot<reset>] <cyan>Resume options:<reset>\n")
  cecho("[<cyan>AutoPilot<reset>]   <green>ap cargo resume<reset> - Continue with next cargo leg (assumes ship empty)\n")
  cecho("[<cyan>AutoPilot<reset>]   <green>ap cargo resume sell<reset> - Sell current cargo first, then continue\n\n")
  
  -- Save current state for resume
  autopilot.pausedState = {
    runningCargo = autopilot.runningCargo,
    deliveryIndex = autopilot.deliveryIndex,
    currentManifest = autopilot.currentManifest,
    expense = autopilot.expense,
    revenue = autopilot.revenue,
    fuelCost = autopilot.fuelCost,
    startTime = autopilot.startTime,
    useContraband = autopilot.useContraband
  }
  
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
end

function autopilot.alias.resumeCargo()
  debugc("autopilot.alias.resumeCargo()")
  if not autopilot.cargoPaused or not autopilot.pausedState.runningCargo then
    cecho("[<cyan>AutoPilot<reset>] <red>No paused cargo run to resume.<reset>\n")
    return
  end

  -- Restore saved state
  autopilot.runningCargo = autopilot.pausedState.runningCargo
  autopilot.deliveryIndex = autopilot.pausedState.deliveryIndex
  autopilot.currentManifest = autopilot.pausedState.currentManifest
  autopilot.expense = autopilot.pausedState.expense
  autopilot.revenue = autopilot.pausedState.revenue
  autopilot.fuelCost = autopilot.pausedState.fuelCost
  autopilot.startTime = autopilot.pausedState.startTime
  autopilot.useContraband = autopilot.pausedState.useContraband

  -- Clear pause flag
  autopilot.cargoPaused = false
  
  -- Check if user wants to sell current cargo first
  local shouldSell = matches.sell and matches.sell:lower():match("sell") ~= nil
  
  if shouldSell then
    -- User wants to sell the last cargo
    local delivery = autopilot.currentManifest.deliveries[autopilot.deliveryIndex]
    local useContraband = delivery.contraband or autopilot.useContraband
    local sellCommand = useContraband and "sellcontraband" or "sellcargo"
    
    cecho("[<cyan>AutoPilot<reset>] <yellow>Cargo run resumed (selling first).<reset>\n")
    cecho("[<cyan>AutoPilot<reset>] Selling <magenta>"..delivery.resource.."<reset> for <cyan>"..delivery.planet.."<reset>\n")
    
    send(sellCommand.." "..autopilot.ship.name.." '"..delivery.resource.."' "..autopilot.ship.capacity)
  else
    -- Assume ship is empty and at the correct cargo pad - buy next cargo
    local delivery = autopilot.currentManifest.deliveries[autopilot.deliveryIndex]
    local useContraband = delivery.contraband or autopilot.useContraband
    local buyCommand = useContraband and "buycontraband" or "buycargo"
    
    cecho("[<cyan>AutoPilot<reset>] <yellow>Cargo run resumed.<reset>\n")
    cecho("[<cyan>AutoPilot<reset>] Buying <magenta>"..delivery.resource.."<reset> for delivery to <cyan>"..delivery.planet.."<reset>\n")
    
    send(buyCommand.." "..autopilot.ship.name.." '"..delivery.resource.."' "..autopilot.ship.capacity)
  end
  
  -- Re-enable autopilot
  autopilot.alias.on()
  
  -- Save state to file
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
end

function autopilot.alias.contraband()
  debugc("autopilot.alias.contraband()")
  if matches.state == "on" then
    autopilot.useContraband = true
    cecho("[<cyan>AutoPilot<reset>] <red>⚠ WARNING: Contraband mode ENABLED ⚠<reset>\n")
    cecho("[<cyan>AutoPilot<reset>] <yellow>Using contraband commands may result in in-game consequences.<reset>\n")
    table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  elseif matches.state == "off" then
    autopilot.useContraband = false
    cecho("[<cyan>AutoPilot<reset>] <green>Contraband mode disabled - using standard cargo commands.<reset>\n")
    table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  else
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap contraband <on/off><reset>\n")
    cecho("----------------------------------------------\n")
    cecho("Current status: ")
    if autopilot.useContraband then
      cecho("<red>ENABLED<reset>\n")
    else
      cecho("<green>DISABLED<reset>\n")
    end
    cecho("----------------------------------------------\n")
  end
end

function autopilot.trigger.openHatch()
  debugc("autopilot.trigger.openHatch()")
  
  -- If cargo run is paused, don't launch
  if autopilot.cargoPaused then
    cecho("\n[<cyan>AutoPilot<reset>] <yellow>Cargo run is paused.<reset> Launch halted. Use <green>ap cargo resume<reset> to continue.\n")
    return
  end
  
  send("refuel "..autopilot.ship.name)
  send("enter "..autopilot.ship.name)
  send("close")
  if autopilot.ship.enter then
    for i = 1, #autopilot.ship.enter do
      send(autopilot.ship.enter[i])
    end
  end
  send("autopilot off")
  send("pilot")
  send("launch")

end

function autopilot.trigger.launch()
  debugc("autopilot.trigger.launch()")
  
  -- If cargo run is paused, don't continue
  if autopilot.cargoPaused then
    cecho("\n[<cyan>AutoPilot<reset>] <yellow>Cargo run is paused.<reset> Flight halted. Use <green>ap cargo resume<reset> to continue.\n")
    return
  end
  
  enableTrigger("autopilot.trigger.showplanet")
  send("showplanet "..autopilot.destination.planet)
end

function autopilot.trigger.showplanet()
  debugc("autopilot.trigger.showplanet()")  
  autopilot.destination.system = multimatches[1].system
  autopilot.destination.x = multimatches[2].x
  autopilot.destination.y = multimatches[2].y
  autopilot.destination.z = multimatches[2].z
  disableTrigger("autopilot.trigger.showplanet") 
  local x = autopilot.destination.x + 289
  local y = autopilot.destination.y + 289
  local z = autopilot.destination.z + 289
  send("calculate '"..autopilot.destination.system.."' "..x.." "..y.." "..z) 
end

function autopilot.trigger.calculate()
  debugc("autopilot.trigger.calculate()")
  send("hyperspace")
end

function autopilot.trigger.exitHyperspace()
  debugc("autopilot.trigger.exitHyperspace()")
  send("course "..autopilot.destination.planet)
end

function autopilot.trigger.orbit()
  debugc("autopilot.trigger.orbit()")

  -- Check if there's a preferred pad for this planet (lowercase the planet name for lookup)
  local planet = matches.planet
  local preferredPad = autopilot.getPreferredPad(planet)

  if preferredPad then
    cecho("\n[<cyan>AutoPilot<reset>] Using preferred pad for <cyan>"..planet.."<reset>: <yellow>"..preferredPad.."<reset>\n")
    send("land '"..planet.."' "..preferredPad)
  else
    autopilot.destination.landIndex = 1
    send("land "..planet)
  end
end

function autopilot.trigger.restricted()
  debugc("autopilot.trigger.restricted()")
  autopilot.destination.landIndex = autopilot.destination.landIndex + 1
  send("land '"..autopilot.destination.planet.. "' "..autopilot.destination.pads[autopilot.destination.landIndex])
end

function autopilot.trigger.startLanding()
  debugc("autopilot.trigger.startLanding()")
  autopilot.destination.pads = {}

  -- Fallback landing logic (used when no preferred pad was specified)
  tempTimer(2, [[send("land '"..autopilot.destination.planet.. "' "..autopilot.destination.pads[autopilot.destination.landIndex])]])
end

function autopilot.trigger.landingChoices()
  debugc("autopilot.trigger.landingChoices()")
  table.insert(autopilot.destination.pads, matches.pad) 
end

function autopilot.trigger.land()
  debugc("autopilot.trigger.land()")
  send("autopilot on")
  if autopilot.ship.exit then
    for i = 1, #autopilot.ship.exit do
      send(autopilot.ship.exit[i])
    end
  end
  send("open")
  send("leave")
  send("close "..autopilot.ship.name)
  send("refuel "..autopilot.ship.name)

  if autopilot.runningCargo then
    local delivery = autopilot.currentManifest.deliveries[autopilot.deliveryIndex]

    -- Check if there are more waypoints - if so, continue the route
    if autopilot.waypoints and next(autopilot.waypoints) then
      cecho("[<cyan>AutoPilot<reset>] <yellow>Waypoint reached<reset>, continuing route...\n")
      autopilot.destination = {}
      autopilot.destination.planet = table.remove(autopilot.waypoints, 1)
      cecho("[<cyan>AutoPilot<reset>] Next destination: <cyan>"..autopilot.destination.planet.."<reset>\n")
      autopilot.openShip()
      return
    end

    -- No more waypoints - we're at the delivery planet
    cecho("[<cyan>AutoPilot<reset>] <green>Delivery destination reached:<reset> <cyan>"..delivery.planet.."<reset>\n")
    
    -- If cargo run is paused, don't sell cargo - leave it for manual handling
    if autopilot.cargoPaused then
      cecho("[<cyan>AutoPilot<reset>] <yellow>Cargo run is paused.<reset> Ship refueled. Cargo remains in hold.\n")
      cecho("[<cyan>AutoPilot<reset>] <gray>Sell cargo manually or use<reset> <green>ap cargo resume<reset> <gray>when ready.<reset>\n")
      return
    end
    
    -- Not paused - proceed with selling cargo
    local useContraband = delivery.contraband or autopilot.useContraband
    local sellCommand = useContraband and "sellcontraband" or "sellcargo"
    send(sellCommand.." "..autopilot.ship.name.." '"..delivery.resource.."' "..autopilot.ship.capacity)
    return
  end

  if autopilot.waypoints and next(autopilot.waypoints) then
    cecho("[<cyan>AutoPilot<reset>] Setting destination to next waypoint...\n")
    autopilot.destination = {}
    autopilot.destination.planet = table.remove(autopilot.waypoints, 1)
    cecho("[<cyan>AutoPilot<reset>] Destination: <cyan>"..autopilot.destination.planet.."<reset>\n")
    autopilot.openShip()
    return
  end

  autopilot.destination = nil
  disableTrigger("autopilot.flight")
  cecho("[<cyan>AutoPilot<reset>] <yellow>Disengaged<reset> | Final Destination\n")
end

function autopilot.trigger.hyperspaceFail()
  debugc("autopilot.trigger.hyperspaceFail()")
  tempTimer(20, [[send("hyperspace")]])
end

function autopilot.trigger.fail()
  debugc("autopilot.trigger.fail()")
  send("!")
end

function autopilot.trigger.cargoPurchased()
  debugc("autopilot.trigger.cargoPurchased()")
  autopilot.expense = autopilot.expense + matches.cost

  -- Get current delivery
  local delivery = autopilot.currentManifest.deliveries[autopilot.deliveryIndex]

  -- Check if delivery has a route
  if delivery.route and autopilot.routes[delivery.route] then
    -- Use the route to get to delivery planet (route should include final destination)
    local route = autopilot.routes[delivery.route]
    autopilot.waypoints = table.deepcopy(route.planets)
    -- Set first planet in route as destination
    autopilot.destination = {}
    autopilot.destination.planet = table.remove(autopilot.waypoints, 1)
    cecho("\n[<cyan>AutoPilot<reset>] Using route <white>#"..delivery.route.."<reset> to reach <cyan>"..delivery.planet.."<reset>\n")
    cecho("[<cyan>AutoPilot<reset>] First stop: <cyan>"..autopilot.destination.planet.."<reset>\n")
  else
    -- Direct flight to delivery planet
    autopilot.waypoints = {}
    autopilot.destination = {}
    autopilot.destination.planet = delivery.planet
    cecho("\n[<cyan>AutoPilot<reset>] Direct flight to <cyan>"..delivery.planet.."<reset>\n")
  end

  autopilot.openShip()
end

function autopilot.trigger.cargoSold()
  debugc("autopilot.trigger.cargoSold()")
  autopilot.revenue = autopilot.revenue + matches.cost
  autopilot.profit = autopilot.revenue - autopilot.expense - autopilot.fuelCost

  -- Check if cargo run is paused - if so, don't buy next cargo
  if autopilot.cargoPaused then
    cecho("[<cyan>AutoPilot<reset>] <yellow>Cargo run is paused.<reset> Use <green>ap cargo resume<reset> to continue.\n")
    return
  end

  -- Move to next delivery
  if #autopilot.currentManifest.deliveries == autopilot.deliveryIndex then
    autopilot.deliveryIndex = 1
  else
    autopilot.deliveryIndex = autopilot.deliveryIndex + 1
  end

  -- Buy cargo for next delivery
  local nextDelivery = autopilot.currentManifest.deliveries[autopilot.deliveryIndex]
  -- Use per-delivery contraband flag if set, otherwise fall back to global setting
  local useContraband = nextDelivery.contraband or autopilot.useContraband
  local buyCommand = useContraband and "buycontraband" or "buycargo"
  send(buyCommand.." "..autopilot.ship.name.." '"..nextDelivery.resource.. "' "..autopilot.ship.capacity)
  cecho("[<cyan>AutoPilot<reset>] Buying <magenta>"..nextDelivery.resource.."<reset> for delivery to <cyan>"..nextDelivery.planet.."<reset>\n")
end

function autopilot.trigger.refuel()
  debugc("autopilot.trigger.refuel()")
  local nocomma = matches.cost:gsub(",","")
  local cost = tonumber(nocomma)
  autopilot.fuelCost = autopilot.fuelCost + cost
end

-- ============================================================================
-- GUI INITIALIZATION
-- ============================================================================

-- GUI Configuration
autopilot.gui = autopilot.gui or {}
autopilot.gui.currentTab = autopilot.gui.currentTab or "ships"
autopilot.gui.currentPage = autopilot.gui.currentPage or 1
autopilot.gui.itemsPerPage = autopilot.gui.itemsPerPage or 15

-- GUI Dimensions
autopilot.gui.config = autopilot.gui.config or {
  window = {
    width = "60%",
    height = "60%",
    x = "20%",
    y = "20%"
  },
  header = {
    height = "8%"
  },
  tabs = {
    height = "10%"
  },
  content = {
    y = "18%",
    height = "74%"
  },
  footer = {
    height = "8%"
  }
}

-- Color scheme (matching ShipDB)
autopilot.gui.colors = autopilot.gui.colors or {
  background = "rgb(47, 49, 54)",
  border = "rgb(32, 34, 37)",
  header = "rgb(64, 68, 75)",
  hover = "rgb(80, 85, 95)",
  active = "rgb(100, 105, 115)",
  text = "rgb(216, 217, 218)",
  textDim = "rgb(180, 180, 180)"
}

-- Create main window as Adjustable.Container (draggable, resizable)
autopilot.gui.window = Adjustable.Container:new({
  name = "autopilot_window",
  x = autopilot.gui.config.window.x,
  y = autopilot.gui.config.window.y,
  width = autopilot.gui.config.window.width,
  height = autopilot.gui.config.window.height,
  titleText = "",  -- No title text
  adjLabelstyle = "background-color: rgba(0,0,0,0)",
  buttonstyle = [[
    background-color: ]]..autopilot.gui.colors.header..[[;
    border: 1px solid ]]..autopilot.gui.colors.border..[[;
  ]],
  lockStyle = "border: 2px solid " .. autopilot.gui.colors.border .. ";",
})

-- Create header
autopilot.gui.header = Geyser.Label:new({
  name = "autopilot_header",
  x = "0%", y = "0%",
  width = "100%",
  height = autopilot.gui.config.header.height
}, autopilot.gui.window)

autopilot.gui.header:setStyleSheet([[
  background-color: ]]..autopilot.gui.colors.header..[[;
  border-bottom: 1px solid ]]..autopilot.gui.colors.border..[[;
  color: ]]..autopilot.gui.colors.text..[[;
  font-size: 14pt;
  font-weight: bold;
  padding-left: 10px;
  qproperty-alignment: 'AlignVCenter|AlignLeft';
]])

autopilot.gui.header:echo("AutoPilot Configuration")

-- Navigation stack for view history
autopilot.gui.viewStack = {}
autopilot.gui.currentView = nil

-- Create HBox container for tabs
autopilot.gui.tabHBox = Geyser.HBox:new({
  name = "autopilot_tabHBox",
  x = "0%",
  y = autopilot.gui.config.header.height,
  width = "100%",
  height = autopilot.gui.config.tabs.height
}, autopilot.gui.window)

-- Create tab buttons (HBox will auto-distribute them equally)
autopilot.gui.tabs = {}
local tabNames = {"status", "ships", "routes", "manifests", "pads"}
local tabLabels = {"Status", "Ships", "Routes", "Manifests", "Pads"}

for i, tabName in ipairs(tabNames) do
  autopilot.gui.tabs[tabName] = Geyser.Label:new({
    name = "autopilot_tab_" .. tabName
  }, autopilot.gui.tabHBox)

  autopilot.gui.tabs[tabName]:echo(tabLabels[i])
  autopilot.gui.tabs[tabName]:setClickCallback(function() autopilot.switchTab(tabName) end)

  autopilot.gui.tabs[tabName]:setStyleSheet([[
    QLabel {
      background-color: ]]..autopilot.gui.colors.header..[[;
      border: 1px solid ]]..autopilot.gui.colors.border..[[;
      color: ]]..autopilot.gui.colors.textDim..[[;
      font-size: 10pt;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background-color: ]]..autopilot.gui.colors.hover..[[;
    }
  ]])
end

-- Create content area
autopilot.gui.content = Geyser.MiniConsole:new({
  name = "autopilot_content",
  x = "0%",
  y = autopilot.gui.config.content.y,
  width = "100%",
  height = autopilot.gui.config.content.height,
  autoWrap = true,
  scrollBar = true,
  fontSize = 12
}, autopilot.gui.window)

autopilot.gui.content:setColor(47, 49, 54)  -- Match background color

-- Create form container (for interactive forms with widgets)
autopilot.gui.formContainer = Geyser.Label:new({
  name = "autopilot_form_container",
  x = "0%",
  y = autopilot.gui.config.content.y,
  width = "100%",
  height = autopilot.gui.config.content.height
}, autopilot.gui.window)

autopilot.gui.formContainer:setStyleSheet([[
  background-color: ]]..autopilot.gui.colors.background..[[;
]])

-- Hide form container by default (show content MiniConsole)
autopilot.gui.formContainer:hide()

-- Create footer container
autopilot.gui.footer = Geyser.Label:new({
  name = "autopilot_footer",
  x = "0%",
  y = "92%",  -- 100% - footer.height (8%)
  width = "100%",
  height = autopilot.gui.config.footer.height
}, autopilot.gui.window)

autopilot.gui.footer:setStyleSheet([[
  background-color: ]]..autopilot.gui.colors.header..[[;
  border-top: 1px solid ]]..autopilot.gui.colors.border..[[;
  color: ]]..autopilot.gui.colors.text..[[;
  font-size: 9pt;
  padding: 5px;
  qproperty-alignment: 'AlignCenter';
]])

--autopilot.gui.footer:echo("AutoPilot v1.0 - Use tab buttons to navigate")

-- Hide window by default
autopilot.gui.window:hide()

-- ============================================================================
-- POPUP DIALOG FUNCTIONS
-- ============================================================================

-- Helper function to create a popup dialog
function autopilot.createPopup(title, fields, onAccept)

  -- Calculate popup height based on number of fields
  local startY = 60
  local fieldSpacing = 45
  local buttonHeight = 40
  local buttonMargin = 30
  local popupHeight = startY + (#fields * fieldSpacing) + buttonMargin + buttonHeight + 20

  -- Create popup window as Adjustable.Container
  local popup = Adjustable.Container:new({
    name = "autopilot_popup",
    x = "30%", y = "15%",
    width = "40%", height = popupHeight,
    titleText = title,
    adjLabelstyle = [[
      background-color: ]]..autopilot.gui.colors.background..[[;
      border: 2px solid ]]..autopilot.gui.colors.border..[[;
    ]],
    buttonstyle = [[
      background-color: ]]..autopilot.gui.colors.header..[[;
      border: 1px solid ]]..autopilot.gui.colors.border..[[;
    ]],
    lockStyle = "border: 2px solid " .. autopilot.gui.colors.border .. ";",
  })

  -- Calculate spacing
  local inputs = {}

  -- Create field labels and command line inputs
  for i, field in ipairs(fields) do
    local yPos = startY + ((i-1) * fieldSpacing)

    -- Field label
    local label = Geyser.Label:new({
      name = "autopilot_popup_label_" .. field.name,
      x = 20, y = yPos,
      width = 120, height = 30
    }, popup)

    label:setStyleSheet([[
      background-color: transparent;
      color: ]] .. autopilot.gui.colors.text .. [[;
      font-size: 12pt;
      qproperty-alignment: 'AlignVCenter|AlignRight';
      padding-right: 10px;
    ]])
    label:setFontSize(12)
    label:echo(field.label .. ":")

    -- Field input using Geyser.CommandLine
    local input = Geyser.CommandLine:new({
      name = "autopilot_popup_input_" .. field.name,
      x = 150, y = yPos,
      width = "60%", height = 30,
      fontSize = 12
    }, popup)

    -- Set initial value if provided
    if field.value then
      input:print(field.value)
    end

    inputs[field.name] = input
  end

  -- Calculate button Y position
  local buttonY = startY + (#fields * fieldSpacing) + buttonMargin

  -- Accept button
  local acceptBtn = Geyser.Label:new({
    name = "autopilot_popup_accept",
    x = "20%", y = buttonY,
    width = "25%", height = buttonHeight
  }, popup)

  acceptBtn:setStyleSheet([[
    QLabel {
      background-color: ]] .. autopilot.gui.colors.header .. [[;
      border: 1px solid ]] .. autopilot.gui.colors.border .. [[;
      color: ]] .. autopilot.gui.colors.text .. [[;
      font-size: 12pt;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background-color: rgb(80, 150, 80);
    }
  ]])
  acceptBtn:echo("Accept")
  acceptBtn:setClickCallback(function()
    -- Collect values from command line inputs
    local values = {}
    for name, input in pairs(inputs) do
      values[name] = input:getText()
    end
    popup:hide()
    onAccept(values)
  end)

  -- Cancel button
  local cancelBtn = Geyser.Label:new({
    name = "autopilot_popup_cancel",
    x = "55%", y = buttonY,
    width = "25%", height = buttonHeight
  }, popup)

  cancelBtn:setStyleSheet([[
    QLabel {
      background-color: ]] .. autopilot.gui.colors.header .. [[;
      border: 1px solid ]] .. autopilot.gui.colors.border .. [[;
      color: ]] .. autopilot.gui.colors.text .. [[;
      font-size: 12pt;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background-color: rgb(150, 80, 80);
    }
  ]])
  cancelBtn:echo("Cancel")
  cancelBtn:setClickCallback(function()
    popup:hide()
  end)

  popup:show()
  autopilot.gui.popup = popup
  return popup
end

-- Ship dialog (add or edit)
function autopilot.showShipDialog(shipIndex)
  autopilot.goToView({type = "edit_ship", index = shipIndex})
end

function autopilot.showShipForm(shipIndex)
  local ship = shipIndex and autopilot.ships[shipIndex] or {}
  local isEdit = shipIndex ~= nil

  -- Convert enter/exit tables to comma-separated strings for editing
  local enterStr = ""
  if ship.enter then
    if type(ship.enter) == "table" then
      enterStr = table.concat(ship.enter, ", ")
    else
      enterStr = ship.enter
    end
  end

  local exitStr = ""
  if ship.exit then
    if type(ship.exit) == "table" then
      exitStr = table.concat(ship.exit, ", ")
    else
      exitStr = ship.exit
    end
  end

  autopilot.showForm(
    isEdit and "EDIT SHIP" or "ADD SHIP",
    {
      {name = "name", label = "Ship Name", value = ship.name or ""},
      {name = "speed", label = "Speed", value = ship.speed or ""},
      {name = "hyperspeed", label = "Hyperspeed", value = ship.hyperspeed or ""},
      {name = "capacity", label = "Capacity", value = ship.capacity or ""},
      {name = "hatchcode", label = "Hatch Code", value = ship.hatchcode or ""},
      {name = "enter", label = "Enter (comma-separated)", value = enterStr},
      {name = "exit", label = "Exit (comma-separated)", value = exitStr}
    },
    function(values)
      -- Validate required fields
      if not values.name or values.name == "" then
        cecho("\n[<cyan>AutoPilot<reset>] <red>Ship name is required.\n")
        return
      end

      -- Parse enter commands from comma-separated string
      local enterCommands = {}
      if values.enter and values.enter ~= "" then
        for cmd in string.gmatch(values.enter, "([^,]+)") do
          local trimmed = cmd:match("^%s*(.-)%s*$")
          if trimmed ~= "" then
            table.insert(enterCommands, trimmed)
          end
        end
      end

      -- Parse exit commands from comma-separated string
      local exitCommands = {}
      if values.exit and values.exit ~= "" then
        for cmd in string.gmatch(values.exit, "([^,]+)") do
          local trimmed = cmd:match("^%s*(.-)%s*$")
          if trimmed ~= "" then
            table.insert(exitCommands, trimmed)
          end
        end
      end

      -- Create or update ship
      local newShip = {
        name = values.name,
        speed = values.speed,
        hyperspeed = values.hyperspeed,
        capacity = values.capacity,
        hatchcode = values.hatchcode,
        enter = #enterCommands > 0 and enterCommands or nil,
        exit = #exitCommands > 0 and exitCommands or nil
      }

      if isEdit then
        autopilot.ships[shipIndex] = newShip
        cecho("\n[<cyan>AutoPilot<reset>] Ship <cyan>"..values.name.."<reset> updated.\n")
      else
        table.insert(autopilot.ships, newShip)
        cecho("\n[<cyan>AutoPilot<reset>] Ship <cyan>"..values.name.."<reset> added.\n")
      end

      -- Save and refresh
      table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
    end
  )
end

-- Route dialog (add or edit)
function autopilot.showRouteDialog(routeIndex)
  autopilot.goToView({type = "edit_route", index = routeIndex})
end

function autopilot.showRouteForm(routeIndex)
  local route = routeIndex and autopilot.routes[routeIndex] or {}
  local isEdit = routeIndex ~= nil

  -- Convert planets array to comma-separated string for editing
  local planetsStr = ""
  if route.planets and #route.planets > 0 then
    planetsStr = table.concat(route.planets, ", ")
  end

  autopilot.showForm(
    isEdit and "EDIT ROUTE" or "ADD ROUTE",
    {
      {name = "name", label = "Route Name", value = route.name or ""},
      {name = "planets", label = "Planets (comma-separated)", value = planetsStr}
    },
    function(values)
      -- Validate required fields
      if not values.name or values.name == "" then
        cecho("\n[<cyan>AutoPilot<reset>] <red>Route name is required.\n")
        return
      end
      if not values.planets or values.planets == "" then
        cecho("\n[<cyan>AutoPilot<reset>] <red>At least one planet is required.\n")
        return
      end

      -- Parse planets from comma-separated string
      local planets = {}
      for planet in string.gmatch(values.planets, "([^,]+)") do
        local trimmed = planet:match("^%s*(.-)%s*$")  -- Trim whitespace
        if trimmed ~= "" then
          table.insert(planets, trimmed)
        end
      end

      if #planets == 0 then
        cecho("\n[<cyan>AutoPilot<reset>] <red>At least one planet is required.\n")
        return
      end

      -- Create or update route
      local newRoute = {
        name = values.name,
        planets = planets
      }

      if isEdit then
        autopilot.routes[routeIndex] = newRoute
        cecho("\n[<cyan>AutoPilot<reset>] Route <cyan>"..values.name.."<reset> updated.\n")
      else
        table.insert(autopilot.routes, newRoute)
        cecho("\n[<cyan>AutoPilot<reset>] Route <cyan>"..values.name.."<reset> added.\n")
      end

      -- Save and refresh
      table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
    end
  )
end

-- Delivery dialog (add or edit individual delivery)
function autopilot.showDeliveryDialog(manifestIndex, deliveryIndex, onSave)
  autopilot.goToView({
    type = "edit_delivery",
    manifestIndex = manifestIndex,
    deliveryIndex = deliveryIndex,
    onSave = onSave
  })
end

function autopilot.showDeliveryForm(manifestIndex, deliveryIndex)
  local manifest = autopilot.gui.workingManifest or (manifestIndex and autopilot.manifests[manifestIndex]) or {deliveries = {}}
  local delivery = deliveryIndex and manifest.deliveries[deliveryIndex] or {}
  local isEdit = deliveryIndex ~= nil

  -- Get the onSave callback from current view if it exists
  local onSave = autopilot.gui.currentView and autopilot.gui.currentView.onSave

  -- Store selected route (nil for direct, number for route index)
  local selectedRoute = delivery.route or nil

  -- Store selected contraband state
  local selectedContraband = delivery.contraband or false

  -- Use showForm for planet and resource only
  autopilot.showForm(
    isEdit and "EDIT DELIVERY" or "ADD DELIVERY",
    {
      {name = "planet", label = "Planet", value = delivery.planet or ""},
      {name = "resource", label = "Resource", value = delivery.resource or ""}
    },
    function(values)
      -- Validate required fields
      if not values.planet or values.planet == "" then
        cecho("\n[<cyan>AutoPilot<reset>] <red>Planet is required.\n")
        return
      end
      if not values.resource or values.resource == "" then
        cecho("\n[<cyan>AutoPilot<reset>] <red>Resource is required.\n")
        return
      end

      -- Build delivery object
      local newDelivery = {
        planet = values.planet,
        resource = values.resource,
        contraband = selectedContraband
      }
      if selectedRoute ~= nil then
        newDelivery.route = selectedRoute
      end

      -- Call the save callback
      if onSave then
        onSave(newDelivery, deliveryIndex)
      end
    end
  )

  -- Now add the route flyout dropdown after the resource field
  -- After 2 fields: 18% + (8% * 2) = 34%
  local yPos = 34

  -- Route label
  local routeLabel = Geyser.Label:new({
    x = "3%", y = yPos .. "%",
    width = "20%", height = "5%"
  }, autopilot.gui.formContainer)
  routeLabel:setStyleSheet([[
    background-color: transparent;
    color: ]]..autopilot.gui.colors.text..[[;
    font-size: 12pt;
    qproperty-alignment: 'AlignVCenter|AlignLeft';
  ]])
  routeLabel:echo("Route:")
  table.insert(autopilot.gui.formData.uiElements, routeLabel)

  -- Function to get display text for selected route
  local function getRouteDisplayText()
    if selectedRoute == nil then
      return "(Direct)"
    else
      local route = autopilot.routes[selectedRoute]
      return route and (route.name or ("Route #" .. selectedRoute)) or "(Direct)"
    end
  end

  -- Create MiniConsole for route selection with clickable links
  local routeConsole = Geyser.MiniConsole:new({
    x = "3%", y = yPos .. "%",
    width = "94%", height = "15%",
    autoWrap = true,
    scrollBar = false,
    fontSize = 12
  }, autopilot.gui.formContainer)
  routeConsole:setColor(47, 49, 54)
  table.insert(autopilot.gui.formData.uiElements, routeConsole)

  -- Helper function to format route label for display
  local function formatRouteLabel(route)
    if not route or not route.planets or #route.planets == 0 then
      return route and (route.name or "Unnamed Route") or "Unknown"
    end

    -- Build route path: planet1 → planet2 → planet3
    local routePath = ""
    for i, planet in ipairs(route.planets) do
      if i > 1 then
        routePath = routePath .. " → "
      end
      routePath = routePath .. planet
    end

    return routePath
  end

  -- Helper function to refresh the route console display
  local function refreshRouteConsole()
    routeConsole:clear()

    -- Display selected route at top
    local displayText = "(Direct)"
    if selectedRoute then
      local route = autopilot.routes[selectedRoute]
      displayText = formatRouteLabel(route)
    end
    routeConsole:cecho("<white>Selected Route: <cyan>" .. displayText .. "\n\n")
    routeConsole:cecho("<white>Available Routes: ")

    -- Add "(Direct)" option
    routeConsole:fg("green")
    routeConsole:echoLink("[Direct]", function()
      selectedRoute = nil
      refreshRouteConsole()
    end, "Direct flight (no route)", true)
    routeConsole:resetFormat()
    routeConsole:cecho("  ")

    -- Add route options
    if autopilot.routes and #autopilot.routes > 0 then
      for i, route in ipairs(autopilot.routes) do
        local routeLabel = formatRouteLabel(route)
        routeConsole:fg("yellow")
        routeConsole:echoLink("[" .. routeLabel .. "]", function()
          selectedRoute = i
          refreshRouteConsole()
        end, "Select " .. routeLabel, true)
        routeConsole:resetFormat()
        routeConsole:cecho("  ")
      end
    end
  end

  -- Initial display
  refreshRouteConsole()

  -- ============================================================================
  -- CONTRABAND TOGGLE SECTION
  -- ============================================================================
  -- Position after route section: 34% + 15% (route console) + 3% spacing = 52%
  local contrabandYPos = 52

  -- Contraband label
  local contrabandLabel = Geyser.Label:new({
    x = "3%", y = contrabandYPos .. "%",
    width = "20%", height = "5%"
  }, autopilot.gui.formContainer)
  contrabandLabel:setStyleSheet([[
    background-color: transparent;
    color: ]]..autopilot.gui.colors.text..[[;
    font-size: 12pt;
    qproperty-alignment: 'AlignVCenter|AlignLeft';
  ]])
  contrabandLabel:echo("Contraband:")
  table.insert(autopilot.gui.formData.uiElements, contrabandLabel)

  -- Create MiniConsole for contraband toggle
  local contrabandConsole = Geyser.MiniConsole:new({
    x = "3%", y = contrabandYPos .. "%",
    width = "94%", height = "8%",
    autoWrap = true,
    scrollBar = false,
    fontSize = 12
  }, autopilot.gui.formContainer)
  contrabandConsole:setColor(47, 49, 54)
  table.insert(autopilot.gui.formData.uiElements, contrabandConsole)

  -- Helper function to refresh the contraband toggle display
  local function refreshContrabandToggle()
    contrabandConsole:clear()

    if selectedContraband then
      contrabandConsole:cecho("<red>⚠ ENABLED<white> - Using contraband at this planet  ")
      contrabandConsole:fg("yellow")
      contrabandConsole:echoLink("[Disable]", function()
        selectedContraband = false
        refreshContrabandToggle()
      end, "Click to disable contraband for this delivery", true)
    else
      contrabandConsole:cecho("<green>o DISABLED<white> - Using standard cargo commands  ")
      contrabandConsole:fg("yellow")
      contrabandConsole:echoLink("[Enable]", function()
        selectedContraband = true
        refreshContrabandToggle()
      end, "Click to enable contraband for this delivery", true)
    end
    contrabandConsole:resetFormat()
  end

  -- Initial contraband toggle display
  refreshContrabandToggle()

end

-- Helper function to format route display text
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

-- Refresh manifest editor display
function autopilot.refreshManifestEditor()
  if not autopilot.gui.manifestEditor or not autopilot.gui.workingManifest then
    return
  end

  local manifest = autopilot.gui.workingManifest
  local deliveries = manifest.deliveries or {}
  local console = autopilot.gui.content

  -- Ensure form container is hidden and content is shown
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()

  -- Clear and update the display
  console:clear()

  -- Manifest name section with edit button
  console:cecho("<white>Manifest Name: <cyan>" .. (manifest.name or "(Not Set)") .. "  ")
  console:fg("yellow")
  console:echoLink("[Edit Name]", [[autopilot.editManifestName()]], "Edit manifest name", true)
  console:resetFormat()
  console:cecho("\n\n<cyan>───────────────────────────────────────────────────────────────\n\n")

  -- Deliveries section
  if #deliveries == 0 then
    console:cecho("<yellow>No deliveries yet. Click [+ Add Delivery] below to add one.\n")
  else
    console:cecho("<white>Deliveries:\n\n")
    for i, delivery in ipairs(deliveries) do
      local routeText = autopilot.formatRouteText(delivery.route)
      local contrabandIndicator = delivery.contraband and " <red>⚠ [CONTRABAND]<white>" or ""
      console:cecho(string.format("<white>%d. <cyan>%s <white>→ <yellow>%s%s%s  ",
        i, delivery.planet or "?", delivery.resource or "?", routeText, contrabandIndicator))

      -- Edit button
      console:fg("yellow")
      console:echoLink("[Edit]", [[autopilot.editDeliveryInManifest(]] .. i .. [[)]], "Edit this delivery", true)
      console:fg("white")
      console:cecho(" ")

      -- Delete button
      console:fg("red")
      console:echoLink("[Delete]", [[autopilot.deleteDeliveryFromManifest(]] .. i .. [[)]], "Delete this delivery", true)
      console:resetFormat()
      console:cecho("\n\n")
    end
  end

  -- Action buttons separator
  console:cecho("\n<cyan>───────────────────────────────────────────────────────────────\n\n")

  -- Add Delivery button
  console:fg("green")
  console:echoLink("[+ Add Delivery]", [[autopilot.addDeliveryToManifest()]], "Add a new delivery to this manifest", true)
  console:resetFormat()
  console:cecho("  ")

  -- Save button
  console:fg("green")
  console:echoLink("[Save]", [[autopilot.saveManifestFromEditor()]], "Save this manifest", true)
  console:resetFormat()
  console:cecho("  ")

  -- Cancel button
  console:fg("red")
  console:echoLink("[Cancel]", [[autopilot.cancelManifestEditor()]], "Cancel editing and discard changes", true)
  console:resetFormat()
  console:cecho("\n")
end

-- Edit manifest name
function autopilot.editManifestName()
  if not autopilot.gui.workingManifest then
    cecho("\n[<cyan>AutoPilot<reset>] <red>Error: No active manifest.\n")
    return
  end

  autopilot.goToView({
    type = "edit_manifest_name",
    manifestIndex = autopilot.gui.workingManifestIndex
  })
end

function autopilot.showManifestNameForm()
  if not autopilot.gui.workingManifest then return end

  autopilot.showForm(
    "EDIT MANIFEST NAME",
    {
      {name = "name", label = "Manifest Name", value = autopilot.gui.workingManifest.name or ""}
    },
    function(values)
      if not values.name or values.name == "" then
        cecho("\n[<cyan>AutoPilot<reset>] <red>Manifest name is required.\n")
        return
      end

      -- Update both the saved manifest AND the working copy
      local manifestIndex = autopilot.gui.workingManifestIndex
      if manifestIndex then
        -- Editing existing manifest - update saved copy and save to disk
        autopilot.manifests[manifestIndex].name = values.name
        autopilot.gui.workingManifest.name = values.name
        table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
        cecho("\n[<cyan>AutoPilot<reset>] Manifest name updated and saved to disk.\n")
      else
        -- Adding new manifest - only update working copy, will save when clicking Save button
        autopilot.gui.workingManifest.name = values.name
        cecho("\n[<cyan>AutoPilot<reset>] Manifest name updated (not saved yet - click Save to persist).\n")
      end
    end,
    function()
      -- onCancel callback - does nothing, popView will handle it
    end
  )
end

-- Save manifest from editor
function autopilot.saveManifestFromEditor()
  if not autopilot.gui.workingManifest then
    cecho("\n[<cyan>AutoPilot<reset>] <red>Error: No active manifest.\n")
    return
  end

  local isEdit = autopilot.gui.manifestEditor and autopilot.gui.manifestEditor.isEdit
  local manifestIndex = autopilot.gui.workingManifestIndex

  -- Validate manifest name
  if not autopilot.gui.workingManifest.name or autopilot.gui.workingManifest.name == "" then
    cecho("\n[<cyan>AutoPilot<reset>] <red>Manifest name is required.\n")
    return
  end

  if #autopilot.gui.workingManifest.deliveries == 0 then
    cecho("\n[<cyan>AutoPilot<reset>] <red>At least one delivery is required.\n")
    return
  end

  -- Save manifest
  if isEdit then
    autopilot.manifests[manifestIndex] = autopilot.gui.workingManifest
    cecho("\n[<cyan>AutoPilot<reset>] Manifest <cyan>"..autopilot.gui.workingManifest.name.."<reset> updated.\n")
  else
    table.insert(autopilot.manifests, autopilot.gui.workingManifest)
    cecho("\n[<cyan>AutoPilot<reset>] Manifest <cyan>"..autopilot.gui.workingManifest.name.."<reset> added.\n")
  end

  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  autopilot.gui.manifestEditor = nil
  autopilot.gui.workingManifest = nil
  autopilot.popView()
end

-- Cancel manifest editor
function autopilot.cancelManifestEditor()
  autopilot.gui.manifestEditor = nil
  autopilot.gui.workingManifest = nil
  cecho("\n[<cyan>AutoPilot<reset>] Manifest editing cancelled.\n")
  autopilot.popView()
end

-- Add delivery to working manifest
function autopilot.addDeliveryToManifest()
  autopilot.showDeliveryDialog(nil, nil, function(newDelivery, deliveryIndex)
    -- Ensure working manifest still exists
    if not autopilot.gui.workingManifest then
      cecho("\n[<cyan>AutoPilot<reset>] <red>Error: No active manifest to add delivery to.\n")
      return
    end

    local manifestIndex = autopilot.gui.workingManifestIndex
    if manifestIndex then
      -- Editing existing manifest - update saved copy and save to disk
      table.insert(autopilot.manifests[manifestIndex].deliveries, newDelivery)
      table.insert(autopilot.gui.workingManifest.deliveries, newDelivery)
      table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
      cecho("\n[<cyan>AutoPilot<reset>] Delivery added and saved to disk.\n")
    else
      -- Adding to new manifest - only update working copy, will save when clicking Save button
      table.insert(autopilot.gui.workingManifest.deliveries, newDelivery)
      cecho("\n[<cyan>AutoPilot<reset>] Delivery added.\n")
    end
  end)
end

-- Edit delivery in working manifest
function autopilot.editDeliveryInManifest(deliveryIndex)
  if not autopilot.gui.workingManifest then
    cecho("\n[<cyan>AutoPilot<reset>] <red>Error: No active manifest.\n")
    return
  end

  local delivery = autopilot.gui.workingManifest.deliveries[deliveryIndex]
  if not delivery then return end

  -- Pass the deliveryIndex so the form can pre-fill values
  autopilot.showDeliveryDialog(nil, deliveryIndex, function(updatedDelivery, _)
    if not autopilot.gui.workingManifest then
      cecho("\n[<cyan>AutoPilot<reset>] <red>Error: No active manifest to update.\n")
      return
    end

    local manifestIndex = autopilot.gui.workingManifestIndex
    if manifestIndex then
      -- Editing existing manifest - update saved copy and save to disk
      autopilot.manifests[manifestIndex].deliveries[deliveryIndex] = updatedDelivery
      autopilot.gui.workingManifest.deliveries[deliveryIndex] = updatedDelivery
      table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
      cecho("\n[<cyan>AutoPilot<reset>] Delivery updated and saved to disk.\n")
    else
      -- Editing delivery in new manifest - only update working copy, will save when clicking Save button
      autopilot.gui.workingManifest.deliveries[deliveryIndex] = updatedDelivery
      cecho("\n[<cyan>AutoPilot<reset>] Delivery updated.\n")
    end
  end)
end

-- Delete delivery from working manifest
function autopilot.deleteDeliveryFromManifest(deliveryIndex)
  table.remove(autopilot.gui.workingManifest.deliveries, deliveryIndex)
  autopilot.refreshManifestEditor()
  cecho("\n[<cyan>AutoPilot<reset>] Delivery deleted.\n")
end

-- Manifest dialog (add or edit) - now with delivery management
function autopilot.showManifestDialog(manifestIndex)
  autopilot.goToView({type = "edit_manifest", index = manifestIndex})
end

function autopilot.showManifestEditor(manifestIndex)
  -- Clean up any existing UI elements first
  autopilot.cleanupFormUI()

  local isEdit = manifestIndex ~= nil

  -- Always create a fresh working manifest
  local manifest = manifestIndex and table.deepcopy(autopilot.manifests[manifestIndex]) or {name = "", deliveries = {}}
  autopilot.gui.workingManifest = manifest
  autopilot.gui.workingManifestIndex = manifestIndex

  -- Store references
  autopilot.gui.manifestEditor = {
    isEdit = isEdit,
    manifestIndex = manifestIndex
  }

  -- Use the main content MiniConsole instead of creating a new one
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()
  autopilot.gui.content:clear()

  -- Initial display
  autopilot.refreshManifestEditor()
end

-- Pad dialog (add or edit)
function autopilot.showPadDialog(planetName)
  autopilot.goToView({type = "edit_pad", planet = planetName})
end

function autopilot.showPadForm(planetName)
  local planet = planetName or ""
  local pad = planetName and autopilot.preferredPads[planetName:lower()] or ""

  autopilot.showForm(
    "SET PREFERRED PAD",
    {
      {name = "planet", label = "Planet Name", value = planet},
      {name = "pad", label = "Pad Name", value = pad or ""}
    },
    function(values)
      -- Validate required fields
      if not values.planet or values.planet == "" then
        cecho("\n[<cyan>AutoPilot<reset>] <red>Planet name is required.\n")
        return
      end
      if not values.pad or values.pad == "" then
        cecho("\n[<cyan>AutoPilot<reset>] <red>Pad name is required.\n")
        return
      end

      -- Set preferred pad
      local planetKey = values.planet:lower()
      autopilot.preferredPads[planetKey] = values.pad

      -- Save and refresh
      table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
      cecho("\n[<cyan>AutoPilot<reset>] Preferred pad for <cyan>"..values.planet.."<reset> set to <green>"..values.pad.."<reset>\n")
    end
  )
end

-- Update tab styles based on active tab
function autopilot.updateTabStyles()
  if not autopilot.gui.tabs then return end

  local activeStyle = [[
    QLabel {
      background-color: ]]..autopilot.gui.colors.active..[[;
      border: 1px solid ]]..autopilot.gui.colors.border..[[;
      color: ]]..autopilot.gui.colors.text..[[;
      font-size: 10pt;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
  ]]

  local inactiveStyle = [[
    QLabel {
      background-color: ]]..autopilot.gui.colors.header..[[;
      border: 1px solid ]]..autopilot.gui.colors.border..[[;
      color: ]]..autopilot.gui.colors.textDim..[[;
      font-size: 10pt;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background-color: ]]..autopilot.gui.colors.hover..[[;
    }
  ]]

  for tabName, tabLabel in pairs(autopilot.gui.tabs) do
    if tabName == autopilot.gui.currentTab then
      tabLabel:setStyleSheet(activeStyle)
    else
      tabLabel:setStyleSheet(inactiveStyle)
    end
  end
end

-- Switch to a different tab
-- Navigation functions
function autopilot.pushView(viewData)
  table.insert(autopilot.gui.viewStack, autopilot.gui.currentView)
  autopilot.gui.currentView = viewData
end

function autopilot.popView()
  if #autopilot.gui.viewStack > 0 then
    autopilot.gui.currentView = table.remove(autopilot.gui.viewStack)
    autopilot.refreshGUI()
  end
end

function autopilot.goToView(viewData)
  autopilot.pushView(viewData)
  autopilot.refreshGUI()
end

-- Clean up any active form UI elements
function autopilot.cleanupFormUI()
  -- Destroy the entire formContainer (and all its children)
  if autopilot.gui.formContainer then
    autopilot.gui.formContainer:hide()
    autopilot.gui.formContainer = nil
  end

  -- Recreate a fresh formContainer
  autopilot.gui.formContainer = Geyser.Label:new({
    name = "autopilot_form_container",
    x = "0%",
    y = autopilot.gui.config.content.y,
    width = "100%",
    height = autopilot.gui.config.content.height
  }, autopilot.gui.window)

  autopilot.gui.formContainer:setStyleSheet([[
    background-color: ]]..autopilot.gui.colors.background..[[;
  ]])

  -- Start hidden (will be shown by forms when needed)
  autopilot.gui.formContainer:hide()

  -- Clear references
  autopilot.gui.formData = nil
  -- NOTE: Don't clear manifestEditor or workingManifest here - they're needed by manifest editor callbacks
  -- They will be cleared when the manifest editor itself is closed
end

-- Generic form builder that renders in form container
function autopilot.showForm(title, fields, onSave, onCancel)
  -- Clean up any existing UI elements first
  autopilot.cleanupFormUI()

  -- Switch to form container
  autopilot.gui.content:hide()
  autopilot.gui.formContainer:show()

  -- Title label
  local titleLabel = Geyser.Label:new({
    x = "0%", y = "0%",
    width = "100%", height = "15%"
  }, autopilot.gui.formContainer)
  titleLabel:setStyleSheet([[
    background-color: transparent;
    color: ]]..autopilot.gui.colors.text..[[;
    font-size: 14pt;
    font-weight: bold;
    qproperty-alignment: 'AlignHCenter|AlignVCenter';
  ]])
  titleLabel:echo(title)

  -- Store form data
  autopilot.gui.formData = {
    fields = fields,
    inputs = {},
    onSave = onSave,
    onCancel = onCancel,
    uiElements = {titleLabel}  -- Track all UI elements for cleanup
  }

  -- Create input fields
  local yPos = 18  -- Starting at 18% (after 15% title + 3% spacing)
  for i, field in ipairs(fields) do
    -- Label
    local label = Geyser.Label:new({
      x = "3%", y = yPos .. "%",
      width = "20%", height = "5%"
    }, autopilot.gui.formContainer)
    label:setStyleSheet([[
      background-color: transparent;
      color: ]]..autopilot.gui.colors.text..[[;
      font-size: 12pt;
      qproperty-alignment: 'AlignVCenter|AlignLeft';
    ]])
    label:setFontSize(12)
    label:echo(field.label .. ":")
    table.insert(autopilot.gui.formData.uiElements, label)

    -- Input field
    local input = Geyser.CommandLine:new({
      x = "25%", y = yPos .. "%",
      width = "60%", height = "5%",
      fontSize = 12
    }, autopilot.gui.formContainer)
    if field.value and field.value ~= "" then
      input:print(field.value)
    end

    autopilot.gui.formData.inputs[field.name] = input
    table.insert(autopilot.gui.formData.uiElements, input)
    yPos = yPos + 8  -- 5% field + 3% spacing
  end

  -- Save button
  local saveBtn = Geyser.Label:new({
    x = "31%", y = "-25%",
    width = "18%", height = "7%"
  }, autopilot.gui.formContainer)
  saveBtn:setStyleSheet([[
    background-color: #2d5016;
    border: 1px solid #4a7c29;
    color: #a3d977;
    font-size: 12pt;
    font-weight: bold;
    qproperty-alignment: 'AlignCenter';
  ]])
  saveBtn:echo("Save")
  saveBtn:setClickCallback(function()
    autopilot.submitForm()
  end)
  table.insert(autopilot.gui.formData.uiElements, saveBtn)

  -- Cancel button
  local cancelBtn = Geyser.Label:new({
    x = "51%", y = "-25%",
    width = "18%", height = "7%"
  }, autopilot.gui.formContainer)
  cancelBtn:setStyleSheet([[
    background-color: #4a1616;
    border: 1px solid #7c2929;
    color: #d97777;
    font-size: 12pt;
    font-weight: bold;
    qproperty-alignment: 'AlignCenter';
  ]])
  cancelBtn:echo("Cancel")
  cancelBtn:setClickCallback(function()
    if autopilot.gui.formData.onCancel then
      autopilot.gui.formData.onCancel()
    end
    autopilot.popView()
  end)
  table.insert(autopilot.gui.formData.uiElements, cancelBtn)
end

function autopilot.submitForm()
  if not autopilot.gui.formData then return end

  local values = {}
  for name, input in pairs(autopilot.gui.formData.inputs) do
    values[name] = input:getText()
  end

  if autopilot.gui.formData.onSave then
    autopilot.gui.formData.onSave(values)
  end

  autopilot.popView()
end

function autopilot.switchTab(tabName)
  -- Clear view stack when switching tabs
  autopilot.gui.viewStack = {}
  autopilot.gui.currentView = {type = "tab", tab = tabName}
  autopilot.gui.currentTab = tabName
  autopilot.gui.currentPage = 1  -- Reset to page 1 when switching tabs
  autopilot.updateTabStyles()
  autopilot.refreshGUI()
end

-- Show GUI
function autopilot.showGUI()
  if not autopilot.gui.window then
    cecho("[<cyan>AutoPilot<reset>] <red>GUI not initialized. Please reload the script.<reset>\n")
    return
  end
  autopilot.gui.window:show()
  autopilot.gui.window:raise()
  autopilot.updateTabStyles()
  autopilot.refreshGUI()
end

-- Hide GUI
function autopilot.hideGUI()
  if not autopilot.gui.window then return end
  autopilot.gui.window:hide()
end

-- Refresh current tab content
function autopilot.refreshGUI()
  if not autopilot.gui.content then return end

  -- Check if we have a current view that overrides tab display
  if autopilot.gui.currentView and autopilot.gui.currentView.type == "form" then
    -- Form view is already displayed, don't refresh
    return
  elseif autopilot.gui.currentView and autopilot.gui.currentView.type == "edit_ship" then
    autopilot.showShipForm(autopilot.gui.currentView.index)
  elseif autopilot.gui.currentView and autopilot.gui.currentView.type == "edit_route" then
    autopilot.showRouteForm(autopilot.gui.currentView.index)
  elseif autopilot.gui.currentView and autopilot.gui.currentView.type == "edit_manifest" then
    -- If workingManifest exists, just refresh the display; otherwise initialize the editor
    if autopilot.gui.workingManifest and autopilot.gui.manifestEditor then
      autopilot.refreshManifestEditor()
    else
      autopilot.showManifestEditor(autopilot.gui.currentView.index)
    end
  elseif autopilot.gui.currentView and autopilot.gui.currentView.type == "edit_manifest_name" then
    autopilot.showManifestNameForm()
  elseif autopilot.gui.currentView and autopilot.gui.currentView.type == "edit_delivery" then
    autopilot.showDeliveryForm(autopilot.gui.currentView.manifestIndex, autopilot.gui.currentView.deliveryIndex)
  elseif autopilot.gui.currentView and autopilot.gui.currentView.type == "edit_pad" then
    autopilot.showPadForm(autopilot.gui.currentView.planet)
  elseif autopilot.gui.currentTab == "ships" then
    autopilot.displayShipsTab()
  elseif autopilot.gui.currentTab == "routes" then
    autopilot.displayRoutesTab()
  elseif autopilot.gui.currentTab == "manifests" then
    autopilot.displayManifestsTab()
  elseif autopilot.gui.currentTab == "pads" then
    autopilot.displayPadsTab()
  elseif autopilot.gui.currentTab == "status" then
    autopilot.displayStatusTab()
  end
end

-- Placeholder tab display functions (we'll implement these next)
function autopilot.displayShipsTab()
  autopilot.cleanupFormUI()
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()
  autopilot.gui.content:clear()

  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n")
  autopilot.gui.content:cecho("<yellow>                        SAVED SHIPS\n")
  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n\n")

  -- Add New button
  autopilot.gui.content:cecho("<white>")
  autopilot.gui.content:fg("green")
  autopilot.gui.content:echoLink("[+ Add New Ship]", [[autopilot.showShipDialog()]], "Click to add a new ship", true)
  autopilot.gui.content:resetFormat()
  autopilot.gui.content:cecho("\n\n")

  if not autopilot.ships or #autopilot.ships == 0 then
    autopilot.gui.content:cecho("<yellow>No ships saved yet.\n\n")
    autopilot.gui.content:cecho("<white>Use <cyan>ap save ship<white> after setting ship details to save a ship configuration.\n")
    return
  end

  for i, ship in ipairs(autopilot.ships) do
    autopilot.gui.content:cecho(string.format("<white>[<yellow>%d<white>] <cyan>%s\n", i, ship.name or "Unknown"))
    autopilot.gui.content:cecho(string.format("    <white>Speed: <green>%s  <white>Hyperspeed: <green>%s  <white>Capacity: <green>%s\n",
      ship.speed or "?", ship.hyperspeed or "?", ship.capacity or "?"))

    -- Show hatchcode, enter, exit if they exist
    if ship.hatchcode or ship.enter or ship.exit then
      autopilot.gui.content:cecho("    ")
      if ship.hatchcode and ship.hatchcode ~= "" then
        autopilot.gui.content:cecho(string.format("<white>Hatch: <green>%s  ", ship.hatchcode))
      end
      if ship.enter and type(ship.enter) == "table" and #ship.enter > 0 then
        autopilot.gui.content:cecho(string.format("<white>Enter: <green>%s  ", table.concat(ship.enter, ", ")))
      elseif ship.enter and type(ship.enter) == "string" and ship.enter ~= "" then
        autopilot.gui.content:cecho(string.format("<white>Enter: <green>%s  ", ship.enter))
      end
      if ship.exit and type(ship.exit) == "table" and #ship.exit > 0 then
        autopilot.gui.content:cecho(string.format("<white>Exit: <green>%s  ", table.concat(ship.exit, ", ")))
      elseif ship.exit and type(ship.exit) == "string" and ship.exit ~= "" then
        autopilot.gui.content:cecho(string.format("<white>Exit: <green>%s  ", ship.exit))
      end
      autopilot.gui.content:cecho("\n")
    end

    -- Action buttons
    autopilot.gui.content:cecho("    <white>Actions: ")
    autopilot.gui.content:fg("green")
    autopilot.gui.content:echoLink("[Load]", [[autopilot.alias.loadShip(]] .. i .. [[)]], "Load this ship configuration", true)
    autopilot.gui.content:fg("white")
    autopilot.gui.content:cecho(" ")
    autopilot.gui.content:fg("yellow")
    autopilot.gui.content:echoLink("[Edit]", [[autopilot.showShipDialog(]] .. i .. [[)]], "Edit this ship", true)
    autopilot.gui.content:fg("white")
    autopilot.gui.content:cecho(" ")
    autopilot.gui.content:fg("red")
    autopilot.gui.content:echoLink("[Delete]", [[
      table.remove(autopilot.ships, ]] .. i .. [[)
      table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
      cecho("\n[<cyan>AutoPilot<reset>] Ship deleted.\n")
      autopilot.refreshGUI()
    ]], "Delete this ship", true)
    autopilot.gui.content:resetFormat()
    autopilot.gui.content:cecho("\n\n")
  end

  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n")
  autopilot.gui.content:cecho("<white>Click <green>[+ Add New Ship]<white> to add, <yellow>[Edit]<white> to modify, or <red>[Delete]<white> to remove.\n")
end

function autopilot.displayRoutesTab()
  autopilot.cleanupFormUI()
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()
  autopilot.gui.content:clear()

  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n")
  autopilot.gui.content:cecho("<yellow>                        SAVED ROUTES\n")
  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n\n")

  -- Add New button
  autopilot.gui.content:cecho("<white>")
  autopilot.gui.content:fg("green")
  autopilot.gui.content:echoLink("[+ Add New Route]", [[autopilot.showRouteDialog()]], "Click to add a new route", true)
  autopilot.gui.content:resetFormat()
  autopilot.gui.content:cecho("\n\n")

  if not autopilot.routes or #autopilot.routes == 0 then
    autopilot.gui.content:cecho("<yellow>No routes saved yet.\n\n")
    autopilot.gui.content:cecho("<white>Use <cyan>ap add route <planets><white> to create a route, then <cyan>ap save route<white> to save it.\n")
    return
  end

  for i, route in ipairs(autopilot.routes) do
    local routeName = route.name or ("Route #" .. i)
    autopilot.gui.content:cecho(string.format("<white>[<yellow>%d<white>] <cyan>%s\n", i, routeName))

    if route.planets and #route.planets > 0 then
      autopilot.gui.content:cecho("    <white>Planets: <green>")
      for j, planet in ipairs(route.planets) do
        autopilot.gui.content:cecho(planet)
        if j < #route.planets then
          autopilot.gui.content:cecho(" <white>→ <green>")
        end
      end
      autopilot.gui.content:cecho("\n")
    end

    -- Action buttons
    autopilot.gui.content:cecho("    <white>Actions: ")
    autopilot.gui.content:fg("cyan")
    autopilot.gui.content:echoLink("[Fly To]", [[autopilot.flyRoute(]] .. i .. [[)]], "Fly this route", true)
    autopilot.gui.content:fg("white")
    autopilot.gui.content:cecho(" ")
    autopilot.gui.content:fg("green")
    autopilot.gui.content:echoLink("[Load]", [[autopilot.alias.loadRoute(]] .. i .. [[)]], "Load this route", true)
    autopilot.gui.content:fg("white")
    autopilot.gui.content:cecho(" ")
    autopilot.gui.content:fg("yellow")
    autopilot.gui.content:echoLink("[Edit]", [[autopilot.showRouteDialog(]] .. i .. [[)]], "Edit this route", true)
    autopilot.gui.content:fg("white")
    autopilot.gui.content:cecho(" ")
    autopilot.gui.content:fg("red")
    autopilot.gui.content:echoLink("[Delete]", [[
      table.remove(autopilot.routes, ]] .. i .. [[)
      table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
      cecho("\n[<cyan>AutoPilot<reset>] Route deleted.\n")
      autopilot.refreshGUI()
    ]], "Delete this route", true)
    autopilot.gui.content:resetFormat()
    autopilot.gui.content:cecho("\n\n")
  end

  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n")
  autopilot.gui.content:cecho("<white>Click <green>[+ Add New Route]<white> to add, <yellow>[Edit]<white> to modify, or <red>[Delete]<white> to remove.\n")
end

function autopilot.displayManifestsTab()
  autopilot.cleanupFormUI()
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()
  autopilot.gui.content:clear()

  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n")
  autopilot.gui.content:cecho("<yellow>                      SAVED MANIFESTS\n")
  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n\n")

  -- Add New button
  autopilot.gui.content:cecho("<white>")
  autopilot.gui.content:fg("green")
  autopilot.gui.content:echoLink("[+ Add New Manifest]", [[autopilot.showManifestDialog()]], "Click to add a new manifest", true)
  autopilot.gui.content:resetFormat()
  autopilot.gui.content:cecho("\n\n")

  if not autopilot.manifests or #autopilot.manifests == 0 then
    autopilot.gui.content:cecho("<yellow>No manifests saved yet.\n\n")
    autopilot.gui.content:cecho("<white>Use <cyan>ap add delivery <planet> <resource><white> to create deliveries, then <cyan>ap save manifest<white> to save.\n")
    return
  end

  for i, manifest in ipairs(autopilot.manifests) do
    local manifestName = manifest.name or ("Manifest #" .. i)
    autopilot.gui.content:cecho(string.format("<white>[<yellow>%d<white>] <cyan>%s\n", i, manifestName))

    if manifest.deliveries and #manifest.deliveries > 0 then
      autopilot.gui.content:cecho("    <white>Deliveries:\n")
      for j, delivery in ipairs(manifest.deliveries) do
        local routeText = autopilot.formatRouteText(delivery.route)
        local contrabandIndicator = delivery.contraband and " <red>⚠ [CONTRABAND]<white>" or ""
        autopilot.gui.content:cecho(string.format("      <green>%s <white>→ <yellow>%s%s%s\n",
          delivery.planet or "?", delivery.resource or "?", routeText, contrabandIndicator))
      end
    end

    -- Action buttons
    autopilot.gui.content:cecho("    <white>Actions: ")
    autopilot.gui.content:fg("green")
    autopilot.gui.content:echoLink("[Load]", [[autopilot.alias.loadManifest(]] .. i .. [[)]], "Load this manifest", true)
    autopilot.gui.content:fg("white")
    autopilot.gui.content:cecho(" ")
    autopilot.gui.content:fg("cyan")
    autopilot.gui.content:echoLink("[Edit]", [[autopilot.showManifestDialog(]] .. i .. [[)]], "Edit this manifest", true)
    autopilot.gui.content:fg("white")
    autopilot.gui.content:cecho(" ")
    autopilot.gui.content:fg("yellow")
    autopilot.gui.content:echoLink("[Start]", [[autopilot.alias.loadManifest(]] .. i .. [[); autopilot.alias.startCargo()]], "Load and start this manifest", true)
    autopilot.gui.content:fg("white")
    autopilot.gui.content:cecho(" ")
    autopilot.gui.content:fg("red")
    autopilot.gui.content:echoLink("[Delete]", [[
      table.remove(autopilot.manifests, ]] .. i .. [[)
      table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
      cecho("\n[<cyan>AutoPilot<reset>] Manifest deleted.\n")
      autopilot.refreshGUI()
    ]], "Delete this manifest", true)
    autopilot.gui.content:resetFormat()
    autopilot.gui.content:cecho("\n\n")
  end

  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n")
  autopilot.gui.content:cecho("<white>Click <green>[+ Add New Manifest]<white> to add, <cyan>[Edit]<white> to modify, or <red>[Delete]<white> to remove.\n")
end

function autopilot.displayPadsTab()
  autopilot.cleanupFormUI()
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()
  autopilot.gui.content:clear()

  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n")
  autopilot.gui.content:cecho("<yellow>                   PREFERRED LANDING PADS\n")
  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n\n")

  -- Add New button
  autopilot.gui.content:cecho("<white>")
  autopilot.gui.content:fg("green")
  autopilot.gui.content:echoLink("[+ Add New Pad]", [[autopilot.showPadDialog()]], "Click to add a new preferred pad", true)
  autopilot.gui.content:resetFormat()
  autopilot.gui.content:cecho("\n\n")

  if not autopilot.preferredPads or not next(autopilot.preferredPads) then
    autopilot.gui.content:cecho("<yellow>No preferred landing pads set yet.\n\n")
    autopilot.gui.content:cecho("<white>Use <cyan>ap set pad <planet> \"<pad name>\"<white> to set a preferred landing pad for a planet.\n")
    autopilot.gui.content:cecho("<white>Example: <cyan>ap set pad coruscant \"Senate District\"\n")
    return
  end

  local padCount = 0
  for planet, pad in pairs(autopilot.preferredPads) do
    padCount = padCount + 1
    autopilot.gui.content:cecho(string.format("<white>• <cyan>%-20s <white>→ <green>%s  ", planet, pad))

    -- Edit button
    autopilot.gui.content:fg("yellow")
    autopilot.gui.content:echoLink("[Edit]", [[autopilot.showPadDialog("]] .. planet .. [[")]], "Edit this preferred pad", true)
    autopilot.gui.content:fg("white")
    autopilot.gui.content:cecho(" ")

    -- Delete button
    autopilot.gui.content:fg("red")
    autopilot.gui.content:echoLink("[Delete]", [[autopilot.alias.clearPad("]] .. planet .. [[")]], "Remove this preferred pad", true)
    autopilot.gui.content:resetFormat()
    autopilot.gui.content:cecho("\n")
  end

  autopilot.gui.content:cecho("\n<cyan>───────────────────────────────────────────────────────────────\n")
  autopilot.gui.content:cecho(string.format("<white>Total: <yellow>%d<white> preferred pads configured\n", padCount))
  autopilot.gui.content:cecho("<white>Click <green>[+ Add New Pad]<white> to add, <yellow>[Edit]<white> to modify, or <red>[Delete]<white> to remove.\n")
end

function autopilot.displayStatusTab()
  autopilot.cleanupFormUI()
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()
  autopilot.gui.content:clear()

  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n")
  autopilot.gui.content:cecho("<yellow>                    AUTOPILOT STATUS\n")
  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n\n")

  -- Current ship info
  autopilot.gui.content:cecho("<white>Current Ship:\n")
  if autopilot.ship and autopilot.ship.name then
    autopilot.gui.content:cecho(string.format("  <cyan>%s<white> (Speed: <green>%s<white>, Hyperspeed: <green>%s<white>, Capacity: <green>%s<white>)\n\n",
      autopilot.ship.name, autopilot.ship.speed or "?", autopilot.ship.hyperspeed or "?", autopilot.ship.capacity or "?"))
  else
    autopilot.gui.content:cecho("  <yellow>No ship configured\n\n")
  end

  -- Current route info
  autopilot.gui.content:cecho("<white>Current Route:\n")
  if autopilot.currentRoute and autopilot.currentRoute.planets then
    local routeName = autopilot.currentRoute.name or "Unnamed Route"
    autopilot.gui.content:cecho(string.format("  <cyan>%s\n", routeName))
    autopilot.gui.content:cecho("  <white>Planets: <green>")
    for j, planet in ipairs(autopilot.currentRoute.planets) do
      autopilot.gui.content:cecho(planet)
      if j < #autopilot.currentRoute.planets then
        autopilot.gui.content:cecho(" <white>→ <green>")
      end
    end
    autopilot.gui.content:cecho("\n\n")
  else
    autopilot.gui.content:cecho("  <yellow>No route loaded\n\n")
  end

  -- Current manifest info
  autopilot.gui.content:cecho("<white>Current Manifest:\n")
  if autopilot.currentManifest and autopilot.currentManifest.deliveries then
    local manifestName = autopilot.currentManifest.name or "Unnamed Manifest"
    autopilot.gui.content:cecho(string.format("  <cyan>%s\n", manifestName))
    autopilot.gui.content:cecho("  <white>Deliveries:\n")
    for j, delivery in ipairs(autopilot.currentManifest.deliveries) do
      local routeText = autopilot.formatRouteText(delivery.route)
      autopilot.gui.content:cecho(string.format("    <green>%s <white>→ <yellow>%s%s\n",
        delivery.planet or "?", delivery.resource or "?", routeText))
    end
    autopilot.gui.content:cecho("\n")
  else
    autopilot.gui.content:cecho("  <yellow>No manifest loaded\n\n")
  end

  -- Autopilot status
 -- Show autopilot status
  local flightEnabled = isActive("autopilot.flight", "trigger")

  autopilot.gui.content:cecho("<white>Autopilot Status:\n")
  if autopilot.runningCargo then
    if autopilot.cargoPaused then
      autopilot.gui.content:cecho("  <yellow>* PAUSED (CARGO PAUSED)<white>  ")
    else
      autopilot.gui.content:cecho("  <green>* ACTIVE (RUNNING CARGO)<white>  ")
    end
  elseif flightEnabled > 0 then
    autopilot.gui.content:cecho("  <green>* ACTIVE<white>  ")
  else
    autopilot.gui.content:cecho("  <red>o Idle<white>  ")
  end

  -- Toggle button for autopilot triggers
  if flightEnabled > 0 then
    autopilot.gui.content:fg("red")
    autopilot.gui.content:echoLink("[Disable]", [[
      disableTrigger("autopilot.flight")
      disableTrigger("autopilot.cargo")
      cecho("[<cyan>AutoPilot<reset>] <red>Disabled<reset>\n")
      autopilot.refreshGUI()
    ]], "Click to disable autopilot", true)
  else
    autopilot.gui.content:fg("green")
    autopilot.gui.content:echoLink("[Enable]", [[
      enableTrigger("autopilot.flight")
      enableTrigger("autopilot.cargo")
      cecho("[<cyan>AutoPilot<reset>] <green>Enabled<reset>\n")
      autopilot.refreshGUI()
    ]], "Click to enable autopilot", true)
  end
  autopilot.gui.content:resetFormat()
  autopilot.gui.content:cecho("\n\n")

  -- Flight Progress Section
  autopilot.gui.content:cecho("<white>Flight Progress:\n")

  -- Current destination
  if autopilot.destination and autopilot.destination.planet then
    autopilot.gui.content:cecho("  <white>Current Destination: <green>➜ " .. autopilot.destination.planet .. "<white>\n")
  else
    autopilot.gui.content:cecho("  <white>Current Destination: <gray>(none)<white>\n")
  end

  -- Waypoints
  if autopilot.waypoints and #autopilot.waypoints > 0 then
    autopilot.gui.content:cecho("  <white>Remaining Waypoints:\n")
    for i, waypoint in ipairs(autopilot.waypoints) do
      if i == #autopilot.waypoints then
        -- Final destination
        autopilot.gui.content:cecho("    <white>" .. i .. ". <yellow>★ " .. waypoint .. " <gray>(Final Destination)<white>\n")
      else
        autopilot.gui.content:cecho("    <white>" .. i .. ". <cyan>" .. waypoint .. "<white>\n")
      end
    end
  elseif autopilot.destination and autopilot.destination.planet then
    autopilot.gui.content:cecho("  <white>Remaining Waypoints: <yellow>★ Final Destination<white>\n")
  end

  autopilot.gui.content:cecho("\n")

  -- Settings
  autopilot.gui.content:cecho("<white>Settings:\n")
  local contrabandStatus = autopilot.useContraband and "<green>Enabled" or "<red>Disabled"
  autopilot.gui.content:cecho(string.format("  Contraband: %s<white>  ", contrabandStatus))

  -- Toggle button
  if autopilot.useContraband then
    autopilot.gui.content:fg("red")
    autopilot.gui.content:echoLink("[Disable]", [[
      autopilot.useContraband = false
      cecho("[<cyan>AutoPilot<reset>] <green>Contraband mode disabled - using standard cargo commands.<reset>\n")
      table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
      autopilot.refreshGUI()
    ]], "Click to disable contraband mode", true)
  else
    autopilot.gui.content:fg("green")
    autopilot.gui.content:echoLink("[Enable]", [[
      autopilot.useContraband = true
      cecho("[<cyan>AutoPilot<reset>] <red>⚠ WARNING: Contraband mode ENABLED ⚠<reset>\n")
      cecho("[<cyan>AutoPilot<reset>] <yellow>Using contraband commands may result in in-game consequences.<reset>\n")
      table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
      autopilot.refreshGUI()
    ]], "Click to enable contraband mode", true)
  end
  autopilot.gui.content:resetFormat()
  autopilot.gui.content:cecho("\n\n")

  -- Statistics
  autopilot.gui.content:cecho("<cyan>───────────────────────────────────────────────────────────────\n")
  autopilot.gui.content:cecho("<white>Saved Configurations:\n")
  autopilot.gui.content:cecho(string.format("  Ships: <yellow>%d<white>  |  Routes: <yellow>%d<white>  |  Manifests: <yellow>%d<white>  |  Pads: <yellow>%d\n",
    autopilot.ships and #autopilot.ships or 0,
    autopilot.routes and #autopilot.routes or 0,
    autopilot.manifests and #autopilot.manifests or 0,
    autopilot.preferredPads and table.size(autopilot.preferredPads) or 0))
end

-- Get current installed version from package info
function autopilot.getCurrentVersion()
  local package_info = getPackageInfo("AutoPilot")
  if package_info and package_info.version then
    return package_info.version
  end
  return "unknown"
end

-- Version comparison function (semantic versioning)
function autopilot.compareVersions(v1, v2)
  -- Remove 'v' prefix if present
  v1 = v1:gsub("^v", "")
  v2 = v2:gsub("^v", "")

  -- Split versions into parts
  local v1_parts = {}
  local v2_parts = {}

  for num in v1:gmatch("%d+") do
    table.insert(v1_parts, tonumber(num))
  end

  for num in v2:gmatch("%d+") do
    table.insert(v2_parts, tonumber(num))
  end

  -- Compare each part
  for i = 1, math.max(#v1_parts, #v2_parts) do
    local v1_part = v1_parts[i] or 0
    local v2_part = v2_parts[i] or 0

    if v1_part < v2_part then
      return -1  -- v1 is older
    elseif v1_part > v2_part then
      return 1   -- v1 is newer
    end
  end

  return 0  -- versions are equal
end

-- Handle update check response
function autopilot.handleUpdateCheck(event, filename)
  -- Only handle our update check download
  if not filename or not filename:match("autopilot_update_check%.json") then
    return
  end

  -- Kill the event handler after first successful call
  if autopilot.update_check_handler then
    killAnonymousEventHandler(autopilot.update_check_handler)
    autopilot.update_check_handler = nil
  end

  -- Read the downloaded JSON file
  local file = io.open(filename, "r")
  if not file then
    cecho("\n[<cyan>AutoPilot<reset>] <red>Update check failed - could not retrieve version info<reset>\n")
    return
  end

  local content = file:read("*all")
  file:close()

  -- Parse JSON to extract latest release tag
  local latest_version = content:match('"tag_name"%s*:%s*"([^"]+)"')

  if not latest_version then
    cecho("\n[<cyan>AutoPilot<reset>] <red>Update check failed - could not parse version from GitHub<reset>\n")
    return
  end

  -- Get current installed version
  local current_version = autopilot.getCurrentVersion()

  -- Compare versions
  local comparison = autopilot.compareVersions(current_version, latest_version)

  if comparison < 0 then
    -- Update available
    local download_url = content:match('"browser_download_url"%s*:%s*"([^"]+%.mpackage)"')
    if not download_url then
      -- No .mpackage found, just show release page
      local release_url = string.format("https://github.com/%s/releases/latest", autopilot.config.github_repo)
      cecho("\n[<cyan>AutoPilot<reset>] <green>Update available!<reset> <yellow>v" .. current_version .. "<reset> → <white>" .. latest_version .. "<reset>\n")
      cecho("[<cyan>AutoPilot<reset>] Download from: <cyan>" .. release_url .. "<reset>\n")
      return
    end

    -- Store the download info
    autopilot.pending_update = {
      version = latest_version,
      url = download_url
    }

    -- Show update popup
    autopilot.showUpdatePopup(current_version, latest_version)
  else
    cecho("\n[<cyan>AutoPilot<reset>] You are running the latest version (<white>v" .. current_version .. "<reset>)\n")
  end
end

-- Show update popup with Yes/No buttons
function autopilot.showUpdatePopup(current_version, latest_version)
  -- Close existing popup if any
  if autopilot.update_popup then
    autopilot.update_popup:hide()
    autopilot.update_popup = nil
  end

  -- Create background overlay as a Label (supports setStyleSheet)
  autopilot.update_popup = Geyser.Label:new({
    name = "autopilot_update_popup",
    x = "0", y = "0",
    width = "100%", height = "100%",
  })

  autopilot.update_popup:setStyleSheet([[
    background-color: rgba(0, 0, 0, 180);
  ]])

  -- Create the dialog box (centered within the overlay)
  -- Using percentage with offset: 50% minus half the width/height
  autopilot.update_dialog = Geyser.Label:new({
    name = "autopilot_update_dialog",
    x = "40%", y = "40%",
    width = "500px", height = "300px",
  }, autopilot.update_popup)

  autopilot.update_dialog:setStyleSheet([[
    background-color: rgb(47, 49, 54);
    border: 2px solid rgb(100, 105, 115);
    border-radius: 10px;
  ]])

  -- Title
  local title = Geyser.Label:new({
    name = "autopilot_update_title",
    x = 0, y = "10px",
    width = "100%", height = "40px",
  }, autopilot.update_dialog)

  title:setStyleSheet([[
    background-color: transparent;
    color: rgb(88, 214, 141);
    font-size: 18pt;
    font-weight: bold;
    qproperty-alignment: 'AlignCenter';
  ]])
  title:echo("AutoPilot Update Available!")

  -- Message
  local message = Geyser.Label:new({
    name = "autopilot_update_message",
    x = "20px", y = "60px",
    width = "460px", height = "120px",
  }, autopilot.update_dialog)

  message:setStyleSheet([[
    background-color: transparent;
    color: rgb(220, 220, 220);
    font-size: 12pt;
    qproperty-alignment: 'AlignCenter';
    qproperty-wordWrap: true;
  ]])

  local msg_text = string.format([[<p style="text-align: center; line-height: 1.5;">
Current Version: v%s<br/>
Latest Version: %s<br/>
<br/>
Would you like to download and install it now?
</p>]], current_version, latest_version)
  message:echo(msg_text)

  -- Yes button
  local yes_button = Geyser.Label:new({
    name = "autopilot_update_yes",
    x = "80px", y = "220px",
    width = "150px", height = "50px",
  }, autopilot.update_dialog)

  yes_button:setStyleSheet([[
    QLabel {
      background-color: rgb(88, 214, 141);
      border: 1px solid rgb(70, 180, 120);
      border-radius: 5px;
      color: rgb(0, 0, 0);
      font-size: 14pt;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background-color: rgb(100, 230, 160);
    }
  ]])
  yes_button:echo("Yes")
  yes_button:setClickCallback(function()
    if autopilot.update_popup then
      autopilot.update_popup:hide()
      autopilot.update_popup = nil
    end
    autopilot.confirmUpdateInstall()
  end)

  -- No button
  local no_button = Geyser.Label:new({
    name = "autopilot_update_no",
    x = "270px", y = "220px",
    width = "150px", height = "50px",
  }, autopilot.update_dialog)

  no_button:setStyleSheet([[
    QLabel {
      background-color: rgb(64, 68, 75);
      border: 1px solid rgb(100, 105, 115);
      border-radius: 5px;
      color: rgb(220, 220, 220);
      font-size: 14pt;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background-color: rgb(80, 85, 95);
    }
  ]])
  no_button:echo("No")
  no_button:setClickCallback(function()
    if autopilot.update_popup then
      autopilot.update_popup:hide()
      autopilot.update_popup = nil
    end
    cecho("\n[<cyan>AutoPilot<reset>] Update cancelled. Run <white>autopilot update<reset> again later to install.\n")
    autopilot.pending_update = nil
  end)
end

-- Confirm and start the update installation
function autopilot.confirmUpdateInstall()
  if not autopilot.pending_update then
    return
  end

  local version = autopilot.pending_update.version
  local url = autopilot.pending_update.url
  local filename = getMudletHomeDir() .. "/AutoPilot_" .. version .. ".mpackage"

  cecho("\n[<cyan>AutoPilot<reset>] Downloading <white>" .. version .. "<reset>...\n")

  -- Register event handler for download completion
  if autopilot.install_handler then
    killAnonymousEventHandler(autopilot.install_handler)
  end
  autopilot.install_handler = registerAnonymousEventHandler("sysDownloadDone", "autopilot.handleInstallDownload")

  -- Store the filename for the handler
  autopilot.install_filename = filename

  -- Download the package
  downloadFile(filename, url)
end

-- Handle the downloaded package
function autopilot.handleInstallDownload(event, filename)
  -- Only handle our install download
  if not filename or filename ~= autopilot.install_filename then
    return
  end

  -- Kill the event handler
  if autopilot.install_handler then
    killAnonymousEventHandler(autopilot.install_handler)
    autopilot.install_handler = nil
  end

  cecho("\n[<cyan>AutoPilot<reset>] <green>Download complete!<reset> Installing package...\n")

  -- Uninstall old version first for clean update
  uninstallPackage("AutoPilot")

  -- Install the new package and check result
  local success = installPackage(filename)

  if success then
    cecho("[<cyan>AutoPilot<reset>] <green>Installation complete!<reset> The updated package is now active.\n")
    cecho("[<cyan>AutoPilot<reset>] <yellow>Note:<reset> If you experience issues, try reloading your profile.\n")
  else
    cecho("[<cyan>AutoPilot<reset>] <red>Installation failed!<reset> Please try downloading manually from:\n")
    cecho("[<cyan>AutoPilot<reset>] <cyan>https://github.com/" .. autopilot.config.github_repo .. "/releases/latest<reset>\n")
  end

  -- Clear pending update
  autopilot.pending_update = nil
  autopilot.install_filename = nil
end

-- Check for updates from GitHub
function autopilot.checkForUpdates(force)
  if not force and autopilot.config.update_check_done then
    return  -- Only check once per session unless forced
  end

  autopilot.config.update_check_done = true

  local api_url = string.format("https://api.github.com/repos/%s/releases/latest", autopilot.config.github_repo)
  local temp_file = getMudletHomeDir() .. "/autopilot_update_check.json"

  -- Register event handler for download completion
  if autopilot.update_check_handler then
    killAnonymousEventHandler(autopilot.update_check_handler)
  end
  autopilot.update_check_handler = registerAnonymousEventHandler("sysDownloadDone", "autopilot.handleUpdateCheck")

  -- Download the GitHub API response
  downloadFile(temp_file, api_url)
end

-- Manual update check (can be called anytime by user)
function autopilot.manualUpdateCheck()
  cecho("\n[<cyan>AutoPilot<reset>] Checking for updates...\n")
  autopilot.checkForUpdates(true)  -- Force check
end

-- Check for updates on load (once per session)
autopilot.checkForUpdates(false)