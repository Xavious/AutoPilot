# AutoPilot

## Description
A Mudlet package for Lotj that automates space travel and cargo hauling. 

This has been created using Muddler's development paradigm https://github.com/demonnic/muddler

If you just want to download the package you can grab the latest release from https://github.com/Xavious/AutoPilot/releases

## Instructions

All commands start with `ap` for (AutoPilot). To get a list of commands use:

```
ap help
```

### Status and on/off Switch

#### Check Ship Values

You can check the current settings for your ship using this command

```
ap status
```

#### AutoPilot Off

Serves as a trigger kill switch. Disables all AutoPilot triggers for travel and cargo.

```
ap off
```

#### AutoPilot On

Enable all AutoPilot triggers. This serves to re-engage the AutoPilot and pick back up where you left off if you had to use the kill switch `ap off`. Will require you to manually trigger the next trigger in the sequence to get things moving again.

```
ap on
```

### Automated Travel
**Note:** This will not work without initial setup detailed in the next section.

Fly to a single planet, or set multiple planets as waypoints with a comma separated list. You can use spaces or omit them.

```
ap fly <planet/planets>
```

**Examples**

This will attempt to fly to the planet from your current location

```
ap fly tatooine
```

Will fly to each planet in the list starting with Ithor and eventually finishing on Coruscant. 
```
ap fly ithor,kashyyyk,coruscant
ap fly ithor, kashyyyk, coruscant
```


### Setting up your ship

To use the most basic feature of automating a flight path, you only need to set the ship's **name** if it's a single seater ship. If you need to walk to the cockpit of your ship, then you'll need to set the **enter** and **exit** path as well.

If you want to run cargo you need to set the **capacity**, and if it's a rented/borrowed ship you'll need to set the **hatch** code.

#### Ship Name

```
ap set ship <name>
```

#### Ship Enter Path

Set the ship's comma separated path to cockpit after entry. You can use spaces, or omit them.

```
ap set enter <path>
```

**Examples**

```
ap set enter n,n,n,n
ap set enter n, n, n, n
```

#### Ship Exit Path

Set the ship's comma separated path to the hatch after landing. Same rules apply

```
ap set exit <path>
```

**Examples**

```
ap set exit s,s,s,s
ap set exit s, s, s, s
```

#### Ship Hatch

Set the ships's hatch code.

```
ap set hatch <code>
```

#### Ship Capacity

Set the ship's cargo capacity

```
ap set capacity <amount>
```

#### Save Ship Template

Saves the previously set values to a template file.

```
ap save ship
```

#### Load Ship Template

Loads saved ship template. Using the command without a number will list the available templates.

Shows a list of templates

```
ap load ship
```

Load a specific ship

```
ap load ship <#>
```

### Running Cargo

This part could probably use some refinement for clarity, but it's really simple to understand with some examples.The basic premise is that a **stop** is a planet/resouce combination where the **planet** is paired with the **resource** you want to sell there, and a **route** is comprised of multiple stops. 

AutoPilot will loop through every **stop** in a **route** using "first in, first out" logic. 

**You should start the route with an empty cargo hold.**

#### Add Stop

This command is used to add a **stop** to the current **route**

```
ap add stop <planet>:<resource>
```

**Examples**

This example assumes a 2 planet route where you're starting on Corellia. When you start the cargo automation it will fill the cargo holds with electronics and plot a course to Coruscant. Upon landing on Coruscant it would sell the electronics, purchase food, then plot a course for Corellia and sell the food there. At this point a full loop would be complet and it would start again from the beginning of the route.

```
ap add stop coruscant:electronics
ap add stop corellia:food
```

#### Start Cargo

Start the cargo loop once a ship and route have been configured. This will reset **expense**, **revenue**, **fuel cost**, **start time**, and **elapsed time** variables.

```
ap start cargo
```

#### Stop Cargo

Disables cargo running and turns of all AutoPilot triggers.

```
ap stop cargo
```

#### Save Route

Saves a cargo route values to a template file.

```
ap save route
```


#### Load Route

Loads a previously saved cargo route. Using the command without a number will list the available routes

Show a list of routes

```
ap load route
```

Load a specific route

```
ap load route <#>
```

#### Cargo Report

Displays the total expenditure, revenue, and fuel costs with a start time, elapsed time, and credits/hour summary.

```
ap profit
```
