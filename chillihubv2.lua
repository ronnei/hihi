--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.10.9) ~  Much Love, Ferib 

]]--

local v0=game:GetService("Lighting");local v1=game:GetService("Workspace");local function v2() v0.GlobalShadows=false;v0.FogEnd=8999999488;for v7,v8 in pairs(v0:GetChildren()) do if (v8:IsA("PostEffect") or v8:IsA("BlurEffect") or v8:IsA("SunRaysEffect") or v8:IsA("ColorCorrectionEffect")) then v8.Enabled=false;end end for v9,v10 in pairs(v1:GetDescendants()) do if (v10:IsA("BasePart") and  not v10:IsA("MeshPart")) then v10.Material=Enum.Material.SmoothPlastic;elseif (v10:IsA("ParticleEmitter") or v10:IsA("Smoke") or v10:IsA("Fire") or v10:IsA("Sparkles")) then v10.Enabled=false;elseif (v10:IsA("Decal") or v10:IsA("Texture")) then v10.Texture="";end end settings().Rendering.QualityLevel=Enum.QualityLevel.Level01;end pcall(v2);loadstring(game:HttpGet("https://raw.githubusercontent.com/robvxs24/freemium/refs/heads/main/chillihubv2.lua"))();
