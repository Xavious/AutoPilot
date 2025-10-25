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
  if autopilot.ship.hatch then
    openString = openString.." "..autopilot.ship.hatch
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


function autopilot.alias.help()
  cecho("<white>------------------------------------------------------------\n")
  cecho("<cyan>                       AutoPilot Help<reset>\n")
  cecho("<white>------------------------------------------------------------\n\n")
  
  -- General Flight Commands
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

  -- Landing Pad Preferences
  cecho("<cyan>LANDING PAD PREFERENCES<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap set pad <planet> \"<pad>\"<reset>\n")
  cecho("   Sets a preferred landing pad for a planet (pad in quotes).\n\n")
  cecho("<yellow>ap clear pad <planet><reset>\n")
  cecho("   Clears the preferred landing pad for a planet.\n\n")
  cecho("<yellow>ap list pads<reset>\n")
  cecho("   Lists all configured preferred landing pads.\n\n")

  -- Ship Attribute Setup
  cecho("<cyan>SHIP ATTRIBUTE COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap set ship <name><reset>\n")
  cecho("   Sets your ship's name (used for open/launch commands).\n\n")
  cecho("<yellow>ap set enter <commands><reset>\n")
  cecho("   Configures the (comma separated) commands to execute upon entering.\n\n")
  cecho("<yellow>ap set exit <commands><reset>\n")
  cecho("   Configures the (comma separated) commands to execute upon landing.\n\n")
  cecho("<yellow>ap set hatch <code><reset>\n")
  cecho("   Sets the hatch code for your ship.\n\n")
  cecho("<yellow>ap set capacity <amount><reset>\n")
  cecho("   Sets your ship's cargo capacity for cargo hauling.\n\n")
  
  -- Ship Management Commands
  cecho("<cyan>SHIP MANAGEMENT COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap save ship<reset>\n")
  cecho("   Saves the current ship to your ship list.\n\n")
  cecho("<yellow>ap load ship <#><reset>\n")
  cecho("   Loads a ship from your saved list by its ID.\n\n")
  cecho("<yellow>ap delete ship <#><reset>\n")
  cecho("   Deletes a ship from your ship list by its ID.\n\n")
  
  -- Route Commands
  cecho("<cyan>ROUTE COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap add route <planet1,planet2,planet3><reset>\n")
  cecho("   Creates a reusable route (waypoint path for fuel stops).\n\n")
  cecho("<yellow>ap save route [name]<reset>\n")
  cecho("   Saves the current route to your route list.\n\n")
  cecho("<yellow>ap load route <#><reset>\n")
  cecho("   Loads a saved route by its ID. Use with 'ap fly route'.\n\n")
  cecho("<yellow>ap delete route <#><reset>\n")
  cecho("   Deletes a route from your route list by its ID.\n\n")
  cecho("<yellow>ap fly route<reset>\n")
  cecho("   Fly using the currently loaded route.\n\n")

  -- Manifest and Cargo Commands
  cecho("<cyan>CARGO / MANIFEST COMMANDS<reset>\n")
  cecho("<white>------------------------------------------------------------\n")
  cecho("<yellow>ap add delivery <planet>:<resource> [route#]<reset>\n")
  cecho("   Adds a delivery to current manifest. Optional route# for multi-hop.\n\n")
  cecho("<yellow>ap view manifest<reset>\n")
  cecho("   Shows detailed view of current manifest with all deliveries.\n\n")
  cecho("<yellow>ap clear manifest<reset>\n")
  cecho("   Clears the current unsaved manifest.\n\n")
  cecho("<yellow>ap clear route<reset>\n")
  cecho("   Clears the current unsaved route.\n\n")
  cecho("<yellow>ap save manifest [name]<reset>\n")
  cecho("   Saves the current manifest to your manifest list.\n\n")
  cecho("<yellow>ap load manifest <#><reset>\n")
  cecho("   Loads a saved manifest by its ID (shows full details).\n\n")
  cecho("<yellow>ap delete manifest <#><reset>\n")
  cecho("   Deletes a manifest from your manifest list by its ID.\n\n")
  cecho("<yellow>ap start cargo<reset>\n")
  cecho("   Begins a cargo run (requires ship capacity and loaded manifest).\n\n")
  cecho("<yellow>ap stop cargo<reset>\n")
  cecho("   Stops your cargo run.\n\n")
  cecho("<yellow>ap profit<reset>\n")
  cecho("   Show cargo hauling financial report.\n\n")
  cecho("<yellow>ap contraband <on/off><reset>\n")
  cecho("   Toggle contraband mode (uses buycontraband/sellcontraband commands).\n")
  cecho("   <red>⚠ WARNING: Requires level 120 Smuggling skill. May have in-game consequences.<reset>\n\n")
  cecho("<white>------------------------------------------------------------<reset>\n")
