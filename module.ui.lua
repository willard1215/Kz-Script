--[[module.ui.lua]]

Module = {}
Module.UI = {}
Module.UI.__index = Module.UI

Module.UI.Text = {}
Module.UI.Text.__index = Module.UI.Text
function Module.UI.Text:Create(args)
    local instance = setmetatable({}, self)
    instance.SetArg = args or {}
    instance.Border = {}
    instance.Shadow = nil
    if instance.SetArg.shadow ~= nil then
        instance:InitShadow()
    end
    if instance.SetArg.border ~= nil then
        instance:InitBorder()
    end
    if instance.SetArg.shadow == nil and instance.SetArg.border == nil then
        instance.Text = UI.Text.Create()
        instance.Text:Set(instance.SetArg)
    end

    return instance
end

function Module.UI.Text:InitBorder()
    for i = 1, 8 do
        self.Border[i] = UI.Text.Create()
    end
    self.Text = UI.Text.Create()
    self.Text:Set(self.SetArg)
end

function Module.UI.Text:InitShadow()
    self.Shadow = UI.Text.Create()
    self.Text = UI.Text.Create()
    self.Text:Set(self.SetArg)
end

function Module.UI.Text:Set(setArg)
    -- 셋으로 첫 그림자 데이터 들어오면 새로 생성함
    if self.SetArg.shadow == nil and setArg.shadow ~= nil then
        self:InitShadow()
    end
    -- 셋으로 첫 보더 데이터 들어오면 새로 생성함
    if self.SetArg.border == nil and setArg.border ~= nil then
        self:InitBorder()
    end

    self.SetArg.text = setArg.text ~= nil and setArg.text or self.SetArg.text
    self.SetArg.font = setArg.font ~= nil and setArg.font or self.SetArg.font
    self.SetArg.align = setArg.align ~= nil and setArg.align or self.SetArg.align
    self.SetArg.x = setArg.x ~= nil and setArg.x or self.SetArg.x
    self.SetArg.y = setArg.y ~= nil and setArg.y or self.SetArg.y
    self.SetArg.width = setArg.width ~= nil and setArg.width or self.SetArg.width
    self.SetArg.height = setArg.height ~= nil and setArg.height or self.SetArg.height
    self.SetArg.r = setArg.r ~= nil and setArg.r or self.SetArg.r
    self.SetArg.g = setArg.g ~= nil and setArg.g or self.SetArg.g
    self.SetArg.b = setArg.b ~= nil and setArg.b or self.SetArg.b
    self.SetArg.a = setArg.a ~= nil and setArg.a or self.SetArg.a
    self.SetArg.border = setArg.border ~= nil and setArg.border or self.SetArg.border
    self.SetArg.shadow = setArg.shadow ~= nil and setArg.shadow or self.SetArg.shadow

    self.Text:Set(self.SetArg)

    -- 그림자 설정
    if self.SetArg.shadow ~= nil then
        local shadowX = self.SetArg.shadow.x or 2
        local shadowY = self.SetArg.shadow.y or 2

        self.Shadow:Set(self.SetArg)
        self.Shadow:Set({
            x = self.SetArg.x + shadowX,
            y = self.SetArg.y + shadowY,
            r = self.SetArg.shadow.r or 0,
            g = self.SetArg.shadow.g or 0,
            b = self.SetArg.shadow.b or 0,
            a = self.SetArg.shadow.a or 128,
        })
    end

    -- 테두리 설정
    if self.SetArg.border ~= nil then
        function CreateBorder(index, xOffset, yOffset)
            self.Border[index]:Set(self.SetArg)
            self.Border[index]:Set({
                x = self.SetArg.x + xOffset,
                y = self.SetArg.y + yOffset,
                r = self.SetArg.border.r or 0,
                g = self.SetArg.border.g or 0,
                b = self.SetArg.border.b or 0,
                a = self.SetArg.border.a or 255,
            })
        end

        local width = self.SetArg.border.width or 1
        CreateBorder(1, -width, width)
        CreateBorder(2, width, width)
        CreateBorder(3, -width, -width)
        CreateBorder(4, width, -width)
        CreateBorder(5, 0, width)
        CreateBorder(6, 0, -width)
        CreateBorder(7, -width, 0)
        CreateBorder(8, width, 0)
    end
