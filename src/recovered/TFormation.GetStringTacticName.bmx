' TFormation.GetStringTacticName
' VA 0x004D9856   187 bytes   vtable slot 0x64   sig (i)$
' byte-identical vs NSS5.exe (187/187, original length from Ghidra's inventory)
' Select/Case (not If/ElseIf): the original tests all 14 constants before any case body. Literals read out of NSS5.exe .data.
' No Default case - the fallback Return sits after End Select.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Function GetStringTacticName:String(a0:Int)
		Select a0
		Case 1
			Return "3-4-3"
		Case 2
			Return "3-5-2 A"
		Case 3
			Return "3-5-2 B"
		Case 4
			Return "4-2-2-2"
		Case 5
			Return "4-2-4"
		Case 6
			Return "4-3-3"
		Case 7
			Return "4-4-1-1"
		Case 8
			Return "4-4-2 A"
		Case 9
			Return "4-4-2 B"
		Case 10
			Return "4-5-1"
		Case 11
			Return "5-3-2"
		Case 12
			Return "Custom 1"
		Case 13
			Return "Custom 2"
		Case 14
			Return "Custom 3"
		End Select
		Return "4-4-2 A"
	End Function
