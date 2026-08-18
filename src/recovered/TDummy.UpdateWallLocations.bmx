' TDummy.UpdateWallLocations
' VA 0x005836D9   398 bytes   vtable slot 0x54   sig (i,i)i   KIND=Function (static)
' byte-identical vs NSS5.exe (398/398, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C5D638 g_wallDist:Int (shared with TTeam.GetWallLocation),
'              0x00C6D568 g_dummies:TList.
' The training-ground twin of TTeam.GetWallLocation, at 10.5 yards instead of 10.2.
' CODEGEN NOTE -- Cos(ang + off) is load-bearing. Written Cos(off + ang) the body comes out
' 394 bytes: bcc evaluates the left operand first, and the original does fld on the Float
' ang BEFORE fild on the Int offset.
	Function UpdateWallLocations(a0:Int, a1:Int)
		'!Global g_wallDist:Int
		'!Global g_dummies:TList
		Local ang:Float = ATan2(a1 + g_wallDist, a0)
		Local n:Int = 5
		For Local d:TDummy = EachIn g_dummies
			Local off:Int = 0
			Select n
				Case 5
					off = 0
				Case 4
					off = 5
				Case 3
					off = -5
				Case 2
					off = 10
				Case 1
					off = -10
			End Select
			d.x = a0 - Cos(ang + off) * TPitch.YardsToPixels(10.5)
			d.y = a1 - Sin(ang + off) * TPitch.YardsToPixels(10.5)
			If n > 1 Then n = n - 1
		Next
	End Function