end

function Module.UI.Text:Show()
    if self.Shadow then
        self.Shadow:Show()
    end
    for _, border in pairs(self.Border) do
        border:Show()
    end
    self.Text:Show()
end

function Module.UI.Text:Hide()
    self.Text:Hide()
    for _, border in pairs(self.Border) do
        border:Hide()
    end
    if self.Shadow then
        self.Shadow:Hide()
    end
end

function Module.UI.Text:IsVisible()
    return self.Text:IsVisible()
end

function Module.UI.Text:Get()
    return self.Text:Get()
end

--[[
==========================================
================ Transform =================
==========================================
]]

Module.Transform = {}
Module.Transform.__index = Module.Transform

function Module.Transform.Cubic(a, b, c, d, t)
    local function _evaluateCubic(a, b, m)
        return 3 * a * (1 - m) * (1 - m) * m + 3 * b * (1 - m) * m * m + m * m * m
    end

    local startp = 0.0
    local endp = 1.0
    local _cubicErrorBound = 0.001
    while (true) do
        local midpoint = (startp + endp) / 2
        local estimate = _evaluateCubic(a, c, midpoint)
        if (math.abs(t - estimate) < _cubicErrorBound) then
            return _evaluateCubic(b, d, midpoint)
        end
        if (estimate < t) then
            startp = midpoint
        else
            endp = midpoint
        end
    end
end

function Module.Transform.Decelerate(t)
    t = 1.0 - t
    return 1.0 - t * t
end

function Module.Transform.Bounce(t)
    if (t < 1.0 / 2.75) then
        return 7.5625 * t * t
    elseif (t < 2 / 2.75) then
        t = t - 1.5 / 2.75
        return 7.5625 * t * t + 0.75
    elseif (t < 2.5 / 2.75) then
        t = t - 2.25 / 2.75
        return 7.5625 * t * t + 0.9375
    end
    t = t - 2.625 / 2.75
    return 7.5625 * t * t + 0.984375
end

function Module.Transform.ElasticIn(t)
    if t == 0 or t == 1 then return t end

    local period = 0.4
    local s = period / 4.0

    t = t - 1.0
    return -(2.0 ^ (10.0 * t)) * math.sin((t - s) * (math.pi * 2.0) / period)
end

function Module.Transform.ElasticOut(t)
    if t == 0 or t == 1 then return t end

    local period = 0.4
    local s = period / 4.0

    return (2.0 ^ (-10.0 * t)) * math.sin((t - s) * (math.pi * 2.0) / period) + 1.0;
end

function Module.Transform.ElasticInOut(t)
    if t == 0 or t == 1 then return t end

    local period = 0.4
    local s = period / 4.0

    t = 2.0 * t - 1.0
    if (t < 0.0) then
        return -0.5 * 2.0 ^ (10.0 * t) * math.sin((t - s) * (math.pi * 2.0) / period)
    else
        return 2.0 ^ (-10.0 * t) * math.sin((t - s) * (math.pi * 2.0) / period) * 0.5 + 1.0
    end
end

--[[
==========================================
================ Animation =================
==========================================
]]

