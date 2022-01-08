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

local char_max_w = 9
local char_max_h = 6


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
TDMP_window.refresh = false
local n_w = 600                     -- TODO: change to font_size and character per line not pixels
local n_h = 220
local TDMP_chat_scale = 1

-- TDMP stuff
TDMP_RegisterEvent("MessageSent", function(message)

    decodeMessage(message)
    DebugPrint(message)
    TDMP_window.refresh = true

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
    if (hostHasConnected and hasInit ~= true) then server_init() hasInit = true end  -- initializes init when client established connection to server


    if InputPressed("q") then table.insert(chat_messages, {"ni"..#chat_messages, "msg"..#chat_messages}) end

    if InputPressed(bindOpenChat) and chatState == false then  -- handles opening and closing chat
        chatState = true
    elseif InputPressed("esc") and chatState == true then
        chatState = false
        chat_input = ""
    end

end

function getNicks() -- well self explanatory
    for i, ply in ipairs(TDMP_GetPlayers()) do
        nicks[ply.id] = ply.nick
        if TDMP_IsMe(ply.id) then
            clientId = ply.id
        end
    end
end

function decodeMessage(message) -- decodes json into arrat{tdmp_id, message}
    message = json.decode(message)
    local msg = message[1]
    local sender = nicks[message[2]]
    table.insert(chat_messages,{sender,msg})
end

function handleKeyInput() -- getting key presses
    SetBool("game.disablepause", true)  -- disables "esc" pause menu
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

    if (InputPressed("backspace")) then chat_input = string.sub(chat_input,1,-2) end

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

function clamp(value, mi, ma) 
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end


function draw_chat_window(scale, input) --totally not copied and modified script for menu.lua
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
		UiTranslate(UiMiddle(), 150)
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
                local char_pixel_w, char_pixel_h = UiGetTextSize("x")
                local itemsInView = math.floor(text_h/char_pixel_h)
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

                if #chat_messages > itemsInView and TDMP_window.refresh then
                    TDMP_window.pos = - (#chat_messages - itemsInView)
                    TDMP_window.refresh = false
                end

                DebugWatch("pos: ",TDMP_window.pos)              -- this is the key forauto scroll
                -- DebugWatch("scrollCount: ", scrollCount)
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
                    UiPop() ]]                                      -- FEAUTURE MAYBE: if we need selecting msg try using this
                    
                    local no_lines = math.floor((#chat_messages[i][1] + #chat_messages[i][2]) / char_max_w)
                    if no_lines < ((#chat_messages[i][1] + #chat_messages[i][2]) / char_max_w) then no_lines = no_lines + 1 end


                    -- DebugPrint((#chat_messages[i][1] + #chat_messages[i][2]) / char_max_w)
                    -- DebugPrint(no_lines)
                    if no_lines > 1 then -- checks number of lines
                        --local current_line = ""
                        local nick_char = #chat_messages[i][2] + 2
                        UiPush()
                        for j=1,no_lines do
                            UiPush()
                            if j == 1 then
                                UiColor(nicks_color, 1)
                                UiText(chat_messages[i][1]..":") 
                                UiTranslate(UiGetTextSize(chat_messages[i][1]..': '), 0)
                                UiColor(1,1,1,1)
                                --UiText(chat_messages[i][2])
                                UiText(string.sub(chat_messages[i][2],1,(char_max_w-nick_char)))
                                -- UiTranslate(0, 22)
                                -- string.sub(chat_input,1,#chat_input-1)
                            elseif j == no_lines then
                                UiColor(1,1,1,1)
                                --UiText(chat_messages[i][2])
                                UiText(string.sub(chat_messages[i][2],((j-1)*char_max_w+1-nick_char),-1))
                                -- UiTranslate(0, 22)
                            else
                                UiColor(1,1,1,1)
                                --UiText(chat_messages[i][2])
                                UiText(string.sub(chat_messages[i][2],((j-1)*char_max_w+1-nick_char),((j*char_max_w)-nick_char)))
                                -- UiTranslate(0, 22)
                            end
                            UiPop()
                            UiTranslate(0, 22)
                        end

                        --UiTranslate(UiGetTextSize(chat_messages[i][1]..': '), 0)
                        
                        --UiWordWrap(200)
                        --UiText(chat_messages[i][2])
                        
                        --UiTranslate(0, 22)
                    else 
                        UiPush()
                        -- UiTranslate(10, 0)
                        --UiFont("bold.ttf", 20)
                        UiColor(nicks_color, 1)
                        UiText(chat_messages[i][1]..":") 
                        UiTranslate(UiGetTextSize(chat_messages[i][1]..': '), 0)
                        UiColor(1,1,1,1)
                        --UiWordWrap(200)
                        UiText(chat_messages[i][2])
                        UiPop()
                        UiTranslate(0, 22)
                    end
                    
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
