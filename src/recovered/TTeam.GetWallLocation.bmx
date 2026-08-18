' TTeam.GetWallLocation
' VA 0x004E0A62   317 bytes   vtable slot 0x80   sig (i,i,i,*f,*f)i   KIND=Method
' byte-identical vs NSS5.exe (317/317, original length from Ghidra's inventory, mode=reloc)
' Assumption: module Global 0x00C5D638 is an Int -- bare mov + imul, no refcount traffic.
' The five-way dispatch is a SELECT, not If/ElseIf: the cmp/je pairs are emitted back to
' back and the no-match path is the trailing EB 23 jmp (no Default).
' Operand order is load-bearing: Cos(ang + a0), not Cos(a0 + ang).
	Method GetWallLocation:Int(a0:Int, a1:Int, a2:Int, a3:Float Ptr, a4:Float Ptr)
		'!Global g_wallDist:Int
		Local ang:Float = ATan2(a2 - g_wallDist * (-Self.GetShootingDirection()), a1)
		Select a0
			Case 5
				a0 = 0
			Case 4
				a0 = 5
			Case 3
				a0 = -5
			Case 2
				a0 = 10
			Case 1
				a0 = -10
		End Select
		a3[0] = a1 - Cos(ang + a0) * TPitch.YardsToPixels(10.2)
		a4[0] = a2 - Sin(ang + a0) * TPitch.YardsToPixels(10.2)
	End Method
