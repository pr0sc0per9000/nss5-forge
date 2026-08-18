' TScreen_Casino.UpdateStakeCurrency
' VA 0x0057411d   303 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x34
' ASSUMPTIONS
'   0x00C6B860..0x00C6B878 are seven TButton Globals (globals_final: TButton, construction).
'     Slot 0x64 = TGadget.SetText($,$,i,i) inherited by TButton -- consistent with that type.
'   Global names are ours; the originals are unrecoverable.
'   The sixth button really is FormatMoney(250,0), not 2500 -- 0x005741FF pushes 0xFA,
'     the same immediate as the third button. Original-source quirk, reproduced faithfully.
'   Literal "UpdateStakeCurrency" read from 0x00C904BC with harness.read_string.
	Function UpdateStakeCurrency:Int()
		'!Global g_casino_stake50:TButton
		'!Global g_casino_stake100:TButton
		'!Global g_casino_stake250:TButton
		'!Global g_casino_stake500:TButton
		'!Global g_casino_stake1000:TButton
		'!Global g_casino_stake2500:TButton
		'!Global g_casino_stake5000:TButton
		LogLine("UpdateStakeCurrency")
		g_casino_stake50.SetText(FormatMoney(50, 0), "", -1, -1)
		g_casino_stake100.SetText(FormatMoney(100, 0), "", -1, -1)
		g_casino_stake250.SetText(FormatMoney(250, 0), "", -1, -1)
		g_casino_stake500.SetText(FormatMoney(500, 0), "", -1, -1)
		g_casino_stake1000.SetText(FormatMoney(1000, 0), "", -1, -1)
		g_casino_stake2500.SetText(FormatMoney(250, 0), "", -1, -1)
		g_casino_stake5000.SetText(FormatMoney(5000, 0), "", -1, -1)
	End Function
