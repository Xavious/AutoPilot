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

autopilot.gui.footer:echo("AutoPilot v1.0 - Use tab buttons to navigate")

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

  -- Build route options string
  local routeOptions = "0 (Direct)"
  if autopilot.routes and #autopilot.routes > 0 then
    for i, route in ipairs(autopilot.routes) do
      routeOptions = routeOptions .. ", " .. i .. " (" .. (route.name or "Route #" .. i) .. ")"
    end
  end

  -- Get the onSave callback from current view if it exists
  local onSave = autopilot.gui.currentView and autopilot.gui.currentView.onSave

  autopilot.showForm(
    isEdit and "EDIT DELIVERY" or "ADD DELIVERY",
    {
      {name = "planet", label = "Planet", value = delivery.planet or ""},
      {name = "resource", label = "Resource", value = delivery.resource or ""},
      {name = "route", label = "Route (0 for direct)", value = delivery.route and tostring(delivery.route) or "0"}
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

      -- Parse route (0 means direct/no route)
      local routeNum = tonumber(values.route) or 0
      local newDelivery = {
        planet = values.planet,
        resource = values.resource
      }
      if routeNum > 0 then
        newDelivery.route = routeNum
      end

      -- Call the save callback
      if onSave then
        onSave(newDelivery, deliveryIndex)
      end
    end
  )

  -- Show available routes as hint at bottom of form
  cecho("\n[<cyan>AutoPilot<reset>] Available routes: " .. routeOptions .. "\n")
end

-- Refresh manifest editor display
function autopilot.refreshManifestEditor()
  if not autopilot.gui.manifestEditor or not autopilot.gui.workingManifest then
    return
  end

  local manifest = autopilot.gui.workingManifest
  local deliveries = manifest.deliveries or {}
  local console = autopilot.gui.manifestEditor.displayConsole

  -- Clear and update the display console
  console:clear()

  -- Manifest name section with edit button
  console:cecho("<white>Manifest Name: <cyan>" .. (manifest.name or "(Not Set)") .. "  ")
  console:fg("yellow")
  console:echoLink("[Edit Name]", [[autopilot.editManifestName()]], "Edit manifest name", true)
  console:resetFormat()
  console:cecho("\n\n<cyan>═══════════════════════════════════════════════════════════════\n\n")

  -- Deliveries section
  if #deliveries == 0 then
    console:cecho("<yellow>No deliveries yet. Click [+ Add Delivery] below to add one.\n")
  else
    console:cecho("<white>Deliveries:\n\n")
    for i, delivery in ipairs(deliveries) do
      local routeText = delivery.route and " <gray>(route #" .. delivery.route .. ")" or " <gray>(direct)"
      console:cecho(string.format("<white>%d. <cyan>%s <white>→ <yellow>%s%s  ",
        i, delivery.planet or "?", delivery.resource or "?", routeText))

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

      autopilot.gui.workingManifest.name = values.name
      cecho("\n[<cyan>AutoPilot<reset>] Manifest name updated.\n")
    end,
    function()
      -- onCancel callback - just refresh the manifest editor
      tempTimer(0.05, function()
        if autopilot.gui.manifestEditor then
          autopilot.refreshManifestEditor()
        end
      end)
    end
  )
end

