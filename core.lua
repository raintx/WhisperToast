-- core.lua

local addonName, addon = ...
WhisperToast = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("WhisperToast")
local TOAST_SPACING = 15
local previewSoundHandle = nil
local previewTimer = nil

WhisperToast.previewLockActive = false
WhisperToast.previewLockToast = nil
WhisperToast.previewLockType = nil
WhisperToast.previewLockHooked = false
WhisperToast.previewLockAuto = false
WhisperToast.previewLockSuppressed = false

local PREVIEW_SENDERS = {
    WHISPER = L["PREVIEW_SENDER_WHISPER"] or "Blizzard",
    BN = L["PREVIEW_SENDER_BN"] or "Battle.net Friend",
    GUILD = L["PREVIEW_SENDER_GUILD"] or "Guildmate",
    PARTY = L["PREVIEW_SENDER_PARTY"] or "Party Member",
    RAID = L["PREVIEW_SENDER_RAID"] or "Raid Member",
}

-- Optional custom sounds. Place your .ogg/.wav files under
-- Interface\AddOns\WhisperToast\Sounds\ and register them here.
local SOUND_FOLDER = "Interface\\AddOns\\WhisperToast\\Sounds\\"
local CUSTOM_SOUND_COUNT = 18
local CUSTOM_SOUNDS = {}
for index = 1, CUSTOM_SOUND_COUNT do
    local suffix = string.format("%02d", index)
    local key = "custom_sound_" .. suffix
    CUSTOM_SOUNDS[key] = {
        labelKey = "CUSTOM_SOUND_LABEL",
        labelArg = index,
        file = SOUND_FOLDER .. "sound" .. suffix .. ".wav",
    }
end

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
            titleOffsetX = 0,
            titleOffsetY = -15,
            portraitOffsetX = 8,
            portraitOffsetY = -7,
            iconOffsetX = 12,
            iconOffsetY = 0,
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
        behavior = { displayTime = 10, showPortrait = true, animatedPortrait = false, ignoreSelf = false }
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
                self:ShowToast(msg.icon, msg.title, msg.message, msg.sender, msg.titleColor, msg.opts)
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
        if toast.previewLock then
            toast.Timer:SetValue(displayTime)
        elseif toast.state ~= "fading_out" then
            local timeLeft = displayTime - (GetTime() - toast.startTime)
            if timeLeft > 0 then 
                toast.Timer:SetValue(timeLeft)
            else 
                toast.state = "fading_out"
                self:HideAnimatedPortrait(toast)
                toast.targetAlpha = 0
            end
            end
            if toast and toast:IsShown() then
                if toast.state == "fading_out" and toast:GetAlpha() <= 0 then 
                    self:HideAnimatedPortrait(toast)
                    toast:Hide()
                    table.remove(activeToasts, i)
                    self:UpdateToastPositions()
                end
            else
                self:HideAnimatedPortrait(toast)
                table.remove(activeToasts, i)
            end
        end
    end
    if #activeToasts == 0 and #messageQueue == 0 then updateFrame:Hide() end
end

function WhisperToast:Show(icon, title, message, sender, titleColor, opts)
    table.insert(messageQueue, {
        icon = icon,
        title = title,
        message = message,
        sender = sender,
        titleColor = titleColor,
        opts = opts,
    })
    updateFrame:Show()
end

function WhisperToast:ShowToast(icon, title, message, sender, titleColor, opts)
    opts = opts or {}
    local toast
    local reused = false
    if opts.previewLock and self.previewLockToast then
        toast = self.previewLockToast
        reused = true
    else
        toast = self:CreateToastFrame()
        if not toast then return end
    end

    toast:ClearAllPoints()
    if opts.previewLock then
        toast:SetPoint("TOP", anchor, "TOP", 0, 0)
    else
        toast:SetPoint("TOP", anchor, "TOP", 0, 50)
    end

    self:ApplyToastAppearance(toast)

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
    if opts.previewLock then
        toast:SetAlpha(1)
        toast.state = "static"
    else
        if not reused then
            toast:SetAlpha(0)
        end
        toast.state = "fading_in"
    end
    toast.previewLock = opts.previewLock and true or false
    toast.previewUnit = opts.previewUnit
    if toast.previewLock then
        toast.previewLockType = opts.previewLockType or sender or "WHISPER"
        self.previewLockToast = toast
        self.previewLockActive = true
        self.previewLockType = opts.previewLockType or self.previewLockType or "WHISPER"
    else
        toast.previewLockType = nil
    end
    if not reused then
        toast:Show()
        table.insert(activeToasts, 1, toast)
    else
        if not toast:IsShown() then
            toast:Show()
        end
        -- Garanta que o toast de preview fique no topo da pilha
        local currentIndex
        for index, frame in ipairs(activeToasts) do
            if frame == toast then
                currentIndex = index
                break
            end
        end
        if not currentIndex then
            table.insert(activeToasts, 1, toast)
        elseif currentIndex ~= 1 then
            table.remove(activeToasts, currentIndex)
            table.insert(activeToasts, 1, toast)
        end
    end
    self:UpdateToastPositions()
