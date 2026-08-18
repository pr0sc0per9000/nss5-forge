' TPlayer.BlockSave
' VA 0x004f89ce   156 bytes   vtable slot 0x114   sig ()i
' byte-identical vs NSS5.exe (156/156, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00c5dea4 declared TBall, NOT TPlayer. globals_final.tsv
' types it TPlayer on the grounds that "only TPlayer has slots 0x68,0x84,0x88,0x90" --
' that is wrong, TBall has all four as well (Kick / NewController / KeeperHolding /
' Deflect), and the +0x70 field dereference is TBall.controlledby:TPlayer. TPlayer slot
' 0x1e0 = DoAnimFall.
' Module Global 0x00c5df18 declared Int[] (currentanim is an Int[] field, compared by
' reference against an animation table Global).
' The kickpower constant is a masked .data Float address; its VALUE is not proven.
' FUN_00505b91 is the recovered module Function LogLine. harness mode=reloc, 9 masked.
' CONSTANT CORRECTED: kickpower was 12.0, the original loads 2.0 (fld [0x00C79F08] at +88).
'   The oracle masks the .rdata ADDRESS, so both values matched equally and the body was
'   verified with the wrong number. Found by scripts/check_floats.py. Re-verified MATCH.
	Method BlockSave:Int()
		'!Global g_ball:TBall
		'!Global g_anim_dive:Int[]
		LogLine("BlockSave")
		If g_ball.controlledby <> Null Then g_ball.controlledby.DoAnimFall()
		g_ball.NewController(Self)
		If currentanim <> g_anim_dive Then
			kickpower = 2.0
			g_ball.Kick(Self, directiontoball, kickpower, 1, -1)
		End If
	End Method
