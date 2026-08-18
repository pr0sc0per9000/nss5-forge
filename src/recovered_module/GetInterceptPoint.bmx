' GetInterceptPoint  -- module-level Function (no Type)
' VA 0x00505e20   333 bytes   mode=reloc   byte-identical vs NSS5.exe (333/333)
' KIND=Function, SIG (f,f,f,f,f,f,f,f):TInterceptPoint
'
' NAME IS OURS. Standard 2-D segment/segment intersection: segment AB is
' (a0,a1)-(a2,a3), segment CD is (a4,a5)-(a6,a7). Returns a fresh TInterceptPoint whose
' `intercept` is 1 only when both parameters land inside [0,1].
'
' ASSUMPTIONS
'   0x00C604D0 is TInterceptPoint's class table (extracted/class_tables.tsv), so the
'   `push 0x00C604D0 / call 0x004A8F20` opening is `New TInterceptPoint` (guide 3d).
'   TInterceptPoint fields from object_model.json: x +0x08, y +0x0C,
'   intercept_AB +0x10, intercept_CD +0x14, intercept +0x18.
'
' CODEGEN NOTES
'   * d1/d2/d3 are Float Locals that never get a memory slot -- they live on the x87
'     stack across the whole body (guide 6 / 10.5). The `fldz / fxch / fucom st(1) /
'     fxch / fstp st(0)` at 0x00505E6E is the d2 <> 0 test performed WITHOUT popping
'     d1 and d2, and the n2=0 arm opens with two `fstp st(0)` to discard them.
'   * `If d2 = 0` is a plain If, so bcc emits the NEGATED setcc (`setne`) with `jne` to
'     the Else. Same for the four clamp tests (`setbe` for `>`, `setae` for `<`).
'   * The four clamp tests are four separate one-line Ifs, not an Or chain: each emits
'     its own `mov dword [edx+0x18],0`.
	Function GetInterceptPoint:TInterceptPoint(a0:Float, a1:Float, a2:Float, a3:Float, a4:Float, a5:Float, a6:Float, a7:Float)
		Local p:TInterceptPoint = New TInterceptPoint
		Local d1:Float = (a1-a5)*(a6-a4) - (a0-a4)*(a7-a5)
		Local d2:Float = (a2-a0)*(a7-a5) - (a3-a1)*(a6-a4)
		If d2 = 0
			p.intercept = 0
		Else
			p.intercept = 1
			Local d3:Float = (a1-a5)*(a2-a0) - (a0-a4)*(a3-a1)
			p.intercept_AB = d1/d2
			p.intercept_CD = d3/d2
			p.x = a0 + p.intercept_AB * (a2 - a0)
			p.y = a1 + p.intercept_AB * (a3 - a1)
			If p.intercept_AB > 1.0 Then p.intercept = 0
			If p.intercept_AB < 0.0 Then p.intercept = 0
			If p.intercept_CD > 1.0 Then p.intercept = 0
			If p.intercept_CD < 0.0 Then p.intercept = 0
		EndIf
		Return p
	End Function
