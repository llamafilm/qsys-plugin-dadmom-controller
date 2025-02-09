-- -- debug mode
-- layout['code']={PrettyName='code',Style='None'}

local DadMomPhoto = "--[[ #encode "dadmom.jpg" ]]"

local CurrentPage = PageNames[props["page_index"].Value]
if CurrentPage == "Control" then
  table.insert(graphics,{
    Type = "Image",
    Image = DadMomPhoto,
    Position = {0,0},
    Size = {500,283}
  })
  layout['Level'] = {
    Position = {335,107},
    Size = {59,53},
    Style = 'Knob'
  }
  layout['TB'] = {
    Position = {254,208},
    Size = {32,32},
  }
  layout['Dim'] = {
    Position = {442,208},
    Size = {32,32},
  }
  layout['Cut'] = {
    Position = {442,39},
    Size = {32,32},
  }
  layout['Ref'] = {
    Position = {254,39},
    Size = {32,32},
  }
  layout['Spkr 1'] = {
    Position = {26,123},
    Size = {32,32},
  }
  layout['Spkr 2'] = {
    Position = {100,123},
    Size = {32,32},
  }
  layout['Spkr 3'] = {
    Position = {174,123},
    Size = {32,32},
  }
  layout['Src A'] = {
    Position = {26,188},
    Size = {32,32},
  }
  layout['Src B'] = {
    Position = {100,188},
    Size = {32,32},
  }
  layout['Src C'] = {
    Position = {174,188},
    Size = {32,32},
  }
  layout['Layer'] = {
    Position = {174,57},
    Size = {32,32},
    UnlinkOffColor = true,
    Color = {124,124,124},
    OffColor = {124,124,124},
    FontSize = 10
  }

elseif CurrentPage == "Setup" then
  table.insert(graphics, {
    Type = 'GroupBox',
    Position = { 0, 0 },
    Size = { 304, 226 },
    CornerRadius = 8
  })
  table.insert(graphics, {
    Type = 'Header',
    Text = "CONNECTION SETUP",
    Position = { 13, 13 },
    Size = { 279, 6 },
    FontSize = 14,
  })

  table.insert(graphics,{
    Type = "Label",
    Text = "IP:",
    Position = { 5,34 },
    Size = { 67,20 },
    FontSize = 14,
    HTextAlign = "Right",
  })
  layout["IPAddress"] = {
    Style = "Text",
    Position = { 84,34 },
    Size = { 120, 20 },
  }
  layout["Identify"] = {
    Style = "Button",
    Position = { 213,34 },
    Size = { 72, 20 },
    Legend = "Identify",
    CornerRadius = 2,
    StrokeWidth = 1,
    Margin = 0,
    FontSize = 12,
    UnlinkOffColor = true,
    OffColor = { 194,194,194 },
    Color = { 0,231,30 }
  }

  table.insert(graphics,{
    Type = "Label",
    Text = "Status",
    Position = { 20,64 },
    Size = { 52,20 },
    FontSize = 14,
    HTextAlign = "Right",
  })
  layout['Status'] = {
    Position = { 84,64 },
    Size = { 201, 20 }
  }

  table.insert(graphics, {
    Type = 'Header',
    Text = "DEVICE INFORMATION",
    Position = { 13, 105 },
    Size = { 279, 6 },
    FontSize = 14,
  })

    table.insert(graphics,{
      Type = "Label",
      Text = "Model",
      Position = { 25,124 },
      Size = { 103,16 },
      FontSize = 10,
    })
    layout['DeviceModel'] = {
      Position = { 25,140 },
      Size = { 103, 20 },
      IsReadOnly = true
    }

    table.insert(graphics,{
      Type = "Label",
      Text = "Software Version",
      Position = { 177,124 },
      Size = { 103,16 },
      FontSize = 10,
    })
    layout['DeviceFirmware'] = {
      Position = { 177,140 },
      Size = { 103, 20 },
      IsReadOnly = true
    }

    table.insert(graphics,{
      Type = "Label",
      Text = "Serial Number",
      Position = { 25,171 },
      Size = { 103,16 },
      FontSize = 10,
    })
    layout['SerialNumber'] = {
      Position = { 25,187 },
      Size = { 103, 20 },
      IsReadOnly = true
    }

    table.insert(graphics,{
      Type = "Label",
      Text = "LED Intensity",
      Position = { 177,171 },
      Size = { 103,16 },
      FontSize = 10
    })
    layout['LedIntensity'] = {
      Position = { 177,187 },
      Style = "ComboBox",
      Size = { 103, 20 },
      Fill = { 255,255,255 }
    }

  table.insert(graphics, {
    Type = 'Label',
    Text = "Version " ..PluginInfo.BuildVersion,
    Position = { 0,210 },
    Size = { 67,20 },
    FontSize = 8,
    HTextAlign = "Left"
  })

end


-- ## Extra Controls
-- Layer button
-- External switch

-- ## Messages
-- - Alive request
-- - Set aliveTime
-- - Restart device
-- - Clear settings
-- - Load application mode
-- - Identify device
-- - Get device information
-- - Get SW version
-- - Set master mode
-- - Set key mode
-- - Set key state
-- - Get key state
-- - Set ring LED state
-- - Set LED intensity
-- - Get rotary switch count
