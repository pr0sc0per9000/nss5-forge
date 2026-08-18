' TPlayer.KeeperDive
' VA 0x004f4124   686 bytes   vtable slot 0xbc   sig (:TInterceptPoint,i)i
' byte-identical vs NSS5.exe (686/686, original length from Ghidra's inventory)
' assumes module global:  Global g_player_float08:Float   (0x00c5de5c)
' assumes module global:  Global g_player_tplayer02:TBall  (0x00c5dea4)
' assumes module global:  Global g_player_arr22:Int[]      (0x00c5df00)
' assumes module global:  Global g_player_arr23:Int[]      (0x00c5df04)
' Cos()/Sin() must be the LEFT operand of the product: sp*Cos(d) spills two Double temps (+24 bytes).
' Parameter names are not recoverable from the binary; a0/a1 as emitted by the harness.

	Method KeeperDive:Int(a0:TInterceptPoint,a1:Int)
		'!Global g_player_float08:Float
		'!Global g_player_tplayer02:TBall
		'!Global g_player_arr22:Int[]
		'!Global g_player_arr23:Int[]
		LogLine("KeeperDive:" + a1)
		Select a1
		Case 0
			Self.zvel = 0
			Self.currentanim = g_player_arr23
		Case 1
			Self.zvel = g_player_float08 * 0.5
			Self.currentanim = g_player_arr22
		Case 2
			Self.zvel = g_player_float08
			Self.currentanim = g_player_arr22
		End Select
		If Self.xvel > 1.0
			Select Self.GetShootingDirection()
			Case -1
				a0.intercept_AB = -1.0
			Case 1
				a0.intercept_AB = 1.0
			End Select
		ElseIf Self.xvel < -1.0
			Select Self.GetShootingDirection()
			Case -1
				a0.intercept_AB = 1.0
			Case 1
				a0.intercept_AB = -1.0
			End Select
		Else
			Local d:Float = Dist2D(Self.x,Self.y,g_player_tplayer02.lastkickedby.posxwhenkicked,g_player_tplayer02.lastkickedby.posywhenkicked)
			If d < TPitch.YardsToPixels(5.0)
				a0.intercept_AB = Rnd(0.0,1.0)
			EndIf
		EndIf
		If a0.intercept_AB > 0.5
			Self.frame = 0
			Self.direction = 0
			If Self.GetShootingDirection() = -1 Then Self.direction = 180.0
		Else
			Self.frame = 0
			Self.direction = 180.0
			If Self.GetShootingDirection() = -1 Then Self.direction = 0
		EndIf
		Local sp:Float = Self.distancetoball / 30.0
		Self.xvel = Cos(Self.direction) * sp
		Self.yvel = Sin(Self.direction) * sp
	End Method
