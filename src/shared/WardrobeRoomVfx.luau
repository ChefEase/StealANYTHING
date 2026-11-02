--!strict

-- Local scanning effect on the locker bank. Only this player's client animates it.
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local WardrobeRoomVfx = {}
local started: {[Player]: boolean} = {}
local CYAN = Color3.fromRGB(83, 246, 215)
local PALE = Color3.fromRGB(184, 255, 237)

function WardrobeRoomVfx.Start(player: Player)
    if started[player] then return end
    started[player] = true
    task.spawn(function()
        local lobby = workspace:WaitForChild("HeistLobby", 60)
        local beacon = lobby and lobby:WaitForChild("WardrobeRoomBeacon", 60)
        local header = beacon and beacon:WaitForChild("LockerPortalHeader", 60)
        if not beacon or not header or not header:IsA("BasePart") then return end
        local light = header:FindFirstChild("WardrobeRoomLight")

        -- A projected scan travels across the locker doors. It does not block
        -- walking and uses no uploaded texture or mesh.
        local scan = Instance.new("Part")
        scan.Name = "LocalWardrobeScan"
        scan.Anchored = true
        scan.CanCollide = false
        scan.CanTouch = false
        scan.CanQuery = false
        scan.CastShadow = false
        scan.Material = Enum.Material.Neon
        scan.Color = CYAN
        scan.Size = Vector3.new(1.5, 7.3, 0.06)
        scan.Transparency = 0.72
        scan.CFrame = CFrame.new(15.9, 4.8, 23.12)
        scan.Parent = beacon
        local projection = Instance.new("Part")
        projection.Name = "LocalWardrobeProjection"
        projection.Anchored = true
        projection.CanCollide = false
        projection.CanTouch = false
        projection.CanQuery = false
        projection.CastShadow = false
        projection.Material = Enum.Material.Neon
        projection.Color = CYAN
        projection.Size = Vector3.new(2.4, 0.025, 3.2)
        projection.Transparency = 0.84
        projection.Parent = beacon

        -- A floating jacket silhouette is the focal projection for the room.
        -- It is clothing alone, suspended above the locker bank, not another
        -- mannequin or a gameplay pickup.
        local garment = Instance.new("Model")
        garment.Name = "LocalWardrobeGarmentProjection"
        garment.Parent = beacon
        local garmentParts: {BasePart} = {}
        local trimParts: {BasePart} = {}
        local function fabric(name: string, size: Vector3, offset: CFrame,
            trim: boolean?)
            local piece = Instance.new("Part")
            piece.Name = name
            piece.Size = size
            piece.Anchored = true
            piece.CanCollide = false
            piece.CanTouch = false
            piece.CanQuery = false
            piece.CastShadow = false
            piece.Material = Enum.Material.Neon
            piece.Color = if trim then PALE else CYAN
            piece.Transparency = if trim then 0.18 else 0.44
            piece.CFrame = CFrame.new(24, 7.2, 22.7) * offset
            piece.Parent = garment
            table.insert(garmentParts, piece)
            if trim then table.insert(trimParts, piece) end
            return piece
        end
        garment.PrimaryPart = fabric("JacketBody", Vector3.new(2.9, 3.4, 0.1), CFrame.new())
        fabric("LeftSleeve", Vector3.new(0.9, 2.6, 0.1),
            CFrame.new(-1.75, 0.25, 0) * CFrame.Angles(0, 0, math.rad(-23)))
        fabric("RightSleeve", Vector3.new(0.9, 2.6, 0.1),
            CFrame.new(1.75, 0.25, 0) * CFrame.Angles(0, 0, math.rad(23)))
        fabric("JacketHem", Vector3.new(3.1, 0.22, 0.12), CFrame.new(0, -1.7, 0))
        fabric("LeftCollar", Vector3.new(0.25, 1.1, 0.12),
            CFrame.new(-0.5, 1.46, 0) * CFrame.Angles(0, 0, math.rad(35)))
        fabric("RightCollar", Vector3.new(0.25, 1.1, 0.12),
            CFrame.new(0.5, 1.46, 0) * CFrame.Angles(0, 0, math.rad(-35)))
        fabric("JacketZipper", Vector3.new(0.075, 2.7, 0.035),
            CFrame.new(0, -0.15, -0.075), true)
        for _, side in { -1, 1 } do
            fabric("PocketSeam", Vector3.new(0.75, 0.065, 0.04),
                CFrame.new(side * 0.82, -0.78, -0.08), true)
            fabric("ShoulderStripe", Vector3.new(0.9, 0.055, 0.04),
                CFrame.new(side * 1.2, 1.22, -0.08)
                    * CFrame.Angles(0, 0, math.rad(side * 18)), true)
        end
        local top = Instance.new("Attachment")
        top.Position = Vector3.new(0, scan.Size.Y / 2, 0)
        top.Parent = scan
        local bottom = Instance.new("Attachment")
        bottom.Position = Vector3.new(0, -scan.Size.Y / 2, 0)
        bottom.Parent = scan
        local afterimage = Instance.new("Trail")
        afterimage.Name = "WardrobeScanAfterimage"
        afterimage.Attachment0 = top
        afterimage.Attachment1 = bottom
        afterimage.Color = ColorSequence.new(CYAN, PALE)
        afterimage.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.78),
            NumberSequenceKeypoint.new(1, 1),
        })
        afterimage.Lifetime = 0.22
        afterimage.LightEmission = 0.6
        afterimage.FaceCamera = true
        afterimage.Parent = scan

        local emitters: {ParticleEmitter} = {}
        for _, offset in { -6, 0, 6 } do
            local mount = Instance.new("Attachment")
            mount.Name = "LocalWardrobeDust"
            mount.Position = Vector3.new(offset, -3.8, 0)
            mount.Parent = header
            local dust = Instance.new("ParticleEmitter")
            dust.Name = "WardrobeRisingMotifs"
            dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            dust.Color = ColorSequence.new(CYAN, PALE)
            dust.LightEmission = 0.65
            dust.Lifetime = NumberRange.new(0.8, 1.35)
            dust.Speed = NumberRange.new(0.9, 1.7)
            dust.SpreadAngle = Vector2.new(28, 28)
            dust.EmissionDirection = Enum.NormalId.Top
            dust.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.24),
                NumberSequenceKeypoint.new(1, 0),
            })
            dust.Rate = 6
            dust.Parent = mount
            table.insert(emitters, dust)
        end

        local excitedUntil = 0
        ProximityPromptService.PromptShown:Connect(function(prompt)
            if prompt.Name ~= "OpenWardrobe" or not prompt:IsDescendantOf(lobby) then return end
            excitedUntil = os.clock() + 1.1
            if player:GetAttribute("LowEffects") ~= true
                and player:GetAttribute("ReduceMotion") ~= true then
                for _, emitter in emitters do emitter:Emit(6) end
            end
        end)

        local elapsed = 0
        local connection: RBXScriptConnection? = nil
        connection = RunService.Heartbeat:Connect(function(dt)
            if beacon.Parent == nil then
                if connection then connection:Disconnect() end
                scan:Destroy()
                projection:Destroy()
                garment:Destroy()
                return
            end
            elapsed += dt
            if elapsed < 0.06 then return end
            elapsed = 0
            local still = player:GetAttribute("ReduceMotion") == true
                or player:GetAttribute("LowEffects") == true
            scan.Transparency = if still then 1
                elseif os.clock() < excitedUntil then 0.46 else 0.72
            projection.Transparency = if still then 1
                elseif os.clock() < excitedUntil then 0.68 else 0.84
            afterimage.Enabled = not still
            for _, emitter in emitters do emitter.Enabled = not still end
            for _, piece in garmentParts do
                piece.Transparency = if still then 1
                    else 0.26 + (math.sin(os.clock() * 1.35) + 1) * 0.11
            end
            if not still then
                for _, piece in trimParts do piece.Transparency = 0.08 end
            end
            if light and light:IsA("PointLight") then
                light.Brightness = if still then 0.8
                    elseif os.clock() < excitedUntil then 2 else 1.15
            end
            if still then return end
            local phase = (os.clock() * 0.23) % 2
            local along = if phase < 1 then phase else 2 - phase
            local x = 15.9 + along * 16.2
            scan.CFrame = CFrame.new(x, 4.8, 23.12)
            projection.CFrame = CFrame.new(x, 0.055, 21.2)
            garment:PivotTo(CFrame.new(24, 7.2 + math.sin(os.clock() * 1.1) * 0.22, 22.7)
                * CFrame.Angles(0, math.sin(os.clock() * 0.5) * 0.22, 0))
        end)
    end)
end

return table.freeze(WardrobeRoomVfx)
