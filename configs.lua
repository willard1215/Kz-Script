-- configs.lua

version = '__kz script ver 4.0.0__' -- 2026/02/20

--[[
	적용법 참고 link: https://youtu.be/j00-yMBij5Q?si=MvSZcQTe9idVRJXx (ver 2.0.1 기준)
	버니블록 스크립트를 사용하지 않으려면 MAP.Mode를 ''로 바꿔주세요. mpbhop.lua의 내용에 의해 오류가 발생합니다.
	kz script ver 3.0 버전 이상의 configs.lua와 mpbhop.lua, ranking.lua를 공유할 수 있습니다.
	스튜디오 저장 관리 그룹 할당 시 세션이 변경되어도 플레이어 세이브 포지션이 소멸하지 않고 불러와집니다. 저장 그룹은 MAP.Title만 서로 다르다면 맵들을 같은 그룹에 적용해도 무관합니다.
	맵에 몬스터 소환을 원할 경우 몬스터 제거 좌표(MAP.MonsterKillBlock)를 입력해주세요. 미입력 시 몬스터가 모두 사망합니다.


	플레이모드 오버프리 안뜸
	그룹저장 고쳐지면 /rank : 랭킹, 기록 | 콘솔에 기록갱신확인 | TOP 바로 반영

	[자주 발생하는 오류]
	==========================================================
	※ 오류 발생 시 콘솔창을 열어 내용 확인

	Error : comfile error : 문법 오류
		[string "-- game.lua..."]:561:
			game.lua의 561번째 줄에서 오류가 발생했다는 의미입니다.
			주로 ,나 }의 규칙을 지키지 않아서 발생합니다. 오류가 발생한 위치를 보면 금방 해결할 수 있습니다.

	Error : runtime error : 밸류 오류
		[string "-- ui.lua..."]:681:
			ui.lua의 681번째 줄에서 오류가 발생했다는 의미입니다.
			최근에 수정한 밸류의 이름이 잘못되어 있을 확률이 큽니다.

	[string "-- game.lua..."]:164: attemp to index a nil value (local
	'StartButton') -- 스타트 버튼 좌표가 일치하지 않습니다.

	[string "-- game.lua..."]:176: attemp to index a nil value (local
	'FinishButton') -- 피니쉬 버튼 좌표가 일치하지 않습니다.

	[string "-- game.lua..."]:563: 오류 1-2 영역 블록 없음
	stack traceback: -- mpbhop.lua의 1구간 2번째 버니블록 좌표가 일치하지 않습니다.


	[3.0 업데이트 패치 내용]
	==========================================================
	- Pre & Max 추가

	- 플레이 후 클라이언트의 숫자 표시에서 #이 붙는 문제 해결

	- 랭킹 페이지화 + 중복 플레이어 제거

	- "/log" 커맨드 추가
		ㆍ 세션 내의 모든 클리어 기록을 불러옵니다.

	- 가상 커맨드 추가
		ㆍ 채팅을 입력하지 못하더라도 SHIFT + C 를 눌러 커맨드를 입력할 수 있습니다.

	- Pause 중 이동 자유 + 가상 체크포인트
		ㆍ Pause 중에 체크포인트와 고체크를 정상적으로 사용할 수 있으며 횟수가 증가하지 않습니다.

	- 데이터 저장 기능 추가
		ㆍ 맵에 저장 그룹 할당 시 세이브 포지션이 세션이 달라져도 소멸하지 않고 불러와집니다.

	- CP버그 허용 비허용 옵션 추가

	- 벽낑 허용 비허용 옵션 추가

	- mpbhop 버전 통일
		ㆍ MAP.Mode 에서 버니블록 사용을 설정할 수 있습니다.

	- mpbhop TpZone x1, x2가 더이상 최솟값 최댓값을 의미하지 않음
		ㆍ 값의 크기에 상관없이 범위의 두 끝 좌표를 입력할 수 있습니다.

	- 버니블록 점프 허용 횟수 기능 추가
		ㆍ 애프터 미허용일 때 특정 버니블록만 애프터가 가능하게 활용할 수도 있습니다.

	- 키입력 오버레이 추가

	- 스타트포지션 설정 기능 추가
		ㆍ 맵에 설정된 좌표로 이동할 지 마지막에 스타트 버튼을 누른 장소로 이동할 지 설정할 수 있습니다.

	- 텔레포트 기능 추가
		ㆍ 제트팩 사용 중 원하는 플레이어의 위치로 이동합니다.

	- 디버깅 모드 추가
		ㆍ 스크립트 테스트 환경에서 보기 힘든 텍스트를 상시로 표시하고, 스타트 버튼과 피니쉬 버튼이 없어도 오류를 발생시키지 않습니다. ※맵 공개 시 꼭 디버깅 모드를 해제하고 공개해주세요.
]]                --

