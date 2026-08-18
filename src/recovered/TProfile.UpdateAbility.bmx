' TProfile.UpdateAbility
' VA 0x00569D57   465 bytes   vtable slot 0xa8   sig (i,i)i
' byte-identical vs NSS5.exe (465/465, original length from Ghidra's inventory), verified
' with NSS5_NO_LEARN=1.
'
' Adjusts one of the seven ability stats by a delta, clamps all seven back into [0,100],
' then recomputes and stores the anti-cheat digest `skillshash`. Sibling of
' TProfile.SetAbility (assigns instead of adding) and gated by TProfile.CheckSkillHash
' (verifies the digest on load). All three were blocked on the SHA-256 implementation at
' 0x0058C960 (`src/recovered_module/Sha256Hex.bmx`) until this session.
'
' CODEGEN NOTES
'   * The 7-way dispatch on a0 is a `Select`, NOT an `If/ElseIf` chain -- the original's
'     cascading `cmp/je` tests (all seven comparisons in a row, THEN the matching body) is
'     Select's shape; an If/ElseIf chain interleaves each test with its body and comes out
'     4 bytes shorter with `a0` in a different register.
'   * The seven ClampInt calls are in a fixed, non-offset order: pace, dribbling, tackling,
'     passing, heading, shooting, flair -- not field-declaration order.
'   * The digest string is `"dontcheatatnss5" + String(pace) + String(shooting) +
'     String(passing) + String(heading) + String(tackling) + String(dribbling) +
'     String(flair)` -- established from the ORDER the seven String() conversions actually
'     execute (flair first, pace last), which is bcc's reverse-evaluation of a flat `+`
'     chain (rightmost operand evaluated first, same rule documented in Sha256Hex.bmx's
'     header): the source's left-to-right order is the reverse of the execution order.
	Method UpdateAbility:Int(a0:Int, a1:Int)
		Select a0
			Case 1
				pace = pace + a1
			Case 2
				dribbling = dribbling + a1
			Case 3
				tackling = tackling + a1
			Case 4
				passing = passing + a1
			Case 5
				heading = heading + a1
			Case 6
				shooting = shooting + a1
			Case 7
				flair = flair + a1
		End Select
		ClampInt(Varptr pace, 0, 100)
		ClampInt(Varptr dribbling, 0, 100)
		ClampInt(Varptr tackling, 0, 100)
		ClampInt(Varptr passing, 0, 100)
		ClampInt(Varptr heading, 0, 100)
		ClampInt(Varptr shooting, 0, 100)
		ClampInt(Varptr flair, 0, 100)
		skillshash = Sha256Hex("dontcheatatnss5" + String(pace) + String(shooting) + String(passing) + String(heading) + String(tackling) + String(dribbling) + String(flair))
		Return 0
	End Method
