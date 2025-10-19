-- core.lua (VERSÃO COMPLETA E FINAL)

local addonName, addon = ...
WhisperToast = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local L = WhisperToast_Locale or {}
local TOAST_SPACING = 15

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
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_BN_WHISPER")
    self:RegisterEvent("CHAT_MSG_GUILD")
    self:RegisterEvent("CHAT_MSG_PARTY")
    self:RegisterEvent("CHAT_MSG_PARTY_LEADER")
    self:RegisterEvent("CHAT_MSG_RAID")
    self:RegisterEvent("CHAT_MSG_RAID_LEADER")
    self:RegisterEvent("CHAT_MSG_RAID_WARNING")
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
    
    local showPortrait = self.db.profile.behavior.showPortrait
    if showPortrait and sender then
        if string.find(sender, "#") then
            -- Battle.net - usar ícone
            toast.Icon:SetTexture(icon)
            toast.Icon:Show()
            toast.Portrait:Hide()
        else
            -- Jogador WoW - tentar várias formas
            local portraitSet = false
            
            -- Tentativa 1: Usar nome original (com realm se tiver)
            local success = pcall(function() SetPortraitTexture(toast.Portrait, sender) end)
            if success and toast.Portrait:GetTexture() and toast.Portrait:GetTexture() ~= 0 then
                portraitSet = true
            end
            
            -- Tentativa 2: Se não funcionou, tentar adicionar o realm do jogador
            if not portraitSet then
                local playerRealm = GetRealmName()
                local senderWithRealm = sender .. "-" .. playerRealm
                success = pcall(function() SetPortraitTexture(toast.Portrait, senderWithRealm) end)
                if success and toast.Portrait:GetTexture() and toast.Portrait:GetTexture() ~= 0 then
                    portraitSet = true
                end
            end
            
            -- Tentativa 3: Tentar apenas o nome sem realm
            if not portraitSet then
                local cleanName = sender:gsub("%-.*$", "")
                success = pcall(function() SetPortraitTexture(toast.Portrait, cleanName) end)
                if success and toast.Portrait:GetTexture() and toast.Portrait:GetTexture() ~= 0 then
                    portraitSet = true
                end
            end
            
            -- Tentativa 4: Buscar na lista de amigos usando C_FriendList
            if not portraitSet and C_FriendList then
                local cleanName = sender:gsub("%-.*$", "")
                local numFriends = C_FriendList.GetNumFriends()
                for i = 1, numFriends do
                    local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
                    if friendInfo and friendInfo.name then
                        local friendCleanName = friendInfo.name:gsub("%-.*$", "")
                        if friendCleanName == cleanName then
                            -- Tentar com o nome completo do amigo
                            success = pcall(function() SetPortraitTexture(toast.Portrait, friendInfo.name) end)
                            if success and toast.Portrait:GetTexture() and toast.Portrait:GetTexture() ~= 0 then
                                portraitSet = true
                                break
                            end
                        end
                    end
                end
            end
            
            -- Tentativa 5: Buscar em grupo/raide
            if not portraitSet then
                local cleanName = sender:gsub("%-.*$", "")
                
                -- Verificar em raide
                if IsInRaid() then
                    for i = 1, GetNumGroupMembers() do
                        local name = GetRaidRosterInfo(i)
                        if name and name:gsub("%-.*$", "") == cleanName then
                            success = pcall(function() SetPortraitTexture(toast.Portrait, name) end)
                            if success and toast.Portrait:GetTexture() and toast.Portrait:GetTexture() ~= 0 then
                                portraitSet = true
                                break
                            end
                        end
                    end
                end
                
                -- Verificar em grupo
                if not portraitSet and IsInGroup() then
                    for i = 1, GetNumSubgroupMembers() do
                        local unit = "party" .. i
                        local name = UnitName(unit)
                        if name and name:gsub("%-.*$", "") == cleanName then
                            -- Usar a unit diretamente é mais confiável
                            success = pcall(function() SetPortraitTexture(toast.Portrait, unit) end)
                            if success and toast.Portrait:GetTexture() and toast.Portrait:GetTexture() ~= 0 then
                                portraitSet = true
                                break
                            end
                        end
                    end
                end
                
                -- Verificar o próprio jogador
                if not portraitSet and UnitName("player"):gsub("%-.*$", "") == cleanName then
                    success = pcall(function() SetPortraitTexture(toast.Portrait, "player") end)
                    if success and toast.Portrait:GetTexture() and toast.Portrait:GetTexture() ~= 0 then
                        portraitSet = true
                    end
                end
            end
            
            -- Aplicar resultado
            if portraitSet then
                toast.Portrait:Show()
                toast.Icon:Hide()
            else
                -- Buscar ícone de classe como fallback
                local classIcon = self:GetClassIconForPlayer(sender)
                if classIcon then
                    toast.Icon:SetTexture(classIcon)
                else
                    toast.Icon:SetTexture(icon)
                end
                toast.Icon:Show()
                toast.Portrait:Hide()
            end
        end
    else
        toast.Icon:SetTexture(icon)
        toast.Icon:Show()
        toast.Portrait:Hide()
    end
    
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
    local cleanName = playerName:gsub("%-.*$", "")
    
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