DebugMode = false -- 디버깅 모드 On / Off ( true / false )

KZ_BASE_URL = "https://cso-studio.com/"
KZ_MAP_INDEX = 0 -- 맵 인덱스

MAP = {
	Title = "kz script 4.0 샘플맵 - 복사본(1)", -- 맵 이름
	By = "Studio", -- 제작자 이름
	Mode = 'mpbhop', -- 'mpbhop' or ''
	CanCP = true, -- 체크포인트 사용 가능 여부 On / Off ( true / false )
	FallDamage = false, -- 낙사 데미지 On / Off ( true / false )
	AutoBhop = false, -- 오토버니 사용 여부 On / Off ( true / false ) ※제트팩이 꺼져있을 때 스페이스바를 꾹 눌러서 사용
	ClearJetPack = false, -- 클리어 후 제트팩 사용 가능 / 모두 사용 가능 ( true / false )
	BlockPixelWalk = true, -- 벽낑 방지 On / Off ( true / false ) ※서프맵에 해당 기능을 사용하는 것을 권장하지 않습니다.
	StartButton = {x=-1, y=2, z=2}, -- 스타트 버튼 좌표 ※좌표가 일치하지 않거나 없을 경우 오류
	FinishButton = {x=1, y=2, z=2}, -- 피니쉬 버튼 좌표 ※좌표가 일치하지 않거나 없을 경우 오류
	StartPosition = {x=0, y=-2, z=1}, -- 스타트 포지션 좌표 (스튜디오 스폰 블록과 무관)

    MonsterKillBlock = nil,                     -- 몬스터 제거 좌표. 맵에 몬스터 소환을 원할 경우 필드에서 안보이는 장소에 몬스터 킬 블록 설치 후 좌표 입력
}

if MAP.Mode == 'mpbhop' then
    Addons = {
	CanAfter = true, -- 버니블록 위에서 애프터 허용 On / Off ( true / false )
	CanBhopBack = true, -- 이전 버니블록 밟기 허용 On / Off ( true / false )
	CanCPBug = false, -- CP 버그 허용 On / Off ( true / false )
	JetPackTeleport = false, -- 제트팩 사용 중 리스폰 적용 / 미적용 ( true / false )
    }
end

VALUE = {
	MaxPlayer = 24, -- 최대 플레이어 ※설정된 값보다 플레이어가 많아지면 오류가 발생합니다. 렉을 다소 줄이려면 월드세팅의 최대 플레이어와 동일하게 설정해주세요.
	PlayerHealth = 255, -- 플레이어 체력
	JetPack = 260, -- 제트팩 출력
	AutoBhopSpeed = 300, -- 오토버니 가속 제한
}

COMMAND = {
    CP = '/cp',                   -- 체크포인트
    GC = '/gc',                   -- 고체크
    BACKCP = '/stuck',            -- 백CP
    JETPACK = '/nc',              -- 제트팩
    SPEC = '/spec',               -- 관전
    START = '/start',             -- 스타트 포지션
    ALL = '/all',                 -- 랭킹 보기
    MENU = '/menu',               -- 메뉴
    PAUSE = '/pause',             -- 타이머 정지
    BIND = '/bind',               -- 바인드 세팅
    UNBIND = '/unbind',           -- 바인드 해제
    LOG = '/log',                 -- 세션 로그 확인
    RTV = 'rtv',                  -- 맵 변경 투표
    SAVE = '/save',               -- 세이브 포지션,
    viewangleGC = '/viewangleGC', -- 시야각 저장 모드로 고체크
}

