-- =========================================================================
--   🌶️ CHILLI HUB V5 X RONNEI - STEAL AN EGG 🥚 (PHẦN 1/5)
--   CẤU HÌNH HỆ THỐNG · PRELOAD ASSET ĐÚNG ID · 00:00 GMT+7
-- =========================================================================

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local KeyUrl = "https://link4m.net/m2JAFv"
local TutorialUrl = "https://craftvip.github.io/free/getkey.html"
local TargetScriptUrl = "https://raw.githubusercontent.com/robvxs24/freemium/refs/heads/main/chilliv5beta.lua"

local ChilliAvatarId = "rbxassetid://92622270383869"  -- Hình quả ớt cho Avatar chính giữa & Header[span_3](start_span)[span_3](end_span)
local GiftBoxAssetId = "rbxassetid://115116611981430" -- Hình hộp quà cho 2 hộp gacha bên trong[span_4](start_span)[span_4](end_span)

local KeyFileName = "ChilliV5_KeyData.json"
local TrialFileName = "ChilliV5_TrialData.json"
local GachaFileName = "ChilliV5_GachaData.json"
local TRIAL_DURATION = 120 -- Thời gian dùng thử 2 phút (120 giây)

local InitialGuis = {}
local ScriptConnections = {}
local ActiveBlurEffect = nil
local InputBlockerScreen = nil
local OpenKeySystemUI = nil

-- TẢI TRƯỚC HÌNH ẢNH VÀO RAM
task.spawn(function()
    pcall(function()
        ContentProvider:PreloadAsync({ GiftBoxAssetId, ChilliAvatarId })
    end)
end)

-- MODULE MÃ HÓA BẢO MẬT DỮ LIỆU CỤC BỘ
local CIPHER_KEY = 127

local function EncryptData(str: string): string
    local hex = {}
    for i = 1, #str do
        table.insert(hex, string.format("%02X", bit32.bxor(string.byte(str, i), CIPHER_KEY)))
    end
    return table.concat(hex)
end

local function DecryptData(hexStr: string): string?
    local res = {}
    for i = 1, #hexStr, 2 do
        local b = tonumber(hexStr:sub(i, i + 1), 16)
        if not b then return nil end
        table.insert(res, string.char(bit32.bxor(b, CIPHER_KEY)))
    end
    return table.concat(res)
end

local function GetCurrentDateGMT7(): string
    local vnTime = os.time() + (7 * 3600)
    local d = os.date("!*t", vnTime)
    return string.format("%04d-%02d-%02d", d.year, d.month, d.day)
end

local function GetSecondsUntilMidnightGMT7(): number
    local vnTime = os.time() + (7 * 3600)
    local d = os.date("!*t", vnTime)
    local elapsed = (d.hour * 3600) + (d.min * 60) + d.sec
    return 86400 - elapsed
end

local function CanPlayGachaToday(): boolean
    if isfile and readfile and isfile(GachaFileName) then
        local ok, raw = pcall(readfile, GachaFileName)
        if ok and raw and raw ~= "" then
            local dec = DecryptData(raw)
            if dec then
                local parseOk, data = pcall(function() return HttpService:JSONDecode(dec) end)
                if parseOk and type(data) == "table" and data.LastGachaDate then
                    if data.LastGachaDate == GetCurrentDateGMT7() then
                        return false
                    end
                end
            end
        end
    end
    return true
end

local function SaveGachaPlayed()
    if writefile then
        pcall(function()
            local data = { LastGachaDate = GetCurrentDateGMT7(), Timestamp = os.time() }
            writefile(GachaFileName, EncryptData(HttpService:JSONEncode(data)))
        end)
    end
end

local function LoadTrialData()
    if isfile and readfile and isfile(TrialFileName) then
        local ok, raw = pcall(readfile, TrialFileName)
        if ok and raw and raw ~= "" then
            local dec = DecryptData(raw)
            if dec then
                local parseOk, data = pcall(function() return HttpService:JSONDecode(dec) end)
                if parseOk and type(data) == "table" and data.StartTime and data.LastSeen then
                    if os.time() < data.LastSeen then
                        return { StartTime = 0, LastSeen = os.time(), Tampered = true }
                    end
                    return data
                end
            end
        end
    end
    return nil
end

local function SaveTrialData(startTime: number, lastSeen: number?)
    if writefile then
        pcall(function()
            local data = { StartTime = startTime, LastSeen = lastSeen or os.time(), Duration = TRIAL_DURATION }
            writefile(TrialFileName, EncryptData(HttpService:JSONEncode(data)))
        end)
    end
end

local function GetKeyRemainingTime(): number?
    if isfile and readfile and isfile(KeyFileName) then
        local ok, content = pcall(readfile, KeyFileName)
        if ok and content and content ~= "" then
            local decOk, data = pcall(function() return HttpService:JSONDecode(content) end)
            if decOk and type(data) == "table" and data.ExpireTimestamp then
                local left = data.ExpireTimestamp - os.time()
                if left > 0 then return left end
            end
        end
    end
    return nil
end

local function Save24hKey(customDuration: number?)
    if writefile then
        pcall(function()
            local duration = customDuration or 86400
            writefile(KeyFileName, HttpService:JSONEncode({ ExpireTimestamp = os.time() + duration }))
        end)
    end
end

local function VerifyChilliV5Key(rawInput: string): boolean
    if not rawInput or rawInput == "" then return false end
    local clean = string.lower(string.gsub(rawInput, "[%s%c]", ""))
    clean = clean:gsub("^chillihubv5%-", ""):gsub("^chilliv5beta%-", ""):gsub("^chilliv5%-", "")

    local vnTime = os.time() + (7 * 3600)
    for _, t in ipairs({ vnTime, vnTime - 86400, vnTime + 3600 }) do
        local d = os.date("!*t", t)
        local v1 = (d.day * 4339 + d.month * 3187 + d.year * 173) % 65535
        local v2 = (d.day * 6823 + d.month * 4931 + d.year * 293) % 65535
        local v3 = (d.day * 8513 + d.month * 7109 + d.year * 431) % 65535
        if clean == string.format("%04x-%04x-%04x", v1, v2, v3) then
            return true
        end
    end
    return false
end
-- =========================================================================
--   🌶️ CHILLI HUB V5 X RONNEI - STEAL AN EGG 🥚 (PHẦN 2/5)
--   SNAPSHOT UI · KHÓA MÀN HÌNH BẢO MẬT · LIVE TOAST THỜI GIAN THỰC
-- =========================================================================

