-- it's quick and dirty, don't even bother
-- needs rework in some time if it breaks or new features



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
local TDMP_window = {}
TDMP_window.pos = 0
TDMP_window.possmooth = 0
TDMP_window.dragstarty = 0
TDMP_window.isdragging = false
TDMP_window.all_lines = 0
local chat_messages = {{"test1","1234 1234 1234 1234 1234 1234 1234 1234 12345",1},{"nick2","eee",1},{"test3","lol",1},{"nick4","eee",1},{"test5","lol",1},{"nick6","eee",1},{"test7","lol",1},{"nick8","eee",1},{"test1","lol",1},{"nick2","eee",1},{"test3","lol",1},{"nick4","eee",1},{"test5","lol",1},{"nick6","eee",1},{"test7","lol",1},{"nick8","eee",1}}
local typing = false
local font_size = 0

function optionsSlider(setting, mi, ma)
	UiColor(1,1,0.5)
	UiPush()
        UiColor(1,1,0.5)
		--UiTranslate(0, -8)
		local val = GetInt(setting)
		val = (val-mi) / (ma-mi)
		local w = 100
		UiRect(w, 3)
		UiAlign("center middle")

        UiPush()
            --UiTranslate(-50,0)
		    val = UiSlider("common/dot.png", "x", val*w, 0, w) / w
        UiPop()

		val = math.floor(val*(ma-mi)+mi)
		SetInt(setting, val)
	UiPop()
	return val
end

function optionsInputDesc(op, key, x1,mapinput)
	UiPush()
		if mapinput then
			UiAlign("left")
			UiTranslate(x1,-10)
			if UiIsMouseInRect(230, 20) and InputPressed("lmb") then
				mapCurInput = key;
			end
			if mapCurInput == key then
				local str = InputLastPressedKey()
				if str ~= "" and str ~= "tab" and str~= "esc" and tonumber(str) == nil then
					mapCurInput = ""
					SetString(key,str)
				end
				UiColor(1,1,1,0.2)
			else
				UiColor(1,1,1,0.1)
			end
			UiRect(230, 20)
		end
	UiPop()
	UiPush()
        UiFont("bold.ttf", 32)
		UiText(op)
		UiTranslate(x1,0)
		UiAlign("left")
		UiColor(0.7,0.7,0.7)
		if mapinput then
			UiText(string.upper(GetString(key)))
		else
			UiText(key)
		end
	UiPop()
	UiTranslate(0, UiFontHeight())
end

function draw()
	UiImage("MOD/example.jpg")
	UiPush()
        UiAlign("center middle")
        font_size = GetInt("savegame.mod.textfontsize")
        local win_w = GetInt("savegame.mod.size_w") * (math.floor((font_size+1)/2)) + 14+20 + math.floor((font_size+1)/2)
        local win_h = GetInt("savegame.mod.size_h") * (font_size + 4)
		UiTranslate((UiWidth()- win_w)*GetInt("savegame.mod.pos_x")/100 , (UiHeight()- win_h)*GetInt("savegame.mod.pos_y")/100 )
		draw_chat_window()
	UiPop()

	
	
	draw_options()
end

