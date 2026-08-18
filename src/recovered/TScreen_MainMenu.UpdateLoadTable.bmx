' TScreen_MainMenu.UpdateLoadTable
' VA 0x0051D183   972 bytes   byte-identical vs NSS5.exe (modulo the four masks)
' KIND=Function (static method on the Type, no implicit Self), SIG=()i, class-table slot 0x4c
' ORACLE 972/972, verified under NSS5_NO_LEARN=1.
'
' ASSUMPTIONS / RESOLUTIONS
'  * Module Globals (names ours; ADDRESS + TYPE load-bearing):
'      g_mm_tableload:TTable 0x00C639DC  (slots 0x9C ClearItems, 0x94 AddItem([]$,$,$),
'                                         0xEC CountItems, 0xDC SelectItemByRow(i))
'      g_userpath:String     0x00C6E9A8  (pushed straight into _bbStringConcat, so String;
'                                         globals_final.tsv calls it an Int and is wrong)
'  * Class-table slots: 0x00C6632C = TMyDate+0x30 Create(i,i,i), 0x00C6B274 =
'    TScreenMessage+0x40 ClearAll(i), 0x00C61CC0 = TScreen+0x94 DoMessage($,i,i).
'    TMyStream extends the BRL Type TStreamWrapper, so slot 0xA4 = SetStream(:TStream) and
'    the `_stream` field at +0x08 are both inherited; 0x8C is TMyStream's own ReadLine.
'
'  * `_bbStringContains`, NOT StartsWith.  0x004A6BF0 is the ONLY byte that ever diverged.
'    `extracted/decomp_annotated`'s symbol layer labels it `_bbStringStartsWith`, but
'    `extracted/runtime_helpers.tsv` names it `_bbStringContains` with 49 witnesses, and
'    that is the table the oracle masks with.  Written as `.StartsWith` the body is
'    972 bytes with a single unmasked E8 at +284; written as `.Contains` it is exact.
'    Recording this because the annotation layer is wrong here and will mislead again.
'
'  * The loop is `Repeat ... If f = "" Then Exit ... Forever`, NOT `Until f = ""`.
'    The original emits `cmp eax,0 / 75 02 / EB 05 / E9 <top>` -- the 9-byte early-return
'    shape of guide 6/10.9.  `Until f = ""` collapses that to a single 6-byte `0F 85 <top>`
'    and the body comes out 969 bytes.
'  * `TMyDate.Create(NextFieldInt(ln,"~t"), 1, 1)` is INLINE, not routed through a Local.
'    The original pushes `1, 1, ebx` with no `mov eax,ebx` in front; a
'    `Local yr:Int = NextFieldInt(...)` adds exactly that 2-byte copy (guide 16.5).
'    The retain/`inc [eax+4]` before and release/`bbGCFree` after each NextFieldInt/NextField
'    call is the `String Var` argument convention and is never written in source.
'  * `If st And st._stream` is the object truth test (setne/movzx) with the And's
'    short-circuit `cmp eax,0 / je`, not a `<> Null` comparison (guide 10.3).
'    `If ln.length` alone compares in memory (`cmp dword [eax+8],0`); inside the `And` the
'    same expression is materialised into eax first.  Both come from `.length`.
'  * BRL helpers by name: ReadDir/NextFile/CloseDir, ReadStream/CloseStream, FileType,
'    DeleteFile, RenameFile, Right.  0x005B6410 and 0x005B812B and 0x005B6425 are alias
'    sets (guide 10.8); NextFile / CloseStream / CloseDir are the members that fit.
'  * `""` here is 0x00C5D284, the bcc-pooled literal, at both sites; AddItem's two colour
'    arguments are 0x005C7D40 (the runtime's shared bbEmptyString) and so are `Null`.
'  * Literal CONTENT is not certified by the MATCH; all were read with harness.read_string,
'    including the 96-character archive password.
'!Global g_mm_tableload:TTable
'!Global g_userpath:String
	Function UpdateLoadTable()
		g_mm_tableload.ClearItems()
		Local dir:Int = ReadDir(g_userpath + "Save/")
		Local f:String
		Repeat
			f = NextFile(dir)
			If Right(f, 4) = ".sav"
				Local st:TMyStream = New TMyStream
				st.SetStream(ReadStream("zipe::" + g_userpath + "Save/" + f + "::newstarsoccerfivesavefile::3c422b4eb93f7e15d399b188f4b4c7278b99a9c5c71ec6428969c9aabd8eed0a"))
				Local d:String = ""
				If st And st._stream
					Local ln:String = st.ReadLine()
					If ln.length And ln.Contains("#VERSION:")
						ln = st.ReadLine()
					End If
					If ln.length
						d = TMyDate.Create(NextFieldInt(ln, "~t"), 1, 1).GetString("YYY-WWW")
						NextField(ln, "~t")
					End If
					CloseStream(st)
					g_mm_tableload.AddItem([f.Replace(".sav", ""), d], Null, Null)
				Else
					If FileType(g_userpath + "Save/" + f.Replace(".sav", ".bak")) = 1
						TScreenMessage.ClearAll(1)
						If TScreen.DoMessage(GetText("CMESSAGE_FILECORRUPTRESTORE").Replace("$filename", f), 1, 0)
							DeleteFile(g_userpath + "Save/" + f)
							RenameFile(g_userpath + "Save/" + f.Replace(".sav", ".bak"), g_userpath + "Save/" + f)
						End If
					Else
						TScreenMessage.ClearAll(1)
						If TScreen.DoMessage(GetText("CMESSAGE_FILECORRUPTDELETE").Replace("$filename", f), 1, 0)
							DeleteFile(g_userpath + "Save/" + f)
						End If
					End If
				End If
			End If
			If f = "" Then Exit
		Forever
		CloseDir(dir)
		If g_mm_tableload.CountItems()
			g_mm_tableload.SelectItemByRow(1)
		End If
	End Function
