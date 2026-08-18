' TCompetition.GetBasedNationId
' VA 0x0050dd4d   871 bytes   vtable slot 0xf4   sig (i)i   (a0 = the round/index)
' byte-identical vs NSS5.exe (871/871, harness mode=reloc)
'
' MODULE GLOBALS (names ours; declared types load-bearing)
'   0x00C596F0 g_nations:TList     -- slot 0x88 Sort and 0x8C ObjectEnumerator
'   0x00C596F4 g_nation_sortby:Int -- same Global TNation.Compare/SortListBy read
'   0x00C6EFD4 g_ticks:Int         -- bare dword, no refcount traffic (11.2)
'
' RESOLVED CALLS
'   PTR_FUN_00C59A40 = TNation classtable + 0x78 = SortListBy(i,i)i
'   0x0059F0F4 _brl_random_SeedRnd -> SeedRnd(...)
'   0x004BBFC1 ReadSettingFloat($,$,f,f)f (src/recovered_module) -- the 3rd/4th arguments
'     are pushed as 0 and 0x43510000 (= 209.0); a0 is turned into a String by the implicit
'     _bbStringFromInt before the push, i.e. the key argument is written plainly as `a0`.
'   list.Sort(0) emits `push CompareObjects / push 0` -- 0x005B3516
'     _brl_linkedlist_CompareObjects is the DEFAULT argument value, never written in source.
' field offsets: TCompetition +0x18 locale, +0x1c level, +0x20 based, +0x2c startweek;
'   TNation +0x64 continent; TBase_Team +0x0c id, +0x38 stadiumcapacity
' string literals read out of NSS5.exe (0x00C7D324/36C/3B4/3FC).
'
' Every branch here is a SELECT (10.2): each run of cmp/je targets addresses past the last
' compare, and each no-match path is a `jmp` to the statement after End Select.
' The two `c = a0 Mod 9` loops emit `mov ecx,9 / cdq / idiv ecx` INSIDE the loop body -- bcc
' does no CSE, so the modulus really is recomputed per iteration and must be written inline.
	Method GetBasedNationId:Int(a0:Int)
		'!Global g_nations:TList
		'!Global g_nation_sortby:Int
		'!Global g_ticks:Int
		Select Self.level
		Case 0
			Select Self.locale
			Case 0
				Return Self.based
			Case 1
				SeedRnd(a0 * Self.startweek)
				TNation.SortListBy(5, 1)
				Local id:Int = 1
				For Local n:TNation = EachIn g_nations
					If n.continent = Self.based And n.stadiumcapacity > 50000
						id = n.id
						Exit
					EndIf
				Next
				TNation.SortListBy(2, 1)
				SeedRnd(g_ticks)
				Return id
			End Select
		Case 1
			Local r:Int = 0
			Select Self.locale
			Case 1
				Select Self.based
				Case 2
					r = Int(ReadSettingFloat("GameMedia/Data/venuesACoN.txt", a0, 0, 209.0))
				Case 4
					r = Int(ReadSettingFloat("GameMedia/Data/venuesCopa.txt", a0, 0, 209.0))
				Case 6
					r = Int(ReadSettingFloat("GameMedia/Data/venuesEuros.txt", a0, 0, 209.0))
				End Select
				If r = 0
					g_nation_sortby = 11
					g_nations.Sort(0)
					Local c:Int = 0
					For Local n:TNation = EachIn g_nations
						If n.continent = Self.based
							If c = a0 Mod 9
								r = n.id
								Exit
							EndIf
							c = c + 1
						EndIf
					Next
				EndIf
				Return r
			Case 2
				r = Int(ReadSettingFloat("GameMedia/Data/venuesWC.txt", a0, 0, 209.0))
				If r = 0
					g_nation_sortby = 11
					g_nations.Sort(0)
					Local c:Int = 0
					For Local n:TNation = EachIn g_nations
						If c = a0 Mod 9
							r = n.id
							Exit
						EndIf
						c = c + 1
					Next
				EndIf
				Return r
			End Select
		End Select
		Return 0
	End Method
