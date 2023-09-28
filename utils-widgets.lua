-- load pfUI environment
setfenv(1, pfUI:GetEnvironment())

local _, serialize, compress, decompress, enc, dec = unpack(UAPI)

local function CreateSliderFrame(name, parent, opts, func, cache)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    
    SkinSlider(slider)

    -- reset original property
    slider.tooltipText = opts.tips or ""
    slider.label       = opts.text or ""
    slider.key         = opts.key
    slider.enabled     = true

    -- value regular formatter
    slider.formatter   = format("%%.%df", strlen(({ strsplit(".", opts.step or "0.01") })[2] or ""))
    
    -- hook SetEnabled method
    slider.SetEnabled = function(self, enabled)
        if enabled then
            self:SetFrameStrata("DIALOG")
            self:GetThumbTexture():SetTexture(1, .82, 0)
            self.add:Enable()
            self.del:Enable()
        else
            self:SetFrameStrata("LOW")
            self:GetThumbTexture():SetTexture(.82, .82, .82)
            self.add:Disable()
            self.del:Disable()
        end
        
        self.enabled = enabled
    end

    -- opts.btn: -1 none, 0 del, 1 add, 2 both
    opts.btn = opts.btn or 2

    -- cache layers
    local regions = { slider:GetRegions() }
    slider.text = regions[1]  -- layer Text
    slider.low  = regions[2]  -- layer Low
    slider.high = regions[3]  -- layer High 

    slider.text:SetText(format("%s: " .. slider.formatter, opts.text, opts.val))
    slider.text:SetPoint("BOTTOM", slider, "TOP", 0, 5)
    slider.low:SetText(format(slider.formatter, opts.min or 0))
    slider.high:SetText(format(slider.formatter, opts.max or 1))

    slider:SetMinMaxValues(opts.min or 0, opts.max or 1)
    slider:SetValueStep(opts.step or 0.01)
    slider:SetValue(tonumber(opts.val))
    slider:SetWidth(opts.width or 180)
    slider:SetHeight(opts.height or 10)
    slider:SetFrameStrata(opts.strata or "DIALOG")
    slider:SetFrameLevel(opts.zlevel or 3)
    slider:SetPoint(opts.relto or "RIGHT", opts.ofx or (opts.btn >= 0 and -25 or -5), opts.ofy or 0)
    slider:SetScript("OnValueChanged", function ()
        local min, max = this:GetMinMaxValues()
        local val = tonumber(format(this.formatter, arg1))
        
        this.text:SetText(format("%s: " .. this.formatter, opts.text, val))
            
        if this.enabled then
            min = tonumber(format(this.formatter, min))
            max = tonumber(format(this.formatter, max))

            if val == min then
                this.del:Disable()
            elseif val == max then
                this.add:Disable()
            elseif val > min and val < max then
                if this.add:IsEnabled() == 0 then
                    this.add:Enable()
                end

                if this.del:IsEnabled() == 0 then
                    this.del:Enable()
                end
            end
            
            if opts.callback then 
                opts.callback(val) 
            else 
                this:GetParent().category[this:GetParent().config] = format(this.formatter, val) 
            end

            if func then func() else pfUI.gui.settingChanged = true end
        end
    end)

    -- minus button
    slider.del = CreateFrame("Button", nil, slider, "UIPanelButtonTemplate")

    SkinButton(slider.del)

    slider.del:SetWidth(16)
    slider.del:SetHeight(16)
    slider.del:SetPoint("RIGHT", slider, "LEFT", -5, 0)
    slider.del:GetFontString():SetPoint("CENTER", 1, 0)
    slider.del:SetText("-")
    slider.del:SetTextColor(1, .5, .5, 1)
    slider.del:Hide()
    slider.del:SetScript("OnMouseDown", function()
        this.elapsed = 0
        this.clicked = 1
    end)
    slider.del:SetScript("OnMouseUp", function()
        this.elapsed = nil

        if this.clicked == 1 then
            local parent = this:GetParent()
            
            parent:SetValue(parent:GetValue() - parent:GetValueStep())
        end
    end)
    slider.del:SetScript("OnUpdate", function()
        if this.elapsed then
            this.elapsed = this.elapsed + arg1 * this.clicked

            if this.elapsed >= 0.16 then
                local parent = this:GetParent()

                this.elapsed = 0
                this.clicked = this.clicked + 1
                parent:SetValue(parent:GetValue() - parent:GetValueStep())
            end
        end
    end)

    -- plus button
    slider.add = CreateFrame("Button", nil, slider, "UIPanelButtonTemplate")

    SkinButton(slider.add)

    slider.add:SetWidth(16)
    slider.add:SetHeight(16)
    slider.add:SetPoint("LEFT", slider, "RIGHT", 5, 0)
    slider.add:GetFontString():SetPoint("CENTER", 1, 0)
    slider.add:SetText("+")
    slider.add:SetTextColor(.5, 1, .5, 1)
    slider.add:Hide()
    slider.add:SetScript("OnMouseDown", function()
        this.elapsed = 0
        this.clicked = 1
    end)
    slider.add:SetScript("OnMouseUp", function()
        this.elapsed = nil

        if this.clicked == 1 then
            local parent = this:GetParent()
            
            parent:SetValue(parent:GetValue() + parent:GetValueStep())
        end
    end)
    slider.add:SetScript("OnUpdate", function()
        if this.elapsed then
            this.elapsed = this.elapsed + arg1 * this.clicked

            if this.elapsed >= 0.16 then
                local parent = this:GetParent()

                this.elapsed = 0
                this.clicked = this.clicked + 1
                parent:SetValue(parent:GetValue() + parent:GetValueStep())
            end
        end
    end)

    if opts.btn == 2 or opts.btn == 0 then
        slider.del:Show()
    end

    if opts.btn == 2 or opts.btn == 1 then
        slider.add:Show()
    end

    -- set disable state
    if opts.disable then
        slider:SetEnabled(false)
        slider.ref = opts.ref
    end

    -- set cache
    if type(cache) == "table" and opts.tab then
        cache[opts.tab] = cache[opts.tab] or {}
        table.insert(cache[opts.tab], slider)

        if opts.key then
            cache[opts.tab][opts.key] = slider
        end
    end
    
    -- hide shadows on wrong stratas
    if slider.backdrop_shadow then
        slider.backdrop_shadow:Hide()
    end

    return slider
