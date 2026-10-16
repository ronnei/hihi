-- =========================================================================
--   CHILLI HUB V2 X RONNEI - STEAL AN EGG (PHẦN 1/5)
--   CARBON MATTE UI · CROP HỘP QUÀ CHUẨN · CHU KỲ 00:00 GMT+7
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

-- Sử dụng rbxthumb để tự động phân giải cả Decal ID lẫn Image ID
local GiftBoxTexture = "rbxthumb://type=Asset&id=138733048851803&w=420&h=420"

local KeyFileName = "ChilliV2_KeyData.json"
local TrialFileName = "ChilliV2_TrialData.json"
local GachaFileName = "ChilliV2_GachaData.json"
local TRIAL_DURATION = 120 -- Dùng thử 2 phút (120 giây)

local InitialGuis = {}
local ScriptConnections = {}
local ActiveBlurEffect = nil
local InputBlockerScreen = nil
local OpenKeySystemUI = nil

task.spawn(function()
    pcall(function()
        ContentProvider:PreloadAsync({ GiftBoxTexture })
    end)
end)

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
    local dateTable = os.date("!*t", vnTime)
    return string.format("%04d-%02d-%02d", dateTable.year, dateTable.month, dateTable.day)
end

local function GetSecondsUntilMidnightGMT7(): number
    local vnTime = os.time() + (7 * 3600)
    local dateTable = os.date("!*t", vnTime)
    local currentDaySeconds = (dateTable.hour * 3600) + (dateTable.min * 60) + dateTable.sec
    return 86400 - currentDaySeconds
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
--   CHILLI HUB V2 X RONNEI - STEAL AN EGG (PHẦN 2/5)
--   SNAPSHOT HỆ THỐNG · KHÓA MÀN HÌNH · THANH TRẠNG THÁI FLUENT STYLE
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
        shield.Position = UDim2.new(0, 0, 0, 0)
        shield.BackgroundColor3 = Color3.fromRGB(8, 8, 11)
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
    ToastFrame.Size = UDim2.new(0, 320, 0, 58)
    ToastFrame.Position = UDim2.new(0.5, -160, 0, -80)
    ToastFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    ToastFrame.BorderSizePixel = 0
    ToastFrame.ZIndex = 50
    ToastFrame.Parent = ToastGui

    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 10)
    local Stroke = Instance.new("UIStroke", ToastFrame)
    Stroke.Thickness = 1
    Stroke.Color = Color3.fromRGB(38, 38, 48)

    local SideBar = Instance.new("Frame")
    SideBar.Size = UDim2.new(0, 3, 1, -16)
    SideBar.Position = UDim2.new(0, 8, 0, 8)
    SideBar.BackgroundColor3 = accentColor or Color3.fromRGB(225, 29, 72)
    SideBar.BorderSizePixel = 0
    SideBar.ZIndex = 51
    SideBar.Parent = ToastFrame
    Instance.new("UICorner", SideBar).CornerRadius = UDim.new(1, 0)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -30, 0, 18)
    Title.Position = UDim2.new(0, 20, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = Color3.fromRGB(244, 244, 246)
    Title.TextSize = 11.5
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 51
    Title.Parent = ToastFrame

    local Msg = Instance.new("TextLabel")
    Msg.Size = UDim2.new(1, -30, 0, 16)
    Msg.Position = UDim2.new(0, 20, 0, 29)
    Msg.BackgroundTransparency = 1
    Msg.Text = "Time remaining: " .. FormatTime(initialSeconds)
    Msg.TextColor3 = Color3.fromRGB(161, 161, 170)
    Msg.TextSize = 10.5
    Msg.Font = Enum.Font.GothamMedium
    Msg.TextXAlignment = Enum.TextXAlignment.Left
    Msg.ZIndex = 51
    Msg.Parent = ToastFrame

    ActiveToastLabel = Msg

    TweenService:Create(ToastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -160, 0, 18) }):Play()

    task.delay(10, function()
        if ToastFrame and ToastFrame.Parent then
            local t = TweenService:Create(ToastFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -160, 0, -80) })
            t:Play()
            t.Completed:Connect(function()
                if ToastGui and ToastGui.Parent then ToastGui:Destroy() end
                ActiveToastLabel = nil
            end)
        end
    end)
end
-- =========================================================================
--   CHILLI HUB V2 X RONNEI - STEAL AN EGG (PHẦN 3/5)
--   THIẾT KẾ CARBON MATTE SLATE · LOẠI BỎ HOÀN TOÀN PHONG CÁCH MÀU MÈ AI
-- =========================================================================

