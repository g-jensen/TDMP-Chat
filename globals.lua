font = "fonts/UbuntuMono-Regular.ttf"
textalpha = GetInt("savegame.mod.textalpha") / 100
textboxalpha = GetInt("savegame.mod.textboxalpha") / 100
font_size = GetInt("savegame.mod.textfontsize")

keys = {
    "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
    "1","2","3","4","5","6","7","8","9","0",
    "-","+",",","."
}

keys_shifted = {
    "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "!","@","#","$","%","^","&","*","(",")",
    "_","DO NOT USE","<",">"
}

-- holds the characters being input in the chat box
input = ""

-- chatState can be false or true
chatState = false
messages = {}