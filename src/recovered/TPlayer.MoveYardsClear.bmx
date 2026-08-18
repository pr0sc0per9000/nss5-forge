' TPlayer.MoveYardsClear -- VA 0x004F9CF5, 391 bytes
' byte-identical vs NSS5.exe (391/391, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=13).
'
' ASSUMPTIONS:
'  * Module Global -- name is OURS, type is the assumption:
'      g_clearradius:Int   0x00C5DE74   (globals_final: Int, usage/medium; the code does
'                                        mov eax,[0xC5DE74] / fild, i.e. an integer widened
'                                        to float, and there is no refcount traffic -> Int.)
'  * call [0x00C5D998] is a class-table interior, not a Global: TPitch+0x6C =
'    YardsToPixels (f)f  (globals_classtable_slots.tsv).  Written as the cross-Type static
'    call TPitch.YardsToPixels(a0) -- that is also the only use of parameter a0.
'  * Float constants read out of the image, not guessed:
'      0x00C7A090 / 0x00C7A098 = 2.0 (double)   -> the two `^ 2.0` exponents
'      0x00C7A0A0 = 2.0 (float)                 -> the (r - d) multiplier
'      0x00C7A0A4 / 0x00C7A0A8 = 180.0 (float)  -> the angle offsets (move AWAY from a1,a2)
'  * Fields: 0x7C desx, 0x80 desy (object_model.json).
'  * Local names (r, d, ang, m) are ours.  All four get real Float stack slots; the two
'    doubles used by the `^`/Sqr chain are compiler temps, not source Locals.
'
' Read off the disassembly, not off Ghidra:
'  * the guard is `If d < r` -- fucompp/setae computes the NEGATED test (d >= r) and jne
'    jumps over the body (guide 10.1 / 3f).
'  * ATan2's two pushes are (a2 - Self.desy) first-argument, (a1 - Self.desx) second.
'  * `r` must be a Local: the value is reused three times and bcc does no CSE.
Method MoveYardsClear:Int(a0:Float, a1:Int, a2:Int)
	'!Global g_clearradius:Int
	Local r:Float = g_clearradius + TPitch.YardsToPixels(a0)
	Local d:Float = Sqr((a1 - Self.desx) ^ 2.0 + (a2 - Self.desy) ^ 2.0)
	If d < r
		Local ang:Float = ATan2(a2 - Self.desy, a1 - Self.desx)
		Local m:Float = (r - d) * 2.0
		Self.desx = Self.desx + m * Cos(ang + 180.0)
		Self.desy = Self.desy + m * Sin(ang + 180.0)
	EndIf
End Method
