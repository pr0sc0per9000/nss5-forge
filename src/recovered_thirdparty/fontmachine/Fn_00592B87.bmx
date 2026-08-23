' Fn_00592B87  --  fontmachine module Function
' VA 0x00592B87   75 bytes
' byte-identical vs NSS5.exe (75/75, mode=reloc, reloc_masked=3, verified via try_function)
'
' UNCERTAIN: the original name. Named by VA for the reason given in Fn_00592A13.bmx.
'
' WHAT IT IS: round-half-away-from-zero. `Int(x + 0.5 * Sgn(x))` -- 0x004A7FF0 is Sgn
' (ftst/fldz/fld1/fchs, no callees) and 0x005B9690 is _bbFloatToInt, which is the Int
' return type's own conversion, not a source-visible call. Takes a Double, returns Int.
'
' `0.5 * Sgn(a0)`, not `Sgn(a0) * 0.5`. The constant is spilled to a qword temp BEFORE
' the Sgn call and reloaded after it, which is bcc's left-operand-across-a-call shape
' (same tell as Fn_00592A37's `d * Cos(a0)`); with the operands the other way round the
' constant would be an `fmul qword [const]` after the call instead.
'
' Used by TPrivateBitmapFont.DrawBorderText and .DrawFaceText, on the
' PhisicalPixelRounding path, to snap both the scale factors and the destination
' coordinates to whole device pixels.

Function Fn_00592B87:Int(a0:Double)
	Return a0 + 0.5 * Sgn(a0)
End Function
