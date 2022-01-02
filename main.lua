--This script will run on all levels when mod is active.
--Modding documentation: http://teardowngame.com/modding
--API reference: http://teardowngame.com/modding/api.html

--if not TDMP_LocalSteamId then DebugPrint("[TDMP Chat] TDMP Isn't launched!") return end

#include "tdmp/networking.lua"
#include "tdmp/player.lua"
#include "tdmp/hooks.lua"
#include "tdmp/json.lua"

if TDMP_LocalSteamId then local TDMP_present = true else local TDMP_present = false end

local keys = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","y","u","z",
        "1","2","3","4","5","6","7","8","9","0",
        "-","+",",","."}
local keys_shifted = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
                "!","@","#","$","%","^","&","*","(",")",
                "_","=","<",">"}

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
function tick(dt)
    if clientNick then return end

    for i, ply in ipairs(TDMP_GetPlayers()) do
        if TDMP_IsMe(ply.id) then
            clientNick = ply.nick
            break
        end
    end
end

function update(dt)
end

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

function handleKeyInput()
    UiMakeInteractive()
    for i=1,#keys,1 do
      --print(i)
      if InputPressed(keys[i]) --[[and clicked == false]] then
        print(keys[i])
        if InputDown("shift") then
          chat_msg = chat_msg..keys_shifted[i]
        else
          chat_msg = chat_msg..keys[i]
        end
        --clicked = true
      elseif not InputDown("any") and clicked == true then
        --clicked = false
      end
    end
    if InputPressed("space") then
      print("space")
      chat_msg = chat_msg.." "
    end


    if InputPressed("return") then
      print("enter lol")
      chat_msg = clientNick..": "..chat_msg
      TDMP_ClientStartEvent("MessageSent", {
          Receiver = TDMP.Enums.Receiver.ClientsOnly,
          Reliable = true,

          DontPack = true,
          Data = chat_msg
      })
      --chat_input = false
      chatState = false
      chat_msg = ""
    end

    if (InputPressed("backspace")) then
        chat_msg = string.sub(chat_msg,1,#chat_msg-1)
    end


    --local enter = InputPressed("return")

  --[[
    if (enter or InputPressed("esc")) then
        if (chat_msg ~= "" and enter) then
            chat_msg = clientNick..": "..chat_msg
            TDMP_ClientStartEvent("MessageSent", {
                Receiver = TDMP.Enums.Receiver.ClientsOnly,
                Reliable = true,

                DontPack = true,
                Data = chat_msg
            })
        end
        chat_msg = ""
        chatState = false
    end
    ]]
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

function draw(dt)
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
