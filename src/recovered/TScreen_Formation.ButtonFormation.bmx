' TScreen_Formation.ButtonFormation
' VA 0x0054BCA1   891 bytes   KIND=Function (static, no Self)   SIG ()i   class-table slot 0x38
' byte-identical vs NSS5.exe (891/891, original length from Ghidra's inventory, mode=reloc)
'
' Handler for clicking a formation-diagram button on the tactics screen. Validates the
' player is captain and, depending on captaincy level, has enough boss-relationship before
' allowing a formation change; then reads which button fired via GetActiveGadgetName() and
' maps its "N-N-N"-style label to a formation index for TTeam.ChangeFormation. Blocks a
' repeat change for a few matches, nagging with a relationship penalty on early retry.
'
' Reconstructed from raw disassembly (Ghidra's decompilation merges each call's argument
' pushes with the FOLLOWING call's -- codegen-patterns.md CALL-annotation note). Three
' points where the byte-exact form differs from the naive transcription:
'   - The captaincy-level check (1/2/3, each gated on a different relationboss threshold)
'     compiles as a `Select` (all three `cmp`s emitted back-to-back, bodies afterward), not
'     an If/ElseIf cascade -- confirmed by localise_diff against the raw bytes.
'   - The button-label match ("3-4-3".."5-3-2" -> ChangeFormation 1..11) is likewise a
'     `Select` over the String, not an If/ElseIf chain -- same "all tests, then all bodies"
'     shape (codegen-patterns.md 10.2).
'   - `If formationchanged = 0 Then <switch+refresh> Else <recent-change message>` is
'     written the other way around and NEGATED: `If formationchanged <> 0 Then <message>
'     Else <switch+refresh>` -- the solo-equality If/Else branch-swap rule (codegen-patterns
'     section 21): bcc places the textually-first branch's code inline at the test
'     site and jumps to the second branch, so matching which branch sits at the LOWER
'     address requires writing the "message" case as the Then and the "switch" case as the
'     Else. Every branch that reaches the function's `Return 0` exit -- including ones with
'     no more statements after them in source -- carries its OWN explicit `Return 0`
'     (own inline `mov eax,0` + `jmp`); relying on one shared exit is 5-10 bytes short at
'     each such site (three exits below, confirmed by localise_diff).
'
' Globals (names ours; addresses and TYPES are load-bearing):
'   0x00C677D8 g_screen_formation_ready:Int    guard flag (globals_final.tsv: "read-only
'                                               int slot")
'   0x00C6F028 g_profile:TProfile              the managed player's own profile (verified,
'                                               hand-corrected in globals_corrections.tsv;
'                                               globals_final.tsv's "TContractOffer" usage
'                                               note is an unsound guess)
'   0x00C5D228 g_captaincy_level:Int           1/2/3 = vice-captain tiers (globals_final.tsv:
'                                               generic Int usage)
'   0x00C677B0 g_myteam:TTeam                  forced TTeam by the ChangeFormation(i,i)
'                                               virtual call at slot 0x5C (globals_final.tsv:
'                                               generic Object, low confidence)
'   TProfile fields (from object_model.json, confirmed against the field offsets in this
'   body): +0x120 captain:Int, +0x104 relationboss:Int, +0x1E4 formationchanged:Int.
'
' Class-table slots used: 0x00C61CC0 TScreen+0x94 DoMessage; 0x00C621CC TGadget+0x7C
'   GetActiveGadgetName; 0x00C63294 unused here; TProfile+0xC0 UpdateRelationship(i,i)
'   (0x0056A955, verified by vtable_map -- confirms g_profile's Type independently of the
'   construction-site note); TTeam+0x5C ChangeFormation(i,i); TScreen_Formation+0x3C
'   RefreshButtons, +0x44 CheckPosition.
'
' Literals read from the exe with harness.read_string(): "CMESSAGE_NEWFORMATIONNOTCAPTAIN",
' "CMESSAGE_NEWFORMATIONFAILRELATIONSHIP", "CMESSAGE_NEWFORMATIONFAILRECENT", and the
' eleven formation labels "3-4-3", "3-5-2 A", "3-5-2 B", "4-2-2-2", "4-2-4", "4-3-3",
' "4-4-1-1", "4-4-2 A", "4-4-2 B", "4-5-1", "5-3-2".
Function ButtonFormation:Int()
	'!Global g_screen_formation_ready:Int
	'!Global g_profile:TProfile
	'!Global g_captaincy_level:Int
	'!Global g_myteam:TTeam

	If g_screen_formation_ready <> 0 Then Return 0

	If g_profile.captain = 0
		TScreen.DoMessage(GetText("CMESSAGE_NEWFORMATIONNOTCAPTAIN"), 0, 0)
		Return 0
	Else
		Select g_captaincy_level
			Case 1
				If g_profile.relationboss < 30
					TScreen.DoMessage(GetText("CMESSAGE_NEWFORMATIONFAILRELATIONSHIP"), 0, 0)
					Return 0
				EndIf
			Case 2
				If g_profile.relationboss < 60
					TScreen.DoMessage(GetText("CMESSAGE_NEWFORMATIONFAILRELATIONSHIP"), 0, 0)
					Return 0
				EndIf
			Case 3
				If g_profile.relationboss < 90
					TScreen.DoMessage(GetText("CMESSAGE_NEWFORMATIONFAILRELATIONSHIP"), 0, 0)
					Return 0
				EndIf
		End Select
		If g_profile.formationchanged <> 0
			If g_profile.formationchanged > 2 Then Return 0
			TScreen.DoMessage(GetText("CMESSAGE_NEWFORMATIONFAILRECENT"), 0, 0)
			g_profile.UpdateRelationship(1, -10)
			g_profile.formationchanged = 3
			Return 0
		Else
			Local gname:String = TGadget.GetActiveGadgetName()
			Select gname
				Case "3-4-3"
					g_myteam.ChangeFormation(1, 0)
				Case "3-5-2 A"
					g_myteam.ChangeFormation(2, 0)
				Case "3-5-2 B"
					g_myteam.ChangeFormation(3, 0)
				Case "4-2-2-2"
					g_myteam.ChangeFormation(4, 0)
				Case "4-2-4"
					g_myteam.ChangeFormation(5, 0)
				Case "4-3-3"
					g_myteam.ChangeFormation(6, 0)
				Case "4-4-1-1"
					g_myteam.ChangeFormation(7, 0)
				Case "4-4-2 A"
					g_myteam.ChangeFormation(8, 0)
				Case "4-4-2 B"
					g_myteam.ChangeFormation(9, 0)
				Case "4-5-1"
					g_myteam.ChangeFormation(10, 0)
				Case "5-3-2"
					g_myteam.ChangeFormation(11, 0)
			End Select
			TScreen_Formation.CheckPosition()
			TScreen_Formation.RefreshButtons()
		EndIf
	EndIf
	Return 0
End Function
