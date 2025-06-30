local serpent = require "serpent"

tetris = {}
tetris.cols, tetris.rows = 10, 20
tetris.cellSize = 30
tetris.timer, tetris.delay = 0, 0.5

tetris.shapes = {
    { {1,1,1,1} },          -- I
    { {1,1}, {1,1} },       -- O
    { {0,1,0}, {1,1,1} },   -- T
    { {1,0,0}, {1,1,1} },   -- L
    { {0,0,1}, {1,1,1} },   -- J
    { {1,1,0}, {0,1,1} },   -- S
    { {0,1,1}, {1,1,0} },   -- Z
}

function tetris.cloneShape(s)
    local c = {}
    for i, row in ipairs(s) do
        c[i] = {}
        for j, v in ipairs(row) do
            c[i][j] = v
        end
    end
    return c
end

function tetris.rotate(s)
    local h, w = #s, #s[1]
    local r = {}
    for i = 1, w do
        r[i] = {}
        for j = 1, h do
            r[i][j] = s[h - j + 1][i]
        end
    end
    return r
end

grid = {}
for y = 1, tetris.rows do
    grid[y] = {}
    for x = 1, tetris.cols do
        grid[y][x] = 0
    end
end

current = {
    shape = tetris.cloneShape(tetris.shapes[math.random(#tetris.shapes)]),
    x = 4,
    y = 1
}
score = 0

function canPlace(shape, gx, gy)
    for i = 1, #shape do
        for j = 1, #shape[i] do
            if shape[i][j] == 1 then
                local x, y = gx + j - 1, gy + i - 1
                if x < 1 or x > tetris.cols or y > tetris.rows or (y > 0 and grid[y][x] ~= 0) then
                    return false
                end
            end
        end
    end
    return true
end

function lockPiece()
    for i, row in ipairs(current.shape) do
        for j, v in ipairs(row) do
            if v == 1 then
                grid[current.y + i - 1][current.x + j - 1] = 1
            end
        end
    end
    clearLines()
    spawnPiece()
end

function clearLines()
    local removed = {}
    for y = tetris.rows, 1, -1 do
        local full = true
        for x = 1, tetris.cols do
            if grid[y][x] == 0 then
                full = false
                break
            end
        end
        if full then
            table.insert(removed, y)
        end
    end

    if #removed > 0 then
        sounds.clear:play()
        table.sort(removed)
        for _, ly in ipairs(removed) do
            for _ = 1, 3 do
                grid[ly] = {}
                for x = 1, tetris.cols do grid[ly][x] = (_ % 2) end
                love.graphics.clear()
                love.update(0)
                love.draw()
                love.graphics.present()
                love.timer.sleep(0.05)
            end
            table.remove(grid, ly)
            table.insert(grid, 1, {})
            for x = 1, tetris.cols do grid[1][x] = 0 end
        end
        score = score + #removed * 100
    end
end

function spawnPiece()
    current.shape = tetris.cloneShape(tetris.shapes[math.random(#tetris.shapes)])
    current.x, current.y = 4, 1
    if not canPlace(current.shape, current.x, current.y) then
        gameOver = true
    end
end

function love.load()
    love.window.setTitle("Tetris Lua")
    love.window.setMode(tetris.cols * tetris.cellSize, tetris.rows * tetris.cellSize)

    sounds = {
        move   = love.audio.newSource("move.wav", "static"),
        rotate = love.audio.newSource("rotate.wav", "static"),
        drop   = love.audio.newSource("drop.wav", "static"),
        clear  = love.audio.newSource("clear.wav", "static"),
    }

    spawnPiece()

    if love.filesystem.getInfo("savegame.lua") then
        local data = love.filesystem.load("savegame.lua")()
        grid, score = data.grid, data.score
    end
end

function love.update(dt)
    tetris.timer = tetris.timer + dt
    if tetris.timer > tetris.delay then
        if canPlace(current.shape, current.x, current.y + 1) then
            current.y = current.y + 1
        else
            lockPiece()
        end
        tetris.timer = 0
    end
end

function love.keypressed(key)
    if gameOver then return end

    if key == "left" then
        if canPlace(current.shape, current.x - 1, current.y) then
            current.x = current.x - 1
            sounds.move:play()
        end
    elseif key == "right" then
        if canPlace(current.shape, current.x + 1, current.y) then
            current.x = current.x + 1
            sounds.move:play()
        end
    elseif key == "up" then
        local r = tetris.rotate(current.shape)
        if canPlace(r, current.x, current.y) then
            current.shape = r
            sounds.rotate:play()
        end
    elseif key == "down" then
        if canPlace(current.shape, current.x, current.y + 1) then
            current.y = current.y + 1
            sounds.drop:play()
        end
    elseif key == "s" then
        love.filesystem.write("savegame.lua", "return {grid=" .. serpent.dump(grid) .. ",score=" .. score .. "}")
    elseif key == "l" then
        if love.filesystem.getInfo("savegame.lua") then
            local data = love.filesystem.load("savegame.lua")()
            grid, score = data.grid, data.score
        end
    end
end

function love.draw()
    for y = 1, tetris.rows do
        for x = 1, tetris.cols do
            if grid[y][x] == 1 then
                love.graphics.rectangle("fill", (x - 1) * tetris.cellSize, (y - 1) * tetris.cellSize,
                    tetris.cellSize - 1, tetris.cellSize - 1)
            end
        end
    end

    for i, row in ipairs(current.shape) do
        for j, v in ipairs(row) do
            if v == 1 then
                love.graphics.rectangle("fill",
                    (current.x + j - 1) * tetris.cellSize - tetris.cellSize,
                    (current.y + i - 1) * tetris.cellSize - tetris.cellSize,
                    tetris.cellSize - 1, tetris.cellSize - 1)
            end
        end
    end

    love.graphics.print("Score: " .. score, 5, 5)
    if gameOver then
        love.graphics.printf("Game Over", 0, (tetris.rows * tetris.cellSize) / 2 - 10, tetris.cols * tetris.cellSize, "center")
    end
end