local Languages = {
    VI = {
        LangBtnText = "VN",
        Title = "Chilli Hub V2 X Ronnei",
        Subtitle = "chilli hub v2 được tạo bởi ronnei7.htk",
        GameTag = "Steal An Egg 🥚",
        LicenseBadge = "24H KEY",
        InputLabel = "MÃ KÍCH HOẠT (LICENSE KEY)",
        Placeholder = "Nhập mã key chillihubv2-...",
        QuickPaste = "Dán",
        GetKey = "Lấy Key (24 Tiếng)",
        CheckKey = "Kích Hoạt Script",
        Tutorial = "Hướng dẫn vượt link lấy key",
        MiniGame = "Mini Game: GetKey or NoKey",
        MiniGameLocked = "Mini Game: Đã mở hôm nay (Reset 00:00)",
        Notice = "Key có thời hạn 24 tiếng kể từ lúc kích hoạt. Vượt link chỉ mất khoảng 1 phút.",
        CopiedLink = "Đã sao chép link lấy key 24 tiếng vào bộ nhớ tạm.",
        CopiedTutorial = "Đã sao chép link hướng dẫn vào bộ nhớ tạm.",
        Checking = "Đang kiểm tra...",
        CheckingMsg = "Đang xác thực mã key...",
        Success = "Xác thực thành công. Đang mở Chilli Hub V2...",
        Error = "Mã key không đúng hoặc đã hết hạn."
    },
    EN = {
        LangBtnText = "EN",
        Title = "Chilli Hub V2 X Ronnei",
        Subtitle = "chilli hub v2 được tạo bởi ronnei7.htk",
        GameTag = "Steal An Egg 🥚",
        LicenseBadge = "24H KEY",
        InputLabel = "LICENSE KEY",
        Placeholder = "Enter chillihubv2-... key",
        QuickPaste = "Paste",
        GetKey = "Get Key (24 Hours)",
        CheckKey = "Verify & Launch",
        Tutorial = "How to get key (Tutorial)",
        MiniGame = "Mini Game: GetKey or NoKey",
        MiniGameLocked = "Mini Game: Opened today (Resets 00:00)",
        Notice = "Each key is valid for 24 hours after activation. Link bypass takes ~1 min.",
        CopiedLink = "24-hour key link copied to clipboard.",
        CopiedTutorial = "Tutorial link copied to clipboard.",
        Checking = "Verifying...",
        CheckingMsg = "Checking license key...",
        Success = "Key valid. Launching Chilli Hub V2...",
        Error = "Invalid or expired license key."
    }
}
local CurrentLang = "VI"

