' Fn_0058FC25  --  zipengine module Function
' VA 0x0058FC25   55 bytes
' byte-identical vs NSS5.exe (55/55, mode=reloc, reloc_masked=2, verified via try_function)
'
' The TELL slot of the minizip callback set -- see Fn_0058FD9E.bmx. String at 0x00C95EE0
' is "tell". Returns 0 rather than the stream position, so the stub is not merely noisy,
' it is wrong -- and it never showed because the whole set is dead in this build; see
' Fn_0058FD9E.bmx.
'
' The return type is Long, not Int: the caller passes a hidden result pointer in the first
' stack slot ([ebp+8] -> ebx) and the body writes the two halves to [ebx] and [ebx+4]. The
' 8-byte frame is the single Long return slot; a Long PARAMETER would add another (compare
' Fn_0058FB9F, frame 0x10, which has one).

Function Fn_0058FC25:Long(a0:Byte Ptr, a1:Byte Ptr)
	Print "tell"
End Function
