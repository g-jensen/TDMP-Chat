--[[ TODO:
      -add movable cursor
        -add del button
      -preety it up
      -add selecting by shift
      -add jumping cursor by ctrl
        -add selecting by shift + crtl

]]

if not TDMP_LocalSteamId then DebugPrint("[TDMP Chat] TDMP is not present, chat mod will be disbled") return end

#include "globals.lua"
#include "ui.lua"
#include "tdmp/networking.lua"
#include "tdmp/player.lua"
#include "tdmp/hooks.lua"
#include "tdmp/json.lua"

local clientNick = nil
local clientId = nil
local nicks = {}

local chat_msg = {}
chat_msg["msg"] = ""
chat_msg["sender_id"] = nil

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

function draw()
    draw_chat()
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

-- populates nicks
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