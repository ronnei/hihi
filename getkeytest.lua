-- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 1/5)
--   CLEAN MINIMALIST UI · CẮT VIỀN HỘP QUÀ · CHU KỲ 00:00 GMT+7
-- =========================================================================

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local KeyUrl = "https://link4m.net/80x8y"
local TutorialUrl = "https://craftvip.github.io/free/getkey.html"
local TargetScriptUrl = "https://raw.githubusercontent.com/robvxs24/freemium/refs/heads/main/chillihubv2.lua"
local GiftBoxAssetId = "rbxassetid://138733048851803"

local KeyFileName = "ChilliV2_KeyData.json"
local TrialFileName = "ChilliV2_TrialData.json"
local GachaFileName = "ChilliV2_GachaData.json"
local TRIAL_DURATION = 120 -- Dùng thử 2 phút (120 giây)

local InitialGuis = {}
local ScriptConnections = {}
local ActiveBlurEffect = nil
local InputBlockerScreen = nil
local OpenKeySystemUI = nil

-- Nạp trước hình ảnh hộp quà vào RAM để hiển thị tức thì
task.spawn(function()
    pcall(function()
        ContentProvider:PreloadAsync({ GiftBoxAssetId })
    end)
end)

-- MODULE MÃ HÓA HEX-XOR BẢO VỆ FILE LƯU
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

-- ĐỒNG BỘ MÚI GIỜ VIỆT NAM GMT+7 (RESET LÚC 00:00)
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

local function VerifyChilliV2Key(rawInput: string): boolean
    if not rawInput or rawInput == "" then return false end
    local clean = string.lower(string.gsub(rawInput, "[%s%c]", ""))
    clean = clean:gsub("^chillihubv2%-", ""):gsub("^chilliv2%-", "")

    local vnTime = os.time() + (7 * 3600)
    for _, t in ipairs({ vnTime, vnTime - 86400, vnTime + 3600 }) do
        local d = os.date("!*t", t)
        local v1 = (d.day * 3617 + d.month * 2851 + d.year * 149) % 65535
        local v2 = (d.day * 6211 + d.month * 4397 + d.year * 269) % 65535
        local v3 = (d.day * 7919 + d.month * 6571 + d.year * 409) % 65535
        if clean == string.format("%04x-%04x-%04x", v1, v2, v3) then
            return true
        end
    end
    return false
end
-- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 2/5)
--   SNAPSHOT UI · KHÓA MÀN HÌNH · THÔNG BÁO TRạng THÁI HIỆN ĐẠI
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
        ActiveBlurEffect.Size = 24
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
        shield.BackgroundColor3 = Color3.fromRGB(8, 9, 12)
        shield.BackgroundTransparency = 0.4
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
    return string.format("%02d:%02d", m, s)
end

local ActiveToastLabel = nil

