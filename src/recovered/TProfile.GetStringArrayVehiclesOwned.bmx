' TProfile.GetStringArrayVehiclesOwned
' VA 0x0056B160   126 bytes   vtable slot 0xe8   sig (i)[]$
' byte-identical vs NSS5.exe (126/126, original length from Ghidra's inventory)
' No Globals. Self.vehicles is the []Int field at +0xF4 (same field TProfile.GetVehicleCosts
' and TProfile.LoadProfile use).
' The ARRAY LITERAL form is load-bearing: `New String[3]` + three `a[i] = ...` stores emits a
' full release of each old slot (`8B 43 18 / FF 48 04 / 75 09 / ... bbGCFree`) that the
' original does not have -- it retains and stores straight into +0x18/+0x1c/+0x20. The literal
' also keeps Self in edi for the whole body (`8B 7D 08` in the prologue), which the
' statement form does not.
' TierB / VehicleName / FormatMoney are the recovered module Functions at 0x00507C04 /
' 0x005077C5 / 0x0050720B, so their E8s mask by name on both sides.
	Method GetStringArrayVehiclesOwned:String[](a0:Int)
		Return [VehicleName(a0), String(Self.vehicles[a0-1]), FormatMoney(TierB(a0) * Self.vehicles[a0-1], 0)]
	End Method
