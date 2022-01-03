--[[ TODO:
    -add movable cursor
        -add del button
    -preety it up
    -add selecting by shift
    -add jumping cursor by ctrl
        -add selecting by shift + crtl
    -add options.lua
        -font size
        -buffer size
        -position
        -death messages

]]


#include "tdmp/networking.lua"
#include "tdmp/player.lua"
#include "tdmp/hooks.lua"
#include "tdmp/json.lua"



if GetInt("savegame.mod.textfontsize") == 0 then -- checks if registry has data
    DebugPrint("set def")
  	SetInt("savegame.mod.textfontsize", 20)
	  SetInt("savegame.mod.textalpha", 50)
	  SetInt("savegame.mod.textboxalpha", 50)
end
DebugPrint(GetInt("savegame.mod.textfontsize"))
DebugPrint("works?")

local keys = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "1","2","3","4","5","6","7","8","9","0",
        "-","+",",","."}
local keys_shifted = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
                "!","@","#","$","%","^","&","*","(",")",
                "_","DO NOT USE","<",">"}


-- font info
local font = "fonts/UbuntuMono-Regular.ttf"
local textalpha = GetInt("savegame.mod.textalpha") / 100
local textboxalpha = GetInt("savegame.mod.textboxalpha") / 100
local font_size = GetInt("savegame.mod.textfontsize")

-- TDMP checker
local TDMP_present = false
if TDMP_LocalSteamId then TDMP_present = true end
if TDMP_present == false then 
    DebugPrint("[TDMP Chat] TDMP is not present, chat mod will be disbled") 
end

-- holds the characters being input in the chat box
local buffer = ""
local payload = "" -- stuff we send to server

local bindOpenChat = "t"

local nicks = {} --holds TDMP ids and coresponding nick

--local clientNick = nil -- holds nick for players
--local client_steamId = nil -- holds nick for players
local client_id = nil -- hold this client TDMP id

-- chatState - if chat input is open
local chatState = false
local chat_messages_buffer = {}

gTDMPScale = 0


-- tick function just gets the client nickname for now

function tick_chat()

    --workaround for initializing stuff after host connects
    if client_id then return end
    for i, ply in ipairs(TDMP_GetPlayers()) do
        nicks[ply.id] = ply.nick
        if TDMP_IsMe(ply.id) then
            --clientNick = ply.nick
            --client_steamId = ply.steamId
            client_id = ply.id
            break
        end
    end
end

function tick()
    if TDMP_present then tick_chat() end --only run chat script id TDMP is present
end

function update(dt)
end

if TDMP_present then
    TDMP_RegisterEvent("MessageSent", function(message)
        decode_msg(message)
        if not TDMP_IsServer() then
            return
        end -- if not a host stop

    TDMP_ServerStartEvent("MessageSent", {
        Receiver = TDMP.Enums.Receiver.ClientsOnly,
        Reliable = true,

        DontPack = true,
        Data = message
        })
    end)
end

function chat_box_interactive()
    UiMakeInteractive()
    for i=1,#keys,1 do
        if InputPressed(keys[i]) and i ~= 38 then
              if InputDown("shift") then
                  buffer = buffer..keys_shifted[i]
              else
                  buffer = buffer..keys[i]
              end
        elseif InputPressed(keys[i]) and i == 38 then --fixes weird =/+ handling
            if InputDown("shift") then 
                buffer = buffer.."+"
            else
                buffer = buffer.."="
            end
        end
    end
    if InputPressed("space") then
        buffer = buffer.." "
    end

    if InputPressed("return") then
        if (string.gsub(buffer, " ", "") == "") then
            chatState = false
            return
        end
        payload = tostring(client_id)..buffer
        TDMP_ClientStartEvent("MessageSent", {
            Receiver = TDMP.Enums.Receiver.ClientsOnly,
            Reliable = true,

            DontPack = true,
            Data = payload
        })
        chatState = false
        buffer = ""
    end

    if (InputPressed("backspace")) then
        buffer = string.sub(buffer,1,#buffer-1)
    end
end

function drawChatBox(scale)

    chat_box_interactive()

    local open = true
    local w = 500
    local h = 700

    -- chat box
    UiPush()
        UiScale(scale)
        UiColorFilter(1, 1, 1, scale)
        UiColor(0,0,0, textboxalpha)
        UiAlign("left top")
        UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
        if InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb")) then
            open = false
        end
    UiPop()

    -- text being input
    UiPush()
        UiFont(font, font_size)
        UiColor(1,1,1)
        UiAlign("left")
        UiTranslate(15, h)
        UiText(buffer)
	UiPop()

    -- chat messages
    UiPush()
        UiFont(font, font_size)
        UiColor(1,1,1)
        UiAlign("left")
        UiTranslate(15, 30)
        local text = ""
        for i=#chat_messages_buffer,1,-1 do
            text = text..chat_messages_buffer[i].."\n"
        end
        if #chat_messages_buffer > 20 then table.remove(chat_messages_buffer,1) end
        UiText(text)
	UiPop()

    return open
end

function draw_chat(dt)
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
        UiColor(1,1,1,textaplha)

        UiAlign("left")
        UiTranslate(15, 30)
        local text = ""
        for i=#chat_messages_buffer,#chat_messages_buffer-4,-1 do
            if (i > 0) then
                text = text..chat_messages_buffer[i].."\n"
            end
        end
        UiText(text)
	UiPop()

    if InputPressed(bindOpenChat) and chatState == false then
        chatState = true
        SetValue("gTDMPScale", 1, "cosine", 0.25)
    end
end

function draw()
    if TDMP_present then draw_chat() end
end

function decode_msg(msg_in)
    local decoded_msg = ""
    local sender_id = tonumber(string.sub(msg_in, 1, 1))
    local msg = string.sub(msg_in, 2, -1)
    decoded_msg = nicks[sender_id]..": "..msg
    table.insert(chat_messages_buffer,decoded_msg)
end