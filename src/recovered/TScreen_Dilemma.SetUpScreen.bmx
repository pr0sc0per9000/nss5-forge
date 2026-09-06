' TScreen_Dilemma.SetUpScreen
' VA 0x00556E11   3561 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static method on TScreen_Dilemma), SIG ()i, class-table slot 0x34
' Oracle: MATCH 3561/3561, reloc_masked=296, orig_len_from=ghidra
'
' ASSUMPTIONS
'   Globals declared here (names are ours; the originals are unrecoverable):
'     0x00C6804C -> g_dil_prg1:TProgressBar   (globals_final: construction site)
'     0x00C68050 -> g_dil_prg2:TProgressBar   (globals_final: construction site)
'     0x00C68054 -> g_dil_btn1:TButton        (globals_final: construction site)
'     0x00C68058 -> g_dil_btn2:TButton        (globals_final: construction site)
'     0x00C6805C -> g_dil_choice1:Int         (bare dword, no refcount traffic -> Int;
'                                              globals_final says TScreen, which is wrong)
'     0x00C68060 -> g_dil_choice2:Int         (bare dword, no refcount traffic -> Int)
'     0x00C68064 -> g_dil_img1:TImage         (retain/release traffic -> reference;
'                                              assigned only from the ten LoadImageChecked
'                                              results below, so TImage)
'     0x00C68068 -> g_dil_img2:TImage         (same)
'     0x00C6806C -> g_img_boss:TImage         '     0x00C68070 -> g_dilemma_img_training:TImage |
'       0x00C68070 is this screen's own full-size training artwork, loaded by
'       TScreen_Dilemma.CreateScreen as g_dilemma_img_training. The g_img_training
'       spelling is TScreen_Abilities.CreateScreen's name for 0x00C66A6C, the 28-pixel
'       training icon on the abilities rows, so the two slots shared one variable and
'       the dilemma drew that icon stretched across 400x440.
'     0x00C68074 -> g_img_fans:TImage          |  loaded by TScreen_Dilemma.CreateScreen
'     0x00C68078 -> g_img_bowling:TImage       |  (0x00556929) with LoadImageChecked from
'     0x00C6807C -> g_img_golf:TImage          |  GameMedia\Images\Relationships\*.png,
'     0x00C68080 -> g_img_cinema:TImage        |  in this exact order: boss, training_ground,
'     0x00C68084 -> g_img_pub:TImage           |  fans, bowling, golf_course, cinema, pub,
'     0x00C68088 -> g_img_restaurant:TImage    |  restaurant, shopping, sponsors
'     0x00C6808C -> g_img_shopping:TImage      |
'     0x00C68090 -> g_img_sponsors:TImage     /
'     0x00C6F028 -> g_profile:TProfile         (globals_final: TProfile, construction;
'                                              g_player is an older name for the same slot)
'     0x00C5B1C8 -> g_font16:TBitmapFont      (globals_final: TBitmapFont, construction)
'     0x00C6EFE4 -> g_gfx_width:Int           (bare dword; halved to centre the message)
'     0x00C6EFE8 -> g_gfx_height:Int          (bare dword; halved to centre the message)
'   Slots resolved (walked through class_tables.tsv / vtable_map.tsv):
'     [0xC61C88] = TScreen+0x5C          -> TScreen.SetActive($,$):TScreen   (static, no Self)
'     [0xC61CE0] = TScreen+0xB4          -> TScreen.Tutorial()i              (static, no Self)
'     [0xC6B264] = TScreenMessage+0x30   -> TScreenMessage.Create(i,i,$,i,:TBitmapFont,
'                                             :TImage,f,$)i                  (static, no Self)
'     TProgressBar+0x8C                  -> TProgressBar.SetPercent(f,i)i
'     TProgressBar+0x6C                  -> TProgressBar.SetColour($,$)i
'     TButton+0x64                       -> TGadget.SetText($,$,i,i)i        (inherited)
'     TProfile+0x120                     -> TProfile.GotSponsor()i
'   Field offsets (extracted/object_model.json, TProfile):
'     +0x104 relationboss  +0x108 relationteam  +0x10C relationfans
'     +0x110 relationfriends  +0x114 relationgirlfriend  +0x118 relationsponsors
'     +0x1C8 helppages:Int[]  -- [eax+0x48] is BBArray data(+0x18) + 12*4, i.e. index 12
'   Module Function called: GetText (0x004C5549, src/recovered_module/GetText.bmx)
'   Direct BRL calls: Rand (0x0059F089), _bbStringFromInt, _bbGCFree (compiler-emitted)
'   String literals read out of the exe with harness.read_string:
'     0x00C8AFDC "dilemma"   0x00C5D284 ""          0x00C7A660 "Boss"
'     0x00C70D78 "Team"      0x00C7A674 "Fans"      0x00C87124 "Friends"
'     0x00C87250 "Girlfriend" 0x00C87378 "Sponsors" 0x00C8AFF8 "Dilemma!"
'     0x00C5D680 "FFFFFF"
'!Global g_dil_prg1:TProgressBar
'!Global g_dil_prg2:TProgressBar
'!Global g_dil_btn1:TButton
'!Global g_dil_btn2:TButton
'!Global g_dil_choice1:Int
'!Global g_dil_choice2:Int
'!Global g_dil_img1:TImage
'!Global g_dil_img2:TImage
'!Global g_img_boss:TImage
'!Global g_dilemma_img_training:TImage
'!Global g_img_fans:TImage
'!Global g_img_bowling:TImage
'!Global g_img_golf:TImage
'!Global g_img_cinema:TImage
'!Global g_img_pub:TImage
'!Global g_img_restaurant:TImage
'!Global g_img_shopping:TImage
'!Global g_img_sponsors:TImage
'!Global g_profile:TProfile
'!Global g_font16:TBitmapFont
'!Global g_gfx_width:Int
'!Global g_gfx_height:Int
TScreen.SetActive("dilemma","")
g_dil_choice1 = 0
Repeat
	g_dil_choice1 = Rand(6,1)
	If g_dil_choice1 = 5 And g_profile.relationgirlfriend = 0 Then g_dil_choice1 = 0
	If g_dil_choice1 = 6 And g_profile.GotSponsor() = 0 Then g_dil_choice1 = 0
