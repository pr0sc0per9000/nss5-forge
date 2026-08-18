' TPlayer.DoRepulsion
' VA 0x004F9B88   329 bytes   mode=reloc   MATCH 329/329
' KIND=Method, SIG (f,f,*f,*f,d)i, class-table slot 0x134.
' Body-only format: statements only, parameters are a0, a1, ...
'   a0,a1 = Float x,y of the repelling point; a2,a3 = Float Ptr accumulators the impulse is
'   added into; a4 = Double strength.
'
' ASSUMPTIONS
'  * Global 0x00C5D628 -> g_pitch_float01:Float (globals_final.tsv, usage-typed, high
'    confidence, "x87 dword access"); it is the distance normaliser. Name is ours.
'    original data-section value is 10.0, read directly from NSS5.exe -- same
'    address as TPitch.SetUp.bmx's g_pitchscale. See codegen-patterns 21.1/21.3.
'  * Global 0x00C5DE74 -> g_player_int34:Int (globals_final.tsv, usage-typed). Read once and
'    converted with fild, i.e. genuinely Int.
'  * 0x00505DA2 = Dist2D, 0x0050639D = AngleTo, both from src/recovered_module/.
'  * 0x004A1F10 = _bbCos and 0x004A1F00 = _bbSin, from runtime_helpers.tsv (27 witnesses
'    each).
'  * Slot 0x138 on TPlayer = TPlayer.pow(i,i)i (vtable_map.tsv); called virtually as
'    Self.pow(...), which is what the decompilation shows.
'  * e1/e2 MUST be Locals, not literal 1 and 2: the original materialises them into stack
'    slots [ebp-0x40] and [ebp-0x48] and pushes from memory, which a literal argument would
'    not do.
'  * f0 is a Double Local initialised to 0.0 (fldz) and then negated; the whole first term
'    is therefore always zero at run time, but the code is emitted, so the source had it.
'  * Operand order in the last two statements is load-bearing: Cos/Sin must be the LEFT
'    factor. Writing (-f2) * Cos(ang) spills the negated value to a temp before the call and
'    the function comes out 349 bytes with a 0x5C frame instead of 329 with a 0x4C frame.
'!Global g_pitch_float01:Float = 10.0
'!Global g_player_int34:Int
Local dist:Float = Dist2D(Self.x, Self.y, a0, a1) / g_pitch_float01
Local ang:Float = AngleTo(Self.x, Self.y, a0, a1)
Local f0:Double = 0.0
Local e1:Int = 1
Local e2:Int = 2
Local n:Int = Int(dist / g_player_int34)
If n < 1 Then n = 1
Local f2:Double = -f0 / Self.pow(n, e1) + a4 / Self.pow(n, e2)
a2[0] = a2[0] + Cos(ang) * (-f2)
a3[0] = a3[0] + Sin(ang) * (-f2)
