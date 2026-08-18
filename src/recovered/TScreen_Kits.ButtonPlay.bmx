' TScreen_Kits.ButtonPlay
' VA 0x0054A4C0   584 bytes  mode=reloc  byte-identical vs NSS5.exe (584/584)
' KIND=Function, SIG ()i, slot 0x44
' ASSUMPTIONS
'   0x00C6F028 g_profile:TProfile  (construction-site typed; the 0x15C/0x1D8/0x1E4 fields
'     used here are TProfile.energy/selectedformatch/formationchanged).
'   0x00C674D0 g_kits_fixture:TFixture -- it is argument 1 of TEngine.SetUpMatch,
'     whose reflection signature (:TFixture,:TTeam,:TTeam,()i)i fixes the type.
'   0x00C674D4 / 0x00C674D8 :TClub, 0x00C674DC..0x00C674E8 :TKit (construction sites),
'     0x00C674F4 / 0x00C674F8 :Int, 0x00C68624 :Float (x87 dword load).
'   0x00C674C0 is NOT an Int: it is argument 4 of SetUpMatch, declared ()i, i.e. a
'     function-pointer Global.  globals_final.tsv types it Int and is wrong.
'   0x00C674EC / 0x00C674F0 hold references (retain of bbNullObject + release of the old
'     value); their exact Type is not observable here, so they are declared :Object.
'   Three back-to-back cmp/je with every target past the last compare = Select, and the
'   Cases really are in the order 2, 1, 3.
	Function ButtonPlay:Int()
		'!Global g_profile:TProfile
		'!Global g_kits_fixture:TFixture
		'!Global g_kits_club1:TClub
		'!Global g_kits_club2:TClub
		'!Global g_kits_kit1:TKit
		'!Global g_kits_kit2:TKit
		'!Global g_kits_kit3:TKit
		'!Global g_kits_kit4:TKit
		'!Global g_kits_obj1:Object
		'!Global g_kits_obj2:Object
		'!Global g_kits_int1:Int
		'!Global g_kits_int2:Int
		'!Global g_kits_energy:Float
		'!Global g_kits_fn:Int()
		TScreen.DoProgressBar(1.0, GetText("Retrieve Team"), "00FF00", 1)
		g_profile.energy = g_kits_energy
		Local sel:Int = -1
		Select g_profile.selectedformatch
			Case 2
				sel = 11
			Case 1
				sel = g_profile.newstarselno
				If g_kits_fixture.level = 1 Then sel = g_profile.internationalselno
			Case 3
				sel = 11
		End Select
		CreateKits("EngineMedia/Match/Player/Player.png")
		g_profile.formationchanged = 0
		If g_kits_club1.CheckManagerChangeFormation() And g_kits_club1.id = g_profile.clubid And g_kits_fixture.level = 0
			g_profile.formationchanged = 1
		End If
		If g_kits_club2.CheckManagerChangeFormation() And g_kits_club2.id = g_profile.clubid And g_kits_fixture.level = 0
			g_profile.formationchanged = 1
		End If
		Local t1:TTeam = TTeam.CreateTeamSimple(g_kits_club1.id, g_kits_club1.labelshortname, g_kits_club1.tla, g_kits_club1.strength, g_kits_int1, g_kits_kit1, g_kits_kit3, g_kits_club1.formation, sel, 1, g_kits_fixture)
		Local t2:TTeam = TTeam.CreateTeamSimple(g_kits_club2.id, g_kits_club2.labelshortname, g_kits_club2.tla, g_kits_club2.strength, g_kits_int2, g_kits_kit2, g_kits_kit4, g_kits_club2.formation, sel, 2, g_kits_fixture)
		TEngine.SetUpMatch(g_kits_fixture, t1, t2, g_kits_fn)
		g_kits_obj1 = Null
		g_kits_obj2 = Null
	End Function
