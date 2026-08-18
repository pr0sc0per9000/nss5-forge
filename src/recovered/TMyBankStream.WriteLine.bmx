' TMyBankStream.WriteLine
' VA 0x00508298   91 bytes   vtable slot 0x90   sig ($)i
' byte-identical vs NSS5.exe (91/91, original length from Ghidra's inventory)
' assumptions: none beyond the Type's own field layout; WriteInt/WriteBytes are the
' inherited TStream methods, 0x004A6DE0 learned as _bbStringToWString by the oracle.
	Method WriteLine:Int(a0:String)
		WriteInt(a0.length)
		If a0.length = 0 Then Return 0
		Local buf:Short Ptr = a0.ToWString()
		WriteBytes(buf, a0.length * 2)
		MemFree(buf)
	End Method
