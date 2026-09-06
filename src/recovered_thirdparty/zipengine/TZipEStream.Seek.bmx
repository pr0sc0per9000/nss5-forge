' TZipEStream.Seek -- VA 0x0058F9FA, 147 bytes   vtable slot 0x3C   sig (i)i
' byte-identical vs NSS5.exe (147/147, mode=reloc, 4 absolute-address slots masked)
' A forward-only stream: seeking backwards is done by reopening the entry (find_file,
' slot 0xA8) and then reading forward one byte at a time into a 1-byte scratch buffer.
' 0x004A8D60 is _bbMemAlloc and 0x004A8DA0 _bbMemFree -- see the BRL_ALIAS_ADDITIONS block
' in scripts/helper_map.py for how the allocator is identified, since the generated helper
' table names only the free.
' The current position is read into a local ONCE and refreshed inside the If: the
' jle at 0x0058FA11 skips straight to `sub ebx,eax` carrying the first Pos() result, which
' a body calling Pos() twice unconditionally cannot produce.
' Parameter names are not recoverable from the binary and do not affect codegen.
	Method Seek:Int(a0:Int)
		Local cur:Int = Pos()
		If cur > a0
			If Not find_file(0) Then RuntimeError("Unable to find file")
			cur = Pos()
		EndIf
		Local n:Int = a0 - cur
		Local buf:Byte Ptr = MemAlloc(1)
		For Local i:Int = 0 Until n
			Read(buf, 1)
		Next
		MemFree buf
		Return Pos()
	End Method
