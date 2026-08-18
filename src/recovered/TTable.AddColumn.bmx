' TTable.AddColumn
' VA 0x005162dd   218 bytes   vtable slot 0x90   sig (i,$,$,$,i)i
' byte-identical vs NSS5.exe (218/218, original length from Ghidra's inventory, mode=reloc)
' Assumptions: FUN_004A8F20(ClassTable_TColumn) = New TColumn.  TColumn layout from
'   object_model (w/heading/txtcolour/bgcolour/alignx).  w/columns come from TGadget/TTable.
'   Global 0x00C625F0 is an INT, not a Float: the original loads it with
'   mov eax,[g] / mov [ebp-4],eax / fild, which is the Int->Float widening; a Float Global
'   would be a single "fld dword [g]" and the function comes out 7 bytes short.
	Method AddColumn:Int(a0:Int,a1:String,a2:String,a3:String,a4:Int)
		'!Global g_tbl_gap:Int
		Local c:TColumn = New TColumn
		c.w = a0
		c.heading = a1
		c.txtcolour = a2
		c.bgcolour = a3
		c.alignx = a4
		Self.columns.AddLast(c)
		Self.w = Self.w + a0
		If Self.columns.Count() > 1
			Self.w = Self.w + g_tbl_gap
		EndIf
	End Method
