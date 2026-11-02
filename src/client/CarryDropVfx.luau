--!strict

-- A local dust release for a server-confirmed voluntary drop only.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryDropVfx = {}

function CarryDropVfx.Start(player: Player)
    local seen: {[string]: number} = {}
    local feedback = ReplicatedStorage.Network:WaitForChild("Feedback") :: RemoteEvent
    feedback.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" or payload.cue ~= "CarryDropped"
            or type(payload.cueId) ~= "string" or seen[payload.cueId] then return end
        local now = os.clock()
        seen[payload.cueId] = now
        for id, at in seen do
            if now - at > 90 then seen[id] = nil end
        end
        if player:GetAttribute("ReduceMotion") == true then return end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then return end
        local mount = Instance.new("Attachment")
        mount.Name = "LocalCarryDropDust"
        mount.Position = Vector3.new(0, -2, 0)
        mount.Parent = root
        local dust = Instance.new("ParticleEmitter")
        dust.Name = "CarryReleasePuff"
        dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
        dust.Color = ColorSequence.new(Color3.fromRGB(138, 143, 137))
        dust.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.42),
            NumberSequenceKeypoint.new(1, 1),
        })
        dust.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.45),
            NumberSequenceKeypoint.new(1, 1.2),
        })
        dust.Lifetime = NumberRange.new(0.35, 0.6)
        dust.Speed = NumberRange.new(0.6, 1.8)
        dust.SpreadAngle = Vector2.new(80, 80)
        dust.EmissionDirection = Enum.NormalId.Bottom
        dust.Rate = 0
        dust.Parent = mount
        dust:Emit(if player:GetAttribute("LowEffects") == true then 2 else 7)
        Debris:AddItem(mount, 0.8)
    end)
end

return table.freeze(CarryDropVfx)
