-- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 1/5)
--   CẤU HÌNH HỆ THỐNG · MÃ HÓA BẢO MẬT · XỬ LÝ CHU KỲ 00:00 GMT+7
-- =========================================================================

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local KeyUrl = "https://link4m.net/80x8y"
local TutorialUrl = "https://craftvip.github.io/free/getkey.html"
local TargetScriptUrl = "https://raw.githubusercontent.com/robvxs24/freemium/refs/heads/main/chillihubv2.lua"

local KeyFileName = "ChilliV2_KeyData.json"
local TrialFileName = "ChilliV2_TrialData.json"
local GachaFileName = "ChilliV2_GachaData.json"
local TRIAL_DURATION = 120 -- Thời hạn dùng thử chính xác 2 phút (120 giây)

local InitialGuis = {}
local ScriptConnections = {}
local ActiveBlurEffect = nil
local InputBlockerScreen = nil
local OpenKeySystemUI = nil

-- MODULE MÃ HÓA DỮ LIỆU CỤC BỘ HEX-XOR
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

-- TÍNH TOÁN NGÀY THEO MÚI GIỜ GMT+7 (RESET LÚC 00:00 HẰNG NGÀY)
local function GetCurrentDateGMT7(): string
    local vnTime = os.time() + (7 * 3600)
    local dateTable = os.date("!*t", vnTime)
    return string.format("%04d-%02d-%02d", dateTable.year, dateTable.month, dateTable.day)
end

local function GetSecondsUntilMidnightGMT7(): number
    local vnTime = os.time() + (7 * 3600)
    local dateTable = os.date("!*t", vnTime)
    local currentDaySeconds = (dateTable.hour * 3600) + (dateTable.min * 60) + dateTable.sec
    return 86400 - currentDaySeconds
end

-- QUẢN LÝ DỮ LIỆU MINI-GAME GACHA HẰNG NGÀY
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
            local data = {
                LastGachaDate = GetCurrentDateGMT7(),
                Timestamp = os.time()
            }
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

-- THUẬT TOÁN ĐỐI SOÁT KEY 24H (GMT+7)
local function VerifyChilliV2Key(rawInput: string): boolean
    if not rawInput or rawInput == "" then return false end
    local clean = string.lower(string.gsub(rawInput, "[%s%c]", ""))
    clean = clean:gsub("^chillihubv2%-", ""):gsub("^chilliv2%-", "")

    local vnTime = os.time() + (7 * 3600)
    local testTimes = { vnTime, vnTime - 86400, vnTime + 3600 }

    for _, t in ipairs(testTimes) do
        local d = os.date("!*t", t)
        local v1 = (d.day * 3617 + d.month * 2851 + d.year * 149) % 65535
        local v2 = (d.day * 6211 + d.month * 4397 + d.year * 269) % 65535
        local v3 = (d.day * 7919 + d.month * 6571 + d.year * 409) % 65535
        local target = string.format("%04x-%04x-%04x", v1, v2, v3)

        if clean == target then
            return true
        end
    end
    return false
end
-- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 2/5)
--   SNAPSHOT QUẢN LÝ GIAO DIỆN · KHÓA MÀN HÌNH BẢO MẬT · LIVE TOAST HUD
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
        ActiveBlurEffect.Name = "ChilliV2_LockdownBlur"
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
        InputBlockerScreen.Name = "ChilliV2_InputBlocker"
        InputBlockerScreen.ResetOnSpawn = false
        pcall(function() InputBlockerScreen.Parent = CoreGui end)
        if not InputBlockerScreen.Parent then InputBlockerScreen.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        local shield = Instance.new("TextButton")
        shield.Size = UDim2.new(1, 0, 1, 0)
        shield.Position = UDim2.new(0, 0, 0, 0)
        shield.BackgroundColor3 = Color3.fromRGB(10, 4, 7)
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
    getgenv().ChilliV2_Active = false
    getgenv().ChilliV2_TrialExpired = true

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
                if not InitialGuis[child] and child.Name ~= "ChilliV2_GetKeyUI" and child.Name ~= "ChilliV2_ToastUI" and child.Name ~= "ChilliV2_InputBlocker" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function LaunchTargetScriptWithWatcher()
    TakeGuiSnapshot()
    getgenv().ChilliV2_Active = true

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
    if CoreGui:FindFirstChild("ChilliV2_ToastUI") then CoreGui.ChilliV2_ToastUI:Destroy() end
    if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("ChilliV2_ToastUI") then
        LocalPlayer.PlayerGui.ChilliV2_ToastUI:Destroy()
    end

    local ToastGui = Instance.new("ScreenGui")
    ToastGui.Name = "ChilliV2_ToastUI"
    ToastGui.ResetOnSpawn = false
    pcall(function() ToastGui.Parent = CoreGui end)
    if not ToastGui.Parent then ToastGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local ToastFrame = Instance.new("Frame")
    ToastFrame.Size = UDim2.new(0, 385, 0, 72)
    ToastFrame.Position = UDim2.new(0.5, -192, 0, -100)
    ToastFrame.BackgroundColor3 = Color3.fromRGB(16, 6, 10)
    ToastFrame.BorderSizePixel = 0
    ToastFrame.ZIndex = 50
    ToastFrame.Parent = ToastGui

    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 16)
    local Stroke = Instance.new("UIStroke", ToastFrame)
    Stroke.Thickness = 1.4
    Stroke.Color = color or Color3.fromRGB(225, 75, 105)

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
    Bar.BackgroundColor3 = color or Color3.fromRGB(225, 75, 105)
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
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 3/5)
--   GIAO DIỆN VELVET RUBY MỜ 470PX · Ô NHẬP LIỆU THÔNG MINH · DÁN NHANH
-- =========================================================================

