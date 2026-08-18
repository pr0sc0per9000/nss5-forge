' Cross2D  -- module-level Function (no Type)
' VA 0x00506165   31 bytes   sig (:TMyVector,:TMyVector)d
' byte-identical vs NSS5.exe (31/31, original length from Ghidra's inventory, mode=exact,
' reloc_masked=0 -- the body calls NOTHING, so nothing could be learned and nothing was
' masked. Verified with NSS5_NO_LEARN=1.)
'
' NAME IS OURS. One caller: the module Function at 0x00506049 (AngleDiff), which is the
' only reason this 31-byte leaf mattered -- it is the last unnamed callee under
' TPlayer.UpdateMovement (4137 bytes), TPlayer.SlideBall and TPlayer.InterceptBall.
'
' The 2-D cross product (perp-dot) of two TMyVectors, ignoring Z. Together with
' TMyVector.GetDotPV it is the (sin, cos) pair that AngleDiff feeds to ATan2 to get a
' SIGNED angle between two headings.
'
' EVIDENCE FOR THE OPERAND ORDER -- read off the disassembly, not inferred:
'   fld qword [edx+0x10] / fchs / fmul qword [eax+8]   -> (-a0.Y) * a1.X   (unary minus
'   binds to a0.Y, and it is applied BEFORE the multiply, so it is not -(a0.Y*a1.X))
'   fld qword [edx+8]    / fmul qword [eax+0x10]       ->   a0.X  * a1.Y
'   faddp                                              -> the sum, left term first
' TMyVector field offsets from object_model.json: X +0x08, Y +0x10, Z +0x18, all Double.
' No prologue `sub esp` -- zero Locals, the whole body is one expression on the x87 stack.
	Function Cross2D:Double(a0:TMyVector, a1:TMyVector)
		Return -a0.Y * a1.X + a0.X * a1.Y
	End Function
