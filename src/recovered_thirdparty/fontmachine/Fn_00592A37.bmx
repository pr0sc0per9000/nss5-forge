' Fn_00592A37  --  fontmachine module Function
' VA 0x00592A37   322 bytes
' byte-identical vs NSS5.exe (322/322, mode=reloc, reloc_masked=12, verified via try_function)
'
' UNCERTAIN: the original name. Named by VA for the reason given in Fn_00592A13.bmx.
'
' WHAT IT IS: places a1 at distance |a1-a2| from a2 on the bearing a0, which is what the
' three Draw*Text bodies use to honour the current Max2D rotation. a0 is degrees (BlitzMax
' Sin/Cos take degrees), a2 is the anchor, and the near-zero guard is the no-rotation fast
' path: it returns a plain copy of a1 rather than paying two pow()s and a Sin/Cos.
'
' CONSTANTS, read out of NSS5.exe rather than guessed:
'   0x00C97EEC -0.01 (Float)   0x00C97EF0 +0.01 (Float)
'   0x00C97EF8  0.5  (Double)  0x00C97F00 2.0   0x00C97F08 2.0
' Each literal gets its own constant slot, so the two `^ 2.0` must be written twice.
'
' BUG (original): this is not a rotation. A real rotate-about-a2 would add a0 to the
' bearing a1 already has; this one DISCARDS a1's bearing and re-places it at a0, so the
' only input angle that leaves a glyph where it started is one that happens to equal its
' own bearing. Harmless at rotation 0 because of the guard above, which is the only path
' the game ever takes. Preserved.
'
' SHAPE NOTES (each of these changes the bytes):
'  * `d * Cos(a0)`, NOT `Cos(a0) * d`. With d on the left bcc must spill it to a temp
'    across the call -- `fld [d]; fstp [tmp]` ... `fld [tmp]; fmulp` -- which is what the
'    original does; with d on the right it emits a bare `fmul qword [d]` and is 12 bytes
'    shorter.
'  * The X half is a Local and the Y half is written inline in the Return. That
'    asymmetry is visible: the X value is copied out to its own slot (`fld [tmp];
'    fstp [nx]`) before the Y half is evaluated, while the Y value is pushed straight
'    from the temp it was computed in. Two Locals, or none, both diverge.
'  * Locals take the DEEPEST frame slots, in declaration order, after every compiler
'    temp: d and nx are at [ebp-0x30] and [ebp-0x38] with five temps below them at
'    [ebp-0x08] .. [ebp-0x28]. That is how the 0x38-byte frame is accounted for.

Function Fn_00592A37:TDrawingPoint(a0:Float, a1:TDrawingPoint, a2:TDrawingPoint)
	If a0 >= -0.01 And a0 <= 0.01 Then Return Fn_00592A13(a1.X, a1.Y)
	Local d:Double = ((a1.X - a2.X) ^ 2.0 + (a1.Y - a2.Y) ^ 2.0) ^ 0.5
	Local nx:Double = a2.X + d * Cos(a0)
	Return Fn_00592A13(nx, a2.Y + d * Sin(a0))
End Function
