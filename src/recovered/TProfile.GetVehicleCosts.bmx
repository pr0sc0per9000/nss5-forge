' TProfile.GetVehicleCosts
' VA 0x0056af98   114 bytes   vtable slot 0xd8   sig ()i
' byte-identical vs NSS5.exe (114/114, original length from Ghidra's inventory)
' assumptions: FUN_00507c04 is the recovered module Function TierB(i)i (src/recovered_module/TierB.bmx).
'              Float constant at 0x00c8ebd8 is 0.005.
' NOTE: the tier index is i+1, not i -- `mov eax,esi / add eax,1 / push eax` is the
'       5 bytes that separated the first attempt (109) from the original (114).
	Method GetVehicleCosts:Int()
		Local cost:Int = 0
		For Local i:Int = 0 To 9
			cost = cost + Self.vehicles[i] * TierB(i+1) * 0.005
		Next
		Return cost
	End Method
