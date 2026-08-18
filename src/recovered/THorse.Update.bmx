' THorse.Update
' VA 0x0058ABCC   518 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG=()i, class-table slot 0x54
' ORACLE 518/518 reloc_masked=13, re-run under NSS5_NO_LEARN=1 (learned_helpers
'   empty, so no call operand was masked by a name this body taught the table).
'   The oracle reports mode=reloc, not mode=diff/exact: the four .rdata float
'   constants below relocate, exactly as guide 3d predicts.
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   No module Globals are referenced.
'   Fields (object_model.json, THorse): +0x10 framecounter:Int, +0x14 frame:Int,
'     +0x18 x:Float, +0x1C y:Float, +0x20 oldx:Float, +0x24 oldy:Float,
'     +0x28 xvel:Float, +0x3C energy:Float, +0x44 strength:Float
'   Calls: 0x0059F089 = _brl_random_Rand; 0x00505F90 = ClampFloat (module Function,
'     src/recovered_module/ClampFloat.bmx, sig (*f,f,f)i -- hence Varptr).
'   Float constants read out of .rdata: 0x00C94338 = 0.1, 0x00C9433C = 500.0,
'     0x00C94340 = 500.0, 0x00C94344 = 200.0. The Clamp bounds are push immediates.
'
' CODEGEN NOTES (each cost an iteration)
'   * bcc emits the NEGATED predicate for a float `If`: `If energy < 1.0` becomes
'     fucompp / setae / cmp eax,0 / jne <skip>. Read the setcc as the inverse of the
'     source condition, and take the LEFT operand from whichever value ends in st(0).
'   * Both Rand dispatches are `Select`, not If/ElseIf -- the compares sit back to back
'     with every target past the last one, and neither has a Default (the trailing jmp).
'     The 6-way clamp dispatch DOES have a Default: its fallback body follows the last
'     compare immediately with no jmp.
'   * `Local edge:Int` inside the loop is load-bearing. Inlined as `If x > 11479 - i*120*16`
'     bcc evaluates x first; the original computes the integer expression into esi first
'     and only then loads x, which is what a register-allocated Int Local does. The
'     `mov [ebp-4],esi / fild` pair is that Local's Int->Float widening.
'   * `i * 120 * 16` is the literal source form: bcc emits `imul eax,eax,0x78` then
'     `shl eax,4`. Written as `i * 1920` it emits a single `imul eax,eax,0x780`.
oldx = x
oldy = y
framecounter :+ 1
If framecounter > 2
	framecounter = 0
	frame :+ 1
	If frame > 7
		frame = 0
	EndIf
EndIf
If Rand(100) < strength
	energy = energy - 0.1
EndIf
If energy < 1.0
	energy = 1.0
EndIf
If energy > 1.0
	Select Rand(50)
		Case 1
			xvel = xvel + strength / 500.0
		Case 2
			xvel = xvel - strength / 500.0
	End Select
Else
	Select Rand(100)
		Case 1
			xvel = xvel - strength / 200.0
	End Select
EndIf
Local seg:Int = 7
For Local i:Int = 0 To 6
	Local edge:Int = 11479 - i * 120 * 16
	If x > edge
		seg = i
		Exit
	EndIf
Next
Select seg
	Case 0
		ClampFloat(Varptr xvel, 9.0, 15.0)
	Case 1
		ClampFloat(Varptr xvel, 9.0, 14.5)
	Case 2
		ClampFloat(Varptr xvel, 9.5, 14.0)
	Case 3
		ClampFloat(Varptr xvel, 10.0, 13.5)
	Case 4
		ClampFloat(Varptr xvel, 10.5, 13.0)
	Default
		ClampFloat(Varptr xvel, 11.0, 12.5)
End Select
x = x + xvel
