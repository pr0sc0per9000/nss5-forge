' TMyBankStream.New
' VA 0x0050821e   34 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory)
' Empty body; the 34 bytes are bcc's implicit ctor -- the Super (TBankStream.New) call
' followed by the store of this Type's class-table pointer into +0.
	Method New:Int()
	End Method
