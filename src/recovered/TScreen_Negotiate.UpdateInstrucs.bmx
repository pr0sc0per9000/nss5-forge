' TScreen_Negotiate.UpdateInstrucs
' VA 0x0057abd4   261 bytes   vtable slot 0x4c   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (261/261, original length from Ghidra's inventory)
'
' GLOBAL NAMES ARE OURS; the DECLARED TYPES are load-bearing (they pick the vtable slot).
' Arg counts were read off the stack, not off Ghidra: Ghidra prints _bbStringFromInt with
' 6 arguments here because bcc pushes the OUTER call's arguments before evaluating the
' inner one. `add esp,4` after each call is what fixes the real arity.
' g_neg_offer is a TContractOffer: [g+8] is .club and [club+0x1c] is TBase_Team.labelname.
'!Global g_neg_lbl1:TLabel
'!Global g_neg_lbl2:TLabel
'!Global g_neg_btn:TButton
'!Global g_neg_offer:TContractOffer
'!Global g_neg_step:Int
	Function UpdateInstrucs:Int()
		Local p:Int = (g_neg_step - 1) * 10
		If p < 0 Or p > 40 Then p = 0
		g_neg_lbl1.SetText(GetText("CMESSAGE_CONTRACTINCREASE").Replace("$percent", String(p)).Replace("$clubname", g_neg_offer.club.labelname), "", -1, -1)
		g_neg_lbl2.SetText(String(p) + "%", "", -1, -1)
		g_neg_btn.SetText(GetText("highlow_EndNegotiations").Replace("$percent", String(p)), "", -1, -1)
	End Function
