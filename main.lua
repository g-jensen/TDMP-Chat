--[[ TODO:
    -add movable cursor
        -add del button
        -add selecting by shift
        -add jumping cursor by ctrl
        -add selecting by shift + crtl
    -preety it up
    -add options.lua
        -nick color
        -buffer size
        -position
    -death messages
]]
if not TDMP_LocalSteamId then DebugPrint("[TDMP Chat] TDMP is not present, chat mod will be disbled") return end

#include "tdmp/networking.lua"
#include "tdmp/player.lua"
#include "tdmp/hooks.lua"
#include "tdmp/json.lua"


local keys = {
    "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
    "1","2","3","4","5","6","7","8","9","0",
    "-","+",",","."
}

local keys_shifted = {
    "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "!","@","#","$","%","^","&","*","(",")",
    "_","DO NOT USE","<",">"
}

-- holds the characters being input in the chat box
local input = ""
local chat_msg = {}
chat_msg["msg"] = ""
chat_msg["sender_id"] = nil

local bindOpenChat = "t"

if GetInt("savegame.mod.textfontsize") == 0 then -- checks if registry has data, if not set default
	SetInt("savegame.mod.textfontsize", 20)
	SetInt("savegame.mod.textalpha", 80)
	SetInt("savegame.mod.textboxalpha", 50)
end

local font = "fonts/UbuntuMono-Regular.ttf"
local textalpha = GetInt("savegame.mod.textalpha") / 100
local textboxalpha = GetInt("savegame.mod.textboxalpha") / 100
local font_size = GetInt("savegame.mod.textfontsize")
local nick_color = {1,0.5,2}

-- chatState can be false or true
local chatState = false
local messages = {}

gTDMPScale = 0

local nicks = {}

local hasInit = false
local hostHasConnected = false

function init()
end

function update(dt)
end

function tick(dt)
    if clientId then hostHasConnected = true else getNicks() end
    if (hostHasConnected and hasInit ~= true) then server_init() hasInit = true end

end

TDMP_RegisterEvent("MessageSent", function(message)

    decodeMessage(message)
    DebugPrint(message)

    if not TDMP_IsServer() then return end -- if not a host stop

    TDMP_ServerStartEvent("MessageSent", {
        Receiver = TDMP.Enums.Receiver.ClientsOnly,
        Reliable = true,

        DontPack = true,
        Data = message
    })

end)

function getNicks()
    for i, ply in ipairs(TDMP_GetPlayers()) do
        nicks[ply.id] = ply.nick
        if TDMP_IsMe(ply.id) then
            clientId = ply.id
        end
    end
end

-- server is initialized
function server_init() 
end

function sendMessage(message) 
    TDMP_ClientStartEvent("MessageSent", {
        Receiver = TDMP.Enums.Receiver.ClientsOnly,
        Reliable = true,
        DontPack = false,
        Data = {input,clientId}
    })
end

function decodeMessage(message)
    message = json.decode(message)
    local msg = message[1]
    local sender = nicks[message[2]]
    table.insert(messages,{sender,msg})
    bend_to_my_will(sender..": "..msg)
end