local function PlayButtonPress(btn: GuiButton)
    local origSize = btn.Size
    local origPos = btn.Position
    local t1 = TweenService:Create(btn, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(origSize.X.Scale, origSize.X.Offset - 2, origSize.Y.Scale, origSize.Y.Offset - 2),
        Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + 1, origPos.Y.Scale, origPos.Y.Offset + 1)
    })
    local t2 = TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = origSize,
        Position = origPos
    })
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

    -- Khung chính Carbon Matte chuẩn UI hiện đại (420 x 365)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 420, 0, 365)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 30
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    local MainScale = Instance.new("UIScale", MainFrame)
    MainScale.Scale = 0.92

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Thickness = 1
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = Color3.fromRGB(38, 38, 48)

    -- HEADER BAR (Căn trái chuẩn Fluent UI)
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, 0, 0, 54)
    HeaderBar.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    HeaderBar.BorderSizePixel = 0
    HeaderBar.ZIndex = 31
    HeaderBar.Parent = MainFrame
    Instance.new("UICorner", HeaderBar).CornerRadius = UDim.new(0, 12)

    -- Che bo góc dưới của HeaderBar
    local HeaderPatch = Instance.new("Frame")
    HeaderPatch.Size = UDim2.new(1, 0, 0, 10)
    HeaderPatch.Position = UDim2.new(0, 0, 1, -10)
    HeaderPatch.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    HeaderPatch.BorderSizePixel = 0
    HeaderPatch.ZIndex = 31
    HeaderPatch.Parent = HeaderBar

    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.Position = UDim2.new(0, 0, 1, 0)
    Divider.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
    Divider.BorderSizePixel = 0
    Divider.ZIndex = 32
    Divider.Parent = HeaderBar

    -- Chấm đỏ nhận diện thương hiệu
    local AccentDot = Instance.new("Frame")
    AccentDot.Size = UDim2.new(0, 8, 0, 8)
    AccentDot.Position = UDim2.new(0, 18, 0, 16)
    AccentDot.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
    AccentDot.BorderSizePixel = 0
    AccentDot.ZIndex = 32
    AccentDot.Parent = HeaderBar
    Instance.new("UICorner", AccentDot).CornerRadius = UDim.new(1, 0)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -160, 0, 18)
    TitleLabel.Position = UDim2.new(0, 32, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Languages[CurrentLang].Title
    TitleLabel.TextColor3 = Color3.fromRGB(244, 244, 246)
    TitleLabel.TextSize = 13.5
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 32
    TitleLabel.Parent = HeaderBar

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Size = UDim2.new(1, -160, 0, 15)
    SubTitleLabel.Position = UDim2.new(0, 32, 0, 29)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = Languages[CurrentLang].Subtitle
    SubTitleLabel.TextColor3 = Color3.fromRGB(130, 130, 142)
    SubTitleLabel.TextSize = 10.5
    SubTitleLabel.Font = Enum.Font.GothamMedium
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.ZIndex = 32
    SubTitleLabel.Parent = HeaderBar

    -- Badge Game & Ngôn ngữ bên phải Header
    local GamePill = Instance.new("TextLabel")
    GamePill.Size = UDim2.new(0, 96, 0, 24)
    GamePill.Position = UDim2.new(1, -148, 0.5, -12)
    GamePill.BackgroundColor3 = Color3.fromRGB(24, 24, 31)
    GamePill.Text = Languages[CurrentLang].GameTag
    GamePill.TextColor3 = Color3.fromRGB(200, 200, 210)
    GamePill.TextSize = 10
    GamePill.Font = Enum.Font.GothamMedium
    GamePill.ZIndex = 32
    GamePill.Parent = HeaderBar
    Instance.new("UICorner", GamePill).CornerRadius = UDim.new(0, 6)
    local GamePillStroke = Instance.new("UIStroke", GamePill)
    GamePillStroke.Color = Color3.fromRGB(38, 38, 48)

    local LangToggleBtn = Instance.new("TextButton")
    LangToggleBtn.Size = UDim2.new(0, 34, 0, 24)
    LangToggleBtn.Position = UDim2.new(1, -46, 0.5, -12)
    LangToggleBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 31)
    LangToggleBtn.Text = Languages[CurrentLang].LangBtnText
    LangToggleBtn.TextColor3 = Color3.fromRGB(244, 244, 246)
    LangToggleBtn.TextSize = 10.5
    LangToggleBtn.Font = Enum.Font.GothamBold
    LangToggleBtn.AutoButtonColor = false
    LangToggleBtn.ZIndex = 32
    LangToggleBtn.Parent = HeaderBar
    Instance.new("UICorner", LangToggleBtn).CornerRadius = UDim.new(0, 6)
    local LangStroke = Instance.new("UIStroke", LangToggleBtn)
    LangStroke.Color = Color3.fromRGB(38, 38, 48)

    -- NHÃN Ô NHẬP KEY
    local InputHeaderLabel = Instance.new("TextLabel")
    InputHeaderLabel.Size = UDim2.new(1, -36, 0, 16)
    InputHeaderLabel.Position = UDim2.new(0, 18, 0, 68)
    InputHeaderLabel.BackgroundTransparency = 1
    InputHeaderLabel.Text = Languages[CurrentLang].InputLabel
    InputHeaderLabel.TextColor3 = Color3.fromRGB(145, 145, 158)
    InputHeaderLabel.TextSize = 10
    InputHeaderLabel.Font = Enum.Font.GothamBold
    InputHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
    InputHeaderLabel.ZIndex = 31
    InputHeaderLabel.Parent = MainFrame

    -- KHUNG NHẬP KEY & NÚT DÁN
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -36, 0, 38)
    InputContainer.Position = UDim2.new(0, 18, 0, 88)
    InputContainer.BackgroundColor3 = Color3.fromRGB(19, 19, 25)
    InputContainer.ZIndex = 31
    InputContainer.Parent = MainFrame
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 8)
    local InputStroke = Instance.new("UIStroke", InputContainer)
    InputStroke.Color = Color3.fromRGB(38, 38, 48)
    InputStroke.Thickness = 1

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -72, 1, 0)
    InputBox.Position = UDim2.new(0, 12, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.TextColor3 = Color3.fromRGB(244, 244, 246)
    InputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 112)
    InputBox.PlaceholderText = Languages[CurrentLang].Placeholder
    InputBox.Text = ""
    InputBox.TextSize = 11.5
    InputBox.Font = Enum.Font.GothamMedium
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.ZIndex = 32
    InputBox.Parent = InputContainer

    InputBox.Focused:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(225, 29, 72) }):Play()
    end)
    InputBox.FocusLost:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(38, 38, 48) }):Play()
    end)

    local QuickPasteBtn = Instance.new("TextButton")
    QuickPasteBtn.Size = UDim2.new(0, 50, 0, 26)
    QuickPasteBtn.Position = UDim2.new(1, -56, 0.5, -13)
    QuickPasteBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    QuickPasteBtn.Text = Languages[CurrentLang].QuickPaste
    QuickPasteBtn.TextColor3 = Color3.fromRGB(210, 210, 220)
    QuickPasteBtn.TextSize = 10.5
    QuickPasteBtn.Font = Enum.Font.GothamBold
    QuickPasteBtn.AutoButtonColor = false
    QuickPasteBtn.ZIndex = 33
    QuickPasteBtn.Parent = InputContainer
    Instance.new("UICorner", QuickPasteBtn).CornerRadius = UDim.new(0, 6)
    -- =========================================================================
