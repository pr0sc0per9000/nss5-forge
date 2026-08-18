' TGadget.SetPosition
' VA 0x00514D70   482 bytes   vtable slot 0x84   sig (i,i,i)i   KIND=Method
' byte-identical vs NSS5.exe (482/482, mode=reloc, reloc_masked=12)
'
' No module Globals.
'
' CODEGEN NOTE -- x87 operand order is byte-observable here and Ghidra normalises it away.
' `Int(dx + g.x)` emits  fild [dx] / fadd dword [esi+0x20]   (12 bytes)
' `Int(g.x + dx)` emits  fld dword [esi+0x20] / fild [dx] / faddp st(1)  (14 bytes)
' The original uses the second form. Four such sums (x and y, in both branches) makes
' exactly the 8-byte shortfall the wrong order produced (474 vs 482).

	Method SetPosition:Int(a0:Int, a1:Int, a2:Int)
		Local dx:Int = Int(a0 - Self.x)
		Local dy:Int = Int(a1 - Self.y)
		If a2 = 1
			For Local g:TGadget = EachIn Self.children
				g.SetPosition(Int(g.x + dx),Int(g.y + dy),1)
			Next
			Self.x = a0
			Self.y = a1
			Self.desx = Self.x
			Self.desy = Self.y
		Else
			For Local g:TGadget = EachIn Self.children
				g.SetPosition(Int(g.x + dx),Int(g.y + dy),0)
			Next
			Self.desx = a0
			Self.desy = a1
		EndIf
	End Method
