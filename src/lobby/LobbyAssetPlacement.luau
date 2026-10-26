--!strict
-- Studio-owned FBX templates live in ServerStorage/LobbyAssets. The lobby
-- keeps its authored collision parts; imported meshes are visual only.
local ServerStorage = game:GetService("ServerStorage")

local LobbyAssetPlacement = {}

local specs = {
    {
        name = "PlanningTable", template = "A1_PlanningTable",
        center = Vector3.new(0, 1.9, 3), bounds = Vector3.new(16, 3.8, 11),
        visuals = { PlanTableLeg = true, PlanningTable = true,
            Blueprint = true, BlueprintRoute = true },
        shadow = true,
    },
    {
        name = "Vault", template = "A2_VaultDoor",
        center = Vector3.new(0, 6, -33.6), bounds = Vector3.new(18, 12, 2.2),
        yawDegrees = 180, placementVersion = 2,
        visuals = { VaultFrame = true, VaultDoor = true,
            VaultLockBar = true, VaultHinge = true },
        shadow = true,
    },
    {
        name = "ArmoryCase", template = "A3_ArmoryCase",
        center = Vector3.new(-29, 4, -15), bounds = Vector3.new(12, 8, 11),
        visuals = { DisplayPlinth = true, CaseGlassFront = true,
            CaseGlassBack = true, CaseGlassSide = true, CaseTop = true,
            ToolStand = true, ScannerBody = true, ScannerScreen = true,
            ToolGrip = true },
        shadow = false,
    },
    {
        name = "CollectorCase", template = "A4_CollectorCase",
        center = Vector3.new(29, 4, -15), bounds = Vector3.new(12, 8, 11),
        visuals = { DisplayPlinth = true, CaseGlassFront = true,
            CaseGlassBack = true, CaseGlassSide = true, CaseTop = true,
            ArtifactBase = true, OriginalArtwork = true, ArtworkMotif = true },
        shadow = false,
    },
    {
        name = "Locker1", template = "A5_EquipmentLocker",
        center = Vector3.new(18, 4.5, 25), bounds = Vector3.new(5, 9, 3.4),
        visuals = { Locker = true, LockerDoor = true, LockerHandle = true },
        shadow = false,
    },
    {
        name = "Locker2", template = "A5_EquipmentLocker",
        center = Vector3.new(24, 4.5, 25), bounds = Vector3.new(5, 9, 3.4),
        visuals = { Locker = true, LockerDoor = true, LockerHandle = true },
        shadow = false,
    },
    {
        name = "Locker3", template = "A5_EquipmentLocker",
        center = Vector3.new(30, 4.5, 25), bounds = Vector3.new(5, 9, 3.4),
        visuals = { Locker = true, LockerDoor = true, LockerHandle = true },
        shadow = false,
    },
    {
        name = "Couch", template = "A6_CrewCouch",
        center = Vector3.new(-26, 1.905, 22), bounds = Vector3.new(14.55, 3.81, 5.125),
        visuals = { CouchSeat = true, CouchBack = true, CouchArm = true },
        shadow = false,
    },
}

local function wrapTemplate(template: Instance): Model?
    local cloned = template:Clone()
    if cloned:IsA("Model") then return cloned end
    if cloned:IsA("BasePart") then
        local wrapper = Instance.new("Model")
        cloned.Parent = wrapper
        return wrapper
    end
    cloned:Destroy()
    return nil
end

local function inRegion(position: Vector3, spec: any): boolean
    local delta = position - spec.center
    return math.abs(delta.X) <= spec.bounds.X / 2 + 2
        and math.abs(delta.Z) <= spec.bounds.Z / 2 + 2
end

