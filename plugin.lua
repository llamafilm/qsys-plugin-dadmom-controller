-- DadMom Controller Plugin
-- by Elliott Balsley
-- January 2025

-- Information block for the plugin
--[[ #include "info.lua" ]]

-- Define the color of the plugin object in the design
function GetColor(props)
  return { 102, 102, 102 }
end

-- The name that will initially display when dragged into a design
function GetPrettyName(props)
  return "DadMom v" .. PluginInfo.Version
end

-- Optional function used if plugin has multiple pages
PageNames = { "Control", "Setup", "Buttons" }  --List the pages within the plugin
function GetPages(props)
  local pages = {}
  for ix,name in ipairs(PageNames) do
    table.insert(pages, {name = PageNames[ix]})
  end
  return pages
end

-- Define User configurable Properties of the plugin
function GetProperties()
  local props = {}
  --[[ #include "properties.lua" ]]
  return props
end

-- Optional function to update available properties when properties are altered by the user
function RectifyProperties(props)
  --[[ #include "rectify_properties.lua" ]]
  return props
end

-- Defines the Controls used within the plugin
function GetControls(props)
  local ctrls = {}
  --[[ #include "controls.lua" ]]
  return ctrls
end

--Layout of controls and graphics for the plugin UI to display
function GetControlLayout(props)
  local layout = {}
  local graphics = {}
  --[[ #include "layout.lua" ]]
  return layout, graphics
end

--Start event based logic
if Controls and not PluginInfo["ShowDebug"] then
  --[[ #include "runtime.lua" ]]
end