end

function autopilot.alias.status()
  debugc("autopilot.alias.status()")
  cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")

  -- Show autopilot status
  local flightEnabled = isActive("autopilot.flight", "trigger")

  cecho("<green>Flight AutoPilot:<reset> ")
  if flightEnabled then
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
    cecho("<green>destination:<reset> <cyan>".. autopilot.destination.planet.."<reset>\n")
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
    cecho("<green>Name:<reset> <yellow>"..manifestName.."<reset>\n")
    cecho("<green>Deliveries:<reset>\n")
    for i, delivery in ipairs(autopilot.currentManifest.deliveries) do
      local routeText = delivery.route and " <gray>(route #<white>"..delivery.route.."<gray>)<reset>" or " <gray>(direct)<reset>"
      cecho("<white>"..i.."<reset>. <cyan>"..delivery.planet.."<reset>:<magenta>"..delivery.resource.."<reset>"..routeText.."\n")
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
  autopilot.ship.hatch = matches.code
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
  table.insert(autopilot.ships, table.deepcopy(autopilot.ship))
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

function autopilot.alias.clearPad()
  debugc("autopilot.alias.clearPad()")
  if matches.planet == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap clear pad <planet><reset>\n")
    cecho("----------------Usage Example----------------\n")
    cecho("<yellow>ap clear pad alderaan\n")
    return
  end

  local planetKey = matches.planet:lower()
  if autopilot.preferredPads[planetKey] then
    autopilot.preferredPads[planetKey] = nil
    table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
    cecho("[<cyan>AutoPilot<reset>] Preferred pad cleared for <cyan>"..matches.planet.."<reset>\n")
  else
    cecho("[<cyan>AutoPilot<reset>] <red>No preferred pad set for <cyan>"..matches.planet.."<reset>\n")
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
  table.insert(autopilot.routes, table.deepcopy(autopilot.currentRoute))
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
  table.insert(autopilot.manifests, table.deepcopy(autopilot.currentManifest))
  table.save(getMudletHomeDir().."/AutoPilot.lua", autopilot)
  local manifestName = autopilot.currentManifest.name or "#"..#autopilot.manifests
  cecho("[<cyan>AutoPilot<reset>] Manifest saved: <yellow>"..manifestName.."<reset>\n\n")
  autopilot.displayCurrentManifest()
end

function autopilot.alias.loadShip()
  debugc("autopilot.alias.loadShip()")
  local index = tonumber(matches.index)
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

function autopilot.alias.loadRoute()
  debugc("autopilot.alias.loadRoute()")
  local index = tonumber(matches.index)
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

function autopilot.alias.loadManifest()
  debugc("autopilot.alias.loadManifest()")
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
  debugc("autopilot.alias.off()")
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
    cecho("[<cyan>AutoPilot<reset>] <red>No current manifest. Use 'ap add delivery' to create one.<reset>\n")
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
    cecho(i..". <cyan>"..delivery.planet.."<reset> ← <magenta>"..delivery.resource.."<reset>"..routeText.."\n")
  end
  cecho("----------------------------------------------\n")
end

