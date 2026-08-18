' TScreen_Stats.ButtonMyStats
' VA 0x0055224e   42 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (42/42, original length from Ghidra's inventory, mode=reloc)
' assumptions: module Globals at 0x00c679b0 and 0x00c679bc are both :TPanel
'              (globals_final.tsv, typed from their construction site);
'              TPanel slot 0x54 = TGadget.Hide (inherited), slot 0x58 = TGadget.Show (inherited)
	Function ButtonMyStats:Int()
		'!Global g_pan_a:TPanel
		'!Global g_pan_b:TPanel
		g_pan_a.Hide()
		g_pan_b.Show()
	End Function
