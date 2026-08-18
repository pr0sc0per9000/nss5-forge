' TDrawOb.RenderAll
' VA        0x004CD555   slot 0x38   KIND=Function (static)   SIG=(f,f,f)i
' ORACLE    MATCH mode=reloc  744/744 bytes  reloc_masked=29
'
' MODULE GLOBALS DECLARED (name is ours; the declared TYPE is load-bearing)
'   0x00C5AF6C g_drawobs:TList -- globals_final says Object/low ("init=bbNullObject, no
'                                 call-site typing"). TList is forced twice over: slot 0x8C
'                                 opens the loop (ObjectEnumerator) and slot 0x34 closes it
'                                 (TList.Clear, vtable_map).
'
' CALL TARGETS RESOLVED
'   call [0x00C5B1BC] -> TDrawOb+0x3C = Sort()i. THIS Type's own class table, so it is the
'                        bare sibling call `Sort()` with no `TDrawOb.` prefix (guide 3d).
'   call [0x00C5BB34] -> TEngine+0x104 = DrawMyText($,f,f,i,i,f,f,$,i). A DIFFERENT Type,
'                        so it is written `TEngine.DrawMyText(...)`.
'   0x00505CEA -> module Function SetColourHex($)i (src/recovered_module)
'   brl.max2d, all from brl_functions.tsv:
'     0x005ADBEF SetBlend   0x005AE0A8 SetScale   0x005AE079 SetRotation
'     0x005ADC28 SetAlpha   0x005ADC66 SetLineWidth 0x005ADB6F SetColor
'     0x005AD486 DrawLine   0x005AD711 DrawImage  0x005AD7C8 DrawImageRect
'
' FIELD OFFSETS (object_model.json, TDrawOb)
'   +0x08 x:f +0x0C y:f +0x10 z:f +0x14 z2:f +0x18 img:TImage +0x1C frame:i +0x24 alph:f
'   +0x28 rot:i +0x2C col:$ +0x30 sclx:f +0x34 scly:f +0x38 blend:i +0x3C txt:$
'   +0x44 imgrectw:f +0x48 imgrecth:f
'   `d.txt.Length` is the BBString length word at [txt+8] -- `cmp dword [eax+8],0`.
'
' SOURCE-FORM NOTES (two iterations, both branch-sense)
'   Ghidra printed both two-way tests the other way round, and the sense is byte-observable:
'     * outer: original is `cmp [esi+0x18],<bbNull> / je <far>`, i.e. `If d.img <> Null`
'       with the IMAGE branch first. Writing `If d.img = Null` emits `jne` and is 1 byte
'       long overall.
'     * inner: original is `mov eax,[esi+0x3C] / cmp [eax+8],0 / je <line branch>`, i.e.
'       `If d.txt.Length <> 0` with the DrawMyText branch first. The `= 0` spelling emits
'       `jne` -- also 1 byte long. Fixing it took ours from 745 to exactly 744.
'   Operand order inside the float expressions is likewise byte-observable and follows the
'   original's x87 order: SetScale is `a0 * d.sclx` (parameter first, `fld [ebp+8] /
'   fmul [esi+0x30]`) but the DrawImageRect sizes are `d.imgrectw * a0` (field first).

Function RenderAll(a0:Float, a1:Float, a2:Float)
	'!Global g_drawobs:TList
	Sort()
	For Local d:TDrawOb = EachIn g_drawobs
		If d.img <> Null
			SetBlend(d.blend)
			SetScale(a0 * d.sclx, a0 * d.scly)
			SetColourHex(d.col)
			SetRotation(d.rot)
			SetAlpha(d.alph)
			If d.imgrectw <> 0.0 And d.imgrecth <> 0.0
				DrawImageRect(d.img, d.x * a0 - a1, (d.y - d.z) * a0 - a2, d.imgrectw * a0, d.imgrecth * a0, d.frame)
			Else
				DrawImage(d.img, d.x * a0 - a1, (d.y - d.z) * a0 - a2, d.frame)
			EndIf
		Else
			If d.txt.Length <> 0
				SetBlend(d.blend)
				SetRotation(0)
				TEngine.DrawMyText(d.txt, d.x * a0 - a1, (d.y - d.z) * a0 - a2, 1, 1, d.sclx, d.alph, d.col, 0)
			Else
				If d.z2 <> 0.0
					SetRotation(0)
					SetBlend(d.blend)
					SetScale(1.0, 1.0)
					SetColourHex(d.col)
					SetAlpha(d.alph)
					SetLineWidth(4.0)
					DrawLine(d.x * a0 - a1, d.y * a0 - a2, d.z * a0 - a1, d.z2 * a0 - a2, 1)
				EndIf
			EndIf
		EndIf
	Next
	g_drawobs.Clear()
	SetScale(1.0, 1.0)
	SetRotation(0)
	SetAlpha(1.0)
	SetColor(255, 255, 255)
	SetLineWidth(1.0)
End Function