--   CHILLI HUB V2 X RONNEI - STEAL AN EGG (PHẦN 4/5)
--   CỤM NÚT CHÍNH · CẮT BỎ 100% VIỀN TRẮNG HÌNH HỘP QUÀ 138733048851803
-- =========================================================================

    -- HÀNG NÚT CHÍNH: LẤY KEY (24 TIẾNG) & KÍCH HOẠT
    local ButtonsRow = Instance.new("Frame")
    ButtonsRow.Size = UDim2.new(1, -36, 0, 38)
    ButtonsRow.Position = UDim2.new(0, 18, 0, 136)
    ButtonsRow.BackgroundTransparency = 1
    ButtonsRow.ZIndex = 31
    ButtonsRow.Parent = MainFrame

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0.5, -5, 1, 0)
    GetKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
    GetKeyBtn.Text = Languages[CurrentLang].GetKey
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.TextSize = 11.5
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.ZIndex = 32
    GetKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 8)

    local CheckKeyBtn = Instance.new("TextButton")
    CheckKeyBtn.Size = UDim2.new(0.5, -5, 1, 0)
    CheckKeyBtn.Position = UDim2.new(0.5, 5, 0, 0)
    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
    CheckKeyBtn.TextColor3 = Color3.fromRGB(244, 244, 246)
    CheckKeyBtn.TextSize = 11.5
    CheckKeyBtn.Font = Enum.Font.GothamBold
    CheckKeyBtn.AutoButtonColor = false
    CheckKeyBtn.ZIndex = 32
    CheckKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 8)
    local CheckStroke = Instance.new("UIStroke", CheckKeyBtn)
    CheckStroke.Color = Color3.fromRGB(45, 45, 58)
    CheckStroke.Thickness = 1

    -- NÚT HƯỚNG DẪN VƯỢT LINK
    local TutorialBtn = Instance.new("TextButton")
    TutorialBtn.Size = UDim2.new(1, -36, 0, 32)
    TutorialBtn.Position = UDim2.new(0, 18, 0, 182)
    TutorialBtn.BackgroundColor3 = Color3.fromRGB(19, 19, 25)
    TutorialBtn.Text = Languages[CurrentLang].Tutorial
    TutorialBtn.TextColor3 = Color3.fromRGB(185, 185, 198)
    TutorialBtn.TextSize = 11
    TutorialBtn.Font = Enum.Font.GothamMedium
    TutorialBtn.AutoButtonColor = false
    TutorialBtn.ZIndex = 32
    TutorialBtn.Parent = MainFrame
    Instance.new("UICorner", TutorialBtn).CornerRadius = UDim.new(0, 8)
    local TutorialStroke = Instance.new("UIStroke", TutorialBtn)
    TutorialStroke.Color = Color3.fromRGB(34, 34, 44)
    TutorialStroke.Thickness = 1

    -- THẺ THÔNG TIN LƯU Ý
    local NoticeCard = Instance.new("Frame")
    NoticeCard.Size = UDim2.new(1, -36, 0, 48)
    NoticeCard.Position = UDim2.new(0, 18, 0, 222)
    NoticeCard.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    NoticeCard.ZIndex = 31
    NoticeCard.Parent = MainFrame
    Instance.new("UICorner", NoticeCard).CornerRadius = UDim.new(0, 8)
    local NoticeStroke = Instance.new("UIStroke", NoticeCard)
    NoticeStroke.Color = Color3.fromRGB(30, 30, 38)

    local NoticeText = Instance.new("TextLabel")
    NoticeText.Size = UDim2.new(1, -20, 1, -8)
    NoticeText.Position = UDim2.new(0, 10, 0, 4)
    NoticeText.BackgroundTransparency = 1
    NoticeText.Text = Languages[CurrentLang].Notice
    NoticeText.TextColor3 = Color3.fromRGB(145, 145, 158)
    NoticeText.TextSize = 10
    NoticeText.Font = Enum.Font.GothamMedium
    NoticeText.TextWrapped = true
    NoticeText.TextXAlignment = Enum.TextXAlignment.Left
    NoticeText.ZIndex = 32
    NoticeText.Parent = NoticeCard

    -- NÚT MINI GAME DƯỚI CÙNG
    local MiniGameBtn = Instance.new("TextButton")
    MiniGameBtn.Size = UDim2.new(1, -36, 0, 36)
    MiniGameBtn.Position = UDim2.new(0, 18, 0, 278)
    MiniGameBtn.BackgroundColor3 = Color3.fromRGB(24, 18, 24)
    MiniGameBtn.Text = CanPlayGachaToday() and Languages[CurrentLang].MiniGame or Languages[CurrentLang].MiniGameLocked
    MiniGameBtn.TextColor3 = CanPlayGachaToday() and Color3.fromRGB(244, 244, 246) or Color3.fromRGB(115, 115, 128)
    MiniGameBtn.TextSize = 11
    MiniGameBtn.Font = Enum.Font.GothamBold
    MiniGameBtn.AutoButtonColor = false
    MiniGameBtn.ZIndex = 32
    MiniGameBtn.Parent = MainFrame
    Instance.new("UICorner", MiniGameBtn).CornerRadius = UDim.new(0, 8)
    local MiniGameStroke = Instance.new("UIStroke", MiniGameBtn)
    MiniGameStroke.Color = CanPlayGachaToday() and Color3.fromRGB(225, 29, 72) or Color3.fromRGB(38, 38, 48)
    MiniGameStroke.Thickness = 1

    local StatusMsg = Instance.new("TextLabel")
    StatusMsg.Size = UDim2.new(1, -36, 0, 18)
    StatusMsg.Position = UDim2.new(0, 18, 0, 322)
    StatusMsg.BackgroundTransparency = 1
    StatusMsg.Text = "Ready • 24-Hour Key System"
    StatusMsg.TextColor3 = Color3.fromRGB(110, 110, 122)
    StatusMsg.TextSize = 10
    StatusMsg.Font = Enum.Font.GothamMedium
    StatusMsg.TextXAlignment = Enum.TextXAlignment.Left
    StatusMsg.ZIndex = 31
    StatusMsg.Parent = MainFrame

    -- =========================================================================
    --   MODAL MINI GAME: CẮT VIỀN TRẮNG TUYỆT ĐỐI CHO ASSET 138733048851803
    -- =========================================================================
    local GachaModal = Instance.new("Frame")
    GachaModal.Name = "GachaModal"
    GachaModal.Size = UDim2.new(1, 0, 1, 0)
    GachaModal.Position = UDim2.new(0, 0, 1, 0)
    GachaModal.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
    GachaModal.BorderSizePixel = 0
    GachaModal.ZIndex = 45
    GachaModal.ClipsDescendants = true
    GachaModal.Parent = MainFrame
    Instance.new("UICorner", GachaModal).CornerRadius = UDim.new(0, 12)

    local GachaTopBar = Instance.new("Frame")
    GachaTopBar.Size = UDim2.new(1, 0, 0, 48)
    GachaTopBar.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    GachaTopBar.BorderSizePixel = 0
    GachaTopBar.ZIndex = 46
    GachaTopBar.Parent = GachaModal

    local GachaHeader = Instance.new("TextLabel")
    GachaHeader.Size = UDim2.new(1, -80, 1, 0)
    GachaHeader.Position = UDim2.new(0, 18, 0, 0)
    GachaHeader.BackgroundTransparency = 1
    GachaHeader.Text = "MINI GAME: GETKEY OR NOKEY"
    GachaHeader.TextColor3 = Color3.fromRGB(244, 244, 246)
    GachaHeader.TextSize = 12.5
    GachaHeader.Font = Enum.Font.GothamBold
    GachaHeader.TextXAlignment = Enum.TextXAlignment.Left
    GachaHeader.ZIndex = 47
    GachaHeader.Parent = GachaTopBar

    local GachaCloseBtn = Instance.new("TextButton")
    GachaCloseBtn.Size = UDim2.new(0, 28, 0, 28)
    GachaCloseBtn.Position = UDim2.new(1, -40, 0.5, -14)
    GachaCloseBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    GachaCloseBtn.Text = "✕"
    GachaCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    GachaCloseBtn.TextSize = 11
    GachaCloseBtn.Font = Enum.Font.GothamBold
    GachaCloseBtn.AutoButtonColor = false
    GachaCloseBtn.ZIndex = 47
    GachaCloseBtn.Parent = GachaTopBar
    Instance.new("UICorner", GachaCloseBtn).CornerRadius = UDim.new(0, 6)

    local BoxesContainer = Instance.new("Frame")
    BoxesContainer.Size = UDim2.new(1, -36, 0, 215)
    BoxesContainer.Position = UDim2.new(0, 18, 0, 60)
    BoxesContainer.BackgroundTransparency = 1
    BoxesContainer.ZIndex = 46
    BoxesContainer.Parent = GachaModal

    local function CreateMysteryBox(name: string, posX: number, boxTitle: string)
        local BoxCard = Instance.new("TextButton")
        BoxCard.Name = name
        BoxCard.Size = UDim2.new(0.5, -6, 1, 0)
        BoxCard.Position = UDim2.new(0, posX, 0, 0)
        BoxCard.BackgroundColor3 = Color3.fromRGB(19, 19, 25)
        BoxCard.Text = ""
        BoxCard.AutoButtonColor = false
        BoxCard.ZIndex = 47
        BoxCard.Parent = BoxesContainer
        Instance.new("UICorner", BoxCard).CornerRadius = UDim.new(0, 10)
        local BoxStroke = Instance.new("UIStroke", BoxCard)
        BoxStroke.Color = Color3.fromRGB(38, 38, 48)
        BoxStroke.Thickness = 1

        -- Tag 50% - 50%
        local OddsLabel = Instance.new("TextLabel")
        OddsLabel.Size = UDim2.new(1, -20, 0, 20)
        OddsLabel.Position = UDim2.new(0, 10, 0, 10)
        OddsLabel.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
        OddsLabel.Text = "50% NOKEY  •  50% GETKEY"
        OddsLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
        OddsLabel.TextSize = 9
        OddsLabel.Font = Enum.Font.GothamBold
        OddsLabel.ZIndex = 48
        OddsLabel.Parent = BoxCard
        Instance.new("UICorner", OddsLabel).CornerRadius = UDim.new(0, 5)

        -- KHUNG CẮT VIEWPORT KHÔNG DÙNG UICORNER ĐỂ CLIPSDESCENDANTS HOẠT ĐỘNG 100%
        -- Loại bỏ hoàn toàn viền sticker trắng và nền trắng quanh nơ
        local CropViewport = Instance.new("Frame")
        CropViewport.Name = "CropViewport"
        CropViewport.Size = UDim2.new(0, 96, 0, 86)
        CropViewport.Position = UDim2.new(0.5, -48, 0, 38)
        CropViewport.BackgroundColor3 = Color3.fromRGB(19, 19, 25)
        CropViewport.BorderSizePixel = 0
        CropViewport.ClipsDescendants = true
        CropViewport.ZIndex = 48
        CropViewport.Parent = BoxCard

        local GiftImage = Instance.new("ImageLabel")
        GiftImage.Name = "GiftImage"
        GiftImage.AnchorPoint = Vector2.new(0.5, 0)
        -- Cắt chính xác vào vùng nắp tím (Y=25%..95%) và thân hộp cam (X=8%..92%), triệt tiêu 100% mảng trắng
        GiftImage.Size = UDim2.new(1.22, 0, 1.43, 0)
        GiftImage.Position = UDim2.new(0.5, 0, -0.36, 0)
        GiftImage.BackgroundTransparency = 1
        GiftImage.BorderSizePixel = 0
        GiftImage.Image = GiftBoxTexture
        GiftImage.ScaleType = Enum.ScaleType.Stretch
        GiftImage.ZIndex = 49
        GiftImage.Parent = CropViewport

        -- Khung viền bo nhẹ phủ lên mép cắt của hộp quà
        local ViewportBorder = Instance.new("Frame")
        ViewportBorder.Size = UDim2.new(1, 0, 1, 0)
        ViewportBorder.BackgroundTransparency = 1
        ViewportBorder.ZIndex = 50
        ViewportBorder.Parent = CropViewport
        local VpStroke = Instance.new("UIStroke", ViewportBorder)
        VpStroke.Color = Color3.fromRGB(45, 45, 58)
        VpStroke.Thickness = 1.5

        local Title = Instance.new("TextLabel")
        Title.Name = "BoxTitle"
        Title.Size = UDim2.new(1, 0, 0, 18)
        Title.Position = UDim2.new(0, 0, 0, 134)
        Title.BackgroundTransparency = 1
        Title.Text = boxTitle
        Title.TextColor3 = Color3.fromRGB(244, 244, 246)
        Title.TextSize = 11.5
        Title.Font = Enum.Font.GothamBold
        Title.ZIndex = 48
        Title.Parent = BoxCard

        local ActionHint = Instance.new("TextLabel")
        ActionHint.Name = "ActionHint"
        ActionHint.Size = UDim2.new(1, -24, 0, 28)
        ActionHint.Position = UDim2.new(0, 12, 0, 175)
        ActionHint.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
        ActionHint.Text = "MỞ HỘP QUÀ"
        ActionHint.TextColor3 = Color3.fromRGB(255, 255, 255)
        ActionHint.TextSize = 10.5
        ActionHint.Font = Enum.Font.GothamBold
        ActionHint.ZIndex = 48
        ActionHint.Parent = BoxCard
        Instance.new("UICorner", ActionHint).CornerRadius = UDim.new(0, 6)

        return BoxCard, BoxStroke, CropViewport, GiftImage, Title, ActionHint
    end

    local Box1, Box1Stroke, Box1Wrap, Box1Img, Box1Title, Box1Hint = CreateMysteryBox("Box1", 0, "HỘP QUÀ #1")
    local Box2, Box2Stroke, Box2Wrap, Box2Img, Box2Title, Box2Hint = CreateMysteryBox("Box2", 198, "HỘP QUÀ #2")

    local GachaResultBanner = Instance.new("TextLabel")
    GachaResultBanner.Size = UDim2.new(1, -36, 0, 34)
    GachaResultBanner.Position = UDim2.new(0, 18, 0, 286)
    GachaResultBanner.BackgroundColor3 = Color3.fromRGB(19, 19, 25)
    GachaResultBanner.Text = "Chọn 1 trong 2 hộp quà (Mỗi ngày chỉ được mở 1 lần, hồi lúc 00:00)"
    GachaResultBanner.TextColor3 = Color3.fromRGB(161, 161, 170)
    GachaResultBanner.TextSize = 10
    GachaResultBanner.Font = Enum.Font.GothamMedium
    GachaResultBanner.ZIndex = 46
    GachaResultBanner.Parent = GachaModal
    Instance.new("UICorner", GachaResultBanner).CornerRadius = UDim.new(0, 8)
    local ResultBannerStroke = Instance.new("UIStroke", GachaResultBanner)
    ResultBannerStroke.Color = Color3.fromRGB(34, 34, 44)
    -- =========================================================================
