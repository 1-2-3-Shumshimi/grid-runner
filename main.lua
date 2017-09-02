--library imports--
gamestate = require('hump.gamestate')
grid = require('jumper.grid') --https://github.com/Yonaba/Jumper.git
pathfinder = require('jumper.pathfinder')

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