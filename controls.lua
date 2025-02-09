-- -- debug mode
-- table.insert(ctrls,{Name = 'code',ControlType = 'Text',UserPin = false,PinStyle = 'Input'})

table.insert (ctrls, {
  Name = 'IPAddress',
  ControlType = 'Text',
  UserPin = false,
})

table.insert (ctrls, {
  Name = 'Status',
  ControlType = 'Indicator',
  IndicatorType = 'Status',
  UserPin = true,
  PinStyle = 'Output',
})

table.insert(ctrls, {
  Name = "Level",
  ControlType = "Knob",
  PinStyle = "Both",
  ControlUnit = "dB",
  Min = -40,
  Max = 12
})

table.insert(ctrls, {
  Name = "TB",
  ControlType = "Button",
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Both",
})

table.insert(ctrls, {
  Name = "Dim",
  ControlType = "Button",
  ButtonType = "Toggle",
  PinStyle = "Both",
})

table.insert(ctrls, {
  Name = "Cut",
  ControlType = "Button",
  ButtonType = "Toggle",
  PinStyle = "Both",
})

table.insert(ctrls, {
  Name = "Ref",
  ControlType = "Button",
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Both"
})

table.insert(ctrls, {
  Name = "Spkr 1",
  ControlType = "Button",
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Both",
})
table.insert(ctrls, {
  Name = "Spkr 2",
  ControlType = "Button",
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Both",
})
table.insert(ctrls, {
  Name = "Spkr 3",
  ControlType = "Button",
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Both",
})

table.insert(ctrls, {
  Name = "Src A",
  ControlType = "Button",
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Both",
})
table.insert(ctrls, {
  Name = "Src B",
  ControlType = "Button",
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Both",
})
table.insert(ctrls, {
  Name = "Src C",
  ControlType = "Button",
  ButtonType = "Toggle",
  UserPin = true,
  PinStyle = "Both",
})

table.insert(ctrls, {
  Name = "External",
  ControlType = "Button",
  ButtonType = "Toggle",
})

table.insert(ctrls, {
  Name = "Layer",
  ControlType = "Button",
  ButtonType = "StateTrigger",
  Min = 0,
  Max = 3
})

table.insert(ctrls, {
  Name = "Identify",
  ControlType = "Button",
  ButtonType = "Toggle",
})

table.insert (ctrls, {
  Name = 'SerialNumber',
  ControlType = 'Text',
})
table.insert (ctrls, {
  Name = 'DeviceFirmware',
  ControlType = 'Text',
})
table.insert (ctrls, {
  Name = 'DeviceModel',
  ControlType = 'Text',
})
table.insert (ctrls, {
  Name = 'LedIntensity',
  ControlType = 'Knob',
  ControlUnit = 'Integer',
  Min = 1,
  Max = 3
})
