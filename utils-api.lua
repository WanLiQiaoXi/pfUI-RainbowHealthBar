-- load pfUI environment
setfenv(1, pfUI:GetEnvironment())

local function strjoin(delimiter, ...)
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

local extension = {
    [1]            = strjoin,
    ["strjoin"]    = strjoin,
    [2]            = serialize,
    ["serialize"]  = serialize,
    [3]            = compress,
    ["compress"]   = compress,
    [4]            = decompress,
    ["decompress"] = decompress,
    [5]            = enc,
    ["enc"]        = enc,
    [6]            = dec,
    ["dec"]        = dec
} 

-- pfUI.env.UAPI = setmetatable({}, { __index = extension })
pfUI.env.UAPI = extension