end

local function CreateButtonxFrame(name, parent, opts, func, cache)
    local buttonx = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")

    CreateBackdrop(buttonx, nil, true)
    SkinButton(buttonx)

    buttonx:SetWidth(opts.width or 80)
    buttonx:SetHeight(opts.height or 20)
    buttonx:SetPoint("TOPRIGHT", opts.ofx or -2, opts.ofy or -1)
    buttonx:SetText(opts.text)
    buttonx:SetTextColor(1, 1, 1, 1)
    buttonx:SetScript("OnClick", opts.callback)

    -- set disable state
    if opts.disable then
        buttonx:Disable()
        buttonx.key = opts.key
    end

    -- set cache
    if type(cache) == "table" and opts.tab then
        cache[opts.tab] = cache[opts.tab] or {}
        table.insert(cache[opts.tab], buttonx)

        if opts.key then
            cache[opts.tab][opts.key] = buttonx
        end
    end

    -- hide shadows on wrong stratas
    if buttonx.backdrop_shadow then
        buttonx.backdrop_shadow:Hide()
    end

    return buttonx
end

local function CreateTextxFrame(name, parent, opts, func, cache)
    local input      = CreateFrame("EditBox", name, parent)
    local SetTextOld = input.SetText

    CreateBackdrop(input, nil, true)

    input.SetReadonly = function(self, readonly)
        self:SetFrameStrata(readonly and "LOW" or "DIALOG")
        self.readonly = readonly
    end
    input.SetText = function(self, text)
        local ratio = 7/12  -- 2/3
        -- local _, size = self:GetFont()
        local max   = tonumber(format("%d", self:GetWidth() / (({ self:GetFont() })[2] * ratio)))
        local text  = text or ""

        if strlen(text) <= max then
            SetTextOld(self, text)
        else
            SetTextOld(self, format("%s...", strsub(text, 1, max)))
        end
    end

    input:SetTextInsets(5, 5, 5, 5)
    input:SetTextColor(.2, 1, .8, 1)
    input:SetJustifyH(opts.align or "RIGHT")

    input:SetWidth(opts.width or 100)
    input:SetHeight(opts.height or 18)
    input:SetPoint("RIGHT", opts.ofx or -2, opts.ofy or 0)
    input:SetFontObject(GameFontNormal)
    input:SetAutoFocus(false)
    input:SetText(opts.text or "")

    if opts.readonly then
        input:SetReadonly(true)
    else
        input:SetScript("OnEscapePressed", function(self)
            this:ClearFocus()
        end)

        input:SetScript("OnTextChanged", function(self)
            if (opts.type and opts.type ~= "number") or tonumber(this:GetText()) then
                if this:GetText() ~= this:GetParent().category[this:GetParent().config] then
                    if opts.callback then 
                        opts.callback(this:GetText()) 
                    else
                        this:GetParent().category[this:GetParent().config] = this:GetText()
                    end
                    if func then func() else pfUI.gui.settingChanged = true end
                end
                this:SetTextColor(.2, 1, .8, 1)
            else
                this:SetTextColor(1, .3, .3, 1)
            end
        end)
    end

    -- set cache
    if type(cache) == "table" and opts.key then
        cache[opts.key] = input
    end

    -- hide shadows on wrong stratas
    if input.backdrop_shadow then
        input.backdrop_shadow:Hide()
    end

    return input
