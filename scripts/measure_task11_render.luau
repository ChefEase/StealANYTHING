-- QA only: Studio Client during Play, after stage_task11_runtime.luau.
-- Compare like-for-like views; simulator timings are PC measurements.
local camera=workspace.CurrentCamera
camera.CameraType=Enum.CameraType.Scriptable
local SAS=game:GetService("SceneAnalysisService")
local RS=game:GetService("RunService")
local result={}
for _,view in {
 {name="entrance",pos=Vector3.new(2000,9,304),look=Vector3.new(2000,9,350)},
 {name="gallery",pos=Vector3.new(2000,7,333),look=Vector3.new(2000,8,382)},
 {name="plaza",pos=Vector3.new(1972,11,-34),look=Vector3.new(2000,7,13)}
} do
 camera.CFrame=CFrame.lookAt(view.pos,view.look)
 task.wait(1)
 local times={}
 for i=1,90 do times[i]=RS.RenderStepped:Wait()*1000 end
 table.sort(times)
 local ok,tri=pcall(function() return SAS:GetTriangleCompositionAsync() end)
 local draws,triangles=0,0
 if ok then for _,p in tri.Children do if p.Name~="Shadows" then draws+=p.Sizes.Drawcalls; triangles+=p.Sizes.Triangles end end end
 result[#result+1]={view=view.name,p50ms=math.floor(times[45]*10)/10,p95ms=math.floor(times[86]*10)/10,drawCalls=draws,triangles=triangles,error=not ok and tostring(tri) or nil}
end
local scene=workspace:FindFirstChild("Task11VisualTestScene")
return game.HttpService:JSONEncode({views=result,viewport=tostring(camera.ViewportSize),sceneDescendants=scene and #scene:GetDescendants(),memoryMB=math.floor(game.Stats:GetTotalMemoryUsageMb())})
