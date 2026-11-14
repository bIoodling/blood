-- GCI Grass Farm V5: grounded walking and normal camera
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
local XMIN,XMAX,ZMIN,ZMAX=-63,35,-19,79
local CENTER=Vector3.new(-14,-27,30.5)
local WALK_SPEED=26 -- real humanoid speed; lower for better contact
local STEP_RADIUS=15 -- short randomized steps, not huge jumps
local ARRIVAL_RADIUS=3
local RISE=8
local RETURN_SPEED=55
local DROP_SPEED=10
local rng=Random.new()
local running=false
local token=0
local cleaned=false
local connections={}
local returnTween=nil
local savedSpeed=nil
local function root()
 local c=player.Character
 return c and c:FindFirstChild("HumanoidRootPart")
end
local function humanoid()
 local c=player.Character
 return c and c:FindFirstChildOfClass("Humanoid")
end
local function track(c) connections[#connections+1]=c return c end
local function cancelReturn()
 if returnTween then returnTween:Cancel() returnTween=nil end
end
local function restoreSpeed()
 local h=humanoid()
 if h and savedSpeed then h.WalkSpeed=savedSpeed end
 savedSpeed=nil
end
local function halt()
 token+=1
 running=false
 cancelReturn()
 local h=humanoid()
 local r=root()
 if h and r then h:Move(Vector3.zero,false) h:MoveTo(r.Position) end
 restoreSpeed()
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
 TweenService:Create(switch,TweenInfo.new(.15),{BackgroundColor3=running and Color3.fromRGB(65,190,115) or Color3.fromRGB(65,65,72)}):Play()
 TweenService:Create(knob,TweenInfo.new(.15),{Position=running and UDim2.fromOffset(20,3) or UDim2.fromOffset(3,3)}):Play()
end
local function nextPoint(current)
 -- Random short segments, with occasional destinations across the pad.
 local x,z
 if rng:NextNumber()<.22 then
  x=rng:NextNumber(XMIN+3,XMAX-3)
  z=rng:NextNumber(ZMIN+3,ZMAX-3)
 else
  x=math.clamp(current.X+rng:NextNumber(-STEP_RADIUS,STEP_RADIUS),XMIN+3,XMAX-3)
  z=math.clamp(current.Z+rng:NextNumber(-STEP_RADIUS,STEP_RADIUS),ZMIN+3,ZMAX-3)
 end
 return Vector3.new(x,current.Y,z)
end
local function start()
 halt()
 local h=humanoid()
 local r=root()
 if not h or not r then return end
 running=true
 token+=1
 local id=token
 savedSpeed=h.WalkSpeed
 h.WalkSpeed=WALK_SPEED
 paint()
 -- Leave CameraType Custom: Roblox follows its humanoid without CFrame camera jitter.
 local cam=workspace.CurrentCamera
 if cam then cam.CameraType=Enum.CameraType.Custom cam.CameraSubject=h end
 task.spawn(function()
  while running and id==token and h.Parent and r.Parent do
   local goal=nextPoint(r.Position)
   h:MoveTo(goal)
   local startTime=os.clock()
   repeat
    RunService.Heartbeat:Wait()
   until id~=token or not running or not h.Parent or not r.Parent
      or (Vector3.new(r.Position.X,0,r.Position.Z)-Vector3.new(goal.X,0,goal.Z)).Magnitude<ARRIVAL_RADIUS
      or os.clock()-startTime>3.5
  end
 end)
end
local function tweenPosition(destination,speed,id)
 local r=root()
 if not r or id~=token then return false end
 local duration=math.max((destination-r.Position).Magnitude/speed,.05)
 local tween=TweenService:Create(r,TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=CFrame.new(destination)*r.CFrame.Rotation})
 returnTween=tween
 tween:Play()
 local result=tween.Completed:Wait()
 if returnTween==tween then returnTween=nil end
 return result==Enum.PlaybackState.Completed and id==token
end
local function stop()
 halt()
 paint()
 local id=token
 task.spawn(function()
  local r=root()
  if not r then return end
  local highY=math.max(r.Position.Y,CENTER.Y+RISE)
  if not tweenPosition(Vector3.new(r.Position.X,highY,r.Position.Z),RETURN_SPEED,id) then return end
  if not tweenPosition(Vector3.new(CENTER.X,highY,CENTER.Z),RETURN_SPEED,id) then return end
  tweenPosition(CENTER,DROP_SPEED,id)
 end)
end
local dragging,moved,startedToggle=false,false,false
local startInput,startPos,touchInput
local function begin(input,isToggle)
 if dragging then return end
 if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
 dragging=true moved=false startedToggle=isToggle
 startInput=input.Position startPos=panel.Position touchInput=input
end
track(drag.InputBegan:Connect(function(i) begin(i,false) end))
track(toggle.InputBegan:Connect(function(i) begin(i,true) end))
track(UIS.InputChanged:Connect(function(i)
 if not dragging then return end
 if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
 if touchInput.UserInputType==Enum.UserInputType.Touch and i~=touchInput then return end
 local delta=i.Position-startInput
 if delta.Magnitude>7 then moved=true end
 if moved then panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y) end
end))
track(UIS.InputEnded:Connect(function(i)
 if not dragging then return end
 if i.UserInputType~=touchInput.UserInputType then return end
 if touchInput.UserInputType==Enum.UserInputType.Touch and i~=touchInput then return end
 local shouldToggle=startedToggle and not moved
 dragging=false touchInput=nil
 if shouldToggle then if running then stop() else start() end end
end))
local function cleanup()
 if cleaned then return end
 cleaned=true
 halt()
 for _,c in ipairs(connections) do c:Disconnect() end
 if gui.Parent then gui:Destroy() end
end
_G.GCIGrassCleanup=cleanup
_G.GCIGrassStop=cleanup
print("GCI Grass Farm V5: grounded walking enabled")
