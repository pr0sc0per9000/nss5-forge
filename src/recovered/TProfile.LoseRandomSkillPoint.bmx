' TProfile.LoseRandomSkillPoint
' VA 0x0056BCFB   641 bytes   vtable slot 0x118   sig (i)$   KIND=Method
' byte-identical vs NSS5.exe (641/641, original length from Ghidra's inventory, mode=reloc)
' assumptions: no module Globals needed.
' slots resolved: TProfile slot 0xA8 = UpdateAbility(i,i) -- virtual call on Self.
' calls: 0x0059F089 _brl_random_Rand, 0x004A7410 _brl_retro_Lower (so the source spells it
'   Lower(...), not .ToLower()), 0x004C5549 GetText (recovered module fn),
'   0x004A6A30 _bbStringCompare, 0x004A7C20 _bbStringConcat.
' fields: TProfile +0xA4 pace, +0xA8 shooting, +0xAC passing, +0xB0 tackling,
'         +0xB4 heading, +0xB8 dribbling, +0xBC flair.
' Shape notes: the seven-way dispatch IS a Select, not an If/ElseIf chain -- the original
' emits all seven `cmp eax,<n> / je` back to back with every target past the last compare,
' then a jmp for the no-match path (codegen-patterns 10.2). There is no Default.
' The ability index passed to UpdateAbility is NOT the Case number: Case 4 (flair) passes 7,
' Case 5 (passing) passes 4, Case 6 (heading) passes 5, Case 7 (shooting) passes 6.
' `Local desc:String = ""` is re-initialised inside the loop; `s` is initialised once
' outside it (the two "" constants live at different addresses, 0x00C5D284 and 0x005C7D40,
' and both mask as ordinary absolute data operands).
' CASE DIRECTION CORRECTED 2026-08-22: 7 call sites -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Method LoseRandomSkillPoint:String(a0:Int)
		Local s:String = ""
		Local last:Int = 0
		For Local i:Int = 1 To a0
			Local desc:String = ""
			Local r:Int = Rand(7, 1)
			Select r
				Case 1
					If Self.pace > 10
						Self.UpdateAbility(1, -10)
						desc = GetText("Pace").ToUpper()
					EndIf
				Case 2
					If Self.dribbling > 5
						Self.UpdateAbility(2, -5)
						desc = GetText("Dribbling").ToUpper()
					EndIf
				Case 3
					If Self.tackling > 5
						Self.UpdateAbility(3, -5)
						desc = GetText("Tackling").ToUpper()
					EndIf
				Case 4
					If Self.flair > 10
						Self.UpdateAbility(7, -10)
						desc = GetText("Flair").ToUpper()
					EndIf
				Case 5
					If Self.passing > 5
						Self.UpdateAbility(4, -5)
						desc = GetText("Passing").ToUpper()
					EndIf
				Case 6
					If Self.heading > 10
						Self.UpdateAbility(5, -10)
						desc = GetText("Heading").ToUpper()
					EndIf
				Case 7
					If Self.shooting > 5
						Self.UpdateAbility(6, -5)
						desc = GetText("Shooting").ToUpper()
					EndIf
			End Select
			If r <> last
				If desc <> ""
					If i > 1 And s <> ""
						s = s + ", "
					EndIf
					s = s + desc
				EndIf
				last = r
			EndIf
		Next
		Return s
	End Method
