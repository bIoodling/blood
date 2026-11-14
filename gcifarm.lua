-- GCI Grass Farm | stable gcifarm.lua
if _G.GCIGrassCleanup then pcall(_G.GCIGrassCleanup) end
if _G.GCIGrassStop then pcall(_G.GCIGrassStop) end
local P=game:GetService("Players").LocalPlayer
local R=game:GetService("RunService")
local U=game:GetService("UserInputService")
local T=game:GetService("TweenService")
local G=P:WaitForChild("PlayerGui")
local old=G:FindFirstChild("GCIGrassCollector")
if old then old:Destroy() end
pcall(function() R:UnbindFromRenderStep("GCIGrassCamera") end)
local X0,X1,Z0,Z1,Y=-63,35,-19,79,-27
local CENTER=Vector3.new(-14,Y,30.5)
local SPEED,RETURN_SPEED,DROP_SPEED=1800,85,12
local active,serial=false,0
local motion,camOn=nil,false
local listeners={}
local rng=Random.new()
local function root()
 local c=P.Character
 return c and c:FindFirstChild("HumanoidRootPart")
end
local function track(c) table.insert(listeners,c) return c end
local function halt()
 if motion then motion:Disconnect() motion=nil end
 local r=root()
 if r then r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero end
end
local function cameraOff()
 camOn=false
 pcall(function() R:UnbindFromRenderStep("GCIGrassCamera") end)
 local c=workspace.CurrentCamera
 if c then c.CameraType=Enum.CameraType.Custom end
end
local function cameraOn()
 cameraOff()
 local r,c=root(),workspace.CurrentCamera
 if not r or not c then return end
 local offset=c.CFrame.Position-r.Position
 c.CameraType=Enum.CameraType.Scriptable
 camOn=true
 R:BindToRenderStep("GCIGrassCamera",Enum.RenderPriority.Camera.Value+1,function()
  local rr,cc=root(),workspace.CurrentCamera
  if not camOn or not rr or not cc then return end
  local target=rr.Position
  cc.CFrame=CFrame.lookAt(target+offset,target)
  cc.Focus=CFrame.new(target)
 end)
end
local function travel(target,speed,id,ease)
 local r=root()
 if not r then return false end
 halt()
 local start=r.Position
 local duration=math.max((target-start).Magnitude/speed,0.001)
 local elapsed=0
 local done=false
 motion=R.Heartbeat:Connect(function(dt)
  if id~=serial or not r.Parent then done=true return end
  elapsed=math.min(elapsed+dt,duration)
  local a=elapsed/duration
  if ease then a=T:GetValue(a,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut) end
  r.CFrame=CFrame.new(start:Lerp(target,a))
  r.AssemblyLinearVelocity=Vector3.zero
  r.AssemblyAngularVelocity=Vector3.zero
  if elapsed>=duration then done=true end
 end)
 while not done and id==serial do R.Heartbeat:Wait() end
 if motion then motion:Disconnect() motion=nil end
 return id==serial