local function hideOldVisuals(lobby: Model, spec: any)
    for _, child in lobby:GetChildren() do
        if child:IsA("BasePart") and spec.visuals[child.Name]
            and inRegion(child.Position, spec) then
            if child:GetAttribute("LobbyOriginalTransparency") == nil then
                child:SetAttribute("LobbyOriginalTransparency", child.Transparency)
            end
            child.Transparency = 1
            -- Keep the authored collision hulls. Seat collision and prompts
            -- remain controlled by LobbyWorld and LobbySeatingService.
        end
    end
    if spec.name == "Couch" then
        for _, name in { "LoungeSeat1", "LoungeSeat2" } do
            local seat = lobby:FindFirstChild(name)
            if seat and seat:IsA("Seat") then
                if seat:GetAttribute("LobbyOriginalTransparency") == nil then
                    seat:SetAttribute("LobbyOriginalTransparency", seat.Transparency)
                end
                seat.Transparency = 1
            end
        end
    end
end

local function restoreOldVisuals(lobby: Model, spec: any)
    for _, child in lobby:GetChildren() do
        if child:IsA("BasePart") and spec.visuals[child.Name]
            and inRegion(child.Position, spec) then
            local original = child:GetAttribute("LobbyOriginalTransparency")
            if type(original) == "number" then child.Transparency = original end
        end
    end
    if spec.name == "Couch" then
        for _, name in { "LoungeSeat1", "LoungeSeat2" } do
            local seat = lobby:FindFirstChild(name)
            if seat and seat:IsA("Seat") then
                local original = seat:GetAttribute("LobbyOriginalTransparency")
                if type(original) == "number" then seat.Transparency = original end
            end
        end
    end
end

local function fit(model: Model, spec: any): boolean
    local _, firstSize = model:GetBoundingBox()
    if firstSize.X <= 0 or firstSize.Y <= 0 or firstSize.Z <= 0 then
        return false
    end
    local factor = math.min(spec.bounds.X / firstSize.X,
        spec.bounds.Y / firstSize.Y, spec.bounds.Z / firstSize.Z)
    if factor <= 0 or factor ~= factor then return false end
    model:ScaleTo(model:GetScale() * factor)
    local box = model:GetBoundingBox()
    local offset = model:GetPivot():ToObjectSpace(box)
    local targetBox = CFrame.new(spec.center)
        * CFrame.Angles(0, math.rad(spec.yawDegrees or 0), 0)
    model:PivotTo(targetBox * offset:Inverse())
    return true
end

-- FBX import does not carry the Blender materials into these MeshParts. Keep
-- the imported geometry, but assign a restrained hideout palette by part name.
local function styleMesh(part: BasePart, spec: any)
    local name = string.lower(part.Name)
    local color = Color3.fromRGB(58, 69, 75)
    local material = Enum.Material.Metal
    local transparency = 0
    if spec.name == "PlanningTable" then
        if string.find(name, "blueprint") then
            color = Color3.fromRGB(25, 93, 105)
            material = Enum.Material.Neon
        elseif string.find(name, "route") or string.find(name, "mission") then
            color = Color3.fromRGB(234, 171, 83)
            material = Enum.Material.Neon
        elseif string.find(name, "button") then
            color = Color3.fromRGB(74, 210, 219)
            material = Enum.Material.Neon
        elseif string.find(name, "worktop") then
            color = Color3.fromRGB(37, 49, 56)
        elseif string.find(name, "folder") then
            color = Color3.fromRGB(136, 102, 62)
            material = Enum.Material.SmoothPlastic
        end
    elseif spec.name == "Vault" then
        if string.find(name, "led") then
            color = Color3.fromRGB(52, 205, 215)
            material = Enum.Material.Neon
        elseif string.find(name, "bolt") or string.find(name, "hub")
            or string.find(name, "spoke") or string.find(name, "ring") then
            color = Color3.fromRGB(175, 126, 67)
        elseif string.find(name, "backplate") then
            color = Color3.fromRGB(26, 35, 42)
        end
    elseif string.find(spec.name, "Case") then
        if string.find(name, "glass") then
            color = Color3.fromRGB(108, 184, 193)
            material = Enum.Material.Glass
            transparency = 0.55
        elseif string.find(name, "glow") or string.find(name, "display") then
            color = Color3.fromRGB(46, 190, 203)
            material = Enum.Material.Neon
        elseif string.find(name, "art") or string.find(name, "motif") then
            color = Color3.fromRGB(185, 131, 75)
        elseif string.find(name, "plaque") or string.find(name, "text") then
            color = Color3.fromRGB(192, 152, 91)
        end
    elseif string.find(spec.name, "Locker") then
        if string.find(name, "handle") or string.find(name, "identifier")
            or string.find(name, "numberplate") then
            color = Color3.fromRGB(182, 136, 75)
        elseif string.find(name, "door") then
            color = Color3.fromRGB(76, 91, 98)
        end
    elseif spec.name == "Couch" then
        if string.find(name, "cushion") or string.find(name, "upholstered")
            or string.find(name, "armrest") then
            color = Color3.fromRGB(61, 105, 108)
            material = Enum.Material.Fabric
        elseif string.find(name, "leg") then
            color = Color3.fromRGB(111, 84, 58)
        end
    end
    part.Color = color
    part.Material = material
    part.Transparency = transparency
