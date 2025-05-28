-- main.lua

local physics = require("physics")

physics.start()
physics.setGravity(0, 9.8)

-- Background
local screenX, screenY =
    display.screenOriginX, display.screenOriginY
local screenW, screenH =
    display.actualContentWidth, display.actualContentHeight
local bg = display.newRect(
    screenX, screenY,
    screenW, screenH
)
bg.anchorX, bg.anchorY = 0, 0
bg.fill = {
    type      = "gradient",
    color1    = { 0.1, 0.4, 0.7 },
    color2    = { 0.6, 0.8, 1.0 },
    direction = "down"
}
bg:toBack()

-- Bucket
local bucket = display.newImageRect("images/bucket.png", 96, 96)
bucket.x, bucket.y = display.contentCenterX, display.contentHeight
physics.addBody(bucket, "static", { friction = 0.5 })
bucket.myName = "bucket"

bucket:addEventListener("touch", function(event)
    if event.phase == "moved" then
        local halfW = bucket.width * 0.5
        bucket.x = math.max(halfW,
                    math.min(display.contentWidth - halfW, event.x))
    end
    return true
end)

-- UI elements
local uiGroup = display.newGroup()
local score   = 0
local level   = 1

local padding = 20
local topY = screenY + padding
local leftX = screenX + padding
local rightX = screenX + screenW - padding
local centerX = screenX + screenW * 0.5

-- Coin icon
local coinIcon = display.newImageRect(uiGroup, "images/coin.png", 64, 64)
coinIcon.anchorX, coinIcon.anchorY = 0, 0.5
coinIcon.x, coinIcon.y = leftX - 20, topY + 50

local scoreText = display.newText({
    parent   = uiGroup,
    text     = tostring(score),
    x        = leftX + 50,
    y        = topY + 50,
    font     = native.systemFontBold,
    fontSize = 20,
})
scoreText.anchorY = 0.5

-- Level label
local levelText = display.newText({
    parent   = uiGroup,
    text     = "LEVEL " .. tostring(level),
    x        = centerX + 10,
    y        = topY + 50,
    font     = native.systemFontBold,
    fontSize = 22,
})
levelText.anchorY = 0.5

-- Gear button
local gearButton = display.newImageRect(uiGroup, "images/gear.png", 32, 32)
gearButton.anchorX, gearButton.anchorY = 1, 0.5
gearButton.x, gearButton.y = rightX, topY + 50
gearButton:addEventListener("tap", function()
    print("Gear tapped")
end)

-- Balls
local ballImages = {
    "ball_red.png",
    "ball_green.png",
    "ball_blue.png",
}

local function spawnBall()
    local img = ballImages[ math.random(#ballImages) ]
    local ball = display.newImageRect("images/"..img, 50, 50)
    ball.x = math.random(ball.width*0.5, display.contentWidth - ball.width*0.5)
    ball.y = -ball.height
    physics.addBody(ball, "dynamic", {
        radius  = ball.width * 0.5,
        bounce  = 0.6,
        density = 1.0,
    })
    ball.myName = "ball"
end

timer.performWithDelay(1000, spawnBall, 0)

local POINTS_PER_LEVEL = 10

-- Collision handling
local function onCollision(event)
    if event.phase == "began" then
        local a, b = event.object1, event.object2
        local caughtBall

        if (a.myName=="ball"   and b.myName=="bucket") then
            caughtBall = a
        elseif (b.myName=="ball" and a.myName=="bucket") then
            caughtBall = b
        end

        if caughtBall then
            display.remove(caughtBall)

            -- Bucket squash and stretch
            transition.to(bucket, {
                time   = 100,
                xScale = 1.1,
                yScale = 0.9,
                onComplete = function()
                    transition.to(bucket, { time=100, xScale=1, yScale=1 })
                end
            })

            -- Update score
            score = score + 1
            scoreText.text = tostring(score)

            -- Next level
            local newLevel = math.floor((score - 1) / POINTS_PER_LEVEL) + 1
            if newLevel > level then
                level = newLevel
                levelText.text = "LEVEL " .. tostring(level)
            end
        end
    end
end

Runtime:addEventListener("collision", onCollision)
