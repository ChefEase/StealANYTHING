-- Geometry effects render in both the world and wardrobe ViewportFrames.
local RunService = game:GetService("RunService")
local Recipes = require(script.Parent.SignatureVfxRecipes)
local Vfx = {}
local started = false

function Vfx.Attach(root, parent, recipe, offset, size)
    local marker = Instance.new("Folder")
    marker.Name = "SignatureVfx"
    marker:SetAttribute("Recipe", recipe)
    marker:SetAttribute("Offset", offset or CFrame.identity)
    marker:SetAttribute("Size", size or Vector3.new(4, 6, 2))
    local reference = Instance.new("ObjectValue")
    reference.Name = "Root"
    reference.Value = root
    reference.Parent = marker
    marker.Parent = parent
    return marker
end

local function build(marker)
    local reference = marker:FindFirstChild("Root")
    local recipe = Recipes[marker:GetAttribute("Recipe")]
    if not reference or not reference.Value or not recipe then return nil end
    local folder = Instance.new("Folder")
    folder.Name = "LocalSignatureGeometry"
    folder.Parent = marker
    local rig = { folder = folder, root = reference.Value,
        offset = marker:GetAttribute("Offset"), size = marker:GetAttribute("Size") }
    function rig:Part(name, size, color, shape, material)
        local p = Instance.new(if shape == "Wedge" then "WedgePart" else "Part")
        p.Name = name
        if shape == "Ball" then p.Shape = Enum.PartType.Ball end
        p.Size, p.Color = size, color
        p.Material = material or Enum.Material.Neon
        p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
        p.CastShadow, p.Transparency = false, 1
        p.Parent = folder
        return p
    end
    function rig:Pose(p, cf, alpha, size)
        p.CFrame = self.origin * cf
        p.Transparency = math.clamp(alpha or 0, 0, 1)
        if size then p.Size = size end
    end
    function rig:Line(p, a, b, width, alpha)
        self:Pose(p, CFrame.lookAt((a + b) / 2, b), alpha,
            Vector3.new(width, width, math.max(0.01, (a - b).Magnitude)))
    end
    local animate = recipe(rig)
    function rig:Update(t, reduced)
        self.origin = self.root.CFrame * self.offset
        animate(if reduced then 1.25 else t)
    end
    return rig
end

function Vfx.Preview(model)
    local rigs = {}
    for _, marker in model:GetDescendants() do
        if marker.Name == "SignatureVfx" and marker:IsA("Folder") then
            local rig = build(marker)
            if rig then table.insert(rigs, rig) end
        end
    end
    return rigs
end

function Vfx.UpdatePreview(rigs, t, reduced)
    for _, rig in rigs or {} do rig:Update(t, reduced) end
end

function Vfx.Start()
    if started then return end
    started = true
    local markers = {}
    local function add(marker)
        if marker.Name == "SignatureVfx" and marker:IsA("Folder") then markers[marker] = false end
    end
    workspace.DescendantAdded:Connect(add)
    for _, marker in workspace:GetDescendants() do add(marker) end
    local elapsed = 0
    RunService.RenderStepped:Connect(function(dt)
        elapsed += dt
        if elapsed < 1 / 30 then return end
        elapsed = 0
        local camera = workspace.CurrentCamera
        if not camera then return end
        local player = game:GetService("Players").LocalPlayer
        local reduced = player and player:GetAttribute("ReduceMotion") == true
        for marker, rig in markers do
            if not marker:IsDescendantOf(workspace) then
                if rig then rig.folder:Destroy() end
                markers[marker] = nil
            else
                local reference = marker:FindFirstChild("Root")
                local root = reference and reference.Value
                local near = root and (root.Position - camera.CFrame.Position).Magnitude < 85
                if near then
                    if not rig then rig = build(marker); markers[marker] = rig or false end
                    if rig then rig:Update(os.clock(), reduced) end
                elseif rig then
                    rig.folder:Destroy()
                    markers[marker] = false
                end
            end
        end
    end)
end

return Vfx
