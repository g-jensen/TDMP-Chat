--[[ TODO:
    -add movable cursor (some code already in place for supporting it)
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
local chat_input = ""

-- registry (or to be registry) stuff
if GetInt("savegame.mod.textfontsize") == 0 then -- checks if registry has data, if not set default
	SetInt("savegame.mod.textfontsize", 20)
	SetInt("savegame.mod.textalpha", 80)
	SetInt("savegame.mod.textboxalpha", 50)
end
local font = "fonts/UbuntuMono-Regular.ttf"
local textalpha = GetInt("savegame.mod.textalpha") / 100
local textboxalpha = GetInt("savegame.mod.textboxalpha") / 100
local font_size = GetInt("savegame.mod.textfontsize")
local nicks_color = {1,0.5,2}
local bindOpenChat = "t"



-- chatState can be false or true
local chatState = false
local chat_messages = {}

local nicks = {}

local hasInit = false
local hostHasConnected = false

-- chat log window variables
local TDMP_window = {}
TDMP_window.pos = 0
TDMP_window.possmooth = 0
TDMP_window.dragstarty = 0
TDMP_window.isdragging = false
local n_w = 600
local n_h = 220
local TDMP_chat_scale = 1

-- holding backspace variables
local doBackspace = false

-- has deleted the first time (like pressing backspace once)
local hasDeleted = false

-- has passed the init delay timer
local hasInitDeleted = false

-- delta frames since last backspace
local dt = 0;

-- amount of frames before quickly deleting
local initDelay = 40;

-- amount of frame between quick deletes
local afterDelay = 5;

-- TDMP stuff
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


function init()
end

function update(dt)
end

-- server is initialized
function server_init() 
    DebugPrint("serv init")
    --SetValue("TDMP_chat_scale", 1, "easein", 2)
end

function draw()
    draw_chat_window(TDMP_chat_scale, chatState)
end

function tick(dt)
    if clientId then hostHasConnected = true else getNicks() end
    if (hostHasConnected and hasInit ~= true) then server_init() hasInit = true end


    if InputPressed("q") then table.insert(chat_messages, {"ni"..#chat_messages, "msg"..#chat_messages}) end

    if InputPressed(bindOpenChat) and chatState == false then
        chatState = true
    elseif InputPressed("esc") and chatState == true then
        chatState = false
        chat_input = ""
    end

end


function getNicks()
    for i, ply in ipairs(TDMP_GetPlayers()) do
        nicks[ply.id] = ply.nick
        if TDMP_IsMe(ply.id) then
            clientId = ply.id
        end
    end
end




function decodeMessage(message)
    message = json.decode(message)
    local msg = message[1]
    local sender = nicks[message[2]]
    table.insert(chat_messages,{sender,msg})
end



function handleKeyInput()

    doBackspace = InputDown("backspace");

    -- UiMakeInteractive()
    SetBool("game.disablepause", true)
    for i=1,#keys,1 do
        if InputPressed(keys[i]) and i ~= 38 then
              if InputDown("shift") then
                chat_input = chat_input..keys_shifted[i]
              else
                chat_input = chat_input..keys[i]
              end
        elseif InputPressed(keys[i]) and i == 38 then
            if InputDown("shift") then --fixes weird =/+ handling
                chat_input = chat_input.."+"
            else
                chat_input = chat_input.."="
            end
        end
    end

    if InputPressed("space") then chat_input = chat_input.." " end

    --backspace holding logic
    if (doBackspace) then
        dt = dt + 1
        if (hasDeleted == false) then
            chat_input = string.sub(chat_input,1,#chat_input-1)
            hasDeleted = true;
            dt = 0
        else
            if (hasInitDeleted == false and dt > initDelay) then
                chat_input = string.sub(chat_input,1,#chat_input-1)
                hasInitDeleted = true
                dt = 0
            end
            if hasInitDeleted and dt > afterDelay then
                chat_input = string.sub(chat_input,1,#chat_input-1)
                dt = 0
            end
        end
    else
        dt = 0
    end

    if InputPressed("return") then
        if (string.gsub(chat_input, " ", "") == "") then
            chatState = false
            return
        end

        TDMP_ClientStartEvent("MessageSent", {
            Receiver = TDMP.Enums.Receiver.ClientsOnly,
            Reliable = true,
            DontPack = false,
            Data = {chat_input,clientId}
        })

        chatState = false
        chat_input = ""
    end
end

--[[ function drawChatBox(scale)

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
end ]]

--[[ function draw_chat()
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
        UiColor(nicks_color,textalpha)
        UiAlign("left")
        UiTranslate(15, 30)
        if #messages ~= 0 then
            UiText(messages[1][1]..": ")
            UiColor(1,1,1,textalpha)
            UiText((string.rep(" ",#messages[1][1]+2))..messages[1][2]) -- TODO: redo it with UiSize or smthing (see TD API)
        end
	UiPop()

    if InputPressed(bindOpenChat) and chatState == false then
        chatState = true
        SetValue("gTDMPScale", 1, "cosine", 0.25)
    end
end ]]



function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end


function draw_chat_window(scale, input) --totally not copied and modified script for menu.lua
    --UiMakeInteractive()
    
    local b_w = n_w
    local b_h = n_h
    local text_w = n_w - 14 - 20
    local text_h = n_h - 10
    -- local itemsInView = math.floor(text_h/UiFontHeight())
    --[[ UiPush()
    UiFont(font, font_size)
    local scroll_bar = (#messages > itemsInView)
    UiPop()
    DebugWatch("scroll bar: ",scroll_bar) ]]
    --if not scroll_bar then text_w = n_w end
    if input then
        
        UiMakeInteractive()
        UiModalBegin()
        b_h = n_h + 60
    end
	UiPush()
		UiTranslate(100, 150)
		UiScale(scale)
		UiColorFilter(1, 1, 1, scale)
		UiColor(0,0,0, 0.5)
		UiAlign("left top")
		UiImageBox("common/box-solid-shadow-50.png", b_w, b_h, -50, -50)
		UiWindow(b_w, b_h)
		UiAlign("left top")
		UiColor(0.96,0.96,0.96)

		UiPush()
        if input then
            
            handleKeyInput()
            UiPush()
            UiAlign("left top")
            UiTranslate(0, (text_h + 20))
            UiColor(1,1,1,0.25)
            UiImageBox("common/box-solid-6.png", text_w, 40, 6, 6)

            UiFont(font, font_size)
            UiColor(1,1,1,1)
            UiAlign("left middle")
            UiTranslate(10, 20)
            UiText(chat_input)



            UiPop()
        end
        --UiTranslate(0, 10)

            if TDMP_window.isdragging and InputReleased("lmb") then
                TDMP_window.isdragging = false
            end
            UiPush()
                UiAlign("top left")
                UiFont(font, font_size)
                local mouseOver = UiIsMouseInRect(text_w, text_h)
                if mouseOver then
                    TDMP_window.pos = TDMP_window.pos + InputValue("mousewheel")
                    if TDMP_window.pos > 0 then
                        TDMP_window.pos = 0
                    end
                end
                if not UiReceivesInput() then
                    mouseOver = false
                end
                local text_w_font, text_h_font = UiGetTextSize("Some text")
                local itemsInView = math.floor(text_h/text_h_font)
                if #chat_messages > itemsInView then
                    local scrollCount = (#chat_messages-itemsInView)
                    if scrollCount < 0 then scrollCount = 0 end
        
                    local frac = itemsInView / #chat_messages
                    local pos = -TDMP_window.possmooth / #chat_messages
                    if TDMP_window.isdragging then
                        local posx, posy = UiGetMousePos()
                        local dy = 0.0445 * (posy - TDMP_window.dragstarty)
                        TDMP_window.pos = -dy / frac
                    end
        
                    UiPush()
                        UiTranslate(text_w, 0)
                        UiColor(1,1,1, 0.07)
                        UiImageBox("common/box-solid-4.png", 14, text_h, 4, 4)
                        UiColor(1,1,1, 0.2)
        
                        local bar_posy = 2 + pos*(text_h-4)
                        local bar_sizey = (text_h-4)*frac
                        UiPush()
                            UiTranslate(2,2)
                            if bar_posy > 2 and UiIsMouseInRect(8, bar_posy-2) and InputPressed("lmb") then
                                TDMP_window.pos = TDMP_window.pos + frac * #chat_messages
                            end
                            local h2 = text_h - 4 - bar_sizey - bar_posy
                            UiTranslate(0,bar_posy + bar_sizey)
                            if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then
                                TDMP_window.pos = TDMP_window.pos - frac * #chat_messages
                            end
                        UiPop()
        
                        UiTranslate(2,bar_posy)
                        UiImageBox("common/box-solid-4.png", 10, bar_sizey, 4, 4)
                        --UiRect(10, bar_sizey)
                        if UiIsMouseInRect(10, bar_sizey) and InputPressed("lmb") then
                            local posx, posy = UiGetMousePos()
                            TDMP_window.dragstarty = posy
                            TDMP_window.isdragging = true
                        end
                    UiPop()
                    TDMP_window.pos = clamp(TDMP_window.pos, -scrollCount, 0)
                else
                    TDMP_window.pos = 0
                    TDMP_window.possmooth = 0
                end
        
                UiWindow(text_w, text_h, true)
                UiColor(1,1,1,0.07)
                UiImageBox("common/box-solid-6.png", text_w, text_h, 6, 6)
        
                UiTranslate(10, 24)
                if TDMP_window.isdragging then
                    TDMP_window.possmooth = TDMP_window.pos
                else
                    TDMP_window.possmooth = TDMP_window.possmooth + (TDMP_window.pos-TDMP_window.possmooth) * 10 * GetTimeStep()
                end
                UiTranslate(0, TDMP_window.possmooth*22)
        
                UiAlign("left")
                UiColor(0.95,0.95,0.95,1)
                for i=1, #chat_messages do
                    --[[ UiPush()
                        UiTranslate(10, -18)
                        UiColor(0,0,0,0)
                        local id = i
                        if gModSelected == id then
                            UiColor(1,1,1,0.1)
                        else
                            if mouseOver and UiIsMouseInRect(228, 22) then
                                UiColor(0,0,0,0.1)
                            end
                        end
                        if mouseOver and UiIsMouseInRect(228, 22) and InputPressed("rmb") then
                            ret = id
                            rmb_pushed = true
                        end
                        UiRect(w, 22)
                    UiPop() ]] -- FEAUTURE: if we need selecting msg try using this
        
                    UiPush()
                        -- UiTranslate(10, 0)
                        --UiFont("bold.ttf", 20)
                    UiColor(nicks_color, 1)
                    UiText(chat_messages[i][1]..":") 
                    UiTranslate(UiGetTextSize(chat_messages[i][1]..': '), 0)
                    UiColor(1,1,1,1)
                    UiText(chat_messages[i][2])
                    UiPop()
                    UiTranslate(0, 22)
                end
        
                if not rmb_pushed and mouseOver and InputPressed("rmb") then
                    rmb_pushed = true
                end
        
            UiPop()

						--[[ UiPush()
							UiTranslate(40, -11)
							UiFont("regular.ttf", 19)
							UiAlign("center")
							UiColor(1,1,1,0.8)
							UiButtonImageBox("common/box-solid-4.png", 4, 4, 1, 1, 1, 0.1)
							if UiTextButton("delete firts", 80, 26) then
								table.remove(chat_messages,1)
							end
						UiPop() ]]
		UiPop()
	UiPop()

end