local function TakeGuiSnapshot()
    table.clear(InitialGuis)
    local containers = { CoreGui, LocalPlayer:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                InitialGuis[child] = true
            end
        end
    end
end

local function ApplyScreenLockdown()
    if not ActiveBlurEffect then
        ActiveBlurEffect = Instance.new("BlurEffect")
        ActiveBlurEffect.Name = "ChilliV5_LockdownBlur"
        ActiveBlurEffect.Size = 28
        ActiveBlurEffect.Parent = Lighting
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.PlatformStand = true
        end
        if hrp then
            hrp.Anchored = true
        end
    end

    if not InputBlockerScreen then
        InputBlockerScreen = Instance.new("ScreenGui")
        InputBlockerScreen.Name = "ChilliV5_InputBlocker"
        InputBlockerScreen.ResetOnSpawn = false
        pcall(function() InputBlockerScreen.Parent = CoreGui end)
        if not InputBlockerScreen.Parent then InputBlockerScreen.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        local shield = Instance.new("TextButton")
        shield.Size = UDim2.new(1, 0, 1, 0)
        shield.Position = UDim2.new(0, 0, 0, 0)
        shield.BackgroundColor3 = Color3.fromRGB(12, 5, 8)
        shield.BackgroundTransparency = 0.45
        shield.Text = ""
        shield.AutoButtonColor = false
        shield.Active = true
        shield.ZIndex = 15
        shield.Parent = InputBlockerScreen
    end
end

local function RemoveScreenLockdown()
    if ActiveBlurEffect then
        ActiveBlurEffect:Destroy()
        ActiveBlurEffect = nil
    end
    if InputBlockerScreen then
        InputBlockerScreen:Destroy()
        InputBlockerScreen = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end
        if hrp then
            hrp.Anchored = false
        end
    end
end

local function TerminateTargetScript()
    getgenv().ChilliV5_Active = false
    getgenv().ChilliV5_TrialExpired = true

    for _, conn in ipairs(ScriptConnections) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(ScriptConnections)

    local containers = { CoreGui, LocalPlayer:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                if not InitialGuis[child] and child.Name ~= "ChilliV5_GetKeyUI" and child.Name ~= "ChilliV5_ToastUI" and child.Name ~= "ChilliV5_InputBlocker" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function LaunchTargetScriptWithWatcher()
    TakeGuiSnapshot()
    getgenv().ChilliV5_Active = true

    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGet(TargetScriptUrl))()
        end)
    end)
end

local function FormatTime(seconds: number): string
    if seconds < 0 then seconds = 0 end
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d phút %02d giây", m, s)
end

local ActiveToastLabel = nil

local function ShowLiveToast(titleText: string, initialSeconds: number, color: Color3)
    if CoreGui:FindFirstChild("ChilliV5_ToastUI") then CoreGui.ChilliV5_ToastUI:Destroy() end
    if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ChilliV5_ToastUI") then
        LocalPlayer.PlayerGui.ChilliV5_ToastUI:Destroy()
    end

    local ToastGui = Instance.new("ScreenGui")
    ToastGui.Name = "ChilliV5_ToastUI"
    ToastGui.ResetOnSpawn = false
    pcall(function() ToastGui.Parent = CoreGui end)
    if not ToastGui.Parent then ToastGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local ToastFrame = Instance.new("Frame")
    ToastFrame.Size = UDim2.new(0, 385, 0, 72)
    ToastFrame.Position = UDim2.new(0.5, -192, 0, -100)
    ToastFrame.BackgroundColor3 = Color3.fromRGB(18, 6, 11)
    ToastFrame.BorderSizePixel = 0
    ToastFrame.ZIndex = 50
    ToastFrame.Parent = ToastGui

    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 16)
    local Stroke = Instance.new("UIStroke", ToastFrame)
    Stroke.Thickness = 1.4
    Stroke.Color = color or Color3.fromRGB(225, 29, 72)

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 42, 1, 0)
    Icon.Position = UDim2.new(0, 10, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🌶️"
    Icon.TextSize = 22
    Icon.ZIndex = 51
    Icon.Parent = ToastFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -65, 0, 20)
    Title.Position = UDim2.new(0, 52, 0, 12)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = color or Color3.fromRGB(250, 205, 218)
    Title.TextSize = 11.5
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 51
    Title.Parent = ToastFrame

    local Msg = Instance.new("TextLabel")
    Msg.Size = UDim2.new(1, -65, 0, 20)
    Msg.Position = UDim2.new(0, 52, 0, 32)
    Msg.BackgroundTransparency = 1
    Msg.Text = "Thời gian dùng thử: " .. FormatTime(initialSeconds)
    Msg.TextColor3 = Color3.fromRGB(240, 230, 235)
    Msg.TextSize = 11
    Msg.Font = Enum.Font.GothamMedium
    Msg.TextXAlignment = Enum.TextXAlignment.Left
    Msg.ZIndex = 51
    Msg.Parent = ToastFrame

    ActiveToastLabel = Msg

    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, -24, 0, 3)
    BarBg.Position = UDim2.new(0, 12, 1, -6)
    BarBg.BackgroundColor3 = Color3.fromRGB(35, 10, 16)
    BarBg.BorderSizePixel = 0
    BarBg.ZIndex = 51
    BarBg.Parent = ToastFrame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 1, 0)
    Bar.BackgroundColor3 = color or Color3.fromRGB(225, 29, 72)
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 52
    Bar.Parent = BarBg

    TweenService:Create(ToastFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -192, 0, 24) }):Play()
    TweenService:Create(Bar, TweenInfo.new(10, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()

    task.delay(10, function()
        if ToastFrame and ToastFrame.Parent then
            local t = TweenService:Create(ToastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -192, 0, -100), BackgroundTransparency = 1 })
            t:Play()
            t.Completed:Connect(function()
                if ToastGui and ToastGui.Parent then ToastGui:Destroy() end
                ActiveToastLabel = nil
            end)
        end
    end)
end
-- =========================================================================
--   🌶️ CHILLI HUB V5 X RONNEI - STEAL AN EGG 🥚 (PHẦN 3/5)
--   GIAO DIỆN CHÍNH DARK MATTE · AVATAR QUẢ ỚT ĐÚNG VỊ TRÍ · PHÓNG XA 480x500
-- =========================================================================

