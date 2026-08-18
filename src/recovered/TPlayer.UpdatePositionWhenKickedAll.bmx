' TPlayer.UpdatePositionWhenKickedAll
' VA 0x004fed92   202 bytes   vtable slot 0x21c   sig (i)i
' byte-identical vs NSS5.exe (202/202, original length from Ghidra's inventory, mode=reloc)
' assumes module Globals (names ours, types load-bearing):
'   Global g_players:TList  (0x00C5DE10)  -- no null guard here, the loop starts directly
'   Global g_ball:TBall     (0x00C5DEA4)  -- globals_final guesses TPlayer from usage, but
'                                            the access is +0x74 compared against a TPlayer,
'                                            which is TBall.lastkickedby:TPlayer
' the EachIn downcast class table is TPlayer (0x00C5F94C); FUN_005B9690 is the
'   Double->Int truncation helper bcc emits for Int(x).
' the inner test is written `<>` with the copy first: as `If p = ... Then 0 Else copy` the
'   two arms come out swapped (first_diff at byte 130, je vs jne).
'!Global g_players:TList
'!Global g_ball:TBall

	Function UpdatePositionWhenKickedAll:Int(a0:Int)
		For Local p:TPlayer = EachIn g_players
			p.posxwhenkicked = Int(p.x)
			p.posywhenkicked = Int(p.y)
			If a0 = p.teamid Then
				If p <> g_ball.lastkickedby Then
					p.offsidewhenkicked = p.offside
				Else
					p.offsidewhenkicked = 0
				EndIf
			Else
				p.offsidewhenkicked = 0
			EndIf
		Next
	End Function