end

function WhisperToast:ApplyToastAppearance(toast)
    if not toast or not self.db or not self.db.profile then
        return
    end
    local app = self.db.profile.appearance
    if not app then
        return
    end

    toast:SetSize(app.width, app.height)
    if toast.SetBackdropColor then
        toast:SetBackdropColor(app.bgColor.r, app.bgColor.g, app.bgColor.b, app.bgColor.a)
    end
    if toast.SetBackdropBorderColor then
        toast:SetBackdropBorderColor(app.borderColor.r, app.borderColor.g, app.borderColor.b, app.borderColor.a)
    end

    if toast.TopGlow then
        toast.TopGlow:SetSize(app.width + 20, 40)
        toast.TopGlow:SetPoint("TOP", 0, 8)
        toast.TopGlow:SetVertexColor(app.borderColor.r, app.borderColor.g, app.borderColor.b)
    end

    if toast.TopLine then
        toast.TopLine:SetPoint("TOPLEFT", 5, -5)
        toast.TopLine:SetPoint("TOPRIGHT", -5, -5)
        toast.TopLine:SetHeight(2)
        toast.TopLine:SetColorTexture(app.borderColor.r, app.borderColor.g, app.borderColor.b, 0.8)
    end

    local portraitSize = app.height - 16
    local portraitOffsetX = app.portraitOffsetX or 8
    local portraitOffsetY = app.portraitOffsetY or -7
    local portraitTexture = toast.Portrait
    if portraitTexture then
        portraitTexture:SetSize(portraitSize, portraitSize)
        portraitTexture:ClearAllPoints()
        portraitTexture:SetPoint("TOPLEFT", toast, "TOPLEFT", portraitOffsetX, portraitOffsetY)
        if toast.PortraitMask then
            toast.PortraitMask:ClearAllPoints()
            toast.PortraitMask:SetAllPoints(portraitTexture)
        end
    end
    local portraitModel = toast.PortraitModel
    if portraitModel then
        portraitModel:SetSize(portraitSize, portraitSize)
        portraitModel:ClearAllPoints()
        portraitModel:SetPoint("CENTER", portraitTexture or toast, "CENTER", 0, 0)
        if portraitModel.Mask then
            portraitModel.Mask:ClearAllPoints()
            portraitModel.Mask:SetAllPoints(portraitModel)
        end
    end
    local portraitBorder = toast.PortraitBorder
    if portraitBorder then
        portraitBorder:SetSize(app.height - 8, app.height - 8)
        portraitBorder:ClearAllPoints()
        portraitBorder:SetPoint("CENTER", portraitTexture or toast, "CENTER", 0, 0)
        portraitBorder:SetVertexColor(app.borderColor.r, app.borderColor.g, app.borderColor.b)
    end

    local iconSize = app.height - 24
    local iconOffsetX = app.iconOffsetX or 12
    local iconOffsetY = app.iconOffsetY or 0
    local iconTexture = toast.Icon
    if iconTexture then
        iconTexture:SetSize(iconSize, iconSize)
        iconTexture:ClearAllPoints()
        iconTexture:SetPoint("TOPLEFT", toast, "TOPLEFT", iconOffsetX, iconOffsetY)
        if toast.IconMask then
            toast.IconMask:ClearAllPoints()
            toast.IconMask:SetAllPoints(iconTexture)
        end
    end
    if toast.IconGlow and iconTexture then
        toast.IconGlow:SetSize(app.height - 12, app.height - 12)
        toast.IconGlow:ClearAllPoints()
        toast.IconGlow:SetPoint("CENTER", iconTexture, "CENTER", 0, 0)
        toast.IconGlow:SetAlpha(0.4)
        toast.IconGlow:SetVertexColor(app.borderColor.r, app.borderColor.g, app.borderColor.b)
    end

    local contentRight = math.max(portraitOffsetX + portraitSize, iconOffsetX + iconSize)
    local textStartX = math.max(contentRight + 12, iconSize + 20)
    local titleOffsetX = app.titleOffsetX or 0
    local titleOffsetY = app.titleOffsetY or -15

    if toast.Title then
        toast.Title:ClearAllPoints()
        toast.Title:SetPoint("TOPLEFT", toast, "TOPLEFT", textStartX + titleOffsetX, titleOffsetY)
        toast.Title:SetPoint("RIGHT", toast, -12, 0)
        toast.Title:SetTextColor(app.titleColor.r, app.titleColor.g, app.titleColor.b, app.titleColor.a)
    end
    if toast.Message then
        toast.Message:ClearAllPoints()
        toast.Message:SetPoint("TOPLEFT", (toast.Title or toast), "BOTTOMLEFT", 0, -4)
        toast.Message:SetPoint("BOTTOMRIGHT", toast, -12, 12)
        toast.Message:SetTextColor(app.textColor.r, app.textColor.g, app.textColor.b, app.textColor.a)
    end

    if toast.TimerBG then
        toast.TimerBG:ClearAllPoints()
        toast.TimerBG:SetPoint("BOTTOMLEFT", 5, 5)
        toast.TimerBG:SetPoint("BOTTOMRIGHT", -5, 5)
        toast.TimerBG:SetHeight(3)
    end
    if toast.Timer then
        toast.Timer:ClearAllPoints()
        toast.Timer:SetPoint("BOTTOMLEFT", 5, 5)
        toast.Timer:SetPoint("BOTTOMRIGHT", -5, 5)
        toast.Timer:SetHeight(3)
        toast.Timer:SetStatusBarColor(app.borderColor.r, app.borderColor.g, app.borderColor.b, 1)
    end
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

