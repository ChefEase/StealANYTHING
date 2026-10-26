-- Run in Studio Edit mode after the visual kit is applied.
-- Matches Rojo's early-evening base values; no day/night cycle.
local Lighting = game:GetService("Lighting")

Lighting.ClockTime = 17.85
Lighting.Brightness = 2.2
Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(105, 109, 119)
Lighting.OutdoorAmbient = Color3.fromRGB(124, 135, 148)
Lighting.ColorShift_Top = Color3.new(0, 0, 0)
Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 0.55
Lighting.ShadowSoftness = 0.35
Lighting.ExposureCompensation = 0.18

local legacy = Lighting:FindFirstChild("Task11Atmosphere")
local atmosphere = Lighting:FindFirstChild("Atmosphere") or legacy
if legacy and atmosphere ~= legacy then legacy:Destroy() end
if not atmosphere then
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "Task11Atmosphere"
    atmosphere.Parent = Lighting
end
atmosphere.Density = 0.18
atmosphere.Offset = 0.15
atmosphere.Color = Color3.fromRGB(181, 195, 207)
atmosphere.Decay = Color3.fromRGB(93, 109, 132)
atmosphere.Glare = 0.04
atmosphere.Haze = 0.8

local color = Lighting:FindFirstChild("Task11ColorCorrection")
if not color then
    color = Instance.new("ColorCorrectionEffect")
    color.Name = "Task11ColorCorrection"
    color.Parent = Lighting
end
color.Brightness = 0.01
color.Contrast = 0.08
color.Saturation = -0.07
color.TintColor = Color3.fromRGB(248, 247, 242)

local bloom = Lighting:FindFirstChild("Bloom")
if bloom and bloom:IsA("BloomEffect") then
    bloom.Intensity, bloom.Size, bloom.Threshold = 0.10, 16, 1.85
end
local focus = Lighting:FindFirstChild("DepthOfField")
if focus and focus:IsA("DepthOfFieldEffect") then focus.Enabled = false end
local rays = Lighting:FindFirstChild("SunRays")
if rays and rays:IsA("SunRaysEffect") then rays.Intensity = 0.008 end

local clouds = workspace.Terrain:FindFirstChild("Task11Clouds")
if not clouds then
    clouds = Instance.new("Clouds")
    clouds.Name = "Task11Clouds"
    clouds.Parent = workspace.Terrain
end
assert(clouds:IsA("Clouds"), "Task11Clouds name belongs to another instance")
clouds.Cover = 0.62
clouds.Density = 0.26
clouds.Color = Color3.fromRGB(175, 185, 197)
clouds.Enabled = true

print("[Task11] premium early-evening lighting applied; edge mist remains local")