Until g_dil_choice1 > 0
g_dil_choice2 = 0
Repeat
	g_dil_choice2 = Rand(6,1)
	If g_dil_choice2 = 5 And g_profile.relationgirlfriend = 0 Then g_dil_choice2 = 0
	If g_dil_choice2 = 6 And g_profile.GotSponsor() = 0 Then g_dil_choice2 = 0
Until g_dil_choice2 > 0 And g_dil_choice1 <> g_dil_choice2
Select g_dil_choice1
Case 1
	g_dil_prg1.SetPercent(g_profile.relationboss,1)
	g_dil_prg1.SetColour(String(g_profile.relationboss),"")
	g_dil_btn1.SetText(GetText("Boss"),"",-1,-1)
	Select Rand(2,1)
	Case 1
		g_dil_img1 = g_img_boss
	Case 2
		g_dil_img1 = g_dilemma_img_training
	End Select
Case 2
	g_dil_prg1.SetPercent(g_profile.relationteam,1)
	g_dil_prg1.SetColour(String(g_profile.relationteam),"")
	g_dil_btn1.SetText(GetText("Team"),"",-1,-1)
	Select Rand(3,1)
	Case 1
		g_dil_img1 = g_img_bowling
	Case 2
		g_dil_img1 = g_img_golf
	Case 3
		g_dil_img1 = g_dilemma_img_training
	End Select
Case 3
	g_dil_prg1.SetPercent(g_profile.relationfans,1)
	g_dil_prg1.SetColour(String(g_profile.relationfans),"")
	g_dil_btn1.SetText(GetText("Fans"),"",-1,-1)
	g_dil_img1 = g_img_fans
Case 4
	g_dil_prg1.SetPercent(g_profile.relationfriends,1)
	g_dil_prg1.SetColour(String(g_profile.relationfriends),"")
	g_dil_btn1.SetText(GetText("Friends"),"",-1,-1)
	Select Rand(5,1)
	Case 1
		g_dil_img1 = g_img_bowling
	Case 2
		g_dil_img1 = g_img_cinema
	Case 3
		g_dil_img1 = g_img_golf
	Case 4
		g_dil_img1 = g_img_pub
	Case 5
		g_dil_img1 = g_img_shopping
	End Select