local Languages = {
    VI = {
        LangBtnText = "🇻🇳 VN ▾",
        SelectLangTitle = "🌶️ NGÔN NGỮ HỆ THỐNG / LANGUAGE",
        Title = "Chilli Hub V2 X Ronnei",
        Subtitle = "chilli hub v2 được tạo bởi ronnei7.htk",
        CenterTitle = "CHILLI HUB V2 × RONNEI",
        CenterSub = "Steal An Egg 🥚 Edition",
        Placeholder = "Dán mã key bản quyền tại đây...",
        QuickPaste = "📋 Dán",
        GetKey = "⚡ LẤY KEY (24 TIẾNG)",
        CheckKey = "🌶️ KÍCH HOẠT V2",
        Tutorial = "📖 HƯỚNG DẪN CÁCH VƯỢT LINK LẤY KEY",
        MiniGame = "🎁 MINI GAME: GETKEY OR NOKEY",
        MiniGameLocked = "🔒 ĐÃ MỞ HÔM NAY (HỒI 00:00 ĐÊM)",
        Notice = "📌 Lưu ý: Link getkey 24 tiếng thao tác nhanh gọn (chỉ 1 phút vượt link). Mỗi key có hạn sử dụng đúng 24 giờ kể từ khi kích hoạt.",
        CopiedLink = "📋 ĐÃ SAO CHÉP LINK GETKEY 24 TIẾNG VÀO CLIPBOARD!",
        CopiedTutorial = "📖 ĐÃ SAO CHÉP LINK HƯỚNG DẪN VÀO CLIPBOARD!",
        Checking = "ĐANG XÁC THỰC...",
        CheckingMsg = "⏳ Đang đối soát chứng chỉ mã hóa trên máy chủ Chilli...",
        Success = "✔ Xác thực thành công! Đang khởi động Chilli Hub V2...",
        Error = "✖ Mã Key không chính xác hoặc phiên 24 giờ đã hết hạn!"
    },
    EN = {
        LangBtnText = "🇺🇸 EN ▾",
        SelectLangTitle = "🌶️ SELECT SYSTEM LANGUAGE",
        Title = "Chilli Hub V2 X Ronnei",
        Subtitle = "chilli hub v2 được tạo bởi ronnei7.htk",
        CenterTitle = "CHILLI HUB V2 × RONNEI",
        CenterSub = "Steal An Egg 🥚 Edition",
        Placeholder = "Paste your license key here...",
        QuickPaste = "📋 Paste",
        GetKey = "⚡ GET KEY (24 HOURS)",
        CheckKey = "🌶️ ACTIVATE V2",
        Tutorial = "📖 HOW TO BYPASS LINK & GET KEY TUTORIAL",
        MiniGame = "🎁 MINI GAME: GETKEY OR NOKEY",
        MiniGameLocked = "🔒 OPENED TODAY (RESETS AT 00:00)",
        Notice = "📌 Notice: 24-hour key link is fast and easy (takes only 1 min). Each key remains fully valid for exactly 24 hours.",
        CopiedLink = "📋 24-HOUR KEY LINK COPIED TO CLIPBOARD!",
        CopiedTutorial = "📖 TUTORIAL LINK COPIED TO CLIPBOARD!",
        Checking = "AUTHENTICATING...",
        CheckingMsg = "⏳ Verifying Velvet Ruby credentials with Chilli server...",
        Success = "✔ Authorization granted! Launching Chilli Hub V2...",
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
    if CoreGui:FindFirstChild("ChilliV2_GetKeyUI") then CoreGui.ChilliV2_GetKeyUI:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ChilliV2_GetKeyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- MainFrame chiều cao 470px chứa trọn các nút hành động
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 440, 0, 470)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 6, 9)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 30
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 22)

    local MainScale = Instance.new("UIScale", MainFrame)
    MainScale.Scale = 0.5

    -- Viền nhịp thở Velvet Rose tối ưu qua C++ Tween
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Thickness = 1.4
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = Color3.fromRGB(225, 65, 95)

    local breatheTween = TweenService:Create(MainStroke, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Color = Color3.fromRGB(160, 40, 65)
    })
    breatheTween:Play()

    -- HEADER TOP BAR
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, -24, 0, 42)
    HeaderBar.Position = UDim2.new(0, 12, 0, 10)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.ZIndex = 31
    HeaderBar.Parent = MainFrame

    local MiniLogo = Instance.new("Frame")
    MiniLogo.Size = UDim2.new(0, 28, 0, 28)
    MiniLogo.Position = UDim2.new(0, 0, 0.5, -14)
    MiniLogo.BackgroundColor3 = Color3.fromRGB(28, 9, 14)
    MiniLogo.ZIndex = 32
    MiniLogo.Parent = HeaderBar
    Instance.new("UICorner", MiniLogo).CornerRadius = UDim.new(1, 0)
    local MiniLogoStroke = Instance.new("UIStroke", MiniLogo)
    MiniLogoStroke.Color = Color3.fromRGB(220, 68, 98)
    MiniLogoStroke.Thickness = 1.2

    local MiniLogoTxt = Instance.new("TextLabel")
    MiniLogoTxt.Size = UDim2.new(1, 0, 1, 0)
    MiniLogoTxt.BackgroundTransparency = 1
    MiniLogoTxt.Text = "🌶️"
    MiniLogoTxt.TextSize = 13
    MiniLogoTxt.ZIndex = 33
    MiniLogoTxt.Parent = MiniLogo

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -115, 0, 18)
    TitleLabel.Position = UDim2.new(0, 36, 0, 2)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Languages[CurrentLang].Title
    TitleLabel.TextColor3 = Color3.fromRGB(250, 235, 238)
    TitleLabel.TextSize = 12
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 32
    TitleLabel.Parent = HeaderBar

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Size = UDim2.new(1, -115, 0, 16)
    SubTitleLabel.Position = UDim2.new(0, 36, 0, 20)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = Languages[CurrentLang].Subtitle
    SubTitleLabel.TextColor3 = Color3.fromRGB(235, 148, 170)
    SubTitleLabel.TextSize = 10
    SubTitleLabel.Font = Enum.Font.GothamMedium
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.ZIndex = 32
    SubTitleLabel.Parent = HeaderBar

    local OpenLangBtn = Instance.new("TextButton")
    OpenLangBtn.Size = UDim2.new(0, 76, 0, 26)
    OpenLangBtn.Position = UDim2.new(1, -76, 0.5, -13)
    OpenLangBtn.BackgroundColor3 = Color3.fromRGB(26, 8, 13)
    OpenLangBtn.Text = Languages[CurrentLang].LangBtnText
    OpenLangBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    OpenLangBtn.TextSize = 10.5
    OpenLangBtn.Font = Enum.Font.GothamBold
    OpenLangBtn.AutoButtonColor = false
    OpenLangBtn.ZIndex = 32
    OpenLangBtn.Parent = HeaderBar
    Instance.new("UICorner", OpenLangBtn).CornerRadius = UDim.new(0, 8)
    local LangStroke = Instance.new("UIStroke", OpenLangBtn)
    LangStroke.Color = Color3.fromRGB(180, 50, 75)
    LangStroke.Thickness = 1

    -- LOGO TRUNG TÂM PHÙ ĐIÊU THẠCH ANH
    local CenterLogoBox = Instance.new("Frame")
    CenterLogoBox.Size = UDim2.new(0, 52, 0, 52)
    CenterLogoBox.Position = UDim2.new(0.5, -26, 0, 48)
    CenterLogoBox.BackgroundColor3 = Color3.fromRGB(24, 7, 12)
    CenterLogoBox.ZIndex = 31
    CenterLogoBox.Parent = MainFrame
    Instance.new("UICorner", CenterLogoBox).CornerRadius = UDim.new(0, 16)
    local CenterLogoStroke = Instance.new("UIStroke", CenterLogoBox)
    CenterLogoStroke.Color = Color3.fromRGB(220, 68, 98)
    CenterLogoStroke.Thickness = 1.2

    local CenterLogoTxt = Instance.new("TextLabel")
    CenterLogoTxt.Size = UDim2.new(1, 0, 1, 0)
    CenterLogoTxt.BackgroundTransparency = 1
    CenterLogoTxt.Text = "🥚"
    CenterLogoTxt.TextSize = 25
    CenterLogoTxt.ZIndex = 32
    CenterLogoTxt.Parent = CenterLogoBox

    local CenterTitle = Instance.new("TextLabel")
    CenterTitle.Size = UDim2.new(1, -30, 0, 18)
    CenterTitle.Position = UDim2.new(0, 15, 0, 104)
    CenterTitle.BackgroundTransparency = 1
    CenterTitle.Text = Languages[CurrentLang].CenterTitle
    CenterTitle.TextColor3 = Color3.fromRGB(252, 242, 245)
    CenterTitle.TextSize = 13
    CenterTitle.Font = Enum.Font.GothamBold
    CenterTitle.ZIndex = 31
    CenterTitle.Parent = MainFrame

    local CenterSub = Instance.new("TextLabel")
    CenterSub.Size = UDim2.new(1, -30, 0, 15)
    CenterSub.Position = UDim2.new(0, 15, 0, 123)
    CenterSub.BackgroundTransparency = 1
    CenterSub.Text = Languages[CurrentLang].CenterSub
    CenterSub.TextColor3 = Color3.fromRGB(235, 148, 170)
    CenterSub.TextSize = 9.5
    CenterSub.Font = Enum.Font.GothamMedium
    CenterSub.ZIndex = 31
    CenterSub.Parent = MainFrame

    -- KHUNG NHẬP LIỆU THÔNG MINH (Ô GÕ + NÚT DÁN NHANH)
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -36, 0, 36)
    InputContainer.Position = UDim2.new(0, 18, 0, 142)
    InputContainer.BackgroundColor3 = Color3.fromRGB(22, 7, 12)
    InputContainer.ZIndex = 31
    InputContainer.Parent = MainFrame
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 10)
    local InputStroke = Instance.new("UIStroke", InputContainer)
    InputStroke.Color = Color3.fromRGB(60, 18, 28)

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -75, 1, 0)
    InputBox.Position = UDim2.new(0, 10, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.TextColor3 = Color3.fromRGB(248, 235, 238)
    InputBox.PlaceholderColor3 = Color3.fromRGB(135, 75, 90)
    InputBox.PlaceholderText = Languages[CurrentLang].Placeholder
    InputBox.Text = ""
    InputBox.TextSize = 11
    InputBox.Font = Enum.Font.GothamMedium
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.ZIndex = 32
    InputBox.Parent = InputContainer

    local QuickPasteBtn = Instance.new("TextButton")
    QuickPasteBtn.Size = UDim2.new(0, 56, 0, 24)
    QuickPasteBtn.Position = UDim2.new(1, -62, 0.5, -12)
    QuickPasteBtn.BackgroundColor3 = Color3.fromRGB(34, 10, 17)
    QuickPasteBtn.Text = Languages[CurrentLang].QuickPaste
    QuickPasteBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    QuickPasteBtn.TextSize = 10
    QuickPasteBtn.Font = Enum.Font.GothamBold
    QuickPasteBtn.AutoButtonColor = false
    QuickPasteBtn.ZIndex = 33
    QuickPasteBtn.Parent = InputContainer
    Instance.new("UICorner", QuickPasteBtn).CornerRadius = UDim.new(0, 7)
    local QuickPasteStroke = Instance.new("UIStroke", QuickPasteBtn)
    QuickPasteStroke.Color = Color3.fromRGB(160, 45, 65)
  -- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 4/5)
