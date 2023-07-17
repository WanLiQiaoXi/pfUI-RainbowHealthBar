pfUI:RegisterModule("rainbowhealthbar", "vanilla:tbc", function ()
    local CreateConfig, UnitFrames = pfUI.gui.CreateConfig, pfUI.gui.frames[T["Unit Frames"]]
    local GradientCache = {}
    local strfind, gsub, tonumber, ipairs = strfind, gsub, tonumber, ipairs
    local globaltimer

    -- config item keys
    local CIK = { 
        --      caption                                      key
        [1] = { T["Rainbow Health Bar"],                     nil                        },
        [2] = { T["Enable Rainbow Health Bar"],              "rainbowbar"               },
        [3] = { T["Reverse The Rainbow Gradient Direction"], "rainbowbar_reverse"       },
        [4] = { T["Orientation Of Rainbow Gradient"],        "rainbowbar_orientation"   },
        [5] = { T["Enable Global Rainbow Gradient"],         "rainbowbar_global_color"  },
        [6] = { T["Duration Of Rainbow Flash"],              "rainbowbar_duration"      },
        [7] = { T["Enable Fixed Rainbow Texture"],           "rainbowbar_tex_fixed"     },
        [8] = { T["Rainbow Texture Alpha Mode"],             "rainbowbar_tex_alphamode" }
    }

    local TEX_FILTER     = "Interface\\AddOns\\pfUI-RainbowHealthBar\\Textures\\HealthBar_Filter"
    local TEX_TRANSPARENT = "Interface\\AddOns\\pfUI-RainbowHealthBar\\Textures\\HealthBar_Transparent"

    --[[
        REGION: gradients
    --]]
    local function HSLtoRGB(h, s, l)
        if s == 0 then return l, l, l end
        local function to(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < .16667 then return p + (q - p) * 6 * t end
            if t < .5 then return q end
            if t < .66667 then return p + (q - p) * (.66667 - t) * 6 end
            return p
        end
        local q = l < .5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        return to(p, q, h + .33334), to(p, q, h), to(p, q, h - .33334)
    end
    
    local function RGBtoHSL(r, g, b)
        local max, min = math.max(r, g, b), math.min(r, g, b)
        local t = max + min
        local d = max - min
        local h, s, l
    
        if t == 0 then return 0, 0, 0 end
        l = t / 2
    
        s = l > .5 and d / (2 - t) or d / t
    
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
    
        h = h * 0.16667
    
        return h, s, l
    end

    local firstH, firstS, firstL = RGBtoHSL(255/255, 151/255, 3/255)
    local secondH, secondS, secondL = RGBtoHSL(HSLtoRGB( ((firstH * 360) + 67) / 360, firstS, firstL))
    
    function GradientCache:InitGradientCache(category)
        if category and not self[category] then
            self[category] = {
                firstH  = firstH, 
                firstS  = firstS, 
                firstL  = firstL,
                secondH = secondH, 
                secondS = secondS, 
                secondL = secondL
            }
        end
    end

    local function UpdateRainbow(category, global)
        if (category == "general" or GradientCache["general"]) and not global or not (category and GradientCache[category]) then return end

        local gradient = GradientCache["general"] or GradientCache[category]

        gradient.firstH  = gradient.firstH + (1/360)
        gradient.secondH = gradient.secondH + (1/360)

        if gradient.firstH > 1 then
            gradient.firstH = 1/360
        end

        if gradient.secondH > 1 then
            gradient.secondH = 1/360
        end
    end
    
    local function GetRainbow(category)
        if not category then return end

        if not GradientCache[category] then
            GradientCache:InitGradientCache(category)
        end

        local gradient = GradientCache["general"] or GradientCache[category]
        local a, b, c = HSLtoRGB(gradient.firstH, gradient.firstS, gradient.firstL)
        local x, y, z = HSLtoRGB(gradient.secondH, gradient.secondS, gradient.secondL)

        return a, b, c, x, y, z
    end

    local function SetGradient(bar, category, orientation, reverse)
        if bar and bar:IsShown() then
            local minR, minG, minB, maxR, maxG, maxB = GetRainbow(category)
            local orientation = orientation or "HORIZONTAL"

            if reverse then
                return bar:SetGradient(orientation, maxR, maxG, maxB, minR, minG, minB)
            end

            bar:SetGradient(orientation, minR, minG, minB, maxR, maxG, maxB)
        end
    end

    local function ForceUpdateHealthBar(bar, name, orientation, reverse)
        if bar then
            local OnShowOld            = bar:GetScript("OnShow")
            local SetStatusBarColorOld = bar.hp.bar.SetStatusBarColor
            
            -- ban the method SetStatusBarColor, because it will reset rainbow gradient when UI update
            bar.hp.bar.SetStatusBarColor = function() end
            bar:SetScript("OnShow", function()
                OnShowOld()
                SetGradient(self.hp.bar.bar, name, orientation, reverse)
                bar:SetScript("OnShow", OnShowOld)
            end)
        end
    end

    local function UpdateHealthBar(name, orientation, reverse, force)
        -- pfPlayer.hp.bar.bar:SetGradient('HORIZONTAL', minR, minG, minB, maxR, maxG, maxB)
        if strfind(name, "^raid") or strfind(name, "^group")  then
            -- local n = name == "raid" and GetNumRaidMembers() or GetNumPartyMembers()
            local n   = name == "raid" and tonumber(C.unitframes.maxraid) or 4
            local sub = strfind(name, "group") and gsub(name, "group", "") or ""
            
            for i = 1, n do
                if force then
                    ForceUpdateHealthBar(sub == "" and pfUI.uf[name][i] or pfUI.uf.group[i][sub], name, orientation, reverse)
                else
                    SetGradient((sub == "" and pfUI.uf[name][i] or pfUI.uf.group[i][sub]).hp.bar.bar, name, orientation, reverse)
                end
            end
        elseif pfUI.uf[name] then 
            if force then
                ForceUpdateHealthBar(pfUI.uf[name], name, orientation, reverse)
            else
                -- pfUI.uf[name].hp.bar.bar:SetGradient(orientation, minR, minG, minB, maxR, maxG, maxB)
                SetGradient(pfUI.uf[name].hp.bar.bar, name, orientation, reverse)
            end
        end
    end

    local function ResetHealthBar(name)
        if strfind(name, "^raid") or strfind(name, "^group")  then
            local n   = name == "raid" and tonumber(C.unitframes.maxraid) or 4
            local sub = strfind(name, "group") and gsub(name, "group", "") or ""
            
            for i = 1, n do
                pfUI.uf:RefreshUnit(sub == "" and pfUI.uf[name][i] or pfUI.uf.group[i][sub])
            end
        elseif pfUI.uf[name] then 
            pfUI.uf:RefreshUnit(pfUI.uf[name])
        end
    end

    local function ResetStatusBarBlendMode()
        local frames = { "player", "target", "ttarget", "tttarget", "pet", "ptarget", "focus", "focustarget", "group", "grouptarget", "grouppet", "raid" }
        
        for _, frame in ipairs(frames) do
            if strfind(frame, "^raid") or strfind(frame, "^group")  then
                local n   = frame == "raid" and tonumber(C.unitframes.maxraid) or 4
                local sub = strfind(frame, "group") and gsub(frame, "group", "") or ""
                local uf
                
                for i = 1, n do
                    uf = sub == "" and pfUI.uf[frame][i] or pfUI.uf.group[i][sub]
                    
                    uf.hp.bar.bar:SetBlendMode(C.unitframes[CIK[8][2]])
                    uf.power.bar.bar:SetBlendMode(C.unitframes[CIK[8][2]])
                end
            elseif pfUI.uf[frame] then 
                pfUI.uf[frame].hp.bar.bar:SetBlendMode(C.unitframes[CIK[8][2]])
                pfUI.uf[frame].power.bar.bar:SetBlendMode(C.unitframes[CIK[8][2]])
            end
        end
    end

    local function ConfigUpdateHandler(config, frame)
        local timer     = nil
        local InitComps = function(bar, tex)
            if bar then
                bar.back = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
                bar.back:SetTexture(tex)
                bar.back:SetAllPoints(bar)

                bar.bar:SetTexture(TEX_TRANSPARENT)
                bar.bar:SetBlendMode(C.unitframes[CIK[8][2]] or "MOD")

                -- bar:SetStatusBarTexture(TEX_TRANSPARENT)
                bar.SetStatusBarTextureOld = bar.SetStatusBarTexture
                bar.SetStatusBarTexture    = function(self, tex)
                    self.back:SetTexture(tex)
                end
            end
        end
        local callback  = function()
            if C.unitframes[config][CIK[2][2]] == "1" then
                if tonumber(C.unitframes[CIK[6][2]]) > 0.1 then
                    UpdateRainbow(frame)
                    UpdateHealthBar(frame, C.unitframes[config][CIK[4][2]], C.unitframes[config][CIK[3][2]] == "1", true)
                end

                timer = C_Timer.NewTicker(tonumber(C.unitframes[CIK[6][2]]), function()
                    UpdateRainbow(frame)
                    UpdateHealthBar(frame, C.unitframes[config][CIK[4][2]], C.unitframes[config][CIK[3][2]] == "1")
                end, -1)
            elseif timer then
                timer:Cancel()
                ResetHealthBar(config)
            end
        end

        -- setup a grey filter for target tap state
        if strfind(frame, "^target") then
            local bar = pfUI.uf[frame].hp.bar

            bar.filter = bar:CreateTexture(nil, "OVERLAY", nil, -1)
            bar.filter:SetTexture(TEX_FILTER)
            bar.filter:SetAllPoints(bar)
            bar.filter:SetBlendMode("ADD")
            bar.filter:Hide()

            -- hook SetStatusBarColor method to refresh
            bar.SetStatusBarColorOld = bar.SetStatusBarColor
            bar.SetStatusBarColor    = function(self, r, g, b, a)
                if C.unitframes[config][CIK[2][2]] == "1" then
                    if UnitIsTapped(frame) and not UnitIsTappedByPlayer(frame) then
                        self.filter:Show()
                    elseif self.filter:IsShown() then
                        self.filter:Hide()
                    end
                else
                    self:SetStatusBarColorOld(r, g, b, a)
                end
            end
        end

        -- setup alpha mode components
        if C.unitframes[CIK[7][2]] == "1" then
            if strfind(frame, "^raid") or strfind(frame, "^group")  then
                local n   = frame == "raid" and tonumber(C.unitframes.maxraid) or 4
                local sub = strfind(frame, "group") and gsub(frame, "group", "") or ""
                local uf
                
                for i = 1, n do
                    uf = sub == "" and pfUI.uf[frame][i] or pfUI.uf.group[i][sub]
                    
                    InitComps(uf.hp.bar, C.unitframes[config].bartexture)
                    InitComps(uf.power.bar, C.unitframes[config].pbartexture)
                end
            elseif pfUI.uf[frame] then 
                InitComps(pfUI.uf[frame].hp.bar, C.unitframes[config].bartexture)
                InitComps(pfUI.uf[frame].power.bar, C.unitframes[config].pbartexture)
            end
        end

        return callback
    end

    --[[
        REGION: main setups    
    --]]
    local function Setup(settings)
        local c, t, f = settings[1], settings[2], settings[3]
        local UFGeneral = UnitFrames[t].area.scroll.content
        local OnShowOld = UFGeneral:GetScript("OnShow")
        local ufunc

        if c then
            ufunc = ConfigUpdateHandler(c, f)

            -- pfUI gui config
            if not C.unitframes[c][CIK[4][2]] then
                pfUI:UpdateConfig("unitframes", c, CIK[4][2], "HORIZONTAL")
            end

            if C.unitframes[c][CIK[2][2]] == "1" then
                ufunc()
            end

            -- hook OnShow handler
            UFGeneral:SetScript("OnShow", function()
                -- release hook
                this:SetScript("OnShow", OnShowOld)

                OnShowOld()

                --- rainbowbar
                CreateConfig(nil, CIK[1][1], nil, nil, "header")
                CreateConfig(ufunc, CIK[2][1], C.unitframes[c], CIK[2][2], "checkbox", "0")
                CreateConfig(function() end, CIK[3][1], C.unitframes[c], CIK[3][2], "checkbox", "0")
                CreateConfig(function() end, CIK[4][1], C.unitframes[c], CIK[4][2], "dropdown", pfUI.gui.dropdowns.orientation)
            end)
        else
            -- pfUI gui config
            if C.unitframes[CIK[4][2]] == nil then
                if not C.unitframes[CIK[6][2]] then
                    pfUI:UpdateConfig("unitframes", nil, CIK[6][2], "0")
                end

                if not C.unitframes[CIK[5][2]] then
                    pfUI:UpdateConfig("unitframes", nil, CIK[5][2], "0")
                end
            end

            if C.unitframes[CIK[7][2]] == "1" and not C.unitframes[CIK[8][2]] then
                C.unitframes[CIK[8][2]] = "MOD"
            end

            -- hook OnShow handler
            UFGeneral:SetScript("OnShow", function()
                -- release hook
                this:SetScript("OnShow", OnShowOld)

                OnShowOld()

                --- rainbowbar
                CreateConfig(nil, CIK[1][1], nil, nil, "header")
                CreateConfig(function() if C.unitframes[CIK[5][2]] == "1" then GradientCache:InitGradientCache("general") else GradientCache["general"] = nil end end, CIK[5][1], C.unitframes, CIK[5][2], "checkbox", "0")
                CreateConfig(nil, CIK[7][1], C.unitframes, CIK[7][2], "checkbox", "0")

                if C.unitframes[CIK[7][2]] == "1" then
                    CreateConfig(ResetStatusBarBlendMode, CIK[8][1], C.unitframes, CIK[8][2], "dropdown", pfUI.gui.dropdowns.alphamode)
                end

                CreateConfig(nil, CIK[6][1], C.unitframes, CIK[6][2], nil, "0")
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

    -- update dropdown lists
    pfUI.gui.dropdowns["orientation"] = {
        "HORIZONTAL:" .. T["Horizontal"],
        "VERTICAL:" .. T["Vertical"],
    }

    -- alpha mode dropdown list
    pfUI.gui.dropdowns["alphamode"] = {
        "DISABLE:" .. T["Disable"],
        "BLEND:" .. T["Mode Blend"],
        "ALPHAKEY:" .. T["Mode AlphaKey"],
        "ADD:" .. T["Mode Add"],
        "MOD:" .. T["Mode Mod"]
    }

    -- init general cache
    if C.unitframes[CIK[5][2]] == "1" then 
        GradientCache:InitGradientCache("general")
    end

    -- global timer only update gradient colors
    globaltimer = C_Timer.NewTicker(tonumber(C.unitframes[CIK[6][2]]), function()
        if GradientCache["general"] then
            UpdateRainbow("general", true)
        end
    end, -1)

    -- setup rainbowbar
    for _, data in ipairs(unitframeSettings) do
        Setup(data)
    end
end)
