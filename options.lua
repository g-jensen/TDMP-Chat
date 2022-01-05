if GetInt("savegame.mod.textfontsize") == 0 then -- checks if registry has data, if not set default
	SetInt("savegame.mod.textfontsize", 20)
	SetInt("savegame.mod.textalpha", 80)
	SetInt("savegame.mod.textboxalpha", 50)
end

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
            local val = optionsSlider("savegame.mod.textalpha",0,100)
            UiTranslate(120, 8)
            UiText(val.."%")
        UiPop()

        UiTranslate(0,40)

        UiPush()
            UiFont("bold.ttf", 32)
            UiText("Text box alpha")
            UiTranslate(x1, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.textboxalpha",0,100)
            UiTranslate(120, 8)
            UiText(val.."%")
        UiPop()

        UiTranslate(0,40)

        UiPush()
            UiFont("bold.ttf", 32)
            UiText("Text font size")
            UiTranslate(x1, 0)
            UiAlign("left")
            local val = optionsSlider("savegame.mod.textfontsize",16,48)
            UiTranslate(120, 8)
            UiText(val)
        UiPop()

        UiTranslate(0,40)

        --doesnt work for now
        --optionsInputDesc("Open chat bind", "options.input.keymap.openchat", x1, true)

    UiPop()

    UiTranslate(0, 200)
    UiAlign("center")
    if UiTextButton("Save & exit", 200, 40) then
        Menu()
    end
end

