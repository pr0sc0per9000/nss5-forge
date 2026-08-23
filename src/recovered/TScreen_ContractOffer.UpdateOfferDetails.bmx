' TScreen_ContractOffer.UpdateOfferDetails
' VA 0x00553C12   945 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (i,i)i, class-table slot 0x3C
' (945/945, original length from Ghidra's inventory; verified under NSS5_NO_LEARN=1,
'  reloc_masked=87.  First attempt, no iteration.)
'
' ASSUMPTIONS -- Global NAMES are ours, the declared TYPES are load-bearing.
'   0x00C67B88 g_co_offer:TContractOffer  -- globals_final.tsv has it as bare Object.  Its
'     +8 is dereferenced and slot 0x3C (TBase_Team.GetPrimaryColour) called on it, which
'     is TContractOffer.club:TClub; +0xC/0x14/0x18/0x1C/0x20 are the five money fields and
'     +0x24/+0x28 newbossrel/negotiationsuccess -- the exact TContractOffer layout.
'     Do not spell this slot `g_offer`: everywhere else in the corpus that name denotes
'     0x00C6CC3C, the NEGOTIATE screen's own offer, which only TScreen_Negotiate.SetUpScreen
'     writes and which is Null until that screen has been opened -- so on a first contract
'     the whole body would read through Null.  The sole writer of 0x00C67B88 is
'     TScreen_ContractOffer.SetUpScreen (`mov [0xc67b88],ebx` at 0x00553802) and it calls
'     the slot g_co_offer, so that is the name here.  g_co_offer and g_offer are two
'     addresses and must never be merged.
'   0x00C67B58 g_lbl_clubname:TLabel    0x00C67B5C g_lbl_nation:TLabel
'   0x00C67B60 g_lbl_league:TLabel      0x00C67B64 g_pb_rel:TProgressBar
'   0x00C67B68 g_lbl_wage:TLabel        0x00C67B6C g_lbl_goalbonus:TLabel
'   0x00C67B70 g_lbl_assistbonus:TLabel 0x00C67B74 g_lbl_cleanbonus:TLabel
'   0x00C67B78 g_lbl_signingfee:TLabel  0x00C67B7C g_lbl_length:TLabel
'   0x00C67B80 g_btn_accept:TButton
'   0x00C6E91C g_colour_disabled:String -- globals_final.tsv calls it
'     `g_screen_stable_int35:Int`; it is pushed straight into TGadget.SetColour's first
'     ($) parameter with no Int->String conversion, so it is a String (pattern 16.7).
'   TClub Extends TBase_Team, so club.labelname is +0x1C and slot 0x3C is
'     GetPrimaryColour()$; TNation likewise (nat.labelname +0x1C).
' SHAPE NOTES
'   * Ghidra prints `club.GetPrimaryColour("FFFFFF")` and
'     `comp.GetStringTeamPosition(club.id," ",comp.name,"",-1,-1)`.  Both are the merge
'     artefact the annotator warns about: call_arity says +0x3C takes only the receiver
'     and +0x9C takes receiver+1, so "FFFFFF" belongs to the FOLLOWING SetColour and
'     " " / comp.name to the two _bbStringConcat calls.
'   * the league label is `pos + " " + comp.name` -- left-associative, concat(pos," ")
'     first, then concat(that, name) (section 16.1).
'   * TGadget.SetText's ("",-1,-1) and SetColour's second argument are BlitzMax defaults
'     that bcc emits as explicit pushes, so spelling them out is byte-identical.
'   * the accept-button dim is a short-circuit `Or`, not two Ifs:
'     `negotiationsuccess` is tested first and the `newbossrel < 40` test is skipped when
'     it is non-zero.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_co_offer:TContractOffer
'!Global g_lbl_clubname:TLabel
'!Global g_lbl_nation:TLabel
'!Global g_lbl_league:TLabel
'!Global g_pb_rel:TProgressBar
'!Global g_lbl_wage:TLabel
'!Global g_lbl_goalbonus:TLabel
'!Global g_lbl_assistbonus:TLabel
'!Global g_lbl_cleanbonus:TLabel
'!Global g_lbl_signingfee:TLabel
'!Global g_lbl_length:TLabel
'!Global g_btn_accept:TButton
'!Global g_colour_disabled:String
Local nat:TNation = TNation.SelectById(g_co_offer.club.nationid)
Local comp:TCompetition = TCompetition.SelectById(g_co_offer.club.leagueid)
g_lbl_clubname.SetColour(g_co_offer.club.GetPrimaryColour(), "FFFFFF")
g_lbl_clubname.SetText(g_co_offer.club.labelname, "", -1, -1)
g_lbl_nation.SetText(nat.labelname, "", -1, -1)
g_lbl_league.SetText(comp.GetStringTeamPosition(g_co_offer.club.id) + " " + comp.name, "", -1, -1)
g_pb_rel.SetPercent(g_co_offer.newbossrel, a0)
g_pb_rel.SetColour("", "00FF00")
If g_co_offer.newbossrel < 50
	g_pb_rel.SetColour("", "FF0000")
End If
g_lbl_wage.SetColour("888888", "FFFFFF")
g_lbl_goalbonus.SetColour("888888", "FFFFFF")
g_lbl_assistbonus.SetColour("888888", "FFFFFF")
g_lbl_cleanbonus.SetColour("888888", "FFFFFF")
g_lbl_signingfee.SetColour("888888", "FFFFFF")
g_lbl_length.SetColour("888888", "FFFFFF")
If a1 <> 0
	g_lbl_wage.SetColour(g_colour_disabled, "FFFFFF")
	g_lbl_goalbonus.SetColour(g_colour_disabled, "FFFFFF")
	g_lbl_assistbonus.SetColour(g_colour_disabled, "FFFFFF")
	g_lbl_cleanbonus.SetColour(g_colour_disabled, "FFFFFF")
	g_lbl_signingfee.SetColour(g_colour_disabled, "FFFFFF")
End If
g_lbl_wage.SetText(FormatMoney(g_co_offer.wage, 0), "", -1, -1)
g_lbl_goalbonus.SetText(FormatMoney(g_co_offer.goalbonus, 0), "", -1, -1)
g_lbl_assistbonus.SetText(FormatMoney(g_co_offer.assistbonus, 0), "", -1, -1)
g_lbl_cleanbonus.SetText(FormatMoney(g_co_offer.cleanbonus, 0), "", -1, -1)
g_lbl_signingfee.SetText(FormatMoney(g_co_offer.signingfee, 0), "", -1, -1)
g_lbl_length.SetText(g_co_offer.GetStringLength(), "", -1, -1)
g_btn_accept.SetAlph(1.0)
If g_co_offer.negotiationsuccess Or g_co_offer.newbossrel < 40
	g_btn_accept.SetAlph(0.5)
End If
