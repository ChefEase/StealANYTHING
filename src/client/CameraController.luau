--!strict

local CameraController = {}

function CameraController.Start(player: Player)
    player.CameraMinZoomDistance = 4
    player.CameraMaxZoomDistance = 28

    local function attachCamera(character: Model)
        local humanoid = character:WaitForChild("Humanoid") :: Humanoid
        local camera = workspace.CurrentCamera
        if camera ~= nil then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
        end
    end

    player.CharacterAdded:Connect(attachCamera)
    if player.Character ~= nil then
        task.spawn(attachCamera, player.Character)
    end
end

return table.freeze(CameraController)
