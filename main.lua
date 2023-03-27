require("math2d")

local Coin = require "coin"
local Snake = require "snake"

local rnd = math.random
local cx, cy = display.contentCenterX, display.contentCenterY
local aw, ah = display.actualContentWidth, display.actualContentHeight
local ox, oy = display.screenOriginX, display.screenOriginY

display.setDefault("magTextureFilter", "nearest")
display.setDefault("minTextureFilter", "linear")
display.setDefault( "isImageSheetSampledInsideFrame", true )

local lastUpdate = 0
local gameTime = 0
local countDownTime = 1000
local combo = 0
local coinValue = 0
local cols = 6
local rows = 6
local tileHeight = 32
local hardTime = 0
local maxLasers = 1

local isOver = false
local isPressed = false
local isMissing = false
local isWaiting = false
local isMonster = false

local platforms = {}
local verticalLasers = {}
local horizontalLasers = {}
local fires = {}
local player, leftPoint, rightPoint, bottomFrame, gameTimer, dt, endBar, redLine, isInsideEndPoint, coin, monster, bg1, bg2

local function pointInBounds(x, y, object)
    local bounds = object.contentBounds
    if not bounds then return false end
    if x > bounds.xMin - object.contentWidth/2 and x < bounds.xMax then
      return true 
    else 
      return false
    end
  end

local function getDeltaTime()
    if lastUpdate == 0 then
        dt = 0
    else
        dt = (system.getTimer() - lastUpdate) / 1000
    end
    lastUpdate = system.getTimer()
    return dt
end

local function lengthOf ( a, b )
    if (b == nil) then
        b = {x=0,y=0}
    end
    local width, height = b.x-a.x, b.y-a.y
    return (width*width + height*height)^0.5 
end
bg1 = display.newImageRect("images/desert-backgorund.png", aw, ah)
bg1.x, bg1.y = cx, cy
bg2 = display.newImageRect("images/desert-backgorund.png", aw, ah)
bg2.x, bg2.y = cx, cy - bg2.contentHeight

local gameGroup = display.newGroup()

-- gameGroup.anchorChildren = true
local timePlay = display.newText("Time Play: " .. hardTime .. " seconds", ox + aw * 0.05, oy + ah * 0.1, nil, 10)
timePlay.anchorX = 0
local txtCombo = display.newText("Combo: " .. 0, 0, 0, nil, 10)
txtCombo.anchorX = 0

txtCombo.x = ox + aw * 0.05
txtCombo.y = oy + ah * 0.1 + 12

local txtCoin = display.newText("Coins: " .. coinValue, ox + aw * 0.05, oy + ah * 0.1 + 24, nil, 10)
txtCoin.anchorX = 0

local isLand = display.newGroup()
gameGroup:insert(isLand)
isLand.x, isLand.y = cx, cy
isLand.anchorChildren = true


bottomFrame = display.newRect(cx, cy + ah/2, aw, 25)
bottomFrame.anchorY = 1
bottomFrame.alpha = 0.2

endBar = display.newRect(cx, cy + ah/2 - 12.5, 66, 25)
endBar.alpha = 0.2
endBar.anchorY = 0.5

redLine = display.newRect(cx, cy + ah/2 - 12.5, 2, 25)
redLine:setFillColor(1, 0, 0)

leftPoint = display.newRect(ox - 11, bottomFrame.y - bottomFrame.contentHeight/2, 33, 22)
rightPoint = display.newRect(ox + aw + 11, bottomFrame.y - bottomFrame.contentHeight/2, 33, 22)
leftPoint.anchorX = 0.5
rightPoint.anchorX = 0.5

leftPoint.distanceToEndPoint = lengthOf(leftPoint, {x = cx, y = cy})
rightPoint.distanceToEndPoint = lengthOf(rightPoint, {x = cx, y = cy})



for c = 1, cols do
    platforms[c] = {}
    for r = 1, rows do
        platforms[c][r] = display.newRect(isLand, 0 + (tileHeight * (c - 1)), 0+ (tileHeight * (r - 1)), tileHeight, tileHeight)
        platforms[c][r]:setFillColor(rnd(), rnd(), rnd())
    end
end

local _px, _py =  platforms[2][2]:localToContent(0.5, 0.5)

