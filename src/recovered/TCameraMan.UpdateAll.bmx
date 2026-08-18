' TCameraMan.UpdateAll
' VA 0x004EB63A   93 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (93/93, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' module Global assumed (name ours, type load-bearing): Global g_cameramen:TList (0x00C5DCA0)

	Function UpdateAll:Int()
		'!Global g_cameramen:TList
		For Local c:TCameraMan = EachIn g_cameramen
			c.Update()
		Next
	End Function
