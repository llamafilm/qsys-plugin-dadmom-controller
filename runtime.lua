-- helper function for debugging
function Dump(o, indent)
  if indent == nil then indent = 0 end
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '\n' .. string.rep(' ', indent)  .. '['..k..'] = ' .. Dump(v, indent+2) .. ', '
    end
    return s .. ' }'
  else
    return tostring(o)
  end
end -- end Dump

function Connect()
  -- initialize controls on first load and after reconnecting
  Controls.Identify.Legend = "Identify"
  Controls.Identify.IsDisabled = false
  Controls.DeviceFirmware.String = ''
  Controls.DeviceModel.String = ''
  Controls.SerialNumber.String = ''

  local control_port = 10003
  local host = Controls.IPAddress.String
  if host == "" then
    Controls.Status.Value = 4 -- missing
    Controls.Status.String = "Invalid IP"
    MOM:Disconnect()
  else
    Controls.Status.Value = 5 -- initializing
    MOM:Connect(host, control_port)
  end
end -- end Connect

function Send(msg)
  if DebugTx then print("Tx: " .. msg) end
  MOM:Write(msg .. '\r')
end -- end Send

function RectifySpeakerSelector()
  -- set button and LED states to match the current layer
  for i=1,12 do
    if i == Controls.SelectedSpeaker.Value then
      Controls['Spkr'][i].Value = 1
    else
      Controls['Spkr'][i].Value = 0
    end
  end

  for i=1,3 do
    if Controls.SelectedSpeaker.Value == Layer * 3 + i then
      Send('&sledstate,' .. i .. ',1')
    else
      Send('&sledstate,' .. i .. ',0')
    end
  end
end -- end RectifySpeakerSelector

function RectifySourceSelector()
  -- set button and LED states to match the current layer
  for i=1,12 do
    if i == Controls.SelectedSource.Value then
      Controls['Src'][i].Value = 1
    else
      Controls['Src'][i].Value = 0
    end
  end

  for i=4,6 do
    if Controls.SelectedSource.Value == Layer * 3 + i - 3 then
      Send('&sledstate,' .. i .. ',1')
    else
      Send('&sledstate,' .. i .. ',0')
    end
  end
end -- end RectifySourceSelector

function ProcessMessage(data)
  -- process messages from device
  if data == '?aliverequest' then
    Send(':aliverequest,0')
    return
  end

  local som, name, result, remainder = data:gmatch("([:!])(%a+),(%d)(.*)")()
  local params = nil
  if som == ":" then
    local msg_type = "reply"
  elseif som == "!" then
    local msg_type = "notification"
  else
    if DebugRx then print("Unknown message: " .. data) end
    return
  end

  if result ~= '0' then
    if DebugRx then print("Unsuccessful: " .. data) end
    return
  end

  if remainder then
    params = {}
    for value in remainder:gmatch("([^,]+)") do
      table.insert(params, value)
    end
  end

  if name == 'gswver' then
    Controls.DeviceFirmware.String = params[3]:sub(2,-2)

  elseif name == 'gdevinfo' then
    Controls.DeviceModel.String = params[1]:sub(2,-2)
    Controls.SerialNumber.String = params[3]:sub(2,-2)

  elseif name == 'gkeystate' then
    local key = tonumber(params[1])
    local state = params[2]
    if DebugFunction then print("Pressed key: " .. KeyNames[key] .. " state: " .. state) end

    if key == Keys.EXTERNAL then
      -- external switch not implemented
      return

    elseif key == Keys.TB then
      -- TB latching/momentary
      Send('%sledstate,' .. key .. ',' .. state)
      Controls.TB.Value = state

    -- ignore key up events for raw keys
    elseif state == '1' then
      if key == Keys.SPKR_1 or key ==  Keys.SPKR_2 or key == Keys.SPKR_3 then
        Controls.SelectedSpeaker.Value = key + Layer*3
        RectifySpeakerSelector()

      elseif key == Keys.SRC_A or key == Keys.SRC_B or key == Keys.SRC_C then
        Controls.SelectedSource.Value = key - 3 + Layer*3
        RectifySourceSelector()

      elseif key == Keys.REF then
        Controls.Level.Value = 0
        Controls.Ref.Value = (Controls.Ref.Value == 0) and 1 or 0
        Controls.Level.IsDisabled = Controls.Ref.Boolean
        HandleLevelChange(0)
        Send('%sledstate,' .. key .. ',' .. Controls.Ref.Value)

      elseif key == Keys.DIM then
        Controls.Dim.Value = (Controls.Dim.Value == 0) and 1 or 0
        Send('%sledstate,' .. key .. ',' .. math.floor(Controls.Dim.Value))

      elseif key == Keys.CUT then
        Controls.Cut.Value = (Controls.Cut.Value == 0) and 1 or 0
        Send('%sledstate,' .. key .. ',' .. math.floor(Controls.Cut.Value))

      elseif key == Keys.LAYER then
        if Layer == 3 then
          Layer = 0
        else
          Layer = Layer + 1
        end

        for i=0,3 do
          if i == Layer then
            Send("&sringledstate," .. i+28 .. ",1")
          else
            Send("&sringledstate," .. i+28 .. ",0")
          end
        end
        if DebugFunction then print("Switched to layer", Layer+1) end
        RectifySpeakerSelector()
        RectifySourceSelector()
      end
    end

  elseif name == 'grotcount' then
    local count = params[1]
    local difference = count - RotaryCount

    -- Handle 16-bit rotary encoder wrap around
    if difference > 32000 then
      difference = difference - 65535 - 1
    elseif difference < -32000 then
      difference = difference + 65535 + 1
    end

    local change = 0.5 * difference
    local new_level = Controls.Level.Value + change
    HandleLevelChange(new_level)
    RotaryCount = count -- 0 thru 65535

  elseif name == 'smaster' then
    -- initialize hardware state after we become the master
    --Send('&sclear')
    --Send('&salivetime,300')

    -- all keys are raw mode except TB
    for key=1,8 do
      Send('&skeymode,' .. key .. ',1,0')
      Send('&sledstate,' .. key .. ',1,0')
    end
    Send('&skeymode,10,1,0')
    Send('&skeymode,11,1,0')

    -- TB key is momentary/latch mode
    Send('&skeymode,9,2,' .. math.floor(LatchTimeoutMilliseconds/100))

    -- initialize all button and LED states
    for led=1,27 do
      Send("&sringledstate," .. led .. ",0")
    end

    for led=28,31 do
      if led == Layer + 28 then
        Send("&sringledstate," .. led .. ",1")
      else
        Send("&sringledstate," .. led .. ",0")
      end
    end


    Send('&sledstate,7,' .. math.floor(Controls.Ref.Value))
    Send('&sledstate,8,' .. math.floor(Controls.Dim.Value))
    Send('&sledstate,9,' .. math.floor(Controls.TB.Value))
    Send('&sledstate,10,' .. math.floor(Controls.Cut.Value))
    Send('&sledstate,11,0')

    RectifySpeakerSelector()
    RectifySourceSelector()
    HandleLevelChange(Controls.Level.Value)

    Send("%sledint," .. Controls['LedIntensity'].Value)
  end