HUD = {

    Label = { -- 라벨
        Text_1 = "  " .. MAP.Title,
        Text_2 = "｜                                  Map by " .. MAP.By .. " ｜", -- 띄어쓰기 여백으로 라벨 길이 조절
        Size = 'small', -- 폰트 사이즈 (small) or medium or large or verylarge
        Place = 'top-left', -- 라벨 위치 (top) or bottom - (left) or center or right
        Zoom = 0.03, -- 라벨 스크린 줌 (화면 끝에서 멀어지는 정도 0 ~ 1)
        Color_1 = { r = 0, g = 155, b = 255, a = 200 }, -- 맵 제목 색깔
        Color_2 = { r = 255, g = 0, b = 0, a = 200 }, -- 제작자 이름 색깔
    },

    Menu = {
        Title = {                                                  -- 메뉴 타이틀 문구
            MainMenu = "Kz Menu",                                  -- 메인 메뉴
            SaveMenu = "SavePosition Menu",                        -- 세이브 메뉴
            SpecMenu = "Spec Menu",                                -- 관전 메뉴
            TPMenu = "Teleport Menu",                              -- 텔레포트 메뉴
            SettingMenu = "Setting",                               -- 세팅 메뉴
            BindMenu = "Bind Setup",                               -- 바인드 메뉴
            OverlayMenu = "Key Viewer Setup",                      -- 키뷰어 메뉴
            StartPosMenu = "Start Position Setup",                 -- 스타트 설정 메뉴
            ViewAngleCPMode = "View Angle CP Mode - ",             -- 시야각 저장 메뉴
            ToggleViewAngleCheckPoint = "Set View Angle | now - ", -- 시야각 체크포인트 활성화 메뉴
            TimerDesign = "Timer Mode - ",                         -- 시야각 체크포인트 활성화 메뉴
            WeaponMode = "Weapon Mode - ",                         -- 무기 모드 설정 메뉴
            Color = { r = 255, g = 140, b = 60, a = 255 },         -- 메뉴 타이틀 색깔
        },
        Elem = {
            Color_default = { r = 255, g = 255, b = 222, a = 255 },      -- 목록 기본 색깔
            Color_number = { r = 222, g = 180, b = 120, a = 255 },       -- 목록 번호 색깔
            Color_count = { r = 255, g = 255, b = 0, a = 180 },          -- CP, GC 카운트 색깔
            Color_pause_on = { r = 255, g = 255, b = 0, a = 180 },       -- Pause 활성화 시 옵션 색깔
            Color_pause_off = { r = 255, g = 50, b = 0, a = 180 },       -- Pause 비활성화 시 옵션 색깔
            Color_view_angle_on = { r = 188, g = 50, b = 50, a = 222 },  -- 시야각 저장 모드 활성화 시 옵션 색깔
            Color_view_angle_off = { r = 255, g = 255, b = 0, a = 180 }, -- 시야각 저장 모드 비활성화 시 옵션 색깔
        },
    },

    Ranking = { -- 랭킹 메뉴
        Title = {
            Text = "ALL Top on " .. MAP.Title,
            Color = { r = 255, g = 50, b = 0, a = 200 },
        },
        Elem = {
            Color_rank = { r = 255, g = 250, b = 0, a = 170 },     -- 랭킹 등수 색깔
            Color_record = { r = 255, g = 255, b = 255, a = 150 }, -- 랭킹 타임 색깔
            Color_player = { r = 255, g = 250, b = 0, a = 170 },   -- 랭킹 플레이어 색깔
        },
    },

    Timer = { -- 타이머
        Size = 'medium',
        Place = 'bottom-center',
        Zoom = 0.18,
        Color = { r = 212, g = 232, b = 232, a = 180 },
        Style = 'detail',     -- 'detail' : 00:00.00까지 표시 / 'simple' : 00:00까지 표시
        Scale = 1.0,          -- 디지털 타이머 크기 배율
        DigitalLength = 14,   -- 세그먼트 길이(길쭉한 정도)
        DigitalDiagStep = 1,  -- scale=1 기준 대각선 단계 간격(px)
        DigitalHourDigits = 3 -- 100시간 이상 표시를 위한 시 자리수
    },

    Notice = { -- 메세지
        Main = {
            Size = 'medium',
            Place = 'top-center',
            Zoom = 0.33,
            Color = { r = 255, g = 255, b = 255, a = 255 },
            VisibleFrame = 1,  -- 보여지는 프레임
            KeepFrame = 320,   -- 온전히 보이는 프레임
            FadeoutFrame = 72, -- 사라지는 프레임
        },
        Under = {
            Size = 'medium',
            Place = 'bottom-center',
            Zoom = 0.09,
            Color = { r = 222, g = 222, b = 222, a = 255 },
            VisibleFrame = 1,
            KeepFrame = 144,
            FadeoutFrame = 72,
        },
        Issue = {
            Color = { r = 222, g = 222, b = 222, a = 222 },
            VisibleFrame = 1,
            KeepFrame = 144,
            FadeoutFrame = 72,
        },
    },

    Unit = { -- 속도계
        Pre = {
            Size = 'small',
            Place = 'bottom-center',
            Zoom = 0.42,
            Color_default = { r = 188, g = 50, b = 50, a = 222 }, -- 프리 기본 색깔
            Color_fail = { r = 255, g = 140, b = 120, a = 222 },  -- 오버프리 색깔
            VisibleFrame = 1,
            KeepFrame = 144,
            FadeoutFrame = 1,
        },
        Max = {
            Size = 'small',
            Place = 'bottom-center',
            Zoom = 0.45,
            Color = { r = 0, g = 188, b = 188, a = 222 },
            VisibleFrame = 1,
            KeepFrame = 144,
            FadeoutFrame = 1,
        },
        Speed = {
            Size = 'small',
            Place = 'bottom-center',
            Zoom = 0.36,
            Color = { r = 255, g = 255, b = 255, a = 255 },
        },
    },

    RTV = {                                               -- rtv
        Color_1 = { r = 222, g = 222, b = 222, a = 222 }, -- rtv 기본 색깔
        Color_2 = { r = 80, g = 140, b = 222, a = 222 },  -- 필요한 rtv 수 색깔
        VisibleFrame = 1,
        KeepFrame = 480,
        FadeoutFrame = 1,
    },

    Session_Rank = { -- 세션 랭킹
        [1] = {
            Text = "1st",
            Color = { r = 255, g = 255, b = 255, a = 255 },
        },
        [2] = {
            Text = "2nd",
            Color = { r = 255, g = 255, b = 255, a = 255 },
        },
        [3] = {
            Text = "3rd",
            Color = { r = 255, g = 255, b = 255, a = 255 },
        },
    },

    Bind = { -- 바인드 목록
        [1] = '/cp',
        [2] = '/gc',
        [3] = '/viewangleGC',
        [4] = '/stuck',
        [5] = '/start',
        [6] = '/pause',
        [7] = '/nc',
    },

    Spec = { -- 관전 오버레이
        Timer = {
            Size = 'small',
            Place = 'top-right',
            Zoom = 0.40,
            Color = { r = 100, g = 200, b = 180, a = 255 },
        },

        Overlay = {
            Size = 'small',
            Place = 'top-right',
            Zoom = 0.18,
            Color = { r = 100, g = 200, b = 180, a = 255 },
        },
    },

    KeyViewer = {                                -- 키뷰어
        Color = { r = 180, g = 222, b = 222 },
        Color_bad = { r = 180, g = 50, b = 20 }, -- A와 D가 동시에 눌리고 있을 때 키뷰어 피드백 색깔
    },

    Descr = { -- 설명
        DefaultMenu = {
            Text = "V.KEY : 메뉴 열기",
            Color = { r = 0, g = 222, b = 80, a = 200 },
        },
        SpecMenu = {
            Text = "M.KEY : 메뉴 열기",
            Color = { r = 0, g = 222, b = 80, a = 200 },
        },
    },

    Effect = {
        PauseColor = { r = 120, g = 120, b = 255, a = 20 },
        InvaildPositionColor = { r = 255, g = 50, b = 50, a = 60 },
        EffectOptions = {
            pixel = 1,      -- 픽셀 크기
            size = 40,      -- 크기
            opacity = 4,    -- 픽셀별 투명도
            duration = 0.2, -- 애니메이션 지속 시간
        }
    }
}

