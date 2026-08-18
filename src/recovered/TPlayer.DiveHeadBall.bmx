' TPlayer.DiveHeadBall
' VA 0x004F9156   171 bytes   mode=reloc   byte-identical vs NSS5.exe (171/171)
' KIND=Method, SIG ()i, slot 0x120
' ASSUMPTIONS
'  * 0x00C5DEA4 is the module Global holding the match ball. globals_final.tsv types it
'    TPlayer; guide 11.2 corrects it to TBall, and the two calls here confirm that --
'    slot 0x84 = TBall.NewController(:TPlayer) and slot 0x68 = TBall.Kick(:TPlayer,f,f,i,i).
'  * 0x00506049 is the recovered module Function AngleDiff (src/recovered_module).
'  * ClampFloat's first parameter is a Var/Ptr; `Varptr d` and a Var argument compile
'    identically (see ClampFloat.bmx).
'  * The float constant at 0x00C7A038 is 20.0; the four zero Float arguments to AddStat
'    push as `6A 00`.
	'!Global g_ball:TBall
	LogLine("DiveHeadBall")
	g_ball.NewController(Self)
	Self.kickpower = 20.0
	Local d:Float = AngleDiff(Self.direction, Self.joy.direction, 0)
	ClampFloat(Varptr d, -30.0, 30.0)
	g_ball.Kick(Self, Self.direction + d, Self.kickpower, 4, -1)
	Self.AddStat(6, 0, 0, 0, 0)