local Languages = {
    VI = {
        LangBtnText = "🇻🇳 VI",
        SelectLangTitle = "Chọn ngôn ngữ hiển thị",
        Title = "Key Steam Chilli Hub V5 - steal an egg 🥚",
        Subtitle = "chilli hub v5 được tạo bởi ronnei7.htk",
        CenterTitle = "CHILLI HUB V5 × RONNEI",
        CenterSub = "Steal An Egg 🥚 Edition",
        Placeholder = "Dán mã key bản quyền tại đây...",
        QuickPaste = "📋 Dán",
        GetKey = "⚡ LẤY KEY (24 TIẾNG)",
        CheckKey = "🌶️ KÍCH HOẠT V5",
        Tutorial = "📖 Hướng dẫn vượt link lấy key",
        MiniGame = "🎁 Mở Hộp Quà May Mắn (50/50)",
        MiniGameLocked = "🔒 Đã mở hôm nay (Reset 00:00)",
        Notice = "📌 Link getkey 24 tiếng thao tác nhanh gọn (chỉ 1 phút). Mỗi key có hạn sử dụng đúng 24 giờ kể từ khi kích hoạt.",
        CopiedLink = "📋 Đã sao chép link getkey 24 tiếng vào clipboard!",
        CopiedTutorial = "📖 Đã sao chép link hướng dẫn vào clipboard!",
        Checking = "ĐANG XÁC THỰC...",
        CheckingMsg = "⏳ Đang đối soát chứng chỉ trên máy chủ Chilli...",
        Success = "✔ Xác thực thành công! Đang khởi động Chilli Hub V5...",
        Error = "✖ Key không hợp lệ hoặc đã hết hạn 24 giờ!"
    },
    EN = {
        LangBtnText = "🇺🇸 EN",
        SelectLangTitle = "Select Display Language",
        Title = "Key Steam Chilli Hub V5 - steal an egg 🥚",
        Subtitle = "chilli hub v5 created by ronnei7.htk",
        CenterTitle = "CHILLI HUB V5 × RONNEI",
        CenterSub = "Steal An Egg 🥚 Edition",
        Placeholder = "Paste your license key here...",
        QuickPaste = "📋 Paste",
        GetKey = "⚡ GET KEY (24 HOURS)",
        CheckKey = "🌶️ ACTIVATE V5",
        Tutorial = "📖 How to bypass link tutorial",
        MiniGame = "🎁 Mystery Box Gacha (50/50)",
        MiniGameLocked = "🔒 Opened Today (Resets 00:00)",
        Notice = "📌 24-hour key link is fast and easy (takes only 1 min). Each key remains valid for exactly 24 hours.",
        CopiedLink = "📋 24-hour key link copied to clipboard!",
        CopiedTutorial = "📖 Tutorial link copied to clipboard!",
        Checking = "AUTHENTICATING...",
        CheckingMsg = "⏳ Verifying credentials with Chilli server...",
        Success = "✔ License verified! Launching Chilli Hub V5...",
        Error = "✖ Invalid key or expired 24-hour license!"
    }
}
local CurrentLang = "VI"

local function PlaySpringButton(btn: TextButton)
    local origSize = btn.Size
    local origPos = btn.Position
    local shrinkSize = UDim2.new(origSize.X.Scale, origSize.X.Offset - 4, origSize.Y.Scale, origSize.Y.Offset - 3)
    local shrinkPos = UDim2.new(origPos.X.Scale, origPos.X.Offset + 2, origPos.Y.Scale, origPos.Y.Offset + 1.5)

    local t1 = TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = shrinkSize, Position = shrinkPos })
    local t2 = TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = origSize, Position = origPos })
    t1:Play()
    t1.Completed:Connect(function() t2:Play() end)
end

