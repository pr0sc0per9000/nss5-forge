' TRoulette.Draw
' VA 0x00575729   108 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory, mode=reloc)
' The name here is g_roulettewheel, not g_wheel. NOT a type conflict: `g_wheel` is one
' NAME over TWO addresses. This one (0x00C6BBBC) is a TRouletteWheel -- assigned at
' 0x00575533 from call [0x00C6BE3C] = TRouletteWheel classtable + 0x30 = Create().
' The other (0x00C6BCB4, in TRouletteWheel.Create.bmx) is the Wheel.png TImage and
' keeps the name. Both types are right; only the shared name was wrong.
' The ball Global has the same defect one line up and for the same reason:
' `g_roul_ball` is one NAME over TWO addresses. This one (0x00C6BBC0) is the
' TRouletteBall, assigned from TRouletteBall.Create; 0x00C5DEA4 is the match-engine TBall
' that 30+ TPlayer bodies declare as g_roul_ball:TBall (codegen-patterns 11.2 documents that
' address). Assembled together they are ONE identifier -- BlitzMax is case-insensitive --
' so the corpus claimed `Object vs TGadget`-style conflicts that were really collisions.
' Both types were right; only the shared name was wrong. Names have no codegen effect
' (codegen-patterns 4), and this body re-verified 108/108 after the rename.
' Globals: 0x00C6BBBC g_roulettewheel:TRouletteWheel, 0x00C6BBC0 g_roul_ball:TRouletteBall,
'          0x00C6172C g_roul_f:Float.
' 0x00506456 is the recovered module Function SetDrawStateHex; the literal at 0x00C5D680
' reads "FFFFFF" out of NSS5.exe. Slot 0x3C on both roulette Types is Draw(f).
	Function Draw:Int()
		'!Global g_roulettewheel:TRouletteWheel
		'!Global g_roul_f:Float
		'!Global g_roul_ball:TRouletteBall
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
		g_roulettewheel.Draw(g_roul_f)
		g_roul_ball.Draw(g_roul_f)
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
	End Function
