' SkillColour  -- module-level Function (name ours; module Functions have no debug record)
' VA 0x00507dcf   14 bytes   sig (i)$   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (i)$
'
' ASSUMPTIONS
'   Name is ours.  Sole caller found so far is TScreen_Abilities.CreateScreen, which passes
'   a skill index (1..7) in the "bar colour" argument slot of TProgressBar.CreateProgressBar,
'   so the parameter is the skill/ability index.
'   The parameter is UNREFERENCED in the body -- the function returns the constant "FFFFFF"
'   regardless.  That is not an inference: the whole body is
'     push ebp / mov ebp,esp / mov eax,0xc5d680 / jmp +0 / mov esp,ebp / pop ebp / ret
'   and 0x00C5D680 reads back as the BBString "FFFFFF" (harness.read_string).
'   The arity is fixed by the CALLERS, which push exactly one dword and then `add esp,4`.
'   Immediate sibling of ColourGreen (0x00507DC1, 14 bytes, ()$ -> "00FF00").
	Function SkillColour:String(skill:Int)
		Return "FFFFFF"
	End Function