--   CHILLI HUB V2 X RONNEI - STEAL AN EGG (PHẦN 5/5)
--   LOGIC MỞ HỘP 70% GETKEY / 30% NOKEY · XỬ LÝ SỰ KIỆN · DÙNG THỬ 2 PHÚT
-- =========================================================================

    local isRollingMutex = false

    local function OpenGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
    end

    local function CloseGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(0, 0, 1, 0)
        }):Play()
    end

    GachaCloseBtn.MouseButton1Click:Connect(function()
        if isRollingMutex then return end
        PlayButtonPress(GachaCloseBtn)
        CloseGachaModal()
    end)

    MiniGameBtn.MouseButton1Click:Connect(function()
        PlayButtonPress(MiniGameBtn)
        if not CanPlayGachaToday() then
            local secsLeft = GetSecondsUntilMidnightGMT7()
            local hoursLeft = math.floor(secsLeft / 3600)
            local minsLeft = math.floor((secsLeft % 3600) / 60)
            StatusMsg.Text = string.format("Đã hết lượt mở hôm nay. Mở lại sau %02dh %02dm (00:00 GMT+7)", hoursLeft, minsLeft)
            StatusMsg.TextColor3 = Color3.fromRGB(239, 68, 68)
            return
        end
        OpenGachaModal()
    end)

    -- HÀM MỞ HỘP QUÀ: HIỂN THỊ 50/50 NHƯNG TỈ LỆ THỰC 70% GETKEY - 30% NOKEY
    local function ExecuteBoxRoll(chosenBox: TextButton, otherBox: TextButton, chosenStroke: UIStroke, chosenWrap: Frame, chosenTitle: TextLabel, chosenHint: TextLabel)
        if isRollingMutex then return end
        isRollingMutex = true

        SaveGachaPlayed()
        MiniGameBtn.Text = Languages[CurrentLang].MiniGameLocked
        MiniGameBtn.TextColor3 = Color3.fromRGB(115, 115, 128)
        MiniGameStroke.Color = Color3.fromRGB(38, 38, 48)

        TweenService:Create(otherBox, TweenInfo.new(0.25), { BackgroundTransparency = 0.65 }):Play()
        otherBox.Active = false

        chosenHint.Text = "ĐANG MỞ..."
        chosenHint.BackgroundColor3 = Color3.fromRGB(217, 119, 6)
        chosenStroke.Color = Color3.fromRGB(217, 119, 6)
        GachaResultBanner.Text = "Đang mở hộp quà..."
        GachaResultBanner.TextColor3 = Color3.fromRGB(250, 204, 21)

        task.spawn(function()
            local origPos = chosenWrap.Position
            for i = 1, 8 do
                local offset = (i % 2 == 0) and 3 or -3
                chosenWrap.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + offset, origPos.Y.Scale, origPos.Y.Offset)
                task.wait(0.05)
            end
            chosenWrap.Position = origPos
        end)

        task.wait(0.75)

        -- TỈ LỆ NGẦM: 30% NOKEY (<= 30) / 70% GETKEY (> 30)
        local roll = math.random(1, 100)
        local isNoKeyWon = (roll <= 30)

        if isNoKeyWon then
            chosenTitle.Text = "TRÚNG NOKEY"
            chosenTitle.TextColor3 = Color3.fromRGB(34, 197, 94)
            chosenHint.Text = "ĐANG MỞ SCRIPT"
            chosenHint.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
            chosenStroke.Color = Color3.fromRGB(34, 197, 94)

            GachaResultBanner.Text = "Chúc mừng! Bạn đã mở trúng NoKey. Đang khởi động script gốc..."
            GachaResultBanner.TextColor3 = Color3.fromRGB(34, 197, 94)

            local secsUntilMidnight = GetSecondsUntilMidnightGMT7()
            Save24hKey(secsUntilMidnight)

            task.wait(1.1)
            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()

            TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 }):Play()
            TweenService:Create(MainFrame, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            task.wait(0.2)
            ScreenGui:Destroy()
        else
            chosenTitle.Text = "TRÚNG GETKEY"
            chosenTitle.TextColor3 = Color3.fromRGB(244, 63, 94)
            chosenHint.Text = "QUAY VỀ GETKEY"
            chosenHint.BackgroundColor3 = Color3.fromRGB(60, 25, 35)
            chosenStroke.Color = Color3.fromRGB(244, 63, 94)

            GachaResultBanner.Text = "Bạn mở trúng GetKey (70%). Đang quay về màn hình lấy key..."
            GachaResultBanner.TextColor3 = Color3.fromRGB(244, 63, 94)

            task.wait(1.5)
            CloseGachaModal()
            isRollingMutex = false

            StatusMsg.Text = "Mở trúng hộp GetKey. Vui lòng bấm Lấy Key (24 Tiếng) để tiếp tục."
            StatusMsg.TextColor3 = Color3.fromRGB(244, 63, 94)
        end
    end

    Box1.MouseButton1Click:Connect(function()
        ExecuteBoxRoll(Box1, Box2, Box1Stroke, Box1Wrap, Box1Title, Box1Hint)
    end)

    Box2.MouseButton1Click:Connect(function()
        ExecuteBoxRoll(Box2, Box1, Box2Stroke, Box2Wrap, Box2Title, Box2Hint)
    end)

    -- ĐỔI NGÔN NGỮ NHANH TRỰC TIẾP TRÊN NÚT HEADER
    LangToggleBtn.MouseButton1Click:Connect(function()
        PlayButtonPress(LangToggleBtn)
        CurrentLang = (CurrentLang == "VI") and "EN" or "VI"
        local data = Languages[CurrentLang]
        LangToggleBtn.Text = data.LangBtnText
        TitleLabel.Text = data.Title
        SubTitleLabel.Text = data.Subtitle
        InputHeaderLabel.Text = data.InputLabel
        InputBox.PlaceholderText = data.Placeholder
        QuickPasteBtn.Text = data.QuickPaste
        GetKeyBtn.Text = data.GetKey
        CheckKeyBtn.Text = data.CheckKey
        TutorialBtn.Text = data.Tutorial
        MiniGameBtn.Text = CanPlayGachaToday() and data.MiniGame or data.MiniGameLocked
        NoticeText.Text = data.Notice
    end)

    QuickPasteBtn.MouseButton1Click:Connect(function()
        PlayButtonPress(QuickPasteBtn)
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
        PlayButtonPress(TutorialBtn)

        if setclipboard then setclipboard(TutorialUrl) elseif toclipboard then toclipboard(TutorialUrl) end

        TutorialBtn.Text = "Đã sao chép link hướng dẫn"
        TutorialBtn.TextColor3 = Color3.fromRGB(34, 197, 94)
        StatusMsg.Text = Languages[CurrentLang].CopiedTutorial
        StatusMsg.TextColor3 = Color3.fromRGB(34, 197, 94)

        task.delay(2.2, function()
            if TutorialBtn and TutorialBtn.Parent then
                TutorialBtn.Text = Languages[CurrentLang].Tutorial
                TutorialBtn.TextColor3 = Color3.fromRGB(185, 185, 198)
                StatusMsg.Text = "Ready • 24-Hour Key System"
                StatusMsg.TextColor3 = Color3.fromRGB(110, 110, 122)
            end
            isTutorialDebounce = false
        end)
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        PlayButtonPress(GetKeyBtn)
        if setclipboard then setclipboard(KeyUrl) elseif toclipboard then toclipboard(KeyUrl) end

        GetKeyBtn.Text = "Copied Link (24H)"
        GetKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
        StatusMsg.Text = Languages[CurrentLang].CopiedLink
        StatusMsg.TextColor3 = Color3.fromRGB(34, 197, 94)

        task.delay(2.2, function()
            if GetKeyBtn and GetKeyBtn.Parent then
                GetKeyBtn.Text = Languages[CurrentLang].GetKey
                GetKeyBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
                StatusMsg.Text = "Ready • 24-Hour Key System"
                StatusMsg.TextColor3 = Color3.fromRGB(110, 110, 122)
            end
        end)
    end)

    local isChecking = false
    CheckKeyBtn.MouseButton1Click:Connect(function()
        if isChecking then return end
        isChecking = true
        PlayButtonPress(CheckKeyBtn)

        CheckKeyBtn.Text = Languages[CurrentLang].Checking
        StatusMsg.Text = Languages[CurrentLang].CheckingMsg
        StatusMsg.TextColor3 = Color3.fromRGB(210, 210, 220)

        task.wait(0.3)
        local isKeyValid = VerifyChilliV2Key(InputBox.Text)

        if isKeyValid then
            Save24hKey()
            CheckKeyBtn.Text = "Verified"
            CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
            StatusMsg.Text = Languages[CurrentLang].Success
            StatusMsg.TextColor3 = Color3.fromRGB(34, 197, 94)

            RemoveScreenLockdown()
            LaunchTargetScriptWithWatcher()

            task.wait(0.35)
            TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 }):Play()
            TweenService:Create(MainFrame, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            task.wait(0.2)
            ScreenGui:Destroy()
        else
            isChecking = false
            CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
            StatusMsg.Text = Languages[CurrentLang].Error
            StatusMsg.TextColor3 = Color3.fromRGB(244, 63, 94)

            InputStroke.Color = Color3.fromRGB(244, 63, 94)
            local origOffset = MainFrame.Position.X.Offset
            local offsets = { -5, 5, -3, 3, 0 }
            task.spawn(function()
                for _, off in ipairs(offsets) do
                    local t = TweenService:Create(MainFrame, TweenInfo.new(0.04), {
                        Position = UDim2.new(0.5, off, 0.5, 0)
                    })
                    t:Play()
                    t.Completed:Wait()
                end
                MainFrame.Position = UDim2.new(0.5, origOffset, 0.5, 0)
            end)
            task.wait(0.5)
            InputStroke.Color = Color3.fromRGB(38, 38, 48)
        end
    end)

    MainFrame.BackgroundTransparency = 1
    MainScale.Scale = 0.9
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- =========================================================================
--   LUỒNG CHÍNH: DÙNG THỬ 2 PHÚT & BẢO MẬT KHÓA MÀN HÌNH TỰ ĐỘNG
-- =========================================================================

