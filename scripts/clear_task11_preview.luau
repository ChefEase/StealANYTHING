-- Run in Studio Edit when finished inspecting, before saving or publishing.
local preview = workspace:FindFirstChild("Task11InspectionPreview")
if preview then
    assert(preview:GetAttribute("GeneratedBy") == "scripts/preview_task11_plots.luau",
        "Refusing to remove unrelated Workspace content")
    preview:Destroy()
end
print("Task 11 inspection preview cleared; playable prototype is unchanged.")
