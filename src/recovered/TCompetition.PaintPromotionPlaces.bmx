' TCompetition.PaintPromotionPlaces
' VA 0x0050DA76   313 bytes   vtable slot 0xec
' byte-identical vs NSS5.exe (313/313, original length from Ghidra's inventory, mode=reloc)
'
' The Select has SIX cases, not five: `Case 0` with an EMPTY body, then Case 1..5 each
' with its own identical `col = ShiftColourHex(col,64)` statement. Ghidra prints the empty
' case as the enclosing `if (n != 0)`. Collapsing 1..5 into `Case 1,2,3,4,5` is 71 bytes short;
' omitting the empty Case 0 is 7 bytes short.
' The row-half test is `If p.place > a0.CountItems()/2` -- Ghidra printed the operands the
' other way round and that spelling diffs at byte 125 (10.1).
	Method PaintPromotionPlaces:Int(a0:TTable)
		a0.SetRowColoursAll("FFFFFF")
		For Local p:TPromotionPlace = EachIn Self.lpromotionplaces
			Local col:String = "6666FF"
			If p.place > a0.CountItems()/2 Then col = "FF0000"
			Select TCompetition.SelectById(p.promotiontoid).comptype
				Case 0
				Case 1
					col = ShiftColourHex(col, 64)
				Case 2
					col = ShiftColourHex(col, 64)
				Case 3
					col = ShiftColourHex(col, 64)
				Case 4
					col = ShiftColourHex(col, 64)
				Case 5
					col = ShiftColourHex(col, 64)
			End Select
			a0.SetRowColour(p.place, col)
		Next
	End Method
