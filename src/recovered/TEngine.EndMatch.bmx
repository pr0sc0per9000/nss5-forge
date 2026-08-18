' TEngine.EndMatch
' VA 0x004d732f   530 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (STATIC method on TEngine), SIG ()i, class-table slot 0xe0
' ASSUMPTIONS
'  * Module Globals -- NAMES ARE OURS, the declared TYPES are load-bearing because they
'    pick the dispatch slot:
'      g_engine_int13:Int      0x00C5B1CC   g_matchstate:Int   0x00C5B1FC
'      g_engine_int20:Int      0x00C5B210
'      g_engine_fixture:TFixture 0x00C5B22C -- globals_final says "TPlayer (guess), UNSOUND
'        uniqueness claim".  It is NOT TPlayer: the code does `call [eax+0x58]` with TWO
'        object arguments, and TPlayer slot 0x58 is the STATIC RenderGUIAll(f,f).  TFixture
'        slot 0x58 is Method UpdatePoints(:TTableData,:TTableData) -- 2 objects -- and the
'        field written just before is +0x24, which is TFixture.result (the same field
'        TCompetition.PlayFixtures tests against -1).
'      g_engine_player:TPlayer 0x00C5B248  (released and nulled; type not byte-observable)
'      g_training_int03:Int    0x00C6CF90
'      g_playerteam:TTeam      0x00C5B218   g_opponentteam:TTeam 0x00C5B21C
'        globals_final says TKit for 0x00C5B218; TKit slot 0x40 is GetPaintedFan(i,i) which
'        takes two arguments, and the call site passes none.  TTeam slot 0x40 is Clear().
'        0x00C5B218 is already TTeam in TBall.CheckSideLines.
'      g_engine_obj20:TTable   0x00C5B2B0 -- GUESS.  All the bytes require is a Type whose
'        slot 0x34 is a no-argument Method; 30 Types qualify (TTable/TButton/TCombo/... all
'        .Update()).  The Type is not determined by this function.
'      g_profile:TProfile      0x00C6F028  (+0x78 = contractwage)
'      g_engine_memstart:Int   0x00C5B378   g_engine_memend:Int 0x00C5B37C
'      g_engine_fnend:Int()    0x00C5B1C0 -- a FUNCTION-POINTER Global, `call [0xC5B1C0]`
'        with no arguments and no receiver.  globals_final calls it Int; it is Int().
'  * Sibling static calls inside TEngine's own class table are written unprefixed
'    (StopChannels = TEngine+0x38, ResetStats = TEngine+0xFC) per guide 3d.
'  * FUN_004A8980 = GCCollect, FUN_004A8550 = GCMemAlloced (arity 0, returns Int).
'  * String literals read out of NSS5.exe: 0x00C73AE0 ">>> MemAlloced = ",
'    0x00C744C4 ">>> Mem Lost   = " (three spaces before the '=').
	Function EndMatch:Int()
		'!Global g_engine_player:TPlayer
		'!Global g_engine_int13:Int
		'!Global g_matchstate:Int
		'!Global g_engine_int20:Int
		'!Global g_engine_fixture:TFixture
		'!Global g_training_int03:Int
		'!Global g_playerteam:TTeam
		'!Global g_opponentteam:TTeam
		'!Global g_engine_obj20:TTable
		'!Global g_profile:TProfile
		'!Global g_engine_memstart:Int
		'!Global g_engine_memend:Int
		'!Global g_engine_fnend:Int()
		FlushAllInput()
		g_engine_int13 = 0
		g_matchstate = 0
		g_engine_int20 = 0
		TOptions.SaveOptions()
		StopChannels()
		If g_engine_fixture <> Null And g_training_int03 = 0
			g_engine_fixture.result = -1
			g_engine_fixture.UpdatePoints(Null, Null)
		EndIf
		g_engine_fixture = Null
		ResetStats()
		g_engine_player = Null
		TBall.ClearAll()
		If g_playerteam <> Null
			g_playerteam.Clear()
			g_playerteam = Null
		EndIf
		If g_opponentteam <> Null
			g_opponentteam.Clear()
			g_opponentteam = Null
		EndIf
		TPlayer.ClearAll()
		TScreenMessage.ClearAll(0)
		If g_engine_obj20 <> Null Then g_engine_obj20.Update()
		TPitchMark.ResetPitchMarks()
		TPhotographer.ClearAll()
		TCameraMan.ClearAll()
		TDrawOb.ClearAll()
		TParticle.ClearAll()
		If g_profile.contractwage > 0 Then PlayTrack(2)
		GCCollect()
		g_engine_memend = GCMemAlloced()
		LogLine(">>> MemAlloced = " + g_engine_memend)
		LogLine(">>> Mem Lost   = " + (g_engine_memstart - g_engine_memend))
		g_engine_fnend()
	End Function
