' TTable.HighlightItem
' VA 0x0051780A   656 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, slot 0xC8
' ASSUMPTIONS
'  * Globals (names are ours; only the declared types are load-bearing):
'      0x00C7E0A0 g_table_float:Float   0x00C625F0 g_table_int03:Int
'      0x00C61CF4 g_gadget_int01:Int   (original value 4, see below)
'  * TTable fields from object_model.json (+0x68 ih, +0x70 selecteditem,
'    +0x7C showheadings) and the inherited TGadget block (+0x20 x, +0x24 y,
'    +0x2C w, +0x38 alive).
'  * FUN_004A7FE0 = Abs(Double); it is unnamed in helper_map.full_table() yet the
'    body matches byte-for-byte, so the E8 operands agree on both sides.
'  * TWO separate early returns, not one compound guard and not an If-block.
'  * `ix`, `iy` and `b` are real Int Locals: `b` is loaded into ebx once and reused
'    across all four DrawRect calls without being re-read from memory, which is what
'    distinguishes a Local from a bare Global reference (guide 10.6).
'  * `Self.y + selecteditem*(ih+g_table_int03)` -- operand order is byte-observable:
'    with the product first bcc emits `fadd [edi+0x24]` (3 bytes) instead of
'    `fld [edi+0x24]` + `faddp` (5), and the body lands 2 bytes short.
' g_table_float's original data-section value is 128.0 (0x00C7E0A0), read
' directly from NSS5.exe. It IS also stored to inside this body (the pulsing highlight
' decrement/wrap below), so check_floats.py's classifier correctly treats it as a mutable
' Global and does not flag it -- but the compile-time initial value still matters for the
' FIRST call before any wrap has happened, exactly like the pure-read cases in
' codegen-patterns 21.1/21.3.
	'!Global g_table_float:Float = 128.0
	'!Global g_table_int03:Int
	'!Global g_gadget_int01:Int = 4
	If Self.selecteditem < 1 Then Return 0
	If Self.alive = 0 Then Return 0
	SetScale(1, 1)
	g_table_float = g_table_float - 6.0
	If g_table_float < -128.0
		g_table_float = 128.0
	EndIf
	SetColor(Int(Abs(g_table_float)), 255, Int(Abs(g_table_float)))
	Local ix:Int = Int(Self.x)
	Local iy:Int = Int(Self.y + Self.selecteditem * (Self.ih + g_table_int03))
	If Self.showheadings = 0
		iy = iy - (Self.ih + g_table_int03)
	EndIf
	Local b:Int = g_gadget_int01
	DrawRect(ix - b, iy - b, Self.w - g_table_int03 + b * 2, b)
	DrawRect(ix - b, iy + Self.ih - g_table_int03, Self.w + b * 2, b)
	DrawRect(ix - b, iy - b, b, Self.ih - g_table_int03 + b * 2)
	DrawRect(ix + Self.w, iy - b, b, Self.ih - g_table_int03 + b * 2)
	SetColor(255, 255, 255)
