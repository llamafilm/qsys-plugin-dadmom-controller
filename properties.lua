table.insert(props, {
  Name = "Debug Print",
  Type = "enum",
  Choices = {"None", "Tx/Rx", "Tx", "Rx", "Function Calls", "All"},
  Value = "None"
})
table.insert(props, {
  Name = "Ref Mode",
  Type = "enum",
  Choices = {
    "Lock",
    "Trigger"
  },
  Value = "Lock"
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