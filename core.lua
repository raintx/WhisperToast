-- core.lua (VERSÃO COMPLETA E FINAL)

local addonName, addon = ...
WhisperToast = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("WhisperToast")
local TOAST_SPACING = 15
local previewSoundHandle = nil

-- Optional custom sounds. Place your .ogg/.wav files under
-- Interface\AddOns\WhisperToast\Sounds\ and register them here.
local SOUND_FOLDER = "Interface\\AddOns\\WhisperToast\\Sounds\\"
local CUSTOM_SOUNDS = {
    ["custom_sound_01"] = { label = "Custom Sound 01", file = SOUND_FOLDER .. "sound01.wav" },
    ["custom_sound_02"] = { label = "Custom Sound 02", file = SOUND_FOLDER .. "sound02.wav" },
    ["custom_sound_03"] = { label = "Custom Sound 03", file = SOUND_FOLDER .. "sound03.wav" },
    ["custom_sound_04"] = { label = "Custom Sound 04", file = SOUND_FOLDER .. "sound04.wav" },
    ["custom_sound_05"] = { label = "Custom Sound 05", file = SOUND_FOLDER .. "sound05.wav" },
    ["custom_sound_06"] = { label = "Custom Sound 06", file = SOUND_FOLDER .. "sound06.wav" },
    ["custom_sound_07"] = { label = "Custom Sound 07", file = SOUND_FOLDER .. "sound07.wav" },
    ["custom_sound_08"] = { label = "Custom Sound 08", file = SOUND_FOLDER .. "sound08.wav" },
    ["custom_sound_09"] = { label = "Custom Sound 09", file = SOUND_FOLDER .. "sound09.wav" },
    ["custom_sound_10"] = { label = "Custom Sound 10", file = SOUND_FOLDER .. "sound10.wav" },
    ["custom_sound_11"] = { label = "Custom Sound 11", file = SOUND_FOLDER .. "sound11.wav" },
    ["custom_sound_12"] = { label = "Custom Sound 12", file = SOUND_FOLDER .. "sound12.wav" },
    ["custom_sound_13"] = { label = "Custom Sound 13", file = SOUND_FOLDER .. "sound13.wav" },
    ["custom_sound_14"] = { label = "Custom Sound 14", file = SOUND_FOLDER .. "sound14.wav" },
    ["custom_sound_15"] = { label = "Custom Sound 15", file = SOUND_FOLDER .. "sound15.wav" },
    ["custom_sound_16"] = { label = "Custom Sound 16", file = SOUND_FOLDER .. "sound16.wav" },
    ["custom_sound_17"] = { label = "Custom Sound 17", file = SOUND_FOLDER .. "sound17.wav" },
    ["custom_sound_18"] = { label = "Custom Sound 18", file = SOUND_FOLDER .. "sound18.wav" },
}

local SOUND_LABEL_KEYS = {
    [11504] = "SOUND_NAME_11504",
    [8960] = "SOUND_NAME_8960",
    [11487] = "SOUND_NAME_11487",
    [567] = "SOUND_NAME_567",
    [850] = "SOUND_NAME_850",
    [1190] = "SOUND_NAME_1190",
    [5274] = "SOUND_NAME_5274",
    [8959] = "SOUND_NAME_8959",
    [12867] = "SOUND_NAME_12867",
    [29495] = "SOUND_NAME_29495",
    [3081] = "SOUND_NAME_3081",
    [5841] = "SOUND_NAME_5841",
    [12889] = "SOUND_NAME_12889",
    [8745] = "SOUND_NAME_8745",
    [11466] = "SOUND_NAME_11466",
    [6595] = "SOUND_NAME_6595",
    [5174] = "SOUND_NAME_5174",
    [878] = "SOUND_NAME_878",
    [569] = "SOUND_NAME_569",
    [1080] = "SOUND_NAME_1080",
    [8835] = "SOUND_NAME_8835",
    [11742] = "SOUND_NAME_11742",
    [8477] = "SOUND_NAME_8477",
    [3400] = "SOUND_NAME_3400",
    [21388] = "SOUND_NAME_21388",
}

local SOUND_LABEL_ORDER = {
    11504, -- Whisper (Default)
    8960,  -- Guild (Default)
    11487, -- Party (Default)
    567, 850, 1190, 5274, 8959, 12867, 29495, 3081, 5841, 12889,
    8745, 11466, 6595, 5174, 878, 569, 1080, 8835, 11742, 8477, 3400, 21388,
}