end

local function alignCouchSeats(lobby: Model, couch: Model)
    local cushions = {}
    for _, child in couch:GetDescendants() do
        if child:IsA("BasePart") and string.find(child.Name, "Seat_Cushion", 1, true) == 1 then
            table.insert(cushions, child)
        end
    end
    table.sort(cushions, function(a, b) return a.Position.X < b.Position.X end)
    if #cushions ~= 2 then
        warn("[Steal Anything Lobby] Couch needs exactly two Seat_Cushion meshes")
        return
    end
    for index, cushion in cushions do
        local seat = lobby:FindFirstChild("LoungeSeat" .. index)
        if seat and seat:IsA("Seat") then
            seat.Position = Vector3.new(cushion.Position.X,
                cushion.Position.Y + cushion.Size.Y / 2 - seat.Size.Y / 2,
                cushion.Position.Z)
        end
    end
end

function LobbyAssetPlacement.Apply(lobby: Model): {string}
    local folder = ServerStorage:FindFirstChild("LobbyAssets")
    local missing = {}
    for _, spec in specs do
        local previous = lobby:FindFirstChild("Imported" .. spec.name)
        local placementVersion = spec.placementVersion or 1
        if previous and previous:IsA("Model")
            and previous:GetAttribute("LobbyAssetPlacementVersion") == placementVersion then
            continue
        end
        local template = folder and folder:FindFirstChild(spec.template)
        if not template then
            table.insert(missing, spec.template)
            if not lobby:FindFirstChild("Imported" .. spec.name) then
                restoreOldVisuals(lobby, spec)
            end
            continue
        end
        local model = wrapTemplate(template)
        if not model then
            table.insert(missing, spec.template .. " (not a model or part)")
            if not lobby:FindFirstChild("Imported" .. spec.name) then
                restoreOldVisuals(lobby, spec)
            end
            continue
        end
        model.Name = "Imported" .. spec.name
        local solidCount = 0
        for _, descendant in model:GetDescendants() do
            if descendant:IsA("BasePart") then
                solidCount += 1
                descendant.Anchored = true
                descendant.CanCollide = false
                descendant.CanTouch = false
                descendant.CanQuery = false
                descendant.CastShadow = spec.shadow
                styleMesh(descendant, spec)
            end
        end
        if solidCount == 0 or not fit(model, spec) then
            model:Destroy()
            table.insert(missing, spec.template .. " (empty or invalid bounds)")
            if not lobby:FindFirstChild("Imported" .. spec.name) then
                restoreOldVisuals(lobby, spec)
            end
            continue
        end
        if previous then previous:Destroy() end
        model:SetAttribute("LobbyAssetPlacementVersion", placementVersion)
        model.Parent = lobby
        if spec.name == "Couch" then alignCouchSeats(lobby, model) end
        hideOldVisuals(lobby, spec)
    end
    if #missing > 0 then
        warn("[Steal Anything Lobby] Missing imported templates: "
            .. table.concat(missing, ", "))
    end
    return missing
end

return table.freeze(LobbyAssetPlacement)
