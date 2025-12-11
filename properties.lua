table.insert(props, {
  Name = "Debug Print",
  Type = "enum",
  Choices = {"None", "Tx/Rx", "Tx", "Rx", "Function Calls", "All"},
  Value = "None"
})
table.insert(props, {
  Name = "Ref Lock",
  Type = "enum",
  Choices = {
    "Off",
    "On"
  },
  Value = "On"
})
table.insert(props, {
  Name = "TB Latch Time",
  Type = "enum",
  Choices = {
    "100ms",
    "200ms",
    "300ms",
    "400ms",
    "500ms"
    },
  Value = "200ms",
})