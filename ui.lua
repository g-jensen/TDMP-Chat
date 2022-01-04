#include "globals.lua"

local gTDMPScale = 0
local bindOpenChat = "t"

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
        UiColor(0,0,0,textboxalpha)
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