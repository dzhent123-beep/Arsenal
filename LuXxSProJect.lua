--=============================================================
-- LuXxS Hub | Xenia menu (CHEATERSOUL) + luxxs features
-- requires: Drawing, writefile/readfile (optional for configs),
--           mousemoverel (optional for smooth PC aim)
--=============================================================

--================= services =================
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local Lighting     = game:GetService("Lighting")
local Workspace    = game:GetService("Workspace")
local CoreGui      = game:GetService("CoreGui")
local LP           = Players.LocalPlayer

local HAS_DRAWING  = pcall(function() local t = Drawing.new("Line") t:Remove() end)
local HAS_FS       = writefile ~= nil and readfile ~= nil
local HAS_MOVEREL  = typeof(mousemoverel) == "function"
local DEBUG_GUI    = false -- true = print lib gui tree to F9 console

--================= library =================
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Luciquad/xenia/main/cheatersoul.lua"))()

-- top-level GUIs before/after library.new -> the lib's own ScreenGui(s)
local function guiSnapshot()
    local t, containers = {}, {CoreGui}
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then table.insert(containers, pg) end
    if typeof(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then table.insert(containers, h) end
    end
    for _, c in ipairs(containers) do
        for _, g in ipairs(c:GetChildren()) do t[g] = true end
    end
    return t
end
local _guiBefore = guiSnapshot()
local venyx      = library.new("LuXxS Hub", 5013109572)
local _libGuis   = {}
local function collectLibGuis()
    for g in pairs(guiSnapshot()) do
        if not _guiBefore[g] and g.Name ~= "LuXxS_Hub_Bar" then _libGuis[g] = true end
    end
end
collectLibGuis()

--================= theme (тёмно-фиолетовый) =================
local themeTable = {
    Background    = Color3.fromRGB(30, 18, 48),
    Glow          = Color3.fromRGB(10, 5, 20),
    Accent        = Color3.fromRGB(107, 63, 160),
    LightContrast = Color3.fromRGB(46, 26, 69),
    DarkContrast  = Color3.fromRGB(21, 12, 34),
    TextColor     = Color3.fromRGB(235, 215, 255),
}

--================= settings =================
local S = {
    silentAimOn=false, silentAimFov=0, silentAimHeadHitchance=0, silentAimBodyHitchance=0,
    showSilentAimFov=false, silentAimFovFilled=false, silentAimFovThickness=1,
    silentAimFovNumSides=3, silentAimFovTransparency=0, silentAimFovColor=Color3.fromRGB(150,70,255),
    aimOn=false, aimMode=(UIS.TouchEnabled and not UIS.KeyboardEnabled) and "Touch button" or "Hold RMB",
    aimBone="Head", aimTeam=true, aimVis=true, aimFov=120, aimSmooth=0.25,
    circleOn=false, circleHue=0.75,
    espOn=false, espShape="2D", espHp=true, espName=true, espDist=true, espHue=0.9,
    chamsOn=false, nameTagsOn=false, chamsColor=Color3.fromRGB(150,70,255),
    armChamsOn=false, weaponChamsOn=false, armColor=Color3.fromRGB(150,70,255),
    weaponColor=Color3.fromRGB(150,70,255), armMaterial="Plastic", weaponMaterial="Plastic",
    antiAimOn=false, noAnims=false, pitchType="Custom", pitchValue=0,
    yawType="Custom", yawValue=0, aaSpinSpeed=0,
    speedOn=false, walk=16, jumpOn=false, jump=50,
    noclip=false, infJump=false, fly=false, flySpeed=50,
    spinOn=false, spinSpeedDeg=360, bhopOn=false, bhopSpeed=1,
    tpOn=false, tpDistance=12, tpX=0, tpY=0,
    fovOn=false, fov=70, blurOn=false, blur=10,
    skyOn=false, skyHue=0.75,
    handsOn=false, handX=0, handY=0, handZ=0,
    wings="None", headless=false, legless=false,
    trailOn=false, trailHue=0.75, hatOn=false, hatHue=0.1, hatTrans=0,
    chatspamOn=false, chatspamType="HAMEWARE", chatspamWait=1,
    collectDebris=false,
}
local flags = {}

--================= helpers =================
local function clamp(v,a,b) return math.max(a, math.min(b, v)) end
local function hue(h) return Color3.fromHSV(h, 1, 1) end
local function cam() return Workspace.CurrentCamera end
local function hrp() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function screenCenter() local c = cam() local vs = c and c.ViewportSize or Vector2.new(1280,720) return Vector2.new(vs.X/2, vs.Y/2) end
local function isFirstPerson() local c = LP.Character local head = c and c:FindFirstChild("Head") local cf = cam() return head and cf and (cf.CFrame.Position - head.Position).Magnitude < 1.5 end
local function isInTable(t, f) for _,v in pairs(t) do if v==f then return true end end return false end
local function mk(class, props, parent) local o = Instance.new(class) for k,v in pairs(props or {}) do o[k]=v end if parent then o.Parent=parent end return o end

local BodyParts = {
    'LeftFoot','LeftHand','LeftLowerArm','LeftLowerLeg','LeftUpperArm','LeftUpperLeg','LowerTorso',
    'RightFoot','RightHand','RightLowerArm','RightLowerLeg','RightUpperLeg','RightUpperArm','UpperTorso','Head'
}

--================= metatable (SilentAim / NoAnims / Pitch) =================
local target, bodyname
local fakeanim = Instance.new("Animation") fakeanim.AnimationId = "rbxassetid://0"

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) else make_writeable(mt, true) end
local namecallMethod = getnamecallmethod or get_namecall_method
local newClose = newcclosure or function(f) return f end

mt.__namecall = newClose(function(...)
    local method = namecallMethod()
    local args = {...}

    if method == "FindPartOnRayWithIgnoreList" and S.silentAimOn and target and bodyname and target[bodyname] then
        args[2] = Ray.new(workspace.CurrentCamera.CFrame.Position,
            (target[bodyname].CFrame.p - workspace.CurrentCamera.CFrame.Position).unit * 500)
    elseif method == "LoadAnimation" and S.noAnims then
        local id = tostring(args[2])
        if id == "RunForward" or id == "RunBackward" or id == "RunLeft" or id == "RunRight" then
            args[2] = fakeanim
        end
    elseif method == "FireServer" and tostring(args[1]) == "ControlTurn" and S.antiAimOn then
        if S.pitchType == "Custom" then args[2] = S.pitchValue
        elseif S.pitchType == "Down" then args[2] = -1.5
        elseif S.pitchType == "Up" then args[2] = 1.5
        elseif S.pitchType == "Zero" then args[2] = 0 end
    end
    return oldNamecall(unpack(args))
end)
if setreadonly then setreadonly(mt, true) else make_writeable(mt, false) end

