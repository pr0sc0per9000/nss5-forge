' Fn_0058FC5C  --  zipengine module Function
' VA 0x0058FC5C   322 bytes
' byte-identical vs NSS5.exe (322/322, mode=reloc, reloc_masked=17, NSS5_NO_LEARN=1,
' verified via try_function)
'
' The SEEK slot of the minizip callback set -- see Fn_0058FB20.bmx for the set and for the
' two bootstrapped helper rows this body's MATCH rests on. a0 is the integer handle
' Fn_0058FB20 handed back, carried here in a `voidpf`; HandleToObject turns it back into
' the stream.
'
' `Int(a0)` is an EXPLICIT cast and is load-bearing. With `a0:Int` and no cast, bcc pushes
' the parameter straight from its register (`push edx`); the original moves it through eax
' first (`mov eax,edx; push eax`), which is the conversion node's shape. Byte Ptr without
' the cast does not compile ("Unable to convert from 'Byte Ptr' to 'Int'"), so the cast is
' written where the original had to have written one.
'
' `Local r:Long = -1` IS DEAD and is not an error. Its two `mov dword [ebp-0x10],-1`
' stores are in the original at 0x0058FC7A, before anything else happens, and nothing ever
' reads the slot. Removing it costs 14 bytes and shifts the register allocation of the
' following call (measured: 306/322 and 320/322 for the two shorter variants). The rest of
' the body is a stub, so a leftover result variable from the real implementation is exactly
' what one would expect.
'
' Case order is 1, 2, 0 then Default, which is the order the original tests them in;
' Default is the only arm that leaves through `Return -1` rather than falling into the
' trailing Print. StreamPos/StreamSize/SeekStream are the brl.stream module Functions
' (0x005B80CE / 0x005B80E3 / 0x005B80F8), direct E8 calls, not methods on the stream.
' SeekStream takes an Int, so each `+ a1` is computed as a Long and then truncated.
'
' `If Not s` -- setcc/movzx/cmp/jne, the boolean-materialising shape, not the direct
' compare-and-branch that `s = Null` would emit.

Function Fn_0058FC5C:Long(a0:Byte Ptr, a1:Long, a2:Int)
	Local r:Long = -1
	Local s:TStream = TStream(HandleToObject(Int(a0)))
	If Not s Then RuntimeError "Unable to Locate Open File"
	Select a2
		Case 1
			SeekStream(s, StreamPos(s) + a1)
		Case 2
			SeekStream(s, StreamSize(s) + a1)
		Case 0
			SeekStream(s, a1)
		Default
			Return -1
	End Select
	Print "seek"
End Function
