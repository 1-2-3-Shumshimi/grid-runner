--library imports--
gamestate = require('hump.gamestate')
class = require('hump.class')
grid = require('jumper.grid') --https://github.com/Yonaba/Jumper.git
pathfinder = require('jumper.pathfinder')
anim8 = require('anim8.anim8')

--utilities and entities--
utils = require('utils')
button = require('UI.button')
creep = require('creep')
tower = require('tower')
bullet = require('bullet')

--game states--
game = require('game')

function love.load()
    gamestate.registerEvents()
    gamestate.switch(game)
end