-- ===== Auto Coin Farm v4 (плавный, без анкора) — Murder Mystery 2 =====
-- Ищет CoinContainer на любой карте, плавно подлетает к ближайшей монете
-- через TweenService и собирает её. Персонаж висит в воздухе (анти-гравитация
-- без анкора, чтобы касания монет срабатывали). Есть GUI вкл/выкл + скорость.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local prevEnabled = _G.AutoCoin and _G.AutoCoin.enabled
local prevSpeed = _G.AutoCoin and _G.AutoCoin.speed
if _G.AutoCoin then pcall(function() _G.AutoCoin:Destroy() end) end

local State = {
    enabled = prevEnabled or false,
    speed = prevSpeed or 22,   -- студов/сек (меньше = безопаснее против анти-чита)
    minTime = 0.6, maxTime = 6, pause = 0.4,
    running = false, holdPos = nil,
}
_G.AutoCoin = State

local fti = firetouchinterest

local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildWhichIsA("Humanoid")
end

local function getCoins()
    local container = Workspace:FindFirstChild("CoinContainer", true)
    local coins = {}
    if container then
        for _, c in ipairs(container:GetChildren()) do
            if c:IsA("BasePart") and c:FindFirstChild("TouchInterest") then
                table.insert(coins, c)
            end
        end
    end
    return coins
end

local function nearestCoin(pos)
    local best, bestDist
    for _, coin in ipairs(getCoins()) do
        local d = (coin.Position - pos).Magnitude
        if not bestDist or d < bestDist then best, bestDist = coin, d end
    end
    return best, bestDist
end

local function collect(coin)
    local hrp = getHRP()
    if not hrp or not coin or not coin.Parent then return end
    pcall(function()
        if fti then fti(hrp, coin, 0); fti(hrp, coin, 1); fti(hrp, coin, 0) end
    end)
end

-- Парение БЕЗ анкора: гасим скорость каждый кадр и удерживаем точку в паузах.
local holdConn = RunService.Heartbeat:Connect(function()
    if _G.AutoCoin ~= State then return end
    local hrp, hum = getHRP()
    if not hrp then return end
    if State.enabled then
        hrp.AssemblyLinearVelocity = Vector3.zero
        if hum then hum.PlatformStand = true end
        if (not State.running) and State.holdPos then
            hrp.CFrame = CFrame.new(State.holdPos)
        end
    end
end)
State.holdConn = holdConn

task.spawn(function()
    while _G.AutoCoin == State do
        if State.enabled and not State.running then
            local hrp, hum = getHRP()
            if hrp and hum and hum.Health > 0 then
                local coin = nearestCoin(hrp.Position)
                if coin then
                    State.running = true
                    State.holdPos = nil
                    local dist = (coin.Position - hrp.Position).Magnitude
                    local t = math.clamp(dist / State.speed, State.minTime, State.maxTime)
                    local tween = TweenService:Create(hrp,
                        TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {CFrame = CFrame.new(coin.Position)})
                    local touchConn = RunService.Heartbeat:Connect(function()
                        if coin and coin.Parent then collect(coin) end
                    end)
                    tween:Play(); tween.Completed:Wait()
                    collect(coin)
                    if touchConn then touchConn:Disconnect() end
                    State.holdPos = coin.Position
                    task.wait(State.pause)
                    State.running = false
                else
                    State.holdPos = nil
                    task.wait(0.4)
                end
            else
                task.wait(0.5)
            end
        else
            local hrp, hum = getHRP()
            if hrp and not State.enabled then
                if hum then hum.PlatformStand = false end
                State.holdPos = nil
            end
            task.wait(0.1)
        end
    end
end)

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "AutoCoin_GUI"; gui.ResetOnSpawn = false
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 150)
frame.Position = UDim2.new(0, 20, 0.32, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,30)
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true; frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,28); title.BackgroundTransparency = 1
title.Text = "Auto Coin Farm (плавный)"; title.Font = Enum.Font.GothamBold
title.TextSize = 14; title.TextColor3 = Color3.fromRGB(255,215,90); title.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1,-20,0,36); btn.Position = UDim2.new(0,10,0,32)
btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.BorderSizePixel = 0; btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1,-20,0,18); speedLabel.Position = UDim2.new(0,10,0,74)
speedLabel.BackgroundTransparency = 1; speedLabel.Font = Enum.Font.Gotham; speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.TextColor3 = Color3.fromRGB(200,200,200); speedLabel.Parent = frame

local function mkBtn(txt, x, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 24); b.Position = UDim2.new(0, x, 0, 94)
    b.BackgroundColor3 = Color3.fromRGB(55,55,65); b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 13; b.Text = txt; b.BorderSizePixel = 0; b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
    return b
end
local minus = mkBtn("- медленнее", 10, 95)
local plus  = mkBtn("+ быстрее", 115, 95)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-20,0,18); status.Position = UDim2.new(0,10,0,124)
status.BackgroundTransparency = 1; status.Font = Enum.Font.Gotham; status.TextSize = 12
status.TextColor3 = Color3.fromRGB(150,150,150); status.Text = "Монет: 0"; status.Parent = frame

local function updateBtn()
    if State.enabled then btn.Text="FARM: ON"; btn.BackgroundColor3=Color3.fromRGB(40,160,80)
    else btn.Text="FARM: OFF"; btn.BackgroundColor3=Color3.fromRGB(170,50,50) end
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    speedLabel.Text = "Скорость: " .. State.speed .. " studs/s"
end
updateBtn()
btn.MouseButton1Click:Connect(function() State.enabled = not State.enabled; if not State.enabled then State.holdPos=nil end; updateBtn() end)
minus.MouseButton1Click:Connect(function() State.speed = math.max(8, State.speed - 6); updateBtn() end)
plus.MouseButton1Click:Connect(function() State.speed = math.min(120, State.speed + 6); updateBtn() end)

task.spawn(function()
    while _G.AutoCoin == State and gui.Parent do
        status.Text = "Монет: " .. #getCoins()
        updateBtn()
        task.wait(0.4)
    end
end)

State.Destroy = function()
    State.enabled = false; _G.AutoCoin = nil
    if State.holdConn then pcall(function() State.holdConn:Disconnect() end) end
    local hrp, hum = getHRP()
    if hrp then pcall(function() hrp.Anchored = false end) end
    if hum then pcall(function() hum.PlatformStand = false end) end
    if gui then gui:Destroy() end
end

print("[AutoCoin v4] Без анкора. speed=" .. State.speed .. " | enabled=" .. tostring(State.enabled))
