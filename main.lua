--library imports--
gamestate = require('hump.gamestate')
class = require('hump.class')
grid = require('jumper.grid') --https://github.com/Yonaba/Jumper.git
pathfinder = require('jumper.pathfinder')
anim8 = require('anim8.anim8')
socket = require('socket')

--utilities and entities--
utils = require('utils')
button = require('UI.button')
creep = require('creep')
tower = require('tower')
bullet = require('bullet')
player = require('player')

--game states--
game = require('game')
client = require('server/client') --jonathan: just POC

function love.load()
    gamestate.registerEvents()
    gamestate.switch(game) --jonathan: uncomment this to play the game as is
--    print("switch to client") --jonathan: entry point to client/server POC
--    gamestate.switch(client)
    --jonathan: remember that prior to running the client you have to first start up the server
    -- which can be done with the command "lua server/server.lua" from the directory of grid-runner
end