function bend_to_my_will(payload)
    local mod = {}
	mod.id = #gMods[2].items+1
	mod.name = payload
	mod.active = false
	mod.steamtime = 1
	mod.subscribetime = 1
	mod.showbold = false;
	gMods[2].items[#gMods[2].items+1] = mod
end


function handleKeyInput()
    UiMakeInteractive()

    for i=1,#keys,1 do
        if InputPressed(keys[i]) and i ~= 38 then
              if InputDown("shift") then
                input = input..keys_shifted[i]
              else
                input = input..keys[i]
              end
        elseif InputPressed(keys[i]) and i == 38 then
            if InputDown("shift") then --fixes weird =/+ handling
                input = input.."+"
            else
                input = input.."="
            end
        end
    end

    if InputPressed("space") then input = input.." " end

    if (InputPressed("backspace")) then input = string.sub(input,1,#input-1) end

    if InputPressed("return") then
        if (string.gsub(input, " ", "") == "") then
            chatState = false
            return
        end
        sendMessage(input)
        chatState = false
        input = ""
    end
end

function drawChatBox(scale)

    handleKeyInput()

    local open = true
    local w = 500
    local h = 700

    -- chat box
    UiPush()
        UiScale(scale)
        UiColorFilter(1, 1, 1, scale)
        UiColor(0,0,0, 0.5,textboxalpha)
        UiAlign("left top")
        UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
        if InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb")) then
            open = false
        end
    UiPop()

    -- text being input
    UiPush()
        UiFont(font, font_size)
        UiColor(1,1,1,1)
        UiAlign("left")
        UiTranslate(15, h)
        UiText(input)
	UiPop()

    -- chat messages
    UiPush()
        UiFont(font, font_size)
        UiColor(1,1,1,1)
        UiAlign("left")
        UiTranslate(15, 30)
	UiPop()

    return open
end

function draw_chat()
    if chatState == true then
        if gTDMPScale > 0 then
            UiPush()
                UiColor(0.7,0.7,0.7, 0.25*gTDMPScale)
                UiModalBegin()
                if not drawChatBox(gTDMPScale) then
                    SetValue("gTDMPScale", 0, "cosine", 0.25)
                    chatState = false
                end
                UiModalEnd()
            UiPop()
        end
    end


     UiPush()
        UiFont(font, font_size)
        UiColor(nick_color,textalpha)
        UiAlign("left")
        UiTranslate(15, 30)
        if #messages ~= 0 then
            UiText(messages[1][1]..": ")
            UiColor(1,1,1,textalpha)
            UiText((string.rep(" ",#messages[1][1]+2))..messages[1][2])
        end
	UiPop()

    if InputPressed(bindOpenChat) and chatState == false then
        chatState = true
        SetValue("gTDMPScale", 1, "cosine", 0.25)
    end
end

function draw()
    draw_chat()
    if not InputPressed("q") then UiMakeInteractive() end
    drawCreate(1)
end

function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end

gMods = {}
for i=1,3 do
	gMods[i] = {}
	gMods[i].items = {}
	gMods[i].pos = 0
	gMods[i].possmooth = 0
	gMods[i].sort = 0
	gMods[i].filter = 0
	gMods[i].dragstarty = 0
	gMods[i].isdragging = false
end
gMods[1].title = "Built-In"
gMods[2].title = "Subscribed"
gMods[3].title = "Local files"

gModSelectedScale = 0





function drawCreate(scale)
	local open = true
	UiPush()
		local w = 890
		local h = 604 + gModSelectedScale*270
		UiTranslate(UiCenter(), UiMiddle())
		UiScale(scale)
		UiColorFilter(1, 1, 1, scale)
		UiColor(0,0,0, 0.5)
		UiAlign("center middle")
		UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
		UiWindow(w, h)
		UiAlign("left top")
		UiColor(0.96,0.96,0.96)
		if InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb")) then
			open = false
			gMods[1].isdragging = false;
			gMods[2].isdragging = false;
			gMods[3].isdragging = false;
		end

		UiPush()
			UiFont("bold.ttf", 48)
			UiColor(1,1,1)
			UiAlign("center")
			UiTranslate(UiCenter(), 60)
			UiText("MODS")
		UiPop()

		UiPush()

			UiTranslate(30, 220)
			UiPush()
			local i = 2
				UiPush()
					UiFont("bold.ttf", 22)
					UiAlign("left")
					UiText(gMods[i].title)
					UiTranslate(0, 10)
					local h = 338
					if i==2 then
						h = 271
						UiTranslate(0, 32)
					end

					local selected, rmb_pushed = listMods(gMods[i], 500, h, i==2)
					if selected ~= "" then
						selectMod(selected)
						if i==2 then
							updateMods()
						end
					end

					if i == 2 then
						UiPush()
							UiTranslate(40, -11)
							UiFont("regular.ttf", 19)
							UiAlign("center")
							UiColor(1,1,1,0.8)
							UiButtonImageBox("common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
							if UiTextButton("delete firts", 80, 26) then
								table.remove(gMods[2].items,1)
							end
						UiPop()
						UiPush()
							UiTranslate(167, -11)
							UiFont("regular.ttf", 19)
							UiAlign("center")
							UiColor(1,1,1,0.8)
							UiButtonImageBox("common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
						UiPop()
					end

					
				UiPop()
				
				
				UiTranslate(290, 0)
			-- end
			UiPop()

			UiColor(0,0,0,0.1)

			UiTranslate(0, 380)
			
			UiPop()
		UiPop()
	UiPop()

end


function listMods(list, w, h, issubscribedlist)
	local ret = ""
	local rmb_pushed = false
	if list.isdragging and InputReleased("lmb") then
		list.isdragging = false
	end
	UiPush()
		UiAlign("top left")
		UiFont("regular.ttf", 22)

		local mouseOver = UiIsMouseInRect(w+12, h)
		if mouseOver then
			list.pos = list.pos + InputValue("mousewheel")
			if list.pos > 0 then
				list.pos = 0
			end
		end
		if not UiReceivesInput() then
			mouseOver = false
		end

		local itemsInView = math.floor(h/UiFontHeight())
		if #list.items > itemsInView then
			local scrollCount = (#list.items-itemsInView)
			if scrollCount < 0 then scrollCount = 0 end

			local frac = itemsInView / #list.items
			local pos = -list.possmooth / #list.items
			if list.isdragging then
				local posx, posy = UiGetMousePos()
				local dy = 0.0445 * (posy - list.dragstarty)
				list.pos = -dy / frac
			end

			UiPush()
				UiTranslate(w, 0)
				UiColor(1,1,1, 0.07)
				UiImageBox("common/box-solid-4.png", 14, h, 4, 4)
				UiColor(1,1,1, 0.2)

				local bar_posy = 2 + pos*(h-4)
				local bar_sizey = (h-4)*frac
				UiPush()
					UiTranslate(2,2)
					if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then
						list.pos = list.pos + frac * #list.items
					end
					local h2 = h - 4 - bar_sizey - bar_posy
					UiTranslate(0,bar_posy + bar_sizey)
					if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then
						list.pos = list.pos - frac * #list.items
					end
				UiPop()

				UiTranslate(2,bar_posy)
				UiImageBox("common/box-solid-4.png", 10, bar_sizey, 4, 4)
				--UiRect(10, bar_sizey)
				if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
					local posx, posy = UiGetMousePos()
					list.dragstarty = posy
					list.isdragging = true
				end
			UiPop()
			list.pos = clamp(list.pos, -scrollCount, 0)
		else
			list.pos = 0
			list.possmooth = 0
		end

		UiWindow(w, h, true)
		UiColor(1,1,1,0.07)
		UiImageBox("common/box-solid-6.png", w, h, 6, 6)

		UiTranslate(10, 24)
		if list.isdragging then
			list.possmooth = list.pos
		else
			list.possmooth = list.possmooth + (list.pos-list.possmooth) * 10 * GetTimeStep()
		end
		UiTranslate(0, list.possmooth*22)

		UiAlign("left")
		UiColor(0.95,0.95,0.95,1)
		for i=1, #list.items do
			UiPush()
				UiTranslate(10, -18)
				UiColor(0,0,0,0)
				local id = list.items[i].id
				if gModSelected == id then
					UiColor(1,1,1,0.1)
				else
					if mouseOver and UiIsMouseInRect(228, 22) then
						UiColor(0,0,0,0.1)
						if InputPressed("lmb") then
							UiSound("terminal/message-select.ogg")
							ret = id
						end
					end
				end
				if mouseOver and UiIsMouseInRect(228, 22) and InputPressed("rmb") then
					ret = id
					rmb_sel = id;
					rmb_pushed = true
				end
				UiRect(w, 22)
			UiPop()

			UiPush()
				UiTranslate(10, 0)
				if issubscribedlist and list.items[i].showbold then
					UiFont("bold.ttf", 20)
				end
				UiText(list.items[i].name)
			UiPop()
			UiTranslate(0, 22)
		end

		if not rmb_pushed and mouseOver and InputPressed("rmb") then
			rmb_pushed = true
		end

	UiPop()

	return ret, rmb_pushed
end


function updateMods()


	gMods[1].items = {}
	gMods[2].items = {}
	gMods[3].items = {}

	for i=1,15 do
		local mod = {}
		mod.id = i
		mod.name = "name "..i
		mod.active = false
		mod.steamtime = i
		mod.subscribetime = 23 -1
		mod.showbold = false;

		gMods[2].items[#gMods[2].items+1] = mod
	end
			table.sort(gMods[2].items, function(a, b) return a.id < b.id end)
end

updateMods()

--[[ if showBuiltinContextMenu and InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and (InputPressed("lmb") or InputPressed("rmb"))) then
						showBuiltinContextMenu = false
					end ]]