function autopilot.alias.addDelivery()
  debugc("autopilot.alias.addDelivery()")
  if matches.planet == "" or matches.resource == "" then
    cecho("-----------------[ <cyan>AutoPilot<reset> ]----------------\n")
    cecho("<red>ap add delivery <planet>:<resource> [route#]<reset>\n")
    cecho("----------------Usage Examples----------------\n")
    cecho("<yellow>ap add delivery coruscant:food\n")
    cecho("<yellow>ap add delivery tatooine:spice 1\n")
    return
  end

  local routeIndex = matches.routeIndex and tonumber(matches.routeIndex) or nil
  local delivery = {
    planet = matches.planet:lower(),
    resource = matches.resource:lower(),
    route = routeIndex
  }

  autopilot.currentManifest = autopilot.currentManifest or {deliveries = {}}
  table.insert(autopilot.currentManifest.deliveries, delivery)

  local routeText = routeIndex and " (via route #"..routeIndex..")" or " (direct)"
  cecho("[<cyan>AutoPilot<reset>] Delivery added: <cyan>"..delivery.planet.."<reset> ← <magenta>"..delivery.resource.."<reset>"..routeText.."\n\n")

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
    cecho("[<cyan>AutoPilot<reset>] <red>No manifest loaded. Use 'ap load manifest #' or create one with 'ap add delivery'.\n")
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
  local buyCommand = autopilot.useContraband and "buycontraband" or "buycargo"
  send(buyCommand.." "..autopilot.ship.name.." '"..firstDelivery.resource.. "' "..autopilot.ship.capacity)
  cecho("[<cyan>AutoPilot<reset>] <yellow>Cargo run started<reset> | Buying <magenta>"..firstDelivery.resource.."<reset> for delivery to <cyan>"..firstDelivery.planet.."<reset>\n")
end

function autopilot.alias.stopCargo()
  debugc("autopilot.alias.stopCargo()")
  autopilot.runningCargo = false
  autopilot.alias.off()
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
  autopilot.destination.landIndex = 1
  send("land "..matches.planet)
end

function autopilot.trigger.restricted()
  debugc("autopilot.trigger.restricted()")
  autopilot.destination.landIndex = autopilot.destination.landIndex + 1
  send("land '"..autopilot.destination.planet.. "' "..autopilot.destination.pads[autopilot.destination.landIndex])
end

function autopilot.trigger.startLanding()
  debugc("autopilot.trigger.startLanding()")
  autopilot.destination.pads = {}

  -- Check if there's a preferred pad for this planet
  local preferredPad = autopilot.getPreferredPad(autopilot.destination.planet)
  if preferredPad then
    cecho("[<cyan>AutoPilot<reset>] Using preferred pad for <cyan>"..autopilot.destination.planet.."<reset>: <yellow>"..preferredPad.."<reset>\n")
    tempTimer(2, function() send("land '"..autopilot.destination.planet.."' "..preferredPad) end)
    return
  end

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

    -- No more waypoints - we're at the delivery planet, sell cargo
    cecho("[<cyan>AutoPilot<reset>] <green>Delivery destination reached:<reset> <cyan>"..delivery.planet.."<reset>\n")
    local sellCommand = autopilot.useContraband and "sellcontraband" or "sellcargo"
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

  -- Move to next delivery
  if #autopilot.currentManifest.deliveries == autopilot.deliveryIndex then
    autopilot.deliveryIndex = 1
  else
    autopilot.deliveryIndex = autopilot.deliveryIndex + 1
  end

  -- Buy cargo for next delivery
  local nextDelivery = autopilot.currentManifest.deliveries[autopilot.deliveryIndex]
  local buyCommand = autopilot.useContraband and "buycontraband" or "buycargo"
  send(buyCommand.." "..autopilot.ship.name.." '"..nextDelivery.resource.. "' "..autopilot.ship.capacity)
  cecho("[<cyan>AutoPilot<reset>] Buying <magenta>"..nextDelivery.resource.."<reset> for delivery to <cyan>"..nextDelivery.planet.."<reset>\n")
end

function autopilot.trigger.refuel()
  debugc("autopilot.trigger.refuel()")
  local nocomma = matches.cost:gsub(",","")
  local cost = tonumber(nocomma)
  autopilot.fuelCost = autopilot.fuelCost + cost
end