Curves = {
    Linear = "Linear",
    Decelerate = "Decelerate",
    FastLinearToSlowEaseIn = "FastLinearToSlowEaseIn",
    FastEaseInToSlowEaseOut = "FastEaseInToSlowEaseOut",
    Ease = "Ease",
    EaseIn = "EaseIn",
    EaseInToLinear = "EaseInToLinear",
    EaseInSine = "EaseInSine",
    EaseInQuad = "EaseInQuad",
    EaseInCubic = "EaseInCubic",
    EaseInQuart = "EaseInQuart",
    EaseInQuint = "EaseInQuint",
    EaseInExpo = "EaseInExpo",
    EaseInCirc = "EaseInCirc",
    EaseInBack = "EaseInBack",
    EaseOut = "EaseOut",
    LinearToEaseOut = "LinearToEaseOut",
    EaseOutSine = "EaseOutSine",
    EaseOutQuad = "EaseOutQuad",
    EaseOutCubic = "EaseOutCubic",
    EaseOutQuart = "EaseOutQuart",
    EaseOutQuint = "EaseOutQuint",
    EaseOutExpo = "EaseOutExpo",
    EaseOutCirc = "EaseOutCirc",
    EaseOutBack = "EaseOutBack",
    EaseInOut = "EaseInOut",
    EaseInOutSine = "EaseInOutSine",
    EaseInOutQuad = "EaseInOutQuad",
    EaseInOutCubic = "EaseInOutCubic",
    EaseInOutCubicEmphasized = "EaseInOutCubicEmphasized",
    EaseInOutQuart = "EaseInOutQuart",
    EaseInOutQuint = "EaseInOutQuint",
    EaseInOutExpo = "EaseInOutExpo",
    EaseInOutCirc = "EaseInOutCirc",
    EaseInOutBack = "EaseInOutBack",
    slowMiddle = "slowMiddle",
    BounceIn = "BounceIn",
    BounceOut = "BounceOut",
    BounceInOut = "BounceInOut",
    ElasticIn = "ElasticIn",
    ElasticOut = "ElasticOut",
    ElasticInOut = "ElasticInOut",
}


Module.Animation = {}
Module.Animation.__index = Module.Animation

function Module.Animation:New()
    local instance = setmetatable({}, self)
    instance.taskId = 0
    instance.tasks = {}
    return instance
end

function Module.Animation:Add(duration, curve, callback, ...)
    self.taskId = self.taskId + 1
    local task = {
        id = self.taskId,
        duration = duration,
        curve = curve,
        callback = callback,
        startTime = 0,
        args = {...},
    }
    table.insert(self.tasks, task) -- 작업 추가
    return task.id
end

--[[
애니메이션 취소

Args:

    taskId (int): 애니메이션 아이디

]]
function Module.Animation:Cancel(taskId)
    for i, task in ipairs(self.tasks) do
        if task.id == taskId then
            table.remove(self.tasks, i)
            break
        end
    end
end

--[[
Game.Rule:OnUpdate에서 매번 실행해야하며, 딜레이 시간이 지난 콜백을 실행

Args:

	time (float): 현재 시간 | ms, sec 모두 상관없으나 Add에서 delay와 동일한 단위여야함
]]
function Module.Animation:UpdateTasks(time)
    for i = #self.tasks, 1, -1 do
        local task = self.tasks[i]

        -- 처음 시작 시간을 기록
        if task.startTime == 0 then
            task.startTime = time
        end

        -- 시간확인
        local isDone = time - task.startTime >= task.duration

        local animationTime = (time - task.startTime) / task.duration
        animationTime = animationTime > 1 and 1 or animationTime

        local animationValue = Module.Animation.GetAnimationValue(animationTime, task.curve, task.args)

        task.callback(animationValue, animationTime, isDone)

        -- 시간 확인
        if isDone then
            table.remove(self.tasks, i) -- 실행된 작업은 삭제
        end
    end
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_linear.mp4}
function Module.Animation.Linear(t)
    return t
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_decelerate.mp4}
function Module.Animation.Decelerate(t)
    return Module.Transform.Decelerate(t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_fast_linear_to_slow_ease_in.mp4}
function Module.Animation.FastLinearToSlowEaseIn(t)
    return Module.Transform.Cubic(0.18, 1.0, 0.04, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_fast_ease_in_to_slow_ease_out.mp4}