end -- end ProcessMessage

function HandleLevelChange(level_db)
  -- Ring LED numbers 1-27
  -- State 0=off, 1=green, 2=red, 3=orange
  -- Each LED represents 2 dB

  if Properties["Ref Lock"].Value == "On" and Controls.Ref.Boolean then
    level_db = 0
  elseif Controls.Level.Value ~= 0 then
    Controls.Ref.Boolean = False
  end

  Controls.Level.Value = level_db
  -- avoid out-of-range values
  if level_db > 12 then
    level_db = 12
  elseif level_db < -40 then
    level_db = -40
  end

  -- three different cases to set ring LEDs
  local offset_db = level_db + 40 -- scale to range 0-52
  local newLedState = {}

  -- even integer shows one red dot
  if offset_db % 2 == 0 then
    if DebugFunction then print(level_db .. ' is even integer') end
    for led=1,27 do
      if (led-1)*2 == offset_db then
        newLedState[led] = '2'
      else
        newLedState[led] = '0'
      end
    end

  -- odd integers show two orange dots
  elseif offset_db % 1 == 0 then
    if DebugFunction then print(level_db .. ' is odd integer') end
    for led=1,27 do
      if (led-1)*2 == offset_db-1 then
        newLedState[led] = '3'
      elseif (led-2)*2 == offset_db-1 then
        newLedState[led] = '3'
      else
        newLedState[led] = '0'
      end
    end

  -- fractional numbers show green and orange
  else
    if DebugFunction then print(level_db .. ' is fractional') end
    local rounded = math.floor(offset_db + 0.5)
    local lowerEven, higherEven, nearestEven, orangePosition

    if rounded % 2 == 0 then
      nearestEven = rounded

      if offset_db > nearestEven then
        orangePosition = 'higher'
      else
        orangePosition = 'lower'
      end

    else
      lowerEven = rounded - 1
      higherEven = rounded + 1

      if (offset_db - lowerEven) < (higherEven - offset_db) then
        nearestEven = lowerEven
        orangePosition = 'higher'
      else
        nearestEven = higherEven
        orangePosition = 'lower'
      end
    end

    for led=1,27 do
      if (led-1)*2 == nearestEven then
        newLedState[led] = '1'
      elseif orangePosition == 'higher' and (led-1)*2 == nearestEven+2 then
        newLedState[led] = '3'
      elseif orangePosition == 'lower' and (led-1)*2 == nearestEven-2 then
        newLedState[led] = '3'
      else
        newLedState[led] = '0'
      end
    end
  end

  -- compare against previous state to change only the LEDs which differ
  for i = 1,27 do
    if RingLedState[i] ~= newLedState[i] then
      if DebugFunction then print("Turning ring LED " .. i .. " to " .. newLedState[i]) end
      Send('%sringledstate,' .. i .. "," .. newLedState[i])
    end
  end
  RingLedState = newLedState
end -- end HandleLevelChange