function WhisperToast:GetUnitForSender(sender, overrideUnit)
    if overrideUnit and UnitExists(overrideUnit) then
        return overrideUnit
    end
    if not sender or sender == "" or sender:find("#") or sender:match("%|K") then
        return nil
    end
    local cleanName = CleanPlayerName(sender)
    if not cleanName or cleanName == "" then
        return nil
    end

    local function matchesUnit(unit)
        if not unit or not UnitExists(unit) then
            return nil
        end
        local name, realm = UnitFullName(unit)
        if not name then
            return nil
        end
        if realm and realm ~= "" then
            name = name .. "-" .. realm
        end
        if CleanPlayerName(name) == cleanName then
            return unit
        end
        return nil
    end

    local unit = matchesUnit("player")
    if unit then return unit end

    unit = matchesUnit("target")
    if unit then return unit end

    unit = matchesUnit("focus")
    if unit then return unit end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            unit = matchesUnit("raid" .. i)
            if unit then return unit end
        end
    end
    if IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            unit = matchesUnit("party" .. i)
            if unit then return unit end
        end
    end

    return nil
end

function WhisperToast:HideAnimatedPortrait(toast)
    if not toast then return end
    toast.previewUnit = nil
    local model = toast.PortraitModel
    if model then
        if model.ClearModel then
            pcall(model.ClearModel, model)
        end
        model:Hide()
        if model.Mask then
            model.Mask:Hide()
        end
    end
end

function WhisperToast:ApplyAnimatedPortrait(toast, unit)
    if not unit or not UnitExists(unit) then
        return false
    end
    if not self.db.profile.behavior.animatedPortrait then
        return false
    end
    local model = toast.PortraitModel
    if not model or not model.SetUnit then
        return false
    end

    local ok = pcall(function()
        model:ClearModel()
        model:SetUnit(unit)
    end)
    if not ok then
        self:HideAnimatedPortrait(toast)
        return false
    end

    if model.SetPortraitZoom then
        model:SetPortraitZoom(1)
    end
    if model.SetCamDistanceScale then
        model:SetCamDistanceScale(1)
    end
    if model.SetAnimation then
        model:SetAnimation(0, 0)
    end
    if model.SetRotation then
        model:SetRotation(0)
    end
    if model.SetPosition then
        model:SetPosition(0, 0, 0)
    end

    model:Show()
    if model.Mask then
        model.Mask:Show()
    end
    toast.Portrait:Hide()
    toast.Icon:Hide()
    return true
end

function WhisperToast:SetToastPortrait(toast, sender, fallbackIcon)
    local portrait = toast.Portrait
    self:HideAnimatedPortrait(toast)
    if not self.db.profile.behavior.showPortrait or not sender then
        toast.Icon:SetTexture(fallbackIcon)
        toast.Icon:Show()
        portrait:Hide()
        return
    end

    if sender:find("#") or sender:match("%|K") then
        toast.Icon:SetTexture(fallbackIcon)
        toast.Icon:Show()
        portrait:Hide()
        return
    end

    local unitForSender
    if self.db.profile.behavior.animatedPortrait then
        unitForSender = self:GetUnitForSender(sender, toast.previewUnit)
        if unitForSender and self:ApplyAnimatedPortrait(toast, unitForSender) then
            toast.previewUnit = unitForSender
            return
        end
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

