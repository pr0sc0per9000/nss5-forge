' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TProfile.SetPlayButtonIcon  -- KIND=Method, slot 0x70
' VA 0x00567AD5   420 bytes   sig ()i
' byte-identical vs NSS5.exe (420/420, original length from Ghidra's inventory,
' mode=reloc, reloc_masked=27)
'
' ASSUMPTIONS
'  Module Globals declared (names are ours; types load-bearing):
'    0x00C66798 g_playbutton  : TButton  (globals_final: construction, medium; slot 0x90
'                                        resolves to TButton.SetIcon(:TImage)i, which
'                                        confirms it -- TGadget has no 0x90)
'    0x00C66758 g_icon_physio : TImage
'    0x00C6675C g_icon_boss   : TImage   (globals_final: 'verified' TImage)
'    0x00C66760 g_icon_coach  : TImage
'    0x00C66748 g_icon_league : TImage
'    0x00C66754 g_icon_train  : TImage
'    0x00C66744 g_icon_match  : TImage
'    0x00C66750 g_icon_cup    : TImage
'    0x00C6674C g_icon_end    : TImage
'    globals_final types the eight icon slots only as "Object" (usage/low). TImage is
'    inferred from the parameter type of TButton.SetIcon; the match does not distinguish
'    TImage from any other object type here, so that is an assumption, not a proof.
'  Class-table slot resolved:
'    [0x00C6160C] = TCompetition + 0x4C = SelectById(i):TCompetition
'  Direct calls resolved:
'    0x00505B91 -> LogLine;  0x004A6A30 -> _bbStringCompare (the pushed 0x00C5D284 is
'    the empty-string constant, so each test is `field <> ""`)
'  It is a Select, NOT an If/ElseIf chain: all five compares are emitted back to back
'  before any body, and there is no Default (the no-match path jumps past End Select).
'  Case order 1,3,2,4,5 is the order in the binary and is load-bearing.
'  The inner three-way test inside Case 1 IS an If/ElseIf cascade (test interleaved
'  with body), unlike the outer Select.
'  The log string literal is pushed as an absolute data address.

	Method SetPlayButtonIcon:Int()
		'!Global g_playbutton:TButton
		'!Global g_icon_physio:TImage
		'!Global g_icon_boss:TImage
		'!Global g_icon_coach:TImage
		'!Global g_icon_league:TImage
		'!Global g_icon_train:TImage
		'!Global g_icon_match:TImage
		'!Global g_icon_cup:TImage
		'!Global g_icon_end:TImage
		LogLine("SetPlayButtonIcon")
		Select Self.playbuttontype
			Case 1
				If Self.physioreport <> ""
					g_playbutton.SetIcon(g_icon_physio)
				ElseIf Self.bossreport <> ""
					g_playbutton.SetIcon(g_icon_boss)
				ElseIf Self.coachreport <> ""
					g_playbutton.SetIcon(g_icon_coach)
				End If
			Case 3
				g_playbutton.SetIcon(g_icon_league)
			Case 2
				g_playbutton.SetIcon(g_icon_train)
			Case 4
				g_playbutton.SetIcon(g_icon_match)
				Local f:TFixture = Self.GetNextFixture(0)
				If f <> Null
					Local comp:TCompetition = TCompetition.SelectById(f.compid)
					If comp <> Null And comp.comptype = 1
						g_playbutton.SetIcon(g_icon_cup)
					End If
				End If
			Case 5
				g_playbutton.SetIcon(g_icon_end)
		End Select
	End Method
