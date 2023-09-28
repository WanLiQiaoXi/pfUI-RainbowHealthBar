--[[
    API: C_Timer
]]
local function GenerateTimer()
    local Timer       = CreateFrame("Frame")
    local TimerObject = {}

    Timer.Infinite    = 0  -- -1 infinite，0 stop，1..n loop n times
    Timer.ElapsedTime = 0
    
    function Timer:Start(duration, callback)
        if type(duration) ~= "number" then
            duration = 0
        end
        
        self:SetScript("OnUpdate", function()
            self.ElapsedTime = self.ElapsedTime + arg1
 
            if self.ElapsedTime >= duration and type(callback) == "function" then
                callback()

                self.ElapsedTime = 0
    
                if self.Infinite == 0 then
                    self:SetScript("OnUpdate", nil) 
                elseif self.Infinite > 0 then
                    self.Infinite = self.Infinite - 1
                end
            end
        end)
    end
    
    function TimerObject:IsCancelled()
        return not Timer:GetScript("OnUpdate")
    end
    
    function TimerObject:Cancel()
        if Timer:GetScript("OnUpdate") then
            Timer:SetScript("OnUpdate", nil) 
            Timer.Infinite    = 0
            Timer.ElapsedTime = 0
        end
    end

    return Timer, TimerObject
end

C_Timer = C_Timer or {
    After = function (duration, callback)
        GenerateTimer():Start(duration, callback)
    end,
    NewTimer = function (duration, callback)
        local timer, timerObj = GenerateTimer()
        
        timer:Start(duration, callback)

        return timerObj
    end,
    NewTicker = function (duration, callback, ...)
        local timer, timerObj = GenerateTimer()
        local iterations = unpack(arg)

        if type(iterations) ~= "number" or iterations < 0 then
            iterations = 0  -- will be infinite
        end

        timer.Infinite = iterations - 1
        timer:Start(duration, callback)

        return timerObj
    end
}