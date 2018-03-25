--library imports--
gamestate = require('hump.gamestate')
class = require('hump.class')
grid = require('jumper.grid') --https://github.com/Yonaba/Jumper.git
pathfinder = require('jumper.pathfinder')
anim8 = require('anim8.anim8')
socket = require('socket')
nk = require('nuklear')

--utilities and entities--
utils = require('utils')
constants = require('constants')
model = require('model')
creep = require('creep')
tower = require('tower')
bullet = require('bullet')
player = require('player')

--UI elements--
style = require('style')
button = require('UI.button') --to be deprecated
textbox = require('UI.textbox') --to be deprecated
toggle = require('UI.toggle') --to be deprecated

--game states--
game = require('game')
client = require('server/client') --jonathan: just POC

--AI/computer players--
basicAgent = require('agents/basicAgent')
basicAgent2 = require('agents/basicAgent2')
useAIFlag = true --true if only one player playing, false otherwise
agent = basicAgent2() --change to play against different AIs

--Other configurations--
debug = true

function love.load()
    love.window.setMode(880, 660)
    nk.init()
    gamestate.registerEvents()
    gamestate.switch(game) --jonathan: uncomment this to play the game as is
--    print("switch to client") --jonathan: entry point to client/server POC
--    gamestate.switch(client)
    --jonathan: remember that prior to running the client you have to first start up the server
    -- which can be done with the command "lua server/server.lua" from the directory of grid-runner
end

-- encoding mouse actions to nuklear library
function love.keypressed(key, scancode, isrepeat)
	nk.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	nk.keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch)
	nk.mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
	nk.mousereleased(x, y, button, istouch)
end

function love.mousemoved(x, y, dx, dy, istouch)
	nk.mousemoved(x, y, dx, dy, istouch)
end