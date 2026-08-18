' TTraining.Success   (KIND=Function -- static, no Self)
' VA 0x00581969   864 bytes   class-table slot 0x98   sig ()i
' byte-identical vs NSS5.exe (864/864, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=864/864  reloc_masked=51  STATUS=MATCH
' Original length from Ghidra's inventory. NSS5_NO_LEARN=1.
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C6CF74 g_snd_training_success1:TSound   argument 1 of PlaySound
'   0x00C6CF78 g_snd_training_success2:TSound
'   0x00C6F090 g_chan_training:TChannel         argument 2 of PlaySound; already :TChannel
'                                               in TBlackJack.Deal / Hit / Update
'   0x00C5B348 g_crowd_oohchannel:TChannel      already :TChannel in TBall.HitPost
'   0x00C6CF98 g_training_state:Int             bare dword store of 2
'   0x00C5B1FC g_matchmode:Int                  globals_final type_source=verified Int
'   0x00C6CFA4 g_training_headline:String       full retain/release around the store --
'   0x00C6CFAC g_training_message:String        codegen-patterns 11.2. globals_final calls
'                                               both "Int (usage)"; the code says String.
'   0x00C6CF90 g_trainingmode:Int               already Int in TBall.HitPost / CheckAdHoardings
'   0x00C6F028 g_profile:TProfile               construction site
' Class-table static call: 0x00C6B274 = TScreenMessage+0x40 -> ClearAll(i)i.
' Module Function GetText (0x004C5549); 0x004A7410 = Lower; 0x0059B25E = PlaySound.
' TProfile slots 0xA4 GetSkillRating, 0xA8 UpdateAbility(i,i), 0xC0 UpdateRelationship(i,i),
' 0x150 CheckAchievement(i); fields +0xA4..+0xBC the seven skills, +0x104 relationboss,
' +0x1DC matchskipped.
'
' NOTES
'   * The training-mode dispatch is ONE `Select` whose `Case 0` body is EMPTY -- not an
'     enclosing `If g_trainingmode <> 0`. The subject is loaded once and `cmp eax,0 / je`
'     is the first of eleven back-to-back compares (codegen-patterns 10.2); the
'     If-plus-Select spelling costs 3 bytes more.
'   * Every skill test is `>= 100` (`cmp ...,0x64 / jl`), not `> 99` (`cmp ...,0x63 / jle`).
'     Same meaning, eight different bytes -- codegen-patterns 10.1.

'!Global g_snd_training_success1:TSound
'!Global g_snd_training_success2:TSound
'!Global g_chan_training:TChannel
'!Global g_crowd_oohchannel:TChannel
'!Global g_training_state:Int
'!Global g_matchmode:Int
'!Global g_training_headline:String
'!Global g_training_message:String
'!Global g_trainingmode:Int
'!Global g_profile:TProfile
PlaySound(g_snd_training_success1, g_chan_training)
PlaySound(g_snd_training_success2, g_crowd_oohchannel)
TScreenMessage.ClearAll(0)
g_training_state = 2
g_matchmode = 11
g_training_headline = Lower(GetText("Success!"))
g_training_message = GetText("CMESSAGE_TRAININGSUCCESS")
If g_profile.matchskipped = 0
	g_profile.UpdateRelationship(1, 2)
	If g_profile.relationboss < 20 Then g_profile.UpdateRelationship(1, 3)
EndIf
Select g_trainingmode
	Case 0
	Case 1
		g_profile.UpdateAbility(1, 10)
	Case 2
		g_profile.UpdateAbility(2, 5)
	Case 3
		g_profile.UpdateAbility(7, 10)
	Case 4
		g_profile.UpdateAbility(3, 5)
	Case 5
		g_profile.UpdateAbility(3, 5)
	Case 6
		g_profile.UpdateAbility(4, 5)
	Case 7
		g_profile.UpdateAbility(5, 10)
	Case 8
		g_profile.UpdateAbility(5, 10)
	Case 9
		g_profile.UpdateAbility(6, 5)
	Case 10
		g_profile.UpdateAbility(6, 5)
End Select
If g_profile.pace >= 100 Then g_profile.CheckAchievement(64)
If g_profile.dribbling >= 100 Then g_profile.CheckAchievement(65)
If g_profile.tackling >= 100 Then g_profile.CheckAchievement(66)
If g_profile.passing >= 100 Then g_profile.CheckAchievement(67)
If g_profile.heading >= 100 Then g_profile.CheckAchievement(68)
If g_profile.shooting >= 100 Then g_profile.CheckAchievement(69)
If g_profile.flair >= 100 Then g_profile.CheckAchievement(70)
If g_profile.GetSkillRating() >= 100 Then g_profile.CheckAchievement(71)