function WhisperToast:UpdateToastPositions()
    local height = self.db.profile.appearance.height
    for i, toast in ipairs(activeToasts) do 
        toast.targetY = -((i - 1) * (height + TOAST_SPACING))
    end
end

function WhisperToast:CHAT_MSG_WHISPER(event, message, sender) self:HandleChatMessage("WHISPER", message, sender) end
function WhisperToast:CHAT_MSG_BN_WHISPER(event, message, sender) self:HandleChatMessage("BN", message, sender) end
function WhisperToast:CHAT_MSG_GUILD(event, message, sender) self:HandleChatMessage("GUILD", message, sender) end
function WhisperToast:CHAT_MSG_PARTY(event, message, sender) self:HandleChatMessage("PARTY", message, sender) end
function WhisperToast:CHAT_MSG_PARTY_LEADER(event, message, sender) self:HandleChatMessage("PARTY", message, sender) end
function WhisperToast:CHAT_MSG_RAID(event, message, sender) self:HandleChatMessage("RAID", message, sender) end
function WhisperToast:CHAT_MSG_RAID_LEADER(event, message, sender) self:HandleChatMessage("RAID", message, sender) end
function WhisperToast:CHAT_MSG_RAID_WARNING(event, message, sender) self:HandleChatMessage("RAID", message, sender) end

