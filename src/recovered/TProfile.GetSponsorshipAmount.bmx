' TProfile.GetSponsorshipAmount
' VA 0x0056ae46   83 bytes   vtable slot 0xc8   sig ()i
' byte-identical vs NSS5.exe (83/83, original length from Ghidra's inventory)
' VERIFIED: the float literal at 0x00C8EBC8 was flagged as an unproven placeholder
'   (masked by mode=reloc). Direct read confirms the exe holds exactly 52.0, and the address
'   is neither in globals_final.tsv nor ever stored to -- a genuine constant. No change needed.
' operand order in the sum is load-bearing: the accumulator is converted to float first
	Method GetSponsorshipAmount:Int()
		Local t:Int = 0
		For Local i:Int = 0 To 8
			t = Int(t + sponsor_amount[i] / 52.0)
		Next
		Return t
	End Method
