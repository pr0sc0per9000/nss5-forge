' Fn_0058FB9F  --  zipengine module Function
' VA 0x0058FB9F   67 bytes
' byte-identical vs NSS5.exe (67/67, mode=reloc, reloc_masked=2, verified via try_function)
'
' The READ slot of the minizip callback set -- see Fn_0058FD9E.bmx. String at 0x00C95EB4
' is "read". Reads nothing and returns 0 bytes.
'
' The arity here IS pinned, unlike the close/error stubs: bcc materialises a Long parameter
' into the frame on entry whether or not the body reads it, so the
' `mov eax,[ebp+0x18] / mov [ebp-8],eax / mov eax,[ebp+0x1c] / mov [ebp-4],eax` pair before
' the Print proves a Long parameter at stack offset 0x18 -- the fourth argument, after
' three 4-byte ones. That is exactly minizip's
' `read_file_func(opaque, stream, buf, size)`.

Function Fn_0058FB9F:Long(a0:Byte Ptr, a1:Byte Ptr, a2:Byte Ptr, a3:Long)
	Print "read"
End Function
