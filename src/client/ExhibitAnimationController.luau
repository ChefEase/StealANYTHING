--!strict

local RunService = game:GetService("RunService")

local Motion = require(game:GetService("ReplicatedStorage").Shared.ExhibitMotion)
local Audio = require(script.Parent.ExhibitAudio)
local ExhibitAnimationController = {}

local function animatedDisplay(instance: Instance): boolean
    local parent = instance.Parent
    while parent ~= nil and parent ~= workspace do
        if parent.Name == "RegisteredDisplays" or parent.Name == "PublicStockRuntime" then
            return true
        end
        parent = parent.Parent
    end
    return false
end

function ExhibitAnimationController.Start(player: Player)
    local joints: {Motor6D} = {}
    local seen: {[Motor6D]: boolean} = {}
    local function add(instance: Instance)
        if not instance:IsA("Motor6D") or instance.Name ~= "MotionJoint"
            or seen[instance] or not animatedDisplay(instance) then return end
        seen[instance] = true
        table.insert(joints, instance)
        Audio.Add(instance)
    end
    workspace.DescendantAdded:Connect(add)
    for _, instance in workspace:GetDescendants() do add(instance) end
    RunService.PreSimulation:Connect(function()
        local reduced = player:GetAttribute("ReduceMotion") == true
        local time = os.clock()
        Audio.Update(time)
        for index = #joints, 1, -1 do
            local joint = joints[index]
            if joint.Parent == nil or not animatedDisplay(joint) then
                seen[joint] = nil
                table.remove(joints, index)
            else
                local itemId = joint:GetAttribute("ItemId")
                joint.Transform = if reduced or type(itemId) ~= "string"
                    then CFrame.identity else Motion.Sample(itemId, joint:GetAttribute("MotionChannel") or "main", time)
            end
        end
    end)
end

return table.freeze(ExhibitAnimationController)
