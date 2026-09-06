' Fn_0058FDB9  --  zipengine module Function
' VA 0x0058FDB9   27 bytes
' byte-identical vs NSS5.exe (27/27, mode=reloc, reloc_masked=2, verified via try_function)
'
' The TESTERROR slot of the same minizip callback set -- see Fn_0058FD9E.bmx for what the
' set is and why the arity is uncertain. String at 0x00C95F60 is "error"; returns 0, i.e.
' "no error", unconditionally.

Function Fn_0058FDB9:Int(a0:Byte Ptr, a1:Byte Ptr)
	Print "error"
End Function