local islandCover = display.newImageRect(gameGroup, "images/isLandCover.png", tileHeight * rows, tileHeight* rows)
islandCover.x, islandCover.y = isLand.x, isLand.y

local sheet =
{
    frames = {
        
    },
    sheetContentWidth = 96,
    sheetContentHeight = 160
}
for c = 1, 4 do
    for r = 1, 3 do
    sheet.frames[#sheet.frames+1] = {
        x = 0 + (32 * (r-1)),
        y = 0 + (40 * (c-1)),
        width = 32,
        height = 40
    }
    end
end

local timeMove = 200
local Psheet = graphics.newImageSheet("images/santa.png", sheet)
local sequence = {
    {
        name = "down",
        frames = {1, 3, 2},
        time = timeMove,
        loopDirection = "forward",
        loopCount = 1
    },
    {
        name = "up",
        frames = {10, 12, 11},
        time = timeMove,
        loopDirection = "forward",
        loopCount = 1
    },
    {
        name = "left",
        frames = {4, 6, 5},
        time = timeMove,
        loopDirection = "forward",
        loopCount = 1
    },
    {
        name = "right",
        frames = {7, 9, 8},
        time = timeMove,
        loopDirection = "forward",
        loopCount = 1
    }
}


player = display.newSprite(gameGroup, Psheet, sequence)
player.c, player.r = 2, 2
player.x, player.y = _px, _py 
player:play()

player.timeMove = timeMove

for i = 1, cols do
    verticalLasers[i] = {}
    local px, py = platforms[i][1]:localToContent(0.5, 0.5)
    verticalLasers[i].up = display.newRect( gameGroup, px, oy + 5, 5, 10)
    verticalLasers[i].down = display.newRect( gameGroup, px, oy + ah - endBar.height - 5, 5, 10)
    verticalLasers[i].idx = i
    verticalLasers[i].connectLine = display.newRect(gameGroup, verticalLasers[i].up.x, verticalLasers[i].up.y, 2, lengthOf(verticalLasers[i].up, verticalLasers[i].down))
    verticalLasers[i].connectLine:setFillColor(1, 1, 1)
    verticalLasers[i].connectLine.anchorY = 0
    verticalLasers[i].connectLine.alpha = 0.0

    horizontalLasers[i] = {}
    px, py = platforms[1][i]:localToContent(0.5, 0.5)
    horizontalLasers[i].left = display.newRect( gameGroup, ox + 5, py, 10, 5)
    horizontalLasers[i].right = display.newRect( gameGroup, ox + aw - 5, py, 10, 5)
    horizontalLasers[i].idx = i
    horizontalLasers[i].connectLine = display.newRect(gameGroup, horizontalLasers[i].left.x, horizontalLasers[i].left.y, lengthOf(horizontalLasers[i].left, horizontalLasers[i].right), 2)
    horizontalLasers[i].connectLine:setFillColor(1, 1, 1)
    horizontalLasers[i].connectLine.anchorX = 0
    horizontalLasers[i].connectLine.alpha = 0.0
end


