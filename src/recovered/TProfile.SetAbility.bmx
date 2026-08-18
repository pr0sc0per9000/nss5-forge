' TProfile.SetAbility
' VA 0x00569F28   465 bytes   vtable slot 0xac   sig (i,i)i
' byte-identical vs NSS5.exe (465/465, original length from Ghidra's inventory), verified
' with NSS5_NO_LEARN=1.
'
' Identical shape to TProfile.UpdateAbility except the 7-way dispatch ASSIGNS a1 to the
' selected stat instead of adding it. Same blocker/unblock story -- see
' TProfile.UpdateAbility.bmx's header for the codegen notes (Select vs If/ElseIf, the
' ClampInt call order, and how the digest field order was established); both apply here
' unchanged.
	Method SetAbility:Int(a0:Int, a1:Int)
		Select a0
			Case 1
				pace = a1
			Case 2
				dribbling = a1
			Case 3
				tackling = a1
			Case 4
				passing = a1
			Case 5
				heading = a1
			Case 6
				shooting = a1
			Case 7
				flair = a1
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
