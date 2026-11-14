-- GCI Grass Farm V9 | exact Y=-27 full-field CFrame tween
if _G.GCIGrassCleanup then pcall(_G.GCIGrassCleanup) end
if _G.GCIGrassStop then pcall(_G.GCIGrassStop) end
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local previous=pg:FindFirstChild("GCIGrassCollector")
if previous then previous:Destroy() end
pcall(function() RunService:UnbindFromRenderStep("GCIGrassCamera") end)

local X0,X1,Z0,Z1=-62,35,-19,79
local EXACT_Y=-27
local LANES=7
local SPEED=450 -- studs per second, adjustable
local RETURN_SPEED=55
local DROP_SPEED=10
local RETURN_RISE=9
local active=false
local version=0
local currentTween=nil
local listeners={}
local originalSpeed=nil
local standingY=nil
local cleaned=false

local function root()
 local c=player.Character
 return c and c:FindFirstChild("HumanoidRootPart")
end
local function humanoid()
 local c=player.Character
 return c and c:FindFirstChildOfClass("Humanoid")
end
local function track(c) listeners[#listeners+1]=c return c end
local function cancelTween()
 if currentTween then currentTween:Cancel() currentTween=nil end
end
local function stopAll()
 version+=1
 active=false
 cancelTween()
 local h=humanoid()
 if h then
  h:Move(Vector3.zero,false)
  if originalSpeed then h.WalkSpeed=originalSpeed end
 end
 originalSpeed=nil
 local r=root()
 if r then
  r.AssemblyLinearVelocity=Vector3.zero
  r.AssemblyAngularVelocity=Vector3.zero
 end
end
local function tweenTo(pos,speed,id)
 local r=root()
 if not r or id~=version then return false end
 local duration=math.max((pos-r.Position).Magnitude/speed,.015)
 local tw=TweenService:Create(r,TweenInfo.new(duration,Enum.EasingStyle.Linear),{
  CFrame=CFrame.new(pos)*r.CFrame.Rotation
 })
 currentTween=tw
 tw:Play()
 local state=tw.Completed:Wait()
 if currentTween==tw then currentTween=nil end
 return id==version and state==Enum.PlaybackState.Completed
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
 TweenService:Create(switch,TweenInfo.new(.15),{BackgroundColor3=active and Color3.fromRGB(65,190,115) or Color3.fromRGB(65,65,72)}):Play()
 TweenService:Create(knob,TweenInfo.new(.15),{Position=active and UDim2.fromOffset(20,3) or UDim2.fromOffset(3,3)}):Play()
end
-- Continuous serpentine route: no random positions.
local route={}
for i=0,LANES-1 do
 local x=X0+(X1-X0)*i/(LANES-1)
 if i%2==0 then
  route[#route+1]=Vector2.new(x,Z0)
  route[#route+1]=Vector2.new(x,Z1)
 else
  route[#route+1]=Vector2.new(x,Z1)
  route[#route+1]=Vector2.new(x,Z0)
 end
end
local function farm()
 stopAll()
 local r=root()
 if not r then return end
 standingY=EXACT_Y
 active=true
 version+=1
 local id=version
 local h=humanoid()
 local cam=workspace.CurrentCamera
 if cam and h then
  cam.CameraType=Enum.CameraType.Custom
  cam.CameraSubject=h
 end
 paint()
 task.spawn(function()
  -- 1 -> 4 (Z -19 to 79), then across to 3,
  -- 3 -> 2 (Z 79 to -19), repeat across adjacent X lanes.
  -- Reverse the full path when the far side is reached.
  while active and id==version do
   for i=1,#route do
    if not active or id~=version then return end
    local p=route[i]
    if not tweenTo(Vector3.new(p.X,EXACT_Y,p.Y),SPEED,id) then return end
   end
   for i=#route-1,1,-1 do
    if not active or id~=version then return end
    local p=route[i]
    if not tweenTo(Vector3.new(p.X,EXACT_Y,p.Y),SPEED,id) then return end
   end
  end
 end)
end
local function stop()
 stopAll()
 paint()
 local id=version
 task.spawn(function()
  local r=root()
  if not r then return end
  local y=math.max(r.Position.Y,(standingY or r.Position.Y)+RETURN_RISE)
  local function easeTo(pos,speed)
   if id~=version then return false end
   local rr=root()
   if not rr then return false end
   local duration=math.max((rr.Position-pos).Magnitude/speed,.08)
   local tw=TweenService:Create(rr,TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=CFrame.new(pos)*rr.CFrame.Rotation})
   currentTween=tw
   tw:Play()
   local state=tw.Completed:Wait()
   if currentTween==tw then currentTween=nil end
   return state==Enum.PlaybackState.Completed and id==version
  end
  if not easeTo(Vector3.new(r.Position.X,y,r.Position.Z),RETURN_SPEED) then return end
  if not easeTo(Vector3.new(-14,y,30.5),RETURN_SPEED) then return end
  easeTo(Vector3.new(-14,EXACT_Y,30.5),DROP_SPEED)
 end)
end
local dragging,moved,fromToggle=false,false,false
local inputStart,frameStart,pressed
local function begin(input,isToggle)
 if dragging then return end
 if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
 dragging=true moved=false fromToggle=isToggle
 inputStart=input.Position frameStart=panel.Position pressed=input
end
track(drag.InputBegan:Connect(function(i) begin(i,false) end))
track(toggle.InputBegan:Connect(function(i) begin(i,true) end))
track(UIS.InputChanged:Connect(function(i)
 if not dragging then return end
 if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
 if pressed.UserInputType==Enum.UserInputType.Touch and i~=pressed then return end
 local d=i.Position-inputStart
 if d.Magnitude>7 then moved=true end
 if moved then panel.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+d.X,frameStart.Y.Scale,frameStart.Y.Offset+d.Y) end
end))
track(UIS.InputEnded:Connect(function(i)
 if not dragging then return end
 if i.UserInputType~=pressed.UserInputType then return end
 if pressed.UserInputType==Enum.UserInputType.Touch and i~=pressed then return end
 local clicked=fromToggle and not moved
 dragging=false pressed=nil
 if clicked then if active then stop() else farm() end end
end))
local function cleanup()
 if cleaned then return end
 cleaned=true
 stopAll()
 for _,c in ipairs(listeners) do c:Disconnect() end
 if gui.Parent then gui:Destroy() end
end
_G.GCIGrassCleanup=cleanup
_G.GCIGrassStop=cleanup
print("GCI Grass Farm V9 loaded - exact Y=-27, CFrame tween")