-- define Debug print options
DebugTx, DebugRx, DebugFunction = false, false, false
DebugPrint = Properties['Debug Print'].Value
if DebugPrint == 'Tx/Rx' then
  DebugTx, DebugRx = true, true
elseif DebugPrint == 'Tx' then
  DebugTx = true
elseif DebugPrint == 'Rx' then
  DebugRx = true
elseif DebugPrint == 'Function Calls' then
  DebugFunction = true
elseif DebugPrint == 'All' then
  DebugTx, DebugRx, DebugFunction = true, true, true
end

MOM = TcpSocket.New()
MOM.ReadTimeout = 11
MOM.EventHandler = function(sock, evt, err)
  if evt == TcpSocket.Events.Connected then
    print("TCP socket is connected")
    Controls.Status.Value = 0 -- OK
    -- Send("?ghwconf,2")
    Send('&smaster,1')
    Send('?gdevinfo')
    Send('?gswver,2')
    AliveTimer:Start(10)

  elseif evt == TcpSocket.Events.Reconnect then
    print("TCP socket is reconnecting")
    Controls.Status.Value = 5 -- initializing

  elseif evt == TcpSocket.Events.Data then
    local message = MOM:ReadLine(TcpSocket.EOL.Any)
    while (message ~= nil) do
      if DebugRx then print("Rx: " .. message ) end
      ProcessMessage(message)
      message = MOM:ReadLine(TcpSocket.EOL.Any)
    end

  elseif evt == TcpSocket.Events.Closed then
    print("TCP socket was closed by the remote end")
    Controls.Status.Value = 2 -- fault
    Controls.Status.String = "socket closed"
    AliveTimer:Stop()

  elseif evt == TcpSocket.Events.Error then
    print("TCP socket had an error:", err)
    Controls.Status.Value = 2 -- fault
    Controls.Status.String = err

  elseif evt == TcpSocket.Events.Timeout then
    print("TCP socket timed out", err)
    Controls.Status.Value = 2 -- fault
    Controls.Status.String = "socket timeout"
    AliveTimer:Stop()
  end
end

RotaryCount = 0
Layer = 0
LatchTimeoutMilliseconds = Properties['TB Latch Time'].Value:sub(1,-3)

AliveTimer = Timer.New()
AliveTimer.EventHandler = function()
  Send('?aliverequest')
end

Keys = {
  SPKR_1 = 1,
  SPKR_2 = 2,
  SPKR_3 = 3,
  SRC_A = 4,
  SRC_B = 5,
  SRC_C = 6,
  REF = 7,
  DIM = 8,
  TB = 9,
  CUT = 10,
  LAYER = 11,
  EXTERNAL = 12,
}

-- Build reverse lookup for debug output
KeyNames = {}
for name, num in pairs(Keys) do
  KeyNames[num] = name
end

RingLedState = {}
for i = 1, 27 do
    RingLedState[i] = '0'
end

Controls.IPAddress.EventHandler = function(ctl)
  Connect()
end

-- light up the LEDs for 10 seconds
Controls.Identify.EventHandler = function(ctl)
  if ctl.Value == 1 then
    ctl.IsDisabled = true
    Send("%sidentify,10")
    local identify_timer = Timer.New()
    local count = 9
    identify_timer.EventHandler = function()
      if count == 0 then
        identify_timer:Stop()
        ctl.IsDisabled = false
        ctl.Legend = "Identify"
        ctl.Value = false
      else
        ctl.Legend = tostring(count)
        count = count - 1
      end
    end
  identify_timer:Start(1)
  end
end

Controls.LedIntensity.EventHandler = function(ctl)
  Send("%sledint," .. ctl.Value)
end

Controls.Level.EventHandler = function(ctl)
  HandleLevelChange(ctl.Value)
end

-- create event handlers for each toggle button
for idx, name in ipairs(Keys) do
  if idx >= 7 and idx <= 10 then
    Controls[name].EventHandler = function(ctl)
      Send('&sledstate,' .. idx .. ',' .. math.floor(ctl.Value))
    end
  end
end

Controls.SelectedSpeaker.EventHandler = RectifySpeakerSelector
Controls.SelectedSource.EventHandler = RectifySourceSelector

Controls.Ref.EventHandler = function(ctl)
  if Properties["Ref Lock"].Value == "On" then
    Controls.Level.IsDisabled = ctl.Boolean
  end
  if ctl.Boolean then
    Controls.Level.Value = 0
    HandleLevelChange(0)
  end
  Send('&sledstate,7,' .. math.floor(ctl.Value))
end

-- when code Control is present, the Index gets pushed
for i=1,12 do
  Controls['Spkr'][i].EventHandler = function(ctl)
    Controls.SelectedSpeaker.Value = ctl.Index - 15 + (PluginInfo["ShowDebug"] and 1 or 0)
    RectifySpeakerSelector()
  end
  Controls['Src'][i].EventHandler = function(ctl)
    Controls.SelectedSource.Value = ctl.Index - 27 + (PluginInfo["ShowDebug"] and 1 or 0)
    RectifySourceSelector()
  end
end

Connect()