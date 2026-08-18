' TProfile.UpdateFinances
' VA 0x0056b7e3   401 bytes   vtable slot 0x108   sig ()i
' byte-identical vs NSS5.exe (401/401, harness mode=reloc -- the only masked operand is the
'   address of the Float constant 50.0 at 0x00c8ecbc, read out of NSS5.exe)
' `sub esp,0x18` = 6 dword slots: wage/-0xc, sponsor/-0x10, bonus/-0x14, prop/-8 plus two
'   x87 conversion temps at -4 and -0x18; shirt/rent/veh/total stay in ebx/edi/eax/edx.
' THE ARGUMENT OF UpdateBank IS A LOCAL, not an inline expression (codegen-patterns 16.2):
'   inline, bcc materialises the receiver first (`mov edx,esi` before the sum) and diverges
'   at +286; with `Local total` the sum is computed first and `mov eax,esi` follows it.
' `Self.lastweeksshirtsales :+ Rand(...)` -- `add [esi+0xa0],eax` on a memory operand (6).
' resolved indirect calls (all Self, so plain TProfile slots):
'   0xc8 GetSponsorshipAmount  0xcc GetRentCosts  0xd0 GetPropertyCosts
'   0xd4 GetLastWeeksShirtSales  0xd8 GetVehicleCosts  0xf8 GetFame  0xfc UpdateBank
'   0x150 CheckAchievement(i)
	Method UpdateFinances:Int()
		Local wage:Int = Self.contractwage
		If Self.date.sdate > Self.contractexpires
			wage = wage / 2
		EndIf
		Local sponsor:Int = Self.GetSponsorshipAmount()
		Local bonus:Int = Self.thisweeksassistbonus + Self.thisweeksgoalbonus + Self.thisweekscleanbonus
		Self.lastweeksshirtsales = Int(Self.relationfans * Self.GetFame() / 50.0)
		Self.lastweeksshirtsales :+ Rand(Self.relationfans / 4, 1)
		If Self.relationfans < 20
			Self.lastweeksshirtsales = 0
		EndIf
		If Self.lastweeksshirtsales > 100
			Self.CheckAchievement(84)
		EndIf
		Local shirt:Int = Self.GetLastWeeksShirtSales()
		Local rent:Int = Self.GetRentCosts()
		Local prop:Int = Self.GetPropertyCosts()
		Local veh:Int = Self.GetVehicleCosts()
		Local total:Int = wage + sponsor + bonus + shirt - (rent + prop + veh)
		Self.UpdateBank(total)
		Self.lastweeksassistbonus = Self.thisweeksassistbonus
		Self.lastweeksgoalbonus = Self.thisweeksgoalbonus
		Self.lastweekscleanbonus = Self.thisweekscleanbonus
		Self.thisweeksassistbonus = 0
		Self.thisweeksgoalbonus = 0
		Self.thisweekscleanbonus = 0
	End Method
