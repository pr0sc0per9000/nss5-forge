' GetBootBonus  -- module-level Function (no Type)
' VA 0x00507ddd   592 bytes   sig (i,i)i
' byte-identical vs NSS5.exe (592/592, original length from Ghidra's inventory, mode=exact)
'
' NAME IS OURS. Called from TPlayer.CreatePlayerSimple as GetBootBonus(bootIdx, statCategory)
' where bootIdx is 1..10 (index into TProfile.boots[], -1 = no boot owned) and statCategory is
' 2/4/6 (dribbling/passing/shooting). Pure lookup table returning a small 0..2 bonus; falls
' through to 0 for any unmatched pair, including bootIdx = -1.
'
' CODEGEN NOTE: this is a NESTED Select, not an outer Select with inner If/ElseIf. The flat
' If-chain form for the inner test came out 565/592 (register colours swapped: a0 in eax/a1 in
' edx instead of the original's a0 in edx/a1 in eax, plus several Case bodies one instruction
' shorter). `Select a0 / Case N / Select a1 / Case M Return X / End Select` is exact at 592/592
' and puts a0 in edx, a1 in eax -- matching the original's registers exactly.
	Function GetBootBonus:Int(a0:Int, a1:Int)
		Select a0
			Case 1
				Select a1
					Case 2 Return 1
					Case 4 Return 0
					Case 6 Return 0
				End Select
			Case 2
				Select a1
					Case 2 Return 0
					Case 4 Return 1
					Case 6 Return 0
				End Select
			Case 3
				Select a1
					Case 2 Return 0
					Case 4 Return 0
					Case 6 Return 1
				End Select
			Case 4
				Select a1
					Case 2 Return 1
					Case 4 Return 1
					Case 6 Return 0
				End Select
			Case 5
				Select a1
					Case 2 Return 1
					Case 4 Return 0
					Case 6 Return 1
				End Select
			Case 6
				Select a1
					Case 2 Return 0
					Case 4 Return 1
					Case 6 Return 1
				End Select
			Case 7
				Select a1
					Case 2 Return 1
					Case 4 Return 1
					Case 6 Return 1
				End Select
			Case 8
				Select a1
					Case 2 Return 2
					Case 4 Return 1
					Case 6 Return 1
				End Select
			Case 9
				Select a1
					Case 2 Return 2
					Case 4 Return 2
					Case 6 Return 1
				End Select
			Case 10
				Select a1
					Case 2 Return 2
					Case 4 Return 2
					Case 6 Return 2
				End Select
		End Select
		Return 0
	End Function