function WhisperToast:HandleChatMessage(msgType, message, sender, opts)
    opts = opts or {}
    local profile = self.db.profile
    if profile.behavior and profile.behavior.ignoreSelf and sender and not opts.previewLock and not opts.allowSelf then
        local playerName, playerRealm = UnitFullName("player")
        if playerName and playerName ~= "" then
            local normalizedSender = sender
            if not normalizedSender:find("-", 1, true) and playerRealm and playerRealm ~= "" then
                normalizedSender = normalizedSender .. "-" .. playerRealm
            end
            local playerFullName = playerName
            if playerRealm and playerRealm ~= "" then
                playerFullName = playerFullName .. "-" .. playerRealm
            end
            if normalizedSender == playerName or normalizedSender == playerFullName then
                return
            end
        end
    end
    local config = MESSAGE_CONFIG[msgType]
    if not config then
        return
    end

    if not profile[config.flag] and not opts.previewLock then
        return
    end

    local senderName = CleanPlayerName(sender) or "?"
    local title = string.format(L[config.titleKey] or config.titleFallback, senderName)
    local appearance = profile.appearance or {}
    local titleColor = appearance[config.colorKey]
    local showOpts
    if opts.previewLock then
        showOpts = {
            previewLock = true,
            previewLockType = opts.previewLockType or msgType,
        }
    end

    self:Show(config.icon, title, message or "", sender, titleColor, showOpts)

    local soundProfile = profile.sound or {}
    local soundEnabled = soundProfile.enabled and soundProfile[config.soundEnabledKey]
    local soundValue = soundProfile[config.soundKey]
    if soundEnabled and soundValue and not opts.suppressSound then
        self:PlayConfiguredSound(soundValue, soundProfile.volume)
    end
end

function WhisperToast:ShowTestToastByType(msgType, suppressSound, forceLock)
    msgType = msgType or self.previewLockType or "WHISPER"
    local sender = PREVIEW_SENDERS[msgType] or PREVIEW_SENDERS.WHISPER
    local previewUnit = nil
    local playerName, playerRealm = UnitFullName("player")
    if playerName and playerName ~= "" then
        sender = playerName
        if playerRealm and playerRealm ~= "" then
            sender = sender .. "-" .. playerRealm
        end
        previewUnit = "player"
    end
    local message = L["PREVIEW_MESSAGE"] or "This is a preview notification."
    local suppress = suppressSound and true or false
    local lockPreview = forceLock or self.previewLockActive
    self.previewLockType = msgType
    local opts = { suppressSound = suppress, previewUnit = previewUnit, allowSelf = true }
    if lockPreview then
        opts.previewLock = true
        opts.previewLockType = msgType
    end
    self:HandleChatMessage(msgType, message, sender, opts)
end

function WhisperToast:SchedulePreview(msgType)
    if not self:IsEnabled() then return end
    if self.previewLockActive then
        if previewTimer then
            previewTimer:Cancel()
            previewTimer = nil
        end
        local previewType = msgType or self.previewLockType or "WHISPER"
        self:ShowTestToastByType(previewType, true, true)
        return
    end
    if previewTimer then
        previewTimer:Cancel()
        previewTimer = nil
    end
    previewTimer = C_Timer.NewTimer(0.15, function()
        WhisperToast:ShowTestToastByType(msgType or "WHISPER", true)
    end)
end

function WhisperToast:EnsurePreviewLock(msgType)
    msgType = msgType or self.previewLockType or "WHISPER"
    if self.previewLockActive then
        if msgType then
            self.previewLockType = msgType
        end
        self:RefreshPreviewLock()
        return true
    end
    if self.previewLockSuppressed then
        return false
    end
    if not self.previewLockActive then
        self:SetPreviewLock(true, msgType, "auto")
    else
        if not self.previewLockToast or not self.previewLockToast:IsShown() then
            self:ShowTestToastByType(msgType, true, true)
        end
    end
    return true
end

function WhisperToast:ClearPreviewLock()
    if self.previewLockToast then
        local toast = self.previewLockToast
        self.previewLockToast = nil
        toast.previewLock = nil
        toast.previewUnit = nil
        toast:Hide()
        self:HideAnimatedPortrait(toast)
        for i = #activeToasts, 1, -1 do
            if activeToasts[i] == toast then
                table.remove(activeToasts, i)
                break
            end
        end
        self:UpdateToastPositions()
    end
