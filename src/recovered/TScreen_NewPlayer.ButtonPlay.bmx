' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_NewPlayer.ButtonPlay
' VA 0x0052496F   453 bytes   class-table slot 0x58   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (453/453, original length from Ghidra's inventory)
' harness mode=reloc, reloc_masked=33.
' Body-only format: statements only, parameters are a0, a1, ...
' CALL TARGETS RESOLVED
'   FUN_004c5549              = the recovered module Function GetText ($)$
'   [0x00c61cc0]              = TScreen class table (0x00c61c2c) + 0x94 = TScreen.DoMessage($,i,i)i
'                               Ghidra prints it one-argument; disasm shows push 0/push 0
'                               ahead of the literal, so it really takes three.
'   [0x00c59a20]              = TNation class table (0x00c599c8) + 0x58 = TNation.SelectById(i):TNation
'   [0x00c64404] / [0x00c6442c] = TScreen_NewPlayer class table (0x00c643d0) + 0x34 / + 0x5c
'                               = SetUpScreen() / DoClubTrial(), i.e. sibling statics,
'                               written unqualified per codegen-patterns section 3d.
'   slot 0xc0 on a TCombo     = TCombo.GetSelectedItemId()i ; slot 0xb0 = TCombo.SelectItemById(i)i
'   slot 0x94 on 0x00c6421c   = TInputBox.GetText()$
' TProfile fields used: name +0x14 ($), nationid +0x1c, position +0x30, side +0x34,
'   mynation +0x1cc (:TNation).  `.Length` on the name reads the BBString +8 header word.
' SHAPE NOTES (measured)
'   * the three failure branches are EARLY RETURNS, not an If/ElseIf cascade: each body
'     ends `mov eax,0 / jmp <epilogue>`.  As nested If/Else the body is 428 bytes.
'   * the mynation test MUST be `If Not ...` -- the original emits the 21-byte
'     cmp/setne/movzx/cmp/jne form of section 10.3.  `= Null` gives the 12-byte form
'     and leaves the body 10 bytes short.
'   * `If g_profile.position = 0 Or g_profile.side < 0` reproduces the sete/setl pair.
' The three string literals are pushed by address only, so their contents are
'   unobservable; "A"/"B"/"C" stand for 0x00c816e8 / 0x00c81718 / 0x00c81758.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_np_nameinput:TInputBox  ' 0x00c6421c -- globals_final.tsv flags a
'                                    '   TPanel/TInputBox construction CONFLICT; slot
'                                    '   0x94 is TInputBox.GetText and TPanel/TGadget
'                                    '   has no 0x94, so the code settles it: TInputBox.
'   Global g_profile:TProfile        ' 0x00c6f028 (construction, 3 sites, high)
'   Global g_np_combonation:TCombo   ' 0x00c64220
'   Global g_np_comboclub:TCombo     ' 0x00c64228
'   Global g_np_comboposition:TCombo ' 0x00c64234
'   Global g_np_comboside:TCombo     ' 0x00c64238
'!Global g_np_nameinput:TInputBox
'!Global g_profile:TProfile
'!Global g_np_combonation:TCombo
'!Global g_np_comboclub:TCombo
'!Global g_np_comboposition:TCombo
'!Global g_np_comboside:TCombo
g_profile.name = g_np_nameinput.GetText()
If g_profile.name.Length < 3
	TScreen.DoMessage(GetText("CMESSAGE_ENTERNAME"), 0, 0)
	Return 0
EndIf
g_profile.nationid = g_np_combonation.GetSelectedItemId()
g_profile.mynation = TNation.SelectById(g_profile.nationid)
If Not g_profile.mynation
	TScreen.DoMessage(GetText("CMESSAGE_CHOOSENATIONALITY"), 0, 0)
	Return 0
EndIf
If g_np_comboclub.GetSelectedItemId() < 1
	g_np_comboclub.SelectItemById(62)
EndIf
g_profile.position = g_np_comboposition.GetSelectedItemId()
g_profile.side = g_np_comboside.GetSelectedItemId() - 1
If g_profile.position = 0 Or g_profile.side < 0
	TScreen.DoMessage(GetText("CMESSAGE_CHOOSEPOSITION"), 0, 0)
	Return 0
EndIf
SetUpScreen()
DoClubTrial()
