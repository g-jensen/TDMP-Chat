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

-- registry  stuff
if GetInt("savegame.mod.pos_x") == 0 then -- checks if registry has data, if not set default
	SetInt("savegame.mod.textfontsize", 20)
	SetInt("savegame.mod.chat_window_alpha", 75)
	SetInt("savegame.mod.nick.r", 0)
	SetInt("savegame.mod.nick.g", 100)
	SetInt("savegame.mod.nick.b", 0)
	SetInt("savegame.mod.size_h", 10)
	SetInt("savegame.mod.size_w", 75)
    SetInt("savegame.mod.pos_x", 1)
    SetInt("savegame.mod.pos_y", 5)
end
local font = "fonts/UbuntuMono-Regular.ttf"
local window_alpha = GetInt("savegame.mod.chat_window_alpha") / 100
local font_size = GetInt("savegame.mod.textfontsize")
local nicks_color = {GetInt("savegame.mod.nick.r")/100,GetInt("savegame.mod.nick.g")/100,GetInt("savegame.mod.nick.b")/100}
local bindOpenChat = "t"
local chat_log_max = 50
local pos_x = GetInt("savegame.mod.pos_x")/100
local pos_y = GetInt("savegame.mod.pos_y")/100


local char_max_w = GetInt("savegame.mod.size_w")
local char_max_h = GetInt("savegame.mod.size_h")
local char_pixel_w = math.floor((font_size+1)/2)

local b_w = char_max_w * (char_pixel_w) + 14+20 + char_pixel_w
local b_h = char_max_h * (font_size + 4)
local text_w = b_w - 14 - 20
local text_h = b_h
local bg_h = 0

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
TDMP_window.all_lines = 0
TDMP_window.refresh = false
local input_no_lines = 0

-- holding backspace variables
local doBackspace = false
local hasDeleted = false -- has deleted the first time (like pressing backspace once)
local hasInitDeleted = false -- has passed the init delay timer
local del_t = 0; -- delta frames since last backspace
local initDelay = 40; -- amount of frames before quickly deleting
local afterDelay = 5; -- amount of frame between quick deletes

