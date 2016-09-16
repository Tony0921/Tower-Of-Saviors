-----------------------------------------------------------------------------------------
-- Tower Of Saviors
-- home.lua
-- Tony Chen
-- 2016/9/12
-----------------------------------------------------------------------------------------

--=======================================================================================
--引入各種函式庫
--=======================================================================================
local composer = require("composer")
local scene = composer.newScene( )
--=======================================================================================
--宣告全域變數
--=======================================================================================


--=======================================================================================
--宣告區域變數
--=======================================================================================
local map
local top
local floor
local mapGroup = display.newGroup( )

--function
local initial
local move
--=======================================================================================
--定義各種函式
--=======================================================================================
initial = function ( group )
	map = display.newImageRect( mapGroup, "Images/map.png", 0, 0 )
	map.width = _SCREEN.WIDTH
	map.height = 5798 / 3.375
	map.x = _SCREEN.CENTER.X
	map.y = _SCREEN.CENTER.Y + 125
	map:addEventListener( "touch", move )

	group:insert( mapGroup )
	mapGroup.x = 0
	mapGroup.y = 0

	top = display.newImageRect( group, "Images/newTop.png", 0, 0 )
	top.x = 0
	top.y = 0
	top.anchorX = 0
	top.anchorY = 0
	top.width = _SCREEN.WIDTH
	top.height = 242 / (1077/320)

	floor = display.newImageRect( group, "Images/newFloor.png", 0, 0 )
	floor.x = 0
	floor.y = _SCREEN.HEIGHT
	floor.anchorX = 0
	floor.anchorY = 1
	floor.width = _SCREEN.WIDTH
	floor.height = 313 / (1080/320)
end

move = function ( e )
	if e.phase == "began" then
		display.getCurrentStage( ):setFocus( map )
		map.oldY = map.y

		-- map.y = e.y
	elseif e.phase == "moved" then
		if ( e.target.oldY == nil) then
			return true
		end

		local move_y = e.y - e.yStart

		map.y = map.oldY + move_y
		if e.target.y > 838 then
			e.target.y = 838
		elseif e.target.y < -358 then
			e.target.y = -358
		end
	elseif e.phase == "canclled" or e.phase == "ended" then
		display.getCurrentStage( ):setFocus( nil )
	end
end
--=======================================================================================
--Composer
--=======================================================================================

--畫面沒到螢幕上時，先呼叫scene:create
--任務:負責UI畫面繪製
function scene:create(event)
	--把場景的view存在sceneGroup這個變數裡
	local sceneGroup = self.view
	--接下來把會出現在畫面的東西，加進sceneGroup裡面
	initial(sceneGroup)
end


--畫面到螢幕上時，呼叫scene:show
--任務:移除前一個場景，播放音效，開始計時，播放各種動畫
function  scene:show( event)
	local sceneGroup = self.view
	local phase = event.phase

	if( "will" == phase ) then
		--畫面即將要推上螢幕時要執行的程式碼寫在這邊
	elseif ( "did" == phase ) then
		--把畫面已經被推上螢幕後要執行的程式碼寫在這邊
		--可能是移除之前的場景，播放音效，開始計時，播放各種動畫

	end
end


--即將被移除，呼叫scene:hide
--任務:停止音樂，釋放音樂記憶體，停止移動的物體等
function scene:hide( event )
	
	local sceneGroup = self.view
	local phase = event.phase

	if ( "will" == phase ) then
		--畫面即將移開螢幕時，要執行的程式碼
		--這邊需要停止音樂，釋放音樂記憶體，有timer的計時器也可以在此停止
	elseif ( "did" == phase ) then
		--畫面已經移開螢幕時，要執行的程式碼
	end
end

--下一個場景畫面推上螢幕後
--任務:摧毀場景
function scene:destroy( event )
	if ("will" == event.phase) then
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