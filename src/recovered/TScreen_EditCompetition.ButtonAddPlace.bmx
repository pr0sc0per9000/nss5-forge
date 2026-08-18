' TScreen_EditCompetition.ButtonAddPlace
' VA 0x005320F5   358 bytes   class-table slot 0x3C   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (358/358, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=25)
'
' ASSUMPTIONS
'  Module Globals -- NAMES ARE OURS, declared TYPES are load-bearing:
'    0x00C65784 TInputBox    g_ec_placebox  (globals_final: construction/medium; slot 0x94
'                                            = TInputBox.GetText()$ confirms it)
'    0x00C65788 TInputBox    g_ec_compbox   (same)
'    0x00C65720 TCompetition g_ec_comp      -- globals_final flags a CONFLICT here
'                 (TScreen=1;TCompetition=1) and picks TScreen.  It is TCompetition:
'                 the code calls slot 0x114 on it, which is TCompetition.SortPromotionPlaces,
'                 and reads +0x08 (id) and +0x20 (based) -- both TCompetition fields.
'  Slots resolved:
'    [0x00C6160C] = TCompetition + 0x4C = SelectById(i):TCompetition
'    [0x00C61610] = TCompetition + 0x50 = SelectByBasedAndName(i,$):TCompetition
'    [0x00C61614] = TCompetition + 0x54 = SelectByTLA($):TCompetition
'    [0x00C61CC0] = TScreen      + 0x94 = TScreen.DoMessage($,i,i)i
'    [0x00C64788] = TPromotionPlace + 0x34 = NewPromotionPlace(i,i,i)i
'    [0x00C658D8] = TScreen_EditCompetition + 0x34 = SetUpScreen(i,$)i
'                   -> sibling Function of THIS Type: written WITHOUT the Type prefix
'    TInputBox slot 0x94 = TInputBox.GetText()$   (NOT the module Function GetText)
'    TCompetition slot 0x114 = SortPromotionPlaces()
'  Runtime: 0x004A7130 = _bbStringToInt -> Int(s);  0x004C5549 = GetText (module Function,
'    ONE argument -- the `push 0 / push 0` before it are TScreen.DoMessage's.
'  Literals: 0x00C844F8 "CMESSAGE_INVALIDPLACE", 0x00C84530 "CMESSAGE_INVALIDCOMPETITION",
'    0x00C5D284 "".
'  SHAPE: both message branches are early returns (`mov eax,0 / jmp epilogue`), not
'  If/Else.  Guard spelling read off the setcc: `setl 1` = `< 1`, `setg 0x6C` = `> 108`.
'  The three `cmp edx,0x5C9C80 / setne / movzx / cmp eax,0 / jne` runs are the `If Not c`
'  emission (codegen-patterns 10.3).
	'!Global g_ec_placebox:TInputBox
	'!Global g_ec_compbox:TInputBox
	'!Global g_ec_comp:TCompetition
	Function ButtonAddPlace:Int()
		Local place:Int = Int(g_ec_placebox.GetText())
		If place < 1 Or place > 108
			TScreen.DoMessage(GetText("CMESSAGE_INVALIDPLACE"), 0, 0)
			Return 0
		EndIf
		Local c:TCompetition = TCompetition.SelectById(Int(g_ec_compbox.GetText()))
		If Not c Then c = TCompetition.SelectByBasedAndName(g_ec_comp.based, g_ec_compbox.GetText())
		If Not c Then c = TCompetition.SelectByTLA(g_ec_compbox.GetText())
		If Not c
			TScreen.DoMessage(GetText("CMESSAGE_INVALIDCOMPETITION"), 0, 0)
			Return 0
		EndIf
		TPromotionPlace.NewPromotionPlace(g_ec_comp.id, place, c.id)
		g_ec_comp.SortPromotionPlaces()
		SetUpScreen(g_ec_comp.id, "")
	End Function
