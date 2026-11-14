-- GCI Grass Farm V6 | full-field fast sweeps
if _G.GCIGrassCleanup then pcall(_G.GCIGrassCleanup) end
if _G.GCIGrassStop then pcall(_G.GCIGrassStop) end
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local old=pg:FindFirstChild("GCIGrassCollector")
if old then old:Destroy() end
pcall(function() RunService:UnbindFromRenderStep("GCIGrassCamera") end)

local MIN_X,MAX_X=-63,35
local MIN_Z,MAX_Z=-19,79
local CENTER_X,CENTER_Z=-14,30.5
local PASSES=7 -- large hitbox: roughly 16 studs between lanes
local CYCLE_SECONDS=2
local RETURN_SPEED=65
local DROP_SPEED=10
local RISE_HEIGHT=9

local running=false
local serial=0
local cleaned=false
local movement=nil
local listeners={}
local savedSpeed=nil
local floorY=nil
local points={}
for i=0,PASSES-1 do
 local x=MIN_X+(MAX_X-MIN_X)*i/(PASSES-1)
 if i%2==0 then
  points[#points+1]=Vector3.new(x,0,MIN_Z)
  points[#points+1]=Vector3.new(x,0,MAX_Z)
 else
  points[#points+1]=Vector3.new(x,0,MAX_Z)
  points[#points+1]=Vector3.new(x,0,MIN_Z)
 end
end
-- Connect lanes in the same continuous path
local function root()
 local c=player.Character
 return c and c:FindFirstChild("HumanoidRootPart")
end
local function hum()
 local c=player.Character
 return c and c:FindFirstChildOfClass("Humanoid")
end
local function track(c) listeners[#listeners+1]=c return c end
local function stopMotion()
 if movement then movement:Disconnect() movement=nil end
end
local function halt()
 serial+=1
 running=false
 stopMotion()
 local r=root()
 if r then
  r.AssemblyLinearVelocity=Vector3.zero
  r.AssemblyAngularVelocity=Vector3.zero
 end
 local h=hum()
 if h and savedSpeed then h.WalkSpeed=savedSpeed end
 savedSpeed=nil
end
local gui=Instance.new("ScreenGui")
gui.Name="GCIGrassCollector"
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=pg
local panel=Instance.new("Frame")
panel.Size=UDim2.fromOffset(162,43)
panel.Position=UDim2.new(.5,-81,.25,0)
panel.BackgroundColor3=Color3.fromRGB(20,20,24)
panel.BorderSizePixel=0
panel.Active=true
panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
local label=Instance.new("TextLabel")
label.Size=UDim2.new(1,-62,1,0)
label.Position=UDim2.fromOffset(12,0)
label.BackgroundTransparency=1
label.Text="Grass Farm"
label.TextColor3=Color3.fromRGB(240,240,245)
label.Font=Enum.Font.GothamMedium
label.TextSize=12
label.TextXAlignment=Enum.TextXAlignment.Left
label.Parent=panel
local switch=Instance.new("Frame")
switch.Size=UDim2.fromOffset(39,22)
switch.Position=UDim2.new(1,-50,.5,-11)
switch.BackgroundColor3=Color3.fromRGB(65,65,72)
switch.BorderSizePixel=0
switch.Parent=panel
Instance.new("UICorner",switch).CornerRadius=UDim.new(1,0)
local knob=Instance.new("Frame")
knob.Size=UDim2.fromOffset(16,16)
knob.Position=UDim2.fromOffset(3,3)
knob.BackgroundColor3=Color3.new(1,1,1)
knob.BorderSizePixel=0
knob.Parent=switch
Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
local drag=Instance.new("TextButton")
drag.Size=UDim2.fromScale(1,1)
drag.BackgroundTransparency=1
drag.Text=""
drag.AutoButtonColor=false
drag.ZIndex=4
drag.Parent=panel
local toggle=Instance.new("TextButton")
toggle.Size=switch.Size
toggle.Position=switch.Position
toggle.BackgroundTransparency=1
toggle.Text=""
toggle.AutoButtonColor=false
toggle.ZIndex=5
toggle.Parent=panel
local function paint()
 TweenService:Create(switch,TweenInfo.new(.15),{BackgroundColor3=running and Color3.fromRGB(65,190,115) or Color3.fromRGB(65,65,72)}):Play()
 TweenService:Create(knob,TweenInfo.new(.15),{Position=running and UDim2.fromOffset(20,3) or UDim2.fromOffset(3,3)}):Play()
end
local function travel(destination,speed,id)
 local r=root()
 if not r or id~=serial then return false end
 local start=r.Position
 local duration=math.max((destination-start).Magnitude/speed,.025)
 local elapsed=0
 local done=false
 stopMotion()
 movement=RunService.Heartbeat:Connect(function(dt)
  if id~=serial or not r.Parent then done=true return end
  elapsed+=dt
  local a=math.min(elapsed/duration,1)
  r.CFrame=CFrame.new(start:Lerp(destination,a))*r.CFrame.Rotation
  r.AssemblyLinearVelocity=Vector3.zero
  if a>=1 then done=true end
 end)
 while not done and id==serial do RunService.Heartbeat:Wait() end
 stopMotion()
 return id==serial
end
local function start()
 halt()
 local r=root()
 if not r then return end
 running=true
 serial+=1
 local id=serial
 floorY=r.Position.Y -- preserve standing height, do not float above it
 local h=hum()
 if h then savedSpeed=h.WalkSpeed end
 local cam=workspace.CurrentCamera
 if cam then
  cam.CameraType=Enum.CameraType.Custom
  if h then cam.CameraSubject=h end
 end
 paint()
 task.spawn(function()
  local route={}
  route[1]=r.Position
  for _,p in ipairs(points) do route[#route+1]=Vector3.new(p.X,floorY,p.Z) end
  -- use total route length to set uniform speed for ~2s sweep
  local length=0
  for i=2,#route do length+=(route[i]-route[i-1]).Magnitude end
  local speed=length/CYCLE_SECONDS
  while running and id==serial do
   for i=2,#route do
    if not running or id~=serial then return end
    if not travel(route[i],speed,id) then return end
   end
   -- reverse route to avoid a large teleport back to start
   for i=#route-1,2,-1 do
    if not running or id~=serial then return end
    if not travel(route[i],speed,id) then return end
   end
  end
 end)
end
local function stop()
 halt()
 paint()
 local id=serial
 task.spawn(function()
  local r=root()
  if not r then return end
  local y=math.max(r.Position.Y,(floorY or r.Position.Y)+RISE_HEIGHT)
  local function easeTo(pos,speed)
   if id~=serial then return false end
   local rr=root()
   if not rr then return false end
   local duration=math.max((rr.Position-pos).Magnitude/speed,.08)
   local tween=TweenService:Create(rr,TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=CFrame.new(pos)*rr.CFrame.Rotation})
   local cancelled=false
   local conn
   conn=RunService.Heartbeat:Connect(function()
    if id~=serial then cancelled=true tween:Cancel() end
   end)
   tween:Play()
   local state=tween.Completed:Wait()
   conn:Disconnect()
   return not cancelled and state==Enum.PlaybackState.Completed and id==serial
  end
  if not easeTo(Vector3.new(r.Position.X,y,r.Position.Z),RETURN_SPEED) then return end
  if not easeTo(Vector3.new(CENTER_X,y,CENTER_Z),RETURN_SPEED) then return end
  easeTo(Vector3.new(CENTER_X,floorY or -27,CENTER_Z),DROP_SPEED)
 end)
end
local dragging,moved,onToggle=false,false,false
local origin,initial,activeInput
local function begin(input,isToggle)
 if dragging then return end
 if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
 dragging=true moved=false onToggle=isToggle
 origin=input.Position initial=panel.Position activeInput=input
end
track(drag.InputBegan:Connect(function(i) begin(i,false) end))
track(toggle.InputBegan:Connect(function(i) begin(i,true) end))
track(UIS.InputChanged:Connect(function(i)
 if not dragging then return end
 if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
 if activeInput.UserInputType==Enum.UserInputType.Touch and i~=activeInput then return end
 local delta=i.Position-origin
 if delta.Magnitude>7 then moved=true end
 if moved then panel.Position=UDim2.new(initial.X.Scale,initial.X.Offset+delta.X,initial.Y.Scale,initial.Y.Offset+delta.Y) end
end))
track(UIS.InputEnded:Connect(function(i)
 if not dragging then return end
 if i.UserInputType~=activeInput.UserInputType then return end
 if activeInput.UserInputType==Enum.UserInputType.Touch and i~=activeInput then return end
 local click=onToggle and not moved
 dragging=false activeInput=nil
 if click then if running then stop() else start() end end
end))
local function cleanup()
 if cleaned then return end
 cleaned=true
 halt()
 for _,c in ipairs(listeners) do c:Disconnect() end
 if gui.Parent then gui:Destroy() end
end
_G.GCIGrassCleanup=cleanup
_G.GCIGrassStop=cleanup
print("GCI Grass Farm V6 loaded")