local SOUND_LABEL_DEFAULTS = {
    [11504] = "Whisper (Default)",
    [8960] = "Guild (Default)",
    [11487] = "Party (Default)",
    [567] = "Map Open",
    [850] = "Bell",
    [1190] = "Chest Looted",
    [5274] = "Gong",
    [8959] = "Tell",
    [12867] = "Door Opening",
    [29495] = "Fanfare",
    [3081] = "Money Looted",
    [5841] = "Level Up",
    [12889] = "Raid Warning",
    [8745] = "Achievement",
    [11466] = "Quest Complete",
    [6595] = "Exploration",
    [5174] = "PvP Flag",
    [878] = "Interface Click",
    [569] = "Menu Pop",
    [1080] = "Rare Item",
    [8835] = "Human Interface",
    [11742] = "Epic Loot",
    [8477] = "Ready Check",
    [3400] = "Tower Alarm",
    [21388] = "Whistle",
}

local CHAT_EVENTS = {
    CHAT_MSG_WHISPER = "WHISPER",
    CHAT_MSG_BN_WHISPER = "BN",
    CHAT_MSG_GUILD = "GUILD",
    CHAT_MSG_PARTY = "PARTY",
    CHAT_MSG_PARTY_LEADER = "PARTY",
    CHAT_MSG_RAID = "RAID",
    CHAT_MSG_RAID_LEADER = "RAID",
    CHAT_MSG_RAID_WARNING = "RAID",
}

local MESSAGE_CONFIG = {
    WHISPER = {
        flag = "whispers",
        titleKey = "WHISPER_TITLE",
        titleFallback = "%s (Whisper):",
        icon = "Interface\\FriendsFrame\\Battlenet-Icon",
        soundKey = "whisperSound",
        soundEnabledKey = "whisperSoundEnabled",
        colorKey = "whisperColor",
    },
    BN = {
        flag = "whispers",
        titleKey = "BNET_TITLE",
        titleFallback = "%s (BNet):",
        icon = "Interface\\FriendsFrame\\Battlenet-Icon",
        soundKey = "whisperSound",
        soundEnabledKey = "whisperSoundEnabled",
        colorKey = "bnetColor",
    },
    GUILD = {
        flag = "guild",
        titleKey = "GUILD_TITLE",
        titleFallback = "%s (Guild):",
        icon = "Interface\\CHATFRAME\\UI-ChatIcon-WoW",
        soundKey = "guildSound",
        soundEnabledKey = "guildSoundEnabled",
        colorKey = "guildColor",
    },
    PARTY = {
        flag = "party",
        titleKey = "PARTY_TITLE",
        titleFallback = "%s (Party):",
        icon = "Interface\\GROUPFRAME\\UI-Group-Icon",
        soundKey = "partySound",
        soundEnabledKey = "partySoundEnabled",
        colorKey = "partyColor",
    },
    RAID = {
        flag = "raid",
        titleKey = "RAID_TITLE",
        titleFallback = "%s (Raid):",
        icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8",
        soundKey = "raidSound",
        soundEnabledKey = "raidSoundEnabled",
        colorKey = "raidColor",
    },
}

local function CleanPlayerName(name)
    return name and name:gsub("%-.*$", "")
end

local function TrySetPortraitTexture(portrait, target)
    if not target or target == "" then
        return false
    end
    local success = pcall(SetPortraitTexture, portrait, target)
    if not success then
        return false
    end
    local texture = portrait:GetTexture()
    return texture and texture ~= 0
end


local defaults = {
    profile = {
        whispers = true, guild = true, party = true, raid = true,
        anchor = { point = "TOP", x = 0, y = -200 },
        appearance = {
            width = 300, height = 80,
            bgColor = { r = 0.05, g = 0.05, b = 0.1, a = 0.95 },
            borderColor = { r = 0.2, g = 0.5, b = 0.8, a = 1 },
            titleColor = { r = 0.3, g = 0.8, b = 1.0, a = 1 },
            textColor = { r = 0.9, g = 0.9, b = 0.9, a = 1 },
            maxChars = 200,
            whisperColor = { r = 1.0, g = 0.9, b = 0.2, a = 1 },
            bnetColor = { r = 0.0, g = 0.8, b = 1.0, a = 1 },
            guildColor = { r = 0.2, g = 0.8, b = 0.2, a = 1 },
            partyColor = { r = 0.4, g = 0.6, b = 1.0, a = 1 },
            raidColor = { r = 1.0, g = 0.5, b = 0.0, a = 1 },
        },
        sound = {
            enabled = true, volume = "Master",
            whisperSound = 11504, whisperSoundEnabled = true,
            guildSound = 8960, guildSoundEnabled = true,
            partySound = 11487, partySoundEnabled = true,
            raidSound = 11487, raidSoundEnabled = true,
        },
        behavior = { displayTime = 10, showPortrait = true }
    }
}

local activeToasts, anchor, updateFrame = {}, nil, nil
local messageQueue, lastMessageTime, MESSAGE_THROTTLE = {}, 0, 0.1

