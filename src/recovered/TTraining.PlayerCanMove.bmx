' TTraining.PlayerCanMove
' VA 0x005829ED   252 bytes
' byte-identical vs NSS5.exe (252/252, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_intraining:Int
If a0.selectionno = 0 Then Return 1
Local b:TBall = TBall.GetActiveBall()
Select g_intraining
Case 1
Case 2
Case 3
	If b And b.controlledby <> a0 Then Return 0
Case 4
Case 5
Case 6
	If b And b.controlledby <> a0 Then Return 0
Case 7
Case 8
Case 9
Case 10
	If b And b.controlledby <> a0 Then Return 0
End Select
Return 1
