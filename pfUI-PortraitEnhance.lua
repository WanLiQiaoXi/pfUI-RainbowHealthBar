pfUI:RegisterModule("protraitenhance", "vanilla:tbc", function ()
    if C.unitframes["always2dportrait"] == "1" then return end

    local CreateConfig, UnitFrames = pfUI.gui.CreateConfig, pfUI.gui.frames[T["Unit Frames"]]
    -- local strlen, strsplit, strjoin, strfind, strsub, gsub, format, tonumber = strlen, strsplit, strjoin, strfind, strsub, gsub, format, tonumber
    -- local GetRealmName, UnitName = GetRealmName, UnitName
    local CacheSliders = {}
    local CacheButtons = {}
    local CacheInputs  = {}
    local caches       = {}

    local UNKNOWN_MODEL = "TalkToMeQuestionMark"

    local strjoin = strjoin or string.join or function (delimiter, ...)
        if type(delimiter) ~= "string" and type(delimiter) ~= "number" then
            error(format("bad argument #1 to 'join' (string expected, got %s)", delimiter and type(delimiter) or "no value"), 2)
        end

        if arg.n == 0 then
            return ""
        end

        return table.concat(arg, delimiter)
    end

    local function serialize(tbl, comp, name, ignored, spacing)
        local spacing = spacing or ""
        local match = nil
        local tname = ( spacing == "" and "" or "[\"" ) .. name .. ( spacing == "" and "" or "\"]" )
        local str = spacing .. tname .. " = {\n"
    
        for k, v in pairs(tbl) do
            if not ( ignored[k] and spacing == "" ) and ( not comp or not comp[k] or comp[k] ~= tbl[k] ) then
                if type(v) == "table" then
                    local result = serialize(tbl[k], comp and comp[k], k, ignored, spacing .. "  ")
                    if result then
                        match = true
                        str = str .. result
                    end
                elseif type(v) == "string" then
                    match = true
                    str = str .. spacing .. "  [\""..k.."\"] = \"".. string.gsub(v, "\\", "\\\\") .."\",\n"
                elseif type(v) == "number" then
                    match = true
                    str = str .. spacing .. "  [\""..k.."\"] = ".. string.gsub(v, "\\", "\\\\") ..",\n"
                end
            end
        end
    
        str = str .. spacing .. "}" .. ( spacing == "" and "" or "," ) .. "\n"
        return match and str or nil
    end
    
    local function compress(input)
        -- based on Rochet2's lzw compression
        if type(input) ~= "string" then
            return nil
        end
        local len = strlen(input)
        if len <= 1 then
            return "u"..input
        end
    
        local dict = {}
        for i = 0, 255 do
            local ic, iic = strchar(i), strchar(i, 0)
            dict[ic] = iic
        end
        local a, b = 0, 1
    
        local result = {"c"}
        local resultlen = 1
        local n = 2
        local word = ""
        for i = 1, len do
            local c = strsub(input, i, i)
            local wc = word..c
            if not dict[wc] then
                local write = dict[word]
                if not write then
                    return nil
                end
                result[n] = write
                resultlen = resultlen + strlen(write)
                n = n+1
                if  len <= resultlen then
                    return "u"..input
                end
                local str = wc
                if a >= 256 then
                    a, b = 0, b+1
                    if b >= 256 then
                        dict = {}
                        b = 1
                    end
                end
                dict[str] = strchar(a,b)
                a = a+1
                word = c
            else
                word = wc
            end
        end
        result[n] = dict[word]
        resultlen = resultlen+strlen(result[n])
        n = n+1
        if  len <= resultlen then
            return "u"..input
        end
        return table.concat(result)
    end
    
    local function decompress(input)
        -- based on Rochet2's lzw compression
        if type(input) ~= "string" or strlen(input) < 1 then
            return nil
        end
    
        local control = strsub(input, 1, 1)
        if control == "u" then
            return strsub(input, 2)
        elseif control ~= "c" then
            return nil
        end
        input = strsub(input, 2)
        local len = strlen(input)
    
        if len < 2 then
            return nil
        end
    
        local dict = {}
        for i = 0, 255 do
            local ic, iic = strchar(i), strchar(i, 0)
            dict[iic] = ic
        end
    
        local a, b = 0, 1
    
        local result = {}
        local n = 1
        local last = strsub(input, 1, 2)
        result[n] = dict[last]
        n = n+1
        for i = 3, len, 2 do
            local code = strsub(input, i, i+1)
            local lastStr = dict[last]
            if not lastStr then
                return nil
            end
            local toAdd = dict[code]
            if toAdd then
                result[n] = toAdd
                n = n+1
                local str = lastStr..strsub(toAdd, 1, 1)
                if a >= 256 then
                    a, b = 0, b+1
                    if b >= 256 then
                        dict = {}
                        b = 1
                    end
                end
                dict[strchar(a,b)] = str
                a = a+1
            else
                local str = lastStr..strsub(lastStr, 1, 1)
                result[n] = str
                n = n+1
                if a >= 256 then
                    a, b = 0, b+1
                    if b >= 256 then
                        dict = {}
                        b = 1
                    end
                end
                dict[strchar(a,b)] = str
                a = a+1
            end
            last = code
        end
        return table.concat(result)
    end
    
    local function enc(to_encode)
        local index_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        local bit_pattern = ''
        local encoded = ''
        local trailing = ''
    
        for i = 1, string.len(to_encode) do
            local remaining = tonumber(string.byte(string.sub(to_encode, i, i)))
            local bin_bits = ''
            for i = 7, 0, -1 do
                local current_power = math.pow(2, i)
                if remaining >= current_power then
                    bin_bits = bin_bits .. '1'
                    remaining = remaining - current_power
                else
                    bin_bits = bin_bits .. '0'
                end
            end
            bit_pattern = bit_pattern .. bin_bits
        end
    
        if mod(string.len(bit_pattern), 3) == 2 then
            trailing = '=='
            bit_pattern = bit_pattern .. '0000000000000000'
        elseif mod(string.len(bit_pattern), 3) == 1 then
            trailing = '='
            bit_pattern = bit_pattern .. '00000000'
        end
    
        local count = 0
        for i = 1, string.len(bit_pattern), 6 do
            local byte = string.sub(bit_pattern, i, i+5)
            local offset = tonumber(tonumber(byte, 2))
            encoded = encoded .. string.sub(index_table, offset+1, offset+1)
            count = count + 1
            if count >= 92 then
                encoded = encoded .. "\n"
                count = 0
            end
        end
    
        return string.sub(encoded, 1, -1 - string.len(trailing)) .. trailing
    end
    
    local function dec(to_decode)
        local index_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        local padded = gsub(to_decode,"%s", "")
        local unpadded = gsub(padded,"=", "")
        local bit_pattern = ''
        local decoded = ''
    
        to_decode = gsub(to_decode,"\n", "")
        to_decode = gsub(to_decode," ", "")
    
        for i = 1, string.len(unpadded) do
            local char = string.sub(to_decode, i, i)
            local offset, _ = string.find(index_table, char)
            if offset == nil then return nil end
    
            local remaining = tonumber(offset-1)
            local bin_bits = ''
            for i = 7, 0, -1 do
                local current_power = math.pow(2, i)
                if remaining >= current_power then
                    bin_bits = bin_bits .. '1'
                    remaining = remaining - current_power
                else
                    bin_bits = bin_bits .. '0'
                end
            end
    
            bit_pattern = bit_pattern .. string.sub(bin_bits, 3)
        end
    
        for i = 1, string.len(bit_pattern), 8 do
            local byte = string.sub(bit_pattern, i, i+7)
            decoded = decoded .. strchar(tonumber(byte, 2))
        end
    
        local padding_length = string.len(padded)-string.len(unpadded)
    
        if (padding_length == 1 or padding_length == 2) then
            decoded = string.sub(decoded,1,-2)
        end
    
        return decoded
    end

    -- initialize portrait3d cache if not found
    local realm  = GetRealmName()
    local player = UnitName("player")

    pfUI_cache["portrait3d"]                = pfUI_cache["portrait3d"] or {}
    pfUI_cache["portrait3d"][realm]         = pfUI_cache["portrait3d"][realm] or {}
    pfUI_cache["portrait3d"][realm][player] = pfUI_cache["portrait3d"][realm][player] or {}

    local GDB = pfUI_cache["portrait3d"]
    local DB  = GDB[realm][player]

    -- config item keys
    local CIK = { 
        --       caption                                              key                         extracap1                                           extracap2            extracap3
        [1]  = { T["3D Portrait Enhance"],                             nil,                        nil,                                               nil,                 nil                                                                                    },
        [2]  = { T["Enable"] .. T["3D Portrait Enhance"],              "portrait3d_enable",        nil,                                               nil,                 nil                                                                                    },
        [3]  = { T["3D Portrait Model Scale"],                         "portrait3d_scale",         T["Set"] .. " " .. T["3D Portrait Model Scale"],   T["Scale"],          nil                                                                                    },
        [4]  = { "3D" .. T["Portrait Position"],                       "portrait3d_position",      T["Set"] .. " " .. "3D" .. T["Portrait Position"], nil,                 nil                                                                                    },
        [5]  = { T["3D Portrait Model Facing"],                        "portrait3d_facing",        T["Set"] .. " " .. T["3D Portrait Model Facing"],  T["Angle Value"],    nil                                                                                    },
        [6]  = { T["3D Portrait Model Size"],                          "portrait3d_size",          T["Set"] .. " " .. T["3D Portrait Model Size"],    T["Portrait Width"], T["Portrait Height"]                                                                   },
        [7]  = { T["3D Portrait Model Offset"],                        "portrait3d_offset",        T["Set"] .. " " .. T["3D Portrait Model Offset"],  T["Offset"] .. "x",  T["Offset"] .. "y"                                                                     },
        [8]  = { T["Enable Global 3D Portrait Enhance"],               "portrait3d_global_enable", nil,                                               nil,                 nil                                                                                    },
        [9]  = { T["Clear Configurations Of 3D Portrait"],             nil,                        T["Delete profile"],                               T["Share"],          T["Some settings need to reload the UI to take effect.\nDo you want to reloadUI now?"] },
        [10] = { T["Portrait Alpha"],                                  "portraitalpha",            T["Set Portrait Alpha Value"],                     T["Alpha Value"],    nil                                                                                    },
        [11] = { T["Reset All Config Of 3D Portrait"],                 nil,                        T["Delete / Reset"],                               nil,                 nil                                                                                    },
        [12] = { T["Portrait Alpha"],                                  "portrait3d_alpha",         T["Set Portrait Alpha Value"],                     T["Alpha Value"],    nil                                                                                    },
        [13] = { T["3D Portrait Model Camera"],                        "portrait3d_camera",        nil,                                               nil,                 nil                                                                                    },
        [14] = { T["Select Party Member"],                             "portrait3d_party_cache",   nil,                                               nil,                 nil                                                                                    },
        [15] = { T["Load An 3D Portrait Model Config"],                "portrait3d_config_cache",  nil,                                               nil,                 nil                                                                                    },
        [16] = { T["3D Portrait Model Config"],                        nil,                        T["Add"],                                          T["Remove"],         nil                                                                                    },
        [17] = { T["Clone Another Player's 3D Portrait Model Config"], "portrait3d_model_cache",   T["Clone"],                                        nil,                 nil                                                                                    }
    }

    --[[
        REGION: config management
    --]]
    local function GetCacheConfigItems()
        local items = {}

        for k, o in pairs(GDB) do 
            if type(o) == "table" then
                for v, _ in pairs(o) do
                    table.insert(items, format("%s/%s", k, v))
                end
            end
        end

        return items
    end

    local function GenerateCacheConfigDropdownItems(filter, mode, gen)
        local items, i, data = {}, 0, ({ GDB, DB })[mode or 1]
        local keys = {}

        for k, o in pairs(data) do 
            if type(o) == "table" then
                table.insert(keys, k)
            end
        end

        table.sort(keys)

        for _, k in ipairs(keys) do
            local subks = {}

            for v, _ in pairs(data[k]) do
                table.insert(subks, v)
            end

            table.sort(subks)

            for _, v in ipairs(subks) do
                if not filter or (type(filter) == "function" and not filter(v, k, data[k])) or (type(filter) == "string" and v ~= filter) then
                    if type(gen) == "function" then
                        table.insert(items, gen(i, k, v, data[k]))
                    else
                        table.insert(items, gen and format("%d:%s", i, v) or format("%d:%s/%s", i, k, v))
                    end

                    i = i + 1
                end
            end
        end

        return items
    end

    local function RemoveConfig(frame, model, mode)
        if mode == 2 then
            GDB[realm][player] = nil
        elseif (not mode or mode == 1) and frame and DB[frame] and model then
            DB[frame][model] = nil
        end
    end

    local function UpdateConfig(category, frame, model)
        --             scale      pos x,y,z  facing     size        offset      alpha       camera
        -- local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[6][2], CIK[7][2], CIK[12][2], CIK[13][2] }
        local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[13][2] }

        if category and C.unitframes[category] and frame and model then
            DB[frame]        = DB[frame] or {}
            DB[frame][model] = DB[frame][model] or {}

            for _, k in ipairs(keys) do
                DB[frame][model][k] = C.unitframes[category][k]
            end
        end
    end

    local function LoadConfig(category, frame, model, cacheitem)
        --             scale      pos x,y,z  facing     size        offset      alpha       camera
        -- local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[6][2], CIK[7][2], CIK[12][2], CIK[13][2] }
        local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[13][2] }
        local opts = cacheitem and { strsplit("/", cacheitem) } or nil
        local data = opts and GDB[opts[1]][opts[2]] or DB

        if category and C.unitframes[category] and data[frame] and data[frame][model] then
            for _, k in ipairs(keys) do
                C.unitframes[category][k] = data[frame][model][k]
            end
        end
    end

    local function HasConfig(category, frame, model, cacheitem)
        local opts = cacheitem and { strsplit("/", cacheitem) } or nil
        local data = opts and GDB[opts[1]][opts[2]] or DB

        return category and C.unitframes[category] and data[frame] and data[frame][model]
    end

    local function IsModifiedConfig(category, frame, model)
        if HasConfig(category, frame, model) then
            local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[13][2] }

            for _, k in ipairs(keys) do
                if C.unitframes[category][k] ~= DB[frame][model][k] then
                    return true
                end
            end

            return false
        end

        return model ~= UNKNOWN_MODEL
    end

    --[[
        REGION: extension of CreateConfig method
    --]]
    local function CreateSliderFrame(name, parent, opts, func, cache)
        local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")

        SkinSlider(slider)

        -- reset original property
        slider.tooltipText = opts.tips or ""
        slider.label       = opts.text or ""
        slider.key         = opts.key
        slider.enabled     = true

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
        slider.text  = regions[1]  -- layer Text
        slider.low   = regions[2]  -- layer Low
        slider.hight = regions[3]  -- layer Hight 

        slider.text:SetText(format("%s: %.2f", opts.text, opts.val))
        slider.text:SetPoint("BOTTOM", slider, "TOP", 0, 5)
        slider.low:SetText(format("%.2f", opts.min or 0))
        slider.hight:SetText(format("%.2f", opts.max or 1))

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
            local val = tonumber(format("%.2f", arg1))

            this.text:SetText(format("%s: %.2f", opts.text, val))
                
            if this.enabled then
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
                    this:GetParent().category[this:GetParent().config] = format("%.2f", val) 
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
            local sld = this:GetParent()

            sld.stimer = C_Timer.NewTicker(0.16, function() sld:SetValue(sld:GetValue() - sld:GetValueStep()) end)
        end)
        slider.del:SetScript("OnMouseUp", function()
            this:GetParent().stimer:Cancel()
        end)
        slider.del:SetScript("OnClick", function()
            local sld = this:GetParent()
            
            sld:SetValue(sld:GetValue() - sld:GetValueStep())
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
            local sld = this:GetParent()

            sld.stimer = C_Timer.NewTicker(0.16, function() sld:SetValue(sld:GetValue() + sld:GetValueStep()) end)
        end)
        slider.add:SetScript("OnMouseUp", function()
            this:GetParent().stimer:Cancel()
        end)
        slider.add:SetScript("OnClick", function()
            local sld = this:GetParent()
            
            sld:SetValue(sld:GetValue() + sld:GetValueStep())
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
                if (opts.type and opts.type ~= "number" ) or tonumber(this:GetText()) then
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
        local f = CreateFrame("Frame", nil, UIParent)

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
            f.scroll = pfUI.api.CreateScrollFrame("pfPortrait3DShareScroll", f)
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
            pfUI.api.SkinButton(f.readButton)
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

    local function CreateConfigEx(ufunc, caption, category, config, widget, values, skip, named, type, expansion)
        local widgets = _G.type(widget) == "table" and widget or { widget }
        local values  = _G.type(widget) == "table" and values or { values }
        local frame

        for i, widget in ipairs(widgets) do
            local vals = values[i]

            if not frame then
                frame       = CreateConfig(ufunc, caption, category, config, widget, vals, skip, named, type, expansion)
                frame.ctrls = {}
            end

            -- use dropdown widget
            if widget == "dropdown" and frame.input and _G.type(vals) == "function" then
                local _, opts = vals()  -- for option settings of dropdown widget you need to set values to a function and return extra values

                frame.input:SetPoint("RIGHT", frame, "RIGHT", opts.ofx or 0, opts.ofy or 0)
                frame.input:SetWidth(opts.width or 180)

                -- set disable state
                if opts.disable then
                    frame.input:Disable()
                    frame.input.button:Disable()
                end

                -- set cache
                if opts.tab then
                    CacheButtons[opts.tab] = CacheButtons[opts.tab] or {}
                    table.insert(CacheButtons[opts.tab], frame.input)
                    table.insert(CacheButtons[opts.tab], frame.input.button)

                    if opts.key then
                        frame.input.key                  = opts.key
                        frame.input.button.key           = opts.key
                        CacheButtons[opts.tab][opts.key] = frame.input
                    end
                end
            end

            -- use slider widget
            if widget == "slider" then
                -- if length is set then create slider groups
                if vals.length then
                    frame.sliders = {}

                    for _, opts in ipairs(vals) do
                        table.insert(frame.sliders, CreateSliderFrame(nil, frame, opts, ufunc, opts.tab and CacheSliders or nil))
                    end
                else
                    frame.ctrls[i] = CreateSliderFrame(nil, frame, vals, ufunc, vals.tab and CacheSliders or nil)
                end
            end

            -- use buttonx widget
            if widget == "buttonx" then
                frame.ctrls[i] = CreateButtonxFrame("pfButton", frame, vals, ufunc, vals.tab and CacheButtons or nil)
            end

            -- use textx widget
            if widget == "textx" then
                vals.type = vals.type or type
                vals.text = vals.text or category[config]

                -- textx field
                frame.ctrls[i] = CreateTextxFrame(nil, frame, vals, ufunc, vals.key and CacheInputs or nil)
            end

            -- use share widget
            if widget == "share" then
                -- share field
                frame.share    = CreateShareFrame()
                frame.ctrls[i] = CreateButtonxFrame("pfButton", frame, vals, ufunc, vals.tab and CacheButtons or nil)
            end
        end
    end

    --[[
        REGION: portrait enhance
    --]]
    local function GetPortraits(frame, cachecontrainer)
        local frames = { 
            ["player"            ] = "player", 
            ["target"            ] = "target", 
            ["targettarget"      ] = "targettarget", 
            ["targettargettarget"] = "targettargettarget", 
            ["pet"               ] = "pet", 
            ["pettarget"         ] = "pettarget", 
            ["focus"             ] = "focus", 
            ["focustarget"       ] = "focustarget", 
            ["group"             ] = "group", 
            ["grouptarget"       ] = "grouptarget", 
            ["grouppet"          ] = "grouppet", 
            ["raid"              ] = "raid"
        }
        local portraits = {}
        local InsertPortrait = function(container, frame)
            frame.portrait.parent = frame
            -- frame.portrait:SetFrameStrata("MEDIUM")
            frame.portrait.model:SetFrameLevel(3)
            table.insert(container, frame.portrait)
        end
        local GetPortrait = function(container, name)
            local parent

            if name == "raid" or name == "group" or name == "grouptarget" or name == "grouppet" then
                local n   = name == "raid" and tonumber(C.unitframes.maxraid) or 4
                local sub = strfind(name, "group") and gsub(name, "group", "") or ""
                
                for i = 1, n do
                    InsertPortrait(container, sub == "" and pfUI.uf[name][i] or pfUI.uf.group[i][sub])
                end
            else
                InsertPortrait(container, pfUI.uf[name])
            end
        end

        if frame and frames[frame] then
            GetPortrait(portraits, frame)
        elseif not frame then
            for _, frame in pairs(frames) do
                GetPortrait(portraits, frame)
            end
        end

        return portraits
    end

    local function GetPortraitModel(frame)
        if frame and ((strfind(frame, "^group") and not UnitInParty("player")) or (strfind(frame, "^raid") and not UnitInRaid("player"))) then
            -- return nil, nil
            return { UNKNOWN_MODEL }, nil
        end

        local portraits = GetPortraits(frame)
        local models    = {}
        local model

        for _, portrait in ipairs(portraits) do 
            model = portrait.model:GetModel()
            
            table.insert(models, type(model) == "string" and ({ strfind(model, [[%\([^%\]+)$]]) })[3] or nil)
        end

        return models, portraits
    end

    local function SetPortraitAlpha(frame, alpha)
        local portraits = GetPortraits(frame)

        for _, portrait in ipairs(portraits) do
            portrait:SetAlpha(tonumber(alpha), true)
        end
    end

    local function SetPortraitScale(frame, index, scale, silence)
        local portrait = GetPortraits(frame)[tonumber(index or 1)]
        
        -- before RefreshUnit must set a base scale and position
        -- if not after set new scale won't set the right position again
        portrait.model:SetModelScale(1)
        -- portrait.model:SetCamera(1)
        portrait.model:SetPosition(0, 0, 0)
        portrait.model:RefreshUnit()
        portrait.model:SetModelScale(tonumber(scale or portrait.model:GetModelScale()))

        -- enable and reset sliders
        if not silence then
            for _, slider in ipairs(CacheSliders[frame]) do
                if slider.ref == "scale" then
                    if not slider.enabled then
                        slider:SetEnabled(true)
                    end

                    slider:SetValue(0)
                end
            end

            CacheButtons[frame]["camera"]:SetSelection(2)
            CacheButtons[frame]["camera"].menu[2].func()
        end
    end

    local function SetPortraitCamera(frame, index, camera)
        local portrait = GetPortraits(frame)[tonumber(index or 1)]

        portrait.model:SetCamera(camera or 0)

        if camera ~= "0" then
            if camera == "1" then
                portrait.model:SetModelScale(1)
                portrait.model:SetPosition(0, 0, 0)
                portrait.model:RefreshUnit()
                portrait.model:SetModelScale(portrait.category[CIK[3][2]] or 1)
                portrait.model:SetFacing(portrait.category[CIK[5][2]] or 0)
            end

            portrait.model:SetPosition(strsplit(",", portrait.category[CIK[4][2]] or "0,0,0"))
        end
    end

    local function SetPortraitPosition(frame, index, x, y, z)
        GetPortraits(frame)[tonumber(index or 1)].model:SetPosition(x or 0, y or 0, z or 0)
    end

    local function SetPortraitFacing(frame, index, angle)
        GetPortraits(frame)[tonumber(index or 1)].model:SetFacing(angle or 0)
    end

    local function SetPortraitSize(frame, index, width, height, ofx, ofy, silence)
        local index     = tonumber(({ strfind(tostring(index), "(%d+)") })[3])
        local portraits = GetPortraits(frame)

        for id, portrait in ipairs(portraits) do
            if not index or index == id then
                portrait.model:ClearAllPoints()
                portrait.model:SetWidth(width or portrait:GetWidth())
                portrait.model:SetHeight(height or portrait:GetHeight())
                portrait.model:SetPoint("CENTER", portrait, "CENTER", ofx or 0, ofy or 0)
            end

            if index == id then
                break
            end
        end

        -- enable and reset sliders
        if not silence then
            for _, slider in ipairs(CacheSliders[frame]) do
                if slider.ref == "size" then
                    if not slider.enabled then
                        slider:SetEnabled(true)
                    end

                    -- slider:SetValue(0)
                end
            end
        end
    end

    local function SetPortraitOffset(frame, ofx, ofy)
        local portraits = GetPortraits(frame)

        for _, portrait in ipairs(portraits) do
            portrait.model:SetPoint("CENTER", portrait, "CENTER", ofx or 0, ofy or 0)
        end
    end

    local function RefreshUnitPortrait(portrait)
        if portrait and portrait.model and portrait.parent then
            portrait.model:ClearAllPoints()
            portrait.model:SetWidth(-1)
            portrait.model:SetHeight(-1)
            portrait.model:SetAllPoints(portrait)
            portrait.model:SetCamera(0)
            -- pfUI.uf:RefreshUnit(portrait.parent, "portrait")
            -- pfUI.uf:RefreshUnit(portrait:GetParent(), "portrait")
        end
    end

    local function RefreshCacheCtrlStatus(frame, portrait, scale, x, y, z, angle, camera, width, height, ofx, ofy)
        if CacheSliders[frame] and CacheInputs[format("%s:model", frame)]:GetText() ~= UNKNOWN_MODEL then
            CacheSliders[frame]["scale"]:SetValue(scale)
            CacheSliders[frame]["posx"]:SetValue(x)
            CacheSliders[frame]["posy"]:SetValue(y)
            CacheSliders[frame]["posz"]:SetValue(z)
            CacheSliders[frame]["angle"]:SetValue(angle)

            if width and height and ofx and ofy then
                CacheSliders[frame]["width"]:SetValue(width)
                CacheSliders[frame]["height"]:SetValue(height)
                CacheSliders[frame]["ofx"]:SetValue(ofx)
                CacheSliders[frame]["ofy"]:SetValue(ofy)
            end
            
            CacheSliders[frame]["posx"]:SetEnabled(false)
            CacheSliders[frame]["posy"]:SetEnabled(false)
            CacheSliders[frame]["posz"]:SetEnabled(false)
            CacheSliders[frame]["angle"]:SetEnabled(false)
            CacheSliders[frame]["ofx"]:SetEnabled(false)
            CacheSliders[frame]["ofy"]:SetEnabled(false)
            
            CacheButtons[frame]["camera"]:SetSelection(camera)
            CacheButtons[frame]["camera"].menu[camera].func()
        elseif portrait then
            portrait.model:SetModelScale(1)
            portrait.model:SetPosition(0, 0, 0)
            portrait.model:RefreshUnit()
            portrait.model:SetModelScale(scale)
            portrait.model:SetPosition(x, y, z)
            portrait.model:SetFacing(angle)

            if width and height and ofx and ofy then
                portrait.model:SetWidth(width)
                portrait.model:SetHeight(height)
                portrait.model:SetPoint(portrait.model:GetPoint(), ofx, ofy)
            end
            
            if tonumber(camera) == 1 then
                portrait.model:SetCamera(0)
            end
        end
    end

    local function SetPortraitModelStatus(category, frame, unit)
        local models, portraits = GetPortraitModel(frame)
        local UpdatePortraitStatus = function(c, f, m, p)
            local scale, x, y, z, angle, camera

            if m then
                if HasConfig(c, f, m) then
                    LoadConfig(c, f, m)
                    
                    scale   = C.unitframes[c][CIK[3][2]]
                    x, y, z = strsplit(",", C.unitframes[c][CIK[4][2]]) 
                    angle   = C.unitframes[c][CIK[5][2]]
                    camera  = C.unitframes[c][CIK[13][2]]

                    RefreshCacheCtrlStatus(f, p, scale, x, y, z, angle, camera + 1)

                    if camera == "0" then
                        p.model:SetCamera(0)
                    end
                else
                    C.unitframes[c][CIK[3][2]]  = "1"
                    C.unitframes[c][CIK[4][2]]  = "0.00,0.00,0.00"
                    C.unitframes[c][CIK[5][2]]  = "0"
                    C.unitframes[c][CIK[13][2]] = "0"

                    RefreshCacheCtrlStatus(f, p, 1, 0, 0, 0, 0, 1)
                    RefreshUnitPortrait(p)
                end
            elseif p then
                p.model:SetModelScale(4.25)
                p.model:SetPosition(0, 0, -1)
                p.model:SetModel("Interface\\Buttons\\TalkToMeQuestionMark.mdx")
                -- p.model:Show()
            end
        end

        if unit then
            local _, _, id = strfind(unit, "(%d+)")
            
            id = id and tonumber(id) or 1
            
            UpdatePortraitStatus(category, frame, models[id], portraits[id])
        else
            for i, portrait in ipairs(portraits) do
                UpdatePortraitStatus(category, frame, models[i], portrait)
            end
        end
    end

    local function LoadPortraitModelConfig(category, frame, model, index)
        local scale, x, y, z, angle, camera
        local alpha, width, height, ofx, ofy

        LoadConfig(category, frame, model)

        scale         = C.unitframes[category][CIK[3][2]]
        x, y, z       = strsplit(",", C.unitframes[category][CIK[4][2]]) 
        angle         = C.unitframes[category][CIK[5][2]]
        camera        = C.unitframes[category][CIK[13][2]]
        alpha         = C.unitframes[category][CIK[12][2]]
        width, height = strsplit(",", C.unitframes[category][CIK[6][2]]) 
        ofx, ofy      = strsplit(",", C.unitframes[category][CIK[7][2]]) 
        
        RefreshCacheCtrlStatus(frame, nil, scale, x, y, z, angle, camera + 1)
        SetPortraitAlpha(frame, alpha)
        SetPortraitSize(frame, index, width, height, ofx, ofy, true)
        SetPortraitCamera(frame, index, camera)
    end

    local function ResetPortrait(frame)
        local portraits = GetPortraits(frame)

        for _, portrait in ipairs(portraits) do
            RefreshUnitPortrait(portrait)
        end
    end

    local function ResetPortraitModuleConfig(config, key, val)
        local conf = config and C.unitframes[config] or C.unitframes

        if conf then
            conf[key] = val
        end
    end

    local function ResetPortraitModuleConfigurations(opts)
        local keys = { nil, "player", "target", "ttarget", "tttarget", "pet", "ptarget", "focus", "focustarget", "group", "grouptarget", "grouppet", "raid" }
    
        --[[
            opts = {
                silence = nil,
                [1] = config or cached control key while silence is nil/false,
                [2] = value
            }    
        --]]
        for _, key in pairs(keys) do 
            if opts.silence then
                for _, val in ipairs(opts) do 
                    ResetPortraitModuleConfig(key, val[1], val[2])
                end
            elseif CacheSliders[key] then
                for _, val in ipairs(opts) do
                    CacheSliders[key][val[1]]:SetValue(val[2])
                end
            end
        end
    end

    local function ClearPortraitModuleConfigurations()
        RemoveConfig(nil, nil, 2)
        ResetPortraitModuleConfigurations({
            silence = true,

            -- general config
            { CIK[8][2], nil },

            -- unitframe config
            -- when callee is general won't find any thus keys behind
            { CIK[2][2],  nil },
            { CIK[3][2],  nil },
            { CIK[4][2],  nil },
            { CIK[5][2],  nil },
            { CIK[6][2], nil },
            { CIK[7][2], nil },
            { CIK[12][2], nil },
            { CIK[13][2], nil }
        })
    end

    local function PortraitPositionChangeHandler()
        local parent  = this:GetParent()
        local sliders = parent.sliders
        local x, y, z = strsplit(",", parent.category[parent.config])
        local pos     = { ["x"] = x, ["y"] = y, ["z"] = z }

        if sliders then
            pos.x, pos.y, pos.z = format("%.2f", sliders[1]:GetValue()), format("%.2f", sliders[2]:GetValue()), format("%.2f", sliders[3]:GetValue())
        else
            pos[this.label] = format("%.2f", this:GetValue())
        end
        
        parent.category[parent.config] = strjoin(",", pos.x, pos.y, pos.z)
    end

    local function PortraitSizeChangeHandler()
        local sliders = this:GetParent().sliders
        local w, h = format("%.2f", sliders[1]:GetValue()), format("%.2f", sliders[2]:GetValue())
        
        this:GetParent().category[this:GetParent().config] = strjoin(",", w, h)
    end

    local function PortraitOffsetChangeHandler()
        local sliders = this:GetParent().sliders
        local ofx, ofy = format("%.2f", sliders[1]:GetValue()), format("%.2f", sliders[2]:GetValue())
        
        this:GetParent().category[this:GetParent().config] = strjoin(",", ofx, ofy)
    end

    local function PortraitRestoreClickHandler(frame)
        local id        = (strfind(frame, "^group") or strfind(frame, "^raid")) and ((CacheButtons[frame]["group"]:GetSelection() or 1) - 1) or 1
        local portrait  = id > 0 and GetPortraits(frame)[id] or nil

        if portrait then
            RefreshCacheCtrlStatus(frame, portrait, 1, 0, 0, 0, 0, 1)
            RefreshUnitPortrait(portrait)
        end
    end

    local function PortraitRemoveConfigClickHandler(frame)
        RemoveConfig(frame, CacheInputs[format("%s:model", frame)]:GetText())
        PortraitRestoreClickHandler(frame)
    end

    local function PortraitCloneConfigClickHandler()
        CreateQuestionDialog(CIK[9][5], function()
            --             scale      pos x,y,z  facing     size        offset      alpha       camera
            -- local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[6][2], CIK[7][2], CIK[12][2], CIK[13][2] }
            local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[13][2] }
            local realm, player = strsplit("/", ({ CacheButtons["general"]["data"]:GetSelection() })[2])
            
            for frame, models in pairs(GDB[realm][player]) do
                DB[frame] = DB[frame] or {}

                for model, config in pairs(models) do
                    DB[frame][model] = DB[frame][model] or {}

                    for _, k in ipairs(keys) do
                        DB[frame][model][k] = config[k]
                    end
                end
            end
            
            ReloadUI()
        end)
    end

    local function PortraitAlphaChangeHandler()
        SetPortraitAlpha(nil, C.unitframes[CIK[10][2]])
        ResetPortraitModuleConfigurations({{ "alpha", C.unitframes[CIK[10][2]] }})
    end

    local function RefreshSaveButtonStatus(config, frame)
        if IsModifiedConfig(config, frame, CacheInputs[format("%s:model", frame)]:GetText()) then
            CacheButtons[frame]["save"]:Enable()
        else
            CacheButtons[frame]["save"]:Disable()
        end
    end

    local function PortraitPartyMemberChangeHandler(config, frame, cachekey)
        local models, portraits = GetPortraitModel(frame)
        local id = tonumber(caches[frame][cachekey] or 0)
        local mtext = id > 0 and models[id] or UNKNOWN_MODEL
        local scale, x, y, z, angle, camera

        CacheInputs[format("%s:model", frame)]:SetText(mtext)

        if id > 0 then
            RefreshCacheCtrlStatus(frame, nil, 1, 0, 0, 0, 0, 1)
            
            if HasConfig(config, frame, mtext) then
                LoadConfig(config, frame, mtext)

                scale   = C.unitframes[config][CIK[3][2]]
                x, y, z = strsplit(",", C.unitframes[config][CIK[4][2]]) 
                angle   = C.unitframes[config][CIK[5][2]]
                camera  = C.unitframes[config][CIK[13][2]]

                RefreshCacheCtrlStatus(frame, nil, scale, x, y, z, angle, camera + 1)
            end

            if not camera or camera == "0" then
                portraits[id].model:SetCamera(0)
            end
        end

        for _, slider in ipairs(CacheSliders[frame]) do
            slider:SetEnabled(not slider.ref and mtext ~= UNKNOWN_MODEL)
        end

        for _, button in ipairs(CacheButtons[frame]) do
            if (button.key == "save" and not IsModifiedConfig(config, frame, mtext)) 
                or (button.key == "remove" and not HasConfig(config, frame, mtext)) 
                or (mtext == UNKNOWN_MODEL and button.key ~= "group" and button.key ~= "raid") 
            then
                button:Disable()
            else
                button:Enable()
            end
        end

        if id == 0 then
            RefreshCacheCtrlStatus(frame, nil, 1, 0, 0, 0, 0, 1)
        end
    end

    local function ConfigUpdateHandler(config, frame)
        local model           = format("%s:model", frame)
        local IsGroupOrRaid   = strfind(frame, "^group") or strfind(frame, "^raid")
        local IsInGroupOrRaid = IsGroupOrRaid and (UnitInParty("player") or UnitInRaid("player"))
        local EnableCtrls     = function()
            if CacheInputs[model] then
                local mtext = CacheInputs[model]:GetText()

                for _, slider in ipairs(CacheSliders[frame]) do
                    if not slider.ref then
                        slider:SetEnabled(C.unitframes[config][CIK[2][2]] == "1" and mtext ~= UNKNOWN_MODEL)
                    elseif C.unitframes[config][CIK[2][2]] == "0" then
                        slider:SetEnabled(false)
                    end
                end

                for _, button in ipairs(CacheButtons[frame]) do
                    if C.unitframes[config][CIK[2][2]] ~= "1"
                        or (button.key == "save" and not IsModifiedConfig(config, frame, mtext)) 
                        or (button.key == "remove" and not HasConfig(config, frame, mtext))
                        or (mtext == UNKNOWN_MODEL and (not IsGroupOrRaid or (button.key ~= "group" and button.key ~= "raid")))
                    then
                        button:Disable()
                    else
                        button:Enable()
                    end
                end
            end
        end
        local DisableCtrls     = function()
            if CacheInputs[model] then
                for _, slider in ipairs(CacheSliders[frame]) do
                    slider:SetEnabled(false)
                end

                for _, button in ipairs(CacheButtons[frame]) do
                    button:Disable()
                end
            end
        end
        local invoke          = function(c, f, u, bc, ac)
            if C.unitframes[c][CIK[2][2]] == "1" then
                local width, height = strsplit(",", C.unitframes[c][CIK[6][2]])
                local ofx, ofy      = strsplit(",", C.unitframes[c][CIK[7][2]])
                local alpha         = C.unitframes[c][CIK[12][2]] or C.unitframes[CIK[10][2]]

                SetPortraitAlpha(f, alpha)
                SetPortraitSize(f, u, width, height, ofx, ofy, true)

                -- async refresh model scale
                C_Timer.After(0, function()
                    -- call before invoke
                    if type(bc) == "function" then bc() end

                    DisableCtrls()
                    SetPortraitModelStatus(c, f, u)
                    EnableCtrls()

                    if type(ac) == "function" then ac() end
                end)
            else
                -- restore portrait states
                DisableCtrls()
                ResetPortrait(f)
            end
        end
        local callback        = function()
            if not IsGroupOrRaid and pfUI.uf[frame].portrait:IsShown() or IsInGroupOrRaid then
                invoke(config, frame, nil, 
                    function()
                        if CacheInputs[model] then
                            CacheInputs[model]:SetText(not IsGroupOrRaid and GetPortraitModel(frame)[1] or UNKNOWN_MODEL)
                        end
                    end,
                    function()
                        if CacheInputs[model] and not IsGroupOrRaid and mtext ~= UNKNOWN_MODEL then
                            local scale   = C.unitframes[config][CIK[3][2]]
                            local x, y, z = strsplit(",", C.unitframes[config][CIK[4][2]]) 
                            local angle   = C.unitframes[config][CIK[5][2]]
                            local camera  = C.unitframes[config][CIK[13][2]]
                            
                            RefreshCacheCtrlStatus(nil, pfUI.uf[frame].portrait, scale, x, y, z, angle, camera + 1)
                        end
                    end
                )
            end
        end
        local portraits = GetPortraits(frame)

        -- init config when setup
        C.unitframes[config][CIK[3][2]]  = "1"
        C.unitframes[config][CIK[4][2]]  = "0.00,0.00,0.00"
        C.unitframes[config][CIK[5][2]]  = "0"
        C.unitframes[config][CIK[13][2]] = "0"
        
        -- hooks
        for _, portrait in ipairs(portraits) do
            local SetAlphaOld = portrait.model.SetAlpha
            local SetUnitOld  = portrait.model.SetUnit
            local OnShowOld   = portrait.model:GetScript("OnShow")
            local OnHideOld   = portrait.model:GetScript("OnHide")

            portrait.category = C.unitframes[config]
            portrait.location = portrait.parent.config.portrait

            -- we need to hook SetAlpha method cause of if portrait is vendor on hp bar will always call when OnUpdate is fired
            portrait.SetAlpha = function(self, alpha, force)
                SetAlphaOld(self, tonumber(force and alpha or (C.unitframes[CIK[8][2]] == "1" and self.category[CIK[2][2]] == "1" and self.category[CIK[12][2]] or C.unitframes[CIK[10][2]])))

                -- refresh unit portrait rendor while portrait location is update
                if C.unitframes[CIK[8][2]] == "1" and self.category[CIK[2][2]] == "1" and self.location ~= self.parent.config.portrait then
                    self.location = self.parent.config.portrait

                    if self.location ~= "off" then
                        self.model:SetUnit(gsub(strlower(self.parent.fname), "group", "party"))
                    end
                end
            end
             
            -- hook portrait SetUnit method
            portrait.model.SetUnit = function(self, unit)
                local parent = self:GetParent()  -- portrait
                local index  = ({ strfind(unit, "(%d+)") })[3]
                
                -- this pointer is top level unitframe
                -- self pointer is the current model
                if not strfind(unit, "^focus") then
                    SetUnitOld(self, unit)
                end
                
                if C.unitframes[CIK[8][2]] == "1" and parent.category[CIK[2][2]] == "1" then
                    invoke(config, frame, unit, 
                        function()
                            if CacheInputs[model] and (not (strfind(unit, "^party") or strfind(unit, "^raid")) or (CacheButtons[frame]["group"] and tostring((CacheButtons[frame]["group"]:GetSelection() or 1) - 1) == tostring(index))) then
                                CacheInputs[model]:SetText(GetPortraitModel(frame)[tonumber(index or 1)])
                            end
                        end,
                        function()
                            if CacheInputs[model] then
                                local scale   = C.unitframes[config][CIK[3][2]]
                                local x, y, z = strsplit(",", C.unitframes[config][CIK[4][2]]) 
                                local angle   = C.unitframes[config][CIK[5][2]]
                                local camera  = C.unitframes[config][CIK[13][2]]

                                RefreshCacheCtrlStatus(nil, parent, scale, x, y, z, angle, camera + 1)
                            end
                        end
                    )
                end
            end

            portrait.model:SetScript("OnShow", function()
                local parent = this:GetParent()  -- portrait
                local index  = ({ strfind(parent.parent.fname, "(%d+)") })[3]

                if OnShowOld then
                    OnShowOld()
                end
                
                if C.unitframes[CIK[8][2]] == "1" and parent.category[CIK[2][2]] == "1" then
                    this:SetUnit(gsub(strlower(parent.parent.fname), "group", "party"))
                end
            end)
            
            -- fired when unitframes show/hide or lost unitframe components
            portrait.model:SetScript("OnHide", function()
                local parent = this:GetParent()  -- portrait
                local index  = ({ strfind(parent.parent.fname, "(%d+)") })[3]
                local unit   = gsub(strlower(parent.parent.fname), "group", "party")

                if OnHideOld then
                    OnHideOld()
                end
                
                if C.unitframes[CIK[8][2]] == "1" and parent.category[CIK[2][2]] == "1" then
                    if CacheButtons[frame] then
                        -- it's not group or raid
                        if not index then
                            DisableCtrls()
                            RefreshCacheCtrlStatus(frame, nil, 1, 0, 0, 0, 0, 1)

                            CacheInputs[format("%s:model", frame)]:SetText(UNKNOWN_MODEL)
                        elseif CacheButtons[frame]["group"] and tostring((CacheButtons[frame]["group"]:GetSelection() or 1) - 1) == tostring(index) then
                            CacheButtons[frame]["group"]:SetSelection(1)
                            CacheButtons[frame]["group"].menu[1].func()
                        end
                    end

                    -- if parent.parent:IsShown() and parent.location == "bar" and not this:IsShown() then
                    --     if this:GetModelScale() == 1 then
                    --         this:SetCamera(0)
                    --     else
                    --         this:SetModelScale(2.5)
                    --         this:SetPosition(0, 0, -0.5)
                    --     end

                    --     this:SetModel("Interface\\Buttons\\TalkToMeQuestionMark.mdx")
                    --     this:Show()
                    -- end
                end
            end)
        end

        return callback
    end

    local function noop() end

    local function GenOptions(c, f, ufunc)
        local model   = format("%s:model", f)
        local umodel  = not (strfind(f, "^group") or strfind(f, "^raid")) and GetPortraitModel(f)[1] or UNKNOWN_MODEL
        local options = {
            [1]  = { nil, CIK[1][1], nil, nil, "header" },
            [2]  = { ufunc, CIK[2][1], C.unitframes[c], CIK[2][2], "checkbox" },
            [3]  = { noop, CIK[11][1], C.unitframes[c], nil, "buttonx", { tab = f, key = "restore", text = CIK[11][3], callback = function() PortraitRestoreClickHandler(f); this:Disable() end, width = 96 } },
            [4]  = { function() PortraitPartyMemberChangeHandler(c, f, CIK[14][2]) end, CIK[14][1], caches[f], CIK[14][2], "dropdown", function() return pfUI.gui.dropdowns.partymember, { tab = f, key = "group" } end },
            [5]  = { function() PortraitPartyMemberChangeHandler(c, f, CIK[14][2]) end, CIK[14][1], caches[f], CIK[14][2], "dropdown", function() return pfUI.gui.dropdowns.raidmember, { tab = f, key = "group" } end },
            [6]  = { function() LoadPortraitModelConfig(c, f, ({ CacheButtons[f]["model"]:GetSelection() })[2], caches[f][CIK[14][2]]) end, CIK[15][1], caches[f], CIK[15][1], "dropdown", function() return GenerateCacheConfigDropdownItems(function(v, k) return k ~= f end, 2, true), { tab = f, key = "model" } end },
            [7]  = { noop, CIK[16][1], {}, "none", { "textx", "buttonx", "buttonx" }, 
                {
                    length = 3,
                    { text = umodel, tab = f, key = model, readonly = true, align = "CENTER", width = 180, ofx = -102 },
                    { text = CIK[16][3], tab = f, key = "save", callback = function() UpdateConfig(c, f, CacheInputs[model]:GetText()); this:Disable(); CacheButtons[f]["remove"]:Enable() end, disable = not IsModifiedConfig(c, f, umodel), width = 46, ofx = -52 },
                    { text = CIK[16][4], tab = f, key = "remove", callback = function() PortraitRemoveConfigClickHandler(f); this:Disable() end, disable = not HasConfig(c, f, umodel), width = 46 }
                }
            },
            [8]  = { function() SetPortraitCamera(f, caches[f][CIK[14][2]], C.unitframes[c][CIK[13][2]]); RefreshSaveButtonStatus(c, f) end, CIK[13][1], C.unitframes[c], CIK[13][2], "dropdown", function() return pfUI.gui.dropdowns.camera, { tab = f, key = "camera" } end },
            [9]  = { function() SetPortraitAlpha(f, C.unitframes[c][CIK[12][2]]) end, CIK[12][1], C.unitframes[c], CIK[12][2], "slider", { tab = f, key = "alpha", tips = CIK[12][3], text = CIK[12][4], val = C.unitframes[c][CIK[12][2]] or 0.35 } },
            [10] = { function() SetPortraitScale(f, caches[f][CIK[14][2]], C.unitframes[c][CIK[3][2]]); RefreshSaveButtonStatus(c, f) end, CIK[3][1], C.unitframes[c], CIK[3][2], "slider", { tab = f, key= "scale", tips = CIK[3][3], text = CIK[3][4], val = C.unitframes[c][CIK[3][2]] or 1, min = 0.1, max = 10, step = 0.05 } },
            [11] = { function() SetPortraitPosition(f, caches[f][CIK[14][2]], strsplit(",", C.unitframes[c][CIK[4][2]])); RefreshSaveButtonStatus(c, f) end, CIK[4][1], C.unitframes[c], CIK[4][2], "slider", { callback = PortraitPositionChangeHandler, tips = CIK[4][3], text = "x", val = strsplit(",", C.unitframes[c][CIK[4][2]]) or 0, min = -30.00, max = 5, step = 0.01, disable = true, ref = "scale", key = "posx", tab = f } },
            [12] = { function() SetPortraitPosition(f, caches[f][CIK[14][2]], strsplit(",", C.unitframes[c][CIK[4][2]])); RefreshSaveButtonStatus(c, f) end, "", C.unitframes[c], CIK[4][2], "slider", { callback = PortraitPositionChangeHandler, tips = CIK[4][3], text = "y", val = ({ strsplit(",", C.unitframes[c][CIK[4][2]]) })[2] or 0, min = -30.00, max = 5, step = 0.01, disable = true, ref = "scale", key = "posy", tab = f } },
            [13] = { function() SetPortraitPosition(f, caches[f][CIK[14][2]], strsplit(",", C.unitframes[c][CIK[4][2]])); RefreshSaveButtonStatus(c, f) end, "", C.unitframes[c], CIK[4][2], "slider", { callback = PortraitPositionChangeHandler, tips = CIK[4][3], text = "z", val = ({ strsplit(",", C.unitframes[c][CIK[4][2]]) })[3] or 0, min = -30.00, max = 5, step = 0.01, disable = true, ref = "scale", key = "posz", tab = f } },
            [14] = { function() SetPortraitFacing(f, caches[f][CIK[14][2]], C.unitframes[c][CIK[5][2]]); RefreshSaveButtonStatus(c, f) end, CIK[5][1], C.unitframes[c], CIK[5][2], "slider", { tips = CIK[5][3], text = CIK[5][4], val = C.unitframes[c][CIK[5][2]] or 0, min = -5, max = 5, step = 0.05, disable = true, ref = "scale", key = "angle", tab = f } },
            [15] = { 
                function() 
                    local w, h = strsplit(",", C.unitframes[c][CIK[6][2]])
                    local x, y = strsplit(",", C.unitframes[c][CIK[7][2]] or "0,0")

                    SetPortraitSize(f, caches[f][CIK[14][2]], w, h, x, y)
                end, 
                CIK[6][1], C.unitframes[c], CIK[6][2], "slider", 
                { 
                    length = 2,
                    { callback = PortraitSizeChangeHandler, tab = f, key = "width", tips = CIK[6][3], text = CIK[6][4], val = strsplit(",", C.unitframes[c][CIK[6][2]] or "120,48"), min = -1, max = 300, step = 1, width = 100, ofx = -175 },
                    { callback = PortraitSizeChangeHandler, tab = f, key = "height", tips = CIK[6][3], text = CIK[6][5], val = ({ strsplit(",", C.unitframes[c][CIK[6][2]] or "120,48") })[2], min = -1, max = 300, step = 1, width = 100 }
                }
            },
            [16] = { function() SetPortraitOffset(f, strsplit(",", C.unitframes[c][CIK[7][2]])) end, CIK[7][1], C.unitframes[c], CIK[7][2], "slider", 
                { 
                    length = 2,
                    { callback = PortraitOffsetChangeHandler, tips = CIK[7][3], text = CIK[7][4], val = strsplit(",", C.unitframes[c][CIK[7][2]] or "0,0"), min = -300, max = 300, step = 1, width = 100, ofx = -175, disable = true, ref = "size", key = "ofx", tab = f },
                    { callback = PortraitOffsetChangeHandler, tips = CIK[7][3], text = CIK[7][5], val = ({ strsplit(",", C.unitframes[c][CIK[7][2]] or "0,0") })[2], min = -300, max = 300, step = 1, width = 100, disable = true, ref = "size", key = "ofy", tab = f }
                }
            }
        }

        return function(index)
            return options[index][1], options[index][2], options[index][3], options[index][4], options[index][5], options[index][6]
        end
    end

    --[[
        REGION: main setups    
    --]]
    local function Setup(settings)
        local c, t, f = settings[1], settings[2], settings[3]
        local UFGeneral = UnitFrames[t].area.scroll.content
        local OnShowOld = UFGeneral:GetScript("OnShow")
        local ufunc, options

        -- hook OnShow handler
        -- render to unitframes only when global enabled
        if c and C.unitframes[CIK[8][2]] == "1" then
            caches[f] = {}
            ufunc     = ConfigUpdateHandler(c, f)
            options   = GenOptions(c, f, ufunc)

            -- GUI config initial
            if not (strfind(f, "^group") or strfind(f, "^raid")) then
                C.unitframes[c][CIK[3][2]]  = "1"
                C.unitframes[c][CIK[4][2]]  = "0.00,0.00,0.00"
                C.unitframes[c][CIK[5][2]]  = "0"
                C.unitframes[c][CIK[13][2]] = "0"
            end

            UFGeneral:SetScript("OnShow", function()
                -- release hook
                this:SetScript("OnShow", OnShowOld)

                OnShowOld()

                -- portrait enhance
                CreateConfig(options(1))
                CreateConfig(options(2))
                CreateConfigEx(options(3))
                if strfind(f, "^group") then CreateConfigEx(options(4)) elseif strfind(f, "^raid") then CreateConfigEx(options(5)) end
                CreateConfigEx(options(6))
                CreateConfigEx(options(7))
                CreateConfigEx(options(8))
                CreateConfigEx(options(9))
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(options(10))
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(options(11))
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(options(12))
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(options(13))
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(options(14))
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(options(15))
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(options(16))
                -- CreateConfigEx(noop, "3D模型配置项", {}, "none", { "textx", "buttonx", "buttonx" }, {
                --     length = 3,
                --     { text = umodel, tab = f, key = model, readonly = true, align = "CENTER", width = 200, ofx = -87 },
                --     { text = "添加", tab = f, key = "save", callback = function() UpdateConfig(c, f, CacheInputs[model]:GetText()); this:Disable(); CacheButtons[f]["remove"]:Enable() end, disable = not IsModifiedConfig(c, f, umodel), width = 37.5, ofx = -44.5 },
                --     { text = "删除", tab = f, key = "remove", callback = function() PortraitRemoveConfigClickHandler(f); this:Disable() end, disable = not HasConfig(c, f, umodel), width = 37.5 }
                -- })

                ufunc()
            end)
        elseif not c then
            -- general tab
            UFGeneral:SetScript("OnShow", function()
                -- release hook
                this:SetScript("OnShow", OnShowOld)

                OnShowOld()

                -- portrait enhance
                CreateConfig(nil, CIK[1][1], nil, nil, "header")

                CreateConfig(nil, CIK[8][1], C.unitframes, CIK[8][2], "checkbox")
                CreateConfigEx(nil, CIK[9][1], C.unitframes, nil, { "buttonx", "share" }, {
                    length = 2,
                    { 
                        text = CIK[9][3], 
                        callback = function() 
                            CreateQuestionDialog(CIK[9][5], function()
                                ClearPortraitModuleConfigurations()
                                ReloadUI()
                            end) 
                        end 
                    },
                    {
                        text = CIK[9][4], 
                        callback = function() this:GetParent().share:Show() end,
                        ofx = -87
                    }
                })
                CreateConfigEx(function() CacheButtons["general"]["clone"]:Enable() end, CIK[17][1], caches, CIK[17][2], { "dropdown", "buttonx" }, {
                    length = 2,
                    function() return pfUI.gui.dropdowns.modelconfigurations, { ofx = -85, tab = "general", key = "data" } end,
                    { text = CIK[17][3], callback = PortraitCloneConfigClickHandler, disable = true, tab = "general", key = "clone" }
                })
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(function() SetPortraitAlpha(f, C.unitframes[CIK[10][2]]); ResetPortraitModuleConfigurations({{ "alpha", C.unitframes[CIK[10][2]] }}) end, CIK[10][1], C.unitframes, CIK[10][2], "slider", { tips = CIK[10][3], text = CIK[10][4], val = C.unitframes[CIK[10][2]] or 0.35 })
            end)
        end
    end

    local unitframeSettings = {
        --      config,        text                       frame
        [1]  = {"player",      T["Player"],               "player"            },
        [2]  = {"target",      T["Target"],               "target"            },
        [3]  = {"ttarget",     T["Target-Target"],        "targettarget"      },
        [4]  = {"tttarget",    T["Target-Target-Target"], "targettargettarget"},
        [5]  = {"pet",         T["Pet"],                  "pet"               },
        [6]  = {"ptarget",     T["Pet-Target"],           "pettarget"         },
        [7]  = {"focus",       T["Focus"],                "focus"             },
        [8]  = {"focustarget", T["Focus-Target"],         "focustarget"       },
        [9]  = {"group",       T["Group"],                "group"             },
        [10] = {"grouptarget", T["Group-Target"],         "grouptarget"       },
        [11] = {"grouppet",    T["Group-Pet"],            "grouppet"          },
        [12] = {"raid",        T["Raid"],                 "raid"              },
        [13] = {nil,           T["General"],              nil                 }
    }

    -- dropdown lists
    pfUI.gui.dropdowns["camera"] = {
        "0:" .. T["Facial Feature"],
        "1:" .. T["Front View"],
        "2:" .. T["Top View"]
    }

    pfUI.gui.dropdowns["partymember"] = {
        "0: ",
        "1:" .. T["Party Member"] .. " 1",
        "2:" .. T["Party Member"] .. " 2",
        "3:" .. T["Party Member"] .. " 3",
        "4:" .. T["Party Member"] .. " 4"
    }

    pfUI.gui.dropdowns["raidmember"] = { "0: " }

    for i = 1, 40 do
        table.insert(pfUI.gui.dropdowns["raidmember"], format("%d:%s %d", i, T["Raid Member"], i))
    end

    pfUI.gui.dropdowns["modelconfigurations"] = GenerateCacheConfigDropdownItems(player)

    -- setup rainbowbar
    for _, data in ipairs(unitframeSettings) do
        Setup(data)
    end
end)
