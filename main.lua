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

local TDMP_present = false
if TDMP_LocalSteamId then TDMP_present = true end

local keys = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "1","2","3","4","5","6","7","8","9","0",
        "-","+",",","."}
local keys_shifted = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
                "!","@","#","$","%","^","&","*","(",")",
                "_","DO NOT USE","<",">"}

-- holds the characters being input in the chat box
local chat_msg = ""

local bindOpenChat = "t"

-- chatState can be false or true
local chatState = false
local messages = {}

gTDMPScale = 0

function init()
    if TDMP_present == false then DebugPrint("[TDMP Chat] TDMP is not present, chat mod will be disbled") end
end

-- tick function just gets the client nickname for now
local clientNick = nil
function tick_chat(dt)
    if clientNick then return end

    for i, ply in ipairs(TDMP_GetPlayers()) do
        if TDMP_IsMe(ply.id) then
            clientNick = ply.nick
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
        table.insert(messages,message)
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

function handleKeyInput()
    UiMakeInteractive()
    for i=1,#keys,1 do
        if InputPressed(keys[i]) and i ~= 38 then
              if InputDown("shift") then
                  chat_msg = chat_msg..keys_shifted[i]
              else
                  chat_msg = chat_msg..keys[i]
              end
        elseif InputPressed(keys[i]) and i == 38 then
            if InputDown("shift") then --fixes weird =/+ handling
                chat_msg = chat_msg.."+"
            else
                chat_msg = chat_msg.."="
            end
        end
    end
    if InputPressed("space") then
        chat_msg = chat_msg.." "
    end


    if InputPressed("return") then
        if (string.gsub(chat_msg, " ", "") == "") then
            chatState = false
            return
        end
        chat_msg = clientNick..": "..chat_msg
        TDMP_ClientStartEvent("MessageSent", {
            Receiver = TDMP.Enums.Receiver.ClientsOnly,
            Reliable = true,

            DontPack = true,
            Data = chat_msg
        })
        chatState = false
        chat_msg = ""
    end

    if (InputPressed("backspace")) then
        chat_msg = string.sub(chat_msg,1,#chat_msg-1)
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
        UiColor(0,0,0, 0.5)
        UiAlign("left top")
        UiImageBox("common/box-solid-shadow-50.png", w, h, -50, -50)
        if InputPressed("esc") or (not UiIsMouseInRect(UiWidth(), UiHeight()) and InputPressed("lmb")) then
            open = false
        end
    UiPop()

    -- text being input
    UiPush()
        UiFont("bold.ttf", 32)
        UiColor(1,1,1)
        UiAlign("left")
        UiTranslate(15, h)
        UiText(chat_msg)
	UiPop()

    -- chat messages
    UiPush()
        UiFont("bold.ttf", 32)
        UiColor(1,1,1)
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
        UiFont("bold.ttf", 32)
        UiColor(1,1,1)
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
    if TDMP_present then draw_chat() end
end