local function ShowLiveToast(titleText: string, initialSeconds: number, accentColor: Color3)
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
    ToastFrame.Size = UDim2.new(0, 340, 0, 62)
    ToastFrame.Position = UDim2.new(0.5, -170, 0, -80)
    ToastFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
    ToastFrame.BorderSizePixel = 0
    ToastFrame.ZIndex = 50
    ToastFrame.Parent = ToastGui

    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 14)
    local Stroke = Instance.new("UIStroke", ToastFrame)
    Stroke.Thickness = 1.2
    Stroke.Color = accentColor or Color3.fromRGB(225, 29, 72)

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 36, 1, 0)
    Icon.Position = UDim2.new(0, 8, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🌶️"
    Icon.TextSize = 18
    Icon.ZIndex = 51
    Icon.Parent = ToastFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -55, 0, 18)
    Title.Position = UDim2.new(0, 44, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = Color3.fromRGB(248, 250, 252)
    Title.TextSize = 11.5
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 51
    Title.Parent = ToastFrame

    local Msg = Instance.new("TextLabel")
    Msg.Size = UDim2.new(1, -55, 0, 16)
    Msg.Position = UDim2.new(0, 44, 0, 28)
    Msg.BackgroundTransparency = 1
    Msg.Text = "Thời gian dùng thử: " .. FormatTime(initialSeconds)
    Msg.TextColor3 = Color3.fromRGB(148, 163, 184)
    Msg.TextSize = 10.5
    Msg.Font = Enum.Font.GothamMedium
    Msg.TextXAlignment = Enum.TextXAlignment.Left
    Msg.ZIndex = 51
    Msg.Parent = ToastFrame

    ActiveToastLabel = Msg

    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, -24, 0, 2)
    BarBg.Position = UDim2.new(0, 12, 1, -5)
    BarBg.BackgroundColor3 = Color3.fromRGB(30, 34, 45)
    BarBg.BorderSizePixel = 0
    BarBg.ZIndex = 51
    BarBg.Parent = ToastFrame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 1, 0)
    Bar.BackgroundColor3 = accentColor or Color3.fromRGB(225, 29, 72)
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 52
    Bar.Parent = BarBg

    TweenService:Create(ToastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -170, 0, 18) }):Play()
    TweenService:Create(Bar, TweenInfo.new(10, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()

    task.delay(10, function()
        if ToastFrame and ToastFrame.Parent then
            local t = TweenService:Create(ToastFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -170, 0, -80) })
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
--   GIAO DIỆN DARK MATTE HIỆN ĐẠI · DỄ DÀNG SỬ DỤNG · NÚT DÁN NHANH
-- =========================================================================

local Languages = {
    VI = {
        LangBtnText = "🇻🇳 VI",
        SelectLangTitle = "Chọn ngôn ngữ hiển thị",
        Title = "Chilli Hub V2 X Ronnei",
        Subtitle = "chilli hub v2 được tạo bởi ronnei7.htk",
        BadgeGame = "Steal An Egg 🥚 • Key 24 Giờ",
        Placeholder = "Dán mã key của bạn vào đây...",
        QuickPaste = "Dán",
        GetKey = "Lấy Key (24 Giờ)",
        CheckKey = "Kích Hoạt",
        Tutorial = "📖 Hướng dẫn vượt link",
        MiniGame = "🎁 Mở Hộp Quà (50/50)",
        MiniGameLocked = "🔒 Đã mở quà (Reset 00:00)",
        Notice = "Mỗi key có thời hạn sử dụng 24 tiếng. Vượt link chỉ mất khoảng 1 phút.",
        CopiedLink = "Đã sao chép link lấy key vào bộ nhớ tạm!",
        CopiedTutorial = "Đã sao chép link hướng dẫn vào bộ nhớ tạm!",
        Checking = "Đang kiểm tra...",
        CheckingMsg = "Đang xác nhận key...",
        Success = "Key hợp lệ! Đang mở Chilli Hub V2...",
        Error = "Key không đúng hoặc đã hết hạn 24 giờ!"
    },
    EN = {
        LangBtnText = "🇺🇸 EN",
        SelectLangTitle = "Select Display Language",
        Title = "Chilli Hub V2 X Ronnei",
        Subtitle = "chilli hub v2 được tạo bởi ronnei7.htk",
        BadgeGame = "Steal An Egg 🥚 • 24H License",
        Placeholder = "Paste your key here...",
        QuickPaste = "Paste",
        GetKey = "Get Key (24 Hours)",
        CheckKey = "Activate",
        Tutorial = "📖 How to get key",
        MiniGame = "🎁 Mystery Box (50/50)",
        MiniGameLocked = "🔒 Opened (Resets 00:00)",
        Notice = "Each key is valid for 24 hours. Link completion takes about 1 minute.",
        CopiedLink = "Key link copied to clipboard!",
        CopiedTutorial = "Tutorial link copied to clipboard!",
        Checking = "Checking...",
        CheckingMsg = "Checking your key...",
        Success = "Key verified! Loading Chilli Hub V2...",
        Error = "Invalid key or expired 24-hour key!"
    }
}
local CurrentLang = "VI"

local function PlayClickEffect(btn: TextButton)
    local origSize = btn.Size
    local origPos = btn.Position
    local sSize = UDim2.new(origSize.X.Scale, origSize.X.Offset - 4, origSize.Y.Scale, origSize.Y.Offset - 2)
    local sPos = UDim2.new(origPos.X.Scale, origPos.X.Offset + 2, origPos.Y.Scale, origPos.Y.Offset + 1)

    local t1 = TweenService:Create(btn, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = sSize, Position = sPos })
    local t2 = TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = origSize, Position = origPos })
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

    -- Khung chính: Phong cách phẳng lì Dark Matte (#0E1015), gọn gàng và dễ nhìn
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 420, 0, 355)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(14, 16, 21)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 30
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

    local MainScale = Instance.new("UIScale", MainFrame)
    MainScale.Scale = 0.85

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Thickness = 1.2
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = Color3.fromRGB(38, 43, 56)

    -- THANH TIÊU ĐỀ TRÊN CÙNG (HEADER)
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, -32, 0, 46)
    HeaderBar.Position = UDim2.new(0, 16, 0, 12)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.ZIndex = 31
    HeaderBar.Parent = MainFrame

    local BrandIcon = Instance.new("Frame")
    BrandIcon.Size = UDim2.new(0, 38, 0, 38)
    BrandIcon.Position = UDim2.new(0, 0, 0.5, -19)
    BrandIcon.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
    BrandIcon.ZIndex = 32
    BrandIcon.Parent = HeaderBar
    Instance.new("UICorner", BrandIcon).CornerRadius = UDim.new(0, 10)
    local BrandStroke = Instance.new("UIStroke", BrandIcon)
    BrandStroke.Color = Color3.fromRGB(225, 29, 72)
    BrandStroke.Thickness = 1

    local BrandIconTxt = Instance.new("TextLabel")
    BrandIconTxt.Size = UDim2.new(1, 0, 1, 0)
    BrandIconTxt.BackgroundTransparency = 1
    BrandIconTxt.Text = "🌶️"
    BrandIconTxt.TextSize = 18
    BrandIconTxt.ZIndex = 33
    BrandIconTxt.Parent = BrandIcon

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -115, 0, 20)
    TitleLabel.Position = UDim2.new(0, 48, 0, 3)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Languages[CurrentLang].Title
    TitleLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 32
    TitleLabel.Parent = HeaderBar

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Size = UDim2.new(1, -115, 0, 16)
    SubTitleLabel.Position = UDim2.new(0, 48, 0, 23)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = Languages[CurrentLang].Subtitle
    SubTitleLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
    SubTitleLabel.TextSize = 10.5
    SubTitleLabel.Font = Enum.Font.GothamMedium
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.ZIndex = 32
    SubTitleLabel.Parent = HeaderBar

    local OpenLangBtn = Instance.new("TextButton")
    OpenLangBtn.Size = UDim2.new(0, 58, 0, 28)
    OpenLangBtn.Position = UDim2.new(1, -58, 0.5, -14)
    OpenLangBtn.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    OpenLangBtn.Text = Languages[CurrentLang].LangBtnText
    OpenLangBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
    OpenLangBtn.TextSize = 11
    OpenLangBtn.Font = Enum.Font.GothamBold
    OpenLangBtn.AutoButtonColor = false
    OpenLangBtn.ZIndex = 32
    OpenLangBtn.Parent = HeaderBar
    Instance.new("UICorner", OpenLangBtn).CornerRadius = UDim.new(0, 8)
    local LangStroke = Instance.new("UIStroke", OpenLangBtn)
    LangStroke.Color = Color3.fromRGB(45, 52, 68)
    LangStroke.Thickness = 1

    -- ĐƯỜNG KẺ PHÂN CÁCH MẢNH
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -32, 0, 1)
    Divider.Position = UDim2.new(0, 16, 0, 66)
    Divider.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    Divider.BorderSizePixel = 0
    Divider.ZIndex = 31
    Divider.Parent = MainFrame

    -- NHÃN GAME & THỜI HẠN KEY
    local GameBadge = Instance.new("TextLabel")
    GameBadge.Size = UDim2.new(1, -32, 0, 22)
    GameBadge.Position = UDim2.new(0, 16, 0, 76)
    GameBadge.BackgroundTransparency = 1
    GameBadge.Text = Languages[CurrentLang].BadgeGame
    GameBadge.TextColor3 = Color3.fromRGB(244, 63, 94)
    GameBadge.TextSize = 11.5
    GameBadge.Font = Enum.Font.GothamBold
    GameBadge.TextXAlignment = Enum.TextXAlignment.Left
    GameBadge.ZIndex = 31
    GameBadge.Parent = MainFrame

    -- Ô NHẬP KEY + NÚT DÁN NHANH TRỰC QUAN
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -32, 0, 42)
    InputContainer.Position = UDim2.new(0, 16, 0, 102)
    InputContainer.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    InputContainer.ZIndex = 31
    InputContainer.Parent = MainFrame
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 10)
    local InputStroke = Instance.new("UIStroke", InputContainer)
    InputStroke.Color = Color3.fromRGB(42, 48, 62)
    InputStroke.Thickness = 1

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -78, 1, 0)
    InputBox.Position = UDim2.new(0, 12, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.TextColor3 = Color3.fromRGB(248, 250, 252)
    InputBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
    InputBox.PlaceholderText = Languages[CurrentLang].Placeholder
    InputBox.Text = ""
    InputBox.TextSize = 12
    InputBox.Font = Enum.Font.GothamMedium
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.ZIndex = 32
    InputBox.Parent = InputContainer

    local QuickPasteBtn = Instance.new("TextButton")
    QuickPasteBtn.Size = UDim2.new(0, 56, 0, 28)
    QuickPasteBtn.Position = UDim2.new(1, -63, 0.5, -14)
    QuickPasteBtn.BackgroundColor3 = Color3.fromRGB(32, 37, 49)
    QuickPasteBtn.Text = Languages[CurrentLang].QuickPaste
    QuickPasteBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
    QuickPasteBtn.TextSize = 11
    QuickPasteBtn.Font = Enum.Font.GothamBold
    QuickPasteBtn.AutoButtonColor = false
    QuickPasteBtn.ZIndex = 33
    QuickPasteBtn.Parent = InputContainer
    Instance.new("UICorner", QuickPasteBtn).CornerRadius = UDim.new(0, 7)
    -- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 4/5)