end

local function CreateShareFrame()
    local f  = CreateFrame("Frame", nil, UIParent)
    local DB = pfUI_cache["portrait3d"][GetRealmName()][UnitName("player")]

    f:Hide()
    f:SetPoint("CENTER", 0, 0)
    f:SetWidth(580)
    f:SetHeight(420)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    f:SetScript("OnShow", function()
        if pfUI.gui and pfUI.gui:IsShown() then
            this.hadGUI = true
            pfUI.gui:Hide()
        else
            this.hadGUI = nil
        end

        local text, compressed = serialize(DB, nil, "pfUI_portrait3d_config", {}), nil

        if text then
            compressed = enc(compress(text))

            this.scroll.text:SetText(compressed)
            this.scroll.text.value = compressed
            this.scroll:SetVerticalScroll(0)
        end
    end)
    f:SetScript("OnHide", function()
        if this.hadGUI then pfUI.gui:Show() end
    end)

    CreateBackdrop(f, nil, true, 0.8)
    CreateBackdropShadow(f)

    do -- Edit Box
        f.scroll = CreateScrollFrame("pfPortrait3DShareScroll", f)
        f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -30)
        f.scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 50)
        f.scroll:SetWidth(560)
        f.scroll:SetHeight(400)

        f.scroll.backdrop = CreateFrame("Frame", "pfPortrait3DShareScrollBackdrop", f.scroll)
        f.scroll.backdrop:SetFrameLevel(1)
        f.scroll.backdrop:SetPoint("TOPLEFT", f.scroll, "TOPLEFT", -5, 5)
        f.scroll.backdrop:SetPoint("BOTTOMRIGHT", f.scroll, "BOTTOMRIGHT", 5, -5)

        CreateBackdrop(f.scroll.backdrop, nil, true)

        f.scroll.text = CreateFrame("EditBox", "pfPortrait3DShareEditBox", f.scroll)
        f.scroll.text.bg = f.scroll.text:CreateTexture(nil, "OVERLAY")
        f.scroll.text.bg:SetAllPoints(f.scroll.text)
        f.scroll.text.bg:SetTexture(1, 1, 1, .05)
        f.scroll.text:SetMultiLine(true)
        f.scroll.text:SetWidth(560)
        f.scroll.text:SetHeight(400)
        f.scroll.text:SetAllPoints(f.scroll)
        f.scroll.text:SetTextInsets(15, 15, 15, 15)
        f.scroll.text:SetFont(pfUI.media["font:RobotoMono.ttf"], 12)
        f.scroll.text:SetAutoFocus(false)
        f.scroll.text:SetJustifyH("LEFT")
        f.scroll.text:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        f.scroll.text:SetScript("OnTextChanged", function()
            this:GetParent():UpdateScrollChildRect()
            this:GetParent():UpdateScrollState()
    
            local _, error = loadstring(f.scroll.text:GetText())
            if error or string.gsub(this:GetText(), " ", "") == "" then
                f.loadButton:Disable()
                f.loadButton.text:SetTextColor(1, .5, .5, 1)
            else
                f.loadButton:Enable()
                f.loadButton.text:SetTextColor(.5, 1, .5, 1)
            end
    
            local trydec = dec(this:GetText())
            if string.gsub(this:GetText(), " ", "") == "" then
                f.readButton.text:SetText(T["N/A"])
                f.readButton:Disable()
            elseif not trydec or trydec == "" then
                f.readButton:Enable()
                f.readButton.text:SetText(T["Encode"])
                f.readButton.func = function()
                    local compressed = enc(compress(f.scroll.text:GetText()))
                    f.scroll.text:SetText(compressed)
                end
            else
                f.readButton:Enable()
                f.readButton.text:SetText(T["Decode"])
                f.readButton.func = function()
                    local uncompressed = decompress(dec(f.scroll.text:GetText()))
                    f.scroll.text:SetText(uncompressed)
                end
            end
        end)
        f.scroll:SetScrollChild(f.scroll.text)
    end

    do -- button: close
        f.closeButton = CreateFrame("Button", "pfPortrait3DShareClose", f)

        SkinButton(f.closeButton, 1, .5, .5)

        f.closeButton:SetPoint("TOPRIGHT", -5, -5)
        f.closeButton:SetHeight(12)
        f.closeButton:SetWidth(12)
        f.closeButton.texture = f.closeButton:CreateTexture("pfQuestionDialogCloseTex")
        f.closeButton.texture:SetTexture(pfUI.media["img:close"])
        f.closeButton.texture:ClearAllPoints()
        f.closeButton.texture:SetAllPoints(f.closeButton)
        f.closeButton.texture:SetVertexColor(1, .25, .25, 1)
        f.closeButton:SetScript("OnClick", function()
            this:GetParent():Hide()
        end)
    end

    do -- button: load
        f.loadButton = CreateFrame("Button", "pfPortrait3DShareLoad", f)

        SkinButton(f.loadButton)

        f.loadButton:SetPoint("BOTTOMRIGHT", -5, 5)
        f.loadButton:SetWidth(75)
        f.loadButton:SetHeight(25)
        f.loadButton.text = f.loadButton:CreateFontString("Caption", "LOW", "GameFontWhite")
        f.loadButton.text:SetAllPoints(f.loadButton)
        f.loadButton.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
        f.loadButton.text:SetText(T["Import"])
        f.loadButton:SetScript("OnClick", function()
            local ImportConfig, error = loadstring(f.scroll.text:GetText())

            if not error and f.scroll.text:GetText() ~= "" then
                ImportConfig()

                for frame, models in pairs(pfUI_portrait3d_config) do
                    DB[frame] = DB[frame] or {}
    
                    for model, options in pairs(models) do
                        DB[frame][model] = DB[frame][model] or {}
    
                        for k, val in pairs(options) do
                            DB[frame][model][k] = val
                        end
                    end
                end

                pfUI_portrait3d_config = nil

                -- CreateQuestionDialog(T["Some settings need to reload the UI to take effect.\nDo you want to reloadUI now?"], ReloadUI)
                this:GetParent():Hide()
            end
        end)
    end

    do -- button: read
        f.readButton = CreateFrame("Button", "pfPortrait3DShareDecode", f)
        SkinButton(f.readButton)
        f.readButton:SetPoint("RIGHT", f.loadButton, "LEFT", -10, 0)
        f.readButton:SetWidth(75)
        f.readButton:SetHeight(25)
        f.readButton.text = f.readButton:CreateFontString("Caption", "LOW", "GameFontWhite")
        f.readButton.text:SetAllPoints(f.readButton)
        f.readButton.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
        f.readButton.text:SetText(T["N/A"])
        f.readButton:SetScript("OnClick", function()
            this.func()
        end)
    end

    return f
