' TScreen_MyContract.UpdateDesiredCombos
' VA 0x005555d7   675 bytes   vtable slot 0x48   KIND=Function (static)   sig ()i
' byte-identical vs NSS5.exe (675/675, harness mode=reloc)
'
' MODULE GLOBALS (names ours; declared types are load-bearing)
'   0x00C6F028 g_profile:TProfile      -- same identity as TScreen_MyContract.ButtonPlay
'   0x00C67DA0/DA4/DA8/DAC g_cmb1..4:TCombo
'   0x00C6080C g_continents:TList      -- slot 0x8C (ObjectEnumerator) opens the loop
'
' RESOLVED SLOTS
'   TCombo 0x8c ClearItems  0x90 AddItem($,$,$,i)  0xb0 SelectItemById(i)  0xb8 CountItems
'          0x70 SetAlph(f) (inherited from TGadget); field +0x38 = TGadget.alive
'   TScreen_MyContract classtable 0x54/0x58/0x5c/0x60 = ComboContinent / ComboNation /
'          ComboDivision / ComboClub -- this Type's own table, so bare sibling calls.
'   0x00505B91 = LogLine (src/recovered_module/LogLine.bmx)
' field offsets: TProfile +0x134 transferlisted, +0x138/13c/140/144 desired{continent,
'   nation,league,club}id ; TContinent +0x08 id, +0x0c name
' string literals read out of NSS5.exe: 0x00C8A8AC "UpdateDesiredCombos",
'   0x00C8A8E0 "CombosDone", 0x00C7F250 "BBBBBB", 0x00C5D680 "FFFFFF"
'
' THE Select HAS THREE EMPTY CASES. Cases 1, 2 and 3 emit nothing but their own `jmp end`
' (0x5556 9E / A0 / A2, two bytes each) -- they are genuinely empty Case labels, not a
' grouped `Case 1, 2, 3`, which would share one body. Dropping them loses 6 bytes.
' The trailing test is `= 0 Or = 4` (sete/movzx pair per operand), not a Select.
	Function UpdateDesiredCombos:Int()
		'!Global g_profile:TProfile
		'!Global g_cmb1:TCombo
		'!Global g_mc_cmb_nation:TCombo
		'!Global g_cmb3:TCombo
		'!Global g_mc_cmb_club:TCombo
		'!Global g_continents:TList
		LogLine("UpdateDesiredCombos")
		If g_cmb1.CountItems() = 0
			For Local c:TContinent = EachIn g_continents
				g_cmb1.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
			Next
		EndIf
		Select g_profile.transferlisted
		Case 0
			g_profile.desiredcontinentid = 0
		Case 1
		Case 2
		Case 3
		Case 4
			g_profile.desiredcontinentid = 0
		End Select
		Local co:Int = g_profile.desiredcontinentid
		Local na:Int = g_profile.desirednationid
		Local le:Int = g_profile.desiredleagueid
		Local cl:Int = g_profile.desiredclubid
		g_cmb1.SelectItemById(co)
		ComboContinent()
		If na > 0
			g_mc_cmb_nation.SelectItemById(na)
			ComboNation()
			If le > 0
				g_cmb3.SelectItemById(le)
				ComboDivision()
				If cl > 0
					g_mc_cmb_club.SelectItemById(cl)
					ComboClub()
				EndIf
			EndIf
		EndIf
		g_profile.desiredcontinentid = co
		g_profile.desirednationid = na
		g_profile.desiredleagueid = le
		g_profile.desiredclubid = cl
		If g_profile.desiredcontinentid = 0
			g_profile.desirednationid = 0
		EndIf
		If g_profile.desirednationid = 0
			g_profile.desiredleagueid = 0
		EndIf
		If g_profile.desiredleagueid = 0
			g_profile.desiredclubid = 0
		EndIf
		If g_profile.transferlisted = 0 Or g_profile.transferlisted = 4
			g_cmb1.ClearItems()
			g_cmb1.alive = 0
			g_cmb1.SetAlph(0.5)
		Else
			g_cmb1.alive = 1
			g_cmb1.SetAlph(1.0)
		EndIf
		LogLine("CombosDone")
	End Function