function Module.Animation.FastEaseInToSlowEaseOut(t)
    -- ThreePointCubic(
    -- Offset(0.056, 0.024),
    -- Offset(0.108, 0.3085),
    -- Offset(0.198, 0.541),
    -- Offset(0.3655, 1.0),
    -- Offset(0.5465, 0.989),
    -- )
    return t
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease.mp4}
function Module.Animation.Ease(t)
    return Module.Transform.Cubic(0.25, 0.1, 0.25, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in.mp4}
function Module.Animation.EaseIn(t)
    return Module.Transform.Cubic(0.42, 0.0, 1.0, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_to_linear.mp4}
function Module.Animation.EaseInToLinear(t)
    return Module.Transform.Cubic(0.67, 0.03, 0.65, 0.09, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_sine.mp4}
function Module.Animation.EaseInSine(t)
    return Module.Transform.Cubic(0.47, 0.0, 0.745, 0.715, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_quad.mp4}
function Module.Animation.EaseInQuad(t)
    return Module.Transform.Cubic(0.55, 0.085, 0.68, 0.53, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_cubic.mp4}
function Module.Animation.EaseInCubic(t)
    return Module.Transform.Cubic(0.55, 0.055, 0.675, 0.19, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_quart.mp4}
function Module.Animation.EaseInQuart(t)
    return Module.Transform.Cubic(0.895, 0.03, 0.685, 0.22, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_quint.mp4}
function Module.Animation.EaseInQuint(t)
    return Module.Transform.Cubic(0.755, 0.05, 0.855, 0.06, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_expo.mp4}
function Module.Animation.EaseInExpo(t)
    return Module.Transform.Cubic(0.95, 0.05, 0.795, 0.035, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_circ.mp4}
function Module.Animation.EaseInCirc(t)
    return Module.Transform.Cubic(0.6, 0.04, 0.98, 0.335, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_back.mp4}
function Module.Animation.EaseInBack(t)
    return Module.Transform.Cubic(0.6, -0.28, 0.735, 0.045, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out.mp4}
function Module.Animation.EaseOut(t)
    return Module.Transform.Cubic(0.0, 0.0, 0.58, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_linear_to_ease_out.mp4}
function Module.Animation.LinearToEaseOut(t)
    return Module.Transform.Cubic(0.35, 0.91, 0.33, 0.97, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_sine.mp4}
function Module.Animation.EaseOutSine(t)
    return Module.Transform.Cubic(0.39, 0.575, 0.565, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_quad.mp4}
function Module.Animation.EaseOutQuad(t)
    return Module.Transform.Cubic(0.25, 0.46, 0.45, 0.94, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_cubic.mp4}
function Module.Animation.EaseOutCubic(t)
    return Module.Transform.Cubic(0.215, 0.61, 0.355, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_quart.mp4}
function Module.Animation.EaseOutQuart(t)
    return Module.Transform.Cubic(0.165, 0.84, 0.44, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_quint.mp4}
function Module.Animation.EaseOutQuint(t)
    return Module.Transform.Cubic(0.23, 1.0, 0.32, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_expo.mp4}
function Module.Animation.EaseOutExpo(t)
    return Module.Transform.Cubic(0.19, 1.0, 0.22, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_circ.mp4}
function Module.Animation.EaseOutCirc(t)
    return Module.Transform.Cubic(0.075, 0.82, 0.165, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_out_back.mp4}
function Module.Animation.EaseOutBack(t)
    return Module.Transform.Cubic(0.175, 0.885, 0.32, 1.275, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out.mp4}
function Module.Animation.EaseInOut(t)
    return Module.Transform.Cubic(0.42, 0.0, 0.58, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_sine.mp4}
function Module.Animation.EaseInOutSine(t)
    return Module.Transform.Cubic(0.445, 0.05, 0.55, 0.95, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_quad.mp4}
function Module.Animation.EaseInOutQuad(t)
    return Module.Transform.Cubic(0.455, 0.03, 0.515, 0.955, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_cubic.mp4}
function Module.Animation.EaseInOutCubic(t)
    return Module.Transform.Cubic(0.645, 0.045, 0.355, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_cubic_emphasized.mp4}