local function onKeyEvent( event )
 
    if ( event.phase == "down" ) then

        if isWaiting then return true end
        if isPressed then return true end
        -- print("Press")
        if event.keyName == "left" or event.keyName == "a" then
            if isInsideEndPoint then
                player.c = player.c - 1
                if player.c <= 0 then
                    isOver = true
                end
                player:setSequence("left")
                player:play()
                transition.to(player, {time = player.timeMove, x = player.x - tileHeight, onComplete = function()
                    if coin ~= nil then
coin:isCollect(player.c, player.r, function()
                        coinValue = coinValue + 500
                        coin = nil
                    end)
end
                    if player.c <= 0 then
                        transition.to(player, {delay = 200, time = 100, xScale = 0.001, yScale = 0.001, onComplete = function()
                        
                        end})
                    end
                end})
                leftPoint.alpha = 0
                rightPoint.alpha = 0
                combo = combo + 1
                local txtCombo = display.newText("Combo x"..combo, endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtCombo, {time = 500, y = txtCombo.y - 30, alpha = 0, onComplete = function()
                    txtCombo:removeSelf()
                    txtCombo = nil
                end})
            else
                local txtMissing = display.newText("MISS", endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtMissing, {time = 500, y = txtMissing.y - 30, alpha = 0, onComplete = function()
                    txtMissing:removeSelf()
                    txtMissing = nil
                end})
                combo = 0
                isMissing = true
                -- leftPoint.alpha = 0
                -- rightPoint.alpha = 0
            end
            isPressed = true
            return true
        elseif event.keyName == "right" or event.keyName == "d" then
            if isInsideEndPoint then
                player.c = player.c + 1
                if player.c >= cols +1 then
                    isOver = true
                end
                player:setSequence("right")
                player:play()
                transition.to(player, {time = player.timeMove, x = player.x + tileHeight, onComplete = function()
                    if coin ~= nil then
coin:isCollect(player.c, player.r, function()
                        coinValue = coinValue + 500
                        coin = nil
                    end)
end
                    if player.c >= cols +1 then
                        transition.to(player, {delay = 200, time = 100, xScale = 0.001, yScale = 0.001, onComplete = function()
                        
                        end})
                    end
                end})
                leftPoint.alpha = 0
                rightPoint.alpha = 0
                combo = combo + 1
                local txtCombo = display.newText("Combo x"..combo, endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtCombo, {time = 500, y = txtCombo.y - 30, alpha = 0, onComplete = function()
                    txtCombo:removeSelf()
                    txtCombo = nil
                end})
            else
                local txtMissing = display.newText("MISS", endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtMissing, {time = 500, y = txtMissing.y - 30, alpha = 0, onComplete = function()
                    txtMissing:removeSelf()
                    txtMissing = nil
                end})
                -- leftPoint.alpha = 0
                -- rightPoint.alpha = 0
                combo = 0
                isMissing = true
            end
            isPressed = true
            return true
        elseif event.keyName == "up" or event.keyName == "w" then
            if isInsideEndPoint then
                player.r = player.r - 1
                if player.r <= 0 then
                    isOver = true
                end
                player:setSequence("up")
                player:play()
                transition.to(player, {time = player.timeMove, y = player.y - tileHeight, onComplete = function()
                    if coin ~= nil then
coin:isCollect(player.c, player.r, function()
                        coinValue = coinValue + 500
                        coin = nil
                    end)
end
                    if player.r <= 0 then
                        transition.to(player, {delay = 200, time = 100, xScale = 0.001, yScale = 0.001, onComplete = function()
                        
                        end})
                    end
                end})
                leftPoint.alpha = 0
                rightPoint.alpha = 0
                combo = combo + 1
                local txtCombo = display.newText("Combo x"..combo, endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtCombo, {time = 500, y = txtCombo.y - 30, alpha = 0, onComplete = function()
                    txtCombo:removeSelf()
                    txtCombo = nil
                end})
            else
                local txtMissing = display.newText("MISS", endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtMissing, {time = 500, y = txtMissing.y - 30, alpha = 0, onComplete = function()
                    txtMissing:removeSelf()
                    txtMissing = nil
                end})
                -- leftPoint.alpha = 0
                -- rightPoint.alpha = 0
                combo = 0
                isMissing = true
            end
            isPressed = true
            return true
        elseif event.keyName == "down" or event.keyName == "s" then
            if isInsideEndPoint then
                player.r = player.r + 1
                if player.r >= rows+1 then
                    isOver = true
                end
                player:setSequence("down")
                player:play()
                transition.to(player, {time = player.timeMove, y = player.y + tileHeight, onComplete = function()
                    if coin ~= nil then
coin:isCollect(player.c, player.r, function()
                        coinValue = coinValue + 500
                        coin = nil
                    end)
end
                    if player.r >= rows+1 then
                        transition.to(player, {delay = 200, time = 100, xScale = 0.001, yScale = 0.001, onComplete = function()
                        
                        end})
                    end
                end})
                leftPoint.alpha = 0
                rightPoint.alpha = 0
                combo = combo + 1
                local txtCombo = display.newText("Combo x"..combo, endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtCombo, {time = 500, y = txtCombo.y - 30, alpha = 0, onComplete = function()
                    txtCombo:removeSelf()
                    txtCombo = nil
                end})
            else
                local txtMissing = display.newText("MISS", endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtMissing, {time = 500, y = txtMissing.y - 30, alpha = 0, onComplete = function()
                    txtMissing:removeSelf()
                    txtMissing = nil
                end})
                combo = 0
                -- leftPoint.alpha = 0
                -- rightPoint.alpha = 0
                isMissing = true
            end
            isPressed = true
            return true
        elseif event.keyName == "space" then
            -- local _x, _y = leftPoint:localToContent(0.5, 0.5)
            -- print(_x, cx)
          
            if isInsideEndPoint then
                leftPoint.alpha = 0
                rightPoint.alpha = 0
                combo = combo + 1
                local txtCombo = display.newText("Combo x"..combo, endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtCombo, {time = 500, y = txtCombo.y - 30, alpha = 0, onComplete = function()
                    txtCombo:removeSelf()
                    txtCombo = nil
                end})
            else
                local txtMissing = display.newText("MISS", endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtMissing, {time = 500, y = txtMissing.y - 30, alpha = 0, onComplete = function()
                    txtMissing:removeSelf()
                    txtMissing = nil
                end})
                combo = 0
                isMissing = true
                -- leftPoint.alpha = 0
                -- rightPoint.alpha = 0
            end
            isPressed = true
            return true
        end
    end
 
    -- IMPORTANT! Return false to indicate that this app is NOT overriding the received key
    -- This lets the operating system execute its default handling of the key
    return false
