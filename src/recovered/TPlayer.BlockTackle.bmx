' TPlayer.BlockTackle
' VA 0x004F889E   304 bytes   vtable slot 0x110   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (304/304, mode=reloc, reloc_masked=17)
'
' ASSUMPTIONS:
'   g_activeball = 0x00C5DEA4  TBall  (codegen-patterns 11.2)
'   the float stored into kickpower is the .rdata constant at 0x00C79EE4 = 5.0 (read out
'   of NSS5.exe, not guessed)
'   0x004A7410 = _brl_retro_Lower  -> Lower(GetText("Tackle"))
'   0x00C6AFC0 = TParticle class table + 0x38 = StarShower(i,i,$,$)

	Method BlockTackle:Int()
		'!Global g_ball:TBall
		LogLine("BlockTackle")
		If g_ball.controlledby <> Null
			If g_ball.controlledby.selectionno = 0 Then Return 0
			g_ball.controlledby.DoAnimFall()
		EndIf
		Self.AddStat(8,0,0,0,0)
		g_ball.NewController(Self)
		Self.kickpower = 5.0
		Self.DoAnimKick(Int(Self.kickpower))
		g_ball.Kick(Self,Self.directiontoball,Self.kickpower,1,-1)
		If Self.newstar <> 0
			TParticle.StarShower(Int(Self.x),Int(Self.y),Lower(GetText("Tackle")),"FF0099")
		EndIf
	End Method
