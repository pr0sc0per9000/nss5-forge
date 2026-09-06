' zip_fileinfo.getBank -- VA 0x0058EF51, 183 bytes   vtable slot 0x30   sig ():TBank
' byte-identical vs NSS5.exe (183/183, mode=reloc, 10 absolute-address slots masked)
' Serialises the record into a 48-byte bank: the six tm_zip Ints at 0..20, then the three
' Longs at 24/32/40. 0x005B6DC2 is _brl_bank_CreateBank, 0x005B6F85 _brl_bank_PokeInt,
' 0x005B6FD7 _brl_bank_PokeLong (a Long argument is two pushes, which is why those three
' call sites clear 0x10 of stack and the Int ones clear 0xC).
	Method getBank:TBank()
		Local b:TBank = CreateBank(48)
		PokeInt(b, 0, tmz_date.tm_sec)
		PokeInt(b, 4, tmz_date.tm_min)
		PokeInt(b, 8, tmz_date.tm_hour)
		PokeInt(b, 12, tmz_date.tm_mday)
		PokeInt(b, 16, tmz_date.tm_mon)
		PokeInt(b, 20, tmz_date.tm_year)
		PokeLong(b, 24, dosDate)
		PokeLong(b, 32, internal_fa)
		PokeLong(b, 40, external_fa)
		Return b
	End Method