ReservedText = {
    DontCP = "공중에서는 체크포인트 생성 불가",
    DontPS = "공중에서는 타이머 일시정지 불가",
    DontGC = "체크포인트가 부족합니다",
    DontUG = "고체크가 부족합니다",
    DidNotStart = "타이머가 시작되지 않았습니다",
    UsedJetPack = "제트팩 사용 후 3초간 기다리세요",
    TimerStart = "타이머 시작",
    TPtoStart = "시작 위치로 텔레포트 됩니다",
    JetPackOn = "제트팩 활성화",
    JetPackOff = "제트팩 비활성화",
    PauseOn = "당신의 타이머가 일시정지됩니다",
    PauseOff = "당신의 타이머가 정지해제됩니다",
    BindSuccess = "입력한 키가 지정되었습니다",
    CantJP = "클리어 후 사용 가능합니다",
    Saved = "타이머와 위치가 저장되었습니다",
    Loaded = "저장된 진행이 있습니다. 불러오시겠습니까?",
    NoSave = "저장된 진행이 없습니다",
    InvaildPosition = "유효한 위치가 아닙니다",
    PressBindKey = "지정하려는 키를 누르세요",
    TimerResetByJetPack = "제트팩 활성화 감지됨. 타이머 리셋",
    NeedJetPack = "제트팩 활성화 후 사용 가능합니다",
    PressArrowKeys = "방향키를 눌러 이동한 후 엔터를 누르세요",
    HideKeyViewer = "키뷰어 비활성화",
    ShowKeyViewer = "키뷰어 활성화",
    ResetKeyViewer = "키뷰어 위치가 초기화되었습니다",
    SetStartPosition = "스타트 포지션이 설정되었습니다",
    UnBinded = "바인드 설정이 모두 해제되었습니다",
}

