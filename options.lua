function optionsSlider(setting, def, mi, ma)
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
    local x1 = 120

	UiTranslate(UiCenter(), 250)
	UiAlign("center middle")

	--Title
	UiFont("bold.ttf", 48)
	UiText("TDMP Chat options")

    UiTranslate(0,100)
    
    UiPush()
        UiTranslate(-80,0)
        UiPush()
            UiFont("bold.ttf", 32)
            UiText("Text alpha")
            UiTranslate(x1, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.textalpha",100,0,100)
            UiTranslate(120, 8)
            UiText(val / 100)
        UiPop()

        UiTranslate(0,40)

        UiPush()
            UiFont("bold.ttf", 32)
            UiText("Text box alpha")
            UiTranslate(x1, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.textboxalpha",50,0,100)
            UiTranslate(120, 8)
            UiText(val / 100)
        UiPop()

        UiTranslate(0,40)

        UiPush()
            UiFont("bold.ttf", 32)
            UiText("Text font size")
            UiTranslate(x1, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.textfontsize",32,16,128)
            UiTranslate(120, 8)
            UiText(val)
        UiPop()

        UiTranslate(0,80)


		local r = GetInt("savegame.mod.textcolor_r")
		local g = GetInt("savegame.mod.textcolor_g")
		local b = GetInt("savegame.mod.textcolor_b")

		UiPush()
			UiFont("bold.ttf", 32)
			UiText("Text color")
			UiTranslate(200,0)
			UiColor(r / 255,g / 255,b / 255)
			UiImageBox("common/box-solid-shadow-50.png", 150, 15, -50, -50)
		UiPop()

		UiPush()
            UiFont("bold.ttf", 32)
			UiTranslate(10,40)
            UiText("r: ")
            UiTranslate(x1, 0)
            UiAlign("left")
            r = optionsSlider("savegame.mod.textcolor_r",255,0,255)
            UiTranslate(120, 8)
            UiText(r)
		UiPop()

		UiTranslate(0,40)

		UiPush()
			UiFont("bold.ttf", 32)
			UiTranslate(10,40)
			UiText("g: ")
			UiTranslate(x1, 0)
			UiAlign("left")
			g = optionsSlider("savegame.mod.textcolor_g",255,0,255)
			UiTranslate(120, 8)
			UiText(g)
		UiPop()

		UiTranslate(0,40)

		UiPush()
			UiFont("bold.ttf", 32)
			UiTranslate(10,40)
			UiText("b: ")
			UiTranslate(x1, 0)
			UiAlign("left")
			b = optionsSlider("savegame.mod.textcolor_b",255,0,255)
			UiTranslate(120, 8)
			UiText(b)
		UiPop()

        --doesnt work for now
        --optionsInputDesc("Open chat bind", "options.input.keymap.openchat", x1, true)

    UiPop()

    UiTranslate(0, 400)
    UiAlign("center")
    if UiTextButton("Close", 200, 40) then
        Menu()
    end
end