--   CỤM NÚT VIP · NÚT HƯỚNG DẪN · GIAO DIỆN MODAL GACHA 2 HỘP (50% - 50%)
-- =========================================================================

    -- HÀNG NÚT CHÍNH: LẤY KEY (24 TIẾNG) & KÍCH HOẠT V2
    local ButtonsRow = Instance.new("Frame")
    ButtonsRow.Size = UDim2.new(1, -36, 0, 38)
    ButtonsRow.Position = UDim2.new(0, 18, 0, 184)
    ButtonsRow.BackgroundTransparency = 1
    ButtonsRow.ZIndex = 31
    ButtonsRow.Parent = MainFrame

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0.5, -6, 1, 0)
    GetKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(215, 60, 90)
    GetKeyBtn.Text = Languages[CurrentLang].GetKey
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.TextSize = 11
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.ZIndex = 32
    GetKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 10)
    local GetKeyStroke = Instance.new("UIStroke", GetKeyBtn)
    GetKeyStroke.Color = Color3.fromRGB(240, 95, 125)

    local CheckKeyBtn = Instance.new("TextButton")
    CheckKeyBtn.Size = UDim2.new(0.5, -6, 1, 0)
    CheckKeyBtn.Position = UDim2.new(0.5, 6, 0, 0)
    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(26, 8, 14)
    CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
    CheckKeyBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    CheckKeyBtn.TextSize = 11
    CheckKeyBtn.Font = Enum.Font.GothamBold
    CheckKeyBtn.AutoButtonColor = false
    CheckKeyBtn.ZIndex = 32
    CheckKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 10)
    local CheckStroke = Instance.new("UIStroke", CheckKeyBtn)
    CheckStroke.Color = Color3.fromRGB(180, 50, 75)
    CheckStroke.Thickness = 1.2

    -- NÚT HƯỚNG DẪN CÁCH VƯỢT LINK GETKEY
    local TutorialBtn = Instance.new("TextButton")
    TutorialBtn.Size = UDim2.new(1, -36, 0, 32)
    TutorialBtn.Position = UDim2.new(0, 18, 0, 228)
    TutorialBtn.BackgroundColor3 = Color3.fromRGB(24, 8, 14)
    TutorialBtn.Text = Languages[CurrentLang].Tutorial
    TutorialBtn.TextColor3 = Color3.fromRGB(255, 180, 200)
    TutorialBtn.TextSize = 10.5
    TutorialBtn.Font = Enum.Font.GothamBold
    TutorialBtn.AutoButtonColor = false
    TutorialBtn.ZIndex = 32
    TutorialBtn.Parent = MainFrame
    Instance.new("UICorner", TutorialBtn).CornerRadius = UDim.new(0, 10)
    local TutorialStroke = Instance.new("UIStroke", TutorialBtn)
    TutorialStroke.Color = Color3.fromRGB(145, 45, 65)
    TutorialStroke.Thickness = 1.2

    -- BẢNG THÔNG BÁO LƯU Ý 24 TIẾNG
    local NoticeCard = Instance.new("Frame")
    NoticeCard.Size = UDim2.new(1, -36, 0, 58)
    NoticeCard.Position = UDim2.new(0, 18, 0, 266)
    NoticeCard.BackgroundColor3 = Color3.fromRGB(20, 6, 11)
    NoticeCard.ZIndex = 31
    NoticeCard.Parent = MainFrame
    Instance.new("UICorner", NoticeCard).CornerRadius = UDim.new(0, 10)
    local NoticeStroke = Instance.new("UIStroke", NoticeCard)
    NoticeStroke.Color = Color3.fromRGB(50, 14, 22)

    local NoticeText = Instance.new("TextLabel")
    NoticeText.Size = UDim2.new(1, -16, 1, -8)
    NoticeText.Position = UDim2.new(0, 8, 0, 4)
    NoticeText.BackgroundTransparency = 1
    NoticeText.Text = Languages[CurrentLang].Notice
    NoticeText.TextColor3 = Color3.fromRGB(245, 215, 222)
    NoticeText.TextSize = 10
    NoticeText.Font = Enum.Font.GothamMedium
    NoticeText.TextWrapped = true
    NoticeText.TextYAlignment = Enum.TextYAlignment.Center
    NoticeText.TextXAlignment = Enum.TextXAlignment.Left
    NoticeText.ZIndex = 32
    NoticeText.Parent = NoticeCard

    -- NÚT MINI GAME Ở DƯỚI CÙNG
    local MiniGameBtn = Instance.new("TextButton")
    MiniGameBtn.Size = UDim2.new(1, -36, 0, 38)
    MiniGameBtn.Position = UDim2.new(0, 18, 0, 332)
    MiniGameBtn.BackgroundColor3 = Color3.fromRGB(38, 10, 18)
    MiniGameBtn.Text = CanPlayGachaToday() and Languages[CurrentLang].MiniGame or Languages[CurrentLang].MiniGameLocked
    MiniGameBtn.TextColor3 = CanPlayGachaToday() and Color3.fromRGB(255, 220, 230) or Color3.fromRGB(150, 90, 105)
    MiniGameBtn.TextSize = 11.5
    MiniGameBtn.Font = Enum.Font.GothamBlack
    MiniGameBtn.AutoButtonColor = false
    MiniGameBtn.ZIndex = 32
    MiniGameBtn.Parent = MainFrame
    Instance.new("UICorner", MiniGameBtn).CornerRadius = UDim.new(0, 10)
    local MiniGameStroke = Instance.new("UIStroke", MiniGameBtn)
    MiniGameStroke.Color = CanPlayGachaToday() and Color3.fromRGB(244, 63, 94) or Color3.fromRGB(70, 25, 35)
    MiniGameStroke.Thickness = 1.4

    if CanPlayGachaToday() then
        local mgGlowTween = TweenService:Create(MiniGameStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Color = Color3.fromRGB(255, 140, 170)
        })
        mgGlowTween:Play()
    end

    local StatusMsg = Instance.new("TextLabel")
    StatusMsg.Size = UDim2.new(1, -36, 0, 20)
    StatusMsg.Position = UDim2.new(0, 18, 0, 376)
    StatusMsg.BackgroundTransparency = 1
    StatusMsg.Text = "Chilli Hub V2 X Ronnei · Security Protocol Active"
    StatusMsg.TextColor3 = Color3.fromRGB(145, 80, 95)
    StatusMsg.TextSize = 9.5
    StatusMsg.Font = Enum.Font.GothamMedium
    StatusMsg.ZIndex = 31
    StatusMsg.Parent = MainFrame

    -- MODAL MINI GAME GACHA: 2 HỘP QUÀ VELVET RUBY
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
    GachaHeader.Text = "🎁 VÒNG QUAY MAY MẮN (1 LẦN / NGÀY)"
    GachaHeader.TextColor3 = Color3.fromRGB(255, 190, 205)
    GachaHeader.TextSize = 12
    GachaHeader.Font = Enum.Font.GothamBlack
    GachaHeader.TextXAlignment = Enum.TextXAlignment.Left
    GachaHeader.ZIndex = 46
    GachaHeader.Parent = GachaModal

    local GachaCloseBtn = Instance.new("TextButton")
    GachaCloseBtn.Size = UDim2.new(0, 28, 0, 28)
    GachaCloseBtn.Position = UDim2.new(1, -38, 0, 14)
    GachaCloseBtn.BackgroundColor3 = Color3.fromRGB(28, 8, 14)
    GachaCloseBtn.Text = "✕"
    GachaCloseBtn.TextColor3 = Color3.fromRGB(220, 68, 98)
    GachaCloseBtn.TextSize = 12
    GachaCloseBtn.Font = Enum.Font.GothamBold
    GachaCloseBtn.ZIndex = 46
    GachaCloseBtn.Parent = GachaModal
    Instance.new("UICorner", GachaCloseBtn).CornerRadius = UDim.new(0, 6)

    local GachaSubText = Instance.new("TextLabel")
    GachaSubText.Size = UDim2.new(1, -40, 0, 26)
    GachaSubText.Position = UDim2.new(0, 20, 0, 42)
    GachaSubText.BackgroundTransparency = 1
    GachaSubText.Text = "Chọn 1 trong 2 hộp quà! Mở trúng NoKey sẽ vào thẳng script không cần vượt link!"
    GachaSubText.TextColor3 = Color3.fromRGB(235, 150, 170)
    GachaSubText.TextSize = 10
    GachaSubText.Font = Enum.Font.GothamMedium
    GachaSubText.TextWrapped = true
    GachaSubText.TextXAlignment = Enum.TextXAlignment.Left
    GachaSubText.ZIndex = 46
    GachaSubText.Parent = GachaModal

    local BoxesContainer = Instance.new("Frame")
    BoxesContainer.Size = UDim2.new(1, -36, 0, 210)
    BoxesContainer.Position = UDim2.new(0, 18, 0, 78)
    BoxesContainer.BackgroundTransparency = 1
    BoxesContainer.ZIndex = 46
    BoxesContainer.Parent = GachaModal

    local function CreateMysteryBox(name: string, posX: number, boxTitle: string)
        local BoxCard = Instance.new("TextButton")
        BoxCard.Name = name
        BoxCard.Size = UDim2.new(0.5, -8, 1, 0)
        BoxCard.Position = UDim2.new(0, posX, 0, 0)
        BoxCard.BackgroundColor3 = Color3.fromRGB(22, 7, 13)
        BoxCard.Text = ""
        BoxCard.AutoButtonColor = false
        BoxCard.ZIndex = 47
        BoxCard.Parent = BoxesContainer
        Instance.new("UICorner", BoxCard).CornerRadius = UDim.new(0, 16)
        local BoxStroke = Instance.new("UIStroke", BoxCard)
        BoxStroke.Color = Color3.fromRGB(160, 45, 65)
        BoxStroke.Thickness = 1.4

        -- Tag Tỉ lệ: 50% - 50% ghi rõ trên từng hộp quà
        local Tag5050 = Instance.new("TextLabel")
        Tag5050.Size = UDim2.new(1, -16, 0, 20)
        Tag5050.Position = UDim2.new(0, 8, 0, 10)
        Tag5050.BackgroundColor3 = Color3.fromRGB(36, 10, 18)
        Tag5050.Text = "TỈ LỆ: 50% - 50%"
        Tag5050.TextColor3 = Color3.fromRGB(255, 205, 220)
        Tag5050.TextSize = 9.5
        Tag5050.Font = Enum.Font.GothamBlack
        Tag5050.ZIndex = 48
        Tag5050.Parent = BoxCard
        Instance.new("UICorner", Tag5050).CornerRadius = UDim.new(0, 6)
        local TagStroke = Instance.new("UIStroke", Tag5050)
        TagStroke.Color = Color3.fromRGB(220, 68, 98)
        TagStroke.Thickness = 1

        local GiftIcon = Instance.new("TextLabel")
        GiftIcon.Name = "GiftIcon"
        GiftIcon.Size = UDim2.new(1, 0, 0, 70)
        GiftIcon.Position = UDim2.new(0, 0, 0, 40)
        GiftIcon.BackgroundTransparency = 1
        GiftIcon.Text = "🎁"
        GiftIcon.TextSize = 48
        GiftIcon.ZIndex = 48
        GiftIcon.Parent = BoxCard

        local Title = Instance.new("TextLabel")
        Title.Name = "BoxTitle"
        Title.Size = UDim2.new(1, 0, 0, 20)
        Title.Position = UDim2.new(0, 0, 0, 120)
        Title.BackgroundTransparency = 1
        Title.Text = boxTitle
        Title.TextColor3 = Color3.fromRGB(255, 235, 240)
        Title.TextSize = 12
        Title.Font = Enum.Font.GothamBold
        Title.ZIndex = 48
        Title.Parent = BoxCard

        local ActionHint = Instance.new("TextLabel")
        ActionHint.Name = "ActionHint"
        ActionHint.Size = UDim2.new(1, -20, 0, 24)
        ActionHint.Position = UDim2.new(0, 10, 0, 155)
        ActionHint.BackgroundColor3 = Color3.fromRGB(215, 60, 90)
        ActionHint.Text = "CHỌN HỘP NÀY"
        ActionHint.TextColor3 = Color3.fromRGB(255, 255, 255)
        ActionHint.TextSize = 10
        ActionHint.Font = Enum.Font.GothamBold
        ActionHint.ZIndex = 48
        ActionHint.Parent = BoxCard
        Instance.new("UICorner", ActionHint).CornerRadius = UDim.new(0, 8)

        local floatTween = TweenService:Create(GiftIcon, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Position = UDim2.new(0, 0, 0, 36)
        })
        floatTween:Play()

        return BoxCard, BoxStroke, GiftIcon, Title, ActionHint
    end

    local Box1, Box1Stroke, Box1Icon, Box1Title, Box1Hint = CreateMysteryBox("Box1", 0, "HỘP QUÀ SỐ 1")
    local Box2, Box2Stroke, Box2Icon, Box2Title, Box2Hint = CreateMysteryBox("Box2", 204, "HỘP QUÀ SỐ 2")

    local GachaResultBanner = Instance.new("TextLabel")
    GachaResultBanner.Size = UDim2.new(1, -36, 0, 38)
    GachaResultBanner.Position = UDim2.new(0, 18, 0, 305)
    GachaResultBanner.BackgroundColor3 = Color3.fromRGB(24, 7, 13)
    GachaResultBanner.Text = "Hãy chọn hộp bạn tin là sẽ chứa NoKey hôm nay!"
    GachaResultBanner.TextColor3 = Color3.fromRGB(250, 180, 200)
    GachaResultBanner.TextSize = 10.5
    GachaResultBanner.Font = Enum.Font.GothamMedium
    GachaResultBanner.ZIndex = 46
    GachaResultBanner.Parent = GachaModal
    Instance.new("UICorner", GachaResultBanner).CornerRadius = UDim.new(0, 10)
    local ResultBannerStroke = Instance.new("UIStroke", GachaResultBanner)
    ResultBannerStroke.Color = Color3.fromRGB(60, 18, 28)
  -- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 5/5)
