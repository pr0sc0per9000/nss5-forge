' TProfile.DoNews
' VA 0x00569106   505 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ($,:TBase_Team,:TBase_Team,i,i)$, class-table slot 0x80
' ASSUMPTIONS
'   All twelve "$..." token literals read out of NSS5.exe with harness.read_string.
'   FormatMoney is the recovered module Function at 0x0050720b (src/recovered_module).
'   GetOriginalName is TProfile slot 0x160, GetValue is TProfile slot 0xb8 (vtable_map).
'   TBase_Team.labelshortname = +0x20, TBase_Team.stadiumname = +0x34 (object_model).
'   TProfile.injury = +0x16c, TProfile.contractwage = +0x78 (object_model).
' Body-only format: statements only; parameters are a0, a1, ...
If a1 <> Null Then
	a0 = a0.Replace("$clubname", a1.labelshortname)
	If a1.stadiumname = "" Then
		a0 = a0.Replace("$clubstadium", a1.labelshortname)
	Else
		a0 = a0.Replace("$clubstadium", a1.stadiumname)
	End If
End If
If a2 <> Null Then
	a0 = a0.Replace("$opposingclubname", a2.labelshortname)
	If a2.stadiumname = "" Then
		a0 = a0.Replace("$opposingclubstadium", a2.labelshortname)
	Else
		a0 = a0.Replace("$opposingclubstadium", a2.stadiumname)
	End If
	a0 = a0.Replace("$offerclubname", a2.labelshortname)
	If a2.stadiumname = "" Then
		a0 = a0.Replace("$offerclubstadium", a2.labelshortname)
	Else
		a0 = a0.Replace("$offerclubstadium", a2.stadiumname)
	End If
End If
a0 = a0.Replace("$playername", GetOriginalName())
a0 = a0.Replace("$years", String(a3))
a0 = a0.Replace("$num", String(a4))
a0 = a0.Replace("$injurylength", String(Self.injury))
Local v:Int = GetValue()
If v > 10000 Then v = (v / 10000) * 10000
a0 = a0.Replace("$value", FormatMoney(v, 1))
a0 = a0.Replace("$wage", FormatMoney(Self.contractwage, 1))
Return a0
