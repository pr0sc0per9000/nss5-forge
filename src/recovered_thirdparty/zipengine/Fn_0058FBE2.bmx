' Fn_0058FBE2  --  zipengine module Function
' VA 0x0058FBE2   67 bytes
' byte-identical vs NSS5.exe (67/67, mode=reloc, reloc_masked=2, verified via try_function)
'
' The WRITE slot of the minizip callback set, byte-for-byte the read stub with a different
' string -- 0x00C95EC8 is "write". See Fn_0058FB9F.bmx for how the fourth, Long parameter
' is pinned by the entry copy into [ebp-8].

Function Fn_0058FBE2:Long(a0:Byte Ptr, a1:Byte Ptr, a2:Byte Ptr, a3:Long)
	Print "write"
End Function
