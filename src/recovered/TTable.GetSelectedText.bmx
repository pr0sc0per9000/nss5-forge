' TTable.GetSelectedText
' VA 0x00517B24   147 bytes   vtable slot 0xD8   sig (i)$
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory, mode=reloc)
' Assumptions:
'   Self.items (:TList at +0x60) is enumerated; 0x00C62D6C is TRow's class table, so the
'   EachIn loop variable is TRow. TRow.fields is String[] at +8, hence the
'   `[edx + eax*4 + 0x18]` element load (0x18 is BlitzMax's array data offset).
'   `.length` reads the bbString length field at +8 -- `cmp dword[eax+8],0`.
'   The two conditions must be NESTED Ifs, not `A And B`. With `And`, bcc materialises the
'   operands (sete/setne/movzx) and the function comes out 167 bytes; nested Ifs give the
'   short-circuit `jne`/`je` straight to the increment and reproduce 147 exactly.
'   `r.fields[a0]` really is evaluated twice -- bcc does no CSE and the original reloads it.

	Method GetSelectedText:String(a0:Int)
		Local n:Int = 1
		For Local r:TRow = EachIn items
			If n = selecteditem + itemoffset
				If r.fields[a0].length <> 0
					Return r.fields[a0]
				End If
			End If
			n = n + 1
		Next
		Return ""
	End Method
