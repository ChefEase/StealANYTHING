--!strict
-- Run in Studio Edit after Rojo sync. All coordinates use the ScreenGui safe area.

local Client = game:GetService("StarterPlayer").StarterPlayerScripts.Client
local Layout = require(Client.PhoneHudLayout)
local TextService = game:GetService("TextService")

local function textWidth(value: string, size: number): number
    return TextService:GetTextSize(value, size, Enum.Font.GothamBold,
        Vector2.new(1000, 30)).X
end

local sizes = {
    Vector2.new(733, 333), -- iPhone 16 simulator safe area
    Vector2.new(844, 390),
    Vector2.new(667, 375),
    Vector2.new(568, 320),
    Vector2.new(430, 932),
    Vector2.new(390, 844),
    Vector2.new(360, 640),
    Vector2.new(320, 568),
    Vector2.new(390, 520),
}

local function distinct(rects: {any}, name: string)
    for i = 1, #rects do
        for j = i + 1, #rects do
            assert(not Layout.Intersects(rects[i], rects[j]), name .. " panels overlap")
        end
    end
end

for _, size in sizes do
    local layout = Layout.Calculate(size)
    for _, rect in { layout.cash, layout.carry, layout.guide, layout.prompt,
        layout.deliver, layout.notice, layout.objective } do
        assert(rect.x >= 0 and rect.y >= 0 and rect.w > 0 and rect.h > 0)
        assert(rect.x + rect.w <= size.X and rect.y + rect.h <= size.Y)
    end
    assert(layout.prompt.w >= 244 and layout.prompt.h >= 70)
    assert(layout.deliver.w >= 204 and layout.deliver.h >= 60)
    assert(textWidth("Follow arrow to the exhibit stand.", 14) <= layout.guide.w - 64)
    assert(textWidth("HOLD TO DELIVER", 17) <= layout.deliver.w - 16)
    assert(textWidth("NO ACTIVE INCOME", 11) <= layout.cash.w - 50)

    distinct({ layout.cash, layout.guide }, "new tutorial")
    distinct({ layout.cash, layout.prompt, layout.notice }, "pickup prompt")
    distinct({ layout.cash, layout.carry, layout.guide, layout.notice }, "carrying")
    distinct({ layout.cash, layout.carry, layout.notice }, "carry feedback")
    distinct({ layout.cash, layout.carry, layout.deliver, layout.notice }, "delivery")
    distinct({ layout.cash, layout.carry, layout.objective, layout.notice }, "completed tutorial")
end

print("Phone HUD layouts and interaction states: PASS")
return "Phone HUD layouts and interaction states: PASS"
