' TProfile.CheckSkillHash
' VA 0x0056A0F9   535 bytes   vtable slot 0xb0   sig ()i
' byte-identical vs NSS5.exe (535/535, original length from Ghidra's inventory), verified
' with NSS5_NO_LEARN=1.
'
' Anti-cheat check: recomputes the SHA-256 digest of "dontcheatatnss5" plus the seven
' ability stats and compares it against the stored `skillshash`. On mismatch it shows an
' "invalid skill hash" message, resets all seven stats to 1, and recomputes+stores a fresh
' digest. Sibling of TProfile.UpdateAbility / SetAbility (same digest expression, same
' blocker -- see TProfile.UpdateAbility.bmx's header for how the field order in the digest
' expression was established).
'
' CODEGEN NOTES
'   * `TScreen.DoMessage(msg, 0, 0)` is a static class `Function` (`($,i,i)i`, class-table
'     slot 0x94), NOT a Method -- the original calls it with `call dword ptr [0x00c61cc0]`
'     and 0x00c61cc0 is TScreen's class table (0x00c61c2c) + 0x94, i.e. a plain cross-Type
'     static call, no Self/receiver pushed. `extracted/globals_classtable_slots.tsv`
'     confirms the address is exactly that slot.
'   * `GetText("CMESSAGE_INVALIDSKILLSHASH")` takes ONE argument, matching its already-
'     recovered signature (`src/recovered_module/GetText.bmx`, sig `($)$`). The `0, 0` seen
'     right before its call site in the disassembly are NOT GetText's arguments -- they are
'     DoMessage's trailing two Int parameters, pushed before GetText's own single-argument
'     call and consumed only after GetText returns and its result is pushed.
'   * The stat reset order (pace, dribbling, tackling, passing, heading, shooting, flair)
'     and the digest field order are the same as TProfile.UpdateAbility/SetAbility's.
	Method CheckSkillHash:Int()
		Local h:String = Sha256Hex("dontcheatatnss5" + String(pace) + String(shooting) + String(passing) + String(heading) + String(tackling) + String(dribbling) + String(flair))
		If skillshash <> h
			TScreen.DoMessage(GetText("CMESSAGE_INVALIDSKILLSHASH"), 0, 0)
			pace = 1
			dribbling = 1
			tackling = 1
			passing = 1
			heading = 1
			shooting = 1
			flair = 1
			skillshash = Sha256Hex("dontcheatatnss5" + String(pace) + String(shooting) + String(passing) + String(heading) + String(tackling) + String(dribbling) + String(flair))
		EndIf
		Return 0
	End Method
