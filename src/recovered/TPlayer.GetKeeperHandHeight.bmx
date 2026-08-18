' TPlayer.GetKeeperHandHeight
' VA 0x004fcd01   192 bytes   vtable slot 0x1cc   sig ()f
' byte-identical vs NSS5.exe (192/192, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00c5df00 declared Int[] (globals_final.tsv says Object[],
' but the walk loads a raw dword per element and compares it against an Int field).
' 0x00c5de44 declared Float (the shared draw-scale Global).
' CONSTANTS CORRECTED: the `v = 59` / `v = 60` return values were written
'   12.0 * g_pscale + z / 8.0 * g_pscale + z as placeholders (the oracle masks the .rdata
'   ADDRESS, so any Float of the right width matched equally). scripts/check_floats.py
'   found the exe holds 40.0 (v=59, code offset +128) and 50.0 (v=60, code offset +151).
'   Re-verified MATCH 192/192.
'
' NOTES -- three shape corrections the oracle forced:
'  * The selectionno guard is an early return (cmp .. ,0 / jle), not an If/Else block.
'  * The loop body is THREE separate If statements, not "If a Or b Or c". Each match
'    emits its own copy of "mov [ebp-4],ecx / jmp out" (89 4D FC / EB xx) -- an Or would
'    share one body. That is what makes the accumulator a stack Local at [ebp-4] rather
'    than a register.
'  * The tail is If/ElseIf, not Select: each test re-reads [ebp-4].
' The two scaled results are written "const * scale + z" to match fld/fmul/fadd order.
' harness mode=reloc, 7 addresses masked.
	Method GetKeeperHandHeight:Float()
		'!Global g_keeperframes:Int[]
		'!Global g_pscale:Float
		If selectionno > 0 Then Return 100.0
		Local v:Int = 0
		For Local f:Int = EachIn g_keeperframes
			If imageframenumber = f
				v = f
				Exit
			End If
			If imageframenumber = f + 64
				v = f
				Exit
			End If
			If imageframenumber = f + 128
				v = f
				Exit
			End If
		Next
		If v = 59
			Return 40.0 * g_pscale + z
		ElseIf v = 60
			Return 50.0 * g_pscale + z
		ElseIf v = 61
			Return z
		Else
			Return 0.0
		End If
	End Method
