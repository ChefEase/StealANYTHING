-- Run in Studio Edit after Rojo sync. The temporary preview is always removed.
local PathfindingService = game:GetService("PathfindingService")
local pack = game.ServerStorage.Assets.Task11MapTemplates
local services = game.ServerScriptService.Server.Services
local source = assert(pack:FindFirstChild("SixPlotWorldTemplate"))
local old = workspace:FindFirstChild("UrbanDistrictValidation")
if old then
    assert(old:GetAttribute("GeneratedBy") == "validate_district_urban",
        "Refusing to remove an unrelated model")
    old:Destroy()
end

local world = source:Clone()
world.Name = "UrbanDistrictValidation"
world.Archivable = false
world:SetAttribute("GeneratedBy", "validate_district_urban")
world:PivotTo(CFrame.new(4000, 0.5, 0) * source:GetPivot())
local urbanCopy = services.DistrictUrbanVisuals:Clone()
urbanCopy.Name = "UrbanValidationModule"
urbanCopy.Parent = services
local detailCopy = services.DistrictOutdoorDetail:Clone()
detailCopy.Name = "ParcelValidationModule"
detailCopy.Parent = services

local ok, result = pcall(function()
    require(urbanCopy).Build(world)
    local detail = require(detailCopy)
    detail.Build(world)
    require(services.WorldCollision).Prepare(world)
    world.Parent = workspace

    assert(#world.VacantPlotScenery:GetChildren() == 6, "Missing vacant parcel")
    local proxyCount = 0
    for _, item in world.UrbanDistrict:GetDescendants() do
        if item:IsA("BasePart") and item.Name == "CollisionProxy" then
            proxyCount += 1
            local right = item.CFrame.RightVector
            local forward = item.CFrame.LookVector
            local halfX = math.abs(right.X) * item.Size.X / 2
                + math.abs(forward.X) * item.Size.Z / 2
            local halfZ = math.abs(right.Z) * item.Size.X / 2
                + math.abs(forward.Z) * item.Size.Z / 2
            for _, slot in world.PlotSlots:GetChildren() do
                local envelope = slot.MaximumEnvelope
                assert(math.abs(item.Position.X - envelope.Position.X) >= halfX + 140
                    or math.abs(item.Position.Z - envelope.Position.Z) >= halfZ + 140,
                    item:GetFullName() .. " enters " .. slot.Name .. " upgrade reservation")
            end
        end
    end
    assert(proxyCount == 46, "Urban module count changed; inspect the route clearances")

    local function checkPath(a, b, name)
        local path = PathfindingService:CreatePath({
            AgentRadius = 4, AgentHeight = 6, AgentCanJump = false,
        })
        path:ComputeAsync(a + Vector3.new(0, 4, 0), b + Vector3.new(0, 4, 0))
        assert(path.Status == Enum.PathStatus.Success, name .. " has no walking path")
    end
    local depot = world.Depot.Platform.Position
    for index = 1, 6 do
        local gate = world.PlotSlots[string.format("plot_%02d", index)].GateTier1.Position
        checkPath(depot, gate, "open route " .. index)
        local a = depot
        for _, b in {
            world.Routes["Covered" .. index .. "Waypoint1"].Position,
            world.Routes["Covered" .. index .. "Waypoint2"].Position,
            gate,
        } do
            checkPath(a, b, "covered route " .. index)
            a = b
        end
    end

    detail.Hide("plot_01")
    assert(#world.VacantPlotScenery:GetChildren() == 5, "Owned plot kept its vacant annex")
    local museum = pack.StarterMuseumTemplate:Clone()
    local transform = CFrame.new(4000, 0.5, 360)
    museum:PivotTo(transform)
    local grounds = pack.LandscapePresets.formal_garden:Clone()
    grounds:PivotTo(transform * grounds:GetPivot())
    grounds.Parent = museum
    require(services.WorldCollision).Prepare(museum)
    for _, name in {"RaidEntrance", "Approach"} do
        local marker = museum:FindFirstChild(name, true)
        if marker and marker:IsA("BasePart") then
            marker.CanCollide = false
            marker.CanQuery = false
        end
    end
    museum.Parent = world
    checkPath(world.PlotSlots.plot_01.GateTier1.Position,
        museum:FindFirstChild("ReceivingZone", true).Position, "museum entrance")
    museum:Destroy()
    detail.Show(world, "plot_01")
    detail.Show(world, "plot_01")
    assert(#world.VacantPlotScenery:GetChildren() == 6, "Vacant annex did not restore exactly once")

    local parts = 0
    for _, item in world:GetDescendants() do
        if item:IsA("BasePart") then parts += 1 end
    end
    return {passed = true, urbanModules = proxyCount, worldParts = parts,
        routes = 6, coveredSegments = 18, vacantPlots = 6}
end)

world:Destroy()
urbanCopy:Destroy()
detailCopy:Destroy()
assert(ok, result)
return result