SIGNAL = {
    ToGame = {
        CP = -1,
        GC = -2,
        START = -3,
        SPEC = -4,
        BACKCP = -5,
        RESET = -6,
        JETPACK = -7,
        NC_ON = -8,
        NC_OFF = -9,
        PAUSE_ON = -10,
        PAUSE_OFF = -11,
        AUTOBHOP = -12,
        LOAD = -13,
        RTV = -14,
        LOG = -15,
        KEYDOWN_W = -16,
        KEYDOWN_A = -17,
        KEYDOWN_S = -18,
        KEYDOWN_D = -19,
        KEYUP_W = -20,
        KEYUP_A = -21,
        KEYUP_S = -22,
        KEYUP_D = -23,
        ONTIME = -24,
        FREESTART = -25,
        PIXELWALK = -26,
        SAVE_VIEW_ANGLE = -27,
        ANGLE_CHECK_POINT = -28,
        BUY_WEAPON = -29,
        SET_WEAPON_MODE = -30
    },

    ToUI = {
        TIMER_START = 1,
        TIMER_END = 2,
        FINISH = 3,
        DONTCP = 4,
        DONTGC = 5,
        PAUSE = 6,
        PAUSE_OFF = 7,
        DONTPS = 8,
        NOSAVE = 9,
        SAVED = 10,
        SAVE = 11,
        LOAD = 12,
        INVAILD_POSITION = 13,
        KEYDOWN_W = 14,
        KEYDOWN_A = 15,
        KEYDOWN_S = 16,
        KEYDOWN_D = 17,
        KEYUP_W = 18,
        KEYUP_A = 19,
        KEYUP_S = 20,
        KEYUP_D = 21,
        PIXELWALK = 22,
    }
}

