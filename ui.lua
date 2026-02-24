-- ui.lua

screen = UI.ScreenSize()
center = {x=screen.width/2, y=screen.height/2}
print(version)

KZ = {}
Animation = Module.Animation:New()


local SyncValueCreate = SyncValueSet(UI)

LanServer = SyncValueCreate('LanServer')
function TextOffSet(place, value, negative)
	return bool_to_number(place == 'bottom' or place == 'right', value, negative)
end

function getHeight(size)
	return size == 'small' and 22 or size == 'medium' and 42 or size == 'large' and 58 or size == 'verylarge' and 88
end

function UI.Text:SetPosition(set)
	local size = set.Size
	local place = splitstr(set.Place, "-")
	local zoom = set.Zoom
	local Y = TextOffSet(place[1], screen.height) - TextOffSet(place[1], screen.height*zoom, true)
	local X = TextOffSet(place[2], -screen.width*zoom, place[2] ~= 'center')
	
	self:Set({font=size, align=place[2], x=X, y=Y, width=screen.width, height=getHeight(size)})
end

function listFind(inputs)
	local input = nil
	
	for key, bool in pairs(inputs) do
		if bool then
			input = key
		end
	end
	
	return input
end

KZ.Index = UI.PlayerIndex()
KZ.Player = {}
KZ.Event = {}
KZ.PreviousTime = 0
KZ.WeaponMode = {
	"USP45",
	"P90",
	"FAMAS",
	"SG552",
	"M4A1",
	"AK47",
	"AWP",
}

KZ.WeaponModeIndex = 1

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- DigitalTimer

GNum = {}
GNum.__index = GNum

local SEGMENT_COUNT = 7
local SEGMENT_PART_COUNT = 5
local SEGMENT_KEYS = {"a", "b", "c", "d", "e", "f", "g"}
local SEGMENT_SHAPES = {
	a = "top",
	b = "right",
	c = "right",
	d = "bottom",
	e = "left",
	f = "left",
	g = "mid",
}

local GNumMap = {
	["0"] = {a=true, b=true, c=true, d=true, e=true, f=true, g=false},
	["1"] = {a=false, b=true, c=true, d=false, e=false, f=false, g=false},
	["2"] = {a=true, b=true, c=false, d=true, e=true, f=false, g=true},
	["3"] = {a=true, b=true, c=true, d=true, e=false, f=false, g=true},
	["4"] = {a=false, b=true, c=true, d=false, e=false, f=true, g=true},
	["5"] = {a=true, b=false, c=true, d=true, e=false, f=true, g=true},
	["6"] = {a=true, b=false, c=true, d=true, e=true, f=true, g=true},
	["7"] = {a=true, b=true, c=true, d=false, e=false, f=false, g=false},
	["8"] = {a=true, b=true, c=true, d=true, e=true, f=true, g=true},
	["9"] = {a=true, b=true, c=true, d=true, e=false, f=true, g=true},
}

local function GetColor(color)
	return color.r or 255, color.g or 255, color.b or 255, color.a or 255
end

local function ClampMin(value, minValue)
	if value < minValue then
		return minValue
	end
	return value
end

local function Round(value)
	return math.floor(value + 0.5)
end

local SegmentBoneBase = {
	top = {axis = "h", offset = {1, 0, 1, 2, 3}, delta = {0, 2, 0, -2, -4}},
	mid = {axis = "h", offset = {2, 1, 0, 1, 2}, delta = {-2, 0, 2, 0, -2}},
	bottom = {axis = "h", offset = {1, 0, 1, 2, 3}, delta = {0, 2, 0, -2, -4}},
	left = {axis = "v", offset = {1, 0, 1, 2, 3}, delta = {0, 2, 0, -2, -4}},
	right = {axis = "v", offset = {1, 0, 1, 2, 3}, delta = {0, 2, 0, -2, -4}},
}

local SegmentBoneCache = {}

local function BuildSegmentBone(step)
	local out = {}
	for name, src in pairs(SegmentBoneBase) do
		local shape = {axis = src.axis, offset = {}, delta = {}}
		for i = 1, 5 do
			shape.offset[i] = src.offset[i] * step
			shape.delta[i] = src.delta[i] * step
		end
		out[name] = shape
	end
	return out
end

local function GetSegmentBone(step)
	local s = tonumber(step) or 1
	s = ClampMin(s, 1)
	local key = tostring(s)
	if SegmentBoneCache[key] == nil then
		SegmentBoneCache[key] = BuildSegmentBone(s)
	end
	return SegmentBoneCache[key]
end

local function BuildDigitLayout(x, y, len, t)
	local seg = t * 5
	local lead = t * 3
	local join = t

	local ax = x + lead
	local ay = y + lead
	local fx = x
	local fy = ay + seg - join
	local bx = ax + len
	local by = fy
	local gx = ax
	local gy = fy + len + join
	local ex = fx
	local ey = gy + seg - join
	local cx = bx
	local cy = ey
	local dx = ax
	local dy = ey + len

	return {
		a = {index = 1, x = ax, y = ay, width = len, height = seg, shape = SEGMENT_SHAPES.a},
		b = {index = 2, x = bx, y = by, width = seg, height = len, shape = SEGMENT_SHAPES.b},
		c = {index = 3, x = cx, y = cy, width = seg, height = len, shape = SEGMENT_SHAPES.c},
		d = {index = 4, x = dx, y = dy, width = len, height = seg, shape = SEGMENT_SHAPES.d},
		e = {index = 5, x = ex, y = ey, width = seg, height = len, shape = SEGMENT_SHAPES.e},
		f = {index = 6, x = fx, y = fy, width = seg, height = len, shape = SEGMENT_SHAPES.f},
		g = {index = 7, x = gx, y = gy, width = len, height = seg, shape = SEGMENT_SHAPES.g},
	}
end

function GNum:Create(args)
	local instance = setmetatable({}, self)
	args = args or {}
	instance.number = tostring(args.number or 0)
	instance.x = args.x or 0
	instance.y = args.y or 0
	instance.length = args.length or 14
	instance.thickness = args.thickness or 1
	instance.diagStep = args.diagStep or 1
	instance.diagStep = ClampMin(instance.diagStep, 1)
	instance.color = args.color or {r=255, g=255, b=255, a=255}
	instance.boxs = {}
	instance.bone = GetSegmentBone(instance.diagStep)
	instance.layout = BuildDigitLayout(instance.x, instance.y, instance.length, instance.thickness)
	instance.lastNumber = nil
	instance.lastR = nil
	instance.lastG = nil
	instance.lastB = nil
	instance.lastA = nil

	for i = 1, SEGMENT_COUNT do
		instance.boxs[i] = {}
		for j = 1, SEGMENT_PART_COUNT do
			instance.boxs[i][j] = UI.Box.Create()
		end
	end

	instance:Set(instance.number)
	return instance
end

function GNum:SetBox(index, x, y, width, height, visible, shape, r, g, b, a)
	local alpha = visible and a or 0
	local t = self.thickness
	local parts = self.boxs[index]
	local reverse = (shape == "bottom" or shape == "right")
	local function SetPart(partIndex, px, py, pw, ph)
		parts[partIndex]:Set({
			x = px,
			y = py,
			width = pw,
			height = ph,
			r = r,
			g = g,
			b = b,
			a = alpha
		})
	end

	local p = self.bone[shape] or self.bone.mid
	if p.axis == "h" then
		for i = 1, SEGMENT_PART_COUNT do
			local pi = reverse and (SEGMENT_PART_COUNT - i + 1) or i
			local px = x + p.offset[pi]
			local py = y + ((i - 1) * t)
			local pw = math.max(1, width + p.delta[pi])
			SetPart(i, px, py, pw, t)
		end
	else
		for i = 1, SEGMENT_PART_COUNT do
			local pi = reverse and (SEGMENT_PART_COUNT - i + 1) or i
			local px = x + ((i - 1) * t)
			local py = y + p.offset[pi]
			local ph = math.max(1, height + p.delta[pi])
			SetPart(i, px, py, t, ph)
		end
	end
end

function GNum:Set(number, color)
	if color then
		self.color = color
	end

	self.number = tostring(number or self.number)
	local map = GNumMap[self.number] or GNumMap["0"]
	local r, g, b, a = GetColor(self.color)
	local colorChanged = self.lastR ~= r or self.lastG ~= g or self.lastB ~= b or self.lastA ~= a
	local numberChanged = self.lastNumber ~= self.number
	if (not colorChanged) and (not numberChanged) then
		return
	end

	for _, key in ipairs(SEGMENT_KEYS) do
		local segment = self.layout[key]
		self:SetBox(segment.index, segment.x, segment.y, segment.width, segment.height, map[key], segment.shape, r, g, b, a)
	end

	self.lastNumber = self.number
	self.lastR = r
	self.lastG = g
	self.lastB = b
	self.lastA = a
end

function GNum:Show()
	for i = 1, SEGMENT_COUNT do
		for j = 1, SEGMENT_PART_COUNT do
			self.boxs[i][j]:Show()
		end
	end
end

function GNum:Hide()
	for i = 1, SEGMENT_COUNT do
		for j = 1, SEGMENT_PART_COUNT do
			self.boxs[i][j]:Hide()
		end
	end
end


DigitalTimer = {}
DigitalTimer.__index = DigitalTimer