end
local gui=Instance.new("ScreenGui")
gui.Name="GCIGrassCollector"
gui.ResetOnSpawn=false
gui.Parent=G
local panel=Instance.new("Frame")
panel.Size=UDim2.fromOffset(162,43)
panel.Position=UDim2.new(.5,-81,.25,0)
panel.BackgroundColor3=Color3.fromRGB(20,20,24)
panel.BorderSizePixel=0
panel.Active=true
panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
local text=Instance.new("TextLabel")
text.Size=UDim2.new(1,-62,1,0)
text.Position=UDim2.fromOffset(12,0)
text.BackgroundTransparency=1
text.Text="Grass Farm"
text.Font=Enum.Font.GothamMedium
text.TextSize=12
text.TextColor3=Color3.fromRGB(240,240,245)
text.TextXAlignment=Enum.TextXAlignment.Left
text.Parent=panel
local switch=Instance.new("Frame")
switch.Size=UDim2.fromOffset(39,22)
switch.Position=UDim2.new(1,-50,.5,-11)
switch.BackgroundColor3=Color3.fromRGB(65,65,72)
switch.Parent=panel
Instance.new("UICorner",switch).CornerRadius=UDim.new(1,0)
local knob=Instance.new("Frame")
knob.Size=UDim2.fromOffset(16,16)
knob.Position=UDim2.fromOffset(3,3)
knob.BackgroundColor3=Color3.new(1,1,1)
knob.Parent=switch
Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
local drag=Instance.new("TextButton")
drag.Size=UDim2.fromScale(1,1)
drag.BackgroundTransparency=1
drag.Text=""
drag.ZIndex=4
drag.Parent=panel
local toggle=Instance.new("TextButton")
toggle.Size=switch.Size
toggle.Position=switch.Position
toggle.BackgroundTransparency=1
toggle.Text=""
toggle.ZIndex=5
toggle.Parent=panel
local function paint()
 T:Create(switch,TweenInfo.new(.15),{BackgroundColor3=active and Color3.fromRGB(65,190,115) or Color3.fromRGB(65,65,72)}):Play()
 T:Create(knob,TweenInfo.new(.15),{Position=active and UDim2.fromOffset(20,3) or UDim2.fromOffset(3,3)}):Play()
end
local points={}
for x=X0,X1,2 do for z=Z0,Z1,2 do table.insert(points,Vector3.new(x,Y,z)) end end
local function shuffle()
 for i=#points,2,-1 do local j=rng:NextInteger(1,i) points[i],points[j]=points[j],points[i] end
end
local function start()
 serial+=1
 local id=serial
 active=true
 paint()
 cameraOn()
 task.spawn(function()
  while active and id==serial do
   shuffle()
   local began=os.clock()
   local index=1
   while active and id==serial and os.clock()-began<3 do
    if not travel(points[index],SPEED,id,false) then return end
    index=index%#points+1
   end
  end
 end)
end
local function stop()
 active=false
 serial+=1
 local id=serial
 halt()
 paint()
 task.spawn(function()
  local r=root()
  if not r then cameraOff() return end
  local height=Y+9
  if not travel(Vector3.new(r.Position.X,math.max(r.Position.Y,height),r.Position.Z),RETURN_SPEED,id,true) then return end
  if not travel(Vector3.new(CENTER.X,height,CENTER.Z),RETURN_SPEED,id,true) then return end
  if not travel(CENTER,DROP_SPEED,id,true) then return end
  if id==serial then cameraOff() end
 end)
end
local dragging,moved,onSwitch=false,false,false
local origin,position,inputStart
local function begin(input,isSwitch)
 if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
 dragging,moved,onSwitch=true,false,isSwitch
 origin=input.Position
 position=panel.Position
 inputStart=input
end
track(drag.InputBegan:Connect(function(i) begin(i,false) end))
track(toggle.InputBegan:Connect(function(i) begin(i,true) end))
track(U.InputChanged:Connect(function(i)
 if not dragging then return end
 if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
 if inputStart.UserInputType==Enum.UserInputType.Touch and i~=inputStart then return end
 local d=i.Position-origin
 if d.Magnitude>7 then moved=true end
 if moved then panel.Position=UDim2.new(position.X.Scale,position.X.Offset+d.X,position.Y.Scale,position.Y.Offset+d.Y) end
end))
track(U.InputEnded:Connect(function(i)
 if not dragging then return end
 if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
 if inputStart.UserInputType==Enum.UserInputType.Touch and i~=inputStart then return end
 local shouldToggle=onSwitch and not moved
 dragging=false
 if shouldToggle then if active then stop() else halt() start() end end
end))
local cleaned=false
local function cleanup()
 if cleaned then return end
 cleaned=true
 active=false
 serial+=1
 halt()
 cameraOff()
 for _,c in ipairs(listeners) do c:Disconnect() end
 gui:Destroy()
end
_G.GCIGrassCleanup=cleanup
_G.GCIGrassStop=cleanup
print("GCI Grass Farm loaded")
