--!strict

local UserInputService = game:GetService("UserInputService")

type Rect = { x: number, y: number, w: number, h: number }

local PhoneHudLayout = {}

function PhoneHudLayout.IsPhone(screen: ScreenGui): boolean
    return UserInputService.TouchEnabled and screen.AbsoluteSize.X < 1100
end

function PhoneHudLayout.Calculate(size: Vector2)
    local width = math.max(280, size.X)
    local height = math.max(320, size.Y)
    local landscape = height < 500
    local narrow = width < 520
    local cash: Rect = { x = width - 168, y = 14, w = 154, h = 62 }
    local carryHeight = if height < 330 then 76 elseif height < 350 then 86 else 96
    local carry: Rect = {
        x = 14,
        y = if narrow then 94 else (if height < 350 then 70 else 78),
        w = math.min(250, width - 28),
        h = carryHeight,
    }
    local guideWidth = math.min(300, width - 28)
    local guide: Rect = {
        x = math.floor((width - guideWidth) / 2),
        y = if landscape then height - 170 else height - 275,
        w = guideWidth,
        h = 70,
    }
    local promptWidth = math.min(244, width - 28)
    local prompt: Rect = {
        x = math.floor((width - promptWidth) / 2),
        y = height - 90,
        w = promptWidth,
        h = 70,
    }
    local deliverWidth = math.min(204, width - 56)
    local deliver: Rect = {
        x = math.floor((width - deliverWidth) / 2),
        y = if landscape then height - 83 else height - 255,
        w = deliverWidth,
        h = 60,
    }
    local noticeWidth = if landscape
        then math.max(180, math.min(260, 2 * (cash.x - 12 - width / 2)))
        else math.min(280, width - 28)
    local notice: Rect = {
        x = math.floor((width - noticeWidth) / 2),
        y = if landscape then 8 else 206,
        w = noticeWidth,
        h = 58,
    }
    local objective: Rect = { x = 14, y = 94, w = width - 28, h = 28 }

    return {
        landscape = landscape,
        cash = cash,
        carry = carry,
        guide = guide,
        prompt = prompt,
        deliver = deliver,
        notice = notice,
        objective = objective,
    }
end

function PhoneHudLayout.Apply(gui: GuiObject, rect: Rect)
    gui.AnchorPoint = Vector2.zero
    gui.Position = UDim2.fromOffset(rect.x, rect.y)
    gui.Size = UDim2.fromOffset(rect.w, rect.h)
end

function PhoneHudLayout.Intersects(a: Rect, b: Rect): boolean
    return a.x < b.x + b.w and b.x < a.x + a.w
        and a.y < b.y + b.h and b.y < a.y + a.h
end

return table.freeze(PhoneHudLayout)
