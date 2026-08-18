' TPromotionPlace.WriteData
' VA 0x00525FF2   350 bytes   class-table slot 0x3c   sig (:TStream)i   KIND=Function (static)
' byte-identical vs NSS5.exe (350/350, original length from Ghidra's inventory)
' harness mode=reloc.
' Body-only format: statements only, parameters are a0, a1, ...
' FUN_005b8307 = _brl_stream_WriteLine.  FUN_004a7ac0 = _bbStringFromInt (String(i)).
' FUN_004a7c20 = _bbStringConcat.  FUN_004a8f60 = _bbObjectDowncast (the For EachIn).
' fields read: TCompetition.id +0x8, TCompetition.lpromotionplaces +0x64,
'              TPromotionPlace.place +0xc, TPromotionPlace.promotiontoid +0x10.
' class tables in the two EachIn downcasts: 0x00c615c0 = TCompetition,
'              0x00c64754 = TPromotionPlace.
' SHAPE NOTE (measured): the three fields MUST be accumulated through a String Local.
'   Written as one expression -- (String(c.id)+",")+(String(p.place)+",")+... -- bcc
'   evaluates the concat tree right-to-left and parks the partial results on the
'   machine stack, giving 341 bytes and only 3 stack slots (sub esp,0xc).  The
'   original keeps a running accumulator in ebx (mov ebx,eax after every concat),
'   which spills the inner enumerator to a 4th slot (sub esp,0x10).  That is the
'   missing 9 bytes.  `line :+ X` and `line = line + X` are indistinguishable here.
'   Note bcc emits NO refcount traffic for this String Local -- it never reaches
'   memory, so the Local is purely an evaluation-order construct.
' STRING LITERALS: the body reads "parentid~tplace~tpromotiontoid", "~t", "~t", "//"
'   at 0x00c81f44/0x00c6fcc0/0x00c6fe94 -- harness.read_string confirms all four
'   exactly. The byte match alone cannot observe them.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_competitions:TList   ' 0x00c6099c -- globals_final.tsv says only
'                                 '   "Object, usage, low"; slot 0x8c
'                                 '   (ObjectEnumerator) is used on it, and its
'                                 '   members downcast to TCompetition, so TList.
'!Global g_competitions:TList
WriteLine(a0, "parentid~tplace~tpromotiontoid")
For Local c:TCompetition = EachIn g_competitions
	For Local p:TPromotionPlace = EachIn c.lpromotionplaces
		Local line:String = String(c.id)+"~t"
		line :+ String(p.place)+"~t"
		line :+ String(p.promotiontoid)+"~t"
		WriteLine(a0, line)
	Next
Next
WriteLine(a0, "//")
