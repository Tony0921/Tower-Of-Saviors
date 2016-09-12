-----------------------------------------------------------------------------------------
-- Tower Of Saviors
-- battle.lua
-- Tony Chen
-- 2016/9/12
-----------------------------------------------------------------------------------------

--=======================================================================================
--引入各種函式庫
--=======================================================================================
local composer = require("composer")
local scene = composer.newScene( )
local physics = require( "physics" )
physics.start( )
physics.setGravity( 0, 0 )
--=======================================================================================
--宣告全域變數
--=======================================================================================


--=======================================================================================
--宣告區域變數
--=======================================================================================
local bg
local road
local runes = {
				{ runeType = "blue" , image="Runes/01.png"},
				{ runeType = "red" , image="Runes/02.png"},
				{ runeType = "green" , image="Runes/03.png"},
				{ runeType = "yellow" , image="Runes/04.png"},
				{ runeType = "black" , image="Runes/05.png"},
				{ runeType = "heart" , image="Runes/06.png"}
		}
local runesTable = {}
local dots = {}
local cards = {}
local nilHpLine
local hpLine
local hp = 10000
local hpText
local circle
local hpIcon
local moveTime
local time = 5
local move_tmr
local tmpRune --暫顯示符文
local selectedRune --目前選定符
local isMoving = false
local tran_pools = {} --用來暫存未完成的transition


local runesWidth = 45
local runesHeight = 45

local grp_runes = display.newGroup( )
local grp_jp = display.newGroup( )
local grp_time = display.newGroup( )