function Module.Animation.EaseInOutCubicEmphasized(t)
    -- ThreePointCubic(
    -- Offset(0.05, 0),
    -- Offset(0.133333, 0.06),
    -- Offset(0.166666, 0.4),
    -- Offset(0.208333, 0.82),
    -- Offset(0.25, 1),
    -- )
    return t
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_quart.mp4}
function Module.Animation.EaseInOutQuart(t)
    return Module.Transform.Cubic(0.77, 0.0, 0.175, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_quint.mp4}
function Module.Animation.EaseInOutQuint(t)
    return Module.Transform.Cubic(0.86, 0.0, 0.07, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_expo.mp4}
function Module.Animation.EaseInOutExpo(t)
    return Module.Transform.Cubic(1.0, 0.0, 0.0, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_circ.mp4}
function Module.Animation.EaseInOutCirc(t)
    return Module.Transform.Cubic(0.785, 0.135, 0.15, 0.86, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_ease_in_out_back.mp4}
function Module.Animation.EaseInOutBack(t)
    return Module.Transform.Cubic(0.68, -0.55, 0.265, 1.55, t)
end

--  * [Easing.legacy], the name for this curve in the Material specification.
function Module.Animation.FastOutSlowIn(t)
    return Module.Transform.Cubic(0.4, 0.0, 0.2, 1.0, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_slow_middle.mp4}
function Module.Animation.slowMiddle(t)
    return Module.Transform.Cubic(0.15, 0.85, 0.85, 0.15, t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in.mp4}
function Module.Animation.BounceIn(t)
    return 1.0 - Module.Transform.Bounce(1.0 - t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_out.mp4}
function Module.Animation.BounceOut(t)
    return Module.Transform.Bounce(t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_bounce_in_out.mp4}
function Module.Animation.BounceInOut(t)
    if (t < 0.5) then
        return (1.0 - Module.Transform.Bounce(1.0 - t * 2.0)) * 0.5
    else
        return Module.Transform.Bounce(t * 2.0 - 1.0) * 0.5 + 0.5
    end
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_in.mp4}
function Module.Animation.ElasticIn(t)
    return Module.Transform.ElasticIn(t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_out.mp4}
function Module.Animation.ElasticOut(t)
    return Module.Transform.ElasticOut(t)
end

-- {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_elastic_in_out.mp4}
function Module.Animation.ElasticInOut(t)
    return Module.Transform.ElasticInOut(t)
end


