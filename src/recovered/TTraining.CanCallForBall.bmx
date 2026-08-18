' TTraining.CanCallForBall
' VA 0x00581d7f   290 bytes   class-table slot 0xa0   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (290/290, original length from Ghidra's inventory, mode=reloc)
'
' GLOBAL NAMES ARE OURS. 0x00C6CF90 Int (training mode), 0x00C5DEA4 TBall (field 0x20 = z),
' 0x00C5DE70 Int.  The eight Case compares are emitted back to back with every target past
' the last one -- a Select, not an If/ElseIf chain (patterns 10.2).
'!Global g_training_mode:Int
'!Global g_matchball:TBall
'!Global g_ballheightscale:Int
	Function CanCallForBall:Int()
		Select g_training_mode
			Case 0
				Return 1
			Case 1
				Return 0
			Case 2
				Return 0
			Case 3
				Return 0
			Case 4
				Return 0
			Case 5
				Return 0
			Case 6
				Return 0
			Case 10
				Return 0
			Default
				Local p:TPlayer = TPlayer.GetHumanPlayer()
				If p And g_matchball And g_matchball.z > g_ballheightscale * 0.5 And p.distancetoball < TPitch.YardsToPixels(10.0) Then Return 0
		End Select
		Return 1
	End Function
