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
  for i=1,3 do
    print(Layer, i, Controls.SelectedSpeaker.Value)
    if Controls.SelectedSpeaker.Value == Layer * 3 + i then
      Send('&sledstate,' .. i .. ',1')
    else
      Send('&sledstate,' .. i .. ',0')
    end
  end

  for i=1,12 do
    if i == Controls.SelectedSpeaker.Value then
      Controls['Spkr'][i].Value = 1
    else
      Controls['Spkr'][i].Value = 0
    end
  end
end -- end RectifySpeakerSelector

function RectifySourceSelector()
  -- set button and LED states to match the current layer
  for i=4,6 do
    if Controls.SelectedSource.Value == Layer * 3 + i - 3 then
      Send('&sledstate,' .. i .. ',1')
    else
      Send('&sledstate,' .. i .. ',0')
    end
  end
  for i=1,12 do
    if i == Controls.SelectedSource.Value then
      Controls['Src'][i].Value = 1
    else
      Controls['Src'][i].Value = 0
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
    if DebugFunction then print("Pressed key: " .. Keys[key] .. " state: " .. state) end

    if key == 12 then
      -- external switch not implemented
      return

    elseif key == 11 then
      -- Layer
      if Layer == 3 then
        Layer = 0
      else
        Layer = Layer + 1
      end

      for i=28,31 do
        if i == state + 28 then
          Send("&sringledstate," .. i .. ",1")
        else
          Send("&sringledstate," .. i .. ",0")
        end
      end
      print("Layer", state+1)
      RectifySpeakerSelector()
      RectifySourceSelector()

    elseif key >= 1 and key <= 3 then
      -- Spkr
      if state == '1' then
        Controls.SelectedSpeaker.Value = key + (Layer*3)
        RectifySpeakerSelector()
      end
    elseif key >= 4 and key <= 6 then
      -- Src
      if state == '1' then
        Controls.SelectedSource.Value = key - 3 + (Layer*3)
        RectifySourceSelector()
      end
    elseif key == 7 then
      -- Ref
      Controls.Level.Value = 0
      Controls.Ref.Value = state
      Controls.Level.IsDisabled = Controls.Ref.Boolean
      HandleLevelChange(0)
      Send('%sledstate,' .. key .. ',' .. state)

    else
      Send('%sledstate,' .. key .. ',' .. state)
      Controls[Keys[key]].Value = state
    end

  elseif name == 'grotcount' then
    local count = params[1]
    local difference = count - RotaryCount

    -- Handle 16-bit rotary encoder wrap around
    if difference > 32000 then
      difference = difference - 65535 - 1
      print("New difference:", difference)
    elseif difference < -32000 then
      difference = difference + 65535 + 1
      print("New difference:", difference)
    end

    local change = 0.5 * difference
    local new_level = Controls.Level.Value + change
    HandleLevelChange(new_level)
    RotaryCount = count -- 0 thru 65535

  elseif name == 'smaster' then
    -- initialize hardware state after we become the master
    --Send('&sclear')
    --Send('&salivetime,300')

    -- restore previous key states after initializing key mode
    -- all keys are momentary/latch mode except layer

    -- selector keys are raw mode
    for key=1,6 do
      Send('&skeymode,' .. key .. ',1,0')
    end

    -- other keys are momentary/latch mode
    for key=7,10 do
      Send('&skeymode,' .. key .. ',2,' .. math.floor(LatchTimeoutMilliseconds/100))
    end
    Send('&skeymode,11,3,4')
    print(Dump(key_states))

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


    RectifySpeakerSelector()
    RectifySourceSelector()
    HandleLevelChange(Controls.Level.Value)

    Send("%sledint," .. Controls['LedIntensity'].Value)
    Send('&skeystate,11,' .. math.floor(Controls.Layer.Value))
  end
end -- end ProcessMessage

function HandleLevelChange(level_db)
  -- Ring LED numbers 1-27
  -- State 0=off, 1=green, 2=red, 3=orange
  -- Each LED represents 2 dB

  if Controls.Ref.Boolean then
    level_db = 0
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
MOM.ReadTimeout = 0
MOM.WriteTimeout = 0
MOM.ReconnectTimeout = 5

MOM.Connected = function(MOM)
  print("TCP socket is connected")
  Controls.Status.Value = 0 -- OK
  -- Send("?ghwconf,2")
  Send('&smaster,1')
  Send('?gdevinfo')
  Send('?gswver,2')
end

MOM.Reconnect = function(MOM)
  print("TCP socket is reconnecting")
  Controls.Status.Value = 5 -- initializing
end

MOM.Data = function(MOM)
  local message = MOM:ReadLine(TcpSocket.EOL.Any)
  while (message ~= nil) do
    if DebugRx then print("Rx: " .. message ) end
    ProcessMessage(message)
    message = MOM:ReadLine(TcpSocket.EOL.Any)
  end
end

MOM.Closed = function(MOM)
  print("TCP socket was closed by the remote end")
  Controls.Status.Value = 2 -- fault
  Controls.Status.String = "socket closed"
end

MOM.Error = function(MOM, err)
  print("TCP socket had an error:", err)
  Controls.Status.Value = 2 -- fault
  Controls.Status.String = err
end

MOM.Timeout = function(MOM, err)
  print("TCP socket timed out", err)
  Controls.Status.Value = 2 -- fault
  Controls.Status.String = "socket timeout"
end

RotaryCount = 0
Layer = 0
LatchTimeoutMilliseconds = Properties['Button Latch Timeout'].Value:sub(1,-3)

Keys = {
  'Spkr 1', -- 1
  'Spkr 2', -- 2
  'Spkr 3', -- 3
  'Src A',  -- 4
  'Src B',  -- 5
  'Src C',  -- 6
  'Ref',    -- 7
  'Dim',    -- 8
  'TB',     -- 9
  'Cut',    -- 10
  'Layer',  -- 11
  'External'-- 12
}

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
      Send('&skeystate,' .. idx .. ',' .. math.floor(ctl.Value))
    end
  end
end

Controls.SelectedSpeaker.EventHandler = RectifySpeakerSelector
Controls.SelectedSource.EventHandler = RectifySourceSelector

Controls.Ref.EventHandler = function(ctl)
  Controls.Level.IsDisabled = ctl.Boolean
  if ctl.Boolean then
    Controls.Level.Value = 0
    HandleLevelChange(0)
  end
  Send('&sledstate,7,' .. math.floor(ctl.Value))
  Send('&skeystate,7,' .. math.floor(ctl.Value))
end

for i=1,12 do
  Controls['Spkr'][i].EventHandler = function(ctl)
    Controls.SelectedSpeaker.Value = ctl.Index - 16
    RectifySpeakerSelector()
  end
  Controls['Src'][i].EventHandler = function(ctl)
    Controls.SelectedSource.Value = ctl.Index - 28
    RectifySourceSelector()
  end
end

Connect()