--[[ 애니메이션 값 반환 | 위에 애니메이션 스케줄 안쓸거면 이걸로 값 반환하면 됨 ]]
function Module.Animation.GetAnimationValue(t, curve, args)
    if curve == Curves.Linear then return Module.Animation.Linear(t)
    elseif curve == Curves.Decelerate then return Module.Animation.Decelerate(t)
    elseif curve == Curves.FastLinearToSlowEaseIn then return Module.Animation.FastLinearToSlowEaseIn(t)
    elseif curve == Curves.FastEaseInToSlowEaseOut then return Module.Animation.FastEaseInToSlowEaseOut(t)
    elseif curve == Curves.Ease then return Module.Animation.Ease(t)
    elseif curve == Curves.EaseIn then return Module.Animation.EaseIn(t)
    elseif curve == Curves.EaseInToLinear then return Module.Animation.EaseInToLinear(t)
    elseif curve == Curves.EaseInSine then return Module.Animation.EaseInSine(t)
    elseif curve == Curves.EaseInQuad then return Module.Animation.EaseInQuad(t)
    elseif curve == Curves.EaseInCubic then return Module.Animation.EaseInCubic(t)
    elseif curve == Curves.EaseInQuart then return Module.Animation.EaseInQuart(t)
    elseif curve == Curves.EaseInQuint then return Module.Animation.EaseInQuint(t)
    elseif curve == Curves.EaseInExpo then return Module.Animation.EaseInExpo(t)
    elseif curve == Curves.EaseInCirc then return Module.Animation.EaseInCirc(t)
    elseif curve == Curves.EaseInBack then return Module.Animation.EaseInBack(t)
    elseif curve == Curves.EaseOut then return Module.Animation.EaseOut(t)
    elseif curve == Curves.LinearToEaseOut then return Module.Animation.LinearToEaseOut(t)
    elseif curve == Curves.EaseOutSine then return Module.Animation.EaseOutSine(t)
    elseif curve == Curves.EaseOutQuad then return Module.Animation.EaseOutQuad(t)
    elseif curve == Curves.EaseOutCubic then return Module.Animation.EaseOutCubic(t)
    elseif curve == Curves.EaseOutQuart then return Module.Animation.EaseOutQuart(t)
    elseif curve == Curves.EaseOutQuint then return Module.Animation.EaseOutQuint(t)
    elseif curve == Curves.EaseOutExpo then return Module.Animation.EaseOutExpo(t)
    elseif curve == Curves.EaseOutCirc then return Module.Animation.EaseOutCirc(t)
    elseif curve == Curves.EaseOutBack then return Module.Animation.EaseOutBack(t)
    elseif curve == Curves.EaseInOut then return Module.Animation.EaseInOut(t)
    elseif curve == Curves.EaseInOutSine then return Module.Animation.EaseInOutSine(t)
    elseif curve == Curves.EaseInOutQuad then return Module.Animation.EaseInOutQuad(t)
    elseif curve == Curves.EaseInOutCubic then return Module.Animation.EaseInOutCubic(t)
    elseif curve == Curves.EaseInOutCubicEmphasized then return Module.Animation.EaseInOutCubicEmphasized(t)
    elseif curve == Curves.EaseInOutQuart then return Module.Animation.EaseInOutQuart(t)
    elseif curve == Curves.EaseInOutQuint then return Module.Animation.EaseInOutQuint(t)
    elseif curve == Curves.EaseInOutExpo then return Module.Animation.EaseInOutExpo(t)
    elseif curve == Curves.EaseInOutCirc then return Module.Animation.EaseInOutCirc(t)
    elseif curve == Curves.EaseInOutBack then return Module.Animation.EaseInOutBack(t)
    elseif curve == Curves.slowMiddle then return Module.Animation.slowMiddle(t)
    elseif curve == Curves.BounceIn then return Module.Animation.BounceIn(t)
    elseif curve == Curves.BounceOut then return Module.Animation.BounceOut(t)
    elseif curve == Curves.BounceInOut then return Module.Animation.BounceInOut(t)
    elseif curve == Curves.ElasticIn then return Module.Animation.ElasticIn(t)
    elseif curve == Curves.ElasticOut then return Module.Animation.ElasticOut(t)
    elseif curve == Curves.ElasticInOut then return Module.Animation.ElasticInOut(t) end
    -- 기본 값 linear
    return t
end


Module.UI.BG = {}
Module.UI.BG.__index = Module.UI.BG

function Module.UI.BG:Create()
    local instance = setmetatable({}, self)
    instance:InitEffect()
    return instance
end

--[[ BG 초기화 ]]
function Module.UI.BG:InitEffect()
    self.color = self.color or HUD.Effect.PauseColor
    self.options = self.options or HUD.Effect.EffectOptions

    self.effect = {}
    self.effect.isShow = false
    self.effect.taskId = -1
    self.effect.bg = UI.Box.Create()
    self.effect.top = {}
    self.effect.left = {}
    self.effect.right = {}
    self.effect.bottom = {}
    self.effect.latestColor = nil


    local gradientPixel = self.options.pixel
    local gradientSize = self.options.size

    self.effect.bg:Set(TableMerge({width=screen.width, height=screen.height*2}, self.color))
    for i = 1, gradientSize do
        self.effect.top[i] = UI.Box.Create()
        self.effect.top[i]:Set(TableMerge(self.color, {y=i-1, width=screen.width, height=gradientPixel, a=self.options.opacity * (gradientSize*2 - i * 2)}))
        self.effect.left[i] = UI.Box.Create()
        self.effect.left[i]:Set(TableMerge(self.color, {x=i-1, width=gradientPixel, height=screen.height, a=gradientSize*2 - i * 2}))
        self.effect.right[i] = UI.Box.Create()
        self.effect.right[i]:Set(TableMerge(self.color, {x=screen.width-(i-1), width=gradientPixel, height=screen.height, a=gradientSize*2 - i * 2}))
        self.effect.bottom[i] = UI.Box.Create()
        self.effect.bottom[i]:Set(TableMerge(self.color, {y=screen.height-(i-1), width=screen.width, height=gradientPixel, a=gradientSize*2 - i * 2}))
    end
    self:HideEffect(self.color, 0, 1)