end
 
-- Add the key event listener
Runtime:addEventListener( "key", onKeyEvent )

countDownTime = 800

local function getRndLaser(lasers)
    local rndPos = rnd(1, cols)
    local isReady = false
    for i = 1, #lasers do
        if not lasers[i].isReady then
            isReady = true
        end
    end
    if not isReady then return false end
    while isReady do
        if lasers[rndPos].isReady then
            rndPos = rnd(1, cols)
        else
            return lasers[rndPos]
        end
    end
    
end

local function resetCount()

end
local function update(event)
    bg1.y = bg1.y + 1
    bg2.y = bg2.y + 1

    if bg1.y - bg1.contentHeight/2 >= oy + ah then
        bg1.y = cy - bg1.contentHeight
    end
    if bg2.y - bg2.contentHeight/2 >= oy + ah then
        bg2.y = cy - bg2.contentHeight
    end

    isInsideEndPoint = pointInBounds(leftPoint.x, leftPoint.y, endBar)
    if isInsideEndPoint then
        endBar:setFillColor(1, 1, 0)
    else
        endBar:setFillColor(1)
    end
    gameTime = gameTime + getDeltaTime()
    -- hardTime = hardTime + getDeltaTime()

    timePlay.text = "Time Play: " .. gameTime .. " seconds"
    if gameTime > 5  and gameTime < 10 then
        countDownTime = 780
        -- maxLasers = 5
        isMonster = true
    elseif gameTime >= 10 and gameTime < 20 then
        countDownTime = 750
      
    elseif gameTime >= 20 and gameTime < 40 then
        countDownTime = 720
        maxLasers = 1
    elseif gameTime >= 40 and gameTime < 60 then
        countDownTime = 700
        maxLasers = 2
    elseif gameTime >= 60 then
        countDownTime = 650
        maxLasers = 2
    end
    
    if leftPoint.x >= endBar.x then
        if isWaiting then return true end
        -- if leftPoint.alpha ~= 0 then
        -- if not isMissing then
          
            isMissing = true
            if not isPressed then
                combo = 0
                local txtMissing = display.newText("MISS", endBar.x, endBar.y - endBar.height, nil, 15)
                transition.to(txtMissing, {time = 500, y = txtMissing.y - 30, alpha = 0, onComplete = function()
                    txtMissing:removeSelf()
                    txtMissing = nil
                end})
            end
        -- end
        -- end

        for i = 1, cols do
            
            if horizontalLasers[i].isReady then
                transition.to(horizontalLasers[i].connectLine, {time = 50, yScale = 2, alpha = 1, onComplete = function()
                    transition.to(horizontalLasers[i].connectLine, {time = 50, xScale = 0.001, yScale = 0.001, alpha = 0, onComplete = function()
                        if horizontalLasers[i].idx == player.r then
                            isOver = true
                            -- print("Over")
                        end
                        transition.to(horizontalLasers[i].connectLine, {time = 100, xScale = 1, yScale = 1, alpha = 1, onComplete = function()
                            horizontalLasers[i].isReady = false
                            horizontalLasers[i].connectLine:setFillColor(1, 1, 1)
                            horizontalLasers[i].connectLine.alpha = 0.0
                        end})
                    end})
                end})
            end

            if verticalLasers[i].isReady then
                transition.to(verticalLasers[i].connectLine, {time = 50, yScale = 2, alpha = 1, onComplete = function()
                    transition.to(verticalLasers[i].connectLine, {time = 50, xScale = 0.001, yScale = 0.001, alpha = 0, onComplete = function()
                        if verticalLasers[i].idx == player.c then
                            isOver = true
                            -- print("Over")
                        end
                        transition.to(verticalLasers[i].connectLine, {time = 100, xScale = 1, yScale = 1, alpha = 1, onComplete = function()
                            verticalLasers[i].isReady = false
                            verticalLasers[i].connectLine:setFillColor(1, 1, 1)
                            verticalLasers[i].connectLine.alpha = 0.0
                        end})
                    end})
                end})
            end
        end

        for k = 1, maxLasers do
  
            local rndVorH = rnd(1, 2)

            if rndVorH == 1 then
                local rndLaser = getRndLaser(horizontalLasers)
                if rndLaser then
                    rndLaser.connectLine.alpha = 0.5
                    rndLaser.connectLine:setFillColor(1, 0, 0)
                    rndLaser.isReady = true
                end
            else
                local rndLaser = getRndLaser(verticalLasers)
                if rndLaser then
                    rndLaser.connectLine.alpha = 0.5
                    rndLaser.connectLine:setFillColor(1, 0, 0)
                    rndLaser.isReady = true
                end
            end
        end

        isWaiting = true
        timer.performWithDelay(50, function()
            isPressed = false
            isWaiting = false
            leftPoint.x = ox - 11
            rightPoint.x = ox + aw + 11
            leftPoint.alpha = 1
            rightPoint.alpha = 1
        end, 1)

        if coin == nil then
            local rndRow = rnd(1, rows)
            local rndCol = rnd(1, cols)
            while true do
                if rndRow == player.r and rndCol == player.c then
                    rndRow = rnd(1, rows)
                    rndCol = rnd(1, cols)
                else
                    break
                end
            end
            local coinX, coinY = platforms[rndRow][rndCol]:localToContent(0.5, 0.5)
            coin = Coin.new({
                    x = coinX,
                    y = coinY,
                    row = rndRow,
                    col = rndCol
            })

        
        end
        if isMonster then
        
            if monster == nil then
                local _rndRow = rnd(1, rows)
                local _rndCol = rnd(1, cols)
                while true do
                    if _rndRow == player.r and _rndCol == player.c then
                        _rndRow = rnd(1, rows)
                        _rndCol = rnd(1, cols)
                    else
                        break
                    end
                end
                local snakeX, snakeY = platforms[_rndRow][_rndCol]:localToContent(0.5, 0.5)
                monster = Snake.new({
                    x = snakeX,
                    y = snakeY,
                    c = _rndCol,
                    r = _rndRow
                })
            else
                local snakeIsAttack = false
                for i = -1, 1 do
                   for j = -1, 1 do
                        if i == 0 or j == 0 then
                            print("Pos " ..monster.r + i, player.r, monster.c + j, player.c)
                            if monster.r + i == player.c and monster.c + j == player.r then
     
                                monster:attack(player, function()
                                    isOver = true
                                end)
                                snakeIsAttack = true
                                break
                            end
                        end
                   end
                end
                if not snakeIsAttack then
                    monster:moveRandom(platforms)
                end
            end
        end
        txtCombo.text = "Combo: " ..combo
    else
        if not isWaiting then
            leftPoint.x = leftPoint.x + (leftPoint.distanceToEndPoint/(countDownTime * 0.1))
            rightPoint.x = rightPoint.x - (rightPoint.distanceToEndPoint/(countDownTime * 0.1))
        end
    end
    if monster then
        if player.c == monster.r and player.r == monster.c then
            isOver = true
        end
    end

    if isOver then
        transition.to(player, {time = 50, alpha = 0, onComplete = function()
            transition.to(player, {time = 50, alpha = 1, onComplete = function()
                transition.to(player, {time = 50, alpha = 0, onComplete = function()
                    transition.to(player, {time = 50, alpha = 1, onComplete = function()
                        transition.to(player, {time = 50, alpha = 0, onComplete = function()
                            local overBoard = display.newGroup()
                            local coverScene = display.newRect(cx, cy, aw, ah)
                            coverScene:setFillColor(0)
                            coverScene.alpha = 0.4
                            transition.from(coverScene, {time = 1000, alpha = 0, onComplete = function()
                                local btnReplay = display.newGroup()
                                btnReplay.btn = display.newRect(btnReplay, 0, 0, 150, 50)
                                btnReplay.lbl = display.newText(btnReplay, "Replay", 0, 0, nil, 20)
                                btnReplay.lbl:setFillColor(0)
                                btnReplay.x, btnReplay.y = cx, cy
                                function btnReplay:touch(event)
                                    if ( event.phase == "began" ) then
                                        print("Replay")
                                        self.xScale = 0.9
                                        self.yScale = 0.9
                                        -- Set touch focus
                                        display.getCurrentStage():setFocus( self )
                                        self.isFocus = true
                                     
                                    elseif ( self.isFocus ) then
                                        if ( event.phase == "moved" ) then
                                            return true
                                        elseif ( event.phase == "ended" or event.phase == "cancelled" ) then
                                            self.xScale = 1
                                            self.yScale = 1
                                            transition.to(self, {time = 200, xScale = 0.001, yScale = 0.001, transition = easing.inBack, onComplete = function()
                                                transition.to(coverScene, {time = 1000, alpha = 0, onComplete = function()
                                                    player.x, player.y = _px, _py 
                                                    player.alpha = 1
                                                    player.r, player.c = 2, 2
                                                    
                                                    isMonster = false
                                                    if monster then
                                                        monster:removeSelf()
                                                        monster = nil
                                                    end
                                                    
                                                    if coin then
                                                        coin:removeSelf()
                                                        coin = nil
                                                    end
                                                    coinValue = 0
                                                    hardTime = 0
                                                    maxLasers = 1
                                                    combo = 0

                                                    isOver = false
                                                    isPressed = false
                                                    isMissing = false
                                                    isWaiting = false
                                                    isMonster = false

                                                    countDownTime = 800
                                                    overBoard:removeSelf()
                                                    overBoard = nil
                                                    coverScene:removeSelf()
                                                    coverScene = nil

                                                    btnReplay:removeEventListener("touch")
                                                    btnReplay:removeSelf()
                                                    btnReplay = nil

                                                    for i = 1, #horizontalLasers do
                                                        horizontalLasers[i].connectLine:setFillColor(1, 1, 1)
                                                        horizontalLasers[i].isReady = false
                                                        horizontalLasers[i].connectLine.alpha = 0
                                                    end

                                                    for i = 1, #verticalLasers do
                                                        verticalLasers[i].connectLine:setFillColor(1, 1, 1)
                                                        verticalLasers[i].isReady = false
                                                        verticalLasers[i].connectLine.alpha = 0
                                                    end

                                                    gameTime = 0
                                             
                                                    timePlay.text = "Time Play: 0 seconds"
                                                    txtCombo.text = "Combo: " .. 0
                                                    txtCoin.text = "Coins: " .. 0

                                                    Runtime:addEventListener("enterFrame", update)
                                                    Runtime:addEventListener("key", onKeyEvent)
                                                end})
                                            end})
                                            -- Reset touch focus
                                            display.getCurrentStage():setFocus( nil )
                                            self.isFocus = nil
                                        end
                                    end
                                    return true
                                end
                                print("adding touch")
                                btnReplay:addEventListener("touch")
                            end})
                        end})
                    end})
                end})
            end})
        end})

        leftPoint.alpha = 0
        rightPoint.alpha = 0
        Runtime:removeEventListener("enterFrame", update)
        Runtime:removeEventListener("key", onKeyEvent)
    end

end

Runtime:addEventListener( "enterFrame", update)