OpenKeySystemUI = function()
    if CoreGui:FindFirstChild("ChilliV5_GetKeyUI") then CoreGui.ChilliV5_GetKeyUI:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ChilliV5_GetKeyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 480, 0, 500)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 6, 10)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 30
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 24)

    local MainScale = Instance.new("UIScale", MainFrame)
    MainScale.Scale = 0.55

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Thickness = 1.4
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = Color3.fromRGB(225, 29, 72)

    -- HEADER TOP BAR (Dùng ảnh quả ớt ChilliAvatarId)[span_5](start_span)[span_5](end_span)
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, -32, 0, 44)
    HeaderBar.Position = UDim2.new(0, 16, 0, 14)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.ZIndex = 31
    HeaderBar.Parent = MainFrame

    local MiniLogo = Instance.new("Frame")
    MiniLogo.Size = UDim2.new(0, 30, 0, 30)
    MiniLogo.Position = UDim2.new(0, 0, 0.5, -15)
    MiniLogo.BackgroundColor3 = Color3.fromRGB(26, 8, 14)
    MiniLogo.ClipsDescendants = true
    MiniLogo.ZIndex = 32
    MiniLogo.Parent = HeaderBar
    Instance.new("UICorner", MiniLogo).CornerRadius = UDim.new(1, 0)
    local MiniLogoStroke = Instance.new("UIStroke", MiniLogo)
    MiniLogoStroke.Color = Color3.fromRGB(225, 29, 72)
    MiniLogoStroke.Thickness = 1.2

    local MiniLogoImg = Instance.new("ImageLabel")
    MiniLogoImg.Size = UDim2.new(1, 0, 1, 0)
    MiniLogoImg.BackgroundTransparency = 1
    MiniLogoImg.Image = ChilliAvatarId[span_6](start_span)[span_6](end_span)
    MiniLogoImg.ScaleType = Enum.ScaleType.Crop
    MiniLogoImg.ZIndex = 33
    MiniLogoImg.Parent = MiniLogo

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -110, 0, 18)
    TitleLabel.Position = UDim2.new(0, 38, 0, 2)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Languages[CurrentLang].Title
    TitleLabel.TextColor3 = Color3.fromRGB(250, 235, 238)
    TitleLabel.TextSize = 11.5
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 32
    TitleLabel.Parent = HeaderBar

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Size = UDim2.new(1, -110, 0, 16)
    SubTitleLabel.Position = UDim2.new(0, 38, 0, 21)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = Languages[CurrentLang].Subtitle
    SubTitleLabel.TextColor3 = Color3.fromRGB(225, 140, 160)
    SubTitleLabel.TextSize = 10
    SubTitleLabel.Font = Enum.Font.GothamMedium
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.ZIndex = 32
    SubTitleLabel.Parent = HeaderBar

    local OpenLangBtn = Instance.new("TextButton")
    OpenLangBtn.Size = UDim2.new(0, 68, 0, 28)
    OpenLangBtn.Position = UDim2.new(1, -68, 0.5, -14)
    OpenLangBtn.BackgroundColor3 = Color3.fromRGB(26, 8, 14)
    OpenLangBtn.Text = Languages[CurrentLang].LangBtnText
    OpenLangBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    OpenLangBtn.TextSize = 11
    OpenLangBtn.Font = Enum.Font.GothamBold
    OpenLangBtn.AutoButtonColor = false
    OpenLangBtn.ZIndex = 32
    OpenLangBtn.Parent = HeaderBar
    Instance.new("UICorner", OpenLangBtn).CornerRadius = UDim.new(0, 8)
    local LangStroke = Instance.new("UIStroke", OpenLangBtn)
    LangStroke.Color = Color3.fromRGB(160, 45, 65)
    LangStroke.Thickness = 1

    -- LOGO AVATAR CHÍNH GIỮA (DÙNG ẢNH QUẢ ỚT ChilliAvatarId)[span_7](start_span)[span_7](end_span)
    local CenterLogoBox = Instance.new("Frame")
    CenterLogoBox.Size = UDim2.new(0, 56, 0, 56)
    CenterLogoBox.Position = UDim2.new(0.5, -28, 0, 56)
    CenterLogoBox.BackgroundColor3 = Color3.fromRGB(24, 7, 13)
    CenterLogoBox.ClipsDescendants = true
    CenterLogoBox.ZIndex = 31
    CenterLogoBox.Parent = MainFrame
    Instance.new("UICorner", CenterLogoBox).CornerRadius = UDim.new(0, 16)
    local CenterLogoStroke = Instance.new("UIStroke", CenterLogoBox)
    CenterLogoStroke.Color = Color3.fromRGB(225, 29, 72)
    CenterLogoStroke.Thickness = 1.2

    local CenterLogoImg = Instance.new("ImageLabel")
    CenterLogoImg.Size = UDim2.new(1, 0, 1, 0)
    CenterLogoImg.BackgroundTransparency = 1
    CenterLogoImg.Image = ChilliAvatarId[span_8](start_span)[span_8](end_span)
    CenterLogoImg.ScaleType = Enum.ScaleType.Crop
    CenterLogoImg.ZIndex = 32
    CenterLogoImg.Parent = CenterLogoBox

    local CenterTitle = Instance.new("TextLabel")
    CenterTitle.Size = UDim2.new(1, -30, 0, 20)
    CenterTitle.Position = UDim2.new(0, 15, 0, 118)
    CenterTitle.BackgroundTransparency = 1
    CenterTitle.Text = Languages[CurrentLang].CenterTitle
    CenterTitle.TextColor3 = Color3.fromRGB(252, 240, 244)
    CenterTitle.TextSize = 14
    CenterTitle.Font = Enum.Font.GothamBold
    CenterTitle.ZIndex = 31
    CenterTitle.Parent = MainFrame

    local CenterSub = Instance.new("TextLabel")
    CenterSub.Size = UDim2.new(1, -30, 0, 16)
    CenterSub.Position = UDim2.new(0, 15, 0, 139)
    CenterSub.BackgroundTransparency = 1
    CenterSub.Text = Languages[CurrentLang].CenterSub
    CenterSub.TextColor3 = Color3.fromRGB(225, 140, 160)
    CenterSub.TextSize = 10
    CenterSub.Font = Enum.Font.GothamMedium
    CenterSub.ZIndex = 31
    CenterSub.Parent = MainFrame

    -- KHUNG NHẬP LIỆU & NÚT DÁN NHANH
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -40, 0, 40)
    InputContainer.Position = UDim2.new(0, 20, 0, 164)
    InputContainer.BackgroundColor3 = Color3.fromRGB(20, 6, 11)
    InputContainer.ZIndex = 31
    InputContainer.Parent = MainFrame
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 12)
    local InputStroke = Instance.new("UIStroke", InputContainer)
    InputStroke.Color = Color3.fromRGB(60, 18, 28)

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -80, 1, 0)
    InputBox.Position = UDim2.new(0, 12, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.TextColor3 = Color3.fromRGB(250, 235, 240)
    InputBox.PlaceholderColor3 = Color3.fromRGB(130, 70, 85)
    InputBox.PlaceholderText = Languages[CurrentLang].Placeholder
    InputBox.Text = ""
    InputBox.TextSize = 11.5
    InputBox.Font = Enum.Font.GothamMedium
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.ZIndex = 32
    InputBox.Parent = InputContainer

    local QuickPasteBtn = Instance.new("TextButton")
    QuickPasteBtn.Size = UDim2.new(0, 60, 0, 28)
    QuickPasteBtn.Position = UDim2.new(1, -66, 0.5, -14)
    QuickPasteBtn.BackgroundColor3 = Color3.fromRGB(32, 9, 16)
    QuickPasteBtn.Text = Languages[CurrentLang].QuickPaste
    QuickPasteBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    QuickPasteBtn.TextSize = 10.5
    QuickPasteBtn.Font = Enum.Font.GothamBold
    QuickPasteBtn.AutoButtonColor = false
    QuickPasteBtn.ZIndex = 33
    QuickPasteBtn.Parent = InputContainer
    Instance.new("UICorner", QuickPasteBtn).CornerRadius = UDim.new(0, 8)
    local QuickPasteStroke = Instance.new("UIStroke", QuickPasteBtn)
    QuickPasteStroke.Color = Color3.fromRGB(150, 40, 60)
    -- =========================================================================
--   🌶️ CHILLI HUB V5 X RONNEI - STEAL AN EGG 🥚 (PHẦN 4/5)
--   CỤM NÚT VIP · MODAL HỘP QUÀ GACHA (DÙNG ẢNH HỘP QUÀ BÊN TRONG)[span_9](start_span)[span_9](end_span)
-- =========================================================================

    local ButtonsRow = Instance.new("Frame")
    ButtonsRow.Size = UDim2.new(1, -40, 0, 42)
    ButtonsRow.Position = UDim2.new(0, 20, 0, 214)
    ButtonsRow.BackgroundTransparency = 1
    ButtonsRow.ZIndex = 31
    ButtonsRow.Parent = MainFrame

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0.5, -6, 1, 0)
    GetKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
    GetKeyBtn.Text = Languages[CurrentLang].GetKey
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.TextSize = 11.5
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.ZIndex = 32
    GetKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 11)
    local GetKeyStroke = Instance.new("UIStroke", GetKeyBtn)
    GetKeyStroke.Color = Color3.fromRGB(244, 63, 94)

    local CheckKeyBtn = Instance.new("TextButton")
    CheckKeyBtn.Size = UDim2.new(0.5, -6, 1, 0)
    CheckKeyBtn.Position = UDim2.new(0.5, 6, 0, 0)
    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(24, 7, 13)
    CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
    CheckKeyBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    CheckKeyBtn.TextSize = 11.5
    CheckKeyBtn.Font = Enum.Font.GothamBold
    CheckKeyBtn.AutoButtonColor = false
    CheckKeyBtn.ZIndex = 32
    CheckKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 11)
    local CheckStroke = Instance.new("UIStroke", CheckKeyBtn)
    CheckStroke.Color = Color3.fromRGB(160, 45, 65)
    CheckStroke.Thickness = 1.2

    local TutorialBtn = Instance.new("TextButton")
    TutorialBtn.Size = UDim2.new(1, -40, 0, 36)
    TutorialBtn.Position = UDim2.new(0, 20, 0, 266)
    TutorialBtn.BackgroundColor3 = Color3.fromRGB(22, 6, 12)
    TutorialBtn.Text = Languages[CurrentLang].Tutorial
    TutorialBtn.TextColor3 = Color3.fromRGB(250, 175, 195)
    TutorialBtn.TextSize = 11
    TutorialBtn.Font = Enum.Font.GothamBold
    TutorialBtn.AutoButtonColor = false
    TutorialBtn.ZIndex = 32
    TutorialBtn.Parent = MainFrame
    Instance.new("UICorner", TutorialBtn).CornerRadius = UDim.new(0, 11)
    local TutorialStroke = Instance.new("UIStroke", TutorialBtn)
    TutorialStroke.Color = Color3.fromRGB(130, 35, 55)
    TutorialStroke.Thickness = 1.2

    local NoticeCard = Instance.new("Frame")
    NoticeCard.Size = UDim2.new(1, -40, 0, 62)
    NoticeCard.Position = UDim2.new(0, 20, 0, 312)
    NoticeCard.BackgroundColor3 = Color3.fromRGB(18, 5, 10)
    NoticeCard.ZIndex = 31
    NoticeCard.Parent = MainFrame
    Instance.new("UICorner", NoticeCard).CornerRadius = UDim.new(0, 12)
    local NoticeStroke = Instance.new("UIStroke", NoticeCard)
    NoticeStroke.Color = Color3.fromRGB(45, 12, 20)

    local NoticeText = Instance.new("TextLabel")
    NoticeText.Size = UDim2.new(1, -18, 1, -8)
    NoticeText.Position = UDim2.new(0, 9, 0, 4)
    NoticeText.BackgroundTransparency = 1
    NoticeText.Text = Languages[CurrentLang].Notice
    NoticeText.TextColor3 = Color3.fromRGB(240, 210, 218)
    NoticeText.TextSize = 10.5
    NoticeText.Font = Enum.Font.GothamMedium
    NoticeText.TextWrapped = true
    NoticeText.TextYAlignment = Enum.TextYAlignment.Center
    NoticeText.TextXAlignment = Enum.TextXAlignment.Left
    NoticeText.ZIndex = 32
    NoticeText.Parent = NoticeCard

    local MiniGameBtn = Instance.new("TextButton")
    MiniGameBtn.Size = UDim2.new(1, -40, 0, 42)
    MiniGameBtn.Position = UDim2.new(0, 20, 0, 384)
    MiniGameBtn.BackgroundColor3 = Color3.fromRGB(34, 9, 16)
    MiniGameBtn.Text = CanPlayGachaToday() and Languages[CurrentLang].MiniGame or Languages[CurrentLang].MiniGameLocked
    MiniGameBtn.TextColor3 = CanPlayGachaToday() and Color3.fromRGB(255, 215, 225) or Color3.fromRGB(140, 80, 95)
    MiniGameBtn.TextSize = 11.5
    MiniGameBtn.Font = Enum.Font.GothamBold
    MiniGameBtn.AutoButtonColor = false
    MiniGameBtn.ZIndex = 32
    MiniGameBtn.Parent = MainFrame
    Instance.new("UICorner", MiniGameBtn).CornerRadius = UDim.new(0, 11)
    local MiniGameStroke = Instance.new("UIStroke", MiniGameBtn)
    MiniGameStroke.Color = CanPlayGachaToday() and Color3.fromRGB(225, 29, 72) or Color3.fromRGB(60, 20, 30)
    MiniGameStroke.Thickness = 1.3

    local StatusMsg = Instance.new("TextLabel")
    StatusMsg.Size = UDim2.new(1, -40, 0, 20)
    StatusMsg.Position = UDim2.new(0, 20, 0, 436)
    StatusMsg.BackgroundTransparency = 1
    StatusMsg.Text = "Chilli Hub V5 • Steal An Egg 🥚 • by ronnei7.htk"
    StatusMsg.TextColor3 = Color3.fromRGB(140, 75, 90)
    StatusMsg.TextSize = 10
    StatusMsg.Font = Enum.Font.GothamMedium
    StatusMsg.ZIndex = 31
    StatusMsg.Parent = MainFrame

    -- MODAL HỘP QUÀ GACHA (DÙNG HÌNH HỘP QUÀ GiftBoxAssetId)[span_10](start_span)[span_10](end_span)
    local GachaModal = Instance.new("Frame")
    GachaModal.Name = "GachaModal"
    GachaModal.Size = UDim2.new(1, 0, 1, 0)
    GachaModal.Position = UDim2.new(0, 0, 1, 0)
    GachaModal.BackgroundColor3 = Color3.fromRGB(13, 4, 8)
    GachaModal.BackgroundTransparency = 0.02
    GachaModal.ZIndex = 45
    GachaModal.ClipsDescendants = true
    GachaModal.Parent = MainFrame
    Instance.new("UICorner", GachaModal).CornerRadius = UDim.new(0, 22)

    local GachaHeader = Instance.new("TextLabel")
    GachaHeader.Size = UDim2.new(1, -60, 0, 26)
    GachaHeader.Position = UDim2.new(0, 20, 0, 14)
    GachaHeader.BackgroundTransparency = 1
    GachaHeader.Text = "🎁 HỘP QUÀ MAY MẮN (1 LẦN/NGÀY)"
    GachaHeader.TextColor3 = Color3.fromRGB(255, 185, 200)
    GachaHeader.TextSize = 12.5
    GachaHeader.Font = Enum.Font.GothamBold
    GachaHeader.TextXAlignment = Enum.TextXAlignment.Left
    GachaHeader.ZIndex = 46
    GachaHeader.Parent = GachaModal

    local GachaCloseBtn = Instance.new("TextButton")
    GachaCloseBtn.Size = UDim2.new(0, 28, 0, 28)
    GachaCloseBtn.Position = UDim2.new(1, -38, 0, 14)
    GachaCloseBtn.BackgroundColor3 = Color3.fromRGB(26, 7, 13)
    GachaCloseBtn.Text = "✕"
    GachaCloseBtn.TextColor3 = Color3.fromRGB(225, 29, 72)
    GachaCloseBtn.TextSize = 11.5
    GachaCloseBtn.Font = Enum.Font.GothamBold
    GachaCloseBtn.ZIndex = 46
    GachaCloseBtn.Parent = GachaModal
    Instance.new("UICorner", GachaCloseBtn).CornerRadius = UDim.new(0, 6)

    local GachaSubText = Instance.new("TextLabel")
    GachaSubText.Size = UDim2.new(1, -40, 0, 26)
    GachaSubText.Position = UDim2.new(0, 20, 0, 44)
    GachaSubText.BackgroundTransparency = 1
    GachaSubText.Text = "Chọn 1 trong 2 hộp quà. Trúng NoKey sẽ vào thẳng script không cần GetKey!"
    GachaSubText.TextColor3 = Color3.fromRGB(230, 140, 160)
    GachaSubText.TextSize = 10.5
    GachaSubText.Font = Enum.Font.GothamMedium
    GachaSubText.TextWrapped = true
    GachaSubText.TextXAlignment = Enum.TextXAlignment.Left
    GachaSubText.ZIndex = 46
    GachaSubText.Parent = GachaModal

    local BoxesContainer = Instance.new("Frame")
    BoxesContainer.Size = UDim2.new(1, -40, 0, 240)
    BoxesContainer.Position = UDim2.new(0, 20, 0, 78)
    BoxesContainer.BackgroundTransparency = 1
    BoxesContainer.ZIndex = 46
    BoxesContainer.Parent = GachaModal

    local function CreateMysteryBox(name: string, posXScale: number, posXOffset: number, boxTitle: string)
        local BoxCard = Instance.new("TextButton")
        BoxCard.Name = name
        BoxCard.Size = UDim2.new(0.5, -6, 1, 0)
        BoxCard.Position = UDim2.new(posXScale, posXOffset, 0, 0)
        BoxCard.BackgroundColor3 = Color3.fromRGB(20, 6, 12)
        BoxCard.Text = ""
        BoxCard.AutoButtonColor = false
        BoxCard.ZIndex = 47
        BoxCard.Parent = BoxesContainer
        Instance.new("UICorner", BoxCard).CornerRadius = UDim.new(0, 16)
        local BoxStroke = Instance.new("UIStroke", BoxCard)
        BoxStroke.Color = Color3.fromRGB(150, 40, 60)
        BoxStroke.Thickness = 1.3

        local Tag5050 = Instance.new("TextLabel")
        Tag5050.Size = UDim2.new(1, -16, 0, 20)
        Tag5050.Position = UDim2.new(0, 8, 0, 8)
        Tag5050.BackgroundColor3 = Color3.fromRGB(34, 9, 16)
        Tag5050.Text = "TỈ LỆ: 50% - 50%"
        Tag5050.TextColor3 = Color3.fromRGB(255, 200, 215)
        Tag5050.TextSize = 9.5
        Tag5050.Font = Enum.Font.GothamBold
        Tag5050.ZIndex = 48
        Tag5050.Parent = BoxCard
        Instance.new("UICorner", Tag5050).CornerRadius = UDim.new(0, 6)
        local TagStroke = Instance.new("UIStroke", Tag5050)
        TagStroke.Color = Color3.fromRGB(210, 50, 80)
        TagStroke.Thickness = 1

        local CropMask = Instance.new("Frame")
        CropMask.Name = "CropMask"
        CropMask.AnchorPoint = Vector2.new(0.5, 0)
        CropMask.Size = UDim2.new(0, 104, 0, 104)
        CropMask.Position = UDim2.new(0.5, 0, 0, 36)
        CropMask.BackgroundTransparency = 1
        CropMask.BorderSizePixel = 0
        CropMask.ClipsDescendants = true
        CropMask.ZIndex = 48
        CropMask.Parent = BoxCard
        Instance.new("UICorner", CropMask).CornerRadius = UDim.new(0, 18)

        local GiftImage = Instance.new("ImageLabel")
        GiftImage.Name = "GiftImage"
        GiftImage.AnchorPoint = Vector2.new(0.5, 0.5)
        GiftImage.Size = UDim2.new(1.2, 0, 1.2, 0)
        GiftImage.Position = UDim2.new(0.5, 0, 0.5, 0)
        GiftImage.BackgroundTransparency = 1
        GiftImage.Image = GiftBoxAssetId -- Đúng hình hộp quà GiftBoxAssetId[span_11](start_span)[span_11](end_span)
        GiftImage.ScaleType = Enum.ScaleType.Fit
        GiftImage.ZIndex = 49
        GiftImage.Parent = CropMask

        local Title = Instance.new("TextLabel")
        Title.Name = "BoxTitle"
        Title.Size = UDim2.new(1, 0, 0, 18)
        Title.Position = UDim2.new(0, 0, 0, 148)
        Title.BackgroundTransparency = 1
        Title.Text = boxTitle
        Title.TextColor3 = Color3.fromRGB(250, 230, 235)
        Title.TextSize = 12
        Title.Font = Enum.Font.GothamBold
        Title.ZIndex = 48
        Title.Parent = BoxCard

        local ActionHint = Instance.new("TextLabel")
        ActionHint.Name = "ActionHint"
        ActionHint.Size = UDim2.new(1, -20, 0, 26)
        ActionHint.Position = UDim2.new(0, 10, 0, 186)
        ActionHint.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
        ActionHint.Text = "MỞ HỘP"
        ActionHint.TextColor3 = Color3.fromRGB(255, 255, 255)
        ActionHint.TextSize = 10.5
        ActionHint.Font = Enum.Font.GothamBold
        ActionHint.ZIndex = 48
        ActionHint.Parent = BoxCard
        Instance.new("UICorner", ActionHint).CornerRadius = UDim.new(0, 8)

        return BoxCard, BoxStroke, CropMask, Title, ActionHint
    end

    local Box1, Box1Stroke, Box1Mask, Box1Title, Box1Hint = CreateMysteryBox("Box1", 0, 0, "HỘP QUÀ #1")
    local Box2, Box2Stroke, Box2Mask, Box2Title, Box2Hint = CreateMysteryBox("Box2", 0.5, 6, "HỘP QUÀ #2")

    local GachaResultBanner = Instance.new("TextLabel")
    GachaResultBanner.Size = UDim2.new(1, -36, 0, 38)
    GachaResultBanner.Position = UDim2.new(0, 18, 0, 324)
    GachaResultBanner.BackgroundColor3 = Color3.fromRGB(20, 6, 12)
    GachaResultBanner.Text = "Bấm vào 1 trong 2 hộp quà phía trên để thử vận may!"
    GachaResultBanner.TextColor3 = Color3.fromRGB(245, 175, 195)
    GachaResultBanner.TextSize = 10.5
    GachaResultBanner.Font = Enum.Font.GothamMedium
    GachaResultBanner.ZIndex = 46
    GachaResultBanner.Parent = GachaModal
    Instance.new("UICorner", GachaResultBanner).CornerRadius = UDim.new(0, 10)
    -- =========================================================================
