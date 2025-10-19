-- Verificação de segurança
if not WhisperToast then return end

function WhisperToast:CreateToastFrame()
    -- Verificação adicional
    if not self or not self.db or not self.db.profile or not self.db.profile.appearance then
        self:Print("|cffff0000Erro: Configurações não carregadas. Tente /reload|r")
        return nil
    end
    
    local app = self.db.profile.appearance
    
    local toastFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    toastFrame:SetSize(app.width, app.height)
    toastFrame:SetFrameStrata("DIALOG")
    toastFrame:SetFrameLevel(100)
    
    -- Background com cores personalizáveis
    toastFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    toastFrame:SetBackdropColor(app.bgColor.r, app.bgColor.g, app.bgColor.b, app.bgColor.a)
    toastFrame:SetBackdropBorderColor(app.borderColor.r, app.borderColor.g, app.borderColor.b, app.borderColor.a)
    
    -- Glow effect superior
    local topGlow = toastFrame:CreateTexture(nil, "BACKGROUND")
    topGlow:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Glow")
    topGlow:SetPoint("TOP", 0, 8)
    topGlow:SetSize(app.width + 20, 40)
    topGlow:SetBlendMode("ADD")
    topGlow:SetAlpha(0.5)
    topGlow:SetVertexColor(app.borderColor.r, app.borderColor.g, app.borderColor.b)
    
    -- Linha decorativa superior
    local topLine = toastFrame:CreateTexture(nil, "ARTWORK")
    topLine:SetColorTexture(app.borderColor.r, app.borderColor.g, app.borderColor.b, 0.8)
    topLine:SetPoint("TOPLEFT", 5, -5)
    topLine:SetPoint("TOPRIGHT", -5, -5)
    topLine:SetHeight(2)
    toastFrame.TopLine = topLine
    
    -- RETRATO (opcional)
    local portrait = toastFrame:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(app.height - 16, app.height - 16)
    portrait:SetPoint("LEFT", 8, 0)
    
    local portraitMask = toastFrame:CreateMaskTexture(nil, "ARTWORK")
    portraitMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    portraitMask:SetAllPoints(portrait)
    portrait:AddMaskTexture(portraitMask)
    
    local portraitBorder = toastFrame:CreateTexture(nil, "OVERLAY")
    portraitBorder:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
    portraitBorder:SetSize(app.height - 8, app.height - 8)
    portraitBorder:SetPoint("CENTER", portrait, "CENTER", 0, 0)
    portraitBorder:SetBlendMode("ADD")
    portraitBorder:SetAlpha(0.3)
    portraitBorder:SetVertexColor(app.borderColor.r, app.borderColor.g, app.borderColor.b)
    
    toastFrame.Portrait = portrait
    portrait:Hide() -- Escondido por padrão
    
    -- Ícone (quando não usar retrato)
    local toastIcon = toastFrame:CreateTexture(nil, "ARTWORK")
    toastIcon:SetSize(app.height - 24, app.height - 24)
    toastIcon:SetPoint("LEFT", 12, 0)
    
    local iconMask = toastFrame:CreateMaskTexture(nil, "ARTWORK")
    iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    iconMask:SetAllPoints(toastIcon)
    toastIcon:AddMaskTexture(iconMask)
    toastFrame.Icon = toastIcon
    
    -- Brilho ao redor do ícone
    local iconGlow = toastFrame:CreateTexture(nil, "ARTWORK")
    iconGlow:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
    iconGlow:SetSize(app.height - 12, app.height - 12)
    iconGlow:SetPoint("CENTER", toastIcon, "CENTER", 0, 0)
    iconGlow:SetBlendMode("ADD")
    iconGlow:SetAlpha(0.4)
    iconGlow:SetVertexColor(app.borderColor.r, app.borderColor.g, app.borderColor.b)
    
    -- Calcular posição do texto baseado no tamanho
    local iconSize = app.height - 24
    local textStartX = iconSize + 20
    
    -- Título (remetente) - REMOVIDA A COR FIXA
    local toastTitle = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toastTitle:SetPoint("TOPLEFT", textStartX, -8)
    toastTitle:SetPoint("RIGHT", toastFrame, -12, 0)
    toastTitle:SetJustifyH("LEFT")
    -- A cor será definida dinamicamente baseada no tipo de chat
    toastTitle:SetShadowColor(0, 0, 0, 1)
    toastTitle:SetShadowOffset(1, -1)
    toastFrame.Title = toastTitle
    
    -- Mensagem
    local toastMessage = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    toastMessage:SetPoint("TOPLEFT", toastTitle, "BOTTOMLEFT", 0, -4)
    toastMessage:SetPoint("BOTTOMRIGHT", toastFrame, -12, 12)
    toastMessage:SetJustifyH("LEFT")
    toastMessage:SetJustifyV("TOP")
    toastMessage:SetWordWrap(true)
    toastMessage:SetNonSpaceWrap(true)
    toastMessage:SetTextColor(app.textColor.r, app.textColor.g, app.textColor.b, app.textColor.a)
    toastMessage:SetShadowColor(0, 0, 0, 0.8)
    toastMessage:SetShadowOffset(1, -1)
    toastFrame.Message = toastMessage
    
    -- Barra de tempo
    local timerBg = toastFrame:CreateTexture(nil, "BACKGROUND")
    timerBg:SetColorTexture(0, 0, 0, 0.5)
    timerBg:SetPoint("BOTTOMLEFT", 5, 5)
    timerBg:SetPoint("BOTTOMRIGHT", -5, 5)
    timerBg:SetHeight(3)
    
    local timerBar = CreateFrame("StatusBar", nil, toastFrame)
    timerBar:SetPoint("BOTTOMLEFT", 5, 5)
    timerBar:SetPoint("BOTTOMRIGHT", -5, 5)
    timerBar:SetHeight(3)
    timerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    timerBar:GetStatusBarTexture():SetHorizTile(false)
    timerBar:GetStatusBarTexture():SetVertTile(false)
    timerBar:SetStatusBarColor(app.borderColor.r, app.borderColor.g, app.borderColor.b, 1)
    toastFrame.Timer = timerBar
    
    -- Botão de fechar
    local closeButton = CreateFrame("Button", nil, toastFrame)
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("TOPRIGHT", -4, -4)
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeButton:SetScript("OnClick", function()
        toastFrame.state = "fading_out"
        toastFrame.targetAlpha = 0
    end)
    
    -- Efeito hover
    toastFrame:EnableMouse(true)
    toastFrame:SetScript("OnEnter", function(self)
        local hoverBorder = app.borderColor
        self:SetBackdropBorderColor(
            math.min(hoverBorder.r + 0.2, 1), 
            math.min(hoverBorder.g + 0.2, 1), 
            math.min(hoverBorder.b + 0.2, 1), 
            1
        )
        topLine:SetColorTexture(
            math.min(hoverBorder.r + 0.2, 1), 
            math.min(hoverBorder.g + 0.2, 1), 
            math.min(hoverBorder.b + 0.2, 1), 
            1
        )
    end)
    toastFrame:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(app.borderColor.r, app.borderColor.g, app.borderColor.b, app.borderColor.a)
        topLine:SetColorTexture(app.borderColor.r, app.borderColor.g, app.borderColor.b, 0.8)
    end)
    
    toastFrame:Hide()
    return toastFrame
end