end

local function CreateComboboxFrame(name, parent, opts)
    local combobox        = CreateDropDownButton(name, parent)
    local ShowMenuOld     = combobox.ShowMenu
    local HideMenuOld     = combobox.HideMenu
    local MenuOnUpdateOld = combobox.menuframe:GetScript("OnUpdate")
    local UpdateScrollStateOld

    combobox.nodefault = opts.nodefault
    
    combobox:SetWidth(opts.width or 160)
    combobox:SetPoint("RIGHT", opts.ofx or 0, opts.ofy or 0)
    if opts.noback then combobox:SetBackdrop(nil) end

    -- dropdown scroll
    combobox.dropdown = CreateScrollFrame(nil, combobox)
    -- combobox.dropdown:SetHeight(opts.height or 300)
    combobox.dropdown:SetPoint("TOPLEFT", combobox, "BOTTOMLEFT", 0, 0)
    combobox.dropdown:SetPoint("TOPRIGHT", combobox, "BOTTOMRIGHT", 0, 0)
    combobox.dropdown:SetParent(pfUI.gui)
    combobox.dropdown:SetFrameLevel(combobox:GetFrameLevel() + 8)
    combobox.dropdown:EnableMouse(true)
    combobox.dropdown:SetScript("OnMouseWheel", function()
        this:Scroll(arg1 * (opts.height or 300) / 3)
    end)
    
    -- make sure to refresh scroll rect when content on update
    UpdateScrollStateOld = combobox.dropdown.UpdateScrollState
    combobox.dropdown.UpdateScrollState = function(self)
        if self then self:UpdateScrollChildRect() end
        UpdateScrollStateOld()
    end

    combobox.dropdown.slider:SetPoint("TOPRIGHT", -4, 0)
    combobox.dropdown.slider:SetFrameStrata("FULLSCREEN")

    -- dropdown content 
    combobox.dropdown.content = combobox.menuframe
    combobox.dropdown.content:SetParent(combobox.dropdown)
    -- combobox.dropdown.content:SetWidth(combobox:GetWidth() - 10)
    combobox.dropdown.content:SetScript("OnUpdate", function()
        if MenuOnUpdateOld and type(MenuOnUpdateOld) == "function" then 
            MenuOnUpdateOld()
        end
        
        this:GetParent():UpdateScrollState()
    end)

    -- dropdown backdrop
    -- combobox.dropdown.tex = combobox.dropdown:CreateTexture(nil, "BACKGROUND")
    -- combobox.dropdown.tex:SetTexture(0, 0, 0, .75)
    -- combobox.dropdown.tex:SetPoint("TOPLEFT", 0, 0)
    -- combobox.dropdown.tex:SetPoint("BOTTOMRIGHT", 0, 0)
    CreateBackdrop(combobox.dropdown, nil, true)  -- use the current theme's config

    combobox.dropdown.max = opts.height or 300

    combobox.dropdown:SetScrollChild(combobox.dropdown.content)
    combobox.dropdown:Hide()

    combobox.ShowMenu = function(self)
        ShowMenuOld(self)
        -- self.dropdown:UpdateScrollChildRect()
        -- self.dropdown:UpdateScrollState()
        self.dropdown:Show()
    end

    combobox.HideMenu = function(self)
        HideMenuOld(self)
        self.dropdown:Hide()
    end

    combobox.SetupMenus = function(self, values, category, config, ufunc)
        self:SetMenu(function()
            local menu = {}
  
            self.current = nil
            
            for i, k in pairs(_G.type(values) == "function" and values() or values) do
                local entry = {}
                -- get human readable
                local value, text = strsplit(":", k)
                text = text or value
    
                entry.text = text
                entry.func = function()
                    if category[config] ~= value then
                        category[config] = value
                        if ufunc then ufunc() else pfUI.gui.settingChanged = true end
                    end
                end
                
                if category[config] == value then
                    self.current = i
                end
    
                table.insert(menu, entry)
            end
    
            return menu
        end)

        -- update menus
        for _, elm in ipairs(self.menuframe.elements) do
            elm:Hide()
        end
        
        self.menuframe.elements = {}

        if not self.nodefault then
            self.current = self.current or 1
            self.id      = self.current
            
            self.text:SetText(self.menu and self.menu[self.id] and self.menu[self.id].text or "")
        end

        for i, _ in ipairs(self.menu) do
            self:CreateMenuEntry(i)

            if self.nodefault or i ~= self.current then
                self.menuframe.elements[i].icon:Hide()
            end
        end
        
        -- resize the dropdown
        local height = table.getn(self.menu) * 20 + 4
        
        self.dropdown:SetHeight(height < self.dropdown.max and height or self.dropdown.max)
        self.dropdown.content:SetWidth(self:GetWidth() - (height < self.dropdown.max and 0 or 10))
        self.dropdown.content:SetHeight(height)
        self.dropdown.content:SetFrameLevel(self:GetFrameLevel() + 8)
        self.dropdown:UpdateScrollChildRect()
        self.dropdown:UpdateScrollState()
        -- self.dropdown.slider:SetValue(0)

        -- if height >= self.dropdown.max + 20 then
        --     self.dropdown:SetVerticalScroll((height - self.dropdown.max) * self.current / table.getn(self.menu))
        -- end
    end

    return combobox
end

pfUI.env.UWGT = {
    [1]                     = CreateSliderFrame,
    ["CreateSliderFrame"]   = CreateSliderFrame,
    [2]                     = CreateButtonxFrame,
    ["CreateButtonxFrame"]  = CreateButtonxFrame,
    [3]                     = CreateTextxFrame,
    ["CreateTextxFrame"]    = CreateTextxFrame,
    [4]                     = CreateShareFrame,
    ["CreateShareFrame"]    = CreateShareFrame,
    [5]                     = CreateComboboxFrame,
    ["CreateComboboxFrame"] = CreateComboboxFrame,
}