local keyTimeLeft = GetKeyRemainingTime()
if keyTimeLeft and keyTimeLeft > 0 then
    ShowLiveToast("Chilli Hub V2 X Ronnei (24H Key)", keyTimeLeft, Color3.fromRGB(34, 197, 94))
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
    ShowLiveToast("System Clock Tamper Detected", 0, Color3.fromRGB(244, 63, 94))
    OpenKeySystemUI()
    return
end

local targetEndTime = trialData.StartTime + TRIAL_DURATION
local remaining = targetEndTime - os.time()

if remaining <= 0 then
    ApplyScreenLockdown()
    ShowLiveToast("Free Trial Expired (2 Mins)", 0, Color3.fromRGB(244, 63, 94))
    OpenKeySystemUI()
    return
else
    ShowLiveToast("Chilli Hub V2 (2-Min Free Trial)", remaining, Color3.fromRGB(225, 29, 72))
    LaunchTargetScriptWithWatcher()

    task.spawn(function()
        local saveInterval = 0

        while true do
            task.wait(1)
            local currentRemaining = targetEndTime - os.time()

            if ActiveToastLabel and ActiveToastLabel.Parent then
                ActiveToastLabel.Text = "Time remaining: " .. FormatTime(currentRemaining)
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
                ShowLiveToast("Free Trial Expired (2 Mins)", 0, Color3.fromRGB(244, 63, 94))
                task.wait(0.3)
                OpenKeySystemUI()
                break
            end
        end
    end)
end
