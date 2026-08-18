' TTable.SetItemText
' VA 0x00516757   181 bytes   vtable slot 0xB4   sig (i,i,$)i
' byte-identical vs NSS5.exe (181/181, original length from Ghidra's inventory, mode=reloc)
' assumptions: the ObjectEnumerator 0x8C / HasNext 0x30 / NextObject 0x34 triple plus
' bbObjectDowncast against the TRow class table is a For..EachIn; TRow.fields is the
' String[] at +0x08 (array length at +0x14, elements at +0x18).
' Shape is load-bearing: the bounds test is `Length >= a1-1` GUARDING the store, with a
' single `Return 0` after it -- writing it as `If Length < a1-1 Then Return 0` produces
' two exits and comes out 192 bytes. bcc does no CSE, so `a1-1` is recomputed three times
' (test, release of the old String, store) automatically.
	Method SetItemText:Int(a0:Int, a1:Int, a2:String)
		Local n:Int = 1
		For Local r:TRow = EachIn items
			If n = a0
				If r.fields.Length >= a1 - 1
					r.fields[a1-1] = a2
				EndIf
				Return 0
			EndIf
			n = n + 1
		Next
	End Method