end

function WhisperToast:SetPreviewLock(enabled, msgType, source)
    if enabled then
        if source == "user" then
            self.previewLockSuppressed = false
        end
        self.previewLockActive = true
        self.previewLockType = msgType or self.previewLockType or "WHISPER"
        self.previewLockAuto = source ~= "user"
        if previewTimer then
            previewTimer:Cancel()
            previewTimer = nil
        end
        self:ShowTestToastByType(self.previewLockType, true, true)
    else
        if source == "user" then
            self.previewLockSuppressed = true
        end
        self.previewLockActive = false
        self.previewLockType = msgType or self.previewLockType or "WHISPER"
        self.previewLockAuto = false
        if previewTimer then
            previewTimer:Cancel()
            previewTimer = nil
        end
        self:ClearPreviewLock()
    end
    local registry = LibStub("AceConfigRegistry-3.0", true)
    if registry then
        registry:NotifyChange("WhisperToast")
    end
end

function WhisperToast:RefreshPreviewLock()
    if self.previewLockActive then
        self:ShowTestToastByType(self.previewLockType or "WHISPER", true, true)
    end
end

function WhisperToast:SetupPreviewLockHooks()
    if self.previewLockHooked then
        return
    end
    local function hookFrame(frame)
        if frame and not frame.WhisperToastPreviewHooked then
            frame:HookScript("OnHide", function()
                if WhisperToast.previewLockActive then
                    WhisperToast:SetPreviewLock(false, nil, "auto")
                end
            end)
            frame.WhisperToastPreviewHooked = true
        end
    end
    hookFrame(InterfaceOptionsFrame)
    if SettingsPanel then
        hookFrame(SettingsPanel)
    end
    self.previewLockHooked = true
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
                local label
                if data.labelKey then
                    local localeString = L[data.labelKey]
                    if type(localeString) == "string" then
                        if data.labelArg ~= nil then
                            label = string.format(localeString, data.labelArg)
                        else
                            label = localeString
                        end
                    end
                end
                list[key] = label or data.label or key
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
    local notificationSpecs = {
        {
            order = 3,
            flag = "whispers",
            toggleKey = "WHISPER_TOGGLE",
            toggleFallback = "Whispers & BNet",
            toggleDescKey = "WHISPER_DESC",
            toggleDescFallback = "Show whisper notifications",
            toggleWidth = 1.5,
            defaultTestType = "WHISPER",
            tests = {
                {
                    msgType = "WHISPER",
                    labelKey = "BTN_TEST_WHISPER",
                    labelFallback = "Test",
                    descKey = "BTN_TEST_WHISPER_DESC",
                    descFallback = "Preview a sample notification.",
                    width = "half",
                },
                {
                    msgType = "BN",
                    labelKey = "BTN_TEST_BN",
                    labelFallback = "Test",
                    descKey = "BTN_TEST_BN_DESC",
                    descFallback = "Preview a sample notification.",
                    width = "half",
                },
            },
        },
        {
            order = 4,
            flag = "guild",
            toggleKey = "GUILD_TOGGLE",
            toggleFallback = "Guild",
            toggleDescKey = "GUILD_DESC",
            toggleDescFallback = "Show guild notifications",
            toggleWidth = 1.5,
            defaultTestType = "GUILD",
            tests = {
                {
                    msgType = "GUILD",
                    labelKey = "BTN_TEST_GUILD",
                    labelFallback = "Test",
                    descKey = "BTN_TEST_GUILD_DESC",
                    descFallback = "Preview a sample notification.",
                    width = "half",
                },
            },
        },
        {
            order = 5,
            flag = "party",
            toggleKey = "PARTY_TOGGLE",
            toggleFallback = "Party",
            toggleDescKey = "PARTY_DESC",
            toggleDescFallback = "Show party notifications",
            toggleWidth = 1.5,
            defaultTestType = "PARTY",
            tests = {
                {
                    msgType = "PARTY",
                    labelKey = "BTN_TEST_PARTY",
                    labelFallback = "Test",
                    descKey = "BTN_TEST_PARTY_DESC",
                    descFallback = "Preview a sample notification.",
                    width = "half",
                },
            },
        },
        {
            order = 6,
            flag = "raid",
            toggleKey = "RAID_TOGGLE",
            toggleFallback = "Raid",
            toggleDescKey = "RAID_DESC",
            toggleDescFallback = "Show raid notifications",
            toggleWidth = 1.5,
            defaultTestType = "RAID",
            tests = {
                {
                    msgType = "RAID",
                    labelKey = "BTN_TEST_RAID",
                    labelFallback = "Test",
                    descKey = "BTN_TEST_RAID_DESC",
                    descFallback = "Preview a sample notification.",
                    width = "half",
                },
            },
        },
    }
    local notificationArgs = {}
    for _, spec in ipairs(notificationSpecs) do
        local previewType = spec.defaultTestType
        if not previewType and spec.tests and spec.tests[1] then
            previewType = spec.tests[1].msgType
        end

        local toggleOrder = spec.order
        notificationArgs[#notificationArgs + 1] = {
            key = string.format("%sToggle", spec.flag),
            order = toggleOrder,
            value = {
                order = toggleOrder,
                type = "toggle",
                width = spec.toggleWidth or "half",
                name = L[spec.toggleKey] or spec.toggleFallback,
                desc = L[spec.toggleDescKey] or spec.toggleDescFallback,
                get = function()
                    return self.db.profile[spec.flag]
                end,
                set = function(_, value)
                    self.db.profile[spec.flag] = value
                    local testType = previewType
                    if value and testType and not self.previewLockSuppressed then
                        self:SetPreviewLock(true, testType, "auto")
                    end
                end,
            },
        }

        if spec.tests then
            for index, test in ipairs(spec.tests) do
                local testInfo = test
                local key = string.format("%sTestButton%d", spec.flag, index)
                local order = spec.order + index * 0.01
                notificationArgs[#notificationArgs + 1] = {
                    key = key,
                    order = order,
                    value = {
                        order = order,
                        type = "execute",
                        width = testInfo.width or "half",
                        name = L[testInfo.labelKey] or testInfo.labelFallback,
                        desc = L[testInfo.descKey] or testInfo.descFallback,
                        func = function()
                            local lock = self.previewLockActive
                            self:ShowTestToastByType(testInfo.msgType, lock, lock)
                        end,
                        disabled = function()
                            return not self.db.profile[spec.flag]
                        end,
                    },
                }
            end
        end

        notificationArgs[#notificationArgs + 1] = {
            key = string.format("%sSpacer", spec.flag),
            order = spec.order + 0.09,
            value = {
                order = spec.order + 0.09,
                type = "description",
                name = " ",
                width = "full",
            },
        }
    end
    local options = { 
        name = L["OPTIONS_TITLE"] or "WhisperToast", 
        type = "group", 
        args = {
            desc = { order = 1, type = "description", name = L["OPTIONS_DESC"] or "WhisperToast Settings" },
            notifHeader = { order = 2, type = "header", name = L["SECTION_NOTIFICATIONS"] or "Notification Types" },
            appearanceHeader = { order = 10, type = "header", name = L["SECTION_APPEARANCE"] or "Appearance" },
            width = { order = 11, type = "range", name = L["WIDTH"] or "Width", min = 200, max = 500, step = 10, get = function() return self.db.profile.appearance.width end, set = function(_, v) self.db.profile.appearance.width = v; if anchor then anchor:SetSize(v, self.db.profile.appearance.height) end; self:EnsurePreviewLock() end },
            height = { order = 12, type = "range", name = L["HEIGHT"] or "Height", min = 60, max = 150, step = 5, get = function() return self.db.profile.appearance.height end, set = function(_, v) self.db.profile.appearance.height = v; if anchor then anchor:SetSize(self.db.profile.appearance.width, v) end; self:EnsurePreviewLock() end },
            maxChars = { order = 13, type = "range", name = L["MAX_CHARS"] or "Max Characters", desc = L["MAX_CHARS_DESC"] or "Maximum characters displayed", min = 50, max = 500, step = 10, width = "full", get = function() return self.db.profile.appearance.maxChars end, set = function(_, v) self.db.profile.appearance.maxChars = v; self:EnsurePreviewLock() end },
            livePreview = { order = 13.5, type = "toggle", name = L["LIVE_PREVIEW"] or "Keep Preview Visible", desc = L["LIVE_PREVIEW_DESC"] or "Keep a test toast visible while adjusting offsets. Automatically hides when you close the options window.", width = "full", get = function() return self.previewLockActive end, set = function(_, value) self:SetPreviewLock(value, self.previewLockType or "WHISPER", "user") end },
            titleOffsetX = { order = 14, type = "range", name = L["TITLE_OFFSET_X"] or "Title Offset X", desc = L["TITLE_OFFSET_X_DESC"] or "Move the title text horizontally", min = -100, max = 100, step = 1, get = function() return self.db.profile.appearance.titleOffsetX end, set = function(_, v) self.db.profile.appearance.titleOffsetX = v; self:EnsurePreviewLock() end },
            titleOffsetY = { order = 15, type = "range", name = L["TITLE_OFFSET_Y"] or "Title Offset Y", desc = L["TITLE_OFFSET_Y_DESC"] or "Move the title text vertically", min = -100, max = 100, step = 1, get = function() return self.db.profile.appearance.titleOffsetY end, set = function(_, v) self.db.profile.appearance.titleOffsetY = v; self:EnsurePreviewLock() end },
            portraitOffsetX = { order = 16, type = "range", name = L["PORTRAIT_OFFSET_X"] or "Portrait Offset X", desc = L["PORTRAIT_OFFSET_X_DESC"] or "Move the portrait/icon mask horizontally", min = -100, max = 100, step = 1, get = function() return self.db.profile.appearance.portraitOffsetX end, set = function(_, v) self.db.profile.appearance.portraitOffsetX = v; self:EnsurePreviewLock() end },
            portraitOffsetY = { order = 17, type = "range", name = L["PORTRAIT_OFFSET_Y"] or "Portrait Offset Y", desc = L["PORTRAIT_OFFSET_Y_DESC"] or "Move the portrait/icon mask vertically", min = -100, max = 100, step = 1, get = function() return self.db.profile.appearance.portraitOffsetY end, set = function(_, v) self.db.profile.appearance.portraitOffsetY = v; self:EnsurePreviewLock() end },
            iconOffsetX = { order = 18, type = "range", name = L["ICON_OFFSET_X"] or "Icon Offset X", desc = L["ICON_OFFSET_X_DESC"] or "Move the icon horizontally", min = -100, max = 100, step = 1, get = function() return self.db.profile.appearance.iconOffsetX end, set = function(_, v) self.db.profile.appearance.iconOffsetX = v; self:EnsurePreviewLock() end },
            iconOffsetY = { order = 19, type = "range", name = L["ICON_OFFSET_Y"] or "Icon Offset Y", desc = L["ICON_OFFSET_Y_DESC"] or "Move the icon vertically", min = -100, max = 100, step = 1, get = function() return self.db.profile.appearance.iconOffsetY end, set = function(_, v) self.db.profile.appearance.iconOffsetY = v; self:EnsurePreviewLock() end },
            colorHeader = { order = 20, type = "header", name = L["SECTION_COLORS"] or "Colors" },
            bgColor = { order = 21, type = "color", name = L["BG_COLOR"] or "Cor de Fundo", desc = L["BG_COLOR_DESC"] or "Cor do fundo da notificação", hasAlpha = true, get = function() local c = self.db.profile.appearance.bgColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.bgColor = {r=r, g=g, b=b, a=a}; self:EnsurePreviewLock() end },
            borderColor = { order = 22, type = "color", name = L["BORDER_COLOR"] or "Cor da Borda", desc = L["BORDER_COLOR_DESC"] or "Cor da borda e efeitos brilhantes", hasAlpha = true, get = function() local c = self.db.profile.appearance.borderColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.borderColor = {r=r, g=g, b=b, a=a}; self:EnsurePreviewLock() end },
            titleColor = { order = 23, type = "color", name = L["TITLE_COLOR"] or "Cor do Título", desc = L["TITLE_COLOR_DESC"] or "Cor padrão do título", hasAlpha = true, get = function() local c = self.db.profile.appearance.titleColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.titleColor = {r=r, g=g, b=b, a=a}; self:EnsurePreviewLock() end },
            textColor = { order = 24, type = "color", name = L["TEXT_COLOR"] or "Cor do Texto", desc = L["TEXT_COLOR_DESC"] or "Cor do texto da mensagem", hasAlpha = true, get = function() local c = self.db.profile.appearance.textColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.textColor = {r=r, g=g, b=b, a=a}; self:EnsurePreviewLock() end },
            colorTitleHeader = { order = 25, type = "header", name = L["SECTION_COLORS_CHAT"] or "Cores por Tipo de Chat" },
            whisperColor = { order = 26, type = "color", name = L["WHISPER_COLOR"] or "Cor do Sussurro", desc = L["WHISPER_COLOR_DESC"] or "Cor do nome em sussurros", hasAlpha = true, get = function() local c = self.db.profile.appearance.whisperColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.whisperColor = {r=r, g=g, b=b, a=a}; self:EnsurePreviewLock() end },
            bnetColor = { order = 27, type = "color", name = L["BNET_COLOR"] or "Cor do Battle.net", desc = L["BNET_COLOR_DESC"] or "Cor do nome em Battle.net", hasAlpha = true, get = function() local c = self.db.profile.appearance.bnetColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.bnetColor = {r=r, g=g, b=b, a=a}; self:EnsurePreviewLock() end },
            guildColor = { order = 28, type = "color", name = L["GUILD_COLOR"] or "Cor da Guilda", desc = L["GUILD_COLOR_DESC"] or "Cor do nome em guilda", hasAlpha = true, get = function() local c = self.db.profile.appearance.guildColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.guildColor = {r=r, g=g, b=b, a=a}; self:EnsurePreviewLock() end },
            partyColor = { order = 29, type = "color", name = L["PARTY_COLOR"] or "Cor do Grupo", desc = L["PARTY_COLOR_DESC"] or "Cor do nome em grupo", hasAlpha = true, get = function() local c = self.db.profile.appearance.partyColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.partyColor = {r=r, g=g, b=b, a=a}; self:EnsurePreviewLock() end },
            raidColor = { order = 30, type = "color", name = L["RAID_COLOR"] or "Cor da Raide", desc = L["RAID_COLOR_DESC"] or "Cor do nome em raide", hasAlpha = true, get = function() local c = self.db.profile.appearance.raidColor; return c.r, c.g, c.b, c.a end, set = function(_, r, g, b, a) self.db.profile.appearance.raidColor = {r=r, g=g, b=b, a=a}; self:EnsurePreviewLock() end },
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
            showPortrait = {
                order = 52,
                type = "toggle",
                name = L["SHOW_PORTRAIT"] or "Mostrar Retrato",
                desc = L["SHOW_PORTRAIT_DESC"] or "Exibir retrato",
                width = "full",
                get = function()
                    return self.db.profile.behavior.showPortrait
                end,
                set = function(_, v)
                    self.db.profile.behavior.showPortrait = v
                    if not v then
                        self:SetPreviewLock(false, nil, "auto")
                    else
                        self:RefreshPreviewLock()
                    end
                end,
            },
            animatedPortrait = {
                order = 53,
                type = "toggle",
                name = L["ANIMATED_PORTRAIT"] or "Animated Portrait",
                desc = L["ANIMATED_PORTRAIT_DESC"] or "Use a 3D animated portrait when possible (self or group).",
                width = "full",
                disabled = function()
                    return not self.db.profile.behavior.showPortrait
                end,
                get = function()
                    return self.db.profile.behavior.animatedPortrait
                end,
                set = function(_, v)
                    self.db.profile.behavior.animatedPortrait = v and true or false
                    self:RefreshPreviewLock()
                end,
            },
            ignoreSelf = {
                order = 54,
                type = "toggle",
                name = L["IGNORE_SELF"] or "Ignore Own Messages",
                desc = L["IGNORE_SELF_DESC"] or "Do not show notifications for messages you send.",
                width = "full",
                get = function()
                    return self.db.profile.behavior.ignoreSelf
                end,
                set = function(_, v)
                    self.db.profile.behavior.ignoreSelf = v and true or false
                end,
            },
            posHeader = { order = 60, type = "header", name = L["SECTION_POSITION"] or "Positioning" },
            move = { order = 61, type = "execute", name = L["BTN_MOVE"] or "Mover Âncora", desc = L["BTN_MOVE_DESC"] or "Mostra âncora animada", func = function() if anchor:IsShown() then anchor:Hide() else anchor:Show() end end },
            reset = { order = 63, type = "execute", name = L["BTN_RESET_POS"] or "Resetar Posição", desc = L["BTN_RESET_POS_DESC"] or "Volta ao centro", func = function() self.db.profile.anchor = { point = "TOP", x = 0, y = -200 }; if anchor then anchor:ClearAllPoints(); anchor:SetPoint("TOP", UIParent, "TOP", 0, -200) end; self:Print(L["POS_RESET"] or "Position reset") end },
            resetAll = { order = 64, type = "execute", name = L["BTN_RESET_ALL"] or "Resetar Tudo", desc = L["BTN_RESET_ALL_DESC"] or "Restaura tudo", confirm = true, confirmText = L["BTN_RESET_CONFIRM"] or "Reset ALL?", func = function() self.db:ResetProfile(); ReloadUI() end }
        }
    }  
    table.sort(notificationArgs, function(a, b) return a.order < b.order end)
    for _, entry in ipairs(notificationArgs) do
        options.args[entry.key] = entry.value
    end
    LibStub("AceConfig-3.0"):RegisterOptionsTable("WhisperToast", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WhisperToast", L["OPTIONS_TITLE"] or "WhisperToast")
    self:SetupPreviewLockHooks()
end