function WhisperToast:HandleChatMessage(msgType, message, sender)
    local senderName = sender and sender:gsub("%-.*$", "") or "?"
    local cfg = self.db.profile
    local icon, title, sound, titleColor, soundEnabled
    if msgType == "WHISPER" and cfg.whispers then 
        title = string.format(L["WHISPER_TITLE"] or "%s (Whisper):", senderName)
        icon = "Interface\\FriendsFrame\\Battlenet-Icon"
        sound = cfg.sound.whisperSound
        soundEnabled = cfg.sound.whisperSoundEnabled
        titleColor = cfg.appearance.whisperColor
    elseif msgType == "BN" and cfg.whispers then 
        title = string.format(L["BNET_TITLE"] or "%s (BNet):", senderName)
        icon = "Interface\\FriendsFrame\\Battlenet-Icon"
        sound = cfg.sound.whisperSound
        soundEnabled = cfg.sound.whisperSoundEnabled
        titleColor = cfg.appearance.bnetColor
    elseif msgType == "GUILD" and cfg.guild then 
        title = string.format(L["GUILD_TITLE"] or "%s (Guild):", senderName)
        icon = "Interface\\CHATFRAME\\UI-ChatIcon-WoW"
        sound = cfg.sound.guildSound
        soundEnabled = cfg.sound.guildSoundEnabled
        titleColor = cfg.appearance.guildColor
    elseif msgType == "PARTY" and cfg.party then 
        title = string.format(L["PARTY_TITLE"] or "%s (Party):", senderName)
        icon = "Interface\\GROUPFRAME\\UI-Group-Icon"
        sound = cfg.sound.partySound
        soundEnabled = cfg.sound.partySoundEnabled
        titleColor = cfg.appearance.partyColor
    elseif msgType == "RAID" and cfg.raid then 
        title = string.format(L["RAID_TITLE"] or "%s (Raid):", senderName)
        icon = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8"
        sound = cfg.sound.raidSound
        soundEnabled = cfg.sound.raidSoundEnabled
        titleColor = cfg.appearance.raidColor
    end
    if title then 
        self:Show(icon, title, message, sender, titleColor)
        if sound and cfg.sound.enabled and soundEnabled then PlaySound(sound, cfg.sound.volume) end
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
        return list
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
            whisperSoundGroup = {
                order = 39,
                type = "group",
                inline = true,
                name = L["SOUND_WHISPER"] or "Whisper Sound",
                args = {
                    whisperSoundEnabled = { order = 1, type = "toggle", width = "full", name = L["SOUND_WHISPER_TOGGLE"] or "Som de Sussurro", desc = L["SOUND_WHISPER_TOGGLE_DESC"] or "Ativar som para sussurros", get = function() return self.db.profile.sound.whisperSoundEnabled end, set = function(_, v) self.db.profile.sound.whisperSoundEnabled = v end },
                    whisperSound = { order = 2, type = "select", width = "full", name = L["SOUND_WHISPER_SELECT"] or "Escolher Som (Sussurro)", desc = L["SOUND_WHISPER_SELECT_DESC"] or "Clique para prévia", values = GetSoundList(), get = function() return tostring(self.db.profile.sound.whisperSound) end, set = function(_, v) self.db.profile.sound.whisperSound = tonumber(v); PlaySound(tonumber(v), self.db.profile.sound.volume) end },
                },
            },
            guildSoundGroup = {
                order = 40,
                type = "group",
                inline = true,
                name = L["SOUND_GUILD"] or "Guild Sound",
                args = {
                    guildSoundEnabled = { order = 1, type = "toggle", width = "full", name = L["SOUND_GUILD_TOGGLE"] or "Som de Guilda", desc = L["SOUND_GUILD_TOGGLE_DESC"] or "Ativar som para guilda", get = function() return self.db.profile.sound.guildSoundEnabled end, set = function(_, v) self.db.profile.sound.guildSoundEnabled = v end },
                    guildSound = { order = 2, type = "select", width = "full", name = L["SOUND_GUILD_SELECT"] or "Escolher Som (Guilda)", desc = L["SOUND_GUILD_SELECT_DESC"] or "Clique para prévia", values = GetSoundList(), get = function() return tostring(self.db.profile.sound.guildSound) end, set = function(_, v) self.db.profile.sound.guildSound = tonumber(v); PlaySound(tonumber(v), self.db.profile.sound.volume) end },
                },
            },
            partySoundGroup = {
                order = 41,
                type = "group",
                inline = true,
                name = L["SOUND_PARTY"] or "Party Sound",
                args = {
                    partySoundEnabled = { order = 1, type = "toggle", width = "full", name = L["SOUND_PARTY_TOGGLE"] or "Som de Grupo", desc = L["SOUND_PARTY_TOGGLE_DESC"] or "Ativar som para grupo", get = function() return self.db.profile.sound.partySoundEnabled end, set = function(_, v) self.db.profile.sound.partySoundEnabled = v end },
                    partySound = { order = 2, type = "select", width = "full", name = L["SOUND_PARTY_SELECT"] or "Escolher Som (Grupo)", desc = L["SOUND_PARTY_SELECT_DESC"] or "Clique para prévia", values = GetSoundList(), get = function() return tostring(self.db.profile.sound.partySound) end, set = function(_, v) self.db.profile.sound.partySound = tonumber(v); PlaySound(tonumber(v), self.db.profile.sound.volume) end },
                },
            },
            raidSoundGroup = {
                order = 42,
                type = "group",
                inline = true,
                name = L["SOUND_RAID"] or "Raid Sound",
                args = {
                    raidSoundEnabled = { order = 1, type = "toggle", width = "full", name = L["SOUND_RAID_TOGGLE"] or "Som de Raide", desc = L["SOUND_RAID_TOGGLE_DESC"] or "Ativar som para raide", get = function() return self.db.profile.sound.raidSoundEnabled end, set = function(_, v) self.db.profile.sound.raidSoundEnabled = v end },
                    raidSound = { order = 2, type = "select", width = "full", name = L["SOUND_RAID_SELECT"] or "Escolher Som (Raide)", desc = L["SOUND_RAID_SELECT_DESC"] or "Clique para prévia", values = GetSoundList(), get = function() return tostring(self.db.profile.sound.raidSound) end, set = function(_, v) self.db.profile.sound.raidSound = tonumber(v); PlaySound(tonumber(v), self.db.profile.sound.volume) end },
                },
            },
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