--================= silent aim target =================
local hed   = Instance.new("Part", workspace.Terrain)
local rhead = Instance.new("Part", hed) rhead.Name = "Head"
local rtors = Instance.new("Part", hed) rtors.Name = "UpperTorso"

local function GetTarget()
    local fob = S.silentAimFov
    local nearest = nil
    pcall(function()
        local m = LP:GetMouse()
        for _, PL in pairs(Players:GetPlayers()) do
            if PL ~= LP and PL.Character and PL.Character:FindFirstChild("Head") then
                local skip = S.aimTeam and PL.Team and PL.Team == LP.Team
                if not skip then
                    local vector, onScreen = workspace.CurrentCamera:WorldToScreenPoint(PL.Character.Head.CFrame.p)
                    local dist = (Vector2.new(vector.X, vector.Y) - Vector2.new(m.X, m.Y)).Magnitude
                    if dist < fob and PL.Character.Humanoid.Health > 0 then
                        nearest = PL.Character
                        fob = dist
                    end
                end
            end
        end
    end)
    return nearest
end

--================= drawing circles =================
local silentCircle, regularCircle
if HAS_DRAWING then
    silentCircle = Drawing.new("Circle")
    silentCircle.NumSides = 64 silentCircle.Thickness = 1.5 silentCircle.Filled = false silentCircle.Visible = false

    regularCircle = Drawing.new("Circle")
    regularCircle.NumSides = 64 regularCircle.Thickness = 1.5 regularCircle.Filled = false regularCircle.Visible = false
end

