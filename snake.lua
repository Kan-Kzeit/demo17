local M = {}
local rnd = math.random
function M.new(options)
    local options = options or {}
    local x = options.x
    local y = options.y
    local c = options.c
    local r = options.r

    local group = display.newGroup()
    group.r = r
    group.c = c

    local sheet =
    {
        frames = {
            
        },
        sheetContentWidth = 64,
        sheetContentHeight = 48
    }

    for c = 1, 3 do
        for r = 1, 4 do
        sheet.frames[#sheet.frames+1] = {
            x = 0 + (16 * (r-1)),
            y = 0 + (16 * (c-1)),
            width = 16,
            height = 16
        }
        end
    end

    group.sheet = graphics.newImageSheet("images/snake.png", sheet)

    local sequence = {
        {
            name = "horizontal",
            frames = { 1, 2, 3, 4},
            time = 200,
            loopDirection = "forward",
            loopCount = 1
        },
        {
            name = "down",
            frames = { 5, 6, 7, 8},
            time = 200,
            loopDirection = "forward",
            loopCount = 1
        },
        {
            name = "up",
            frames = { 9, 10, 11, 12},
            time = 200,
            loopDirection = "forward",
            loopCount = 1
        }
    }

    local snake = display.newSprite(group, group.sheet, sequence)
    snake.x, snake.y = x, y

    function group:moveRandom(platforms)
        local rndRow = rnd(-1, 1)
        local rndCol = rnd(-1, 1)
        while true do
            if (rndRow == 0 and rndCol ~= 0) or (rndRow ~= 0 and rndCol == 0) then
                if (self.r + rndRow > 0 and self.r + rndRow < 7) and (self.c + rndCol > 0 and self.c + rndCol < 7) then
                    self.c, self.r = self.c + rndCol, self.r + rndRow 
                    break
                end
            end
            rndRow = rnd(-1, 1)
            rndCol = rnd(-1, 1)
        end
        -- print(rndCol, rndRow)
        local moveName
        if rndCol > 0 then
            moveName = "down"
        end

        if rndCol < 0 then
            moveName = "up"
        end

        if rndRow > 0 then
            moveName = "horizontal"
            snake.xScale = 1
        end
        
        if rndRow < 0 then
            moveName = "horizontal"
            snake.xScale = -1
        end
        snake:setSequence(moveName)
        snake:play()
        local px, py = platforms[self.r][self.c]:localToContent(0.5, 0.5)
        
        transition.to(snake, {time = 200, x = px, y = py, onComplete = function ()
           
        end})
    end

    function group:attack(obj, onComplete)
        snake.ox, snake.oy = snake.x, snake.y
        local offsetRow = obj.r - self.c
        local offsetCol = obj.c - self.r
        
        local moveName
        if offsetRow > 0 then
            moveName = "down"
        end

        if offsetRow < 0 then
            moveName = "up"
        end

        if offsetCol > 0 then
            moveName = "horizontal"
            snake.xScale = 1
        end
        
        if offsetCol < 0 then
            moveName = "horizontal"
            snake.xScale = -1
        end
        snake:setSequence(moveName)
        snake:play()
        transition.to(snake, {time = 100, x = obj.x, y = obj.y, transition = easing.inBack, onComplete = function ()
            transition.to(snake, {time = 100, x = snake.ox, y = snake.oy, transition = easing.inBack, onComplete = function ()
                onComplete()
            end})
        end})
    end
    snake:setSequence("down")
    snake:play()
    
    return group
end

return M