' TTraining.GetMatchState
' VA 0x0058256D   324 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_tr_active:Int   ' 0x00C6CF98
'!Global g_tr_mode:Int     ' 0x00C6CF90
'!Global g_tr_count:Int    ' 0x00C6CFFC
'!Global g_tr_x1:Int       ' 0x00C6CFD0
'!Global g_tr_y1:Int       ' 0x00C6CFD4
'!Global g_tr_x2:Int       ' 0x00C6CFD8
'!Global g_tr_y2:Int       ' 0x00C6CFDC
If g_tr_active = 0
	a0[0] = 0
	Return 0
End If
Select g_tr_mode
	Case 1
		a0[0] = 1
	Case 2
		a0[0] = 1
	Case 3
		a0[0] = 4
		g_tr_count :- 1
		a1[0] = g_tr_x1
		a2[0] = g_tr_y1
		ResetTraining()
	Case 4
		a0[0] = 1
	Case 5
		a0[0] = 1
	Case 6
		a0[0] = 4
		g_tr_count :- 1
		a1[0] = g_tr_x1
		a2[0] = g_tr_y1
		ResetTraining()
	Case 7
		a0[0] = 1
	Case 8
		a0[0] = 1
	Case 9
		a0[0] = 1
	Case 10
		a0[0] = 4
		g_tr_count :- 1
		a1[0] = g_tr_x2
		a2[0] = g_tr_y2
		TDummy.UpdateWallLocations(g_tr_x2, g_tr_y2)
		TDummy.ResetDummies()
End Select
