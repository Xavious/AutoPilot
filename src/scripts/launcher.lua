-- ============================================================================
-- AutoPilot Plugin Registration
-- ============================================================================

-- Register AutoPilot with the plugin dock
function autopilot.registerPlugin()
  if not (lotj and lotj.plugin and lotj.plugin.dock and lotj.plugin.dock.register) then 
    return 
  end

  lotj.plugin.dock.register("@PKGNAME@", {
  icon = getMudletHomeDir() .. '/@PKGNAME@/autopilot_icon.png',
  hoverIcon = getMudletHomeDir() .. '/@PKGNAME@/autopilot_icon_hover.gif',
  onClick = function()
    if autopilot.gui.window.hidden then
      autopilot.showGUI()
    else
      autopilot.hideGUI()
    end
  end
  })
end

autopilot.registerPlugin()

-- Register event handler to clean up when package is uninstalled
registerAnonymousEventHandler("sysUninstallPackage", function(_, packageName)
  if packageName == "@PKGNAME@" then
      autopilot.hideGUI()
      autopilot = nil
  end
end)