--================= ESP =================
local esp = {}
local CORNERS = {
    Vector3.new(-1,-1,-1),Vector3.new(1,-1,-1),Vector3.new(1,1,-1),Vector3.new(-1,1,-1),
    Vector3.new(-1,-1,1),Vector3.new(1,-1,1),Vector3.new(1,1,1),Vector3.new(-1,1,1)
}
local EDGES = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
local BONES = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
    {"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}

local function espCreate(plr)
    if not HAS_DRAWING or esp[plr] or plr == LP then return end
    local e = {lines = {}, texts = {}}
    for i = 1, 64 do
        local l = Drawing.new("Line") l.Thickness = 1.5 l.Visible = false e.lines[i] = l
    end
    for i = 1, 3 do
        local t = Drawing.new("Text") t.Size = 13 t.Center = false t.Outline = true t.Font = 0 t.Visible = false e.texts[i] = t
    end
    esp[plr] = e
end

local function espDestroy(plr)
    local e = esp[plr] if not e then return end
    for _,l in ipairs(e.lines) do l:Remove() end
    for _,t in ipairs(e.texts) do t:Remove() end
    esp[plr] = nil
end

local function espHide(e)
    for _,l in ipairs(e.lines) do l.Visible = false end
    for _,t in ipairs(e.texts) do t.Visible = false end
end

local function espDraw()
    local c = cam() if not c then return end
    for plr, e in pairs(esp) do
        espHide(e)
        local ch = plr.Character
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        if S.espOn and root and h and h.Health > 0 then
            local col = hue(S.espHue)
            local cf = root.CFrame
            local half = Vector3.new(1.7, 3.1, 1.3)
            local pts, inFront = {}, true
            for i, o in ipairs(CORNERS) do
                local p = c:WorldToViewportPoint((cf * CFrame.new(o * half)).Position)
                pts[i] = Vector2.new(p.X, p.Y)
                if p.Z <= 0 then inFront = false end
            end
            if inFront then
                local n = 0
                local function ln(a, b)
                    n = n + 1
                    local l = e.lines[n]
                    if l then l.From = a l.To = b l.Color = col l.Visible = true end
                end
                local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                for _, p in ipairs(pts) do
                    minX = math.min(minX, p.X) minY = math.min(minY, p.Y)
                    maxX = math.max(maxX, p.X) maxY = math.max(maxY, p.Y)
                end
                local shape = S.espShape
                if shape == "2D" then
                    ln(Vector2.new(minX,minY), Vector2.new(maxX,minY))
                    ln(Vector2.new(maxX,minY), Vector2.new(maxX,maxY))
                    ln(Vector2.new(maxX,maxY), Vector2.new(minX,maxY))
                    ln(Vector2.new(minX,maxY), Vector2.new(minX,minY))
                elseif shape == "3D" then
                    for _, ed in ipairs(EDGES) do ln(pts[ed[1]], pts[ed[2]]) end
                elseif shape == "Corner" then
                    local cw = (maxX-minX)*0.25 local chh = (maxY-minY)*0.25
                    ln(Vector2.new(minX,minY), Vector2.new(minX+cw,minY)) ln(Vector2.new(minX,minY), Vector2.new(minX,minY+chh))
                    ln(Vector2.new(maxX,minY), Vector2.new(maxX-cw,minY)) ln(Vector2.new(maxX,minY), Vector2.new(maxX,minY+chh))
                    ln(Vector2.new(minX,maxY), Vector2.new(minX+cw,maxY)) ln(Vector2.new(minX,maxY), Vector2.new(minX,maxY-chh))
                    ln(Vector2.new(maxX,maxY), Vector2.new(maxX-cw,maxY)) ln(Vector2.new(maxX,maxY), Vector2.new(maxX,maxY-chh))
                elseif shape == "Markers" then
                    local cs = 4
                    for _, cp in ipairs({Vector2.new(minX,minY),Vector2.new(maxX,minY),Vector2.new(minX,maxY),Vector2.new(maxX,maxY)}) do
                        ln(cp - Vector2.new(cs,0), cp + Vector2.new(cs,0))
                        ln(cp - Vector2.new(0,cs), cp + Vector2.new(0,cs))
                    end
                elseif shape == "Skeleton" then
                    for _, b in ipairs(BONES) do
                        local pa, pb = ch:FindFirstChild(b[1]), ch:FindFirstChild(b[2])
                        if pa and pb then
                            local va, oa = c:WorldToViewportPoint(pa.Position)
                            local vb, ob = c:WorldToViewportPoint(pb.Position)
                            if oa and ob then ln(Vector2.new(va.X,va.Y), Vector2.new(vb.X,vb.Y)) end
                        end
                    end
                end
                local slot = 0
                local function right(t, text, color)
                    t.Text = text t.Color = color
                    t.Position = Vector2.new(maxX + 5, minY + slot * 13)
                    t.Visible = true slot = slot + 1
                end
                if S.espName then right(e.texts[1], plr.Name, col) end
                if S.espHp then right(e.texts[2], math.floor(h.Health).." HP", Color3.fromRGB(120,255,120)) end
                if S.espDist then right(e.texts[3], math.floor((root.Position - c.CFrame.Position).Magnitude).." m", col) end
            end
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do espCreate(p) end
Players.PlayerAdded:Connect(espCreate)
Players.PlayerRemoving:Connect(espDestroy)

--================= regular aim =================
local aimRMB, aimTouch = false, false
local function aimActive()
    if S.aimMode == "Always" then return true
    elseif S.aimMode == "Hold RMB" then return aimRMB end
    return aimTouch
end

local function isVisible(part)
    local c = cam()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = LP.Character and {LP.Character} or {}
    local hit = Workspace:Raycast(c.CFrame.Position, part.Position - c.CFrame.Position, params)
    return hit == nil or hit.Instance:IsDescendantOf(part.Parent)
end

local function findTargetAim(center)
    local best, bestD = nil, S.aimFov
    local c = cam()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local part = plr.Character:FindFirstChild(S.aimBone)
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            local sameTeam = S.aimTeam and plr.Team ~= nil and plr.Team == LP.Team
            if part and h and h.Health > 0 and not sameTeam then
                local p, onScreen = c:WorldToViewportPoint(part.Position)
                if onScreen and p.Z > 0 then
                    local d = (Vector2.new(p.X, p.Y) - center).Magnitude
                    if d < bestD and (not S.aimVis or isVisible(part)) then best, bestD = part, d end
                end
            end
        end
    end
    return best
end

local function aimAt(targetPart, center, c)
    local p, onScreen = c:WorldToViewportPoint(targetPart.Position)
    if not onScreen or p.Z <= 0 then return end
    local k = clamp(1 - S.aimSmooth, 0.05, 1)
    if HAS_MOVEREL and UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
        mousemoverel((p.X - center.X) * k, (p.Y - center.Y) * k)
    else
        local goal = CFrame.lookAt(c.CFrame.Position, targetPart.Position)
        c.CFrame = c.CFrame:Lerp(goal, k)
    end
end

--================= anti-aim =================
local function characterrotate(pos)
    pcall(function()
        if LP.Character then
            local h = LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.AutoRotate = false end
            local torso = LP.Character:FindFirstChild("UpperTorso") or LP.Character:FindFirstChild("Torso")
            if not torso then return end
            local gyro = Instance.new('BodyGyro')
            gyro.D = 0 gyro.P = 1000000 gyro.MaxTorque = Vector3.new(0,1000000,0)
            gyro.Parent = torso
            gyro.CFrame = CFrame.new(torso.Position, pos)
            wait() gyro:Destroy()
        end
    end)
end

--================= camera / effects / hands =================
local tpSaved  = nil
local origFov  = cam() and cam().FieldOfView or 70
local blurEffect = Lighting:FindFirstChild("LuXxS_Blur") or mk("BlurEffect", {Name="LuXxS_Blur", Size=0, Enabled=false}, Lighting)
local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
local atmosNew = atmos == nil
if atmosNew then atmos = mk("Atmosphere", {Density=0}, Lighting) end
local atmosOrig = {color=atmos.Color, decay=atmos.Decay, density=atmos.Density}

local function applyThirdPerson()
    local h = hum()
    if S.tpOn then
        if not tpSaved then tpSaved = {mode=LP.CameraMode, min=LP.CameraMinZoomDistance, max=LP.CameraMaxZoomDistance} end
        LP.CameraMode = Enum.CameraMode.Classic
        LP.CameraMaxZoomDistance = S.tpDistance
        LP.CameraMinZoomDistance = S.tpDistance
        if h then h.CameraOffset = Vector3.new(S.tpX, S.tpY, 0) end
    elseif tpSaved then
        LP.CameraMinZoomDistance = tpSaved.min
        LP.CameraMaxZoomDistance = tpSaved.max
        LP.CameraMode = tpSaved.mode
        if h then h.CameraOffset = Vector3.zero end
        tpSaved = nil
    end
end

local function applyBlur() blurEffect.Enabled = S.blurOn blurEffect.Size = S.blur end
local function applyFov() local c = cam() if c then c.FieldOfView = S.fovOn and clamp(S.fov,1,120) or origFov end end
local function applySky()
    if S.skyOn then
        local c = hue(S.skyHue)
        atmos.Color = c atmos.Decay = c
        if atmos.Density < 0.2 then atmos.Density = 0.3 end
    else
        atmos.Color = atmosOrig.color atmos.Decay = atmosOrig.decay
        atmos.Density = atmosNew and 0 or atmosOrig.density
    end
end

local shoulders, handsApplied = {}, false
local function refreshShoulders()
    shoulders = {} handsApplied = false
    local c = LP.Character
    local torso = c and (c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
    if not torso then return end
    for _, n in ipairs({"RightShoulder","LeftShoulder","Right Shoulder","Left Shoulder"}) do
        local m = torso:FindFirstChild(n)
        if m and m:IsA("Motor6D") then table.insert(shoulders, m) end
    end
end

local function applyHands()
    if S.handsOn and isFirstPerson() then
        local off = CFrame.new(S.handX, S.handY, S.handZ)
        for _, m in ipairs(shoulders) do if m.Parent then m.Transform = off end end
        handsApplied = true
    elseif handsApplied then
        handsApplied = false
        for _, m in ipairs(shoulders) do if m.Parent then m.Transform = CFrame.new() end end
    end
end

--================= cosmetics =================
local wingParts, wingOffs, hatParts = {}, {}, {}
local trail, trailA0, trailA1
local function clearWings() for _,p in ipairs(wingParts) do p:Destroy() end wingParts, wingOffs = {}, {} end
local function buildWings()
    clearWings()
    if S.wings == "None" or not LP.Character then return end
    local angel = S.wings == "Angel"
    for side = -1, 1, 2 do
        for i = 1, 8 do
            local len = 2.6 - i*0.22
            local f = Instance.new("Part")
            f.Anchored=true f.CanCollide=false f.CanQuery=false f.CanTouch=false f.CastShadow=false
            f.Size = Vector3.new(0.15, len, 0.5)
            f.Material = angel and Enum.Material.Neon or Enum.Material.SmoothPlastic
            f.Color = angel and Color3.new(1,1,1) or (i%2==0 and Color3.fromRGB(255,40,40) or Color3.fromRGB(60,0,0))
            f.Parent = Workspace
            table.insert(wingParts, f)
            table.insert(wingOffs, CFrame.new(side*0.5,0.6,0.9) * CFrame.Angles(math.rad(-25-i*4),0,math.rad(-side*(10+i*8))) * CFrame.new(0,len/2,0))
        end
    end
end
local function buildTrail()
    if trail then trail:Destroy() trail=nil end
    if trailA0 then trailA0:Destroy() trailA0=nil end
    if trailA1 then trailA1:Destroy() trailA1=nil end
    local r = hrp() if not (S.trailOn and r) then return end
    trailA0 = mk("Attachment", {Position=Vector3.new(0,1.5,0)}, r)
    trailA1 = mk("Attachment", {Position=Vector3.new(0,-1.5,0)}, r)
    trail = mk("Trail", {Attachment0=trailA0, Attachment1=trailA1, Lifetime=0.6, LightEmission=1, WidthScale=NumberSequence.new(1), Color=ColorSequence.new(hue(S.trailHue))}, r)
end
local function buildHat()
    for _,p in ipairs(hatParts) do p:Destroy() end hatParts = {}
    if not S.hatOn then return end
    local brim = Instance.new("Part")
    brim.Anchored=true brim.CanCollide=false brim.CanQuery=false brim.CanTouch=false brim.CastShadow=false
    brim.Shape=Enum.PartType.Cylinder brim.Size=Vector3.new(0.2,2.8,2.8)
    brim.Material=Enum.Material.SmoothPlastic brim.Color=hue(S.hatHue) brim.Parent=Workspace
    table.insert(hatParts, brim)
    local cone = Instance.new("Part")
    cone.Anchored=true cone.CanCollide=false cone.CanQuery=false cone.CanTouch=false cone.CastShadow=false
    cone.Size=Vector3.new(2.2,1.4,2.2) cone.Material=Enum.Material.SmoothPlastic cone.Color=hue(S.hatHue) cone.Parent=Workspace
    local mesh = Instance.new("SpecialMesh") mesh.MeshType = Enum.MeshType.Pyramid mesh.Parent = cone
    table.insert(hatParts, cone)
end
local function rebuildCosmetics() buildWings() buildTrail() buildHat() end
LP.CharacterAdded:Connect(function() task.wait(0.5) refreshShoulders() rebuildCosmetics() end)

--================= chams / nametags =================
local function updateChams()
    if not S.chamsOn then
        for _, V in pairs(Players:GetPlayers()) do
            if V ~= LP and V.Character then
                for _, Z in pairs(V.Character:GetDescendants()) do
                    if Z:FindFirstChild("LuXxS_ESP") then Z.LuXxS_ESP:Destroy() end
                end
            end
        end
        return
    end
    for _, V in pairs(Players:GetPlayers()) do
        if V ~= LP and V.Character and V.Character:FindFirstChild("Humanoid") then
            local skip = S.aimTeam and V.Team and V.Team == LP.Team
            for _, Z in pairs(V.Character:GetDescendants()) do
                if (Z:IsA("MeshPart") or Z:IsA("Part")) and isInTable(BodyParts, Z.Name) then
                    if skip then
                        if Z:FindFirstChild("LuXxS_ESP") then Z.LuXxS_ESP:Destroy() end
                    else
                        if Z:FindFirstChild("LuXxS_ESP") then
                            Z.LuXxS_ESP.Color3 = S.chamsColor
                        else
                            if Z.Name == "Head" then
                                local h = Instance.new("CylinderHandleAdornment", Z)
                                h.Adornee=Z h.Transparency=0 h.AlwaysOnTop=true h.Name="LuXxS_ESP" h.ZIndex=1 h.Color3=S.chamsColor h.Height=1.3
                            else
                                local h = Instance.new("BoxHandleAdornment", Z)
                                h.Adornee=Z h.Transparency=0 h.AlwaysOnTop=true h.Name="LuXxS_ESP" h.Size=Z.Size h.ZIndex=1 h.Color3=S.chamsColor
                            end
                        end
                    end
                end
            end
        end
    end
end

local function updateNameTags()
    if not S.nameTagsOn then
        for _, V in pairs(Players:GetPlayers()) do
            if V.Character and V.Character:FindFirstChild("Head") and V.Character.Head:FindFirstChild("LuXxS_NAME") then
                V.Character.Head.LuXxS_NAME:Destroy()
            end
        end
        return
    end
    for _, V in pairs(Players:GetPlayers()) do
        if V ~= LP and V.Character and V.Character:FindFirstChild("Head") then
            local skip = S.aimTeam and V.Team and V.Team == LP.Team
            if skip then
                if V.Character.Head:FindFirstChild("LuXxS_NAME") then V.Character.Head.LuXxS_NAME:Destroy() end
            else
                local bbg = V.Character.Head:FindFirstChild("LuXxS_NAME")
                if bbg then
                    bbg.TextLabel.TextColor3 = S.chamsColor
                else
                    bbg = Instance.new("BillboardGui", V.Character.Head)
                    bbg.Name="LuXxS_NAME" bbg.AlwaysOnTop=true bbg.StudsOffset=Vector3.new(0,2,0)
                    bbg.Size=UDim2.new(0,200,0,50)
                    local l = Instance.new("TextLabel", bbg)
                    l.Size=UDim2.new(0,200,0,50) l.TextColor3=S.chamsColor l.Text=V.Name
                    l.Font=Enum.Font.Code l.TextSize=20 l.BackgroundTransparency=1 l.BorderSizePixel=0
                    l.TextWrapped=true
                end
            end
        end
    end
end

--================= chatspam =================
local CS = {
    HAMEWARE = {"LuXxS Hub ON TOP!","OWNING ANY OTHER CHEAT MAKES YOU AN IDIOT","LuXxS HUB WINNING","GET GOOD GET LuXxS HUB","LuXxS HUB TWO STUDS AHEAD"},
    Furry    = {"UwU Sowwiez! Im using LuXxS Hub </3","OwO LuXxS Hub is tapping aww of youw fwiends :c",">.< I am tapping eyes closed~",":3 come get LuXxS Hub!"},
    Swiss    = {"Salue zaeme Ig bin en schwiizer.","LuXxS Hub isch de best script","Ier sing alli extrem schlecht lol"},
    HvH      = {"HHHHHH owned by LuXxS Hub user","No LuXxS Hub no talk dog LLLL","hvh legend here"},
    China    = {"LuXxS Hub 最佳","脚本黑客软件","打包含黑客LuXxS Hub"},
}
local ChatDebounce = false
local function startChatspam()
    if ChatDebounce then return end
    ChatDebounce = true
    spawn(function()
        while ChatDebounce and S.chatspamOn do
            local list = CS[S.chatspamType] or CS.HAMEWARE
            pcall(function()
                game.ReplicatedStorage.Events.PlayerChatted:FireServer(list[math.random(1,#list)], false, false, false, true)
            end)
            wait(S.chatspamWait)
        end
        ChatDebounce = false
    end)
end

--================= open bar + window (drag / X / anim) + theme =================
local toggleMenu, applyTheme, ensureWindow -- assigned below

local barGui = Instance.new("ScreenGui")
barGui.Name = "LuXxS_Hub_Bar"
barGui.ResetOnSpawn = false
barGui.IgnoreGuiInset = true
barGui.DisplayOrder = 1000
if not pcall(function() barGui.Parent = CoreGui end) or not barGui.Parent then
    barGui.Parent = LP:WaitForChild("PlayerGui")
end

local BAR_W, BAR_H = 240, 6   -- visible pill
local HIT_W, HIT_H = 320, 44  -- tap area

local barBtn = Instance.new("TextButton")
barBtn.Name = "Open"
barBtn.Size = UDim2.new(0, HIT_W, 0, HIT_H)
barBtn.Position = UDim2.new(0.5, -HIT_W / 2, 1, -HIT_H)
barBtn.BackgroundTransparency = 1
barBtn.Text = ""
barBtn.AutoButtonColor = false
barBtn.Visible = false
barBtn.Parent = barGui

local barFrame = Instance.new("Frame")
barFrame.AnchorPoint = Vector2.new(0.5, 0.5)
barFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
barFrame.Size = UDim2.new(0, BAR_W, 0, BAR_H)
barFrame.BackgroundColor3 = themeTable.TextColor
barFrame.BackgroundTransparency = 0.1
barFrame.BorderSizePixel = 0
barFrame.Parent = barBtn
Instance.new("UICorner", barFrame).CornerRadius = UDim.new(1, 0)

do
    local menuOpen = true
    local root, uiScale, xBtn, REST
    local xLines, winTweens = {}, {}
    local dragging, dragStart, dragOrigin = false, nil, nil
    local winAnim, barTween = false, nil
    local TI_IN  = TweenInfo.new(0.32, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
    local TI_OUT = TweenInfo.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
    local TI_BAR = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local DROP = 22 -- px the window slides on open/close

    local function shifted(p, dy)
        return UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + dy)
    end

    local function stopWin()
        for _, t in ipairs(winTweens) do t:Cancel() end
        winTweens, winAnim = {}, false
    end

    --- bar ---
    local function tweenBar(goal, alpha, info, onDone)
        if barTween then barTween:Cancel() end
        barTween = TweenService:Create(barFrame, info, {Position = goal, BackgroundTransparency = alpha})
        if onDone then
            barTween.Completed:Connect(function(s)
                if s == Enum.PlaybackState.Completed then onDone() end
            end)
        end
        barTween:Play()
    end

    local function showBar()
        barBtn.Visible = true
        barFrame.Position = UDim2.new(0.5, 0, 0.5, 14)
        barFrame.BackgroundTransparency = 1
        tweenBar(UDim2.new(0.5, 0, 0.5, 0), 0.1, TI_BAR)
    end

    local function hideBar()
        tweenBar(UDim2.new(0.5, 0, 0.5, 14), 1, TI_OUT, function()
            if menuOpen then barBtn.Visible = false end
        end)
    end

    --- window ---
    local function openWindow()
        stopWin()
        if not root.Visible then
            root.Visible = true
            uiScale.Scale = 0.9
            root.Position = shifted(REST, DROP)
        end
        local a = TweenService:Create(uiScale, TI_IN, {Scale = 1})
        local b = TweenService:Create(root, TI_IN, {Position = REST})
        winTweens, winAnim = {a, b}, true
        b.Completed:Connect(function(s)
            if s == Enum.PlaybackState.Completed then winAnim = false end
        end)
        a:Play()
        b:Play()
    end

    local function closeWindow()
        REST = winAnim and REST or root.Position
        stopWin()
        local a = TweenService:Create(uiScale, TI_OUT, {Scale = 0.9})
        local b = TweenService:Create(root, TI_OUT, {Position = shifted(REST, DROP)})
        winTweens, winAnim = {a, b}, true
        b.Completed:Connect(function(s)
            if s ~= Enum.PlaybackState.Completed then return end
            winAnim = false
            if not menuOpen then
                root.Visible = false
                uiScale.Scale = 1
                root.Position = REST
            end
        end)
        a:Play()
        b:Play()
    end

    local function setMenu(open)
        if open == menuOpen then return end
        menuOpen = open
        if root then
            if open then openWindow() else closeWindow() end
        else
            venyx:toggle() -- fallback: lib window not found
        end
        if open then hideBar() else showBar() end
    end

    toggleMenu = function() setMenu(not menuOpen) end
    barBtn.MouseButton1Click:Connect(function() setMenu(true) end)

    --- finding the lib window ---
    local function isGlowish(n)
        n = n:lower()
        return n:find("glow") ~= nil or n:find("shadow") ~= nil
    end

    local function pickWindow()
        local vp = cam().ViewportSize
        local function best(list)
            local b, ba = nil, 0
            for _, f in ipairs(list) do
                if f:IsA("GuiObject") and f.BackgroundTransparency < 1 and not isGlowish(f.Name) then
                    local a = (f.Size.X.Scale * vp.X + f.Size.X.Offset) * (f.Size.Y.Scale * vp.Y + f.Size.Y.Offset)
                    if a > ba then b, ba = f, a end
                end
            end
            return b
        end
        local direct, deep = {}, {}
        for g in pairs(_libGuis) do
            if g.Parent then
                for _, f in ipairs(g:GetChildren()) do table.insert(direct, f) end
                for _, f in ipairs(g:GetDescendants()) do table.insert(deep, f) end
            end
        end
        return best(direct) or best(deep)
    end

    local function debugTree()
        for g in pairs(_libGuis) do
            print("[lib gui] " .. tostring(g.Name) .. " " .. g.ClassName)
            for _, f in ipairs(g:GetChildren()) do
                print("   " .. f.ClassName .. " " .. f.Name)
            end
        end
    end

    local function setupWindow()
        local w = pickWindow()
        if not w then return false end
        root = w
        REST = root.Position
        uiScale = root:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", root)

        -- drag strip across the top; ZIndex 0 so the lib's own buttons stay clickable
        local handle = Instance.new("TextButton")
        handle.Name = "LuXxS_Drag"
        handle.Size = UDim2.new(1, 0, 0, 36)
        handle.BackgroundTransparency = 1
        handle.Text = ""
        handle.AutoButtonColor = false
        handle.ZIndex = 0
        handle.Parent = root
        handle.InputBegan:Connect(function(input)
            if not menuOpen then return end
            local t = input.UserInputType
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                stopWin()
                uiScale.Scale = 1
                dragging = true
                dragStart = input.Position
                dragOrigin = root.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if not dragging then return end
            local t = input.UserInputType
            if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
            local d = input.Position - dragStart
            root.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X,
                                      dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y)
        end)
        UIS.InputEnded:Connect(function(input)
            local t = input.UserInputType
            if dragging and (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) then
                dragging = false
            end
        end)

        -- X, top right
        xBtn = Instance.new("TextButton")
        xBtn.Name = "LuXxS_Close"
        xBtn.AnchorPoint = Vector2.new(1, 0)
        xBtn.Position = UDim2.new(1, -8, 0, 8)
        xBtn.Size = UDim2.new(0, 26, 0, 26)
        xBtn.BackgroundColor3 = themeTable.LightContrast
        xBtn.AutoButtonColor = false
        xBtn.Text = ""
        xBtn.ZIndex = 100
        xBtn.Parent = root
        Instance.new("UICorner", xBtn).CornerRadius = UDim.new(0, 6)
        for _, rot in ipairs({45, -45}) do
            local ln = Instance.new("Frame")
            ln.AnchorPoint = Vector2.new(0.5, 0.5)
            ln.Position = UDim2.new(0.5, 0, 0.5, 0)
            ln.Size = UDim2.new(0, 14, 0, 2)
            ln.Rotation = rot
            ln.BorderSizePixel = 0
            ln.BackgroundColor3 = themeTable.TextColor
            ln.ZIndex = 101
            ln.Parent = xBtn
            table.insert(xLines, ln)
        end
        xBtn.MouseButton1Click:Connect(function() setMenu(false) end)

        -- keep the window on screen (not while it's animating)
        RunService.RenderStepped:Connect(function()
            if not root.Visible or winAnim then return end
            local as, vp, ap = root.AbsoluteSize, cam().ViewportSize, root.AbsolutePosition
            if as.X <= 0 or as.Y <= 0 then return end
            local dx, dy = 0, 0
            if ap.X + as.X < 40 then dx = 40 - (ap.X + as.X)
            elseif ap.X > vp.X - 40 then dx = (vp.X - 40) - ap.X end
            if ap.Y < 0 then dy = -ap.Y
            elseif ap.Y > vp.Y - 40 then dy = (vp.Y - 40) - ap.Y end
            if dx ~= 0 or dy ~= 0 then
                local p = root.Position
                root.Position = UDim2.new(p.X.Scale, p.X.Offset + dx, p.Y.Scale, p.Y.Offset + dy)
            end
        end)
        return true
    end

    ensureWindow = function()
        if not root then
            if not setupWindow() then
                collectLibGuis() -- fallback: lib may have made its gui later
                setupWindow()
            end
        end
        if DEBUG_GUI then debugTree() end
    end

    applyTheme = function()
        for name, color in pairs(themeTable) do venyx:setTheme(name, color) end
        barFrame.BackgroundColor3 = themeTable.TextColor
        if xBtn then xBtn.BackgroundColor3 = themeTable.LightContrast end
        for _, ln in ipairs(xLines) do ln.BackgroundColor3 = themeTable.TextColor end
    end
end

--================= venyx pages =================
-- === Aimbot ===
local aimPage  = venyx:addPage("Aimbot", 5892773989)
local saSec    = aimPage:addSection("Silent Aim")
local saSet    = aimPage:addSection("Silent Aim Settings")
local saVis    = aimPage:addSection("Silent Aim Visuals")
local raSec    = aimPage:addSection("Regular Aimbot")
local raSet    = aimPage:addSection("Regular Aimbot Settings")
local targetSec= aimPage:addSection("Targets")

saSec:addToggle("Silent Aim", nil, function(v) S.silentAimOn = v end)
saSet:addSlider("FOV", 0, 0, 500, function(v) S.silentAimFov = v end)
saSet:addSlider("Head hitchance", 0, 0, 100, function(v) S.silentAimHeadHitchance = v end)
saSet:addSlider("Body hitchance", 0, 0, 100, function(v) S.silentAimBodyHitchance = v end)
saVis:addToggle("Show FOV", nil, function(v) S.showSilentAimFov = v end)
saVis:addToggle("FOV Filled", nil, function(v) S.silentAimFovFilled = v end)
saVis:addSlider("FOV Thickness", 1, 1, 5, function(v) S.silentAimFovThickness = v end)
saVis:addSlider("FOV Sides", 3, 3, 100, function(v) S.silentAimFovNumSides = v end)
saVis:addSlider("FOV Transparency", 0, 0, 100, function(v) S.silentAimFovTransparency = v end)
saVis:addColorPicker("FOV Color", S.silentAimFovColor, function(c) S.silentAimFovColor = c end)

raSec:addToggle("Regular Aimbot", nil, function(v) S.aimOn = v end)
raSec:addDropdown("Activation", {"Hold RMB","Always","Touch button"}, function(t) S.aimMode = t end)
raSet:addDropdown("Target bone", {"Head","UpperTorso","HumanoidRootPart"}, function(t) S.aimBone = t end)
raSet:addSlider("Aimbot FOV", 120, 30, 600, function(v) S.aimFov = v end)
raSet:addSlider("Smoothing", 0.25, 0, 0.95, function(v) S.aimSmooth = v end)
raSet:addToggle("Show circle", nil, function(v) S.circleOn = v end)
raSet:addColorPicker("Circle color", Color3.fromHSV(S.circleHue,1,1), function(c) S.circleHue = c:ToHSV() end)
targetSec:addToggle("Team check", nil, function(v) S.aimTeam = v end)
targetSec:addToggle("Visibility check", nil, function(v) S.aimVis = v end)

-- === Visuals ===
local visPage   = venyx:addPage("Visuals", 5892783507)
local espSec    = visPage:addSection("ESP")
local espSet    = visPage:addSection("ESP Info")
local chamsSec  = visPage:addSection("Chams")
local armSec    = visPage:addSection("Arm / Weapon Chams")

espSec:addToggle("ESP", nil, function(v) S.espOn = v end)
espSec:addDropdown("Box mode", {"2D","3D","Corner","Skeleton","Markers"}, function(t) S.espShape = t end)
espSet:addToggle("Health", nil, function(v) S.espHp = v end)
espSet:addToggle("Name", nil, function(v) S.espName = v end)
espSet:addToggle("Distance", nil, function(v) S.espDist = v end)
espSet:addColorPicker("ESP Color", Color3.fromHSV(S.espHue,1,1), function(c) S.espHue = c:ToHSV() end)

chamsSec:addToggle("Chams", nil, function(v) S.chamsOn = v end)
chamsSec:addToggle("Nametags", nil, function(v) S.nameTagsOn = v end)
chamsSec:addColorPicker("Chams Color", S.chamsColor, function(c) S.chamsColor = c end)

armSec:addToggle("Arm Chams", nil, function(v) S.armChamsOn = v end)
armSec:addToggle("Weapon Chams", nil, function(v) S.weaponChamsOn = v end)
armSec:addColorPicker("Arm Color", S.armColor, function(c) S.armColor = c end)
armSec:addColorPicker("Weapon Color", S.weaponColor, function(c) S.weaponColor = c end)
armSec:addDropdown("Arm Material", {"Plastic","ForceField","Wood","Grass"}, function(t) S.armMaterial = t end)
armSec:addDropdown("Weapon Material", {"Plastic","ForceField","Wood","Grass"}, function(t) S.weaponMaterial = t end)

-- === Anti-Aim ===
local aaPage  = venyx:addPage("Anti-Aim", 5012544693)
local aaMain  = aaPage:addSection("Main")
local aaPitch = aaPage:addSection("Pitch")
local aaYaw   = aaPage:addSection("Yaw")
aaMain:addToggle("Anti-Aim", nil, function(v) S.antiAimOn = v end)
aaMain:addToggle("Disable Animations", nil, function(v) S.noAnims = v end)
aaPitch:addDropdown("Pitch Type", {"Custom","Up","Down","Zero"}, function(t) S.pitchType = t end)
aaPitch:addSlider("Pitch Value", 0, -150, 150, function(v) S.pitchValue = v/100 end)
aaYaw:addDropdown("Yaw Type", {"Custom","Jitter","Spin","Back"}, function(t) S.yawType = t end)
aaYaw:addSlider("Spin Speed", 0, 0, 100, function(v) S.aaSpinSpeed = v end)
aaYaw:addSlider("Yaw Value", 0, 0, 360, function(v) S.yawValue = v end)

-- === Movement ===
local movePage = venyx:addPage("Movement", 5012543246)
local spdSec   = movePage:addSection("Speed & Jump")
local flySec   = movePage:addSection("Fly & Spin")
local bhSec    = movePage:addSection("Bhop")
spdSec:addToggle("Walk speed on", nil, function(v) S.speedOn = v end)
spdSec:addSlider("Walk speed", 16, 16, 10000, function(v) S.walk = v end)
spdSec:addToggle("Jump power on", nil, function(v) S.jumpOn = v end)
spdSec:addSlider("Jump power", 50, 0, 10000, function(v) S.jump = v end)
spdSec:addToggle("Noclip", nil, function(v) S.noclip = v end)
spdSec:addToggle("Infinite jump", nil, function(v) S.infJump = v end)
flySec:addToggle("Fly", nil, function(v) S.fly = v end)
flySec:addSlider("Fly speed", 50, 10, 10000, function(v) S.flySpeed = v end)
flySec:addToggle("Spin", nil, function(v) S.spinOn = v end)
flySec:addSlider("Spin speed (deg/s)", 360, 1, 10000, function(v) S.spinSpeedDeg = v end)
bhSec:addToggle("Bhop", nil, function(v) S.bhopOn = v end)
bhSec:addSlider("Bhop speed", 1, 0, 100, function(v) S.bhopSpeed = v end)

-- === Screen ===
local screenPage = venyx:addPage("Screen", 5894272440)
local tpSec      = screenPage:addSection("Third person")
local fovSec     = screenPage:addSection("Camera")
local fxSec      = screenPage:addSection("Effects")
tpSec:addToggle("Third person", nil, function(v) S.tpOn = v applyThirdPerson() end)
tpSec:addSlider("Distance", 12, 4, 60, function(v) S.tpDistance = v applyThirdPerson() end)
tpSec:addSlider("Shoulder X", 0, -3, 3, function(v) S.tpX = v applyThirdPerson() end)
tpSec:addSlider("Height Y", 0, -2, 3, function(v) S.tpY = v applyThirdPerson() end)
fovSec:addToggle("Custom FOV", nil, function(v) S.fovOn = v applyFov() end)
fovSec:addSlider("FOV", 70, 30, 120, function(v) S.fov = v applyFov() end)
fxSec:addToggle("Motion blur", nil, function(v) S.blurOn = v applyBlur() end)
fxSec:addSlider("Blur strength", 10, 0, 24, function(v) S.blur = v applyBlur() end)
fxSec:addToggle("Sky color", nil, function(v) S.skyOn = v applySky() end)
fxSec:addSlider("Sky hue", 0.75, 0, 1, function(v) S.skyHue = v applySky() end)

-- === Player ===
local playerPage = venyx:addPage("Player", 5012544693)
local bodySec    = playerPage:addSection("Body")
local cosSec     = playerPage:addSection("Cosmetics")
local handsSec   = playerPage:addSection("Hands view")
bodySec:addDropdown("Wings", {"None","Angel","Demon"}, function(t) S.wings = t buildWings() end)
bodySec:addToggle("Headless", nil, function(v) S.headless = v end)
bodySec:addToggle("Legless", nil, function(v) S.legless = v end)
cosSec:addToggle("Trail", nil, function(v) S.trailOn = v buildTrail() end)
cosSec:addSlider("Trail hue", 0.75, 0, 1, function(v) S.trailHue = v buildTrail() end)
cosSec:addToggle("Chinese hat", nil, function(v) S.hatOn = v buildHat() end)
cosSec:addSlider("Hat hue", 0.1, 0, 1, function(v) S.hatHue = v buildHat() end)
cosSec:addSlider("Hat transparency", 0, 0, 1, function(v) S.hatTrans = v buildHat() end)
handsSec:addToggle("Enabled", nil, function(v) S.handsOn = v end)
handsSec:addSlider("Offset X", 0, -3, 3, function(v) S.handX = v end)
handsSec:addSlider("Offset Y", 0, -3, 3, function(v) S.handY = v end)
handsSec:addSlider("Offset Z", 0, -3, 3, function(v) S.handZ = v end)

-- === Misc ===
local miscPage = venyx:addPage("Misc", 5894272440)
local trollSec = miscPage:addSection("Troll")
local debSec   = miscPage:addSection("Local")
trollSec:addToggle("Chatspam", nil, function(v) S.chatspamOn = v if v then startChatspam() end end)
trollSec:addDropdown("Chatspam Type", {"HAMEWARE","Furry","Swiss","HvH","China"}, function(t) S.chatspamType = t end)
trollSec:addSlider("Chatspam Sleep", 1, 1, 10, function(v) S.chatspamWait = v end)
debSec:addToggle("Collect Debris", nil, function(v) S.collectDebris = v end)

-- === Config (через keybinds) ===
local cfgPage = venyx:addPage("Config", 5012544693)
local cfgSec  = cfgPage:addSection("Config")
local function cfgPath() return "luxxs_hub_config.json" end
cfgSec:addKeybind("Save config (F5)", Enum.KeyCode.F5, function()
    if not HAS_FS then return end
    pcall(function() writefile(cfgPath(), HttpService:JSONEncode(S)) end)
end, function() end)
cfgSec:addKeybind("Load config (F9)", Enum.KeyCode.F9, function()
    if not HAS_FS then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(cfgPath())) end)
    if not ok or type(data) ~= "table" then return end
    for k, v in pairs(data) do if S[k] ~= nil then S[k] = v end end
    applyBlur() applyFov() applySky() applyThirdPerson()
    rebuildCosmetics() refreshShoulders()
end, function() end)

-- === GUI ===
local guiPage = venyx:addPage("GUI", 5012543246)
local colors  = guiPage:addSection("Theme colors")
local guiTog  = guiPage:addSection("GUI")
for name, color in pairs(themeTable) do
    colors:addColorPicker(name, color, function(c) themeTable[name] = c applyTheme() end)
end
guiTog:addKeybind("GUI Toggle (Insert)", Enum.KeyCode.Insert, function()
    toggleMenu()
end, function() end)

ensureWindow()
applyTheme()
venyx:SelectPage(venyx.pages[1], true)

--================= render loop: aim =================
RunService:BindToRenderStep("luxxs_aim", Enum.RenderPriority.Camera.Value + 1, function()
    local c = cam() if not c then return end
    local center = screenCenter()

    if S.silentAimOn then
        local rnd = math.random(0,100)
        if S.silentAimHeadHitchance <= rnd then bodyname = "UpperTorso"
        elseif S.silentAimBodyHitchance >= rnd then bodyname = "Head"
        else bodyname = "Head" end
        local t = GetTarget()
        target = t or hed
        if silentCircle then
            silentCircle.Visible = S.showSilentAimFov
            silentCircle.Position = center
            silentCircle.Radius = S.silentAimFov
            silentCircle.NumSides = S.silentAimFovNumSides
            silentCircle.Thickness = S.silentAimFovThickness
            silentCircle.Filled = S.silentAimFovFilled
            silentCircle.Color = S.silentAimFovColor
            silentCircle.Transparency = S.silentAimFovTransparency / 100
        end
    elseif silentCircle then silentCircle.Visible = false end

    if regularCircle then
        regularCircle.Visible = S.circleOn
        regularCircle.Position = center
        regularCircle.Radius = S.aimFov
        regularCircle.Color = hue(S.circleHue)
    end
    if S.aimOn and aimActive() then
        local t = findTargetAim(center)
        if t then aimAt(t, center, c) end
    end
end)

--================= heartbeat =================
local flyWasOn = false
local ltmTouched = setmetatable({}, {__mode = "k"})

RunService.Heartbeat:Connect(function(dt)
    local ch = LP.Character
    local h, r = hum(), hrp()
    if not (ch and h and r) or h.Health <= 0 then return end

    if S.speedOn then h.WalkSpeed = S.walk end
    if S.jumpOn then h.UseJumpPower = true h.JumpPower = S.jump end
    if S.noclip then
        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    if S.bhopOn and UIS:IsKeyDown(Enum.KeyCode.Space) then
        h.Jump = true h.WalkSpeed = S.bhopSpeed
    end

    if S.fly then
        if not flyWasOn then flyWasOn = true h.PlatformStand = true end
        local camCF = cam().CFrame
        local rel = camCF:VectorToObjectSpace(h.MoveDirection)
        local dir = camCF.LookVector * (-rel.Z) + camCF.RightVector * rel.X
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        if dir.Magnitude > 1 then dir = dir.Unit end
        r.AssemblyLinearVelocity = dir * S.flySpeed
        local flat = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
        if flat.Magnitude > 0.05 then r.CFrame = CFrame.new(r.Position, r.Position + flat) end
    elseif flyWasOn then
        flyWasOn = false h.PlatformStand = false
        r.AssemblyLinearVelocity = Vector3.zero h:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    if S.spinOn and not S.fly then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(S.spinSpeedDeg * dt), 0) end

    -- headless/legless
    local fp = isFirstPerson()
    for _, p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then
            local leg = string.find(p.Name, "Leg") ~= nil or string.find(p.Name, "Foot") ~= nil
            local hide = (p.Name == "Head" and S.headless) or (leg and S.legless)
            if hide then p.LocalTransparencyModifier = 1 ltmTouched[p] = true
            elseif ltmTouched[p] then ltmTouched[p] = nil p.LocalTransparencyModifier = (p.Name == "Head" and fp) and 1 or 0 end
        end
    end

    -- anti-aim yaw
    if S.antiAimOn then
        if S.yawType == "Custom" then characterrotate(CFrame.new(S.yawValue, 0, 0))
        elseif S.yawType == "Jitter" then
            local spin = Instance.new('BodyAngularVelocity', r)
            spin.AngularVelocity = Vector3.new(0, math.random(-60000,55000), 0)
            spin.MaxTorque = Vector3.new(0, 35000, 0)
            wait() spin:Destroy()
        elseif S.yawType == "Spin" then
            local spin = Instance.new('BodyAngularVelocity', r)
            spin.AngularVelocity = Vector3.new(0, S.aaSpinSpeed * 100, 0)
            spin.MaxTorque = Vector3.new(0, 23000, 0)
            wait() spin:Destroy()
        elseif S.yawType == "Back" then
            characterrotate((cam().CFrame * CFrame.new(-4,0,0)).p)
        end
    end

    -- collect debris
    if S.collectDebris then
        local deb = Workspace:FindFirstChild("Debris")
        if deb then
            for _, v in pairs(deb:GetChildren()) do
                if v.Name == "DeadHP" or v.Name == "DeadAmmo" then
                    v.CFrame = r.CFrame * CFrame.new(0, 0.2, 0)
                end
            end
        end
    end

    -- arm / weapon chams
    if Workspace.Camera:FindFirstChild("Arms") then
        for _, v in pairs(Workspace.Camera.Arms:GetDescendants()) do
            if (v.Name == "Right Arm" or v.Name == "Left Arm") and v:IsA("BasePart") and S.armChamsOn then
                v.Material = Enum.Material[S.armMaterial]
                v.Color = S.armColor
            end
            if v:IsA("MeshPart") and S.weaponChamsOn then
                v.Material = Enum.Material[S.weaponMaterial]
                v.Color = S.weaponColor
            end
        end
    end
end)

--================= render: cosmetics + esp + chams =================
RunService.RenderStepped:Connect(function()
    local r = hrp()
    if r then for i, p in ipairs(wingParts) do p.CFrame = r.CFrame * wingOffs[i] end end
    local ch = LP.Character
    local head = ch and ch:FindFirstChild("Head")
    if head and #hatParts >= 2 then
        hatParts[1].CFrame = head.CFrame * CFrame.new(0,0.62,0) * CFrame.Angles(0,0,math.rad(90))
        hatParts[2].CFrame = head.CFrame * CFrame.new(0,1.32,0)
        for _, p in ipairs(hatParts) do p.Color = hue(S.hatHue) p.Transparency = S.hatTrans end
    end
    if trail then trail.Color = ColorSequence.new(hue(S.trailHue)) end
    if S.skyOn then local c = hue(S.skyHue) atmos.Color = c atmos.Decay = c end
    applyHands()
    espDraw()
    if S.chamsOn or S.nameTagsOn then updateChams() updateNameTags() end
end)

--================= input =================
UIS.JumpRequest:Connect(function()
    if not S.infJump or S.fly then return end
    local h, r = hum(), hrp() if not (h and r) then return end
    local v = r.AssemblyLinearVelocity
    r.AssemblyLinearVelocity = Vector3.new(v.X, math.max(S.jump, 50), v.Z)
    h:ChangeState(Enum.HumanoidStateType.Jumping)
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then aimRMB = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then aimRMB = false
    elseif input.UserInputType == Enum.UserInputType.Touch then aimTouch = false end
end)

--================= init =================
applyBlur() applySky() applyFov() applyThirdPerson() refreshShoulders()
if S.wings ~= "None" or S.trailOn or S.hatOn then rebuildCosmetics() end
