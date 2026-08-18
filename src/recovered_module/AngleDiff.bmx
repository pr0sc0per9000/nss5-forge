' AngleDiff  -- module-level Function (no Type)
' VA 0x00506049   284 bytes   sig (f,f,i)f
' byte-identical vs NSS5.exe (284/284, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=17), verified with NSS5_NO_LEARN=1.
'
' NAME IS OURS. 7 call sites. This is the function four earlier passes reported as the sole
' blocker on TPlayer.UpdateMovement (0x004F0468, 4137 bytes), TPlayer.SlideBall
' (0x004F86D6, 456) and TPlayer.InterceptBall (0x004F9201, 696) -- guide 13.3 rightly
' forbade stubbing it, so recovering it was the only way through.
'
' WHAT IT COMPUTES. The angle between two headings a0 and a1, in degrees. Each heading is
' turned into a TMyVector of length 10 on the unit circle, then ATan2(cross, dot) gives the
' angle between them -- SIGNED (which way to turn) when a2 = 0, and ABSOLUTE (how far
' apart) when a2 <> 0. That is exactly how UpdateMovement uses it: a2 = 0 to steer
' kickdirection toward the joystick, a2 = 1 to test the turn against a turn-rate limit.
'
' NO CIRCULARITY IN THE VERIFICATION. Its callees are named independently of this body:
' _bbFloatToInt / _bbObjectNew / _bbCos / _bbSin from helper_map.full_table(); slot 0x48 on
' class table 0x00C5D118 resolves by reflection to TMyVector.GetDotPV (:TMyVector)d; and
' Cross2D (0x00506165) was matched first, on its own, at 31/31 with reloc_masked=0.
'
' EVIDENCE, read off the disassembly rather than assumed:
'   * The four Double constants at 0x00C7BB78/80/88/90 are each 10.0 -- bcc does not pool
'     duplicate constants, so one literal per use site, which is why there are four.
'   * `fld [const] / fmulp` AFTER each Cos/Sin call means the CALL is the left operand:
'     Cos(a0) * 10.0, not 10.0 * Cos(a0) (guide 16.2).
'   * ATan2's arguments: both are pushed as qwords, right to left, so [esp] is arg 1.
'     Cross2D's result is pushed LAST -> ATan2(cross, dot), not the other way round.
'   * `mov edi,[ebp+0x10]` at entry homes a2 in a register; the discarded
'     `fld [ebp+8] / call _bbFloatToInt` before the first New is a DEAD Int Local
'     initialised from a0 -- bcc emits the conversion and then allocates it no home.
'     Dropping it costs 16 bytes, so it is in the source.
'   * a2 is tested with a bare `If a2`, not `If a2 <> 0`; the two arms duplicate the whole
'     GetDotPV/ATan2 sequence rather than sharing it (bcc does no CSE, guide 6).
'   * `Local c:Float` gets the frame's only slot (`sub esp,4`, [ebp-4]) because it must
'     survive the GetDotPV call.
	Function AngleDiff:Float(a0:Float, a1:Float, a2:Int)
		Local n:Int = a0
		Local v1:TMyVector = New TMyVector
		v1.X = Cos(a0) * 10.0
		v1.Y = Sin(a0) * 10.0
		Local v2:TMyVector = New TMyVector
		v2.X = Cos(a1) * 10.0
		v2.Y = Sin(a1) * 10.0
		Local c:Float = Cross2D(v1, v2)
		If a2
			Return Abs(ATan2(c, v1.GetDotPV(v2)))
		Else
			Return ATan2(c, v1.GetDotPV(v2))
		EndIf
	End Function
