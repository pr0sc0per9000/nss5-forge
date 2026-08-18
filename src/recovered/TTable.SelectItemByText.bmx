' TTable.SelectItemByText
' VA 0x00517BFC   173 bytes   vtable slot 0xE0   sig ($,i)i
' byte-identical vs NSS5.exe (173/173, original length from Ghidra's inventory, mode=reloc)
' assumptions: For..EachIn over TTable.items downcast to TRow; TRow.fields is the String[]
' at +0x08; 0x004A6A30 is _bbStringCompare (runtime_helpers.tsv, 202 witnesses).
' Operand order is load-bearing: the original is `cmp edi,[edx+0x14] / jl`, i.e. the
' parameter is the LEFT operand -- `If a1 >= r.fields.Length Then Return 0`.
' Written the other way round (`If r.fields.Length <= a1`) the length still matches at
' 173 but bytes 88.. differ (`39 7A 14 / 7F` instead of `3B 7A 14 / 7C`).
	Method SelectItemByText:Int(a0:String, a1:Int)
		selecteditem = -1
		Local n:Int = 1
		For Local r:TRow = EachIn items
			If a1 >= r.fields.Length
				Return 0
			EndIf
			If r.fields[a1] = a0
				SelectItemByRow(n)
			EndIf
			n = n + 1
		Next
	End Method
