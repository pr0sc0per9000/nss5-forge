' TBossMessage.New
' VA 0x0057081C   128 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (128/128, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c6b284 declared g_bossmsgs:TList (slot 0x44 = TList.AddLast).
' The only non-default field initialiser is flipit:Int = -1; every other field takes
' bcc's default (0 / "" / Null), which it still emits explicitly.
	Method New()
		'!Global g_bossmsgs:TList
		'!Field flipit = -1
		g_bossmsgs.AddLast(Self)
	End Method
