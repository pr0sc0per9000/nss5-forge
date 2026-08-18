' TProfile.GetPropertyCosts
' VA 0x0056aec2   114 bytes   vtable slot 0xd0   sig ()i
' byte-identical vs NSS5.exe (114/114, original length from Ghidra's inventory)
' No Globals. Self.property is the []Int field at +0xF8. TierA is the recovered module
' Function at 0x00507B79. The float constant at 0x00C8EBCC is 0.005.
' Loop is `To 9` (jle), not `Until 10` (jl), and the array element is inlined -- a Local
' for it reorders the x87 conversion and costs 6 bytes.
	Method GetPropertyCosts:Int()
		Local t:Int = 0
		For Local i:Int = 0 To 9
			t = Int(t + Self.property[i] * TierA(i + 1) * 0.005)
		Next
		Return t
	End Method