function draw_options()
    local x1 = 120

	UiTranslate(UiCenter(), UiMiddle())
	UiAlign("center middle")
	UiColor(0,0,0, 0.55)
	UiImageBox("common/box-solid-shadow-50.png", 600, 800, -50, -50)
	UiColor(1,1,1,1)
	UiTranslate(0,-300)

	--Title
	UiFont("bold.ttf", 48)
	UiText("TDMP Chat options")

    UiTranslate(0,100)
    
    UiPush()
	UiFont("bold.ttf", 32)
        UiTranslate(-100,0)

        UiPush()
            UiText("Characters horizontal")
            UiTranslate(200, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.size_w",25,125)
            UiTranslate(120, 8)
            UiText(val)
        UiPop()

        UiTranslate(0,40)

        UiPush()
            UiText("Characters vertical")
            UiTranslate(200, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.size_h",2,50)
            UiTranslate(120, 8)
            UiText(val)
        UiPop()

        UiTranslate(0,40)

        UiPush()
            UiText("Text font size")
            UiTranslate(200, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.textfontsize",16,64)
            UiTranslate(120, 8)
            UiText(val)
        UiPop()

		UiTranslate(0,40)

        UiPush()
            UiText("In-game window alpha")
            UiTranslate(200, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.chat_window_alpha",0,100)
            UiTranslate(120, 8)
            UiText(val)
        UiPop()

        UiTranslate(0,80)


		UiPush()
			UiTranslate(100,0)
			UiText("Nick color")
			--UiTranslate(0,100)
			-- UiColor(r/100, g/100, b/100)
			-- UiImageBox("common/box-solid-shadow-50.png", 150, 15, -50, -50)
		UiPop()

		UiPush()
			UiTranslate(10,40)
            UiText("r: ")
            UiTranslate(x1, 0)
            UiAlign("left")
            r = optionsSlider("savegame.mod.nick.r",0,100)
            UiTranslate(120, 8)
            UiText(r)
		UiPop()

		UiTranslate(0,40)

		UiPush()
			UiTranslate(10,40)
			UiText("g: ")
			UiTranslate(x1, 0)
			UiAlign("left")
			g = optionsSlider("savegame.mod.nick.g",0,100)
			UiTranslate(120, 8)
			UiText(g)
		UiPop()

		UiTranslate(0,40)

		UiPush()
			UiTranslate(10,40)
			UiText("b: ")
			UiTranslate(x1, 0)
			UiAlign("left")
			b = optionsSlider("savegame.mod.nick.b",0,100)
			UiTranslate(120, 8)
			UiText(b)
		UiPop()

        UiTranslate(0,80)


        UiPush()
            UiText("Window position vertical")
            UiTranslate(200, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.pos_x",0,100)
            UiTranslate(120, 8)
            UiText(val)
        UiPop()

		UiTranslate(0,40)

        UiPush()
            UiText("Window position horizontal")
            UiTranslate(200, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.pos_y",0,100)
            UiTranslate(120, 8)
            UiText(val)
        UiPop()

        --doesnt work for now
        --optionsInputDesc("Open chat bind", "options.input.keymap.openchat", x1, true)

    UiPop()

	UiTranslate(0, 500)
	UiButtonImageBox("common/box-outline-fill-6.png", 6, 6, 0.96, 0.96, 0.96)
	UiFont("regular.ttf", 26)
	UiColor(0.96, 0.96, 0.96)

    UiPush()
	
		if UiTextButton("Change state", 200, 50) then
			if typing then typing = false else typing = true end
		end
	UiPop()

    
	
end

function clamp(value, mi, ma) 
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end

function tick()
end

function draw_chat_window() --totally not copied and modified script for menu.lua
	
	local nicks_color = {GetInt("savegame.mod.nick.r")/100,GetInt("savegame.mod.nick.g")/100,GetInt("savegame.mod.nick.b")/100, GetInt("savegame.mod.nick.alpha")/100}
	

    for i =1, #chat_messages do
		local no_lines = math.floor((#chat_messages[i][1] + #chat_messages[i][2] +2) / GetInt("savegame.mod.size_w"))
		if no_lines < ((#chat_messages[i][1] + #chat_messages[i][2] +2) / GetInt("savegame.mod.size_w")) then no_lines = no_lines + 1 end
		chat_messages[i][3]= no_lines
	end
	TDMP_window.all_lines = 0
                    for i = 1,#chat_messages do
                        TDMP_window.all_lines = TDMP_window.all_lines + chat_messages[i][3]
                    end
    local char_pixel_w = math.floor((font_size+1)/2)

    local b_w = GetInt("savegame.mod.size_w") * (char_pixel_w) + 14+20 + char_pixel_w
    local b_h = GetInt("savegame.mod.size_h") * (font_size + 4)
    local text_w = b_w - 14 - 20
    local text_h = b_h 

	UiPush()

    if not typing then UiColorFilter(1, 1, 1, GetInt("savegame.mod.chat_window_alpha")/100) end
		UiColor(0,0,0, 0.5)
		UiAlign("left top")
        if typing then
		    UiImageBox("common/box-solid-shadow-50.png", b_w, b_h + font_size + 30, -50, -50)
        else
            UiImageBox("common/box-solid-shadow-50.png", b_w, b_h, -50, -50)
        end
		UiWindow(b_w, b_h)
		UiAlign("left top")
		UiColor(0.96,0.96,0.96)

		UiPush()
        if typing then
            UiPush()
            UiAlign("left top")
            UiTranslate(0, (text_h + 10))
            UiColor(1,1,1,0.25)
            UiImageBox("common/box-solid-6.png", text_w, font_size+20, 6, 6)

            UiFont(font, font_size)
            UiColor(1,1,1,1)
            UiAlign("left middle")
            UiTranslate(10, (font_size+20)/2)
            UiText("your text here")
            UiPop()
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
                UiTranslate(0, TDMP_window.possmooth*(font_size + 4))
                UiAlign("left")
                UiColor(0.95,0.95,0.95,1)
                for i=1, #chat_messages do
                    local no_lines = chat_messages[i][3]
                    local nick_char = #chat_messages[i][1] + 2
                    if no_lines > 1 then -- checks number of lines
                        for j=1,no_lines do
                            UiPush()
                            if j == 1 then
                                UiColor(nicks_color[1],nicks_color[2],nicks_color[3], 1)
                                UiText(chat_messages[i][1]..":") 
                                UiTranslate(char_pixel_w*nick_char, 0)
                                UiColor(1,1,1,1)
                                UiText(string.sub(chat_messages[i][2],1,(GetInt("savegame.mod.size_w")-nick_char)))
                            elseif j == no_lines then
                                UiColor(1,1,1,1)
                                UiText(string.sub(chat_messages[i][2],((j-1)*GetInt("savegame.mod.size_w")+1-nick_char),-1))
                            else
                                UiColor(1,1,1,1)
                                UiText(string.sub(chat_messages[i][2],((j-1)*GetInt("savegame.mod.size_w")+1-nick_char),((j*GetInt("savegame.mod.size_w"))-nick_char)))
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


end