BuymenuWeaponList =	{
	Common.WEAPON.USP45,
	Common.WEAPON.P90,
	Common.WEAPON.FAMAS,
    Common.WEAPON.SG552,
	Common.WEAPON.M4A1,
	Common.WEAPON.AK47,
	Common.WEAPON.AWP,
    4008,
}


Common.UseScenarioBuymenu(true)
Common.SetBuymenuWeaponList(BuymenuWeaponList)

WeaponList = {
	Common.WEAPON.Scout,
    Common.WEAPON.USP45,
	Common.WEAPON.P90,
	Common.WEAPON.FAMAS,
    Common.WEAPON.SG552,
	Common.WEAPON.M4A1,
	Common.WEAPON.AK47,
	Common.WEAPON.AWP,
}

for i = 1, #BuymenuWeaponList do
	Common.GetWeaponOption(WeaponList[i]).price = 0
end

Common.GetWeaponOption(WeaponList[1]).user.correctionFactor = 1.0    -- Scout
Common.GetWeaponOption(WeaponList[2]).user.correctionFactor = 1.0       -- USP-45
Common.GetWeaponOption(WeaponList[3]).user.correctionFactor = 1.023   -- P90
Common.GetWeaponOption(WeaponList[4]).user.correctionFactor = 1.045   -- FAMAS
Common.GetWeaponOption(WeaponList[5]).user.correctionFactor = 1.067    -- SG552
Common.GetWeaponOption(WeaponList[6]).user.correctionFactor = 1.089    -- M4A1
Common.GetWeaponOption(WeaponList[7]).user.correctionFactor = 1.135    -- AK47
Common.GetWeaponOption(WeaponList[8]).user.correctionFactor = 1.195   -- AWP


-- 무기별 속도
WEAPONSPEED = {
	[1] = 1,  -- USP45
	[2] = 0.98, -- P90
	[3] = 0.96, -- FAMAS
	[4] = 0.94, -- SG552
	[5] = 0.92, -- M4A1
	[6] = 0.88, -- AK47
	[7] = 0.84, -- AWP
}


Common.SetNeedMoney(true) -- 무기 구매핵 방지
Common.SetAutoLoad(true)  -- 저장정보 자동 불러오기

function splitstr(inputstr, sep)
    sep = sep or "%s"

    local t = {}

    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end

    return t
end

function dynamicPadding(n)
    if n < 10 then
        return string.format("%02d", n)
    else
        return string.format("%d", n)
    end
end

function bool_to_number(bool, value, negative)
    if negative then
        return bool and value or -value
    else
        return bool and value or 0
    end
end

function SyncValueSet(module)
    local function f(name, range)
        local t

        if range then
            t = {}

            for i = 1, range do
                t[i] = module.SyncValue.Create(string.format("%s%i", name, i))
            end
        else
            t = module.SyncValue.Create(name)
        end

        return t
    end

    return f
end

--[[
테이블 깊은 복사

Args:

	table(table): 복사할 테이블

Returns:

    table: 복사된 테이블
]]
function TableDeepCopy(orig)
    local orig_type = type(orig)
    local copy

    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[orig_key] = TableDeepCopy(orig_value)
        end
    else -- 테이블이 아니면 그대로 복사
        copy = orig
    end
    return copy
end