function WhisperToast:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("WhisperToastDB", defaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    self:SetupOptions()
    self:RegisterChatCommand("whispertoast", "SlashCommand")
    self:RegisterChatCommand("wt", "SlashCommand")
    for event in pairs(CHAT_EVENTS) do
        self:RegisterEvent(event, "OnChatEvent")
    end
end

function WhisperToast:RefreshConfig()
    if anchor then
        local anchorData = self.db.profile.anchor
        local app = self.db.profile.appearance
        anchor:ClearAllPoints()
        anchor:SetPoint(anchorData.point, UIParent, anchorData.point, anchorData.x, anchorData.y)
        anchor:SetSize(app.width, app.height)
    end
end

function WhisperToast:SlashCommand(input)
    if input == "test" or input == "teste" then
        self:HandleChatMessage("WHISPER", L["TEST_MESSAGE"] or "This is a test message to see how your customization looks!", "Blizzard")
    elseif input == "move" or input == "mover" then
        if anchor:IsShown() then anchor:Hide() else anchor:Show() end
    else
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory("WhisperToast")
        elseif InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory("WhisperToast")
            InterfaceOptionsFrame_OpenToCategory("WhisperToast")
        else
            self:Print(L["SLASH_HELP"] or "Use the addon options via: ESC > Interface > AddOns > WhisperToast")
        end
    end
end

function WhisperToast:OnEnable()
    anchor = CreateFrame("Frame", "WhisperToastAnchor", UIParent, "BackdropTemplate")
    local app = self.db.profile.appearance
    anchor:SetSize(app.width, app.height)
    local anchorData = self.db.profile.anchor
    anchor:SetPoint(anchorData.point, UIParent, anchorData.point, anchorData.x, anchorData.y)
    anchor:SetBackdrop({ 
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
        tile = true, tileSize = 16, edgeSize = 16, 
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    anchor:SetBackdropColor(0.1, 0.8, 0.1, 0.25)
    anchor:SetMovable(true)
    anchor:EnableMouse(true)
    anchor:SetFrameStrata("TOOLTIP")
    anchor:SetFrameLevel(9999)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetClampedToScreen(true)
    anchor:SetScript("OnDragStart", function(self) self:StartMoving() end)
    anchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        x, y = math.floor(x + 0.5), math.floor(y + 0.5)
        WhisperToast.db.profile.anchor.point = point
        WhisperToast.db.profile.anchor.x = x
        WhisperToast.db.profile.anchor.y = y
        WhisperToast:Print(string.format(L["POS_SAVED"] or "|cff00ff00Position saved:|r %s (X: %d, Y: %d)", point, x, y))
    end)
    anchor:SetScript("OnShow", function(self)
        self:SetFrameStrata("TOOLTIP")
        self:SetFrameLevel(9999)
        self:Raise()
    end)
    
    -- Texto da âncora
    local text = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    text:SetAllPoints(true)
    text:SetText(L["ANCHOR_TEXT"] or "|cff00ff00Drag to Move|r\n|cffaaaaaa/wt move to hide|r")
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    
    -- Animação de pulso na âncora
    local pulseAnim = anchor:CreateAnimationGroup()
    local pulse1 = pulseAnim:CreateAnimation("Alpha")
    pulse1:SetFromAlpha(0.25)
    pulse1:SetToAlpha(0.8)
    pulse1:SetDuration(1)
    pulse1:SetSmoothing("IN_OUT")
    local pulse2 = pulseAnim:CreateAnimation("Alpha")
    pulse2:SetFromAlpha(0.8)
    pulse2:SetToAlpha(0.25)
    pulse2:SetDuration(1)
    pulse2:SetSmoothing("IN_OUT")
    pulse2:SetStartDelay(1)
    pulseAnim:SetLooping("REPEAT")
    
    -- Animação de escala
    local scaleAnim = anchor:CreateAnimationGroup()
    local scale1 = scaleAnim:CreateAnimation("Scale")
    scale1:SetScale(1.05, 1.05)
    scale1:SetDuration(1)
    scale1:SetSmoothing("IN_OUT")
    local scale2 = scaleAnim:CreateAnimation("Scale")
    scale2:SetScale(0.95, 0.95)
    scale2:SetDuration(1)
    scale2:SetSmoothing("IN_OUT")
    scale2:SetStartDelay(1)
    scaleAnim:SetLooping("REPEAT")
    
    anchor:SetScript("OnShow", function(self)
        self:SetFrameStrata("TOOLTIP")
        self:SetFrameLevel(9999)
        self:Raise()
        pulseAnim:Play()
        scaleAnim:Play()
    end)
    
    anchor:SetScript("OnHide", function(self)
        pulseAnim:Stop()
        scaleAnim:Stop()
    end)
    
    anchor:Hide()
    updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function(self, elapsed) WhisperToast:OnUpdate(elapsed) end)
    updateFrame:Hide()
end

function WhisperToast:OnUpdate(elapsed)
    local displayTime = self.db.profile.behavior.displayTime
    if #messageQueue > 0 then
        local currentTime = GetTime()
        if currentTime - lastMessageTime >= MESSAGE_THROTTLE then
            local msg = table.remove(messageQueue, 1)
            if msg then
                self:ShowToast(msg.icon, msg.title, msg.message, msg.sender, msg.titleColor)
                lastMessageTime = currentTime
            end
        end
    end
    for i = #activeToasts, 1, -1 do
        local toast = activeToasts[i]
        if not toast or not toast:IsShown() then
            table.remove(activeToasts, i)
        else
            local _, _, _, _, currentY = toast:GetPoint()
            local targetY = toast.targetY
            if currentY ~= targetY then 
                local newY = currentY + (targetY - currentY) * (10 * elapsed)
                if math.abs(newY - targetY) < 1 then newY = targetY end
                toast:SetPoint("TOP", anchor, "TOP", 0, newY)
            end
            local currentAlpha = toast:GetAlpha()
            local targetAlpha = toast.targetAlpha
            if currentAlpha ~= targetAlpha then 
                local newAlpha = currentAlpha + (targetAlpha - currentAlpha) * (7 * elapsed)
                newAlpha = math.max(0, math.min(1, newAlpha))
                if math.abs(newAlpha - targetAlpha) < 0.01 then newAlpha = targetAlpha end
                toast:SetAlpha(newAlpha)
            end
            if toast.state ~= "fading_out" then
                local timeLeft = displayTime - (GetTime() - toast.startTime)
                if timeLeft > 0 then 
                    toast.Timer:SetValue(timeLeft)
                else 
                    toast.state = "fading_out"
                    toast.targetAlpha = 0
                end
            end
            if toast and toast:IsShown() then
                if toast.state == "fading_out" and toast:GetAlpha() <= 0 then 
                    toast:Hide()
                    table.remove(activeToasts, i)
                    self:UpdateToastPositions()
                end
            else
                table.remove(activeToasts, i)
            end
        end
    end
    if #activeToasts == 0 and #messageQueue == 0 then updateFrame:Hide() end
end

function WhisperToast:Show(icon, title, message, sender, titleColor)
    table.insert(messageQueue, {icon = icon, title = title, message = message, sender = sender, titleColor = titleColor})
    updateFrame:Show()
end

function WhisperToast:ShowToast(icon, title, message, sender, titleColor)
    local toast = self:CreateToastFrame()
    if not toast then return end
    toast:SetPoint("TOP", anchor, "TOP", 0, 50)
    toast:SetAlpha(0)
    local maxChars = self.db.profile.appearance.maxChars
    if #message > maxChars then message = message:sub(1, maxChars) .. "..." end
    toast.Message:SetText(message)
    toast.Title:SetText(title)
    if titleColor then
        toast.Title:SetTextColor(titleColor.r, titleColor.g, titleColor.b, titleColor.a)
    else
        local app = self.db.profile.appearance
        toast.Title:SetTextColor(app.titleColor.r, app.titleColor.g, app.titleColor.b, app.titleColor.a)
    end
    
    self:SetToastPortrait(toast, sender, icon)
    
    local displayTime = self.db.profile.behavior.displayTime
    toast.Timer:SetMinMaxValues(0, displayTime)
    toast.Timer:SetValue(displayTime)
    toast.startTime = GetTime()
    toast.targetAlpha = 1
    toast.state = "fading_in"
    toast:Show()
    table.insert(activeToasts, 1, toast)
    self:UpdateToastPositions()
end

-- Nova função para buscar ícone de classe
function WhisperToast:GetClassIconForPlayer(playerName)
    if not playerName then return nil end
    
    -- Limpar nome do servidor
    local cleanName = CleanPlayerName(playerName)
    
    -- Verificar se está em grupo/raide
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, _, _, _, _, class = GetRaidRosterInfo(i)
            if name and name:gsub("%-.*$", "") == cleanName and class then
                return "Interface\\WorldStateFrame\\Icons-Classes"
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local unit = "party" .. i
            if UnitName(unit) and UnitName(unit):gsub("%-.*$", "") == cleanName then
                local _, class = UnitClass(unit)
                if class then
                    return "Interface\\WorldStateFrame\\Icons-Classes"
                end
            end
        end
    end
    
    return nil
end

function WhisperToast:TrySetPortraitFromFriends(portrait, cleanName)
    if not cleanName or not C_FriendList then
        return false
    end
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        local friendName = friendInfo and friendInfo.name
        if friendName and CleanPlayerName(friendName) == cleanName then
            if TrySetPortraitTexture(portrait, friendName) then
                return true
            end
        end
    end
    return false
end

function WhisperToast:TrySetPortraitFromGroup(portrait, cleanName)
    if not cleanName then
        return false
    end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name and CleanPlayerName(name) == cleanName then
                if TrySetPortraitTexture(portrait, name) then
                    return true
                end
            end
        end
    end
    if IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local unit = "party" .. i
            local name = UnitName(unit)
            if name and CleanPlayerName(name) == cleanName then
                if TrySetPortraitTexture(portrait, unit) then
                    return true
                end
            end
        end
    end
    if CleanPlayerName(UnitName("player")) == cleanName then
        return TrySetPortraitTexture(portrait, "player")
    end
    return false
end

function WhisperToast:SetToastPortrait(toast, sender, fallbackIcon)
    local portrait = toast.Portrait
    if not self.db.profile.behavior.showPortrait or not sender then
        toast.Icon:SetTexture(fallbackIcon)
        toast.Icon:Show()
        portrait:Hide()
        return
    end

    if sender:find("#") then
        toast.Icon:SetTexture(fallbackIcon)
        toast.Icon:Show()
        portrait:Hide()
        return
    end

    if TrySetPortraitTexture(portrait, sender) then
        portrait:Show()
        toast.Icon:Hide()
        return
    end

    local cleanName = CleanPlayerName(sender)
    if TrySetPortraitTexture(portrait, sender .. "-" .. GetRealmName())
        or TrySetPortraitTexture(portrait, cleanName)
        or self:TrySetPortraitFromFriends(portrait, cleanName)
        or self:TrySetPortraitFromGroup(portrait, cleanName) then
        portrait:Show()
        toast.Icon:Hide()
        return
    end

    local classIcon = self:GetClassIconForPlayer(sender)
    toast.Icon:SetTexture(classIcon or fallbackIcon)
    toast.Icon:Show()
    portrait:Hide()
end

function WhisperToast:PlayConfiguredSound(value, channel)
    if not value then return end

    local willPlay, handle
    local numericValue = tonumber(value)
    if type(value) == "number" then
        willPlay, handle = PlaySound(value, channel)
    elseif numericValue then
        willPlay, handle = PlaySound(numericValue, channel)
    else
        local data = CUSTOM_SOUNDS[value]
        if data and data.file then
            willPlay, handle = PlaySoundFile(data.file, channel)
        end
    end

    if handle and type(handle) == "number" then
        return handle
    end
end

function WhisperToast:UpdateToastPositions()
    local height = self.db.profile.appearance.height
    for i, toast in ipairs(activeToasts) do 
        toast.targetY = -((i - 1) * (height + TOAST_SPACING))
    end
end

function WhisperToast:OnChatEvent(event, message, sender, ...)
    local msgType = CHAT_EVENTS[event]
    if msgType then
        self:HandleChatMessage(msgType, message, sender, ...)
    end
end

function WhisperToast:HandleChatMessage(msgType, message, sender)
    local config = MESSAGE_CONFIG[msgType]
    if not config then
        return
    end

    local profile = self.db.profile
    if not profile[config.flag] then
        return
    end

    local senderName = CleanPlayerName(sender) or "?"
    local title = string.format(L[config.titleKey] or config.titleFallback, senderName)
    local appearance = profile.appearance or {}
    local titleColor = appearance[config.colorKey]

    self:Show(config.icon, title, message or "", sender, titleColor)

    local soundProfile = profile.sound or {}
    local soundEnabled = soundProfile.enabled and soundProfile[config.soundEnabledKey]
    local soundValue = soundProfile[config.soundKey]
    if soundEnabled and soundValue then
        self:PlayConfiguredSound(soundValue, soundProfile.volume)
    end
end

function WhisperToast:SetupOptions()
    local function GetSoundList()
        local list = {}
        for _, id in ipairs(SOUND_LABEL_ORDER) do
            local key = SOUND_LABEL_KEYS[id]
            if key then
                list[tostring(id)] = L[key] or SOUND_LABEL_DEFAULTS[id] or ("Sound " .. id)
            end
        end
        for id, key in pairs(SOUND_LABEL_KEYS) do
            local idStr = tostring(id)
            if not list[idStr] then
                list[idStr] = L[key] or SOUND_LABEL_DEFAULTS[id] or ("Sound " .. id)
            end
        end
        local customKeys = {}
        for key in pairs(CUSTOM_SOUNDS) do
            customKeys[#customKeys + 1] = key
        end
        table.sort(customKeys)
        for _, key in ipairs(customKeys) do
            local data = CUSTOM_SOUNDS[key]
            if data then
                list[key] = data.label or key
            end
        end
        return list
    end
    local function CreateSoundGroup(spec)
        return {
            order = spec.order,
            type = "group",
            inline = true,
            name = L[spec.labelKey] or spec.labelFallback,
            args = {
                enabled = {
                    order = 1,
                    type = "toggle",
                    width = "full",
                    name = L[spec.toggleKey] or spec.toggleFallback,
                    desc = L[spec.toggleDescKey] or spec.toggleDescFallback,
                    get = function()
                        return self.db.profile.sound[spec.enabledField]
                    end,
                    set = function(_, value)
                        self.db.profile.sound[spec.enabledField] = value
                    end,
                },
                sound = {
                    order = 2,
                    type = "select",
                    width = "full",
                    name = L[spec.selectKey] or spec.selectFallback,
                    desc = L[spec.selectDescKey] or spec.selectDescFallback,
                    values = GetSoundList(),
                    get = function()
                        local current = self.db.profile.sound[spec.soundField]
                        if type(current) == "number" then
                            return tostring(current)
                        end
                        return current
                    end,
                    set = function(_, value)
                        if type(previewSoundHandle) == "number" then
                            StopSound(previewSoundHandle)
                        end
                        previewSoundHandle = nil

                        local numericValue = tonumber(value)
                        if numericValue then
                            self.db.profile.sound[spec.soundField] = numericValue
                            previewSoundHandle = self:PlayConfiguredSound(numericValue, self.db.profile.sound.volume)
                        else
                            self.db.profile.sound[spec.soundField] = value
                            previewSoundHandle = self:PlayConfiguredSound(value, self.db.profile.sound.volume)
                        end
                    end,
                },
            },
        }
    end
    local options = { 
        name = L["OPTIONS_TITLE"] or "WhisperToast", 
        type = "group", 
        args = {
            desc = { order = 1, type = "description", name = L["OPTIONS_DESC"] or "WhisperToast Settings" },
            notifHeader = { order = 2, type = "header", name = L["SECTION_NOTIFICATIONS"] or "Notification Types" },
            whispers = { order = 3, type = "toggle", name = L["WHISPER_TOGGLE"] or "Whispers & BNet", desc = L["WHISPER_DESC"] or "Show whisper notifications", width = "full", get = function() return self.db.profile.whispers end, set = function(_, v) self.db.profile.whispers = v end },
            guild = { order = 4, type = "toggle", name = L["GUILD_TOGGLE"] or "Guild", desc = L["GUILD_DESC"] or "Show guild notifications", width = "full", get = function() return self.db.profile.guild end, set = function(_, v) self.db.profile.guild = v end },
            party = { order = 5, type = "toggle", name = L["PARTY_TOGGLE"] or "Party", desc = L["PARTY_DESC"] or "Show party notifications", width = "full", get = function() return self.db.profile.party end, set = function(_, v) self.db.profile.party = v end },
            raid = { order = 6, type = "toggle", name = L["RAID_TOGGLE"] or "Raid", desc = L["RAID_DESC"] or "Show raid notifications", width = "full", get = function() return self.db.profile.raid end, set = function(_, v) self.db.profile.raid = v end },
            appearanceHeader = { order = 10, type = "header", name = L["SECTION_APPEARANCE"] or "Appearance" },
            width = { order = 11, type = "range", name = L["WIDTH"] or "Width", min = 200, max = 500, step = 10, get = function() return self.db.profile.appearance.width end, set = function(_, v) self.db.profile.appearance.width = v; if anchor then anchor:SetSize(v, self.db.profile.appearance.height) end end },
            height = { order = 12, type = "range", name = L["HEIGHT"] or "Height", min = 60, max = 150, step = 5, get = function() return self.db.profile.appearance.height end, set = function(_, v) self.db.profile.appearance.height = v; if anchor then anchor:SetSize(self.db.profile.appearance.width, v) end end },
            maxChars = { order = 13, type = "range", name = L["MAX_CHARS"] or "Max Characters", desc = L["MAX_CHARS_DESC"] or "Maximum characters displayed", min = 50, max = 500, step = 10, width = "full", get = function() return self.db.profile.appearance.maxChars end, set = function(_, v) self.db.profile.appearance.maxChars = v end },
            colorHeader = { order = 20, type = "header", name = L["SECTION_COLORS"] or "Colors" },
            bgColor = { order = 21, type = "color", name = L["BG_COLOR"] or "Cor de Fundo", desc = L["BG_COLOR_DESC"] or "Cor do fundo da notificação", hasAlpha = true, get = function() local c = self.db.profile.appearance.bgColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.bgColor = {r=r, g=g, b=b, a=a} end },
            borderColor = { order = 22, type = "color", name = L["BORDER_COLOR"] or "Cor da Borda", desc = L["BORDER_COLOR_DESC"] or "Cor da borda e efeitos brilhantes", hasAlpha = true, get = function() local c = self.db.profile.appearance.borderColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.borderColor = {r=r, g=g, b=b, a=a} end },
            titleColor = { order = 23, type = "color", name = L["TITLE_COLOR"] or "Cor do Título", desc = L["TITLE_COLOR_DESC"] or "Cor padrão do título", hasAlpha = true, get = function() local c = self.db.profile.appearance.titleColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.titleColor = {r=r, g=g, b=b, a=a} end },
            textColor = { order = 24, type = "color", name = L["TEXT_COLOR"] or "Cor do Texto", desc = L["TEXT_COLOR_DESC"] or "Cor do texto da mensagem", hasAlpha = true, get = function() local c = self.db.profile.appearance.textColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.textColor = {r=r, g=g, b=b, a=a} end },
            colorTitleHeader = { order = 25, type = "header", name = L["SECTION_COLORS_CHAT"] or "Cores por Tipo de Chat" },
            whisperColor = { order = 26, type = "color", name = L["WHISPER_COLOR"] or "Cor do Sussurro", desc = L["WHISPER_COLOR_DESC"] or "Cor do nome em sussurros", hasAlpha = true, get = function() local c = self.db.profile.appearance.whisperColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.whisperColor = {r=r, g=g, b=b, a=a} end },
            bnetColor = { order = 27, type = "color", name = L["BNET_COLOR"] or "Cor do Battle.net", desc = L["BNET_COLOR_DESC"] or "Cor do nome em Battle.net", hasAlpha = true, get = function() local c = self.db.profile.appearance.bnetColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.bnetColor = {r=r, g=g, b=b, a=a} end },
            guildColor = { order = 28, type = "color", name = L["GUILD_COLOR"] or "Cor da Guilda", desc = L["GUILD_COLOR_DESC"] or "Cor do nome em guilda", hasAlpha = true, get = function() local c = self.db.profile.appearance.guildColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.guildColor = {r=r, g=g, b=b, a=a} end },
            partyColor = { order = 29, type = "color", name = L["PARTY_COLOR"] or "Cor do Grupo", desc = L["PARTY_COLOR_DESC"] or "Cor do nome em grupo", hasAlpha = true, get = function() local c = self.db.profile.appearance.partyColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.partyColor = {r=r, g=g, b=b, a=a} end },
            raidColor = { order = 30, type = "color", name = L["RAID_COLOR"] or "Cor da Raide", desc = L["RAID_COLOR_DESC"] or "Cor do nome em raide", hasAlpha = true, get = function() local c = self.db.profile.appearance.raidColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.raidColor = {r=r, g=g, b=b, a=a} end },
            soundHeader = { order = 35, type = "header", name = L["SECTION_SOUND"] or "Sound" },
            soundEnabled = { order = 36, type = "toggle", name = L["SOUND_ENABLE"] or "Ativar Sons", desc = L["SOUND_ENABLE_DESC"] or "Ativa/desativa todos os sons", width = "full", get = function() return self.db.profile.sound.enabled end, set = function(_, v) self.db.profile.sound.enabled = v end },
            soundVolume = { order = 37, type = "select", name = L["SOUND_VOLUME"] or "Volume Channel", desc = L["SOUND_VOLUME_DESC"] or "Audio channel", values = {
                Master = L["SOUND_VOLUME_MASTER"] or "Master",
                Sound = L["SOUND_VOLUME_SOUND"] or "Sound Effects",
                Music = L["SOUND_VOLUME_MUSIC"] or "Music",
                Ambience = L["SOUND_VOLUME_AMBIENCE"] or "Ambience",
                Dialog = L["SOUND_VOLUME_DIALOG"] or "Dialog",
            }, get = function() return self.db.profile.sound.volume end, set = function(_, v) self.db.profile.sound.volume = v end },
            soundIndividualHeader = { order = 38, type = "header", name = L["SECTION_SOUND_INDIVIDUAL"] or "Sons Individuais" },
            whisperSoundGroup = CreateSoundGroup({
                order = 39,
                labelKey = "SOUND_WHISPER",
                labelFallback = "Whisper Sound",
                toggleKey = "SOUND_WHISPER_TOGGLE",
                toggleFallback = "Som de Sussurro",
                toggleDescKey = "SOUND_WHISPER_TOGGLE_DESC",
                toggleDescFallback = "Ativar som para sussurros",
                selectKey = "SOUND_WHISPER_SELECT",
                selectFallback = "Escolher Som (Sussurro)",
                selectDescKey = "SOUND_WHISPER_SELECT_DESC",
                selectDescFallback = "Clique para previa",
                enabledField = "whisperSoundEnabled",
                soundField = "whisperSound",
            }),
            guildSoundGroup = CreateSoundGroup({
                order = 40,
                labelKey = "SOUND_GUILD",
                labelFallback = "Guild Sound",
                toggleKey = "SOUND_GUILD_TOGGLE",
                toggleFallback = "Som de Guilda",
                toggleDescKey = "SOUND_GUILD_TOGGLE_DESC",
                toggleDescFallback = "Ativar som para guilda",
                selectKey = "SOUND_GUILD_SELECT",
                selectFallback = "Escolher Som (Guilda)",
                selectDescKey = "SOUND_GUILD_SELECT_DESC",
                selectDescFallback = "Clique para previa",
                enabledField = "guildSoundEnabled",
                soundField = "guildSound",
            }),
            partySoundGroup = CreateSoundGroup({
                order = 41,
                labelKey = "SOUND_PARTY",
                labelFallback = "Party Sound",
                toggleKey = "SOUND_PARTY_TOGGLE",
                toggleFallback = "Som de Grupo",
                toggleDescKey = "SOUND_PARTY_TOGGLE_DESC",
                toggleDescFallback = "Ativar som para grupo",
                selectKey = "SOUND_PARTY_SELECT",
                selectFallback = "Escolher Som (Grupo)",
                selectDescKey = "SOUND_PARTY_SELECT_DESC",
                selectDescFallback = "Clique para previa",
                enabledField = "partySoundEnabled",
                soundField = "partySound",
            }),
            raidSoundGroup = CreateSoundGroup({
                order = 42,
                labelKey = "SOUND_RAID",
                labelFallback = "Raid Sound",
                toggleKey = "SOUND_RAID_TOGGLE",
                toggleFallback = "Som de Raide",
                toggleDescKey = "SOUND_RAID_TOGGLE_DESC",
                toggleDescFallback = "Ativar som para raide",
                selectKey = "SOUND_RAID_SELECT",
                selectFallback = "Escolher Som (Raide)",
                selectDescKey = "SOUND_RAID_SELECT_DESC",
                selectDescFallback = "Clique para previa",
                enabledField = "raidSoundEnabled",
                soundField = "raidSound",
            }),
            behaviorHeader = { order = 50, type = "header", name = L["SECTION_BEHAVIOR"] or "Behavior" },
            displayTime = { order = 51, type = "range", name = L["DISPLAY_TIME"] or "Tempo de Exibição", desc = L["DISPLAY_TIME_DESC"] or "Quantos segundos fica visível", min = 3, max = 30, step = 1, width = "full", get = function() return self.db.profile.behavior.displayTime end, set = function(_, v) self.db.profile.behavior.displayTime = v end },
            showPortrait = { order = 52, type = "toggle", name = L["SHOW_PORTRAIT"] or "Mostrar Retrato", desc = L["SHOW_PORTRAIT_DESC"] or "Exibir retrato", width = "full", get = function() return self.db.profile.behavior.showPortrait end, set = function(_, v) self.db.profile.behavior.showPortrait = v end },
            posHeader = { order = 60, type = "header", name = L["SECTION_POSITION"] or "Positioning" },
            move = { order = 61, type = "execute", name = L["BTN_MOVE"] or "Mover Âncora", desc = L["BTN_MOVE_DESC"] or "Mostra âncora animada", func = function() if anchor:IsShown() then anchor:Hide() else anchor:Show() end end },
            test = { order = 62, type = "execute", name = L["BTN_TEST"] or "Mostrar Teste", desc = L["BTN_TEST_DESC"] or "Exibe notificação de teste", func = function() self:HandleChatMessage("WHISPER", L["TEST_MESSAGE"] or "This is a test message to see how your customization looks!", "Blizzard") end },
            reset = { order = 63, type = "execute", name = L["BTN_RESET_POS"] or "Resetar Posição", desc = L["BTN_RESET_POS_DESC"] or "Volta ao centro", func = function() self.db.profile.anchor = { point = "TOP", x = 0, y = -200 }; if anchor then anchor:ClearAllPoints(); anchor:SetPoint("TOP", UIParent, "TOP", 0, -200) end; self:Print(L["POS_RESET"] or "Position reset") end },
            resetAll = { order = 64, type = "execute", name = L["BTN_RESET_ALL"] or "Resetar Tudo", desc = L["BTN_RESET_ALL_DESC"] or "Restaura tudo", confirm = true, confirmText = L["BTN_RESET_CONFIRM"] or "Reset ALL?", func = function() self.db:ResetProfile(); ReloadUI() end }
        }
    }  
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WhisperToast", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WhisperToast", L["OPTIONS_TITLE"] or "WhisperToast")
end