--   2 HÀNG NÚT ĐỐI XỨNG DỄ DÙNG · HỘP QUÀ 138733048851803 CẮT VIỀN TRẮNG
-- =========================================================================

    -- HÀNG 1: LẤY KEY (24H) & KÍCH HOẠT
    local PrimaryRow = Instance.new("Frame")
    PrimaryRow.Size = UDim2.new(1, -32, 0, 40)
    PrimaryRow.Position = UDim2.new(0, 16, 0, 154)
    PrimaryRow.BackgroundTransparency = 1
    PrimaryRow.ZIndex = 31
    PrimaryRow.Parent = MainFrame

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0.5, -5, 1, 0)
    GetKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
    GetKeyBtn.Text = Languages[CurrentLang].GetKey
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.TextSize = 12
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.ZIndex = 32
    GetKeyBtn.Parent = PrimaryRow
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 10)

    local CheckKeyBtn = Instance.new("TextButton")
    CheckKeyBtn.Size = UDim2.new(0.5, -5, 1, 0)
    CheckKeyBtn.Position = UDim2.new(0.5, 5, 0, 0)
    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
    CheckKeyBtn.TextColor3 = Color3.fromRGB(248, 250, 252)
    CheckKeyBtn.TextSize = 12
    CheckKeyBtn.Font = Enum.Font.GothamBold
    CheckKeyBtn.AutoButtonColor = false
    CheckKeyBtn.ZIndex = 32
    CheckKeyBtn.Parent = PrimaryRow
    Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 10)
    local CheckStroke = Instance.new("UIStroke", CheckKeyBtn)
    CheckStroke.Color = Color3.fromRGB(55, 65, 81)
    CheckStroke.Thickness = 1

    -- HÀNG 2: HƯỚNG DẪN VƯỢT LINK & MINI GAME HỘP QUÀ (ĐẶT CẠNH NHAU GỌN ĐẸP)
    local SecondaryRow = Instance.new("Frame")
    SecondaryRow.Size = UDim2.new(1, -32, 0, 38)
    SecondaryRow.Position = UDim2.new(0, 16, 0, 202)
    SecondaryRow.BackgroundTransparency = 1
    SecondaryRow.ZIndex = 31
    SecondaryRow.Parent = MainFrame

    local TutorialBtn = Instance.new("TextButton")
    TutorialBtn.Size = UDim2.new(0.5, -5, 1, 0)
    TutorialBtn.Position = UDim2.new(0, 0, 0, 0)
    TutorialBtn.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    TutorialBtn.Text = Languages[CurrentLang].Tutorial
    TutorialBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    TutorialBtn.TextSize = 11
    TutorialBtn.Font = Enum.Font.GothamBold
    TutorialBtn.AutoButtonColor = false
    TutorialBtn.ZIndex = 32
    TutorialBtn.Parent = SecondaryRow
    Instance.new("UICorner", TutorialBtn).CornerRadius = UDim.new(0, 10)
    local TutorialStroke = Instance.new("UIStroke", TutorialBtn)
    TutorialStroke.Color = Color3.fromRGB(38, 43, 56)
    TutorialStroke.Thickness = 1

    local MiniGameBtn = Instance.new("TextButton")
    MiniGameBtn.Size = UDim2.new(0.5, -5, 1, 0)
    MiniGameBtn.Position = UDim2.new(0.5, 5, 0, 0)
    MiniGameBtn.BackgroundColor3 = CanPlayGachaToday() and Color3.fromRGB(32, 16, 28) or Color3.fromRGB(20, 23, 31)
    MiniGameBtn.Text = CanPlayGachaToday() and Languages[CurrentLang].MiniGame or Languages[CurrentLang].MiniGameLocked
    MiniGameBtn.TextColor3 = CanPlayGachaToday() and Color3.fromRGB(251, 113, 133) or Color3.fromRGB(100, 116, 139)
    MiniGameBtn.TextSize = 11
    MiniGameBtn.Font = Enum.Font.GothamBold
    MiniGameBtn.AutoButtonColor = false
    MiniGameBtn.ZIndex = 32
    MiniGameBtn.Parent = SecondaryRow
    Instance.new("UICorner", MiniGameBtn).CornerRadius = UDim.new(0, 10)
    local MiniGameStroke = Instance.new("UIStroke", MiniGameBtn)
    MiniGameStroke.Color = CanPlayGachaToday() and Color3.fromRGB(225, 29, 72) or Color3.fromRGB(38, 43, 56)
    MiniGameStroke.Thickness = 1

    -- KHUNG GHI CHÚ NGẮN GỌN
    local NoticeCard = Instance.new("Frame")
    NoticeCard.Size = UDim2.new(1, -32, 0, 48)
    NoticeCard.Position = UDim2.new(0, 16, 0, 250)
    NoticeCard.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
    NoticeCard.ZIndex = 31
    NoticeCard.Parent = MainFrame
    Instance.new("UICorner", NoticeCard).CornerRadius = UDim.new(0, 10)
    local NoticeStroke = Instance.new("UIStroke", NoticeCard)
    NoticeStroke.Color = Color3.fromRGB(32, 37, 49)
    NoticeStroke.Thickness = 1

    local NoticeText = Instance.new("TextLabel")
    NoticeText.Size = UDim2.new(1, -20, 1, -8)
    NoticeText.Position = UDim2.new(0, 10, 0, 4)
    NoticeText.BackgroundTransparency = 1
    NoticeText.Text = Languages[CurrentLang].Notice
    NoticeText.TextColor3 = Color3.fromRGB(148, 163, 184)
    NoticeText.TextSize = 10.5
    NoticeText.Font = Enum.Font.GothamMedium
    NoticeText.TextWrapped = true
    NoticeText.TextXAlignment = Enum.TextXAlignment.Left
    NoticeText.ZIndex = 32
    NoticeText.Parent = NoticeCard

    -- DÒNG TRẠNG THÁI DƯỚI CÙNG
    local StatusMsg = Instance.new("TextLabel")
    StatusMsg.Size = UDim2.new(1, -32, 0, 20)
    StatusMsg.Position = UDim2.new(0, 16, 0, 312)
    StatusMsg.BackgroundTransparency = 1
    StatusMsg.Text = "Sẵn sàng kết nối • Chilli Hub V2"
    StatusMsg.TextColor3 = Color3.fromRGB(100, 116, 139)
    StatusMsg.TextSize = 10.5
    StatusMsg.Font = Enum.Font.GothamMedium
    StatusMsg.ZIndex = 31
    StatusMsg.Parent = MainFrame

    -- =========================================================================
    --   MODAL HỘP QUÀ MAY MẮN: CĂN CHỈNH LẤY ĐÚNG THÂN HỘP QUÀ (CẮT VIỀN TRẮNG)
    -- =========================================================================
    local GachaModal = Instance.new("Frame")
    GachaModal.Name = "GachaModal"
    GachaModal.Size = UDim2.new(1, 0, 1, 0)
    GachaModal.Position = UDim2.new(0, 0, 1, 0)
    GachaModal.BackgroundColor3 = Color3.fromRGB(14, 16, 21)
    GachaModal.ZIndex = 45
    GachaModal.ClipsDescendants = true
    GachaModal.Parent = MainFrame
    Instance.new("UICorner", GachaModal).CornerRadius = UDim.new(0, 16)

    local GachaHeader = Instance.new("TextLabel")
    GachaHeader.Size = UDim2.new(1, -60, 0, 24)
    GachaHeader.Position = UDim2.new(0, 18, 0, 14)
    GachaHeader.BackgroundTransparency = 1
    GachaHeader.Text = "🎁 HỘP QUÀ MAY MẮN MỖI NGÀY"
    GachaHeader.TextColor3 = Color3.fromRGB(248, 250, 252)
    GachaHeader.TextSize = 13
    GachaHeader.Font = Enum.Font.GothamBold
    GachaHeader.TextXAlignment = Enum.TextXAlignment.Left
    GachaHeader.ZIndex = 46
    GachaHeader.Parent = GachaModal

    local GachaCloseBtn = Instance.new("TextButton")
    GachaCloseBtn.Size = UDim2.new(0, 28, 0, 28)
    GachaCloseBtn.Position = UDim2.new(1, -42, 0, 12)
    GachaCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    GachaCloseBtn.Text = "✕"
    GachaCloseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    GachaCloseBtn.TextSize = 12
    GachaCloseBtn.Font = Enum.Font.GothamBold
    GachaCloseBtn.ZIndex = 46
    GachaCloseBtn.Parent = GachaModal
    Instance.new("UICorner", GachaCloseBtn).CornerRadius = UDim.new(0, 8)

    local GachaSubText = Instance.new("TextLabel")
    GachaSubText.Size = UDim2.new(1, -36, 0, 20)
    GachaSubText.Position = UDim2.new(0, 18, 0, 40)
    GachaSubText.BackgroundTransparency = 1
    GachaSubText.Text = "Chọn 1 hộp bất kỳ. Trúng NoKey sẽ mở thẳng script không cần vượt link!"
    GachaSubText.TextColor3 = Color3.fromRGB(148, 163, 184)
    GachaSubText.TextSize = 10.5
    GachaSubText.Font = Enum.Font.GothamMedium
    GachaSubText.TextXAlignment = Enum.TextXAlignment.Left
    GachaSubText.ZIndex = 46
    GachaSubText.Parent = GachaModal

    local BoxesContainer = Instance.new("Frame")
    BoxesContainer.Size = UDim2.new(1, -36, 0, 215)
    BoxesContainer.Position = UDim2.new(0, 18, 0, 68)
    BoxesContainer.BackgroundTransparency = 1
    BoxesContainer.ZIndex = 46
    BoxesContainer.Parent = GachaModal

    -- HÀM TẠO THẺ HỘP QUÀ: DÙNG MASK CẮT BỎ HOÀN TOÀN VIỀN TRẮNG CỦA STICKER
    local function CreateMysteryBox(name: string, posXScale: number, posXOffset: number, boxTitle: string)
        local BoxCard = Instance.new("TextButton")
        BoxCard.Name = name
        BoxCard.Size = UDim2.new(0.5, -6, 1, 0)
        BoxCard.Position = UDim2.new(posXScale, posXOffset, 0, 0)
        BoxCard.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
        BoxCard.Text = ""
        BoxCard.AutoButtonColor = false
        BoxCard.ZIndex = 47
        BoxCard.Parent = BoxesContainer
        Instance.new("UICorner", BoxCard).CornerRadius = UDim.new(0, 14)
        local BoxStroke = Instance.new("UIStroke", BoxCard)
        BoxStroke.Color = Color3.fromRGB(45, 52, 68)
        BoxStroke.Thickness = 1.2

        -- Nhãn hiển thị 50% - 50% rõ ràng
        local RateTag = Instance.new("TextLabel")
        RateTag.Size = UDim2.new(1, -20, 0, 20)
        RateTag.Position = UDim2.new(0, 10, 0, 10)
        RateTag.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
        RateTag.Text = "TỈ LỆ: 50% - 50%"
        RateTag.TextColor3 = Color3.fromRGB(251, 113, 133)
        RateTag.TextSize = 9.5
        RateTag.Font = Enum.Font.GothamBold
        RateTag.ZIndex = 48
        RateTag.Parent = BoxCard
        Instance.new("UICorner", RateTag).CornerRadius = UDim.new(0, 6)

        -- KHUNG MẶT NẠ CẮT (CROP MASK): CHỈ LẤY HÌNH HỘP QUÀ BÊN TRONG
        local CropMask = Instance.new("Frame")
        CropMask.Name = "CropMask"
        CropMask.AnchorPoint = Vector2.new(0.5, 0)
        CropMask.Size = UDim2.new(0, 96, 0, 96)
        CropMask.Position = UDim2.new(0.5, 0, 0, 38)
        CropMask.BackgroundTransparency = 1 -- Trong suốt hoàn toàn, chỉ dùng để cắt rìa
        CropMask.BorderSizePixel = 0
        CropMask.ClipsDescendants = true
        CropMask.ZIndex = 48
        CropMask.Parent = BoxCard
        Instance.new("UICorner", CropMask).CornerRadius = UDim.new(0, 18)

        -- Phóng đại 1.28x và cân chỉnh tâm để đẩy viền trắng & sao thừa ra khỏi vùng hiển thị
        local GiftImage = Instance.new("ImageLabel")
        GiftImage.Name = "GiftImage"
        GiftImage.AnchorPoint = Vector2.new(0.5, 0.5)
        GiftImage.Size = UDim2.new(1.28, 0, 1.28, 0)
        GiftImage.Position = UDim2.new(0.5, 0, 0.52, 0)
        GiftImage.BackgroundTransparency = 1
        GiftImage.Image = GiftBoxAssetId
        GiftImage.ScaleType = Enum.ScaleType.Crop
        GiftImage.ZIndex = 49
        GiftImage.Parent = CropMask

        local Title = Instance.new("TextLabel")
        Title.Name = "BoxTitle"
        Title.Size = UDim2.new(1, 0, 0, 18)
        Title.Position = UDim2.new(0, 0, 0, 142)
        Title.BackgroundTransparency = 1
        Title.Text = boxTitle
        Title.TextColor3 = Color3.fromRGB(248, 250, 252)
        Title.TextSize = 12
        Title.Font = Enum.Font.GothamBold
        Title.ZIndex = 48
        Title.Parent = BoxCard

        local ActionHint = Instance.new("TextLabel")
        ActionHint.Name = "ActionHint"
        ActionHint.Size = UDim2.new(1, -24, 0, 28)
        ActionHint.Position = UDim2.new(0, 12, 0, 172)
        ActionHint.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
        ActionHint.Text = "MỞ HỘP NÀY"
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
    GachaResultBanner.Size = UDim2.new(1, -36, 0, 36)
    GachaResultBanner.Position = UDim2.new(0, 18, 0, 296)
    GachaResultBanner.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    GachaResultBanner.Text = "Bấm vào 1 trong 2 hộp quà phía trên để thử vận may!"
    GachaResultBanner.TextColor3 = Color3.fromRGB(226, 232, 240)
    GachaResultBanner.TextSize = 11
    GachaResultBanner.Font = Enum.Font.GothamMedium
    GachaResultBanner.ZIndex = 46
    GachaResultBanner.Parent = GachaModal
    Instance.new("UICorner", GachaResultBanner).CornerRadius = UDim.new(0, 10)
    -- =========================================================================
