' TCompetition.IsCupFinal
' VA 0x0050E0B4   386 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
If Self.comptype <> 1 Then Return 0
LogLine("IsCupFinal:" + Self.tla)
If Not Self.lpromotionplaces Or Self.lpromotionplaces.IsEmpty() Then Return 1
For Local pp:TPromotionPlace = EachIn Self.lpromotionplaces
	Select Self.level
		Case 0
			Select Self.locale
				Case 0
					If TCompetition.SelectById(pp.promotiontoid).locale = 0 Then Return 0
				Case 1
					Local c:TCompetition = TCompetition.SelectById(pp.promotiontoid)
					If c <> Null
						If c.id = 555 Or c.tla.ToUpper() = "SUPER CUP" Then Return 1
						If c.locale = 1 Then Return 0
					End If
			End Select
		Case 1
			Return 0
	End Select
Next
Return 1
