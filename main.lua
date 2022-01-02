--This script will run on all levels when mod is active.
--Modding documentation: http://teardowngame.com/modding
--API reference: http://teardowngame.com/modding/api.html

local alphabet = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}
local numbers = {'0','1','2','3','4','5','6','7','8','9'}
local input = ""
local bindOpenChat = "t"
local chatState = "default"
local messages = {}
gTDMPScale = 0

function init()
end

function tick(dt)
end


function update(dt)
end

function handleKeyPress()
    UiMakeInteractive()
    for i=1,#alphabet,1 do
        local key = alphabet[i]
        if InputPressed(key) then
            input = input..key
        end
    end

    for i=1,#numbers,1 do
        local key = numbers[i]
        if InputPressed(key) then
            input = input..key
        end
    end
    
    if (InputPressed("space")) then
        input = input.." "
    end

    if (InputPressed("backspace")) then
        input = string.sub(input,1,#input-1)
    end

    if (InputPressed("return") or InputPressed("esc")) then 
        if (input ~= "") then table.insert(messages,input) end
        input = ""
        chatState = "default"
    end
end

function drawChatBox(scale)

    handleKeyPress()

    local open = true
    local w = 500
    local h = 700

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

    UiPush()
        UiFont("bold.ttf", 32)
        UiColor(1,1,1)
        UiAlign("left")
        UiTranslate(15, h)
        UiText(input)
	UiPop()

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
    if chatState == "typing" then
        if gTDMPScale > 0 then
            UiPush()
                UiColor(0.7,0.7,0.7, 0.25*gTDMPScale)
                UiModalBegin()
                if not drawChatBox(gTDMPScale) then
                    SetValue("gTDMPScale", 0, "cosine", 0.25)
                    chatState = "default"
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

    if InputPressed(bindOpenChat) and chatState == "default" then
        chatState = "typing"
        SetValue("gTDMPScale", 1, "cosine", 0.25)
    end
end