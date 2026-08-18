' TScreen_Pairs.NewButtonPositions
' VA 0x005790EE   360 bytes
' byte-identical vs NSS5.exe (mode=reloc)
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable
'
' assumes module global:  Global g_screen_pairs_arr:TButton[]   -- 0x00C6C81C
'   (same declaration already used by TScreen_Pairs.EnableAll / .DisableAll)
'
' NOTE ON THE TWO COUNTERS. `n` and `m` are genuinely DISTINCT Locals in the original, not
' one counter reset to 0. With a single counter the body is 366 bytes: the counter is live
' across the whole function, its spill cost is divided down by block_count, and it loses its
' register to the outer loop variable. Two non-interfering Locals share one colour (edi) and
' push `i` onto the stack at [ebp-4], which is what NSS5.exe does.

	Function NewButtonPositions()
		'!Global g_screen_pairs_arr:TButton[]
		LogLine("NewButtonPositions")
		Local w:Int = 94
		Local h:Int = 94
		Local n:Int = 0
		Local lst:TList = CreateList()
		For Local i:Int = 1 To 4
			For Local j:Int = 1 To 4
				Local xx:Int = i*w+90+i*10
				Local yy:Int = j*h+12+j*10
				lst.AddLast(TButtonPos.Create(xx, yy))
				g_screen_pairs_arr[n].alive = 1
				n = n + 1
			Next
		Next
		lst.Sort()
		Local m:Int = 0
		For Local bp:TButtonPos = EachIn lst
			g_screen_pairs_arr[m].SetPosition(Int(bp.x), Int(bp.y), 0)
			m = m + 1
		Next
	End Function