-- Add delivery to working manifest
function autopilot.addDeliveryToManifest()
  autopilot.showDeliveryDialog(nil, nil, function(newDelivery, deliveryIndex)
    -- Ensure working manifest still exists
    if not autopilot.gui.workingManifest then
      cecho("\n[<cyan>AutoPilot<reset>] <red>Error: No active manifest to add delivery to.\n")
      return
    end

    table.insert(autopilot.gui.workingManifest.deliveries, newDelivery)

    -- After popView brings us back, re-render the manifest editor
    tempTimer(0.1, function()
      if autopilot.gui.currentView and autopilot.gui.currentView.type == "edit_manifest" then
        autopilot.showManifestEditor(autopilot.gui.currentView.index)
      end
    end)

    cecho("\n[<cyan>AutoPilot<reset>] Delivery added.\n")
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

    -- Update the delivery at the correct index
    autopilot.gui.workingManifest.deliveries[deliveryIndex] = updatedDelivery

    -- After popView brings us back, re-render the manifest editor
    tempTimer(0.1, function()
      if autopilot.gui.currentView and autopilot.gui.currentView.type == "edit_manifest" then
        autopilot.showManifestEditor(autopilot.gui.currentView.index)
      end
    end)

    cecho("\n[<cyan>AutoPilot<reset>] Delivery updated.\n")
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

  -- Only create a new working manifest if one doesn't exist
  -- This preserves edits when returning from sub-forms
  if not autopilot.gui.workingManifest then
    local manifest = manifestIndex and table.deepcopy(autopilot.manifests[manifestIndex]) or {name = "", deliveries = {}}
    autopilot.gui.workingManifest = manifest
    autopilot.gui.workingManifestIndex = manifestIndex
  end

  -- Switch to form container
  autopilot.gui.content:hide()
  autopilot.gui.formContainer:show()

  -- Title label
  local titleLabel = Geyser.Label:new({
    x = 0, y = 0,
    width = "100%", height = 60
  }, autopilot.gui.formContainer)
  titleLabel:setStyleSheet([[
    background-color: transparent;
    color: ]]..autopilot.gui.colors.text..[[;
    font-size: 14pt;
    font-weight: bold;
    qproperty-alignment: 'AlignHCenter|AlignVCenter';
  ]])
  titleLabel:echo(isEdit and "EDIT MANIFEST" or "ADD MANIFEST")

  -- Main display console (for manifest name and delivery list)
  local displayConsole = Geyser.MiniConsole:new({
    x = 20, y = 80,
    width = "94%", height = 400,
    autoWrap = true,
    scrollBar = true
  }, autopilot.gui.formContainer)
  displayConsole:setColor(47, 49, 54)

  -- Add Delivery button
  local addBtn = Geyser.Label:new({
    x = 20, y = 500,
    width = 150, height = 40
  }, autopilot.gui.formContainer)
  addBtn:setStyleSheet([[
    background-color: #2d5016;
    border: 1px solid #4a7c29;
    color: #a3d977;
    font-size: 12pt;
    font-weight: bold;
    qproperty-alignment: 'AlignCenter';
  ]])
  addBtn:echo("[+ Add Delivery]")
  addBtn:setClickCallback(function() autopilot.addDeliveryToManifest() end)

  -- Save button
  local saveBtn = Geyser.Label:new({
    x = 190, y = 500,
    width = 120, height = 40
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
  end)

  -- Cancel button
  local cancelBtn = Geyser.Label:new({
    x = 330, y = 500,
    width = 120, height = 40
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
    autopilot.gui.manifestEditor = nil
    autopilot.gui.workingManifest = nil
    cecho("\n[<cyan>AutoPilot<reset>] Manifest editing cancelled.\n")
    autopilot.popView()
  end)

  -- Store references with UI elements
  autopilot.gui.manifestEditor = {
    displayConsole = displayConsole,
    isEdit = isEdit,
    manifestIndex = manifestIndex,
    uiElements = {titleLabel, displayConsole, addBtn, saveBtn, cancelBtn}
  }

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
  autopilot.gui.manifestEditor = nil
  -- NOTE: Don't clear workingManifest here - it's needed by manifest editor callbacks
  -- It will be cleared when the manifest editor itself is closed
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
    x = 0, y = 0,
    width = "100%", height = 100
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
  local yPos = 120
  for i, field in ipairs(fields) do
    -- Label
    local label = Geyser.Label:new({
      x = 20, y = yPos,
      width = 150, height = 30
    }, autopilot.gui.formContainer)
    label:setStyleSheet([[
      background-color: transparent;
      color: ]]..autopilot.gui.colors.text..[[;
      font-size: 12pt;
      qproperty-alignment: 'AlignVCenter|AlignLeft';
    ]])
    label:echo(field.label .. ":")
    table.insert(autopilot.gui.formData.uiElements, label)

    -- Input field
    local input = Geyser.CommandLine:new({
      x = 180, y = yPos,
      width = "60%", height = 30
    }, autopilot.gui.formContainer)
    if field.value and field.value ~= "" then
      input:print(field.value)
    end

    autopilot.gui.formData.inputs[field.name] = input
    table.insert(autopilot.gui.formData.uiElements, input)
    yPos = yPos + 45
  end

  -- Save button
  local saveBtn = Geyser.Label:new({
    x = 20, y = yPos + 20,
    width = 120, height = 40
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
    x = 160, y = yPos + 20,
    width = 120, height = 40
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
    autopilot.showManifestEditor(autopilot.gui.currentView.index)
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

  if not autopilot.ships or #autopilot.ships == 0 then
    autopilot.gui.content:cecho("<yellow>No ships saved yet.\n\n")
    autopilot.gui.content:cecho("<white>Use <cyan>ap save ship<white> after setting ship details to save a ship configuration.\n")
    return
  end

  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n")
  autopilot.gui.content:cecho("<yellow>                        SAVED SHIPS\n")
  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n\n")

  -- Add New button
  autopilot.gui.content:cecho("<white>")
  autopilot.gui.content:fg("green")
  autopilot.gui.content:echoLink("[+ Add New Ship]", [[autopilot.showShipDialog()]], "Click to add a new ship", true)
  autopilot.gui.content:resetFormat()
  autopilot.gui.content:cecho("\n\n")

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

  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n")
  autopilot.gui.content:cecho("<white>Click <green>[+ Add New Ship]<white> to add, <yellow>[Edit]<white> to modify, or <red>[Delete]<white> to remove.\n")
end

function autopilot.displayRoutesTab()
  autopilot.cleanupFormUI()
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()
  autopilot.gui.content:clear()

  if not autopilot.routes or #autopilot.routes == 0 then
    autopilot.gui.content:cecho("<yellow>No routes saved yet.\n\n")
    autopilot.gui.content:cecho("<white>Use <cyan>ap add route <planets><white> to create a route, then <cyan>ap save route<white> to save it.\n")
    return
  end

  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n")
  autopilot.gui.content:cecho("<yellow>                        SAVED ROUTES\n")
  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n\n")

  -- Add New button
  autopilot.gui.content:cecho("<white>")
  autopilot.gui.content:fg("green")
  autopilot.gui.content:echoLink("[+ Add New Route]", [[autopilot.showRouteDialog()]], "Click to add a new route", true)
  autopilot.gui.content:resetFormat()
  autopilot.gui.content:cecho("\n\n")

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

  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n")
  autopilot.gui.content:cecho("<white>Click <green>[+ Add New Route]<white> to add, <yellow>[Edit]<white> to modify, or <red>[Delete]<white> to remove.\n")
end

function autopilot.displayManifestsTab()
  autopilot.cleanupFormUI()
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()
  autopilot.gui.content:clear()

  if not autopilot.manifests or #autopilot.manifests == 0 then
    autopilot.gui.content:cecho("<yellow>No manifests saved yet.\n\n")
    autopilot.gui.content:cecho("<white>Use <cyan>ap add delivery <planet> <resource><white> to create deliveries, then <cyan>ap save manifest<white> to save.\n")
    return
  end

  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n")
  autopilot.gui.content:cecho("<yellow>                      SAVED MANIFESTS\n")
  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n\n")

  -- Add New button
  autopilot.gui.content:cecho("<white>")
  autopilot.gui.content:fg("green")
  autopilot.gui.content:echoLink("[+ Add New Manifest]", [[autopilot.showManifestDialog()]], "Click to add a new manifest", true)
  autopilot.gui.content:resetFormat()
  autopilot.gui.content:cecho("\n\n")

  for i, manifest in ipairs(autopilot.manifests) do
    local manifestName = manifest.name or ("Manifest #" .. i)
    autopilot.gui.content:cecho(string.format("<white>[<yellow>%d<white>] <cyan>%s\n", i, manifestName))

    if manifest.deliveries and #manifest.deliveries > 0 then
      autopilot.gui.content:cecho("    <white>Deliveries:\n")
      for j, delivery in ipairs(manifest.deliveries) do
        local routeText = delivery.route and " <gray>(route #" .. delivery.route .. ")" or " <gray>(direct)"
        autopilot.gui.content:cecho(string.format("      <green>%s <white>→ <yellow>%s%s\n",
          delivery.planet or "?", delivery.resource or "?", routeText))
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

  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n")
  autopilot.gui.content:cecho("<white>Click <green>[+ Add New Manifest]<white> to add, <cyan>[Edit]<white> to modify, or <red>[Delete]<white> to remove.\n")
end

function autopilot.displayPadsTab()
  autopilot.cleanupFormUI()
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()
  autopilot.gui.content:clear()

  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n")
  autopilot.gui.content:cecho("<yellow>                   PREFERRED LANDING PADS\n")
  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n\n")

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

  autopilot.gui.content:cecho("\n<cyan>═══════════════════════════════════════════════════════════════\n")
  autopilot.gui.content:cecho(string.format("<white>Total: <yellow>%d<white> preferred pads configured\n", padCount))
  autopilot.gui.content:cecho("<white>Click <green>[+ Add New Pad]<white> to add, <yellow>[Edit]<white> to modify, or <red>[Delete]<white> to remove.\n")
end

function autopilot.displayStatusTab()
  autopilot.cleanupFormUI()
  autopilot.gui.formContainer:hide()
  autopilot.gui.content:show()
  autopilot.gui.content:clear()

  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n")
  autopilot.gui.content:cecho("<yellow>                    AUTOPILOT STATUS\n")
  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n\n")

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
      local routeText = delivery.route and " <gray>(route #" .. delivery.route .. ")" or " <gray>(direct)"
      autopilot.gui.content:cecho(string.format("    <green>%s <white>→ <yellow>%s%s\n",
        delivery.planet or "?", delivery.resource or "?", routeText))
    end
    autopilot.gui.content:cecho("\n")
  else
    autopilot.gui.content:cecho("  <yellow>No manifest loaded\n\n")
  end

  -- Autopilot status
  autopilot.gui.content:cecho("<white>Autopilot Status:\n")
  if autopilot.runningCargo then
    autopilot.gui.content:cecho("  <green>● RUNNING CARGO<white>\n")
  else
    autopilot.gui.content:cecho("  <red>○ Idle<white>\n")
  end
  autopilot.gui.content:cecho("\n")

  -- Settings
  autopilot.gui.content:cecho("<white>Settings:\n")
  local contrabandStatus = autopilot.useContraband and "<green>Enabled" or "<red>Disabled"
  autopilot.gui.content:cecho(string.format("  Contraband: %s<white>\n", contrabandStatus))
  autopilot.gui.content:cecho("\n")

  -- Statistics
  autopilot.gui.content:cecho("<cyan>═══════════════════════════════════════════════════════════════\n")
  autopilot.gui.content:cecho("<white>Saved Configurations:\n")
  autopilot.gui.content:cecho(string.format("  Ships: <yellow>%d<white>  |  Routes: <yellow>%d<white>  |  Manifests: <yellow>%d<white>  |  Pads: <yellow>%d\n",
    autopilot.ships and #autopilot.ships or 0,
    autopilot.routes and #autopilot.routes or 0,
    autopilot.manifests and #autopilot.manifests or 0,
    autopilot.preferredPads and table.size(autopilot.preferredPads) or 0))
end