-- TDMP stuff
TDMP_RegisterEvent("MessageSent", function(message)

    decodeMessage(message)
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
end

function draw()
    UiPush()
        UiAlign("center middle")
		UiTranslate((UiWidth()- b_w)*pos_x, (UiHeight()- b_h)*pos_y )
		draw_chat_window(chatState)
	UiPop()
    
end

function tick(dt)
    if clientId then hostHasConnected = true else getNicks() end
    if (hostHasConnected and hasInit ~= true) then server_init() hasInit = true end  -- initializes init when client established connection to server

    if InputPressed(bindOpenChat) and chatState == false then  -- handles opening and closing chat
        chatState = true
    elseif InputPressed("esc") and chatState == true then
        chatState = false
        chat_input = ""
    end

    if doBackspace then del_t = del_t + 1 end
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
    local no_lines = math.floor((#sender + #msg +2) / char_max_w)
    if no_lines < ((#sender + #msg +2) / char_max_w) then no_lines = no_lines + 1 end
    table.insert(chat_messages,{sender,msg,no_lines})
end

function handleKeyInput() -- getting key presses
    doBackspace = InputDown("backspace")
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

    --backspace holding logic
    if (doBackspace) then
        if del_t == 0 and hasInitDeleted == false then
            chat_input = string.sub(chat_input,1,-2)
        end
        --del_t = del_t + 1
            if (hasInitDeleted == false and del_t > initDelay) then
                chat_input = string.sub(chat_input,1,-2)
                hasInitDeleted = true
                del_t = 0
            end
            if hasInitDeleted and del_t > afterDelay then
                chat_input = string.sub(chat_input,1,-2)
                del_t = 0
            end
        -- end
    else
        del_t = 0
        hasInitDeleted = false
    end

    --if (InputPressed("backspace")) then chat_input = string.sub(chat_input,1,-2) end


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

function draw_chat_window(input) --totally not copied and modified script for menu.lua
    if input then
        
        UiMakeInteractive()
        UiModalBegin()
        handleKeyInput()
        input_no_lines = math.floor(#chat_input / char_max_w)
        if input_no_lines < (#chat_input / char_max_w) then input_no_lines = input_no_lines + 1 elseif input_no_lines == 0 then input_no_lines = 1 end
        bg_h = b_h + input_no_lines*font_size + 30
    else 
        bg_h = b_h
    end
	UiPush()
		if not input then UiColorFilter(1, 1, 1, window_alpha) end
		UiColor(0,0,0, 0.5)
		UiAlign("left top")
		UiImageBox("common/box-solid-shadow-50.png", b_w, bg_h, -50, -50)
		UiWindow(b_w, bg_h)
		UiAlign("left top")
		UiColor(0.96,0.96,0.96)

		UiPush()
        if input then
            UiPush()
            UiAlign("left top")
            UiTranslate(0, (text_h + 10))
            UiColor(1,1,1,0.25)
            UiImageBox("common/box-solid-6.png", text_w, (input_no_lines*font_size+20), 6, 6)

            UiFont(font, font_size)
            UiColor(1,1,1,1)
            UiAlign("left middle")
            UiTranslate(10, (font_size+20)/2)
            if #chat_input > 0 then
                if input_no_lines > 1 then
                    for j=1,input_no_lines do
                        if j == 1 then
                            UiText(string.sub(chat_input,1,char_max_w))
                        elseif j == input_no_lines then
                            UiText(string.sub(chat_input,((j-1)*char_max_w+1),-1))
                        else
                            UiText(string.sub(chat_input,((j-1)*char_max_w+1),j*char_max_w))
                        end
                        UiTranslate(0, font_size + 4)
                    end
                else
                    UiText(chat_input)
                end
            end

            UiPop()
        else 
            UiColorFilter(1, 1, 1, window_alpha)
        end

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
                local itemsInView = math.floor(text_h/(font_size + 4))

                if TDMP_window.refresh then
                    if #chat_messages > chat_log_max then
                        table.remove(chat_messages,(#chat_messages-chat_log_max))
                    end
                    TDMP_window.all_lines = 0
                    for i = 1,#chat_messages do
                        TDMP_window.all_lines = TDMP_window.all_lines + chat_messages[i][3]
                    end
                    TDMP_window.pos = - (TDMP_window.all_lines - itemsInView)
                    TDMP_window.refresh = false
                end

                if TDMP_window.all_lines > itemsInView then
                    local scrollCount = (TDMP_window.all_lines-itemsInView)
                    if scrollCount < 0 then scrollCount = 0 end
        
                    local frac = itemsInView / TDMP_window.all_lines
                    local pos = -TDMP_window.possmooth / TDMP_window.all_lines
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
                                TDMP_window.pos = TDMP_window.pos + frac * TDMP_window.all_lines
                            end
                            local h2 = text_h - 4 - bar_sizey - bar_posy
                            UiTranslate(0,bar_posy + bar_sizey)
                            if h2 > 0 and UiIsMouseInRect(10, h2) and InputPressed("lmb") then
                                TDMP_window.pos = TDMP_window.pos - frac * TDMP_window.all_lines
                            end
                        UiPop()
        
                        UiTranslate(2,bar_posy)
                        UiImageBox("common/box-solid-4.png", 10, bar_sizey, 4, 4)
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
                UiTranslate(0, TDMP_window.possmooth*(font_size + 4))
        
                UiAlign("left")
                UiColor(0.95,0.95,0.95,1)

                for i=1, #chat_messages do
                    local no_lines = chat_messages[i][3]
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
                    local nick_char = #chat_messages[i][1] + 2
                    if no_lines > 1 then -- checks number of lines
                        UiPush()
                        for j=1,no_lines do
                            UiPush()
                            if j == 1 then
                                UiColor(nicks_color[1],nicks_color[2],nicks_color[3],1)
                                UiText(chat_messages[i][1]..":") 
                                UiTranslate(char_pixel_w*nick_char, 0)
                                UiColor(1,1,1,1)
                                UiText(string.sub(chat_messages[i][2],1,(char_max_w-nick_char)))
                            elseif j == no_lines then
                                UiColor(1,1,1,1)
                                UiText(string.sub(chat_messages[i][2],((j-1)*char_max_w+1-nick_char),-1))
                            else
                                UiColor(1,1,1,1)
                                UiText(string.sub(chat_messages[i][2],((j-1)*char_max_w+1-nick_char),((j*char_max_w)-nick_char)))
                            end
                            UiPop()
                            UiTranslate(0, font_size + 4)
                        end
                    else 
                        UiPush()
                        UiColor(nicks_color[1],nicks_color[2],nicks_color[3], 1)
                        UiText(chat_messages[i][1]..":") 
                        UiTranslate(char_pixel_w*nick_char, 0)
                        UiColor(1,1,1,1)
                        UiText(chat_messages[i][2])
                        UiPop()
                        UiTranslate(0, font_size + 4)
                    end
                    
                end
        
                if not rmb_pushed and mouseOver and InputPressed("rmb") then
                    rmb_pushed = true
                end
        
            UiPop()
		UiPop()
	UiPop()
    UiPop()

end
