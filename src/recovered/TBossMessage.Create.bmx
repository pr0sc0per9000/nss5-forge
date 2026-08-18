' TBossMessage.Create
' VA 0x00570973   212 bytes   vtable slot 0x34   sig (i,$,$)i
' byte-identical vs NSS5.exe (212/212, original length from Ghidra's inventory, mode=reloc)
' Globals: 0x00C5D298 g_nomsgs:Int, 0x00C5D674 g_msgx:Int, 0x00C5D678 g_msgy_away:Int,
'          0x00C5D67C g_msgy_home:Int, 0x00C6EFD8 g_starttime:Int, 0x00C6EFD4 g_ticks:Int.
' Ghidra's timeGetTime import call is BlitzMax MilliSecs().
' The guard is an early return (`cmp [g],1 / jne / mov eax,0 / jmp`); the If-block form is 206.
' The y branch is `If a0` with the AWAY value in the Then arm -- `If a0 = 0` inverts the jcc.
	Function Create:Int(a0:Int, a1:String, a2:String)
		'!Global g_nomsgs:Int
		'!Global g_msgx:Int
		' g_msgy_away/g_msgy_home are aliases (a different name
		' choice) for the same two addresses TPlayer.DoAnimCelebrate.bmx already declares as
		' g_pitch_int18/g_pitch_int19 -- 0x00C5D678=140, 0x00C5D67C=-140. merge_globals dedups
		' by NAME, so this pair needs its own initialiser too or it stays a separate,
		' zero-defaulted Global in the assembled build (codegen-patterns 21.1/21.3).
		'!Global g_msgy_away:Int = 140
		'!Global g_msgy_home:Int = -140
		'!Global g_starttime:Int
		'!Global g_ticks:Int
		If g_nomsgs = 1 Then Return 0
		Local m:TBossMessage = New TBossMessage
		m.homeboss = a0
		m.x = g_msgx + 10
		If a0
			m.y = g_msgy_away - 20
		Else
			m.y = g_msgy_home - 20
		End If
		m.message = a1
		m.starttime = MilliSecs() - g_starttime
		m.delaytime = 1750
		m.finishtime = g_ticks + m.delaytime
		m.alfa = 1.0
		m.colour = a2
	End Function
