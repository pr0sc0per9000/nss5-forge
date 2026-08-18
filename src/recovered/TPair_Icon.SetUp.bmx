' TPair_Icon.SetUp
' VA 0x005799e3   590 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (STATIC method on TPair_Icon), SIG (i)i, class-table slot 0x34
' ASSUMPTIONS
'  * Module Globals -- NAMES ARE OURS, declared TYPES are load-bearing:
'      g_datapath:String    0x00C6E950  (prefixed to every asset path)
'      g_pairicons:TList    0x00C6C9E0  -- globals_final says bare Object.  It is a TList:
'          slot 0x8C = ObjectEnumerator drives two For-EachIn loops and slot 0x88 = Sort.
'      g_pair_icon_int:Int  0x00C6C9E4
'      g_pair_backs:TImage[]  0x00C6C9F0    g_pair_fronts:TImage[] 0x00C6C9FC
'          globals_final calls both Object[]; the elements are stored into TPair_Icon.back
'          and .front, which the object model types :TImage.
'  * `g_pairicons.Sort()` -- the original pushes 1 and 0x005B3516
'    (_brl_linkedlist_CompareObjects) explicitly.  Those are TList.Sort's DEFAULT arguments
'    (`Sort(ascending=True, compareFunc=CompareObjects)`), which bcc materialises at the
'    call site, so the source is the bare `.Sort()`.
'  * `Rand(99)` compiles to `push 1 / push 0x63`: BRL's Rand(min_value, max_value=1), the
'    default 1 supplied by bcc.  `Rand(0,4)` is written out in full.
'  * The Case chain is a Select, not If/ElseIf -- all six `cmp/je` targets sit past the LAST
'    compare (guide 10.2).  There is no Default; `nm` is initialised to "" before it.
'  * String literals read out of NSS5.exe: "Boss" "Team" "Fans" "Friends" "Girl"
'    "Sponsors" "GameMedia/Images/Casino/Pairs/" "_" ".png".
'  * LoadImageChecked's second argument is -1 (the flags word), matching
'    src/recovered_module/LoadImageChecked.bmx's ($ ,i) signature.
	Function SetUp:Int(a0:Int)
		'!Global g_datapath:String
		'!Global g_pairicons:TList
		'!Global g_pair_icon_int:Int
		'!Global g_pair_backs:TImage[]
		'!Global g_pair_fronts:TImage[]
		Local nm:String = ""
		Select a0
			Case 1
				nm = "Boss"
			Case 2
				nm = "Team"
			Case 3
				nm = "Fans"
			Case 4
				nm = "Friends"
			Case 5
				nm = "Girl"
			Case 6
				nm = "Sponsors"
		End Select
		For Local i:Int = 0 To 3
			g_pair_fronts[i] = LoadImageChecked(g_datapath + "GameMedia/Images/Casino/Pairs/" + nm + "_" + (i + 1) + ".png", -1)
		Next
		Local n:Int = 0
		For Local ic:TPair_Icon = EachIn g_pairicons
			ic.randno = Rand(99)
			ic.picked = 0
			ic.back = g_pair_backs[Rand(0, 4)]
			ic.front = g_pair_fronts[n]
			ic.imgId = n + 1
			n = n + 1
			If n > 3 Then n = 0
		Next
		g_pair_icon_int = 5
		g_pairicons.Sort()
		Local m:Int = 0
		For Local ic2:TPair_Icon = EachIn g_pairicons
			ic2.id = m
			m = m + 1
		Next
	End Function