--   LOGIC MỞ HỘP 70% GETKEY - 30% NOKEY · MODAL NGÔN NGỮ · LUỒNG THỜI GIAN
-- =========================================================================

    local isRollingMutex = false

    local function OpenGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
    end

    local function CloseGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
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
            StatusMsg.Text = string.format("⏳ Đã mở hôm nay! Hồi lại sau: %02d giờ %02d phút (00:00 GMT+7)", hoursLeft, minsLeft)
            StatusMsg.TextColor3 = Color3.fromRGB(239, 68, 68)
            return
        end
        OpenGachaModal()
    end)

    -- HÀM MỞ HỘP: BACKEND 70% GETKEY / 30% NOKEY
    local function ExecuteBoxRoll(chosenBox: TextButton, otherBox: TextButton, chosenIcon: TextLabel, chosenTitle: TextLabel, chosenHint: TextLabel)
        if isRollingMutex then return end
        isRollingMutex = true

        SaveGachaPlayed()
        MiniGameBtn.Text = Languages[CurrentLang].MiniGameLocked
        MiniGameBtn.TextColor3 = Color3.fromRGB(150, 90, 105)
        MiniGameStroke.Color = Color3.fromRGB(70, 25, 35)

        TweenService:Create(otherBox, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.6 }):Play()
        otherBox.Active = false

        chosenHint.Text = "ĐANG MỞ..."
        chosenHint.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
        GachaResultBanner.Text = "⏳ Đang hồi hộp bóc seal hộp quà may mắn..."
        GachaResultBanner.TextColor3 = Color3.fromRGB(254, 240, 138)

        task.spawn(function()
            local origPos = chosenBox.Position
            for i = 1, 10 do
                local offset = (i % 2 == 0) and 4 or -4
                chosenBox.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + offset, origPos.Y.Scale, origPos.Y.Offset)
                task.wait(0.06)
            end
            chosenBox.Position = origPos
        end)

        task.wait(0.85)

        -- TÍNH TOÁN RANDOM: 30% NOKEY (<= 30) VÀ 70% GETKEY (> 30)
        local roll = math.random(1, 100)
        local isNoKeyWon = (roll <= 30)

        if isNoKeyWon then
            chosenIcon.Text = "🎉"
            chosenTitle.Text = "TRÚNG NOKEY!"
            chosenTitle.TextColor3 = Color3.fromRGB(74, 222, 128)
            chosenHint.Text = "THÀNH CÔNG!"
            chosenHint.BackgroundColor3 = Color3.fromRGB(22, 101, 52)

            GachaResultBanner.Text = "🎉 CHÚC MỪNG! Bạn mở trúng NOKEY! Tự động chạy script..."
            GachaResultBanner.TextColor3 = Color3.fromRGB(74, 222, 128)

            local secsUntilMidnight = GetSecondsUntilMidnightGMT7()
            Save24hKey(secsUntilMidnight)

            task.wait(1.4)
            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()

            TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.5 }):Play()
            task.wait(0.3)
            ScreenGui:Destroy()
        else
            chosenIcon.Text = "🔑"
            chosenTitle.Text = "TRÚNG GETKEY!"
            chosenTitle.TextColor3 = Color3.fromRGB(244, 63, 94)
            chosenHint.Text = "VỀ LẤY KEY"
            chosenHint.BackgroundColor3 = Color3.fromRGB(180, 50, 75)

            GachaResultBanner.Text = "😢 Bạn mở trúng hộp GETKEY! Vui lòng vượt link để nhận key hôm nay."
            GachaResultBanner.TextColor3 = Color3.fromRGB(244, 63, 94)

            task.wait(1.8)
            CloseGachaModal()
            isRollingMutex = false

            StatusMsg.Text = "📌 Hôm nay chưa may mắn trúng NoKey! Bấm LẤY KEY (24 TIẾNG) để vào Hub."
            StatusMsg.TextColor3 = Color3.fromRGB(245, 195, 210)
        end
    end

    Box1.MouseButton1Click:Connect(function()
        ExecuteBoxRoll(Box1, Box2, Box1Icon, Box1Title, Box1Hint)
    end)

    Box2.MouseButton1Click:Connect(function()
        ExecuteBoxRoll(Box2, Box1, Box2Icon, Box2Title, Box2Hint)
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
                TutorialBtn.BackgroundColor3 = Color3.fromRGB(24, 8, 14)
                TutorialStroke.Color = Color3.fromRGB(145, 45, 65)
                StatusMsg.Text = "Chilli Hub V2 X Ronnei · Security Protocol Active"
                StatusMsg.TextColor3 = Color3.fromRGB(145, 80, 95)
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
                GetKeyBtn.BackgroundColor3 = Color3.fromRGB(215, 60, 90)
                GetKeyStroke.Color = Color3.fromRGB(240, 95, 125)
                StatusMsg.Text = "Chilli Hub V2 X Ronnei · Security Protocol Active"
                StatusMsg.TextColor3 = Color3.fromRGB(145, 80, 95)
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
        local isKeyValid = VerifyChilliV2Key(InputBox.Text)

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

            InputStroke.Color = Color3.fromRGB(220, 68, 98)
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

    -- MODAL CHỌN NGÔN NGỮ
    local LangModal = Instance.new("Frame")
    LangModal.Name = "LangModal"
    LangModal.Size = UDim2.new(1, 0, 1, 0)
    LangModal.Position = UDim2.new(0, 0, 1, 0)
    LangModal.BackgroundColor3 = Color3.fromRGB(12, 4, 7)
    LangModal.BackgroundTransparency = 0.02
    LangModal.ZIndex = 50
    LangModal.Parent = MainFrame
    Instance.new("UICorner", LangModal).CornerRadius = UDim.new(0, 22)

    local ModalTitle = Instance.new("TextLabel")
    ModalTitle.Size = UDim2.new(1, -60, 0, 30)
    ModalTitle.Position = UDim2.new(0, 20, 0, 18)
    ModalTitle.BackgroundTransparency = 1
    ModalTitle.Text = Languages[CurrentLang].SelectLangTitle
    ModalTitle.TextColor3 = Color3.fromRGB(220, 68, 98)
    ModalTitle.TextSize = 12
    ModalTitle.Font = Enum.Font.GothamBold
    ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
    ModalTitle.ZIndex = 51
    ModalTitle.Parent = LangModal

    local CloseModalBtn = Instance.new("TextButton")
    CloseModalBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseModalBtn.Position = UDim2.new(1, -40, 0, 18)
    CloseModalBtn.BackgroundColor3 = Color3.fromRGB(28, 8, 14)
    CloseModalBtn.Text = "✕"
    CloseModalBtn.TextColor3 = Color3.fromRGB(220, 68, 98)
    CloseModalBtn.TextSize = 12
    CloseModalBtn.Font = Enum.Font.GothamBold
    CloseModalBtn.ZIndex = 51
    CloseModalBtn.Parent = LangModal
    Instance.new("UICorner", CloseModalBtn).CornerRadius = UDim.new(0, 6)

    local LangList = Instance.new("Frame")
    LangList.Size = UDim2.new(1, -40, 0, 150)
    LangList.Position = UDim2.new(0, 20, 0, 65)
    LangList.BackgroundTransparency = 1
    LangList.ZIndex = 51
    LangList.Parent = LangModal

    local OptViBtn = Instance.new("TextButton")
    OptViBtn.Size = UDim2.new(1, 0, 0, 56)
    OptViBtn.BackgroundColor3 = Color3.fromRGB(28, 8, 14)
    OptViBtn.Text = "🇻🇳  Tiếng Việt (Vietnamese)  ✓"
    OptViBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
    OptViBtn.TextSize = 13
    OptViBtn.Font = Enum.Font.GothamBold
    OptViBtn.ZIndex = 52
    OptViBtn.AutoButtonColor = false
    OptViBtn.Parent = LangList
    Instance.new("UICorner", OptViBtn).CornerRadius = UDim.new(0, 12)
    local OptViStroke = Instance.new("UIStroke", OptViBtn)
    OptViStroke.Color = Color3.fromRGB(220, 68, 98)
    OptViStroke.Thickness = 1.3

    local OptEnBtn = Instance.new("TextButton")
    OptEnBtn.Size = UDim2.new(1, 0, 0, 56)
    OptEnBtn.Position = UDim2.new(0, 0, 0, 68)
    OptEnBtn.BackgroundColor3 = Color3.fromRGB(18, 5, 9)
    OptEnBtn.Text = "🇺🇸  English (Global)"
    OptEnBtn.TextColor3 = Color3.fromRGB(156, 163, 175)
    OptEnBtn.TextSize = 13
    OptEnBtn.Font = Enum.Font.GothamMedium
    OptEnBtn.ZIndex = 52
    OptEnBtn.AutoButtonColor = false
    OptEnBtn.Parent = LangList
    Instance.new("UICorner", OptEnBtn).CornerRadius = UDim.new(0, 12)
    local OptEnStroke = Instance.new("UIStroke", OptEnBtn)
    OptEnStroke.Color = Color3.fromRGB(50, 14, 22)

    local function SetLanguage(code: string)
        CurrentLang = code
        local data = Languages[code]
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
        ModalTitle.Text = data.SelectLangTitle

        if code == "VI" then
            OptViBtn.Text = "🇻🇳  Tiếng Việt (Vietnamese)  ✓"
            OptViBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
            OptViBtn.Font = Enum.Font.GothamBold
            OptViStroke.Color = Color3.fromRGB(220, 68, 98)
            OptViBtn.BackgroundColor3 = Color3.fromRGB(28, 8, 14)

            OptEnBtn.Text = "🇺🇸  English (Global)"
            OptEnBtn.TextColor3 = Color3.fromRGB(156, 163, 175)
            OptEnBtn.Font = Enum.Font.GothamMedium
            OptEnStroke.Color = Color3.fromRGB(50, 14, 22)
            OptEnBtn.BackgroundColor3 = Color3.fromRGB(18, 5, 9)
        else
            OptEnBtn.Text = "🇺🇸  English (Global)  ✓"
            OptEnBtn.TextColor3 = Color3.fromRGB(245, 195, 210)
            OptEnBtn.Font = Enum.Font.GothamBold
            OptEnStroke.Color = Color3.fromRGB(220, 68, 98)
            OptEnBtn.BackgroundColor3 = Color3.fromRGB(28, 8, 14)

            OptViBtn.Text = "🇻🇳  Tiếng Việt (Vietnamese)"
            OptViBtn.TextColor3 = Color3.fromRGB(156, 163, 175)
            OptViBtn.Font = Enum.Font.GothamMedium
            OptViStroke.Color = Color3.fromRGB(50, 14, 22)
            OptViBtn.BackgroundColor3 = Color3.fromRGB(18, 5, 9)
        end
    end

    local function OpenLangModal()
        TweenService:Create(LangModal, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    end
    local function CloseLangModal()
        TweenService:Create(LangModal, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 1, 0) }):Play()
    end

    OpenLangBtn.MouseButton1Click:Connect(function() PlaySpringButton(OpenLangBtn); OpenLangModal() end)
    CloseModalBtn.MouseButton1Click:Connect(function() PlaySpringButton(CloseModalBtn); CloseLangModal() end)
    OptViBtn.MouseButton1Click:Connect(function() PlaySpringButton(OptViBtn); SetLanguage("VI"); task.wait(0.15); CloseLangModal() end)
    OptEnBtn.MouseButton1Click:Connect(function() PlaySpringButton(OptEnBtn); SetLanguage("EN"); task.wait(0.15); CloseLangModal() end)

    MainFrame.BackgroundTransparency = 1
    MainScale.Scale = 0.4
    TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(MainScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- =========================================================================
--   LUỒNG CHÍNH: DÙNG THỬ 2 PHÚT & BẢO MẬT KHÓA MÀN HÌNH TỰ ĐỘNG
-- =========================================================================

local keyTimeLeft = GetKeyRemainingTime()
if keyTimeLeft and keyTimeLeft > 0 then
    ShowLiveToast("CHILLI HUB V2 X RONNEI (24H)", keyTimeLeft, Color3.fromRGB(220, 68, 98))
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
    ShowLiveToast("⚠️ HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(220, 68, 98))
    OpenKeySystemUI()
    return
else
    ShowLiveToast("CHILLI HUB V2 X RONNEI (2 PHÚT)", remaining, Color3.fromRGB(220, 68, 98))
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
                ShowLiveToast("⚠️ HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(220, 68, 98))
                task.wait(0.3)
                OpenKeySystemUI()
                break
            end
        end
    end)
end
