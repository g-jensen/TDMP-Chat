--[[ TODO:
      -add movable cursor
        -add del button
      -preety it up
      -add selecting by shift
      -add jumping cursor by ctrl
        -add selecting by shift + crtl

]]


#include "tdmp/networking.lua"
#include "tdmp/player.lua"
#include "tdmp/hooks.lua"
#include "tdmp/json.lua"

if not TDMP_LocalSteamId then DebugPrint("[TDMP Chat] TDMP is not present, chat mod will be disbled") return end

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

local font = "fonts/UbuntuMono-Regular.ttf"
local textalpha = 1 --GetInt("savegame.mod.textalpha") / 100
local textboxalpha = 0.5 --GetInt("savegame.mod.textboxalpha") / 100
local font_size = 28 --GetInt("savegame.mod.textfontsize")

-- chatState can be false or true
local chatState = false
local messages = {}

gTDMPScale = 0

local clientNick = nil
local clientId = nil
local nicks = {}

local hasInit = false
local hostHasConnected = false

function init()
end

function update(dt)
end

function tick(dt)
    if clientNick then hostHasConnected = true else getNicks() end
    if (hostHasConnected and hasInit ~= true) then server_init() hasInit = true end

end

TDMP_RegisterEvent("MessageSent", function(message)

    decodeMessage(message)

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

function getNicks()
    for i, ply in ipairs(TDMP_GetPlayers()) do
        nicks[ply.id] = ply.nick
        if TDMP_IsMe(ply.id) then
            clientNick = ply.nick
            clientId = ply.id
        end
    end
end

-- server is initialized
function server_init() 
    chat_msg["sender_id"] = clientId
    
    for i=0,#nicks,1 do
        DebugPrint(nicks[i])
    end
end

function sendMessage(message) 
    chat_msg["msg"] = input
    TDMP_ClientStartEvent("MessageSent", {
        Receiver = TDMP.Enums.Receiver.ClientsOnly,
        Reliable = true,

        DontPack = false,
        Data = {chat_msg["msg"],chat_msg["sender_id"]}
    })
end

function decodeMessage(message)
    message = json.decode(message)
    local msg = message[1]
    local sender = ""
    for i, ply in ipairs(TDMP_GetPlayers()) do
        if (ply.id == message[2]) then
            sender = ply.nick
            break
        end
    end

    table.insert(messages,sender..": "..msg)
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
    if InputPressed("space") then
        input = input.." "
    end

    if (InputPressed("backspace")) then
        input = string.sub(input,1,#input-1)
    end

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
        UiColor(1,1,1,textalpha)
        UiAlign("left")
        UiTranslate(15, h)
        UiText(input)
	UiPop()

    -- chat messages
    UiPush()
        UiFont(font, font_size)
        UiColor(1,1,1,textalpha)
        UiAlign("left")
        UiTranslate(15, 30)
        local text = ""
        for i=#messages,1,-1 do
            text = text..messages[i].."\n"
        end
        if #messages > 20 then table.remove(messages,1) end
        UiText(text)
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
        UiColor(1,1,1,textalpha)
        UiAlign("left")
        UiTranslate(15, 30)
        local text = ""
        for i=#messages,#messages-4,-1 do
            if (i > 0) then
                text = text..messages[i].."\n"
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
    draw_chat()
end
