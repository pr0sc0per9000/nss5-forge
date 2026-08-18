' TKit.CheckBlack
' VA 0x004dbf9f   67 bytes   vtable slot 0x50   sig (*$)i
' byte-identical vs NSS5.exe (67/67, original length from Ghidra's inventory, mode=reloc)
' No Globals. Both string literals read out of NSS5.exe as BlitzMax string objects
' (0x00C6FC58 = "000000", 0x00C752AC = "444444"). Parameter is String Var (sig *$).
'
' Verified from scratch -> MATCH 67/67, reloc_masked=4. harness.py's sig parser must
' lower `*$` to `String Var`, not the illegal `String Ptr`; a "Compile Error: Pointer
' type mismatch" here is a sig-parser fault, not a body defect.
	Function CheckBlack:Int(a0:String Var)
		If a0 = "000000" Then a0 = "444444"
	End Function