local initial
local move
local timeToMove
local onCollision
local ClearUpRunes
local checkRunes
local resumeTrans
-- local putin
local physicalProperties = { density = 1.0, bounce = 0.2 }
--=======================================================================================
--定義各種函式
--=======================================================================================
initial = function (  )
	--戰鬥背景
	road = display.newImageRect( "Images/road.png", 300, 200 )
	road.x = _SCREEN.CENTER.X
	road.y = 100
	road.path.x1 = 100
	road.path.y1 = 50
	road.path.y4 = 50
	road.path.x4 = -100

	--符石背景
	bg = display.newImageRect( grp_runes , "Images/battleBackGround.png", 300, 250 )
	bg.anchorX = 0.5
	bg.anchorY = 1
	bg.x = _SCREEN.CENTER.X
	bg.y = _SCREEN.HEIGHT

	--符石
	for i=1,5 do
		for j=1,6 do
			local m = math.random( #runes )
			local tmpRuneData = runes[m]
			local n = j + 6 * ( i - 1 )
			local runesX = 35 + 50 * ( j - 1 )
			local runesY = _SCREEN.HEIGHT - ( 25 + 50 * ( i - 1 ) )
			runesTable[n] = display.newImageRect( grp_runes , tmpRuneData.image , runesWidth, runesHeight )
			runesTable[n].runeData = tmpRuneData
			runesTable[n].index = n
			runesTable[n].x = runesX
			runesTable[n].y = runesY
			runesTable[n]:addEventListener( "touch", move )
			--撞擊點
			dots[n] = display.newCircle( 0, 0, 1 )
			dots[n].x = runesX
			dots[n].y = runesY
			dots[n].index = n
			dots[n].isVisible = true   -- 測試完改成 false
			physics.addBody( dots[n], "dynamic", physicalProperties )
			dots[n].isSensor = true
			-- dots[n].CanCollision = true
			dots[n]:addEventListener( "collision", onCollision )
		end
	end

	--隊長＆隊員
	for i=1,6 do
		local j
		if i > 5 then
			j = i - 5
		else
			j = i
		end
		cards[i] = display.newImageRect( "Cards/0"..j..".png", 46, 46 )
		cards[i].x = 35 + 50 * (i - 1)
		cards[i].y = 193
	end

	--空的血量條
	nilHpLine = display.newRoundedRect( 0, 0, 0, 0, 3 )
	nilHpLine.anchorX = 0
	nilHpLine.anchorY = 0.5
	nilHpLine.x = 20
	nilHpLine.y = 224
	nilHpLine.width = 290
	nilHpLine.height = 10
	nilHpLine:setFillColor( 0, 0, 0 )
	nilHpLine.strokeWidth = 2
	nilHpLine:setStrokeColor( 1, 0, 0 )

	--血量條
	hpLine = display.newRoundedRect( 0, 0, 0, 0, 3 )
	hpLine.anchorX = 0
	hpLine.anchorY = 0.5
	hpLine.x = 20
	hpLine.y = 224
	hpLine.width = 290
	hpLine.height = 10
	hpLine:setFillColor( 0, 1, 0 )
	--hpLine.isVisible = false

	--移動時間條
	moveTime = display.newRoundedRect( 0, 0, 0, 0, 3 )
	moveTime.anchorX = 0
	moveTime.anchorY = 0.5
	moveTime.x = 20
	moveTime.y = 224
	moveTime.width = 290
	moveTime.height = 10
	moveTime:setFillColor( 0, 1, 1 )
	moveTime.isVisible = false

	--血量圖示
	circle = display.newCircle( 15, 224, 10 )
	circle:setFillColor( 1, 1, 1 )
	circle.strokeWidth = 2
	circle:setStrokeColor( 1, 0, 0 )
	hpIcon = display.newImageRect( "Images/heart.png", 12, 12 )
	hpIcon.x = 15
	hpIcon.y = 224

	--血量數值
	hpText = display.newText( hp.."/10000", 290, 232, native.systemFont , 12 )
	hpText.anchorX = 1
	hpText.anchorY = 1
end

--拖移符石
move = function ( e )
	-- if (!isHandle) then
	-- 	return 		
	-- end	
	if e.phase == "began" then
		--暫時的半透明符石
		tmpRune = display.newImageRect( grp_runes, e.target.runeData.image, runesWidth, runesHeight )
		tmpRune.x = dots[e.target.index].x
		tmpRune.y = dots[e.target.index].y
		tmpRune.alpha = 0.4
		tmpRune.index = e.target.index

		selectedRune = e.target
		physics.addBody( selectedRune, "dynamic", physicalProperties )
		selectedRune.isSensor = true
		selectedRune:addEventListener( "collision", onCollision )

		display.getCurrentStage( ):setFocus( selectedRune )
		selectedRune.isFocus = true
		selectedRune.oldX = selectedRune.x
		selectedRune.oldY = selectedRune.y
		selectedRune.x = e.x
		selectedRune.y = e.y - 10
		selectedRune:toFront( )
		-- selectedRune.alpha = 1
	elseif e.phase == "moved" then
		if (e.target.oldX == nil or e.target.oldY == nil) then
			return true
		end
		if isMoving == false then
			local event = { name = "touch", phase = "cancelled", target = selectedRune }
			selectedRune:dispatchEvent( event )
			-- return
		end
		if tmpRune == nil then
			return
		end
		local move_x = e.x - e.xStart
		local move_y = e.y - e.yStart
		selectedRune.x = e.target.oldX + move_x
		selectedRune.y = e.target.oldY + move_y

		--防止出界
		if (e.target.x > 310) then
			e.target.x = 310
		elseif (e.target.x < 10) then
			e.target.x = 10
		end
		if (e.target.y > 480) then
			e.target.y = 480
		elseif (e.target.y < 230) then
			e.target.y = 230
		end
	elseif e.phase == "cancelled" or e.phase == "ended" then
		if tmpRune == nil then
			return
		end
		if isMoving == true then
			isMoving = false
			timer.pause( move_tmr )
		end
		
		selectedRune.x , selectedRune.y = tmpRune.x , tmpRune.y --改成抓點的位置
		physics.removeBody( selectedRune )
		print( "removeBody" )
		
		tmpRune:removeSelf( )
		tmpRune = nil

		display.getCurrentStage( ):setFocus( nil )
		e.target.isFocus = false
		hpLine.isVisible = true
		moveTime.isVisible = false
		-- e.target.alpha = 1
	end

	return true
end

--碰撞事件
onCollision = function ( e )
	--print("pre other index:" , e.other.index)
	--print("pre target index:" , e.target.index)
	
	if e.phase == "began" then
		if e.target ~= selectedRune then
			print( "e.target ~= selectedRune" )
			return
		elseif selectedRune == nil then
			print( "selectedRune = nil" )
			return
		end

		print("other index:" , e.other.index)
		-- if e.target.index == e.other.index then
		-- 	print( "lastHitRune" )
		-- 	return
		-- end
		--print_r(runesTable)
		if isMoving == false then
			timeToMove(e)
		end

		if (e.target.index == e.other.index) then
			return
		end

		timer.performWithDelay( 1 , function ( )
			physics.pause( )

			--resumeTrans()

			local tmpX , tmpY = dots[e.target.index].x , dots[e.target.index].y
			local tran1 = transition.to( tmpRune, { time = 100 , x = dots[e.other.index].x , y = dots[e.other.index].y , onComplete = function (  )
				--table.remove( tran_pools , 1 )
			end} )
			--table.insert( tran_pools, #tran_pools + 1, tran1 )
			local tran2 = transition.to( runesTable[e.other.index] , { time = 100 , x = tmpX , y = tmpY  , onComplete = function (  )
				--table.remove( tran_pools , 1 )
			end} )
			-- table.insert( tran_pools, #tran_pools + 1, tran2)

			local tmpIndex = e.target.index
			e.target.index = e.other.index
			runesTable[e.other.index].index = tmpIndex

			local otherRune = runesTable[e.other.index]
			runesTable[e.other.index] = selectedRune
			runesTable[tmpIndex] = otherRune
			-- 
			-- local indexStr = ""
			-- local runeTypeStr = ""
			-- for i=1,#runesTable do
			-- 	indexStr = indexStr .. runesTable[i].index .. ","
			-- 	runeTypeStr = runeTypeStr .. runesTable[i].runeData.runeType .. ","
			-- end
			-- print(indexStr)
			-- print(runeTypeStr)
			-- 

			physics.start( )
		end)
	end
	
end

-- resumeTrans = function (  )
-- 	print("pool size:" , #tran_pools)
-- 	for i, v in ipairs(tran_pools) do
-- 		transition.resume( v )
-- 	end
-- end

timeToMove = function ( e )
	isMoving = true
	hpLine.isVisible = false
	moveTime.isVisible = true
	time = 5

	move_tmr = timer.performWithDelay( 100, function ( e )
		-- print_r(move_tmr)
		if time > 0 then
			-- print( time )
			if moveTime then
				moveTime:removeSelf( )
			end
			moveTime = display.newRoundedRect( 0, 0, 0, 0, 3 )
			moveTime.anchorX = 0
			moveTime.anchorY = 0.5
			moveTime.x = 20
			moveTime.y = 224
			moveTime.width = 58 * time
			moveTime.height = 10
			moveTime:setFillColor( 0, 1, 1 )

			time = time - 0.1
		else
			timer.pause( move_tmr )
			isMoving = false
			print( isMoving )
			local event = { name = "touch", phase = "cancelled", target = selectedRune }
			selectedRune:dispatchEvent( event )
			print( "times up" )
		end
	end, -1 )
end

--消除符石
ClearUpRunes = function (  )
	
end

--檢查符石
checkRunes = function (  )
	local isSame = false
	if runesTable[n+2].index == runesTable[n+1].index == runesTable[n].index then
		isSame = true
	end
end

--30個符石的位置
-- putin = function ( e )
-- 	for i=1,5 do
-- 		local rangeY = e.target.y >= 430 - 50 * (i - 1) and e.target.y <= 480 - 50 * (i - 1)
-- 		for j=1,6 do
-- 			local rangeX = e.target.x >= 10 + 50 * (j - 1) and e.target.x <= 60 + 50 * (j - 1)
-- 			if rangeX and rangeY then
-- 				e.target.x = 35 + 50 * (j - 1)
-- 				e.target.y = 455 - 50 * (i - 1)
-- 			end
-- 		end
-- 	end
-- end

--深層列印Table
function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

--=======================================================================================
--Composer
--=======================================================================================
--畫面沒到螢幕上時，先呼叫scene:create
--任務:負責UI畫面繪製
function scene:create(event)
	--把場景的view存在sceneGroup這個變數裡
	local sceneGroup = self.view
	if (isDebug) then
		print( "scene:create" )
	end
	--接下來把會出現在畫面的東西，加進sceneGroup裡面
	initial()
end

--畫面到螢幕上時，呼叫scene:show
--任務:移除前一個場景，播放音效，開始計時，播放各種動畫
function  scene:show(event)
	local sceneGroup = self.view
	local phase = event.phase
	if( "will" == phase ) then
		if (isDebug) then
			print( "show:will" )
		end
		--畫面即將要推上螢幕時要執行的程式碼寫在這邊
	elseif ( "did" == phase ) then
		if (isDebug) then
			print( "show:did" )
		end
		--把畫面已經被推上螢幕後要執行的程式碼寫在這邊
		--可能是移除之前的場景，播放音效，開始計時，播放各種動畫
		--composer.removeScene( "main", isRecycle )
	end
end

--即將被移除，呼叫scene:hide
--任務:停止音樂，釋放音樂記憶體，停止移動的物體等
function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	if ( "will" == phase ) then
		if (isDebug) then
			print( "hide:will" )
		end
		--畫面即將移開螢幕時，要執行的程式碼
		--這邊需要停止音樂，釋放音樂記憶體，有timer的計時器也可以在此停止
	elseif ( "did" == phase ) then
		if (isDebug) then
			print( "hide:did" )
		end
		--畫面已經移開螢幕時，要執行的程式碼
	end
end

--下一個場景畫面推上螢幕後
--任務:摧毀場景
function scene:destroy( event )
	if ("will" == event.phase) then
		if (isDebug) then
			print( "destroy" )
		end
		--這邊寫下畫面要被消滅前要執行的程式碼
	end
end

--=======================================================================================
--加入偵聽器
--=======================================================================================
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene