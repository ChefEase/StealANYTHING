--!strict

-- A tiny projected museum and moving route markers on the heist table.
-- Decorative only: it never shows actual player/guard positions.
local RunService = game:GetService("RunService")

local LobbyPlanningVfx = {}
local started: {[Player]: boolean} = {}
local CYAN = Color3.fromRGB(103, 240, 224)
local GOLD = Color3.fromRGB(255, 202, 112)

function LobbyPlanningVfx.Start(player: Player)
    if started[player] then return end
    started[player] = true
    task.spawn(function()
        local lobby = workspace:WaitForChild("HeistLobby", 60)
        local tableTop = lobby and lobby:WaitForChild("PlanningTable", 60)
        if not lobby or not tableTop or not tableTop:IsA("BasePart") then return end
        local projection = Instance.new("Model")
        projection.Name = "LocalHeistPlanProjection"
        projection.Parent = lobby
        local pieces: {BasePart} = {}
        local center = tableTop.Position + Vector3.new(0, 2, 0)
        local function shape(name: string, size: Vector3, offset: Vector3, color: Color3)
            local part = Instance.new("Part")
            part.Name = name
            part.Size = size
            part.Position = center + offset
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part.Material = Enum.Material.Neon
            part.Color = color
            part.Transparency = 0.48
            part.Parent = projection
            table.insert(pieces, part)
            return part
        end
        projection.PrimaryPart = shape("MuseumPlanBase", Vector3.new(3.4, 0.08, 2.5),
            Vector3.new(), CYAN)
        for _, x in { -1.35, 1.35 } do
            for _, z in { -0.9, 0.9 } do
                shape("MuseumPlanColumn", Vector3.new(0.13, 1.5, 0.13),
                    Vector3.new(x, 0.76, z), CYAN)
            end
        end
        shape("MuseumPlanRoof", Vector3.new(3.6, 0.1, 2.7),
            Vector3.new(0, 1.55, 0), CYAN)
        shape("MuseumPlanPrize", Vector3.new(0.42, 0.42, 0.42),
            Vector3.new(0, 0.6, 0), GOLD).Shape = Enum.PartType.Ball

        local route = {
            tableTop.Position + Vector3.new(-5, 0.42, -2),
            tableTop.Position + Vector3.new(4.5, 0.42, -2),
            tableTop.Position + Vector3.new(4.5, 0.42, 2),
            tableTop.Position + Vector3.new(-5, 0.42, 2),
        }
        local pings: {BasePart} = {}
        for index in { 1, 2 } do
            local ping = shape("RoutePing" .. index, Vector3.new(0.27, 0.27, 0.27),
                Vector3.new(0, -1.5, 0), if index == 1 then GOLD else CYAN)
            ping.Shape = Enum.PartType.Ball
            table.insert(pings, ping)
        end

        local elapsed = 0
        local connection: RBXScriptConnection? = nil
        connection = RunService.Heartbeat:Connect(function(dt)
            if lobby.Parent == nil then
                if connection then connection:Disconnect() end
                projection:Destroy()
                return
            end
            elapsed += dt
            if elapsed < 0.07 then return end
            elapsed = 0
            local low = player:GetAttribute("LowEffects") == true
            local still = player:GetAttribute("ReduceMotion") == true
            for _, piece in pieces do
                piece.Transparency = if low then 1 else 0.5
            end
            if low or still then return end
            local t = os.clock()
            projection:PivotTo(CFrame.new(center + Vector3.new(0, math.sin(t * 0.7) * 0.14, 0))
                * CFrame.Angles(0, math.sin(t * 0.3) * 0.22, 0))
            for index, ping in pings do
                local phase = (t * 0.24 + (index - 1) * 0.5) % 1
                local segment = math.floor(phase * 4) + 1
                local a = route[segment]
                local b = route[if segment == 4 then 1 else segment + 1]
                ping.Position = a:Lerp(b, phase * 4 - (segment - 1))
            end
        end)
    end)
end

return table.freeze(LobbyPlanningVfx)