Case 5
	g_dil_prg1.SetPercent(g_profile.relationgirlfriend,1)
	g_dil_prg1.SetColour(String(g_profile.relationgirlfriend),"")
	g_dil_btn1.SetText(GetText("Girlfriend"),"",-1,-1)
	Select Rand(4,1)
	Case 1
		g_dil_img1 = g_img_cinema
	Case 2
		g_dil_img1 = g_img_pub
	Case 3
		g_dil_img1 = g_img_restaurant
	Case 4
		g_dil_img1 = g_img_shopping
	End Select
Case 6
	g_dil_prg1.SetPercent(g_profile.relationsponsors,1)
	g_dil_prg1.SetColour(String(g_profile.relationsponsors),"")
	g_dil_btn1.SetText(GetText("Sponsors"),"",-1,-1)
	g_dil_img1 = g_img_sponsors
End Select
Repeat
	Select g_dil_choice2
	Case 1
		g_dil_prg2.SetPercent(g_profile.relationboss,1)
		g_dil_prg2.SetColour(String(g_profile.relationboss),"")
		g_dil_btn2.SetText(GetText("Boss"),"",-1,-1)
		Select Rand(2,1)
		Case 1
			g_dil_img2 = g_img_boss
		Case 2
			g_dil_img2 = g_dilemma_img_training
		End Select
	Case 2
		g_dil_prg2.SetPercent(g_profile.relationteam,1)
		g_dil_prg2.SetColour(String(g_profile.relationteam),"")
		g_dil_btn2.SetText(GetText("Team"),"",-1,-1)
		Select Rand(3,1)
		Case 1
			g_dil_img2 = g_img_bowling
		Case 2
			g_dil_img2 = g_img_golf
		Case 3
			g_dil_img2 = g_dilemma_img_training
		End Select
	Case 3
		g_dil_prg2.SetPercent(g_profile.relationfans,1)
		g_dil_prg2.SetColour(String(g_profile.relationfans),"")
		g_dil_btn2.SetText(GetText("Fans"),"",-1,-1)
		g_dil_img2 = g_img_fans
	Case 4
		g_dil_prg2.SetPercent(g_profile.relationfriends,1)
		g_dil_prg2.SetColour(String(g_profile.relationfriends),"")
		g_dil_btn2.SetText(GetText("Friends"),"",-1,-1)
		Select Rand(5,1)
		Case 1
			g_dil_img2 = g_img_bowling
		Case 2
			g_dil_img2 = g_img_cinema
		Case 3
			g_dil_img2 = g_img_golf
		Case 4
			g_dil_img2 = g_img_pub
		Case 5
			g_dil_img2 = g_img_shopping
		End Select
	Case 5
		g_dil_prg2.SetPercent(g_profile.relationgirlfriend,1)
		g_dil_prg2.SetColour(String(g_profile.relationgirlfriend),"")
		g_dil_btn2.SetText(GetText("Girlfriend"),"",-1,-1)
		Select Rand(4,1)
		Case 1
			g_dil_img2 = g_img_cinema
		Case 2
			g_dil_img2 = g_img_pub
		Case 3
			g_dil_img2 = g_img_restaurant
		Case 4
			g_dil_img2 = g_img_shopping
		End Select
	Case 6
		g_dil_prg2.SetPercent(g_profile.relationsponsors,1)
		g_dil_prg2.SetColour(String(g_profile.relationsponsors),"")
		g_dil_btn2.SetText(GetText("Sponsors"),"",-1,-1)
		g_dil_img2 = g_img_sponsors
	End Select
Until g_dil_img1 <> g_dil_img2
TScreenMessage.Create(g_gfx_width/2,g_gfx_height/2,GetText("Dilemma!"),1000,g_font16,Null,1.0,"FFFFFF")
If g_profile.helppages[12] = 0
	TScreen.Tutorial()
	g_profile.helppages[12] = 1
EndIf
