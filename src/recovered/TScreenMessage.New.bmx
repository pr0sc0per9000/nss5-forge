' TScreenMessage.New
' VA 0x0056fd1e   214 bytes   vtable slot 0x10   sig ()i
' byte-identical vs NSS5.exe (214/214, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C6AFDC declared TList (globals_final.tsv says bare Object; the
'   CreateList factory plus the AddLast at slot 0x44 fix it).
'   Every field store Ghidra shows (x/y/message/starttime/delaytime/finishtime/delaystart/
'   alfa/bmfnt/img/imgScale/colour/lbl) is compiler default-init, not source -- the
'   DAT_005C7D44 and DAT_005C9C84 increments are the empty-string and Null refcounts.
'   Guard is `If Not x`, not `If x = Null`.
'!Global g_screenmessagelist:TList
	Method New()
		If Not g_screenmessagelist
			g_screenmessagelist = CreateList()
		End If
		g_screenmessagelist.AddLast(Self)
	End Method