--[[
테이블 병합

Args:

	...: 병합할 테이블들

Returns:

    table: 병합된 테이블
]]
function TableMerge(...)
    local tables_to_merge = { ... }
    assert(#tables_to_merge > 1, "There should be at least two tables to merge them")

    for k, t in ipairs(tables_to_merge) do
        assert(type(t) == "table", string.format("Expected a table as function parameter %d", k))
    end

    local result = TableDeepCopy(tables_to_merge[1])

    for i = 2, #tables_to_merge do
        local from = tables_to_merge[i]
        for k, v in pairs(from) do
            if type(k) == "number" then
                table.insert(result, v)
            elseif type(k) == "string" then
                if type(v) == "table" then
                    result[k] = result[k] or {}
                    result[k] = TableMerge(result[k], v)
                else
                    result[k] = v
                end
            end
        end
    end

    return result
end

-- isSurf.lua
-- generated by CSOEPS

__KZ_SURF_DATA_PARTS = __KZ_SURF_DATA_PARTS or {}

local _kz_b64_map = nil
local _kz_b64_alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function _kz_build_b64_map()
    if _kz_b64_map ~= nil then
        return _kz_b64_map
    end
    local m = {}
    for i = 1, string.len(_kz_b64_alphabet), 1 do
        local ch = string.sub(_kz_b64_alphabet, i, i)
        m[ch] = i - 1
    end
    _kz_b64_map = m
    return m
end

local function _kz_base64_decode(data)
    if data == nil or data == "" then
        return ""
    end
    local map = _kz_build_b64_map()
    local out = {}
    local i = 1
    local n = string.len(data)
    while i <= n do
        local c1 = string.sub(data, i, i)
        local c2 = string.sub(data, i + 1, i + 1)
        local c3 = string.sub(data, i + 2, i + 2)
        local c4 = string.sub(data, i + 3, i + 3)
        i = i + 4

        local v1 = map[c1] or 0
        local v2 = map[c2] or 0
        local v3 = (c3 == "" or c3 == "=") and nil or (map[c3] or 0)
        local v4 = (c4 == "" or c4 == "=") and nil or (map[c4] or 0)

        local combined = v1 * 262144 + v2 * 4096 + (v3 or 0) * 64 + (v4 or 0)
        out[#out + 1] = string.char(math.floor(combined / 65536) % 256)
        if v3 ~= nil then
            out[#out + 1] = string.char(math.floor(combined / 256) % 256)
        end
        if v4 ~= nil then
            out[#out + 1] = string.char(combined % 256)
        end
    end
    return table.concat(out)
end

local function _kz_decode_varints(raw)
    local result = {}
    local prev = 0
    local idx = 1
    local len = string.len(raw)

    while idx <= len do
        local shift = 0
        local delta = 0
        while true do
            if idx > len then
                break
            end
            local b = string.byte(raw, idx)
            idx = idx + 1
            delta = delta + ((b % 128) * (2 ^ shift))
            if b < 128 then
                break
            end
            shift = shift + 7
        end

        prev = prev + delta
        result[#result + 1] = prev
    end

    return result
end

local function _kz_build_surf_lookup()
    if __KZ_SURF_LOOKUP ~= nil then
        return __KZ_SURF_LOOKUP
    end

    local merged = table.concat(__KZ_SURF_DATA_PARTS)
    local raw = _kz_base64_decode(merged)
    local values = _kz_decode_varints(raw)
    local lookup = {}
    for i = 1, #values, 1 do
        lookup[values[i]] = true
    end
    __KZ_SURF_LOOKUP = lookup
    return __KZ_SURF_LOOKUP
end

local function _kz_pack_surf_coord(x, y, z)
    local rx = math.floor((x or 0) + 192)
    local ry = math.floor((y or 0) + 192)
    local rz = math.floor((z or 0) + 96)

    if rx < 0 or rx > 383 then return nil end
    if ry < 0 or ry > 383 then return nil end
    if rz < 0 or rz > 191 then return nil end

    return rx + (ry * 512) + (rz * 262144)
end

function isSurf(x, y, z)
    local packed = _kz_pack_surf_coord(x, y, z)
    if packed == nil then
        return false
    end
    local lookup = _kz_build_surf_lookup()
    return lookup[packed] == true
end
