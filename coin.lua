local M = {}

function M.new(options)
    local options = options or {}

    local x = options.x or display.contentCenterX
    local y = options.y or display.contentCenterY
    local row = options.row 
    local col = options.col

    local group = display.newGroup()
    group.r = row
    group.c = col

    local sheet =
    {
        frames = {
            
        },
        sheetContentWidth = 448,
        sheetContentHeight = 32
    }
    for i = 1, 14 do
        sheet.frames[i] = {
            x = 0 + (32 * (i-1)),
            y = 0,
            width = 32,
            height = 32
        }
    end
    group.sheet = graphics.newImageSheet("images/coin.png", sheet)

    local sequence = {
        {
            name = "idle",
            start = 1,
            count = 14,
            time = 350,
            loopDirection = "forward",
            loopCount = 0
        }
    }

    function group:isCollect(r, c, onComplete)
        if not group then return false end
        print(c, self.c, r, self.r)
        local onComplete = onComplete or function() end
        if c == self.c and r == self.r then
            group:collected(onComplete)
        end
    end

    function group:collected(onComplete)
        local onComplete = onComplete or function() end
        transition.to(group, {y = group.y - 50, alpha = 0, onComplete = function()
            
            group:removeSelf()
            group = nil
            onComplete()
        end})
    end
    group.effect = display.newSprite(group, group.sheet, sequence)
    group.effect.x, group.effect.y = x, y
    group.effect:scale(0.5, 0.5)
    group.effect:play()
    return group
end
return M