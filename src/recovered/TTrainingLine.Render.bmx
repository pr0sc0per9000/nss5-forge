' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TTrainingLine.Render
' VA 0x005840D8   116 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (116/116, original length from Ghidra's inventory)
' The early-return form is load-bearing: `If alive Then <call>` is 7 bytes short (je) -- the original emits `cmp [edx+0x18],0 / jne` over a `mov eax,0 / jmp end`.
' x2 and y2 are Int fields passed to Float parameters; bcc emits the fild conversion.
' The empty-string literal (arg 14) is a placeholder -- its address is masked by mode=reloc.
' TDrawOb.AddDrawOb resolved to TDrawOb+0x34 on both sides. harness mode=reloc.

	Method Render:Int()
		If alive = 0 Then Return 0
		TDrawOb.AddDrawOb(Null, x, y, x2, 0, 2, alph, 0, colour, 1.0, 1.0, 3, y2, "", 0, 0)
	End Method