--   🌶️ CHILLI HUB V2 X RONNEI - STEAL AN EGG 🥚 (PHẦN 5/5)
--   XỬ LÝ MỞ HỘP 70/30 · CHUYỂN NGÔN NGỮ · LUỒNG DÙNG THỬ 2 PHÚT
-- =========================================================================

    local isRollingMutex = false

    local function OpenGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
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
        PlayClickEffect(GachaCloseBtn)
        CloseGachaModal()
    end)

    MiniGameBtn.MouseButton1Click:Connect(function()
        PlayClickEffect(MiniGameBtn)
        if not CanPlayGachaToday() then
            local secsLeft = GetSecondsUntilMidnightGMT7()
            local h = math.floor(secsLeft / 3600)
            local m = math.floor((secsLeft % 3600) / 60)
            StatusMsg.Text = string.format("⏳ Đã mở hôm nay! Reset sau %02d giờ %02d phút (00:00)", h, m)
            StatusMsg.TextColor3 = Color3.fromRGB(244, 63, 94)
            return
        end
        OpenGachaModal()
    end)

    -- HÀM MỞ HỘP QUÀ: HIỂN THỊ 50/50 NHƯNG TỈ LỆ THỰC 30% NOKEY - 70% GETKEY
    local function ExecuteBoxRoll(chosenBox: TextButton, otherBox: TextButton, chosenStroke: UIStroke, chosenMask: Frame, chosenTitle: TextLabel, chosenHint: TextLabel)
        if isRollingMutex then return end
        isRollingMutex = true

        -- Lưu trạng thái đã mở ngay lập tức chống thoát game mở lại
        SaveGachaPlayed()
        MiniGameBtn.Text = Languages[CurrentLang].MiniGameLocked
        MiniGameBtn.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
        MiniGameBtn.TextColor3 = Color3.fromRGB(100, 116, 139)
        MiniGameStroke.Color = Color3.fromRGB(38, 43, 56)

        TweenService:Create(otherBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.65 }):Play()
        otherBox.Active = false

        chosenStroke.Color = Color3.fromRGB(245, 158, 11)
        chosenHint.Text = "ĐANG MỞ..."
        chosenHint.BackgroundColor3 = Color3.fromRGB(217, 119, 6)
        GachaResultBanner.Text = "⏳ Đang mở hộp quà của bạn..."
        GachaResultBanner.TextColor3 = Color3.fromRGB(253, 224, 71)

        -- Hiệu ứng lắc hộp quà mượt mà
        for i = 1, 8 do
            local angle = (i % 2 == 0) and 6 or -6
            TweenService:Create(chosenMask, TweenInfo.new(0.06, Enum.EasingStyle.Quad), { Rotation = angle }):Play()
            task.wait(0.065)
        end
        TweenService:Create(chosenMask, TweenInfo.new(0.08, Enum.EasingStyle.Back), { Rotation = 0 }):Play()
        task.wait(0.25)

        -- TỈ LỆ THỰC TẾ: 30% NOKEY (<= 30) | 70% GETKEY (> 30)
        local roll = math.random(1, 100)
        local isNoKeyWon = (roll <= 30)

        if isNoKeyWon then
            chosenStroke.Color = Color3.fromRGB(34, 197, 94)
            chosenTitle.Text = "🎉 TRÚNG NOKEY!"
            chosenTitle.TextColor3 = Color3.fromRGB(74, 222, 128)
            chosenHint.Text = "VÀO SCRIPT NGAY"
            chosenHint.BackgroundColor3 = Color3.fromRGB(22, 163, 74)

            GachaResultBanner.Text = "🎉 Chúc mừng! Bạn mở trúng NoKey! Đang tải script..."
            GachaResultBanner.TextColor3 = Color3.fromRGB(74, 222, 128)

            Save24hKey(GetSecondsUntilMidnightGMT7())

            task.wait(1.2)
            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()

            TweenService:Create(MainScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.6 }):Play()
            task.wait(0.22)
            ScreenGui:Destroy()
        else
            chosenStroke.Color = Color3.fromRGB(225, 29, 72)
            chosenTitle.Text = "🔑 TRÚNG GETKEY"
            chosenTitle.TextColor3 = Color3.fromRGB(251, 113, 133)
            chosenHint.Text = "QUAY VỀ LẤY KEY"
            chosenHint.BackgroundColor3 = Color3.fromRGB(159, 18, 57)

            GachaResultBanner.Text = "Hộp này là GetKey! Đang đưa bạn về màn hình lấy key..."
            GachaResultBanner.TextColor3 = Color3.fromRGB(251, 113, 133)

            task.wait(1.5)
            CloseGachaModal()
            isRollingMutex = false

            StatusMsg.Text = "📌 Mở trúng GetKey! Bấm 'Lấy Key (24 Giờ)' để nhận mã."
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
        PlayClickEffect(QuickPasteBtn)
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
        PlayClickEffect(TutorialBtn)

        if setclipboard then setclipboard(TutorialUrl) elseif toclipboard then toclipboard(TutorialUrl) end

        TutorialBtn.Text = "✔ Đã chép link HD"
        TutorialBtn.TextColor3 = Color3.fromRGB(52, 211, 153)
        StatusMsg.Text = Languages[CurrentLang].CopiedTutorial
        StatusMsg.TextColor3 = Color3.fromRGB(52, 211, 153)

        task.delay(2.2, function()
            if TutorialBtn and TutorialBtn.Parent then
                TutorialBtn.Text = Languages[CurrentLang].Tutorial
                TutorialBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
                StatusMsg.Text = "Sẵn sàng kết nối • Chilli Hub V2"
                StatusMsg.TextColor3 = Color3.fromRGB(100, 116, 139)
            end
            isTutorialDebounce = false
        end)
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        PlayClickEffect(GetKeyBtn)
        if setclipboard then setclipboard(KeyUrl) elseif toclipboard then toclipboard(KeyUrl) end

        GetKeyBtn.Text = "✔ Đã Sao Chép Link!"
        GetKeyBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        StatusMsg.Text = Languages[CurrentLang].CopiedLink
        StatusMsg.TextColor3 = Color3.fromRGB(52, 211, 153)

        task.delay(2.2, function()
            if GetKeyBtn and GetKeyBtn.Parent then
                GetKeyBtn.Text = Languages[CurrentLang].GetKey
                GetKeyBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
                StatusMsg.Text = "Sẵn sàng kết nối • Chilli Hub V2"
                StatusMsg.TextColor3 = Color3.fromRGB(100, 116, 139)
            end
        end)
    end)

    local isChecking = false
    CheckKeyBtn.MouseButton1Click:Connect(function()
        if isChecking then return end
        isChecking = true
        PlayClickEffect(CheckKeyBtn)

        CheckKeyBtn.Text = Languages[CurrentLang].Checking
        StatusMsg.Text = Languages[CurrentLang].CheckingMsg
        StatusMsg.TextColor3 = Color3.fromRGB(226, 232, 240)

        task.wait(0.3)
        local isKeyValid = VerifyChilliV2Key(InputBox.Text)

        if isKeyValid then
            Save24hKey()
            CheckKeyBtn.Text = "✔ Thành Công"
            CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
            StatusMsg.Text = Languages[CurrentLang].Success
            StatusMsg.TextColor3 = Color3.fromRGB(74, 222, 128)

            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()

            task.wait(0.35)
            TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.6 }):Play()
            task.wait(0.2)
            ScreenGui:Destroy()
        else
            isChecking = false
            CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
            StatusMsg.Text = Languages[CurrentLang].Error
            StatusMsg.TextColor3 = Color3.fromRGB(244, 63, 94)

            InputStroke.Color = Color3.fromRGB(225, 29, 72)
            local origOffset = MainFrame.Position.X.Offset
            for _, off in ipairs({ -5, 5, -3, 3, 0 }) do
                TweenService:Create(MainFrame, TweenInfo.new(0.04, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(0.5, off, 0.5, 0)
                }):Play()
                task.wait(0.045)
            end
            MainFrame.Position = UDim2.new(0.5, origOffset, 0.5, 0)
            task.wait(0.5)
            InputStroke.Color = Color3.fromRGB(42, 48, 62)
        end
    end)

    -- ĐỔI NGÔN NGỮ NHANH TRỰC TIẾP KHI BẤM NÚT (KHÔNG CẦN MỞ POPUP RườM RÀ)
    OpenLangBtn.MouseButton1Click:Connect(function()
        PlayClickEffect(OpenLangBtn)
        CurrentLang = (CurrentLang == "VI") and "EN" or "VI"
        local data = Languages[CurrentLang]
        OpenLangBtn.Text = data.LangBtnText
        TitleLabel.Text = data.Title
        SubTitleLabel.Text = data.Subtitle
        GameBadge.Text = data.BadgeGame
        InputBox.PlaceholderText = data.Placeholder
        QuickPasteBtn.Text = data.QuickPaste
        GetKeyBtn.Text = data.GetKey
        CheckKeyBtn.Text = data.CheckKey
        TutorialBtn.Text = data.Tutorial
        MiniGameBtn.Text = CanPlayGachaToday() and data.MiniGame or data.MiniGameLocked
        NoticeText.Text = data.Notice
    end)

    MainFrame.BackgroundTransparency = 1
    MainScale.Scale = 0.85
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- =========================================================================
--   LUỒNG CHÍNH: DÙNG THỬ 2 PHÚT & BẢO MẬT KHÓA MÀN HÌNH TỰ ĐỘNG
-- =========================================================================

local keyTimeLeft = GetKeyRemainingTime()
if keyTimeLeft and keyTimeLeft > 0 then
    ShowLiveToast("CHILLI HUB V2 (24H)", keyTimeLeft, Color3.fromRGB(225, 29, 72))
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
    ShowLiveToast("PHÁT HIỆN CHỈNH GIỜ THIẾT BỊ", 0, Color3.fromRGB(239, 68, 68))
    OpenKeySystemUI()
    return
end

local targetEndTime = trialData.StartTime + TRIAL_DURATION
local remaining = targetEndTime - os.time()

if remaining <= 0 then
    ApplyScreenLockdown()
    ShowLiveToast("HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(225, 29, 72))
    OpenKeySystemUI()
    return
else
    ShowLiveToast("CHILLI HUB V2 (DÙNG THỬ 2 PHÚT)", remaining, Color3.fromRGB(225, 29, 72))
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
                ShowLiveToast("HẾT THỜI GIAN DÙNG THỬ (2 PHÚT)", 0, Color3.fromRGB(225, 29, 72))
                task.wait(0.25)
                OpenKeySystemUI()
                break
            end
        end
    end)
end
