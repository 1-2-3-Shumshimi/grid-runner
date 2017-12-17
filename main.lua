--library imports--
gamestate = require('hump.gamestate')
class = require('hump.class')
grid = require('jumper.grid') --https://github.com/Yonaba/Jumper.git
pathfinder = require('jumper.pathfinder')
anim8 = require('anim8.anim8')
socket = require('socket')

--utilities and entities--
utils = require('utils')
constants = require('constants')
model = require('model')
creep = require('creep')
tower = require('tower')
bullet = require('bullet')
player = require('player')

--UI elements--
button = require('UI.button')
textbox = require('UI.textbox')
toggle = require('UI.toggle')

--game states--
game = require('game')
client = require('server/client') --jonathan: just POC

--AI/computer players--
basicAgent = require('agents/basicAgent')
basicAgent2 = require('agents/basicAgent2')
useAIFlag = true --true if only one player playing, false otherwise
agent = basicAgent2() --change to play against different AIs

function love.load()
    gamestate.registerEvents()
    gamestate.switch(game) --jonathan: uncomment this to play the game as is
--    print("switch to client") --jonathan: entry point to client/server POC
--    gamestate.switch(client)
    --jonathan: remember that prior to running the client you have to first start up the server
    -- which can be done with the command "lua server/server.lua" from the directory of grid-runner
end