function DigitalTimer:GetSlots(minuteDigits)
	local slots = {}

	for _ = 1, minuteDigits do
		slots[#slots + 1] = "d"
	end

	slots[#slots + 1] = ":"
	slots[#slots + 1] = "d"
	slots[#slots + 1] = "d"

	if self.style == "detail" then
		slots[#slots + 1] = "."
		slots[#slots + 1] = "d"
		slots[#slots + 1] = "d"
	end

	return slots
end

function DigitalTimer:GetMinuteDigits(text)
	local minuteText = tostring(text or self.defaultText):match("^(%d+):")
	if minuteText == nil then
		return 2
	end
	return math.max(2, #minuteText)
end

function DigitalTimer:HideLayout()
	for _, digit in ipairs(self.digits) do
		digit:Hide()
	end

	for _, mark in ipairs(self.marks) do
		mark:Hide()
	end
end

function DigitalTimer:Create(args)
	args = args or {}
	local instance = setmetatable({}, self)
	instance.style = args.style == "simple" and "simple" or "detail"
	instance.align = args.align or "center"
	instance.x = args.x or 0
	instance.y = args.y or 0
	instance.width = args.width or screen.width
	instance.height = args.height or 42
	instance.color = args.color or {r=255, g=255, b=255, a=255}
	instance.scale = args.scale or 1
	if instance.scale <= 0 then
		instance.scale = 1
	end

	local baseThickness = args.thickness or 1
	local baseLength = args.length or 14
	local baseGap = args.gap or 2
	local baseDiagStep = args.diagStep or 1
	instance.thickness = ClampMin(Round(baseThickness * instance.scale), 1)
	instance.length = ClampMin(Round(baseLength * instance.scale), instance.thickness * 5)
	instance.gap = ClampMin(Round(baseGap * instance.scale), 1)
	instance.diagStep = ClampMin(Round(baseDiagStep * instance.scale), 1)
	instance.minuteDigits = 2
	instance.digitCount = 0
	instance.defaultText = instance.style == "simple" and "00:00" or "00:00.00"
	instance.digits = {}
	instance.marks = {}
	instance.lastDigits = {}
	instance.lastText = nil
	instance.visible = true
	instance:Init(instance.minuteDigits)
	instance:Set(instance.defaultText)
	return instance
end

function DigitalTimer:Init(minuteDigits)
	self.minuteDigits = math.max(2, minuteDigits or self.minuteDigits or 2)
	local slots = self:GetSlots(self.minuteDigits)
	local totalWidth = 0
	local digitWidth = self.length + (self.thickness * 6)
	local digitHeight = (self.length * 2) + (self.thickness * 10)
	local markWidth = self.thickness * 4
	local digitCount = 0

	for _, slot in ipairs(slots) do
		if slot == "d" then
			digitCount = digitCount + 1
		end
	end
	self.digitCount = digitCount

	for i = 1, #slots do
		local width = slots[i] == "d" and digitWidth or markWidth
		totalWidth = totalWidth + width
		if i < #slots then
			totalWidth = totalWidth + self.gap
		end
	end

	local startX = self.x
	if self.align == "center" then
		startX = self.x + math.floor((self.width - totalWidth) / 2)
	elseif self.align == "right" then
		startX = self.x + self.width - totalWidth
	end

	local startY = self.y + math.floor((self.height - digitHeight) / 2)
	local cursorX = startX
	local r, g, b, a = GetColor(self.color)
	local colonTopY = startY + math.floor(digitHeight * 0.35)
	local colonBottomY = startY + math.floor(digitHeight * 0.8)
	local dotY = startY + digitHeight - self.thickness

	for _, slot in ipairs(slots) do
		if slot == "d" then
			local digit = GNum:Create({
				number = 0,
				x = cursorX,
				y = startY,
				length = self.length,
				thickness = self.thickness,
				diagStep = self.diagStep,
				color = self.color
			})
			self.digits[#self.digits + 1] = digit
			cursorX = cursorX + digitWidth + self.gap * 2
		elseif slot == ":" then
			local upper = UI.Box.Create()
			local lower = UI.Box.Create()
			upper:Set({x = cursorX, y = colonTopY, width = markWidth, height = markWidth, r = r, g = g, b = b, a = a})
			lower:Set({x = cursorX, y = colonBottomY, width = markWidth, height = markWidth, r = r, g = g, b = b, a = a})
			self.marks[#self.marks + 1] = upper
			self.marks[#self.marks + 1] = lower
			cursorX = cursorX + markWidth + self.gap * 2
		elseif slot == "." then
			local dot = UI.Box.Create()
			dot:Set({x = cursorX, y = dotY, width = markWidth, height = markWidth, r = r, g = g, b = b, a = a})
			self.marks[#self.marks + 1] = dot
			cursorX = cursorX + markWidth + self.gap * 2
		end
	end
end

function DigitalTimer:Set(text)
	local displayText = text or self.defaultText
	local requiredMinuteDigits = self:GetMinuteDigits(displayText)
	if requiredMinuteDigits ~= self.minuteDigits then
		self:HideLayout()
		self.digits = {}
		self.marks = {}
		self.lastDigits = {}
		self.lastText = nil
		self:Init(requiredMinuteDigits)

		if not self.visible then
			for _, digit in ipairs(self.digits) do
				digit:Hide()
			end
			for _, mark in ipairs(self.marks) do
				mark:Hide()
			end
		end
	end

	local raw = displayText:gsub("%D", "")
	if #raw < self.digitCount then
		raw = string.rep("0", self.digitCount - #raw) .. raw
	elseif #raw > self.digitCount then
		raw = raw:sub(#raw - self.digitCount + 1)
	end

	if self.lastText == raw then
		return
	end

	for i = 1, self.digitCount do
		local n = raw:sub(i, i)
		if self.lastDigits[i] ~= n then
			self.digits[i]:Set(n, self.color)
			self.lastDigits[i] = n
		end
	end

	self.lastText = raw
end

function DigitalTimer:SetVisible(visible)
	if type(self.digits) ~= "table" or type(self.marks) ~= "table" then
		return
	end

	if self.visible == visible then
		return
	end

	self.visible = visible

	for _, digit in ipairs(self.digits) do
		if visible then
			digit:Show()
		else
			digit:Hide()
		end
	end

	for _, mark in ipairs(self.marks) do
		if visible then
			mark:Show()
		else
			mark:Hide()
		end
	end
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- Fade Text Module

FadeText = {}

function FadeText:Setup(object, visibleFrame, keepFrame, fadeoutFrame, alpha)
	local user = setmetatable({}, self)
	self.__index = self
	
	user.text = object
	user.r = object:Get().r
	user.g = object:Get().g
	user.b = object:Get().b
	user.value = 0
	user.visibleFrame = visibleFrame or 1 -- 보여지는 프레임
	user.keepFrame = keepFrame or 1 -- 온전히 보이는 프레임
	user.fadeoutFrame = fadeoutFrame or 1 -- 사라지는 프레임
	user.alpha = alpha
	
	FadeText[#FadeText + 1] = user
	
	return user
end

function FadeText:Fade(string, warning)
	self.text:Set({text=string or self.text:Get().text, r=warning and 222 or self.r, g=warning and 100 or self.g, b=warning and 100 or self.b})
	self.value = 1
end

function FadeText:IsVisible()
	return self.value ~= 0
end

function FadeText:FadeOn()
	local alpha = math.floor((self.alpha/self.visibleFrame) * self.value)
	self.text:Set({a=alpha})
end

function FadeText:FadeOut()
	local alpha = self.alpha - math.floor((self.alpha/self.fadeoutFrame) * (self.value-self.visibleFrame-self.keepFrame))
	self.text:Set({a=alpha})
end

function FadeText:FadeControl()
	if self.value <= self.visibleFrame then
		self:FadeOn()
	elseif self.value >= self.visibleFrame + self.keepFrame + self.fadeoutFrame then
		self.value = 0
		self.text:Set({a=0})
		return
	elseif self.value >= self.visibleFrame + self.keepFrame then
		self:FadeOut()
	end
	
	self.value = self.value + 1
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- Menu Module

Menu = {}

function Menu:IsVisible()
	return self.stack[1]:IsVisible()
end

---@param titleArg table
---@param elemArg table
---@param elemCount number
---@return Menu
function Menu:new(titleArg, elemArg, elemCount)
	local menu = setmetatable({}, self)
	self.__index = self
	
	menu.titleArg = titleArg
	menu.elemArg = {}
	
	menu.stack = {}
	
	menu.title = UI.Text.Create()
	menu.title:Set(titleArg)
	
	menu.stack[#menu.stack + 1] = menu.title
	
	menu.elem = {}
	
	for k, v in pairs(elemArg) do
		menu.elem[k] = {}
		menu.elemArg[k] = v
		for i = 1, elemCount do
			menu.elem[k][i] = UI.Text.Create()
			menu.elem[k][i]:Set(v)
			menu.elem[k][i]:Set({y=v.y + ((i-1)*20)})
			menu.stack[#menu.stack + 1] = menu.elem[k][i]
		end
	end
	
	Menu[#Menu + 1] = menu
	
	return menu
end

function Menu:PageSetup(data, elemIndex)
	if not self.iter then
		self.iter = {}
		self.page = 0
	end
	
	self.iter[elemIndex] = data
	self:Page(self.page) -- 내용 새로고침
end

function Menu:Page(page)
	page = page or 0
	
	local maxcount = 0
	local maxnumber = 0
	
	if not self.titleText then
		self.titleText = self.title:Get().text
	end
	
	for k, v in pairs(self.iter) do
		maxcount = #v
		maxnumber = math.min(maxcount - (page * 7), 7)
		
		for i = 1, maxnumber do
			self.elem[k][i]:Set({text=v[i+(page*7)]})
		end
	end
	
	for i = 1, #self.elem do
		for j = 1, maxnumber do
			self.elem[i][j]:Set({a=self.elemArg[i].a})
		end
		
		for j = maxnumber+1, 7 do
			self.elem[i][j]:Set({a=0})
		end
		
		self.elem[i][8]:Set({a=self.elemArg[i].a})
		self.elem[i][9]:Set({a=self.elemArg[i].a})
	end
	
	self.title:Set({text=self.titleText..string.format(" %d/%d", page+1, math.max(math.ceil(maxcount/7), 1))})
	
	if page == 0 then -- Back
		for i = 1, #self.elem do
			self.elem[i][8]:Set({a=80})
		end
	end
	
	if maxcount < ((page+1) * 7) then -- More
		for i = 1, #self.elem do
			self.elem[i][9]:Set({a=80})
		end
	end
end

function Menu:Visible(visible, page)
	if visible then
		if self.page then
			self:Page(page)
		end
		
		for k, v in pairs(self.stack) do
			v:Show()
		end
	else
		for k, v in pairs(self.stack) do
			v:Hide()
		end
		
		if self.page then
			self.page = 0
		end
	end
end

function Menu:PageDown()
	if self.page == nil then
		return
	end
	
	if self.page > 0 then
		self.page = self.page - 1
		self:Visible(true, self.page)
	end
end

function Menu:PageUp()
	if self.page == nil then
		return
	end
	
	for _, v in pairs(self.iter) do
		if #v > ((self.page+1) * 7) then
			self.page = self.page + 1
			self:Visible(true, self.page)
			return
		end
	end
end

function Menu:ActionSetup(number, method)
	-- 메뉴 버튼에 메서드 할당
	if self.event == nil then
		self.event = {}
	end
	
	self.event[number] = method
end

function Menu:Action(number)
	if self.event == nil or self.event[number] == nil then
		return
	end
	
	self.event[number](self)
end

function Menu:Showing()
	-- 보여지고 있는 메뉴 검색
	for k, v in ipairs(Menu) do
		if v:IsVisible() then
			return v
		end
	end
	
	return self
end

function Menu:Toggle()
	-- 보여지고 있는 메뉴를 토글하면 메뉴 숨기기
	-- 보여지고 있는 메뉴와 다른 메뉴를 토글하면 메뉴 새로 보이기
	if KZ and KZ.Event and KZ.Event.HideAllMenuQR then
		if self ~= rankingMenu then
			KZ.Event:HideAllMenuQR()
		end
	end

	for k, v in ipairs(Menu) do
		v:Visible(v == self and not v:IsVisible())
	end
end

local title_set = HUD.Menu.Title
local default_color = HUD.Menu.Elem.Color_default
local number_color = HUD.Menu.Elem.Color_number

local menuTitleSet = {font='small', align='left', x=30, y=center.y-124, width=250, height=20,
	r=title_set.Color.r, g=title_set.Color.g, b=title_set.Color.b, a=title_set.Color.a}
local menuNumberSet = {font='small', align='left', x=30, y=center.y-90, width=250, height=20,
	r=number_color.r, g=number_color.g, b=number_color.b, a=number_color.a}
local menuElemSet = {font='small', align='left', x=48, y=center.y-90, width=250, height=20,
	r=default_color.r, g=default_color.g, b=default_color.b, a=default_color.a}

KZ.Menu = Menu

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- HUD

local label_set = HUD.Label

label_1 = UI.Text.Create()
label_2 = UI.Text.Create()

label_1:SetPosition(label_set)
label_2:SetPosition(label_set)

label_1:Set({text=label_set.Text_1, r=label_set.Color_1.r, g=label_set.Color_1.g, b=label_set.Color_1.b, a=label_set.Color_1.a})
label_2:Set({text=label_set.Text_2, r=label_set.Color_2.r, g=label_set.Color_2.g, b=label_set.Color_2.b, a=label_set.Color_2.a})

local descr_set = HUD.Descr.DefaultMenu

descr = UI.Text:Create()
descr:Set({text=descr_set.Text, font='small', align="right", x=-20, y=screen.height/4*3, width=screen.width, height=16,
	r=descr_set.Color.r, g=descr_set.Color.g, b=descr_set.Color.b, a=descr_set.Color.a})

local Notice = HUD.Notice
local main_set = Notice.Main
local under_set = Notice.Under
local issue_set = Notice.Issue

clearNotice = UI.Text.Create()
underNotice = UI.Text.Create()
issueText = UI.Text:Create()

clearNotice:SetPosition(main_set)
underNotice:SetPosition(under_set)

clearNotice:Set({r=main_set.Color.r, g=main_set.Color.g, b=main_set.Color.b, a=main_set.Color.a})
underNotice:Set({r=under_set.Color.r, g=under_set.Color.g, b=under_set.Color.b, a=under_set.Color.a})
issueText:Set({font='small', align="left", x=30, y=screen.height/20*14, width=screen.width, height=screen.height/10,
	r=issue_set.Color.r, g=issue_set.Color.g, b=issue_set.Color.b, a=issue_set.Color.a})

FadeText.main = FadeText:Setup(clearNotice, main_set.VisibleFrame, main_set.KeepFrame, main_set.FadeoutFrame, main_set.Color.a)
FadeText.under = FadeText:Setup(underNotice, under_set.VisibleFrame, under_set.KeepFrame, under_set.FadeoutFrame, under_set.Color.a)
FadeText.issue = FadeText:Setup(issueText, issue_set.VisibleFrame, issue_set.KeepFrame, issue_set.FadeoutFrame, issue_set.Color.a)

if DebugMode then
	clearNotice:Set({text="Unknown 맵 클리어 00:00.00 ( CPs: 0| GCs: 0 ) !"})
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 속도계

local Unit = HUD.Unit
local pre_set = Unit.Pre
local max_set = Unit.Max
local speed_set = Unit.Speed

playerPre = UI.Text.Create()
playerMax = UI.Text.Create()
playerSpeed = UI.Text.Create()

playerPre:SetPosition(pre_set)
playerMax:SetPosition(max_set)
playerSpeed:SetPosition(speed_set)

playerPre:Set({r=pre_set.Color_default.r, g=pre_set.Color_default.g, b=pre_set.Color_default.b, a=pre_set.Color_default.a})
playerMax:Set({r=max_set.Color.r, g=max_set.Color.g, b=max_set.Color.b, a=max_set.Color.a})
playerSpeed:Set({r=speed_set.Color.r, g=speed_set.Color.g, b=speed_set.Color.b, a=speed_set.Color.a})

FadeText.Pre = FadeText:Setup(playerPre, pre_set.VisibleFrame, pre_set.KeepFrame, pre_set.FadeoutFrame, pre_set.Color_default.a)
FadeText.Max = FadeText:Setup(playerMax, max_set.VisibleFrame, max_set.KeepFrame, max_set.FadeoutFrame, max_set.Color.a)

function SetGroundSpeed(index)
	speed = SyncValueCreate(string.format("groundSpeed%i", index))
	function speed:OnSync()
		playerSpeed:Set({text=string.format("%d units/sec", math.floor(self.value))})
	end
end

function SetPreStrafe(index)
	pre = SyncValueCreate(string.format("preStrafe%i", index))
	
	function pre:OnSync()
		local str
			
		if self.value >= 10000 then
			local pre = self.value % 10000
			local baseSpeed = WEAPONSPEED[KZ.WeaponModeIndex]
			local limit = 250*baseSpeed*1.2 -- movement 정보 받을 것
			
			if pre >= limit then
				str = string.format("Your prestrafe %03.3f is too high (%03.3f)", pre, limit)
				playerPre:Set(pre_set.Color_fail)
			else
				str = string.format("%03.3f pre", pre)
				playerPre:Set(pre_set.Color_default)
			end
		else
			str = string.format("%03.3f pre", self.value)
			playerPre:Set(pre_set.Color_default)
		end
		
		FadeText.Pre:Fade(str)
	end
end

function SetMaxSpeed(index)
	maxspeed = SyncValueCreate(string.format("maxSpeed%i", index))
	local baseSpeed = WEAPONSPEED[KZ.WeaponModeIndex]
	
	function maxspeed:OnSync()
		if not pre.value or pre.value % 10000 > self.value then
			return
		end
		
		local P = tonumber(pre.value) % 10000
		local M = tonumber(self.value)
		if P > 250*baseSpeed*1.2 then P = 250*baseSpeed*0.96 end -- movement 정보 받을 것
		local cal = M - P
		if cal < 0 then cal = 0 end
		local str = string.format("Maxspeed: %03.2f (%05.3f)", self.value, cal)
		
		FadeText.Max:Fade(str)
	end
end

function KZ.Event:SetSpeedMeter(index)
	if speed then
		function speed:OnSync()
		end
	end
	
	if pre then
		function pre:OnSync()
		end
	end
	
	if maxspeed then
		function maxspeed:OnSync()
		end
	end
	
	SetGroundSpeed(index)
	SetPreStrafe(index)
	SetMaxSpeed(index)
end

KZ.Event:SetSpeedMeter(KZ.Index)

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 타이머

Effect = Module.UI.BG:Create()

Timer = {}
Timer.isrunning = false

KZ.Player.cp = {}
KZ.Player.gc = {}

local timer_set = HUD.Timer
NewTimerMode = true

Timer.timer = UI.Text.Create()
Timer.timer:SetPosition(timer_set)
Timer.timer:Set({text="00:00.00", r=timer_set.Color.r, g=timer_set.Color.g, b=timer_set.Color.b, a=timer_set.Color.a})

if timer_set.Style == 'simple' then

	Timer.timer:Set({text="00:00"})
	
	function timeToStr(time)
		return string.format("%02d:%02d", time//60, math.floor(time%60))
	end
else

	Timer.timer:Set({text="00:00.00"})
	
	function timeToStr(time)
		return string.format("%02d:%05.2f", time//60, time%60)
	end
end

function Timer:CreateDigital()
	if Timer.digital then
		return
	end

	local timerArg = Timer.timer:Get()
	Timer.digital = DigitalTimer:Create({
		style = timer_set.Style,
		align = timerArg.align,
		x = timerArg.x,
		y = timerArg.y,
		width = timerArg.width,
		height = timerArg.height,
		color = timer_set.Color,
		scale = timer_set.Scale or 1,
		length = timer_set.DigitalLength or 14,
		diagStep = timer_set.DigitalDiagStep or 1
	})
	Timer.timer:Set({a=0})
end

function Timer:Init() -- 접속 시
	Timer:CreateDigital()
	KZ.Player.cp[UI.PlayerIndex()] = 0
	KZ.Player.gc[UI.PlayerIndex()] = 0
	KZ.Clear = false
	Timer:Reset()
end

function Timer:Reset(clear) -- 타이머 종료, 제트팩 리셋, 세이브 리셋, 종료 리셋
	Timer.pause = false
	Timer.startTime = 0
	Timer.pauseTime = 0
	Timer.pauseStart = 0
	Timer.pauseEnd = 0
	
	if clear then
		-- 맵 클리어가 아니고 타이머 재정비
		if Timer.digital then
			Timer.digital:Set(Timer.defaultText)
		else
			Timer.timer:Set({text=Timer.defaultText})
		end
	end
end

function Timer:ChangeTimerMode(new)
	NewTimerMode = not not new

	if Timer.digital then
		Timer.digital:SetVisible(NewTimerMode)
	end

	Timer.timer:Set({a = NewTimerMode and 0 or 255})
	digitalTimerElem:Set({text = NewTimerMode and "Digital" or "Normal"})
end

function Timer:GetTime()
	return UI.GetTime() - (Timer.startTime + Timer.pauseTime)
end

function Timer:CanStartAndFinish(finish)
	-- 타이머를 시작/종료할 수 없는 상태면 false
	
	if KZ.Used_JetPack > UI.GetTime() then -- 제트팩 후 3초 방지
		FadeText.under:Fade(ReservedText.UsedJetPack)
		return false
	end

	if KZ.Used_Pause > UI.GetTime() and finish then -- 퍼즈 후 1초 방지
		FadeText.under:Fade(ReservedText.UsedPause)
		return false
	end

	return not Timer.pause
end

function Timer:Start()
	if Timer:CanStartAndFinish(false) then
		Timer.isrunning = true
		Timer:Reset()
		Timer.startTime = UI.GetTime()
		FadeText.under:Fade(ReservedText.TimerStart)
		KZ.Event:HideSubmitQR()
		KZ.JetPack = false
	end
end

function Timer:Finish()
	if Timer.startTime == 0 then
		FadeText.under:Fade(ReservedText.DidNotStart)
	elseif Timer:CanStartAndFinish(true) then
		Timer.isrunning = false
		local time = math.floor(Timer:GetTime()*100)
		UI.Signal(time)
		KZ.PreviousTime = time
		Timer:Reset(false)
		KZ.Clear = true
		KZ.Event:SubmitMenu()
	end
end

function Timer:Pause_On()
	Timer.pause = true
	pauseElem:Set({text="ON", g=255})
	Effect:ShowEffect(HUD.Effect.PauseColor)

	Timer.pauseStart = UI.GetTime()
	FadeText.under:Fade(ReservedText.PauseOn)
end

function Timer:Pause_Off(reset)
	KZ.Used_Pause = UI.GetTime()+1

	if KZ.JetPack then
		-- 제트팩 강제 종료
		KZ.JetPack = false
		UI.Signal(SIGNAL.ToGame.NC_OFF)
	end
	pauseElem:Set({text="OFF", g=50})
	Effect:HideEffect(HUD.Effect.PauseColor)
	Timer.pauseEnd = Timer.pauseEnd + (UI.GetTime() - Timer.pauseStart)
	FadeText.under:Fade(ReservedText.PauseOff)
	
	if reset then
		-- 퍼즈 중 세이브를 하면 퍼즈 포지션으로 이동하지 않고 리셋만
		UI.Signal(SIGNAL.ToGame.RESET)
	else
		UI.Signal(SIGNAL.ToGame.PAUSE_OFF)
	end
	
	Timer.pause = false
end

function Timer:Refresh()
	local timeText = timeToStr(Timer:GetTime())
	if NewTimerMode then
		Timer.digital:Set(timeText)
	end
	Timer.timer:Set({text=timeText})
end

function KZ.Event:Pause()
	if not Timer.pause then
		if Timer.startTime == 0 then
			FadeText.under:Fade(ReservedText.DidNotStart)
		else
			UI.Signal(SIGNAL.ToGame.PAUSE_ON)
		end
	else
		Timer:Pause_Off()
	end
end

KZ.Timer = Timer

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 클리어

sessionRank = SyncValueCreate('sessionRank', 3)
clear = SyncValueCreate('clear')

sessionRanking = {}

for i = 1, 3 do
	local session_set = HUD.Session_Rank[i]
	sessionRanking[i] = UI.Text.Create()
	sessionRanking[i]:Set({font="small", align="left", x=screen.width/35, y=screen.height/8+((i-1)*48), width=300, height=40,
		r=session_set.Color.r, g=session_set.Color.g, b=session_set.Color.b, a=session_set.Color.a})
	
	local rank = sessionRank[i]
	function rank:OnSync()
		sessionRanking[i]:Set({text=session_set.Text.."\n"..self.value})
	end
end

function clear:OnSync()
	FadeText.main:Fade(self.value)
end

if DebugMode then
	for i = 1, 3 do
		local session_set = HUD.Session_Rank[i]
		sessionRanking[i]:Set({text=session_set.Text.."\n".."00:00.00 (0/0) Unknown"})
	end
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 체크포인트

CP = SyncValueCreate('checkPoint', VALUE.MaxPlayer)
GC = SyncValueCreate('goCheck', VALUE.MaxPlayer)

for i = 1, VALUE.MaxPlayer do
	local cp = CP[i]
	local gc = GC[i]
	
	function cp:OnSync()
		if i == UI.PlayerIndex() then
			KZ.Event:OnCheckPoint(self.value)
		end
		
		KZ.Player.cp[i] = self.value
		KZ.Event:RefreshSpecTimer(i)
	end
	
	function gc:OnSync()
		if i == UI.PlayerIndex() then
			KZ.Event:OnGoCheck(self.value)
		end
		
		KZ.Player.gc[i] = self.value
		KZ.Event:RefreshSpecTimer(i)
	end
end

function KZ.Event:OnCheckPoint(value)
	if value ~= 0 then
		local txt = string.format("체크포인트 ＃%d", value)
		FadeText.under:Fade(txt)
	end
	
	local str = string.format("＃%d", value)
	cpElem:Set({text=str})
end

function KZ.Event:OnGoCheck(value)
	if value ~= 0 then
		local txt = string.format("고체크 ＃%d", value)
		FadeText.under:Fade(txt)
	end
	
	local str = string.format("＃%d", value)
	gcElem:Set({text=str})
end

function KZ.Event:CP()
	if MAP.CanCP then
		UI.Signal(SIGNAL.ToGame.CP)
	end
end

function KZ.Event:GC()
	if ViewAngleMode then
		UI.Signal(SIGNAL.ToGame.ANGLE_CHECK_POINT)
		return
	end
	if MAP.CanCP then
		UI.Signal(SIGNAL.ToGame.GC)
	end
end

function KZ.Event:ViewAngleGC()
	if MAP.CanCP then
		UI.Signal(SIGNAL.ToGame.ANGLE_CHECK_POINT)
		UI.Signal(SIGNAL.ToGame.GC)
	end
end

function KZ.Event:BackCP()
	if MAP.CanCP then
		UI.Signal(SIGNAL.ToGame.BACKCP)
	end
end

function KZ.Event:Start()
	if UndefinedPosition then
		UI.Signal(SIGNAL.ToGame.FREESTART)
	else
		UI.Signal(SIGNAL.ToGame.START)
	end
	
	FadeText.under:Fade(ReservedText.TPtoStart)
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 관전

Spec = {}

KZ.Player.name = {}
KZ.Player.time = {}

specPlayer = SyncValueCreate('specPlayer', VALUE.MaxPlayer)

for k, v in pairs(specPlayer) do
	function v:OnSync()
		KZ.Player.name[k] = self.value
		
		KZ.playerList = KZ.Event:SetPlayerList()
		specMenu:PageSetup(KZ.playerList.name, 2)
		tpMenu:PageSetup(KZ.playerList.name, 2)
	end
end

function KZ.Event:SetPlayerList()
	local list = {}
	
	list.index = {}
	list.name = {}
	
	for index, name in pairs(KZ.Player.name) do
		if name ~= '' then
			list.index[#list.index + 1] = index
			list.name[#list.name + 1] = name
		end
	end
	
	return list
end

specMenu = Menu:new(menuTitleSet, {menuNumberSet, menuElemSet}, 10)

specMenu.title:Set({text=title_set.SpecMenu})
specMenu.elem[1][1]:Set({text="1. "})
specMenu.elem[1][2]:Set({text="2. "})
specMenu.elem[1][3]:Set({text="3. "})
specMenu.elem[1][4]:Set({text="4. "})
specMenu.elem[1][5]:Set({text="5. "})
specMenu.elem[1][6]:Set({text="6. "})
specMenu.elem[1][7]:Set({text="7. "})
specMenu.elem[1][8]:Set({text="8. "})	specMenu.elem[2][8]:Set({text="Bacｋ"})
specMenu.elem[1][9]:Set({text="9. "})	specMenu.elem[2][9]:Set({text="More"})
specMenu.elem[1][10]:Set({text="0. "})	specMenu.elem[2][10]:Set({text="Exit"})

specMenu:PageSetup(KZ.Event:SetPlayerList().name, 2)

specMenu:Visible(false)

local spectimer_set = HUD.Spec.Timer
local specname_set = HUD.Spec.Name

spectating = {}

Spec.timer = UI.Text.Create()
Spec.timer:SetPosition(spectimer_set)
Spec.timer:Set({r=spectimer_set.Color.r, g=spectimer_set.Color.g, b=spectimer_set.Color.b, a=spectimer_set.Color.a})

spectating[#spectating + 1] = Spec.timer

function Spec:OnOff(value)
	-- 관전을 풀 방법이 있을거라 믿고 만들어두자
	if value then
		self.value = true
		Timer.timer:Hide()
		for _, text in ipairs(spectating) do
			text:Show()
		end
		descr:Set({text=HUD.Descr.SpecMenu.Text, r=HUD.Descr.SpecMenu.Color.r, g=HUD.Descr.SpecMenu.Color.g, b=HUD.Descr.SpecMenu.Color.b, a=HUD.Descr.SpecMenu.Color.a})
	else
		self.value = false
		Timer.timer:Show()
		for _, text in ipairs(spectating) do
			text:Hide()
		end
		descr:Set({text=HUD.Descr.DefaultMenu.Text, r=HUD.Descr.DefaultMenu.Color.r, g=HUD.Descr.DefaultMenu.Color.g, b=HUD.Descr.DefaultMenu.Color.b, a=HUD.Descr.DefaultMenu.Color.a})
	end
end

function Spec:playerSelect()
	local i = OnInputNumber + (specMenu.page*7)
	
	if KZ.playerList.index[i] then
		KZ.Event:ConnectIndex(KZ.playerList.index[i])
		specMenu:Toggle()
	end
end

Spec.CPs = {}

sharingTime = SyncValueCreate('sharingTime', VALUE.MaxPlayer)

for i, v in pairs(sharingTime) do
	function v:OnSync()
		KZ.Player.time[i] = self.value
		KZ.Event:RefreshSpecTimer(i)
	end
end

function KZ.Event:ConnectIndex(index)
	-- 인덱스를 받음
	-- 기존에 받던 인덱스의 ui들 초기화
	-- ui 새로고침
	KZ.Index = index
	self:SetSpeedMeter(index)
	
	-- Spectating player.name
	Spec.name:Set({text=string.format("Spectating %s", KZ.Player.name[index])})
	
	KZ.Event:RefreshSpecTimer(index)
end

function KZ.Event:Spec()
	Spec:OnOff(true)
	UI.Signal(SIGNAL.ToGame.SPEC) -- 플레이어를 죽임
	specMenu:Toggle()
end

function KZ.Event:RefreshSpecTimer(index)
	local CPs = string.format("[CPs: %d, GCs: %d]", KZ.Player.cp[index] or 0, KZ.Player.gc[index] or 0)
	local Time = KZ.Player.time[index] or '00:00'
	
	Spec.CPs[index] = Time.." "..CPs
	
	if KZ.Index == index then
		Spec.timer:Set({text=Spec.CPs[index]})
	end
end

specMenu:ActionSetup(1, Spec.playerSelect)
specMenu:ActionSetup(2, Spec.playerSelect)
specMenu:ActionSetup(3, Spec.playerSelect)
specMenu:ActionSetup(4, Spec.playerSelect)
specMenu:ActionSetup(5, Spec.playerSelect)
specMenu:ActionSetup(6, Spec.playerSelect)
specMenu:ActionSetup(7, Spec.playerSelect)
specMenu:ActionSetup(8, specMenu.PageDown)
specMenu:ActionSetup(9, specMenu.PageUp)

--------------------------------------------------------------------------------------------------

local specoverlay_set = HUD.Spec.Overlay

Spec.input_W = UI.Text.Create()
Spec.input_A = UI.Text.Create()
Spec.input_S = UI.Text.Create()
Spec.input_D = UI.Text.Create()
Spec.pause = UI.Text.Create()
Spec.name = UI.Text.Create()

Spec.input_W:SetPosition(specoverlay_set)
Spec.input_A:SetPosition(specoverlay_set)
Spec.input_S:SetPosition(specoverlay_set)
Spec.input_D:SetPosition(specoverlay_set)
Spec.pause:SetPosition(specoverlay_set)
Spec.name:SetPosition(specoverlay_set)

Spec.input_W:Set({r=specoverlay_set.Color.r, g=specoverlay_set.Color.g, b=specoverlay_set.Color.b, a=specoverlay_set.Color.a})
Spec.input_A:Set({r=specoverlay_set.Color.r, g=specoverlay_set.Color.g, b=specoverlay_set.Color.b, a=specoverlay_set.Color.a})
Spec.input_S:Set({r=specoverlay_set.Color.r, g=specoverlay_set.Color.g, b=specoverlay_set.Color.b, a=specoverlay_set.Color.a})
Spec.input_D:Set({r=specoverlay_set.Color.r, g=specoverlay_set.Color.g, b=specoverlay_set.Color.b, a=specoverlay_set.Color.a})
Spec.pause:Set({r=specoverlay_set.Color.r, g=specoverlay_set.Color.g, b=specoverlay_set.Color.b, a=specoverlay_set.Color.a})
Spec.name:Set({r=specoverlay_set.Color.r, g=specoverlay_set.Color.g, b=specoverlay_set.Color.b, a=specoverlay_set.Color.a})

spectating[#spectating + 1] = Spec.input_W
spectating[#spectating + 1] = Spec.input_A
spectating[#spectating + 1] = Spec.input_S
spectating[#spectating + 1] = Spec.input_D
spectating[#spectating + 1] = Spec.pause
spectating[#spectating + 1] = Spec.name

local W = Spec.input_W:Get()

Spec.input_W:Set({text='·'})
Spec.input_A:Set({text='·', x=W.x-16, y=W.y+16})
Spec.input_S:Set({text='·', y=W.y+16})
Spec.input_D:Set({text='·', x=W.x+16, y=W.y+16})
Spec.pause:Set({x=W.x+TextOffSet(splitstr(specoverlay_set.Place, "-")[2], 32, true), y=W.y-28})
Spec.name:Set({x=W.x+TextOffSet(splitstr(specoverlay_set.Place, "-")[2], 64, true), y=W.y+56})

Spec.input_W:Hide()
Spec.input_A:Hide()
Spec.input_S:Hide()
Spec.input_D:Hide()
Spec.pause:Hide()
Spec.name:Hide()

function KZ.Event:RefreshInputOverlay(index)
	if KZ.Index == index then
		Spec.input_W:Set({text=KZ.Player.input_W[index] and 'W' or '·'})
		Spec.input_A:Set({text=KZ.Player.input_A[index] and 'A' or '·'})
		Spec.input_S:Set({text=KZ.Player.input_S[index] and 'S' or '·'})
		Spec.input_D:Set({text=KZ.Player.input_D[index] and 'D' or '·'})
		Spec.pause:Set({text=KZ.Player.pause[index] and '[PAUSED]' or ''})
	end
end

KZ.Spec = Spec

if DebugMode then
	Spec.timer:Set({text="00:00 [CPs: 0, GCs: 0]"})
	Spec.name:Set({text="Spectating Unknown"})
	for _, text in ipairs(spectating) do
		text:Show()
	end
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 텔레포트 메뉴

TP = {}

tpMenu = Menu:new(menuTitleSet, {menuNumberSet, menuElemSet}, 10)

tpMenu.title:Set({text=title_set.TPMenu})
tpMenu.elem[1][1]:Set({text="1. "})
tpMenu.elem[1][2]:Set({text="2. "})
tpMenu.elem[1][3]:Set({text="3. "})
tpMenu.elem[1][4]:Set({text="4. "})
tpMenu.elem[1][5]:Set({text="5. "})
tpMenu.elem[1][6]:Set({text="6. "})
tpMenu.elem[1][7]:Set({text="7. "})
tpMenu.elem[1][8]:Set({text="8. "})		tpMenu.elem[2][8]:Set({text="Bacｋ"})
tpMenu.elem[1][9]:Set({text="9. "})		tpMenu.elem[2][9]:Set({text="More"})
tpMenu.elem[1][10]:Set({text="0. "})	tpMenu.elem[2][10]:Set({text="Exit"})

tpMenu:PageSetup(KZ.Event:SetPlayerList().name, 2)

tpMenu:Visible(false)

function TP:playerSelect()
	local i = OnInputNumber + (tpMenu.page*7)
	
	if KZ.playerList.index[i] then
		KZ.Event:TeleportToPlayer(KZ.playerList.index[i])
		tpMenu:Toggle()
	end
end

function KZ.Event:TeleportToPlayer(index)
	if KZ.JetPack and KZ.Used_Pause < UI.GetTime() then
		UI.Signal(index + 900000000)
	else
		FadeText.under:Fade(ReservedText.NeedJetPack)
	end
end

function KZ.Event:TP()
	tpMenu:Toggle()
end

tpMenu:ActionSetup(1, TP.playerSelect)
tpMenu:ActionSetup(2, TP.playerSelect)
tpMenu:ActionSetup(3, TP.playerSelect)
tpMenu:ActionSetup(4, TP.playerSelect)
tpMenu:ActionSetup(5, TP.playerSelect)
tpMenu:ActionSetup(6, TP.playerSelect)
tpMenu:ActionSetup(7, TP.playerSelect)
tpMenu:ActionSetup(8, tpMenu.PageDown)
tpMenu:ActionSetup(9, tpMenu.PageUp)

KZ.TP = TP

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- rtv

RTV = SyncValueCreate('RTV')

local rtv_set = HUD.RTV

rtvPlr_1 = UI.Text:Create()
rtvPlr_2 = UI.Text:Create()
rtvPlr_1:Set({font='small', align="left", x=30, y=screen.height/20*14+20, width=screen.width, height=screen.height/10,
	r=rtv_set.Color_1.r, g=rtv_set.Color_1.g, b=rtv_set.Color_1.b, a=rtv_set.Color_1.a})
rtvPlr_2:Set({font='small', align="left", x=30, y=screen.height/20*14+20, width=screen.width, height=screen.height/10,
	r=rtv_set.Color_2.r, g=rtv_set.Color_2.g, b=rtv_set.Color_2.b, a=rtv_set.Color_2.a})

FadeText.rtv_1 = FadeText:Setup(rtvPlr_1, rtv_set.VisibleFrame, rtv_set.KeepFrame, rtv_set.FadeoutFrame, rtv_set.Color_1.a)
FadeText.rtv_2 = FadeText:Setup(rtvPlr_2, rtv_set.VisibleFrame, rtv_set.KeepFrame, rtv_set.FadeoutFrame, rtv_set.Color_2.a)

function RTV:OnSync()
	local str_1 = string.format("%d 명의 유저 'rtv'가 필요합니다.", self.value)
	local str_2 = string.format("%d", self.value)
	
	FadeText.rtv_1:Fade(str_1)
	FadeText.rtv_2:Fade(str_2)
end

function KZ.Event:RTV()
	UI.Signal(SIGNAL.ToGame.RTV)
end

if DebugMode then
	rtvPlr_1:Set({text="1명의 유저 'rtv'가 필요합니다."})
	rtvPlr_2:Set({text="1"})
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- Log

Log = SyncValueCreate('Log')

function Log:OnSync()
	local value = splitstr(self.value, "|")
	if tonumber(value[1]) == UI.PlayerIndex() then
		for i = 2, #value do
			-- print(value[i])
		end
	end
end

function KZ.Event:Log()
	UI.Signal(SIGNAL.ToGame.LOG)
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 제트팩

function KZ.Event:NC()
	if (MAP.ClearJetPack and not KZ.Clear) then
		-- 클리어 후 제트팩 사용 가능
		FadeText.under:Fade(ReservedText.CantJP)
	else
		if KZ.JetPack then
			-- 제트팩 ON
			KZ.JetPack = false
			UI.Signal(SIGNAL.ToGame.NC_OFF)
			FadeText.under:Fade(ReservedText.JetPackOff)
		else
			-- 제트팩 OFF
			KZ.JetPack = true
			UI.Signal(SIGNAL.ToGame.NC_ON)
			FadeText.under:Fade(ReservedText.JetPackOn)
			if (Timer.startTime ~= 0 and not Timer.pause) then
				-- 타이머 리셋
				UI.Signal(SIGNAL.ToGame.RESET)
				FadeText.issue:Fade(ReservedText.TimerResetByJetPack)
			end
		end
	end
end

function KZ.Event:UseJetPack()
	if KZ.JetPack then
		UI.Signal(SIGNAL.ToGame.JETPACK)
		KZ.Used_JetPack = UI.GetTime()+3
	elseif MAP.AutoBhop then
		UI.Signal(SIGNAL.ToGame.AUTOBHOP)
	end
end


--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 커맨드

function KZ.Event:OnCommand(command)
	-- MAP.CanCP false 시 불가능한 것 : CP, GC, BackCP, Save
	if command == COMMAND.CP then
		KZ.Event:CP()
	elseif command == COMMAND.GC then
		KZ.Event:GC()
	elseif command == COMMAND.BACKCP then
		KZ.Event:BackCP()
	elseif command == COMMAND.JETPACK then
		KZ.Event:NC()
	elseif command == COMMAND.SPEC then
		KZ.Event:Spec()
	elseif command == COMMAND.START then
		KZ.Event:Start()
	elseif command == COMMAND.ALL then
		KZ.Event:All()
	elseif command == COMMAND.MENU then
		KZ.Event:Menu()
	elseif command == COMMAND.PAUSE then
		KZ.Event:Pause()
	elseif command == COMMAND.BIND then
		KZ.Event:Bind()
	elseif command == COMMAND.UNBIND then
		KZ.Event:UnBind()
	elseif command == COMMAND.LOG then
		KZ.Event:Log()
	elseif command == COMMAND.RTV then
		KZ.Event:RTV()
	elseif command == COMMAND.SAVE then
		KZ.Event:Save()
	elseif command == COMMAND.viewangleGC then
		KZ.Event:ViewAngleGC()
	end
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 가상 커맨드 -AuMaDeath-

CommandKeySHIFT = false

vcommandInsert = false
vcommand = ''

function InputToChar(keyIndex)
	local s = ''

	-- 스페이스 처리
	if keyIndex == 37 then
		s = ' '
	
	-- 알파벳 입력만 추출
	elseif (UI.KEY.A <= keyIndex and keyIndex <= UI.KEY.Z) then
		s = string.char(keyIndex + 87)
	end

	return s
end

function SetCommandInput(vcommand)
	if vcommandInsert then
		PlayerCommand:Show()
		PlayerCommandLine:Show()
		PlayerCommand:Set({ text = string.format("명령어 입력 중 : %s", vcommand) })
	else
		PlayerCommand:Hide()
		PlayerCommandLine:Hide()
	end
end

PlayerCommand = UI.Text.Create()
PlayerCommand:Set({font="small", align="left", x=center.x-150, y=center.y-66, width=300, height=50, r=222,g=222,b=222,a=222})
PlayerCommandLine = UI.Box.Create()
PlayerCommandLine:Set({x=center.x-152, y=center.y-44, width=304, height=1, r=222,g=222,b=222,a=222})

PlayerCommand:Hide()
PlayerCommandLine:Hide()

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 인풋 오버레이

local keyviewer_set = HUD.KeyViewer

local keyviewer_x = screen.width/5*3
local keyviewer_y = screen.height/10*9

input_W = UI.Text.Create()
input_W:Set({text="W", font='medium', align='center', x=keyviewer_x, y=keyviewer_y-40, width=40, height=41,
	r=keyviewer_set.Color.r, g=keyviewer_set.Color.g, b=keyviewer_set.Color.b, a=40})

input_A = UI.Text.Create()
input_A:Set({text="A", font='medium', align='center', x=keyviewer_x-40, y=keyviewer_y, width=40, height=41,
	r=keyviewer_set.Color.r, g=keyviewer_set.Color.g, b=keyviewer_set.Color.b, a=40})

input_S = UI.Text.Create()
input_S:Set({text="S", font='medium', align='center', x=keyviewer_x, y=keyviewer_y, width=40, height=41,
	r=keyviewer_set.Color.r, g=keyviewer_set.Color.g, b=keyviewer_set.Color.b, a=40})

input_D = UI.Text.Create()
input_D:Set({text="D", font='medium', align='center', x=keyviewer_x+40, y=keyviewer_y, width=40, height=41,
	r=keyviewer_set.Color.r, g=keyviewer_set.Color.g, b=keyviewer_set.Color.b, a=40})

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------

Input_W = SyncValueCreate('input_W', VALUE.MaxPlayer)
Input_A = SyncValueCreate('input_A', VALUE.MaxPlayer)
Input_S = SyncValueCreate('input_S', VALUE.MaxPlayer)
Input_D = SyncValueCreate('input_D', VALUE.MaxPlayer)
Pause = SyncValueCreate('Pause', VALUE.MaxPlayer)

KZ.Player.input_W = {}
KZ.Player.input_A = {}
KZ.Player.input_S = {}
KZ.Player.input_D = {}
KZ.Player.pause = {}

for i = 1, VALUE.MaxPlayer do
	local w = Input_W[i]
	local a = Input_A[i]
	local s = Input_S[i]
	local d = Input_D[i]
	local pause = Pause[i]
	
	function w:OnSync()
		KZ.Player.input_W[i] = self.value
		KZ.Event:RefreshInputOverlay(i)
	end
	
	function a:OnSync()
		KZ.Player.input_A[i] = self.value
		KZ.Event:RefreshInputOverlay(i)
	end
	
	function s:OnSync()
		KZ.Player.input_S[i] = self.value
		KZ.Event:RefreshInputOverlay(i)
	end
	
	function d:OnSync()
		KZ.Player.input_D[i] = self.value
		KZ.Event:RefreshInputOverlay(i)
	end
	
	function pause:OnSync()
		KZ.Player.pause[i] = self.value
		KZ.Event:RefreshInputOverlay(i)
	end
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- UI.Event

KZ.TimeSignal = 0
KZ.Used_JetPack = 0
KZ.Used_Pause = 0

OnInputNumber = 0

function UI.Event:OnUpdate(time)
	Animation:UpdateTasks(time)
	UI.Signal(SIGNAL.ToGame.ONTIME)

	if Timer.startTime ~= 0 then
		if Timer.pause then
			Timer.pauseTime = Timer.pauseEnd + (UI.GetTime() - Timer.pauseStart)
		else
			Timer:Refresh()
			
			if KZ.TimeSignal <= UI.GetTime() then
				KZ.TimeSignal = UI.GetTime()+1
				UI.Signal(1000000000 + math.floor(Timer:GetTime()*100))
			end
		end
	end
	
	for _, text in ipairs(FadeText) do
		if text:IsVisible() then
			text:FadeControl()
		end
	end
end

function UI.Event:OnSignal(signal)
	if signal == SIGNAL.ToUI.TIMER_START then 		Timer:Start()
	elseif signal == SIGNAL.ToUI.TIMER_END then 	Timer:Reset(true)
	elseif signal == SIGNAL.ToUI.FINISH then 		Timer:Finish()
	elseif signal == SIGNAL.ToUI.DONTCP then 		FadeText.under:Fade(ReservedText.DontCP)
	elseif signal == SIGNAL.ToUI.DONTPS then 		FadeText.under:Fade(ReservedText.DontPS)
	elseif signal == SIGNAL.ToUI.DONTGC then 		FadeText.under:Fade(ReservedText.DontGC)
	elseif signal == SIGNAL.ToUI.PAUSE then 		Timer:Pause_On()
	elseif signal == SIGNAL.ToUI.PAUSE_OFF then 	Timer.pause = false
	elseif signal == SIGNAL.ToUI.SAVED then 		FadeText.under:Fade(ReservedText.Saved) UI.Signal(SIGNAL.ToGame.RESET)
	elseif signal == SIGNAL.ToUI.LOAD then 			FadeText.under:Fade(ReservedText.Loaded) saveMenu:Toggle()
	elseif signal == SIGNAL.ToUI.NOSAVE then 		FadeText.under:Fade(ReservedText.NoSave)
	elseif signal == SIGNAL.ToUI.INVAILD_POSITION then
		FadeText.under:Fade(ReservedText.InvaildPosition, true)
		Effect:ShowEffect(HUD.Effect.InvaildPositionColor)
		Effect:HideEffect(HUD.Effect.InvaildPositionColor, 0.3)
	elseif signal == SIGNAL.ToUI.PIXELWALK then UI.StopPlayerControl(true) UI.StopPlayerControl(false)
	end
end

function UI.Event:OnSpawn()
	KZ.Event:SetSpeedMeter(KZ.Index)
	if not DebugMode then
		Spec:OnOff(false)
	end
end

--------------------------------------------------------------------------------------------------
-- 뷰앵글 관련 함수
--------------------------------------------------------------------------------------------------
-- 시야각 저장
local agv_on = HUD.Menu.Elem.Color_view_angle_on
local agv_off = HUD.Menu.Elem.Color_view_angle_off

function KZ.Event:RecordViewAngle()
  UI.Signal(SIGNAL.ToGame.RECORD_VIEW_ANGLE)
end

function KZ.Event:ToggleViewAngleMode()
	if angleModeElem:Get().text == "OFF" then
		angleModeElem:Set({text="ON", r=agv_on.r, g=agv_on.g, b=agv_on.b, a=agv_on.a})
		ViewAngleMode = true
	else
		angleModeElem:Set({text="OFF", r=agv_off.r, g=agv_off.g, b=agv_off.b, a=agv_off.a})
		ViewAngleMode = false
	end
end

angleYaw = SyncValueCreate('angleYaw', VALUE.MaxPlayer)[KZ.Index]
function angleYaw:OnSync()
	-- print("save angle called")
	if self.value == nil then
		return
	end
	if type(self.value) == "number" then
		angleYawElem:Set({text=string.format("%.2f", self.value)})
	else
		angleYawElem:Set({text="N/A"})
	end
end

function KZ.Event:SetViewAngleYaw()
	UI.Signal(SIGNAL.ToGame.SAVE_VIEW_ANGLE)
end

function KZ.Event:SetTimerDesign()
	Timer:ChangeTimerMode(not NewTimerMode)
end

function KZ.Event:BuyWeapon()
	UI.Signal(SIGNAL.ToGame.BUY_WEAPON)
end

-- 무기 모드 전환
function KZ.Event:SetWeaponMode()
	if Timer.isrunning then
		return
	end
	weaponModeElem:Set({text=KZ.WeaponMode[KZ.WeaponModeIndex]})
	UI.Signal(SIGNAL.ToGame.SET_WEAPON_MODE)
end

SyncWeaponModeIndex = SyncValueCreate(string.format('weaponModeIndex%d',KZ.Index))
function SyncWeaponModeIndex:OnSync()
	KZ.WeaponModeIndex = self.value
	weaponModeElem:Set({text=KZ.WeaponMode[KZ.WeaponModeIndex]})
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------


function UI.Event:OnKeyDown(inputs)
	-- 가상커맨드 입력 중 다른 키 사용 불가, 이동 불가
	-- 바인드 키 설정 중 다른 키 사용 불가
	-- 고정키 : V, M, NUM1 ~ NUM0, 설정된 바인드 키

	if inputs[UI.KEY.B] then
		KZ.Event:BuyWeapon()
	end
	
	if (CommandKeySHIFT and inputs[UI.KEY.C]) or vcommandInsert then
		if vcommandInsert == false then
			UI.StopPlayerControl(true)
			vcommand = '/'
			vcommandInsert = true
			SetCommandInput('명령어를 입력해주세요.')
			
			return
		elseif inputs[UI.KEY.ENTER] then
			KZ.Event:OnCommand(string.lower(vcommand))
			
			vcommand = ''
			vcommandInsert = false
			SetCommandInput(vcommand)
			UI.StopPlayerControl(false)
		end
		
		vcommand = vcommand .. InputToChar(listFind(inputs))
		SetCommandInput(vcommand)
		
		return
	elseif Bind.PressKey:IsVisible() then
		KZ.Event:BindSet(Bind:KeyCheck(inputs))
	else
		Bind:OnInput(inputs)
		if inputs[UI.KEY.V] then
			if rankingMenu and rankingMenu.IsVisible and rankingMenu:IsVisible() then
				KZ.Event:HideQRCode()
			end
			defaultMenu:Toggle()
		elseif (inputs[UI.KEY.M] and Spec.value) then specMenu:Toggle()
		elseif inputs[UI.KEY.NUM0] then
			Menu:Showing():Action(0)
			Menu:Toggle()
		elseif inputs[UI.KEY.NUM1] then	OnInputNumber = 1	Menu:Showing():Action(1)
		elseif inputs[UI.KEY.NUM2] then	OnInputNumber = 2	Menu:Showing():Action(2)
		elseif inputs[UI.KEY.NUM3] then	OnInputNumber = 3	Menu:Showing():Action(3)
		elseif inputs[UI.KEY.NUM4] then	OnInputNumber = 4	Menu:Showing():Action(4)
		elseif inputs[UI.KEY.NUM5] then OnInputNumber = 5	Menu:Showing():Action(5)
		elseif inputs[UI.KEY.NUM6] then	OnInputNumber = 6	Menu:Showing():Action(6)
		elseif inputs[UI.KEY.NUM7] then	OnInputNumber = 7	Menu:Showing():Action(7)
		elseif inputs[UI.KEY.NUM8] then	OnInputNumber = 8	Menu:Showing():Action(8)
		elseif inputs[UI.KEY.NUM9] then OnInputNumber = 9	Menu:Showing():Action(9)
		end
	end
	
	if inputs[UI.KEY.W] then
		UI.Signal(SIGNAL.ToGame.KEYDOWN_W)
		input_W:Set({a=255})
	end
	if inputs[UI.KEY.A] then
		UI.Signal(SIGNAL.ToGame.KEYDOWN_A)
		input_A:Set({a=255})
	end
	if inputs[UI.KEY.S] then
		UI.Signal(SIGNAL.ToGame.KEYDOWN_S)
		input_S:Set({a=255})
	end
	if inputs[UI.KEY.D] then
		UI.Signal(SIGNAL.ToGame.KEYDOWN_D)
		input_D:Set({a=255})
	end
	
	if MoveKeyViewer and inputs[UI.KEY.ENTER] then
		-- 키뷰어 이동 종료
		MoveKeyViewer = false
		UI.StopPlayerControl(false)
		PressArrowKeys:Hide()
	end
end

function UI.Event:OnKeyUp(inputs)
	if inputs[UI.KEY.W] then
		UI.Signal(SIGNAL.ToGame.KEYUP_W)
		input_W:Set({a=40})
	end
	if inputs[UI.KEY.A] then
		UI.Signal(SIGNAL.ToGame.KEYUP_A)
		input_A:Set({a=40})
	end
	if inputs[UI.KEY.S] then
		UI.Signal(SIGNAL.ToGame.KEYUP_S)
		input_S:Set({a=40})
	end
	if inputs[UI.KEY.D] then
		UI.Signal(SIGNAL.ToGame.KEYUP_D)
		input_D:Set({a=40})
	end
end

function UI.Event:OnChat(msg)
	KZ.Event:OnCommand(string.lower(msg))
end

function UI.Event:OnInput(inputs)
	if MoveKeyViewer then
		if inputs[UI.KEY.UP] then
			KZ.Event:MoveUpDownKeyViewer(-2)
		elseif inputs[UI.KEY.DOWN] then
			KZ.Event:MoveUpDownKeyViewer(2)
		elseif inputs[UI.KEY.LEFT] then
			KZ.Event:MoveSideKeyViewer(-2)
		elseif inputs[UI.KEY.RIGHT] then
			KZ.Event:MoveSideKeyViewer(2)
		end
	end
	
	if inputs[UI.KEY.A] and inputs[UI.KEY.D] then
		KZ.Event:SetKeyViewer(UI.Text.Set, {r=keyviewer_set.Color_bad.r, g=keyviewer_set.Color_bad.g, b=keyviewer_set.Color_bad.b})
	else
		KZ.Event:SetKeyViewer(UI.Text.Set, {r=keyviewer_set.Color.r, g=keyviewer_set.Color.g, b=keyviewer_set.Color.b})
	end
	
	if inputs[UI.KEY.SPACE] then
		KZ.Event:UseJetPack()
	end
	
	CommandKeySHIFT = inputs[UI.KEY.SHIFT]
end

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 랭킹 메뉴

Records = Records or {}
rankFromData = SyncValueCreate('rankFromData')

function rankFromData:OnSync()
	-- 랭킹 텍스트는 사용하지 않고 QR만 노출
	KZ.Event:RankingUpdate()
end

function KZ.Event:RankingUpdate()
	if not rankingMenu then
		return
	end

	rankingMenu:PageSetup({}, 1)
	rankingMenu:PageSetup({}, 2)
	rankingMenu:PageSetup({}, 3)
end

local ranking_set = HUD.Ranking

local rankingTitleSet = {text=ranking_set.Title.Text, font="small", align="left", x=30, y=center.y-80, width=screen.width, height=20,
	r=ranking_set.Title.Color.r, g=ranking_set.Title.Color.g, b=ranking_set.Title.Color.b, a=ranking_set.Title.Color.a}
local rankingElemSet_1 = {font="small",align="left", x=30, y=center.y-55, width=screen.width, height=20,
	r=ranking_set.Elem.Color_rank.r, g=ranking_set.Elem.Color_rank.g, b=ranking_set.Elem.Color_rank.b, a=ranking_set.Elem.Color_rank.a}
local rankingElemSet_2 = {font="small",align="left", x=60, y=center.y-55, width=screen.width, height=20,
	r=ranking_set.Elem.Color_record.r, g=ranking_set.Elem.Color_record.g, b=ranking_set.Elem.Color_record.b, a=ranking_set.Elem.Color_record.a}
local rankingElemSet_3 = {font="small",align="left", x=133, y=center.y-55, width=screen.width, height=20,
	r=ranking_set.Elem.Color_player.r, g=ranking_set.Elem.Color_player.g, b=ranking_set.Elem.Color_player.b, a=ranking_set.Elem.Color_player.a}

rankingMenu = Menu:new(rankingTitleSet, {rankingElemSet_1, rankingElemSet_2, rankingElemSet_3}, 10)
KZ.Event:RankingUpdate()

-- rankingMenu.elem[1][8]:Set({text=" 8."})	rankingMenu.elem[2][8]:Set({text="Bacｋ"})
-- rankingMenu.elem[1][9]:Set({text=" 9."})	rankingMenu.elem[2][9]:Set({text="More"})
rankingMenu.elem[1][10]:Set({text=" 0."})	rankingMenu.elem[2][10]:Set({text="Exit"})

rankingMenu:Visible(false)

function KZ.Event:All()
	if rankingMenu:IsVisible() then
		KZ.Event:HideQRCode()
	else
		local baseURL = tostring(KZ_BASE_URL or "")
		baseURL = string.gsub(baseURL, "/+$", "")
		local mapIndex = tostring(KZ_MAP_INDEX or 0)
		local url = string.format("%s/registered-map/%s", baseURL, mapIndex)
		KZ.Event:CreateQRCodeByBox(url, {
			show_info = false,
			show_logo = true,
			anchor = "ranking_record",
			qr_context = "all_menu",
		})
	end

	rankingMenu:Toggle()
end

-- rankingMenu:ActionSetup(8, rankingMenu.PageDown)
-- rankingMenu:ActionSetup(9, rankingMenu.PageUp)

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 바인드 메뉴

Bind = {}

bindMenu = Menu:new(menuTitleSet, {menuNumberSet, menuElemSet}, 10)

bindMenu.title:Set({text=title_set.BindMenu})
bindMenu.elem[1][1]:Set({text="1. "})
bindMenu.elem[1][2]:Set({text="2. "})
bindMenu.elem[1][3]:Set({text="3. "})
bindMenu.elem[1][4]:Set({text="4. "})
bindMenu.elem[1][5]:Set({text="5. "})
bindMenu.elem[1][6]:Set({text="6. "})
bindMenu.elem[1][7]:Set({text="7. "})
bindMenu.elem[1][8]:Set({text="8. "})	bindMenu.elem[2][8]:Set({text="Bacｋ"})
bindMenu.elem[1][9]:Set({text="9. "})	bindMenu.elem[2][9]:Set({text="More"})
bindMenu.elem[1][10]:Set({text="0. "})	bindMenu.elem[2][10]:Set({text="Exit"})

bindMenu:PageSetup(HUD.Bind, 2)

Bind.Hotkey = {}

bindMenu:Visible(false)

Bind.PressKey = UI.Text.Create()
Bind.PressKey:Set({text=ReservedText.PressBindKey, font='medium', align="center", y=screen.height/4*3, width=screen.width, height=120, r=222,g=222,b=222,a=222})
Bind.PressKey:Hide()

CanNotBeHotKey = {
	-- 사용할 수 없는 키 리스트
	UI.KEY.W,
	UI.KEY.A,
	UI.KEY.S,
	UI.KEY.D,
	UI.KEY.V,
	UI.KEY.M,
	UI.KEY.NUM1,
	UI.KEY.NUM2,
	UI.KEY.NUM4,
	UI.KEY.NUM5,
	UI.KEY.NUM6,
	UI.KEY.NUM7,
	UI.KEY.NUM8,
	UI.KEY.NUM0,
	UI.KEY.ENTER,
	UI.KEY.SPACE,
}

Bind.Hotkey = {}

function KZ.Event:Bind()
	bindMenu:Toggle()
end

function KZ.Event:OnBind()
	Bind.index = OnInputNumber + (bindMenu.page*7)
	Bind.PressKey:Show()
	bindMenu:Toggle()
end

function KZ.Event:BindSet(key, command)
	if command then
		Bind.Hotkey[key] = command
		Bind.PressKey:Hide()
		FadeText.under:Fade(ReservedText.BindSuccess)
	end
end

function KZ.Event:UnBind()
	Bind.Hotkey = {}
	FadeText.under:Fade(ReservedText.UnBinded)
end

function Bind:OnInput(inputs)
	for key, command in pairs(self.Hotkey) do
		if inputs[key] then
			KZ.Event:OnCommand(command)
			return
		end
	end
end

function Bind:KeyCheck(inputs)
	local key = listFind(inputs)
	
	for _, v in pairs(CanNotBeHotKey) do
		if key == v then
			return false
		end
	end
	
	return key, HUD.Bind[Bind.index]
end

for i = 1, math.min(#HUD.Bind, 7) do
	bindMenu:ActionSetup(i, KZ.Event.OnBind)
end

bindMenu:ActionSetup(8, bindMenu.PageDown)
bindMenu:ActionSetup(9, bindMenu.PageUp)

KZ.Bind = Bind

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 세이브 메뉴

saveMenu = Menu:new(menuTitleSet, {menuNumberSet, menuElemSet}, 4)

saveMenu.title:Set({text=title_set.SaveMenu})
saveMenu.elem[1][1]:Set({text="1. "})	saveMenu.elem[2][1]:Set({text="저장하기"})
saveMenu.elem[1][2]:Set({text="2. "})	saveMenu.elem[2][2]:Set({text="불러오기"})
saveMenu.elem[1][4]:Set({text="0. "})	saveMenu.elem[2][4]:Set({text="Exit"})

saveMenu:Visible(false)

loadData = SyncValueCreate('loadData')

function loadData:OnSync()
	if self.value == nil then
		return
	end
	
	local args = splitstr(self.value, ",")
	local index = tonumber(args[1])
	local Time = tonumber(args[2])
	
	if index == UI.PlayerIndex() then
		Timer:Reset()
		Timer.startTime = UI.GetTime() - Time/100
		Timer:Refresh()
		Timer:Pause_On()
	end
end

function KZ.Event:Save()
	if MAP.CanCP then
		saveMenu:Toggle()
	end
end

function KZ.Event:OnSave()
	if Timer.startTime == 0 then
		FadeText.under:Fade(ReservedText.DidNotStart)
	else
		local time = Timer:GetTime()
		UI.Signal(2000000000 + math.floor(time*100))
		if Timer.pause then
			Timer:Pause_Off(true) -- 퍼즈중에 세이브하면 퍼즈는 풀고 퍼즈포지션 텔포는 X
		end
	end
	
	defaultMenu:Toggle()
end

function KZ.Event:OnLoad()
	UI.Signal(SIGNAL.ToGame.LOAD)
	defaultMenu:Toggle()
end

saveMenu:ActionSetup(1, KZ.Event.OnSave)
saveMenu:ActionSetup(2, KZ.Event.OnLoad)

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 키뷰어 메뉴

overlayMenu = Menu:new(menuTitleSet, {menuNumberSet, menuElemSet}, 6)

overlayMenu.title:Set({text=title_set.OverlayMenu})
overlayMenu.elem[1][1]:Set({text="1. "})	overlayMenu.elem[2][1]:Set({text="보이기"})
overlayMenu.elem[1][2]:Set({text="2. "})	overlayMenu.elem[2][2]:Set({text="숨기기"})
overlayMenu.elem[1][3]:Set({text="3. "})	overlayMenu.elem[2][3]:Set({text="이동"})
overlayMenu.elem[1][4]:Set({text="4. "})	overlayMenu.elem[2][4]:Set({text="초기화"})
overlayMenu.elem[1][6]:Set({text="0. "})	overlayMenu.elem[2][6]:Set({text="Exit"})

overlayMenu:Visible(false)

PressArrowKeys = UI.Text.Create()
PressArrowKeys:Set({text=ReservedText.PressArrowKeys, font='medium', align="center", y=screen.height/4*3, width=screen.width, height=120, r=222,g=222,b=222,a=222})
PressArrowKeys:Hide()

function KZ.Event:KeyViewer()
	overlayMenu:Toggle()
end

function KZ.Event:SetKeyViewer(action, args)
	action(input_W, args)
	action(input_A, args)
	action(input_S, args)
	action(input_D, args)
end

function KZ.Event:HideKeyViewer()
	KZ.Event:SetKeyViewer(UI.Text.Hide)
	FadeText.under:Fade(ReservedText.HideKeyViewer)
	overlayMenu:Toggle()
end

function KZ.Event:ShowKeyViewer()
	KZ.Event:SetKeyViewer(UI.Text.Show)
	FadeText.under:Fade(ReservedText.ShowKeyViewer)
	overlayMenu:Toggle()
end

function KZ.Event:MoveKeyViewer()
	MoveKeyViewer = true
	UI.StopPlayerControl(true)
	PressArrowKeys:Show()
	overlayMenu:Toggle()
end

function KZ.Event:ResetKeyViewer()
	input_W:Set({x=keyviewer_x, y=keyviewer_y-40})
	input_A:Set({x=keyviewer_x-40, y=keyviewer_y})
	input_S:Set({x=keyviewer_x, y=keyviewer_y})
	input_D:Set({x=keyviewer_x+40, y=keyviewer_y})
	FadeText.under:Fade(ReservedText.ResetKeyViewer)
	overlayMenu:Toggle()
end

function KZ.Event:MoveSideKeyViewer(space)
	input_W:Set({x=input_W:Get().x+space})
	input_A:Set({x=input_A:Get().x+space})
	input_S:Set({x=input_S:Get().x+space})
	input_D:Set({x=input_D:Get().x+space})
end

function KZ.Event:MoveUpDownKeyViewer(space)
	input_W:Set({y=input_W:Get().y+space})
	input_A:Set({y=input_A:Get().y+space})
	input_S:Set({y=input_S:Get().y+space})
	input_D:Set({y=input_D:Get().y+space})
end

overlayMenu:ActionSetup(1, KZ.Event.ShowKeyViewer)
overlayMenu:ActionSetup(2, KZ.Event.HideKeyViewer)
overlayMenu:ActionSetup(3, KZ.Event.MoveKeyViewer)
overlayMenu:ActionSetup(4, KZ.Event.ResetKeyViewer)

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 스타트포지션 메뉴

startMenu = Menu:new(menuTitleSet, {menuNumberSet, menuElemSet}, 4)

startMenu.title:Set({text=title_set.StartPosMenu})
startMenu.elem[1][1]:Set({text="1. "})	startMenu.elem[2][1]:Set({text="설정된 위치"})
startMenu.elem[1][2]:Set({text="2. "})	startMenu.elem[2][2]:Set({text="버튼을 누른 위치"})
startMenu.elem[1][4]:Set({text="0. "})	startMenu.elem[2][4]:Set({text="Exit"})

startMenu:Visible(false)

function KZ.Event:SetStartPosition()
	startMenu:Toggle()
end

function KZ.Event:DefinedPosition()
	-- 설정된 좌표로 이동
	UndefinedPosition = false
	FadeText.under:Fade(ReservedText.SetStartPosition)
	startMenu:Toggle()
end

function KZ.Event:UndefinedPosition()
	-- 마지막에 버튼을 누른 좌표로 이동
	UndefinedPosition = true
	FadeText.under:Fade(ReservedText.SetStartPosition)
	startMenu:Toggle()
end

startMenu:ActionSetup(1, KZ.Event.DefinedPosition)
startMenu:ActionSetup(2, KZ.Event.UndefinedPosition)

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 세팅 메뉴

local menuCountSet = {font="small", align="left", y=center.y-87, width=screen.width, height=15}
settingMenu = Menu:new(menuTitleSet, {menuNumberSet, menuElemSet, menuCountSet}, 8)

settingMenu.title:Set({text=title_set.SettingMenu})
settingMenu.elem[1][1]:Set({text="1. "})	settingMenu.elem[2][1]:Set({text=title_set.BindMenu})
settingMenu.elem[1][2]:Set({text="2. "})	settingMenu.elem[2][2]:Set({text=title_set.OverlayMenu})
settingMenu.elem[1][3]:Set({text="3. "})	settingMenu.elem[2][3]:Set({text=title_set.StartPosMenu})
settingMenu.elem[1][4]:Set({text="4. "})	settingMenu.elem[2][4]:Set({text=title_set.ViewAngleCPMode})
settingMenu.elem[1][5]:Set({text="5. "})	settingMenu.elem[2][5]:Set({text=title_set.ToggleViewAngleCheckPoint})
settingMenu.elem[1][6]:Set({text="6. "})	settingMenu.elem[2][6]:Set({text=title_set.TimerDesign})
settingMenu.elem[1][7]:Set({text="7. "})	settingMenu.elem[2][7]:Set({text=title_set.WeaponMode})

settingMenu.elem[1][8]:Set({text="0. "})	settingMenu.elem[2][8]:Set({text="Exit"})

settingMenu:Visible(false)

function KZ.Event:Setting()
	settingMenu:Toggle()
end


ViewAngleMode = false
angleModeElem = settingMenu.elem[3][4]
angleYawElem = settingMenu.elem[3][5]
digitalTimerElem = settingMenu.elem[3][6]
weaponModeElem = settingMenu.elem[3][7]


local elem_set = HUD.Menu.Elem

angleModeElem:Set({x=230, r=elem_set.Color_count.r, g=elem_set.Color_count.g, b=elem_set.Color_count.b, a=elem_set.Color_count.a})
angleModeElem:Set({text="OFF"})
angleYawElem:Set({x=230, r=elem_set.Color_count.r, g=elem_set.Color_count.g, b=elem_set.Color_count.b, a=elem_set.Color_count.a})
angleYawElem:Set({text="0.00"})
digitalTimerElem:Set({x=160, r=elem_set.Color_count.r, g=elem_set.Color_count.g, b=elem_set.Color_count.b, a=elem_set.Color_count.a})
digitalTimerElem:Set({text="Digital"})
weaponModeElem:Set({x=180, r=elem_set.Color_count.r, g=elem_set.Color_count.g, b=elem_set.Color_count.b, a=elem_set.Color_count.a})
weaponModeElem:Set({text="USP45"})





settingMenu:ActionSetup(1, KZ.Event.Bind)
settingMenu:ActionSetup(2, KZ.Event.KeyViewer)
settingMenu:ActionSetup(3, KZ.Event.SetStartPosition)
settingMenu:ActionSetup(4, KZ.Event.ToggleViewAngleMode)
settingMenu:ActionSetup(5, KZ.Event.SetViewAngleYaw)
settingMenu:ActionSetup(6, KZ.Event.SetTimerDesign)
settingMenu:ActionSetup(7, KZ.Event.SetWeaponMode)


--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 완주 시 활성화 메뉴

local QR_MAX_VERSION = 40
local QR_MODULE_SIZE = 4
local QR_QUIET_ZONE = 4
local QR_MAX_BOX_COUNT = 600
local QR_MARGIN_X = 20
local QR_MARGIN_Y = 20
local LOGO_MAX_BOX_COUNT = 500
local LOGO_PADDING_PX = 5
local QR_BOX_BUDGET = 800 -- QR + 로고 합산 박스 예산 고정

local LOGO_CANVAS_W = 47
local LOGO_CANVAS_H = 87
local LOGO_COLORS = {
	[1] = {r = 14, g = 14, b = 14, a = 216},
	[2] = {r = 28, g = 28, b = 28, a = 239},
}
local LOGO_RECTS = {}
local LOGO_DATA_LOADED = false

local function getBaseURL()
	local baseURL = tostring(KZ_BASE_URL or "")
	return string.gsub(baseURL, "/+$", "")
end

local function precreateBoxPool(targetCount)
	local boxes = {}
	local created = 0
	local safeTarget = math.max(0, math.floor(targetCount or 0))

	for i = 1, safeTarget do
		local box = UI.Box.Create()
		if not box then
			break
		end
		if box.Hide then
			box:Hide()
		end
		boxes[i] = box
		created = i
	end

	return boxes, created
end

local function expandBoxPool(boxes, targetCount)
	local created = #boxes
	local safeTarget = math.max(0, math.floor(targetCount or 0))
	for i = created + 1, safeTarget do
		local box = UI.Box.Create()
		if not box then
			break
		end
		if box.Hide then
			box:Hide()
		end
		boxes[i] = box
		created = i
	end
	return boxes, created
end

local function initQRPools(QRTest)
	local totalBudget = math.max(64, QR_BOX_BUDGET)
	local currentCap = tonumber(QRTest.pool_capacity) or 0
	local existingBoxes = nil

	if type(QRTest.renderState) == "table" and type(QRTest.renderState.boxes) == "table" then
		existingBoxes = QRTest.renderState.boxes
	elseif type(QRTest.logoState) == "table" and type(QRTest.logoState.boxes) == "table" then
		existingBoxes = QRTest.logoState.boxes
	end

	if QRTest.pool_initialized and currentCap >= totalBudget and type(existingBoxes) == "table" and #existingBoxes > 0 then
		return
	end

	local sharedBoxes, sharedCap
	if type(existingBoxes) == "table" and #existingBoxes > 0 then
		sharedBoxes, sharedCap = expandBoxPool(existingBoxes, totalBudget)
	else
		sharedBoxes, sharedCap = precreateBoxPool(totalBudget)
	end

	QRTest.renderState = {boxes = sharedBoxes, active_count = 0}
	QRTest.logoState = {boxes = sharedBoxes, active_count = 0, start_index = 1}
	QRTest.pool_capacity = sharedCap
	QRTest.render_capacity = sharedCap
	QRTest.logo_capacity = sharedCap
	QRTest.pool_initialized = true
end

local function getQRState()
	Timer.QRTest = Timer.QRTest or {
		renderState = {boxes = {}},
		logoState = {boxes = {}, active_count = 0},
		statusText = nil,
		infoText = nil,
		qrObject = {origin_x = 0, origin_y = 0, pixel_size = 0},
	}
	Timer.QRTest.qrObject = Timer.QRTest.qrObject or {origin_x = 0, origin_y = 0, pixel_size = 0}
	Timer.QRTest.pool_initialized = Timer.QRTest.pool_initialized or false
	initQRPools(Timer.QRTest)
	return Timer.QRTest
end

local function setQRObjectPosition(QRTest, originX, originY, qrPixelSize)
	local obj = QRTest.qrObject or {origin_x = 0, origin_y = 0, pixel_size = 0}
	obj.origin_x = originX
	obj.origin_y = originY
	obj.pixel_size = qrPixelSize
	QRTest.qrObject = obj
	return obj
end

local function ensureLogoData()
	if LOGO_DATA_LOADED then
		return
	end

	local data = nil
	if type(CSO_BOX_DATA) == "table" then
		data = CSO_BOX_DATA
	elseif type(dofile) == "function" then
		local ok, loaded = pcall(dofile, "logo.lua")
		if ok and type(loaded) == "table" then
			data = loaded
		end
		if type(data) ~= "table" and type(CSO_BOX_DATA) == "table" then
			data = CSO_BOX_DATA
		end
		if type(data) ~= "table" then
			local okLegacy, legacyLoaded = pcall(dofile, "generated_cso_boxes.lua")
			if okLegacy and type(legacyLoaded) == "table" then
				data = legacyLoaded
			end
			if type(data) ~= "table" and type(CSO_BOX_DATA) == "table" then
				data = CSO_BOX_DATA
			end
		end
	end

	if type(data) ~= "table" then
		return
	end
	if type(data.canvas_w) == "number" and data.canvas_w > 0 then
		LOGO_CANVAS_W = data.canvas_w
	end
	if type(data.canvas_h) == "number" and data.canvas_h > 0 then
		LOGO_CANVAS_H = data.canvas_h
	end
	if type(data.colors) == "table" then
		LOGO_COLORS = data.colors
	end
	if type(data.rects) == "table" then
		LOGO_RECTS = data.rects
	end
	if #LOGO_RECTS > 0 then
		LOGO_DATA_LOADED = true
	end
end

local function getQrOrigin(matrix, options)
	local matrixSize = #matrix
	local totalModules = matrixSize + (QR_QUIET_ZONE * 2)
	local qrPixelSize = totalModules * QR_MODULE_SIZE
	local originX = screen.width - qrPixelSize - QR_MARGIN_X
	local originY = QR_MARGIN_Y

	if type(options) == "table" and options.anchor == "ranking_record" then
		-- 기존 랭킹 기록 줄이 표시되던 위치
		originX = 60
		originY = center.y - 55
	end

	originX = math.max(0, math.min(screen.width - qrPixelSize, originX))
	originY = math.max(0, math.min(screen.height - qrPixelSize, originY))
	return originX, originY, qrPixelSize
end

local function ensureStatusText(QRTest)
	if QRTest.statusText == nil then
		QRTest.statusText = UI.Text.Create()
		QRTest.statusText:Set({
			font = "small",
			align = "left",
			x = 20,
			y = screen.height - 20,
			width = screen.width - 40,
			height = 20,
			r = 220,
			g = 220,
			b = 220,
			a = 255,
		})
	end
	return QRTest.statusText
end

local function ensureInfoText(QRTest)
	if type(QRTest.infoText) ~= "table" then
		QRTest.infoText = {}
	end
	if QRTest.infoText.nick == nil then
		QRTest.infoText.nick = UI.Text.Create()
	end
	if QRTest.infoText.record == nil then
		QRTest.infoText.record = UI.Text.Create()
	end
	if QRTest.infoText.count == nil then
		QRTest.infoText.count = UI.Text.Create()
	end
	return QRTest.infoText
end

local function carveLogoHole(matrix)
	local size = #matrix
	local holeW = math.max(7, math.floor(size * 0.30))
	local holeH = math.max(9, math.floor(size * 0.42))
	holeW = math.min(holeW, size - 10)
	holeH = math.min(holeH, size - 10)

	-- QR 좌하단 파인더(7x7) 바로 위에 홀 배치
	local finderSize = 7
	local finderY1 = size - finderSize + 1
	local safeTop = finderSize + 2

	local x1 = 1
	local x2 = math.min(size, x1 + holeW - 1)
	local y2 = finderY1 - 1
	local y1 = y2 - holeH + 1

	if y1 < safeTop then
		y1 = safeTop
		y2 = y1 + holeH - 1
		if y2 >= finderY1 then
			y2 = finderY1 - 1
			y1 = math.max(safeTop, y2 - holeH + 1)
		end
	end

	for x = x1, x2 do
		for y = y1, y2 do
			matrix[x][y] = 0
		end
	end

	return {x = x1, y = y1, w = x2 - x1 + 1, h = y2 - y1 + 1}
end

local function drawLogo(QRTest, originX, originY, hole, maxLogoBoxes)
	if not hole or #LOGO_RECTS == 0 then
		return 0
	end

	local holeX = originX + (QR_QUIET_ZONE + hole.x - 1) * QR_MODULE_SIZE
	local holeY = originY + (QR_QUIET_ZONE + hole.y - 1) * QR_MODULE_SIZE
	local holeW = hole.w * QR_MODULE_SIZE
	local holeH = hole.h * QR_MODULE_SIZE
	local usableW = math.max(1, holeW - (LOGO_PADDING_PX * 2))
	local usableH = math.max(1, holeH - (LOGO_PADDING_PX * 2))
	local contentX = holeX + LOGO_PADDING_PX
	local contentY = holeY + LOGO_PADDING_PX

	local scale = math.min(usableW / LOGO_CANVAS_W, usableH / LOGO_CANVAS_H)
	if scale <= 0 then
		return 0
	end

	local spriteW = math.max(1, math.floor(LOGO_CANVAS_W * scale))
	local spriteH = math.max(1, math.floor(LOGO_CANVAS_H * scale))
	local spriteX = contentX + math.floor((usableW - spriteW) / 2)
	local spriteY = contentY + math.floor((usableH - spriteH) / 2)

	local drawableRects = #LOGO_RECTS
	if type(maxLogoBoxes) == "number" then
		drawableRects = math.min(drawableRects, math.max(0, math.floor(maxLogoBoxes)))
	end
	if drawableRects <= 0 then
		return 0
	end

	local logoState = QRTest.logoState or {boxes = {}, active_count = 0, start_index = 1}
	local boxes = logoState.boxes or {}
	local renderUsed = 0
	if type(QRTest.renderState) == "table" and type(QRTest.renderState.active_count) == "number" then
		renderUsed = math.max(0, QRTest.renderState.active_count)
	end
	local poolCap = tonumber(QRTest.pool_capacity) or #boxes
	local start = renderUsed + 1
	local availableCount = math.max(0, poolCap - renderUsed)
	if drawableRects > availableCount then
		drawableRects = availableCount
	end
	if drawableRects <= 0 then
		return 0
	end

	local prevStart = logoState.start_index or 1
	local prevActive = logoState.active_count or 0
	for i = 0, prevActive - 1 do
		local box = boxes[prevStart + i]
		if box and box.Hide then
			box:Hide()
		end
	end

	local used = 0
	local function mapX(px)
		return spriteX + math.floor((px * spriteW) / LOGO_CANVAS_W)
	end
	local function mapY(py)
		return spriteY + math.floor((py * spriteH) / LOGO_CANVAS_H)
	end

	for i = 1, drawableRects do
		local rect = LOGO_RECTS[i]
		local color = LOGO_COLORS[rect.c] or LOGO_COLORS[1]
		local rx0 = mapX(rect.x)
		local ry0 = mapY(rect.y)
		local rx1 = mapX(rect.x + rect.w)
		local ry1 = mapY(rect.y + rect.h)
		local rx = rx0
		local ry = ry0
		local rw = math.max(1, rx1 - rx0)
		local rh = math.max(1, ry1 - ry0)

		if rx < holeX then
			rw = rw - (holeX - rx)
			rx = holeX
		end
		if ry < holeY then
			rh = rh - (holeY - ry)
			ry = holeY
		end
		if rx + rw > holeX + holeW then
			rw = (holeX + holeW) - rx
		end
		if ry + rh > holeY + holeH then
			rh = (holeY + holeH) - ry
		end

		if rw > 0 and rh > 0 then
			used = used + 1
			local slot = start + used - 1
			local box = boxes[slot]
			if not box then
				break
			end
			box:Set({
				x = rx,
				y = ry,
				width = rw,
				height = rh,
				r = color.r,
				g = color.g,
				b = color.b,
				a = color.a,
			})
			box:Show()
		end
	end

	for i = used, prevActive - 1 do
		local box = boxes[start + i]
		if box and box.Hide then
			box:Hide()
		end
	end

	logoState.start_index = start
	logoState.active_count = used
	QRTest.logoState = logoState
	return used
end

function KZ.Event:HideQRCode()
	local QRTest = Timer.QRTest
	if type(QRTest) ~= "table" then
		return
	end

	local renderState = QRTest.renderState
	if type(renderState) == "table" then
		if type(qrcode_destroy_boxes) == "function" then
			qrcode_destroy_boxes(renderState)
		else
			local boxes = renderState.boxes
			if type(boxes) == "table" then
				for i = 1, #boxes do
					local box = boxes[i]
					if box and box.Hide then
						box:Hide()
					end
				end
			end
			renderState.active_count = 0
		end
	end

	local logoState = QRTest.logoState
	if type(logoState) == "table" then
		local boxes = logoState.boxes
		if type(boxes) == "table" then
			local active = logoState.active_count or #boxes
			local start = logoState.start_index or 1
			for i = 0, active - 1 do
				local box = boxes[start + i]
				if box and box.Hide then
					box:Hide()
				end
			end
		end
		logoState.start_index = 1
		logoState.active_count = 0
	end

	if QRTest.statusText and QRTest.statusText.Hide then
		QRTest.statusText:Hide()
	end

	local infoText = QRTest.infoText
	if type(infoText) == "table" then
		for _, text in pairs(infoText) do
			if text and text.Hide then
				text:Hide()
			end
		end
	end

	QRTest.qr_context = nil
end

function KZ.Event:HideSubmitQR()
	-- 객체 풀은 유지하고 숨김만 수행
	KZ.Event:HideQRCode()
end

function KZ.Event:HideAllMenuQR()
	local QRTest = Timer.QRTest
	if type(QRTest) ~= "table" then
		return
	end
	if QRTest.qr_context == "all_menu" then
		KZ.Event:HideQRCode()
	end
end

function KZ.Event:IsQRCodeVisible(context)
	local QRTest = Timer.QRTest
	if type(QRTest) ~= "table" then
		return false
	end
	if context and QRTest.qr_context ~= context then
		return false
	end

	local renderState = QRTest.renderState
	if type(renderState) == "table" and type(renderState.active_count) == "number" and renderState.active_count > 0 then
		return true
	end

	local logoState = QRTest.logoState
	if type(logoState) == "table" and type(logoState.active_count) == "number" and logoState.active_count > 0 then
		return true
	end

	return false
end

function KZ.Event:CreateQRCodeByBox(input, options)
	local value = tostring(input or "")
	if value == "" then
		return false
	end

	local QRTest = getQRState()
	KZ.Event:HideQRCode()
	ensureLogoData()
	local function setStatus(text, r, g, b)
		local statusText = ensureStatusText(QRTest)
		statusText:Set({
			y = screen.height + 20,
			text = text,
			r = r or 220,
			g = g or 220,
			b = b or 220,
			a = 255,
		})
		statusText:Show()
	end

	local ok, matrix = qrcode(value, 2)
	if not ok then
		setStatus("QR generation failed", 255, 120, 120)
		return false
	end

	local version = qrcode_get_version(matrix)
	if not version then
		setStatus("QR matrix invalid", 255, 120, 120)
		return false
	end

	local showLogo = not (type(options) == "table" and options.show_logo == false)
	local qrContext = type(options) == "table" and options.qr_context or "generic"
	local useLogo = showLogo and (#LOGO_RECTS > 0)
	local fullLogoCount = math.min(LOGO_MAX_BOX_COUNT, #LOGO_RECTS)
	local logoHole = nil
	if useLogo then
		logoHole = carveLogoHole(matrix)
	end

	local function drawMatrix(targetMatrix, reserveLogoBoxes)
		local originX, originY, qrPixelSize = getQrOrigin(targetMatrix, options)
		local qrPoolCap = tonumber(QRTest.render_capacity) or #(QRTest.renderState and QRTest.renderState.boxes or {})
		if qrPoolCap <= 0 then
			return false, "QR box pool is empty", originX, originY, qrPixelSize
		end
		local reserve = math.max(0, math.floor(reserveLogoBoxes or 0))
		local qrUsableCap = qrPoolCap - reserve
		if qrUsableCap <= 0 then
			return false, "QR box pool reserved for logo", originX, originY, qrPixelSize
		end
		local qrMaxBoxes = math.max(1, math.min(QR_MAX_BOX_COUNT, qrUsableCap))
		setQRObjectPosition(QRTest, originX, originY, qrPixelSize)
		local okDraw, info = qrcode_create_boxes(QRTest.renderState, targetMatrix, {
			origin_x = originX,
			origin_y = originY,
			module_size = QR_MODULE_SIZE,
			quiet_zone = QR_QUIET_ZONE,
			optimize_merge = true,
			prefer_axis = "auto",
			max_box_count = qrMaxBoxes,
			include_background = true,
			fg = {r = 10, g = 10, b = 10, a = 255},
			bg = {r = 255, g = 255, b = 255, a = 230},
		})
		return okDraw, info, originX, originY, qrPixelSize
	end

	local reserveForLogo = useLogo and fullLogoCount or 0
	local okDraw, info, originX, originY, qrPixelSize = drawMatrix(matrix, reserveForLogo)
	if (not okDraw) and useLogo then
		-- 로고 예산을 확보하지 못한 경우 로고 없이 재시도
		local okRetry, retryMatrix = qrcode(value, 2)
		if okRetry then
			useLogo = false
			logoHole = nil
			okDraw, info, originX, originY, qrPixelSize = drawMatrix(retryMatrix, 0)
		end
	end
	if not okDraw then
		setStatus("QR draw failed: " .. tostring(info), 255, 120, 120)
		return false
	end

	local logoBoxCount = 0
	if useLogo and logoHole then
		logoBoxCount = drawLogo(QRTest, originX, originY, logoHole, fullLogoCount)
	end

	QRTest.qr_context = qrContext
	setStatus(string.format("QR Ready (v%d, logo %d)", version, logoBoxCount), 180, 255, 180)

	local showInfo = not (type(options) == "table" and options.show_info == false)
	local infoText = ensureInfoText(QRTest)
	if showInfo then
		local nickname = tostring(options and options.nickname or "Unknown")
		local record = tostring(options and options.record or "00:00.00")
		local cp = tonumber(options and options.cp) or 0
		local gc = tonumber(options and options.gc) or 0
		local textWidth = math.max(120, qrPixelSize)
		local baseY = originY + qrPixelSize + 16

		infoText.nick:Set({
			font = "small",
			align = "left",
			x = originX,
			y = baseY,
			width = textWidth,
			height = 16,
			text = string.format("닉네임: %s", nickname),
			r = 240,
			g = 240,
			b = 240,
			a = 255,
		})
		infoText.record:Set({
			font = "small",
			align = "left",
			x = originX,
			y = baseY + 16,
			width = textWidth,
			height = 16,
			text = string.format("기록: %s", record),
			r = 240,
			g = 240,
			b = 240,
			a = 255,
		})
		infoText.count:Set({
			font = "small",
			align = "left",
			x = originX,
			y = baseY + 32,
			width = textWidth,
			height = 16,
			text = string.format("CP/GC: %d / %d", cp, gc),
			r = 240,
			g = 240,
			b = 240,
			a = 255,
		})

		infoText.nick:Show()
		infoText.record:Show()
		infoText.count:Show()
	else
		infoText.nick:Hide()
		infoText.record:Hide()
		infoText.count:Hide()
	end

	return true
end

-- 인자 time에 해당하는 QR생성
---@param time number
function KZ.Event:getQR(time)
	local nickName = KZ.Player.name[KZ.Index]
	local mapIndex = KZ_MAP_INDEX
	local cp = KZ.Player.cp[KZ.Index]
	local gc = KZ.Player.gc[KZ.Index]
	local plain = string.format("%s.%s.%s.%d.%d,%d", mapIndex, nickName, time, cp, gc, KZ.WeaponModeIndex)
	local enc = strEncrypt(plain, "20260224")
	local url = ""
	if LanServer.value == true then
		url = string.format("%s/submit/%s", getBaseURL(), "LAN")
	else
		url = string.format("%s/submit/%s", getBaseURL(), enc)
	end
	local record = timeToStr((tonumber(time) or 0) / 100)

	return KZ.Event:CreateQRCodeByBox(url, {
		show_info = true,
		nickname = nickName,
		record = record,
		cp = cp,
		gc = gc,
		qr_context = "submit_run",
	})
end

function KZ.Event:SubmitRun()
	if KZ.Event:IsQRCodeVisible("submit_run") then
		return
	end
	KZ.Event:getQR(KZ.PreviousTime)
end

function KZ.Event:StartNewRun()
	KZ.Event:HideSubmitQR()
	Timer:Reset()
	Timer.startTime = UI.GetTime()
	Timer:Refresh()
	Timer:Pause_Off(true)
	KZ.Event:Menu()
	KZ.Event:Start()
end

local menuCountSet = {font="small", align="left", y=center.y-87, width=screen.width, height=15}
SubmitMenu = Menu:new(menuTitleSet, {menuNumberSet, menuElemSet, menuCountSet}, 12)

SubmitMenu.elem[1][1]:Set({text="1. "})	SubmitMenu.elem[2][1]:Set({text="Submit this Run"})
SubmitMenu.elem[1][2]:Set({text="2. "})	SubmitMenu.elem[2][2]:Set({text="Start new Run"})
SubmitMenu.elem[1][5]:Set({text="0. "})	SubmitMenu.elem[2][5]:Set({text="Exit"})

SubmitMenu:ActionSetup(1, KZ.Event.SubmitRun)
SubmitMenu:ActionSetup(2, KZ.Event.StartNewRun)
SubmitMenu:ActionSetup(0, KZ.Event.HideSubmitQR)
rankingMenu:ActionSetup(0, KZ.Event.HideQRCode)

function KZ.Event:SubmitMenu()
	KZ.Event:HideAllMenuQR()
	defaultMenu:Toggle()
	SubmitMenu:Toggle()
end

SubmitMenu:Visible(false)
--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- 기본 메뉴

local menuCountSet = {font="small", align="left", y=center.y-87, width=screen.width, height=15}
defaultMenu = Menu:new(menuTitleSet, {menuNumberSet, menuElemSet, menuCountSet}, 12)

cpElem = defaultMenu.elem[3][1]
gcElem = defaultMenu.elem[3][2]
pauseElem = defaultMenu.elem[3][7]

local elem_set = HUD.Menu.Elem

cpElem:Set({x=154, r=elem_set.Color_count.r, g=elem_set.Color_count.g, b=elem_set.Color_count.b, a=elem_set.Color_count.a})
gcElem:Set({x=134, r=elem_set.Color_count.r, g=elem_set.Color_count.g, b=elem_set.Color_count.b, a=elem_set.Color_count.a})
pauseElem:Set({x=114, r=elem_set.Color_pause_off.r, g=elem_set.Color_pause_off.g, b=elem_set.Color_pause_off.b, a=elem_set.Color_pause_off.a})

function SetPauseColor(onoff)
	if onoff then
		pauseElem:Set({text="ON", r=elem_set.Color_pause_on.r, g=elem_set.Color_pause_on.g, b=elem_set.Color_pause_on.b, a=elem_set.Color_pause_on.a})
	else
		pauseElem:Set({text="OFF", r=elem_set.Color_pause_off.r, g=elem_set.Color_pause_off.g, b=elem_set.Color_pause_off.b, a=elem_set.Color_pause_off.a})
	end
end

defaultMenu.title:Set({text=title_set.MainMenu})
defaultMenu.elem[1][1]:Set({text="1. "})	defaultMenu.elem[2][1]:Set({text="Checkpoint - "})
defaultMenu.elem[1][2]:Set({text="2. "})	defaultMenu.elem[2][2]:Set({text="Gocheck - "})
defaultMenu.elem[1][3]:Set({text="3. "})	defaultMenu.elem[2][3]:Set({text="Stuck"})
defaultMenu.elem[1][5]:Set({text="4. "})	defaultMenu.elem[2][5]:Set({text="Start"})
defaultMenu.elem[1][6]:Set({text="5. "})	defaultMenu.elem[2][6]:Set({text="All Top"})
defaultMenu.elem[1][7]:Set({text="6. "})	defaultMenu.elem[2][7]:Set({text="Pause -"})
defaultMenu.elem[1][9]:Set({text="7. "})	defaultMenu.elem[2][9]:Set({text="Settings"})
defaultMenu.elem[1][10]:Set({text="8. "})	defaultMenu.elem[2][10]:Set({text="Save Position"})
defaultMenu.elem[1][11]:Set({text="9. "})	defaultMenu.elem[2][11]:Set({text="Teleport"})
defaultMenu.elem[1][12]:Set({text="0. "})	defaultMenu.elem[2][12]:Set({text="Exit"})

if not MAP.CanCP then
	for i = 1, 3 do
		defaultMenu.elem[i][1]:Set({a=100})
		defaultMenu.elem[i][2]:Set({a=100})
		defaultMenu.elem[i][3]:Set({a=100})
		defaultMenu.elem[i][9]:Set({a=100})
	end
end

defaultMenu:ActionSetup(1, KZ.Event.CP)
defaultMenu:ActionSetup(2, KZ.Event.GC)
defaultMenu:ActionSetup(3, KZ.Event.BackCP)
defaultMenu:ActionSetup(4, KZ.Event.Start)
defaultMenu:ActionSetup(5, KZ.Event.All)
defaultMenu:ActionSetup(6, KZ.Event.Pause)
defaultMenu:ActionSetup(7, KZ.Event.Setting)
defaultMenu:ActionSetup(8, KZ.Event.Save)
defaultMenu:ActionSetup(9, KZ.Event.TP)

function KZ.Event:Menu()
	defaultMenu:Toggle()
end

SetPauseColor(false)
defaultMenu:Visible(true)

Timer:Init()


