-- Configuration
function love.conf(t)
	t.title = "Grid Runner" -- POC for tower arena game
	t.version = "0.10.2"         -- The LÖVE version this game was made for (string)
	t.window.width = 1000        -- we want our game to be long and thin.
	t.window.height = 600

	-- For Windows debugging
	t.console = true
end