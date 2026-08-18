' TRouletteWheel.GetColour
' VA 0x00575CA9   343 bytes   vtable slot 0x40   sig (i)i
' byte-identical vs NSS5.exe (343/343, original length from Ghidra's inventory)
' oracle mode 'exact' -- no relocations needed masking, every byte agrees literally.
' Select, not If/ElseIf: the original loads a0 into eax once and cmp/je per case.
' Each Case has its own body; they are not collapsed into Case 1,3,5,...
	Function GetColour:Int(a0:Int)
		Select a0
			Case 0
				Return -1
			Case 1
				Return 1
			Case 3
				Return 1
			Case 5
				Return 1
			Case 7
				Return 1
			Case 9
				Return 1
			Case 12
				Return 1
			Case 14
				Return 1
			Case 16
				Return 1
			Case 18
				Return 1
			Case 19
				Return 1
			Case 21
				Return 1
			Case 23
				Return 1
			Case 25
				Return 1
			Case 27
				Return 1
			Case 30
				Return 1
			Case 32
				Return 1
			Case 34
				Return 1
			Case 36
				Return 1
			Case 37
				Return -1
			Default
				Return 0
		End Select
	End Function
