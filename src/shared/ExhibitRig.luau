--!strict
local Rig = {}

local function motor(root: BasePart, model: Model, name: string, id: string, center: CFrame): BasePart
    local mover = Instance.new("Part")
    mover.Name = name .. "Root"
    mover.Size = Vector3.new(0.1, 0.1, 0.1)
    mover.CFrame = center
    mover.Transparency = 1
    mover.CanCollide, mover.CanTouch, mover.CanQuery = false, false, false
    mover.Massless = true
    mover.Parent = model
    local joint = Instance.new("Motor6D")
    joint.Name = "MotionJoint"
    joint.Part0, joint.Part1 = root, mover
    joint.C0 = root.CFrame:ToObjectSpace(center)
    joint:SetAttribute("ItemId", id)
    joint:SetAttribute("MotionChannel", name)
    joint.Parent = root
    return mover
end

function Rig.Configure(model: Model, id: string)
    local root = model.PrimaryPart
    if not root then return end
    if id == "snack_machine" then
        local oldJoint = root:FindFirstChild("MotionJoint") :: Motor6D?
        local bounds, size = model:GetBoundingBox()
        local chassis = motor(root, model, "chassis", id, bounds * CFrame.new(0, -size.Y / 2, 0))
        for _, weld in model:GetDescendants() do
            if weld:IsA("WeldConstraint") and weld.Part0 == root and weld.Part1
                and weld.Part1.Name ~= "SM_Plinth" and not weld.Part1.Name:match("^SM_Foot_") then
                weld.Part0 = chassis
            end
        end
        if oldJoint and oldJoint.Part1 then
            oldJoint.C0 = chassis.CFrame:ToObjectSpace(oldJoint.Part1.CFrame)
            oldJoint.Part0 = chassis
        end
    elseif id == "toaster" then
        local lever = model:FindFirstChild("LeverKnob", true) or model:FindFirstChild("Lever", true)
        if not lever or not lever:IsA("BasePart") then return end
        local mover = motor(root, model, "lever", id, lever.CFrame)
        for _, p in model:GetDescendants() do
            if p:IsA("BasePart") and (p.Name == "LeverKnob" or p.Name == "LeverArm" or p.Name == "Lever") then
                for _, weld in model:GetDescendants() do
                    if weld:IsA("WeldConstraint") and (weld.Part0 == p or weld.Part1 == p) then weld:Destroy() end
                end
                p.Anchored = false
                local weld = Instance.new("WeldConstraint")
                weld.Part0, weld.Part1 = mover, p
                weld.Parent = p
            end
        end
    end
end

return Rig
