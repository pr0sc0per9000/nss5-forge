' TCameraMan.Create
' VA 0x004eb484   39 bytes   vtable slot 0x34   sig (f,f)i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory)
' local name not recoverable; declared return type is Int and the object is not returned

	Function Create:Int(a0:Float, a1:Float)
		Local c:TCameraMan = New TCameraMan
		c.x = a0
		c.y = a1
	End Function
