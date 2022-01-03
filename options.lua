function optionsSlider(setting, def, mi, ma)
	UiColor(1,1,0.5)
	UiPush()
		UiTranslate(0, -8)
		local val = GetInt(setting)
		val = (val-mi) / (ma-mi)
		local w = 100
		UiRect(w, 3)
		UiAlign("center middle")

        UiPush()
            UiTranslate(-50,0)
		    val = UiSlider("common/dot.png", "x", val*w, 0, w) / w
        UiPop()

		val = math.floor(val*(ma-mi)+mi)
		SetInt(setting, val)
	UiPop()
	return val
end

function draw()
	UiTranslate(UiCenter(), 250)
	UiAlign("center middle")

	--Title
	UiFont("bold.ttf", 48)
	UiText("TDMP Chat options")

    UiTranslate(0,100)
    UiFont("bold.ttf", 32)
    UiText(optionsSlider("savegame.mod.alpha",50,0,100) / 100)
	
	UiTranslate(0, 100)
	if UiTextButton("Close", 200, 40) then
		Menu()
	end
end

