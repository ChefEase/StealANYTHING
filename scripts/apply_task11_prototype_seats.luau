-- Studio Edit: attach sit-only controls to the benches in the playable
-- prototype. Existing bench geometry and collisions remain untouched.
local map = assert(workspace:FindFirstChild("Map"), "Playable Map missing")
local existing = map:FindFirstChild("Task11PrototypeSeats")
if existing then
    assert(existing:GetAttribute("GeneratedBy") == "scripts/apply_task11_prototype_seats.luau",
        "Refusing to replace unrelated content")
    existing:Destroy()
end
local root = Instance.new("Folder")
root.Name = "Task11PrototypeSeats"
root:SetAttribute("GeneratedBy", "scripts/apply_task11_prototype_seats.luau")
root.Parent = map

for _, source in {
    map.ExteriorDressing.Bench1Seat,
    map.ExteriorDressing.Bench2Seat,
    map.ExteriorDressing.Bench3Seat,
    map.ExteriorDressing.Bench4Seat,
    map.Depot.DepotArt.DepotBenchSeat,
} do
    local seat = Instance.new("Seat")
    seat.Name = source.Name .. "SitOnly"
    seat.Size = Vector3.new(math.min(source.Size.X - 0.25, 2.7), 0.12,
        math.max(0.7, source.Size.Z - 0.2))
    -- Seat:Sit places the avatar lower body below the invisible Seat's top.
    -- Raise it above the visible wooden surface so the avatar does not sink in.
    seat.CFrame = source.CFrame * CFrame.new(0, source.Size.Y / 2 + 0.31, 0)
    seat.Transparency = 1
    seat.Anchored = true
    seat.CanCollide, seat.CanTouch, seat.CanQuery = false, false, false
    seat:SetAttribute("Task11Visual", true)
    seat:SetAttribute("Task11SitOnly", true)
    seat.Parent = root
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "SitPrompt"
    prompt.ActionText, prompt.ObjectText = "Sit", "Bench"
    prompt.MaxActivationDistance, prompt.HoldDuration = 7, 0.15
    prompt.RequiresLineOfSight = false
    prompt.Style = Enum.ProximityPromptStyle.Default
    prompt:SetAttribute("Task11SitPrompt", true)
    prompt.Parent = seat
end
print("Task 11: five prototype benches now offer server-checked sitting")