end

function Module.UI.BG:Set(setArg)
    self.color = setArg.color or self.color or HUD.Effect.PauseColor
    self.options = setArg.options or self.options or HUD.Effect.EffectOptions
end

function Module.UI.BG:ShowEffect(color, duration, startAnimation)
    local pixelOpacity = self.options.opacity
    local opacity = self.options.size * pixelOpacity
    color = color or self.color
    duration = duration or self.options.duration
    startAnimation = startAnimation or 0
    self.effect.isShow = true
    self.effect.latestColor = color
    self.effect.bg:Show()
    for i = 1, self.options.size do
        self.effect.top[i]:Show()
        self.effect.left[i]:Show()
        self.effect.right[i]:Show()
        self.effect.bottom[i]:Show()
    end
    Animation:Cancel(self.effect.taskId)
    self.effect.taskId = Animation:Add(duration, Curves.Linear, function(animationValue)
        local av = startAnimation + (1 - startAnimation) * animationValue
        self.effect.bg:Set({r = color.r, g = color.g, b = color.b, a = color.a * av})
        for i = 1, self.options.size do
            self.effect.top[i]:Set({r = color.r, g = color.g, b = color.b, a = (opacity - i * pixelOpacity) * av})
            self.effect.left[i]:Set({r = color.r, g = color.g, b = color.b, a = (opacity - i * pixelOpacity) * av})
            self.effect.right[i]:Set({r = color.r, g = color.g, b = color.b, a = (opacity - i * pixelOpacity) * av})
            self.effect.bottom[i]:Set({r = color.r, g = color.g, b = color.b, a = (opacity - i * pixelOpacity) * av})
        end
    end)
end

function Module.UI.BG:HideEffect(color, duration, startAnimation)
    local pixelOpacity = self.options.opacity
    local opacity = self.options.size * pixelOpacity
    color = color or self.color
    duration = duration or self.options.duration
    startAnimation = startAnimation or 0
    self.effect.isShow = false
    self.effect.latestColor = nil
    Animation:Cancel(self.effect.taskId)
    function _Hide(animationValue, _, isDone)
        local av = startAnimation + (1 - startAnimation) * (1 - animationValue)
        self.effect.bg:Set({r = color.r, g = color.g, b = color.b, a = color.a * av})
        for i = 1, self.options.size do
            self.effect.top[i]:Set({r = color.r, g = color.g, b = color.b, a = (opacity - i * pixelOpacity) * av})
            self.effect.left[i]:Set({r = color.r, g = color.g, b = color.b, a = (opacity - i * pixelOpacity) * av})
            self.effect.right[i]:Set({r = color.r, g = color.g, b = color.b, a = (opacity - i * pixelOpacity) * av})
            self.effect.bottom[i]:Set({r = color.r, g = color.g, b = color.b, a = (opacity - i * pixelOpacity) * av})
        end
        if isDone then
            self.effect.bg:Hide()
            for i = 1, self.options.size do
                self.effect.top[i]:Hide()
                self.effect.left[i]:Hide()
                self.effect.right[i]:Hide()
                self.effect.bottom[i]:Hide()
            end
        end
    end
    if startAnimation == 1 then
        _Hide(1, nil, true)
    else
        self.effect.taskId = Animation:Add(duration, Curves.Linear, _Hide)
    end
end