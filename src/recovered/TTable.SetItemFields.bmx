' TTable.SetItemFields
' VA 0x0051680c   147 bytes   vtable slot 0xb8   sig (i,[]$)i
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory)
' harness mode=reloc.
' NOTE for the pattern guide: `For Local r:TRow = EachIn items` ALREADY emits the
'   `cmp <downcast>, Null / je <continue>` after bbObjectDowncast. Adding an explicit
'   `If r <> Null` on top duplicates that compare and costs exactly 8 bytes (155 vs 147).
'   Ghidra renders the built-in check as a do/while around the enumerator step.
' The BBRETAIN of a1 and BBRELEASE of the old r.fields are compiler-emitted.
	Method SetItemFields:Int(a0:Int, a1:String[])
		Local n:Int = 1
		For Local r:TRow = EachIn items
			If n = a0
				r.fields = a1
				Return 0
			EndIf
			n = n + 1
		Next
	End Method
