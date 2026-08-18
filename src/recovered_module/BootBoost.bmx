' BootBoost  -- module-level Function (no Type)
' VA 0x00507ddd   592 bytes   sig (i,i)i
' byte-identical vs NSS5.exe (592/592, original length from Ghidra's inventory, mode=exact,
' verified with NSS5_NO_LEARN=1 -- the body calls nothing, so nothing could be learned)
'
' NAME IS OURS. A pure lookup table: given a boot tier a0 (1..10) and a stat selector a1
' (2, 4 or 6) it returns that boot's boost for that stat, 0..2. 9 call sites; three of
' them are TScreen_MatchPrep.SetUpScreen, which applies the results to dribbling (2),
' passing (4) and shooting (6).
'
' The nested Select is load-bearing (codegen-patterns 10.2): every Case compare is emitted
' back to back before any body, and each inner Select's no-match path jumps past the OUTER
' End Select to the implicit `Return 0` tail at 0x00508022. There is no explicit trailing
' Return -- bcc emits `mov eax,0 / jmp epilogue` for the fallthrough of an :Int Function.
	Function BootBoost:Int(a0:Int, a1:Int)
		Select a0
			Case 1
				Select a1
					Case 2
						Return 1
					Case 4
						Return 0
					Case 6
						Return 0
				End Select
			Case 2
				Select a1
					Case 2
						Return 0
					Case 4
						Return 1
					Case 6
						Return 0
				End Select
			Case 3
				Select a1
					Case 2
						Return 0
					Case 4
						Return 0
					Case 6
						Return 1
				End Select
			Case 4
				Select a1
					Case 2
						Return 1
					Case 4
						Return 1
					Case 6
						Return 0
				End Select
			Case 5
				Select a1
					Case 2
						Return 1
					Case 4
						Return 0
					Case 6
						Return 1
				End Select
			Case 6
				Select a1
					Case 2
						Return 0
					Case 4
						Return 1
					Case 6
						Return 1
				End Select
			Case 7
				Select a1
					Case 2
						Return 1
					Case 4
						Return 1
					Case 6
						Return 1
				End Select
			Case 8
				Select a1
					Case 2
						Return 2
					Case 4
						Return 1
					Case 6
						Return 1
				End Select
			Case 9
				Select a1
					Case 2
						Return 2
					Case 4
						Return 2
					Case 6
						Return 1
				End Select
			Case 10
				Select a1
					Case 2
						Return 2
					Case 4
						Return 2
					Case 6
						Return 2
				End Select
		End Select
	End Function