--   🌶️ CHILLI HUB V5 X RONNEI - STEAL AN EGG 🥚 (PHẦN 5/5)
--   BACKEND TỈ LỆ 80% GETKEY - 20% NOKEY · ĐỔI NGÔN NGỮ · LUỒNG DÙNG THỬ
-- =========================================================================

    local isRollingMutex = false

    local function OpenGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
    end

    local function CloseGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(0, 0, 1, 0)
        }):Play()
    end

    GachaCloseBtn.MouseButton1Click:Connect(function()
        if isRollingMutex then return end
        PlaySpringButton(GachaCloseBtn)
        CloseGachaModal()
    end)

    MiniGameBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(MiniGameBtn)
        if not CanPlayGachaToday() then
            local secsLeft = GetSecondsUntilMidnightGMT7()
            local hoursLeft = math.floor(secsLeft / 3600)
            local minsLeft = math.floor((secsLeft % 3600) / 60)
            StatusMsg.Text = string.format("⏳ Đã mở hôm nay! Reset sau %02d:%02d (00:00 GMT+7)", hoursLeft, minsLeft)
            StatusMsg.TextColor3 = Color3.fromRGB(239, 68, 68)
            return
        end
        OpenGachaModal()
    end)

    -- HÀM MỞ HỘP: TỈ LỆ THỰC TẾ 80% GETKEY (> 20) VÀ 20% NOKEY (<= 20)
    local function ExecuteBoxRoll(chosenBox: TextButton, otherBox: TextButton, chosenStroke: UIStroke, chosenMask: Frame, chosenTitle: TextLabel, chosenHint: TextLabel)
        if isRollingMutex then return end
        isRollingMutex = true

        SaveGachaPlayed()
        MiniGameBtn.Text = Languages[CurrentLang].MiniGameLocked
        MiniGameBtn.TextColor3 = Color3.fromRGB(140, 80, 95)
        MiniGameStroke.Color = Color3.fromRGB(60, 20, 30)

        TweenService:Create(otherBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.65 }):Play()
        otherBox.Active = false

        chosenStroke.Color = Color3.fromRGB(245, 158, 11)
        chosenHint.Text = "ĐANG MỞ..."
        chosenHint.BackgroundColor3 = Color3.fromRGB(217, 119, 6)
        GachaResultBanner.Text = "⏳ Đang hồi hộp bóc seal hộp quà..."
        GachaResultBanner.TextColor3 = Color3.fromRGB(253, 224, 71)

        for i = 1, 8 do
            local angle = (i % 2 == 0) and 6 or -6
            TweenService:Create(chosenMask, TweenInfo.new(0.06, Enum.EasingStyle.Quad), { Rotation = angle }):Play()
            task.wait(0.065)
        end
        TweenService:Create(chosenMask, TweenInfo.new(0.08, Enum.EasingStyle.Back), { Rotation = 0 }):Play()
        task.wait(0.25)

        local roll = math.random(1, 100)
        local isNoKeyWon = (roll <= 20)

        if isNoKeyWon then
            chosenStroke.Color = Color3.fromRGB(34, 197, 94)
            chosenTitle.Text = "🎉 TRÚNG NOKEY!"
            chosenTitle.TextColor3 = Color3.fromRGB(74, 222, 128)
            chosenHint.Text = "VÀO SCRIPT NGAY"
            chosenHint.BackgroundColor3 = Color3.fromRGB(22, 163, 74)

            GachaResultBanner.Text = "🎉 Chúc mừng! Bạn trúng NoKey! Đang tải script..."
            GachaResultBanner.TextColor3 = Color3.fromRGB(74, 222, 128)

            Save24hKey(GetSecondsUntilMidnightGMT7())

            task.wait(1.2)
            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()

            TweenService:Create(MainScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.5 }):Play()
            task.wait(0.25)
            ScreenGui:Destroy()
        else
            chosenStroke.Color = Color3.fromRGB(225, 29, 72)
            chosenTitle.Text = "🔑 TRÚNG GETKEY"
            chosenTitle.TextColor3 = Color3.fromRGB(251, 113, 133)
            chosenHint.Text = "QUAY VỀ LẤY KEY"
            chosenHint.BackgroundColor3 = Color3.fromRGB(159, 18, 57)

            GachaResultBanner.Text = "😢 Hộp này là GetKey! Vui lòng vượt link để lấy key nhé."
            GachaResultBanner.TextColor3 = Color3.fromRGB(251, 113, 133)

            task.wait(1.6)
            CloseGachaModal()
            isRollingMutex = false

            StatusMsg.Text = "📌 Mở trúng GetKey! Bấm 'Lấy Key (24 Tiếng)' để tiếp tục."
            StatusMsg.TextColor3 = Color3.fromRGB(251, 113, 133)
        end
    end

    Box1.MouseButton1Click:Connect(function()
        ExecuteBoxRoll(Box1, Box2, Box1Stroke, Box1Mask, Box1Title, Box1Hint)
    end)

    Box2.MouseButton1Click:Connect(function()
        ExecuteBoxRoll(Box2, Box1, Box2Stroke, Box2Mask, Box2Title, Box2Hint)
    end)

    QuickPasteBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(QuickPasteBtn)
        local pasted = false
        pcall(function()
            if getclipboard then
                InputBox.Text = getclipboard()
                pasted = true
            elseif fromclipboard then
                InputBox.Text = fromclipboard()
                pasted = true
            end
        end)
        if not pasted then
            InputBox:CaptureFocus()
        end
    end)

    local isTutorialDebounce = false
    TutorialBtn.MouseButton1Click:Connect(function()
        if isTutorialDebounce then return end
        isTutorialDebounce = true
        PlaySpringButton(TutorialBtn)

        if setclipboard then setclipboard(TutorialUrl) elseif toclipboard then toclipboard(TutorialUrl) end

        TutorialBtn.Text = "📖 ĐÃ SAO CHÉP LINK HƯỚNG DẪN!"
        TutorialBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        TutorialStroke.Color = Color3.fromRGB(52, 211, 153)
        StatusMsg.Text = Languages[CurrentLang].CopiedTutorial
        StatusMsg.TextColor3 = Color3.fromRGB(52, 211, 153)

        task.delay(2.5, function()
            if TutorialBtn and TutorialBtn.Parent then
                TutorialBtn.Text = Languages[CurrentLang].Tutorial
                TutorialBtn.BackgroundColor3 = Color3.fromRGB(22, 6, 12)
                TutorialStroke.Color = Color3.fromRGB(130, 35, 55)
                StatusMsg.Text = "Chilli Hub V5 • Steal An Egg 🥚 • by ronnei7.htk"
                StatusMsg.TextColor3 = Color3.fromRGB(140, 75, 90)
            end
            isTutorialDebounce = false
        end)
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(GetKeyBtn)
        if setclipboard then setclipboard(KeyUrl) elseif toclipboard then toclipboard(KeyUrl) end

        GetKeyBtn.Text = "COPIED LINK (24H)!"
        GetKeyBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        GetKeyStroke.Color = Color3.fromRGB(52, 211, 153)
        StatusMsg.Text = Languages[CurrentLang].CopiedLink
        StatusMsg.TextColor3 = Color3.fromRGB(52, 211, 153)

        task.delay(2.5, function()
            if GetKeyBtn and GetKeyBtn.Parent then
                GetKeyBtn.Text = Languages[CurrentLang].GetKey
                GetKeyBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
                GetKeyStroke.Color = Color3.fromRGB(244, 63, 94)
                StatusMsg.Text = "Chilli Hub V5 • Steal An Egg 🥚 • by ronnei7.htk"
                StatusMsg.TextColor3 = Color3.fromRGB(140, 75, 90)
            end
        end)
    end)

    local isChecking = false
    CheckKeyBtn.MouseButton1Click:Connect(function()
        if isChecking then return end
        isChecking = true
        PlaySpringButton(CheckKeyBtn)

        CheckKeyBtn.Text = Languages[CurrentLang].Checking
        StatusMsg.Text = Languages[CurrentLang].CheckingMsg
        StatusMsg.TextColor3 = Color3.fromRGB(245, 195, 210)

        task.wait(0.35)
        local isKeyValid = VerifyChilliV5Key(InputBox.Text)

        if isKeyValid then
            Save24hKey()
            CheckKeyBtn.Text = "SUCCESS"
            CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 101, 52)
            CheckStroke.Color = Color3.fromRGB(74, 222, 128)
            StatusMsg.Text = Languages[CurrentLang].Success
            StatusMsg.TextColor3 = Color3.fromRGB(74, 222, 128)

            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()

            task.wait(0.4)
            TweenService:Create(MainScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.5 }):Play()
            task.wait(0.25)
            ScreenGui:Destroy()
        else
            isChecking = false
            CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
            StatusMsg.Text = Languages[CurrentLang].Error
            StatusMsg.TextColor3 = Color3.fromRGB(239, 68, 68)

            InputStroke.Color = Color3.fromRGB(225, 29, 72)
            local origOffset = MainFrame.Position.X.Offset
            local offsets = { -8, 8, -6, 6, -3, 3, 0 }
            task.spawn(function()
                for _, off in ipairs(offsets) do
                    local t = TweenService:Create(MainFrame, TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0.5, off, 0.5, 0)
                    })
                    t:Play()
                    t.Completed:Wait()
                end
                MainFrame.Position = UDim2.new(0.5, origOffset, 0.5, 0)
            end)
            task.wait(0.6)
            InputStroke.Color = Color3.fromRGB(60, 18, 28)
        end
    end)

    -- ĐỔI NGÔN NGỮ TRỰC TIẾP
    OpenLangBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(OpenLangBtn)
        CurrentLang = (CurrentLang == "VI") and "EN" or "VI"
        local data = Languages[CurrentLang]
        OpenLangBtn.Text = data.LangBtnText
        TitleLabel.Text = data.Title
        SubTitleLabel.Text = data.Subtitle
        CenterTitle.Text = data.CenterTitle
        CenterSub.Text = data.CenterSub
        InputBox.PlaceholderText = data.Placeholder
        QuickPasteBtn.Text = data.QuickPaste
        GetKeyBtn.Text = data.GetKey
        CheckKeyBtn.Text = data.CheckKey
        TutorialBtn.Text = data.Tutorial
        MiniGameBtn.Text = CanPlayGachaToday() and data.MiniGame or data.MiniGameLocked
        NoticeText.Text = data.Notice
    end)

    MainFrame.BackgroundTransparency = 1
    MainScale.Scale = 0.4
    TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(MainScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- =========================================================================
--   LUỒNG CHÍNH: DÙNG THỬ 2 PHÚT & KHÓA MÀN HÌNH TỰ ĐỘNG
-- =========================================================================

local keyTimeLeft = GetKeyRemainingTime()
if keyTimeLeft and keyTimeLeft > 0 then
    ShowLiveToast("CHILLI HUB V5 (24H)", keyTimeLeft, Color3.fromRGB(225, 29, 72))
    LaunchTargetScriptWithWatcher()
    return
end

local trialData = LoadTrialData()

if not trialData then
    trialData = { StartTime = os.time(), LastSeen = os.time() }
    SaveTrialData(trialData.StartTime, trialData.LastSeen)
end

if trialData.Tampered then
    ApplyScreenLockdown()
    ShowLiveToast("⚠ SECURITY: TAMPER DETECTED", 0, Color3.fromRGB(239, 68, 68))
    OpenKeySystemUI()
    return
end

local targetEndTime = trialData.StartTime + TRIAL_DURATION
local remaining = targetEndTime - os.time()

if remaining <= 0 then
    ApplyScreenLockdown()
    ShowLiveToast("⚠️ HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(225, 29, 72))
    OpenKeySystemUI()
    return
else
    ShowLiveToast("CHILLI HUB V5 (DÙNG THỬ 2 PHÚT)", remaining, Color3.fromRGB(225, 29, 72))
    LaunchTargetScriptWithWatcher()

    task.spawn(function()
        local saveInterval = 0

        while true do
            task.wait(1)
            local currentRemaining = targetEndTime - os.time()

            if ActiveToastLabel and ActiveToastLabel.Parent then
                ActiveToastLabel.Text = "Thời gian dùng thử: " .. FormatTime(currentRemaining)
            end

            saveInterval = saveInterval + 1
            if saveInterval >= 10 then
                saveInterval = 0
                SaveTrialData(trialData.StartTime, os.time())
            end

            if GetKeyRemainingTime() then return end

            if currentRemaining <= 0 then
                SaveTrialData(trialData.StartTime, os.time())
                TerminateTargetScript()
                ApplyScreenLockdown()
                ShowLiveToast("⚠️ HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(225, 29, 72))
                task.wait(0.3)
                OpenKeySystemUI()
                break
            end
        end
    end)
end
