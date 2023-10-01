pfUI:RegisterModule("protraitenhance", "vanilla:tbc", function ()
    if C.unitframes["always2dportrait"] == "1" then return end

    local CreateConfig, UnitFrames = pfUI.gui.CreateConfig, pfUI.gui.frames[T["Unit Frames"]]
    -- local strlen, strsplit, strjoin, strfind, strsub, gsub, format, tonumber = strlen, strsplit, strjoin, strfind, strsub, gsub, format, tonumber
    -- local GetRealmName, UnitName = GetRealmName, UnitName
    local strjoin, serialize, compress, decompress, enc, dec = unpack(UAPI)
    local CreateSliderFrame, CreateButtonxFrame, CreateTextxFrame, CreateShareFrame, CreateComboboxFrame = unpack(UWGT)
    local CacheSliders    = {}
    local CacheButtons    = {}
    local CacheInputs     = {}
    local caches          = {}
    local CacheAnimations = {}
    local globaltimer

    local UNKNOWN_MODEL          = "TalkToMeQuestionMark"
    local DEFAULT_PORTRAIT_ALPHA = 0.35
    local DEFAULT_ANIM_SEQUENCE  = "0"
    local DEFAULT_ANIM_SPEED     = 1000
    local DEFAULT_ANIM_DURATION  = 3500
    local DEFAULT_ANIM_OPTION    = format("%.1f,%.1f", DEFAULT_ANIM_SPEED / 1000, DEFAULT_ANIM_DURATION / 1000)

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
        --       caption                                                   key                              extracap1                                   extracap2                                 extracap3
        [1]  = { T["3D Portrait Enhance"],                                 nil,                             nil,                                        nil,                                      nil                                                                                    },
        [2]  = { T["Enable 3D Portrait Enhance"],                          "portrait3d_enable",             nil,                                        nil,                                      nil                                                                                    },
        [3]  = { T["3D Portrait Model Scale"],                             "portrait3d_scale",              T["Set "] .. T["3D Portrait Model Scale"],  T["Scale"],                               nil                                                                                    },
        [4]  = { T["3D Portrait Position"],                                "portrait3d_position",           T["Set "] .. T["3D Portrait Position"],     nil,                                      nil                                                                                    },
        [5]  = { T["3D Portrait Model Facing"],                            "portrait3d_facing",             T["Set "] .. T["3D Portrait Model Facing"], T["Angle Value"],                         nil                                                                                    },
        [6]  = { T["3D Portrait Model Size"],                              "portrait3d_size",               T["Set "] .. T["3D Portrait Model Size"],   T["Portrait Width"],                      T["Portrait Height"]                                                                   },
        [7]  = { T["3D Portrait Model Offset"],                            "portrait3d_offset",             T["Set "] .. T["3D Portrait Model Offset"], T["Offset"] .. "x",                       T["Offset"] .. "y"                                                                     },
        [8]  = { T["Enable Global 3D Portrait Enhance"],                   "portrait3d_global_enable",      nil,                                        nil,                                      nil                                                                                    },
        [9]  = { T["Clear Configurations Of 3D Portrait"],                 nil,                             T["Delete profile"],                        T["Share"],                               T["Some settings need to reload the UI to take effect.\nDo you want to reloadUI now?"] },
        [10] = { T["Portrait Alpha"],                                      "portraitalpha",                 T["Set Portrait Alpha Value"],              T["Alpha Value"],                         nil                                                                                    },
        [11] = { T["Reset All Config Of 3D Portrait"],                     nil,                             T["Delete / Reset"],                        nil,                                      nil                                                                                    },
        [12] = { T["Portrait Alpha"],                                      "portrait3d_alpha",              T["Set Portrait Alpha Value"],              T["Alpha Value"],                         nil                                                                                    },
        [13] = { T["3D Portrait Model Camera"],                            "portrait3d_camera",             nil,                                        nil,                                      nil                                                                                    },
        [14] = { T["Select Party Member"],                                 "portrait3d_party_cache",        nil,                                        nil,                                      nil                                                                                    },
        [15] = { T["Load An 3D Portrait Model Config"],                    "portrait3d_config_cache",       nil,                                        nil,                                      nil                                                                                    },
        [16] = { T["3D Portrait Model Config"],                            nil,                             T["Add"],                                   T["Remove"],                              nil                                                                                    },
        [17] = { T["Clone Another Player's 3D Portrait Model Config"],     "portrait3d_model_cache",        T["Clone"],                                 nil,                                      nil                                                                                    },
        [18] = { T["Enable Global Animation Config Of 3D Portrait Model"], "portrait3d_global_anim_enable", T["Reset"],                                 nil,                                      nil                                                                                    },
        [19] = { nil,                                                      "portrait3d_anim_option",        nil,                                        T["Set The Animation's Playback Speed"],  T["Playback Speed"]                                                                    },
        [20] = { nil,                                                      nil,                             nil,                                        T["Set The Animation's Replay Duration"], T["Replay Duration"]                                                                   },
        [21] = { T["3D Portrait Model Animation Config"],                  "portrait3d_anim",               nil,                                        nil,                                      nil                                                                                    }
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
        --                scale      pos x,y,z  facing     size       offset     alpha       camera      anim sequence  anim speed/duration
        -- local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[6][2], CIK[7][2], CIK[12][2], CIK[13][2], CIK[19][2],    CIK[21][2] }
        local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[12][2], CIK[13][2], CIK[19][2], CIK[21][2] }

        if category and C.unitframes[category] and frame and model then
            DB[frame]        = DB[frame] or {}
            DB[frame][model] = DB[frame][model] or {}

            for _, k in ipairs(keys) do
                DB[frame][model][k] = C.unitframes[category][k]
            end
        end
    end

    local function LoadConfig(category, frame, model, cacheitem)
        local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[12][2], CIK[13][2], CIK[19][2], CIK[21][2] }
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
            local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[12][2], CIK[13][2], CIK[19][2], CIK[21][2] }

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

            -- use dropdown/combobox widget
            if (widget == "dropdown" or widget == "combobox") and _G.type(vals) == "function" then
                local menus, opts = vals()  -- for option settings of dropdown widget you need to set values to a function and return extra values

                if frame.input then -- dropdown
                    frame.input:SetPoint("RIGHT", frame, "RIGHT", opts.ofx or 0, opts.ofy or 0)
                    frame.input:SetWidth(opts.width or 180)
                else                -- combobox
                    frame.input = CreateComboboxFrame(nil, frame, opts)
                    frame.input:SetupMenus(menus, category, config, ufunc)
                end

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

        return frame
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

    local function RefreshUnitPortrait(portrait, options)
        if portrait and portrait.model and portrait.model:IsVisible() then
            portrait.model.animation.duration = DEFAULT_ANIM_DURATION
            portrait.model.animation.elapsed  = 0
            portrait.model.animation.sequence = DEFAULT_ANIM_SEQUENCE + 0
            portrait.model.animation.speed    = DEFAULT_ANIM_SPEED

            if options then
                portrait.model.animation.duration = options.anim.duration
                portrait.model.animation.sequence = options.anim.sequence
                portrait.model.animation.speed    = options.anim.speed
            
                portrait.model:SetCamera(options.camera)
                portrait.model:RefreshUnit()  -- only camera = 2 have free rotation style, when it's not equal 2 need to call RefreshUnit
                portrait.model:SetAlpha(options.alpha)
            else
                portrait.model:ClearAllPoints()
                portrait.model:SetWidth(-1)
                portrait.model:SetHeight(-1)
                portrait.model:SetAllPoints(portrait)
                portrait.model:SetCamera(0)
                portrait.model:SetAlpha(portrait.location == "bar" and tonumber(C.unitframes[CIK[10][2]]) or portrait:GetAlpha())
            end

            portrait.model:SetSequenceTime(portrait.model.animation.sequence, portrait.model.animation.elapsed)
        end
    end

    local function RefreshCacheCtrlStatus(frame, portrait, alpha, scale, x, y, z, angle, camera, width, height, ofx, ofy)
        if CacheSliders[frame] and CacheInputs[format("%s:model", frame)]:GetText() ~= UNKNOWN_MODEL then
            CacheSliders[frame]["alpha"]:SetValue(alpha)
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
            
            CacheSliders[frame]["alpha"]:SetEnabled(false)
            CacheSliders[frame]["posx"]:SetEnabled(false)
            CacheSliders[frame]["posy"]:SetEnabled(false)
            CacheSliders[frame]["posz"]:SetEnabled(false)
            CacheSliders[frame]["angle"]:SetEnabled(false)
            CacheSliders[frame]["ofx"]:SetEnabled(false)
            CacheSliders[frame]["ofy"]:SetEnabled(false)
            
            CacheButtons[frame]["camera"]:SetSelection(camera)
            CacheButtons[frame]["camera"].menu[camera].func()
        elseif portrait then
            portrait.model:SetAlpha(alpha)
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
            if p and p.model and p.model:IsVisible() then
                if m ~= UNKNOWN_MODEL then
                    if HasConfig(c, f, m) then
                        LoadConfig(c, f, m)

                        local scale   = C.unitframes[c][CIK[3][2]]
                        local x, y, z = strsplit(",", C.unitframes[c][CIK[4][2]]) 
                        local angle   = C.unitframes[c][CIK[5][2]]
                        local alpha   = C.unitframes[c][CIK[12][2]] or C.unitframes[CIK[10][2]]
                        local camera  = C.unitframes[c][CIK[13][2]]
                        local anim    = _ANIMS[m] and _ANIMS[m][C.unitframes[c][CIK[21][2]]] or { id = DEFAULT_ANIM_SEQUENCE + 0 }
                        
                        RefreshCacheCtrlStatus(f, p, alpha, scale, x, y, z, angle, camera + 1)
                        RefreshUnitPortrait(p, {
                            alpha  = alpha + 0,
                            camera = camera + 0,
                            anim   = {
                                sequence = anim.id,
                                speed    = anim.duration and C.unitframes[c][CIK[19][2]] and strsplit(",", C.unitframes[c][CIK[19][2]]) * 1000 or DEFAULT_ANIM_SPEED,
                                duration = anim.duration and (C.unitframes[c][CIK[19][2]] and ({ strsplit(",", C.unitframes[c][CIK[19][2]]) })[2] * 1000 or anim.duration) or DEFAULT_ANIM_DURATION
                            }
                        })
                    else
                        C.unitframes[c][CIK[3][2]]  = "1"
                        C.unitframes[c][CIK[4][2]]  = "0.00,0.00,0.00"
                        C.unitframes[c][CIK[5][2]]  = "0"
                        C.unitframes[c][CIK[12][2]] = format("%.2f", p.localtion == "bar" and C.unitframes[CIK[10][2]] or p:GetAlpha())
                        C.unitframes[c][CIK[13][2]] = "0"

                        RefreshCacheCtrlStatus(f, p, C.unitframes[CIK[10][2]] + 0, 1, 0, 0, 0, 0, 1)
                        RefreshUnitPortrait(p)
                    end
                else
                    p.model:SetModelScale(4.25)
                    p.model:SetPosition(0, 0, -1)
                    p.model:SetModel("Interface\\Buttons\\TalkToMeQuestionMark.mdx")
                    -- p.model:Show()
                end
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
        alpha         = C.unitframes[category][CIK[12][2]] or C.unitframes[CIK[10][2]]
        width, height = strsplit(",", C.unitframes[category][CIK[6][2]]) 
        ofx, ofy      = strsplit(",", C.unitframes[category][CIK[7][2]]) 
        
        RefreshCacheCtrlStatus(frame, nil, alpha, scale, x, y, z, angle, camera + 1)
        -- SetPortraitAlpha(frame, alpha)
        SetPortraitSize(frame, index, width, height, ofx, ofy, true)
        SetPortraitCamera(frame, index, camera)
    end

    local function ResetPortrait(frame)
        local portraits = GetPortraits(frame)

        for _, portrait in ipairs(portraits) do
            RefreshUnitPortrait(portrait)
        end
    end

    local function ResetPortraitModuleConfig(category, key, val)
        local conf = category and C.unitframes[category] or C.unitframes

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
            { CIK[8][2],  nil },
            { CIK[18][2], nil },

            -- unitframe config
            -- when callee is general won't find any thus keys behind
            { CIK[2][2],  nil },
            { CIK[3][2],  nil },
            { CIK[4][2],  nil },
            { CIK[5][2],  nil },
            { CIK[6][2],  nil },
            { CIK[7][2],  nil },
            { CIK[12][2], nil },
            { CIK[13][2], nil },

            -- common config
            { CIK[19][2], nil },
            { CIK[21][2], nil }
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

    local function PortraitSizeAndOffsetChangeHandler()
        local parent  = this:GetParent()
        local sliders = parent.sliders
        
        parent.category[parent.config] = format("%d,%d", sliders[1]:GetValue(), sliders[2]:GetValue())
    end

    local function PortraitRestoreClickHandler(frame)
        local id        = (strfind(frame, "^group") or strfind(frame, "^raid")) and ((CacheButtons[frame]["group"]:GetSelection() or 1) - 1) or 1
        local portrait  = id > 0 and GetPortraits(frame)[id] or nil

        if portrait then
            RefreshCacheCtrlStatus(frame, portrait, C.unitframes[CIK[10][2]], 1, 0, 0, 0, 0, 1)
            RefreshUnitPortrait(portrait)
        end
    end

    local function PortraitRemoveConfigClickHandler(frame)
        RemoveConfig(frame, CacheInputs[format("%s:model", frame)]:GetText())
        PortraitRestoreClickHandler(frame)
    end

    local function PortraitCloneConfigClickHandler()
        CreateQuestionDialog(CIK[9][5], function()
            --                scale      pos x,y,z  facing     size       offset     alpha       camera      anim sequence  anim speed/duration
            -- local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[6][2], CIK[7][2], CIK[12][2], CIK[13][2], CIK[19][2],    CIK[21][2] }
            local keys = { CIK[3][2], CIK[4][2], CIK[5][2], CIK[12][2], CIK[13][2], CIK[19][2], CIK[21][2] }
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

    local function RefreshSaveButtonStatus(category, frame)
        if IsModifiedConfig(category, frame, CacheInputs[format("%s:model", frame)]:GetText()) then
            CacheButtons[frame]["save"]:Enable()
        else
            CacheButtons[frame]["save"]:Disable()
        end
    end

    local function GetAnimationMenus(model)
        local menus = { "0:".. T["Defaults"] }
        local keys  = {}

        for k, _ in pairs(_ANIMS[model] or {}) do
            table.insert(keys, k)
        end

        table.sort(keys)

        for _, k in ipairs(keys) do
            table.insert(menus, format("%s:%s", k, L["animations"][k]))
        end

        return menus
    end

    local function PortraitAnimationSequanceChangeHandler(category, frame)
        local model  = CacheInputs[format("%s:model", frame)]:GetText()
        local key    = C.unitframes[category][CIK[21][2]]
        local anim   = _ANIMS[model] and _ANIMS[model][key] or { id = DEFAULT_ANIM_SEQUENCE, duration = DEFAULT_ANIM_DURATION }
        local option = { DEFAULT_ANIM_SPEED / 1000, anim.duration / 1000 }
        
        C.unitframes[category][CIK[19][2]] = format("%.1f,%.1f", option[1], option[2])
        
        if HasConfig(category, frame, model) then
            LoadConfig(category, frame, model)
        end
        
        if C.unitframes[category][CIK[21][2]] ~= key then
            C.unitframes[category][CIK[21][2]] = key
        end
        
        option = { strsplit(",", C.unitframes[category][CIK[19][2]] or DEFAULT_ANIM_OPTION) }

        CacheAnimations:SetItemValue(frame, "sequence", anim.id, tonumber(caches[frame][CIK[14][2]]))
        CacheSliders[frame]["anim_speed"]:SetValue(tonumber(option[1]))
        CacheSliders[frame]["anim_duration"]:SetValue(tonumber(option[2]))
    end

    local function PortraitAnimationOptionChangeHandler(category, frame, option, val)
        local model   = category and CacheInputs[format("%s:model", frame)]:GetText() or nil
        local ufconf  = category and C.unitframes[category] or C.unitframes
        local anim    = _ANIMS[model] and _ANIMS[model][ufconf[CIK[21][2]]] or { id = DEFAULT_ANIM_SEQUENCE, duration = DEFAULT_ANIM_DURATION }
        local options = { strsplit(",", ufconf[CIK[19][2]]) }
        local keys    = { speed = 1, duration = 2 }
        local btn     = CacheButtons[frame]["anim_reset"]
        
        if options[keys[option]] ~= format("%.1f", val) then
            options[keys[option]] = tonumber(val)
            ufconf[CIK[19][2]]    = format("%.1f,%.1f", options[1], options[2])
        end
        
        if ufconf[CIK[19][2]] == format("%.1f,%.1f", DEFAULT_ANIM_SPEED / 1000, anim.duration / 1000) then
            btn:Disable()
        elseif not btn:IsEnabled() or btn:IsEnabled() == 0 then
            btn:Enable()
        end

        CacheAnimations:SetItemValue(frame, option, options[keys[option]] * 1000, category and tonumber(caches[frame][CIK[14][2]]))

        if category and frame then
            RefreshSaveButtonStatus(category, frame)
        end
    end

    local function PortraitPartyMemberChangeHandler(category, frame, cachekey)
        local models, portraits = GetPortraitModel(frame)
        local id = tonumber(caches[frame][cachekey] or 0)
        local mtext = id > 0 and models[id] or UNKNOWN_MODEL
        local alpha, scale, x, y, z, angle, camera
        
        CacheInputs[format("%s:model", frame)]:SetText(mtext)

        -- reset animation menus
        CacheButtons[frame]["anims"]:SetupMenus(GetAnimationMenus(mtext), C.unitframes[category], CIK[21][2], 
            function() 
                PortraitAnimationSequanceChangeHandler(category, frame)
            end
        )
        PortraitAnimationSequanceChangeHandler(category, frame)

        if mtext ~= UNKNOWN_MODEL then
            if HasConfig(category, frame, mtext) then
                LoadConfig(category, frame, mtext)
                
                alpha   = C.unitframes[category][CIK[12][2]] or C.unitframes[CIK[10][2]]
                scale   = C.unitframes[category][CIK[3][2]]
                x, y, z = strsplit(",", C.unitframes[category][CIK[4][2]]) 
                angle   = C.unitframes[category][CIK[5][2]]
                camera  = C.unitframes[category][CIK[13][2]]

                RefreshCacheCtrlStatus(frame, nil, alpha, scale, x, y, z, angle, camera + 1)
            else
                RefreshCacheCtrlStatus(frame, nil, C.unitframes[CIK[10][2]], 1, 0, 0, 0, 0, 1)
            end
        end

        for _, slider in ipairs(CacheSliders[frame]) do
            slider:SetEnabled(not slider.ref and mtext ~= UNKNOWN_MODEL)
        end

        for _, button in ipairs(CacheButtons[frame]) do
            if (button.key == "save" and not IsModifiedConfig(category, frame, mtext)) 
                or (button.key == "remove" and not HasConfig(category, frame, mtext)) 
                or (mtext == UNKNOWN_MODEL and button.key ~= "group" and button.key ~= "raid") 
            then
                button:Disable()
            else
                button:Enable()
            end
        end

        if id == 0 then
            RefreshCacheCtrlStatus(frame, nil, C.unitframes[CIK[10][2]], 1, 0, 0, 0, 0, 1)
        end
    end

    local function ConfigUpdateHandler(category, frame)
        local model           = format("%s:model", frame)
        local IsGroupOrRaid   = strfind(frame, "^group") or strfind(frame, "^raid")
        local IsInGroupOrRaid = IsGroupOrRaid and (UnitInParty("player") or UnitInRaid("player"))
        local EnableCtrls     = function()
            if CacheInputs[model] then
                local mtext = CacheInputs[model]:GetText()

                for _, slider in ipairs(CacheSliders[frame]) do
                    if not slider.ref then
                        slider:SetEnabled(C.unitframes[category][CIK[2][2]] == "1" and mtext ~= UNKNOWN_MODEL)
                    elseif C.unitframes[category][CIK[2][2]] == "0" then
                        slider:SetEnabled(false)
                    end
                end

                for _, button in ipairs(CacheButtons[frame]) do
                    if C.unitframes[category][CIK[2][2]] ~= "1"
                        or (button.key == "save" and not IsModifiedConfig(category, frame, mtext)) 
                        or (button.key == "remove" and not HasConfig(category, frame, mtext))
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
                invoke(category, frame, nil, 
                    function()
                        if CacheInputs[model] then
                            CacheInputs[model]:SetText(not IsGroupOrRaid and GetPortraitModel(frame)[1] or UNKNOWN_MODEL)
                        end
                    end,
                    function()
                        PortraitAnimationSequanceChangeHandler(category, frame)
                    end
                )
            end
        end
        local portraits = GetPortraits(frame)
        
        -- hooks
        for pid, portrait in ipairs(portraits) do
            local SetAlphaOld    = portrait.SetAlpha
            local SetUnitOld     = portrait.model.SetUnit
            local OnShowOld      = portrait.model:GetScript("OnShow")
            local OnHideOld      = portrait.model:GetScript("OnHide")
            local OnUpdateOld    = portrait.model:GetScript("OnUpdate")
            local OnMouseDownOld = portrait.model:GetScript("OnMouseDown")
            local OnMouseUpOld   = portrait.model:GetScript("OnMouseUp")

            portrait.category = C.unitframes[category]
            portrait.location = portrait.parent.config.portrait
            
            -- we need to hook SetAlpha method cause of if portrait is vendor on hp bar will always call when OnUpdate is fired
            portrait.SetAlpha = function(self, alpha, force)
                if C.unitframes[CIK[8][2]] == "1" and self.category[CIK[2][2]] == "1" then
                    local mtext   = ({ strfind(tostring(self.model:GetModel()), [[%\([^%\]+)$]]) })[3]
                    local opacity = self:GetAlpha()
                    
                    if force then
                        self.model:SetAlpha(alpha)
                    elseif HasConfig(category, frame, mtext) then
                        if opacity > self.model:GetAlpha() then
                            LoadConfig(category, frame, mtext)

                            self.model:SetAlpha(opacity > tonumber(self.category[CIK[12][2]]) and self.category[CIK[12][2]] + 0 or opacity)  -- keep model alpha never over the portrait
                        end
                    else
                        SetAlphaOld(self, alpha)
                    end
                    
                    -- refresh unit portrait rendor while portrait location is update
                    if self.location ~= self.parent.config.portrait then
                        self.location = self.parent.config.portrait
                        
                        if self.location ~= "off" then
                            self.model:SetUnit(gsub(strlower(self.parent.fname), "group", "party"))
                        end
                    end
                else
                    SetAlphaOld(self, alpha)
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
                    local mtext = GetPortraitModel(frame)[tonumber(index or 1)]

                    invoke(category, frame, unit, 
                        function()
                            if CacheInputs[model] and (not (strfind(unit, "^party") or strfind(unit, "^raid")) or (CacheButtons[frame]["group"] and tostring((CacheButtons[frame]["group"]:GetSelection() or 1) - 1) == tostring(index))) then
                                CacheInputs[model]:SetText(mtext)
                            end

                            C.unitframes[category][CIK[19][2]] = DEFAULT_ANIM_OPTION
                            C.unitframes[category][CIK[21][2]] = DEFAULT_ANIM_SEQUENCE
                        end,
                        function()
                            local anim   = mtext and _ANIMS[mtext] and _ANIMS[mtext][C.unitframes[category][CIK[21][2]]] or {}
                            local option = { strsplit(",", C.unitframes[category][CIK[19][2]] or DEFAULT_ANIM_OPTION) }
                            
                            CacheAnimations:SetItem(frame, { anim.id, option[1] * 1000, option[2] * 1000 }, tonumber(index or 0))

                            if CacheInputs[model] then
                                local alpha   = C.unitframes[category][CIK[12][2]] or C.unitframes[CIK[10][2]]
                                local scale   = C.unitframes[category][CIK[3][2]]
                                local x, y, z = strsplit(",", C.unitframes[category][CIK[4][2]]) 
                                local angle   = C.unitframes[category][CIK[5][2]]
                                local camera  = C.unitframes[category][CIK[13][2]]

                                RefreshCacheCtrlStatus(nil, parent, alpha, scale, x, y, z, angle, camera + 1)
                            end

                            if CacheButtons[frame] and CacheButtons[frame]["anims"] then
                                CacheButtons[frame]["anims"]:SetupMenus(GetAnimationMenus(mtext), C.unitframes[category], CIK[21][2], 
                                    function() 
                                        PortraitAnimationSequanceChangeHandler(category, frame)
                                    end
                                )
                                PortraitAnimationSequanceChangeHandler(category, frame)
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
                            RefreshCacheCtrlStatus(frame, nil, C.unitframes[CIK[10][2]], 1, 0, 0, 0, 0, 1)

                            CacheInputs[format("%s:model", frame)]:SetText(UNKNOWN_MODEL)
                        elseif CacheButtons[frame]["group"] and tostring((CacheButtons[frame]["group"]:GetSelection() or 1) - 1) == tostring(index) then
                            CacheButtons[frame]["group"]:SetSelection(1)
                            CacheButtons[frame]["group"].menu[1].func()
                        end

                        if CacheButtons[frame]["anims"] then
                            CacheButtons[frame]["anims"]:SetSelection(1)
                            CacheButtons[frame]["anims"].menu[1].func()
                        end
                    end
                end
            end)

            -- init animation options cache
            if not CacheAnimations:GetItem(frame, pid) then
                CacheAnimations:SetItem(frame, nil, pid)
            end
            
            portrait.model.animation = CacheAnimations:GetItem(frame, pid)

            -- display animation frames by OnUpdate
            portrait.model:SetScript("OnUpdate", function()
                if OnUpdateOld then
                    OnUpdateOld()
                end
                
                if this.animation and this.animation.sequence > 0 then
                    if C.unitframes[CIK[18][2]] == "1" then
                        this:SetSequenceTime(this.animation.sequence, CacheAnimations["general"].elapsed)
                    else
                        this.animation.elapsed = this.animation.elapsed + arg1 * this.animation.speed
                        this:SetSequenceTime(this.animation.sequence, this.animation.elapsed)

                        if this.animation.elapsed >= this.animation.duration then
                            this.animation.elapsed = 0
                        end
                    end
                end

                if this:GetParent().category[CIK[13][2]] == "1" then
                    if IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown() then
                        this:EnableMouse(true)
                    else
                        this:EnableMouse(false)
                    end

                    if this.delta then
                        if this.delta.dx then
                            this.delta.dx = this.delta.dx - this.delta.dt

                            this:SetRotation(this.delta.dx + this.delta.ox)

                            if abs(this.delta.dx) <= 0.005 then
                                this:GetScript("OnAnimFinished")()
                            end
                        else
                            this:SetRotation((GetCursorPosition() - this.delta.x) / 20 + this.delta.ox)
                        end
                    end
                end
            end)

            -- enable mouse motions
            -- portrait.model:EnableMouse(true)
            portrait.model:SetScript("OnMouseDown", function()
                if OnMouseDownOld then 
                    OnMouseDownOld() 
                end
                
                this.delta = { x = GetCursorPosition(), ox = tonumber(this:GetParent().category[CIK[5][2]]) }
            end)

            portrait.model:SetScript("OnMouseUp", function()
                if OnMouseUpOld then 
                    OnMouseUpOld()
                end

                this:EnableMouse(false)
                
                this.delta.dx = (GetCursorPosition() - this.delta.x) / 20
                this.delta.dt = this.delta.dx / 12
            end)

            -- in 1.12.1 OnAnimFinished is legal script but seems never been called
            -- however we can call it manually just like this -> xxx:GetScript("OnAnimFinished")()
            portrait.model:SetScript("OnAnimFinished", function()
                this.delta = nil
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
            [5]  = { function() PortraitPartyMemberChangeHandler(c, f, CIK[14][2]) end, CIK[14][1], caches[f], CIK[14][2], "combobox", function() return pfUI.gui.dropdowns.raidmember, { tab = f, key = "group", noback = true, nodefault = true } end },
            [6]  = { function() LoadPortraitModelConfig(c, f, ({ CacheButtons[f]["model"]:GetSelection() })[2], caches[f][CIK[14][2]]) end, CIK[15][1], caches[f], CIK[15][1], "combobox", function() return GenerateCacheConfigDropdownItems(function(v, k) return k ~= f end, 2, true), { tab = f, key = "model", noback = true, nodefault = true } end },
            [7]  = { noop, CIK[16][1], {}, "none", { "textx", "buttonx", "buttonx" }, 
                {
                    { text = umodel, tab = f, key = model, readonly = true, align = "CENTER", width = 180, ofx = -102 },
                    { text = CIK[16][3], tab = f, key = "save", callback = function() UpdateConfig(c, f, CacheInputs[model]:GetText()); this:Disable(); CacheButtons[f]["remove"]:Enable() end, disable = not IsModifiedConfig(c, f, umodel), width = 46, ofx = -52 },
                    { text = CIK[16][4], tab = f, key = "remove", callback = function() PortraitRemoveConfigClickHandler(f); this:Disable() end, disable = not HasConfig(c, f, umodel), width = 46 }
                }
            },
            [8]  = { function() SetPortraitCamera(f, caches[f][CIK[14][2]], C.unitframes[c][CIK[13][2]]); RefreshSaveButtonStatus(c, f) end, CIK[13][1], C.unitframes[c], CIK[13][2], "dropdown", function() return pfUI.gui.dropdowns.camera, { tab = f, key = "camera" } end },
            [9]  = { function() SetPortraitAlpha(f, C.unitframes[c][CIK[12][2]]); RefreshSaveButtonStatus(c, f) end, CIK[12][1], C.unitframes[c], CIK[12][2], "slider", { tab = f, key = "alpha", tips = CIK[12][3], text = CIK[12][4], val = C.unitframes[c][CIK[12][2]] or C.unitframes[CIK[10][2]] } },
            [10] = { 
                function() 
                    local w, h = strsplit(",", C.unitframes[c][CIK[6][2]])
                    local x, y = strsplit(",", C.unitframes[c][CIK[7][2]] or "0,0")

                    SetPortraitScale(f, caches[f][CIK[14][2]], C.unitframes[c][CIK[3][2]])
                    SetPortraitSize(f, caches[f][CIK[14][2]], w, h, x, y, true)
                    RefreshSaveButtonStatus(c, f) 
                end, 
                CIK[3][1], C.unitframes[c], CIK[3][2], "slider", 
                { tab = f, key= "scale", tips = CIK[3][3], text = CIK[3][4], val = C.unitframes[c][CIK[3][2]] or 1, min = 0.01, max = 5, step = 0.01 }
            },
            [11] = { function() SetPortraitPosition(f, caches[f][CIK[14][2]], strsplit(",", C.unitframes[c][CIK[4][2]])); RefreshSaveButtonStatus(c, f) end, CIK[4][1], C.unitframes[c], CIK[4][2], "slider", { callback = PortraitPositionChangeHandler, tips = CIK[4][3], text = "x", val = strsplit(",", C.unitframes[c][CIK[4][2]]) or 0, min = -15, max = 15, step = 0.01, disable = true, ref = "scale", key = "posx", tab = f } },
            [12] = { function() SetPortraitPosition(f, caches[f][CIK[14][2]], strsplit(",", C.unitframes[c][CIK[4][2]])); RefreshSaveButtonStatus(c, f) end, "", C.unitframes[c], CIK[4][2], "slider", { callback = PortraitPositionChangeHandler, tips = CIK[4][3], text = "y", val = ({ strsplit(",", C.unitframes[c][CIK[4][2]]) })[2] or 0, min = -15, max = 15, step = 0.01, disable = true, ref = "scale", key = "posy", tab = f } },
            [13] = { function() SetPortraitPosition(f, caches[f][CIK[14][2]], strsplit(",", C.unitframes[c][CIK[4][2]])); RefreshSaveButtonStatus(c, f) end, "", C.unitframes[c], CIK[4][2], "slider", { callback = PortraitPositionChangeHandler, tips = CIK[4][3], text = "z", val = ({ strsplit(",", C.unitframes[c][CIK[4][2]]) })[3] or 0, min = -15, max = 15, step = 0.01, disable = true, ref = "scale", key = "posz", tab = f } },
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
                    { callback = PortraitSizeAndOffsetChangeHandler, tab = f, key = "width", tips = CIK[6][3], text = CIK[6][4], val = strsplit(",", C.unitframes[c][CIK[6][2]] or "120,48"), min = -1, max = 300, step = 1, width = 100, ofx = -175 },
                    { callback = PortraitSizeAndOffsetChangeHandler, tab = f, key = "height", tips = CIK[6][3], text = CIK[6][5], val = ({ strsplit(",", C.unitframes[c][CIK[6][2]] or "120,48") })[2], min = -1, max = 300, step = 1, width = 100 }
                }
            },
            [16] = { function() SetPortraitOffset(f, strsplit(",", C.unitframes[c][CIK[7][2]])) end, CIK[7][1], C.unitframes[c], CIK[7][2], "slider", 
                { 
                    length = 2,
                    { callback = PortraitSizeAndOffsetChangeHandler, tips = CIK[7][3], text = CIK[7][4], val = strsplit(",", C.unitframes[c][CIK[7][2]] or "0,0"), min = -300, max = 300, step = 1, width = 100, ofx = -175, disable = true, ref = "size", key = "ofx", tab = f },
                    { callback = PortraitSizeAndOffsetChangeHandler, tips = CIK[7][3], text = CIK[7][5], val = ({ strsplit(",", C.unitframes[c][CIK[7][2]] or "0,0") })[2], min = -300, max = 300, step = 1, width = 100, disable = true, ref = "size", key = "ofy", tab = f }
                }
            },
            [17] = { function() PortraitAnimationSequanceChangeHandler(c, f) end, CIK[21][1], C.unitframes[c], CIK[21][2], "combobox", function() return GetAnimationMenus(not (strfind(f, "^group") or strfind(f, "^raid")) and GetPortraitModel(f)[1] or UNKNOWN_MODEL), { tab = f, key = "anims", noback = true } end },
            [18] = { noop, "", C.unitframes[c], CIK[19][2], { "buttonx", "slider" }, 
                {
                    { 
                        callback = function() 
                            local model = CacheInputs[format("%s:model", f)]:GetText()
                            local anim  = _ANIMS[model] and _ANIMS[model][C.unitframes[c][CIK[21][2]]] or { duration = DEFAULT_ANIM_DURATION }
                            
                            CacheSliders[f]["anim_speed"]:SetValue(DEFAULT_ANIM_SPEED / 1000)
                            CacheSliders[f]["anim_duration"]:SetValue(anim.duration / 1000)
                            this:Disable()
                        end, 
                        text = CIK[18][3], disable = true, tab = f, key = "anim_reset", width = 50, ofx = -303 
                    },
                    {
                        length = 2,
                        { callback = function(val) PortraitAnimationOptionChangeHandler(c, f, "speed", val) end, tips = CIK[19][4], text = CIK[19][5], val = strsplit(",", C.unitframes[c][CIK[19][2]] or DEFAULT_ANIM_OPTION), min = 0.1, max = 10, step = 0.1, width = 100, ofx = -175, disable = false, tab = f, key = "anim_speed" },
                        { callback = function(val) PortraitAnimationOptionChangeHandler(c, f, "duration", val) end, tips = CIK[20][4], text = CIK[20][5], val = ({ strsplit(",", C.unitframes[c][CIK[19][2]] or DEFAULT_ANIM_OPTION) })[2], min = 0, max = 20, step = 0.1, width = 100, disable = false, tab = f, key = "anim_duration" }
                    }
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
                C.unitframes[c][CIK[12][2]] =  C.unitframes[CIK[10][2]]
                C.unitframes[c][CIK[13][2]] = "0"
                C.unitframes[c][CIK[19][2]] = DEFAULT_ANIM_OPTION
                C.unitframes[c][CIK[21][2]] = DEFAULT_ANIM_SEQUENCE
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
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(options(17))
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(options(18))
                
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
                    function() return pfUI.gui.dropdowns.modelconfigurations, { ofx = -85, tab = "general", key = "data" } end,
                    { text = CIK[17][3], callback = PortraitCloneConfigClickHandler, disable = true, tab = "general", key = "clone" }
                })
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(function() SetPortraitAlpha(f, C.unitframes[CIK[10][2]]); ResetPortraitModuleConfigurations({{ "alpha", C.unitframes[CIK[10][2]] }}) end, CIK[10][1], C.unitframes, CIK[10][2], "slider", { tips = CIK[10][3], text = CIK[10][4], val = C.unitframes[CIK[10][2]] })
            
                -- portrait animation
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfig(
                    function() 
                        local parent = this:GetParent()
                        local category, config = parent.category, parent.config
                        
                        if category[config] == "0" then 
                            CacheButtons["general"]["anim_reset"]:Disable()
                            CacheSliders["general"]["anim_speed"]:SetEnabled()
                            CacheSliders["general"]["anim_duration"]:SetEnabled()
                        else 
                            CacheSliders["general"]["anim_speed"]:SetEnabled(true)
                            CacheSliders["general"]["anim_duration"]:SetEnabled(true)

                            if not category[CIK[19][2]] then 
                                category[CIK[19][2]] = format("%.1f,%.1f", CacheSliders["general"]["anim_speed"]:GetValue(), CacheSliders["general"]["anim_duration"]:GetValue())
                            end

                            if category[CIK[19][2]] ~= DEFAULT_ANIM_OPTION then
                                CacheButtons["general"]["anim_reset"]:Enable()
                            end
                        end 
                    end, 
                    CIK[18][1], C.unitframes, CIK[18][2], "checkbox"
                )
                CreateConfig(nil, nil, nil, nil, "space")
                CreateConfigEx(noop, "", C.unitframes, CIK[19][2], { "buttonx", "slider" }, {
                    { 
                        callback = function() 
                            CacheSliders["general"]["anim_speed"]:SetValue(DEFAULT_ANIM_SPEED / 1000)
                            CacheSliders["general"]["anim_duration"]:SetValue(DEFAULT_ANIM_DURATION / 1000) 
                            this:Disable()
                        end, 
                        text = CIK[18][3], disable = not C.unitframes[CIK[18][2]] or C.unitframes[CIK[18][2]] == "0" or C.unitframes[CIK[19][2]] == DEFAULT_ANIM_OPTION, tab = "general", key = "anim_reset", width = 50, ofx = -303 
                    },
                    {
                        length = 2,
                        { callback = function(val) PortraitAnimationOptionChangeHandler(c, "general", "speed", val) end, tips = CIK[19][4], text = CIK[19][5], val = strsplit(",", C.unitframes[CIK[19][2]] or DEFAULT_ANIM_OPTION), min = 0.1, max = 10, step = 0.1, width = 100, ofx = -175, disable = not C.unitframes[CIK[18][2]] or C.unitframes[CIK[18][2]] == "0", tab = "general", key = "anim_speed" },
                        { callback = function(val) PortraitAnimationOptionChangeHandler(c, "general", "duration", val) end, tips = CIK[20][4], text = CIK[20][5], val = ({ strsplit(",", C.unitframes[CIK[19][2]] or DEFAULT_ANIM_OPTION) })[2], min = 0, max = 20, step = 0.1, width = 100, disable = not C.unitframes[CIK[18][2]] or C.unitframes[CIK[18][2]] == "0", tab = "general", key = "anim_duration" }
                    }
                })
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

    function CacheAnimations.GetItem(self, category, index)
        if strfind(category, "^group") or strfind(category, "^raid") then -- index is required
            if self[category] and type(index) == "number" and index > 0 then
                return self[category][index]
            end

            return nil
        else
            return self[category]
        end
    end

    function CacheAnimations.SetItem(self, category, option, index)
        local category, option, cache = category or "general", option or {}

        if not self[category] then
            self[category] = {}
        end

        if strfind(category, "^group") or strfind(category, "^raid") then -- index is required
            if type(index) == "number" and index > 0 then
                if not self[category][index] then
                    self[category][index] = {}
                end

                cache = self[category][index]
            end
        else
            cache = self[category]
        end

        if cache then
            cache.elapsed  = 0
            cache.sequence = tonumber(option.sequence or option[1] or DEFAULT_ANIM_SEQUENCE)
            cache.speed    = tonumber(option.speed    or option[2] or DEFAULT_ANIM_SPEED)
            cache.duration = tonumber(option.duration or option[3] or DEFAULT_ANIM_DURATION)
        end
    end

    function CacheAnimations.SetItemValue(self, category, key, value, index)
        local cache = self:GetItem(category, index)

        if cache then
            cache[key] = tonumber(value)
        end
    end

    -- init general animation cache
    CacheAnimations:SetItem(nil, { 0, strsplit(",", C.unitframes[CIK[19][2]] or DEFAULT_ANIM_OPTION) * 1000, ({ strsplit(",", C.unitframes[CIK[19][2]] or DEFAULT_ANIM_OPTION) })[2] * 1000 })
    
    globaltimer = C_Timer.NewTicker(0, function()
        local cache = CacheAnimations["general"]

        if cache then
            cache.elapsed = cache.elapsed + arg1 * cache.speed

            if cache.elapsed >= cache.duration then
                cache.elapsed = 0
            end
        end
    end, -1)

    -- init portrait alpha value
    C.unitframes[CIK[10][2]] = C.unitframes[CIK[10][2]] or DEFAULT_PORTRAIT_ALPHA
    
    -- setup portrait3d enhance
    for _, data in ipairs(unitframeSettings) do
        Setup(data)
    end
end)