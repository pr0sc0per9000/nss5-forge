' TScreen_Finances.CreateScreen
' VA 0x00557E42   1729 bytes   KIND=Function (static), SIG ()i, class-table slot 0x30
' byte-identical vs NSS5.exe (1729/1729, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=163, NSS5_NO_LEARN=1, no learned helpers -- naming is FULL. Verified twice for
' determinism.)
' ASSUMPTIONS -- module Globals (names ours except where already established by a sibling
' file; the ADDRESS and the TYPE are load-bearing, not the name)
'   0x00C68150 g_finances_screen:TScreen      (slot 0x40 = TScreen.AddGadget)
'   0x00C68154 g_pan_finances:TPanel   0x00C68158 g_pan_sponsors:TPanel
'   0x00C6815C g_pan_lifestyle:TPanel          (slot 0x74 = TGadget.AddChild, inherited)
'   0x00C68160 g_finances_summary_table:TTable   0x00C68164 g_finances_sponsors_table:TTable
'   0x00C68168 g_finances_table:TTable   -- names for these three, and for the two labels and
'     the progress bar below, are the SAME globals TScreen_Finances.SetUpScreen.bmx and
'     TScreen_Finances.ButtonSell.bmx already established; reused verbatim for consistency.
'   0x00C6816C g_finances_weeklybalance_label:TLabel
'   0x00C68170 g_finances_totalperyear_label:TLabel
'   0x00C68174 g_finances_lifestyle_bar:TProgressBar
'   0x00C66768 g_pan_stable:TPanel   0x00C667B0 g_pan_money:TPanel  -- shared "always present"
'     gadgets added to every screen; names established by TScreen_Achievements.CreateScreen.bmx.
'   0x00C6EFDC g_screenwidth:Int  -- established by TScreen_Achievements.CreateScreen.bmx.
'   0x00C6E91C g_col_highlight:String -- a shared "highlight colour" String Global; many
'     sibling CreateScreen/RefreshButtons files already use this exact name for this address.
' Class-table slots (vtable_map.tsv): 0x00C61C64 TScreen+0x38 CreateScreen; 0x00C63294
'   TPanel+0x88 CreatePanel; 0x00C62BAC TTable+0x88 CreateTable; TTable+0x90 AddColumn(i,$,$,
'   $,i)i; 0x00C634C0 TLabel+0x88 CreateLabel; 0x00C637A8 TProgressBar+0x88 CreateProgressBar;
'   0x00C623CC TButton+0x88 CreateButton. TGadget+0x74 AddChild(:TGadget)i (inherited by
'   TPanel). 0x005B95D0 (alias set incl. _brl_blitz_NullFunctionError/_brl_blitz_NullMethodError)
'   is the empty-function value bcc stores for an uninitialised ()i field -- source-level Null.
' Full raw disassembly read byte-for-byte with harness.disasm_original (Ghidra's merged C
'   printout is misleading here: every GetText(...) call in the decompilation shows extra
'   trailing "arguments" that are actually the FOLLOWING CreatePanel/CreateTable/AddColumn/
'   CreateButton call's own remaining pushes, not GetText's -- GetText truly takes one String
'   argument, confirmed both by the CALL-count annotation ("args=1", 1831 sites agree) and by
'   the raw push/call sequence, e.g. at 0x00557EFD only ONE dword is pushed before `call
'   0x004C5549` and `add esp,4` after).
' Three stack Locals, forced by the prologue (16.3: `sub esp,0xc` = 3 slots) plus three
'   callee-saved registers (ebx/esi/edi) used as CG temporaries, not by count of declared
'   Locals (section 18.1):
'     [ebp-8]  mov dword ptr [ebp-8],0xa      -> Local x:Int = 10   (REASSIGNED later, see below)
'     [ebp-4]  mov dword ptr [ebp-4],0x64     -> Local colw:Int = 100   (never reassigned;
'              read as a bare width AND, twice more, inside a width subtraction -- confirmed
'              by two separate `sub eax, dword ptr [ebp-4]` at each of the three tables'
'              first AddColumn call, i.e. bcc's no-CSE re-reads the same slot three times
'              per table for one column's width)
'     [ebp-0xc] mov dword ptr [ebp-0xc],eax   -> Local w:Int = g_screenwidth/2 - 15  (never
'              reassigned; reused as every panel's width AND inside the same subtraction above)
'   ebx is the running Y-cursor (register, never spilled): 70 -> +26 (table row) -> +(hgt-N)
'     (after the 3 AddColumns, before the label/progress-bar) -> +30 (after the label, before
'     the next panel) -- and is RESET to 70 for the third (Lifestyle) unit.
'   edi is `hgt`: the CreatePanel call's own 12th argument (179 / 220 / 420 for the three
'     panels) AND, unchanged, the amount added to the Y-cursor afterward (minus 20, 21, then
'     20 again -- the three units use two DIFFERENT literal subtrahends, confirmed byte-exact
'     from the raw `sub eax,0x14` / `sub eax,0x15` / `sub eax,0x14`, so this is written
'     verbatim per call, not via one shared constant).
'   [ebp-8] (`x`) is REASSIGNED once, right before the Lifestyle unit, from the literal 10 to
'     a freshly-recomputed `g_screenwidth/2 + 5` -- a second, independent halving of
'     g_screenwidth (bcc has no CSE: this is NOT the earlier `w` value reused, it is the same
'     source expression written again at a new point, confirmed by a second, separate
'     `sar eax,1` sequence at 0x00558298-0x005582AA reading g_screenwidth from memory again).
' Every string literal read from the exe with harness.read_string, not guessed: "finances",
'   "Finances", "pan_Finances", "tbl_Finances", "finances_In", "finances_Out",
'   "lbl_Finances", "Sponsors", "pan_Sponsors", "tbl_Sponsors", "Amount", "Expires",
'   "lbl_Sponsors", "Lifestyle", "pan_Lifestyle", "tbl_Lifestyle", "finances_Own",
'   "finances_Cost", "prg_Lifestyle", "finances_Sell", "btn_sell", "00FF00", "000000",
'   "888888", "EEEEEE", "FFFFFF".
' Float literals (all raw immediates, not masked): 0x3F800000=1.0, 0x3F4CCCCD=0.8.
'!Global g_finances_screen:TScreen
'!Global g_pan_finances:TPanel
'!Global g_pan_sponsors:TPanel
'!Global g_pan_lifestyle:TPanel
'!Global g_finances_summary_table:TTable
'!Global g_finances_sponsors_table:TTable
'!Global g_finances_table:TTable
'!Global g_finances_weeklybalance_label:TLabel
'!Global g_finances_totalperyear_label:TLabel
'!Global g_finances_lifestyle_bar:TProgressBar
'!Global g_pan_stable:TPanel
'!Global g_pan_money:TPanel
'!Global g_screenwidth:Int
'!Global g_col_highlight:String
' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function CreateScreen:Int()
		g_finances_screen = TScreen.CreateScreen("finances", Null, Null, Null)
		g_finances_screen.AddGadget(g_pan_stable)
		g_finances_screen.AddGadget(g_pan_money)
		Local x:Int = 10
		Local y:Int = 70
		Local w:Int = g_screenwidth / 2 - 15
		Local hgt:Int = 179
		Local colw:Int = 100
		g_pan_finances = TPanel.CreatePanel("pan_Finances", GetText("Finances"), x, y, w, 26, "FFFFFF", "FFFFFF", 3, 1.0, 1, hgt, 0)
		y :+ 26
		g_finances_summary_table = TTable.CreateTable("tbl_Finances", x, y, 7, 0, 0, 2, "00FF00", 1.0, 1, Null)
		y :+ hgt - 20
		g_finances_summary_table.AddColumn(w - colw - colw - 2, "", "000000", "FFFFFF", 2)
		g_finances_summary_table.AddColumn(colw, GetText("finances_In"), "000000", g_col_highlight, 1)
		g_finances_summary_table.AddColumn(colw, GetText("finances_Out"), "000000", "EEEEEE", 1)
		g_finances_weeklybalance_label = TLabel.CreateLabel("lbl_Finances", "", x, y, w, 20, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ 30
		g_finances_screen.AddGadget(g_pan_finances)
		g_pan_finances.AddChild(g_finances_summary_table)
		g_pan_finances.AddChild(g_finances_weeklybalance_label)
		hgt = 220
		g_pan_sponsors = TPanel.CreatePanel("pan_Sponsors", GetText("Sponsors"), x, y, w, 26, "FFFFFF", "FFFFFF", 3, 1.0, 1, hgt, 0)
		y :+ 26
		g_finances_sponsors_table = TTable.CreateTable("tbl_Sponsors", x, y, 9, 0, 0, 2, "00FF00", 1.0, 1, Null)
		y :+ hgt - 21
		g_finances_sponsors_table.AddColumn(w - colw - colw - 2, "", "000000", "FFFFFF", 2)
		g_finances_sponsors_table.AddColumn(colw, GetText("Amount"), "000000", g_col_highlight, 1)
		g_finances_sponsors_table.AddColumn(colw, GetText("Expires"), "000000", "EEEEEE", 1)
		g_finances_totalperyear_label = TLabel.CreateLabel("lbl_Sponsors", "", x, y, w, 21, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ 26
		g_finances_screen.AddGadget(g_pan_sponsors)
		g_pan_sponsors.AddChild(g_finances_sponsors_table)
		g_pan_sponsors.AddChild(g_finances_totalperyear_label)
		x = g_screenwidth / 2 + 5
		y = 70
		hgt = 420
		g_pan_lifestyle = TPanel.CreatePanel("pan_Lifestyle", GetText("Lifestyle"), x, y, w, 26, "FFFFFF", "FFFFFF", 3, 1.0, 1, hgt, 0)
		y :+ 26
		g_finances_table = TTable.CreateTable("tbl_Lifestyle", x, y, 19, 0, 1, 2, "00FF00", 1.0, 1, Null)
		y :+ hgt - 20
		g_finances_table.AddColumn(w - colw - colw - 2, "", "000000", "FFFFFF", 2)
		g_finances_table.AddColumn(colw, GetText("finances_Own"), "000000", g_col_highlight, 1)
		g_finances_table.AddColumn(colw, GetText("finances_Cost"), "000000", "EEEEEE", 1)
		g_finances_lifestyle_bar = TProgressBar.CreateProgressBar("prg_Lifestyle", "", x, y, w - 120, 36, 2, "888888", "00FF00", "FFFFFF", 0.8, 9, Null)
		g_finances_screen.AddGadget(g_pan_lifestyle)
		g_pan_lifestyle.AddChild(g_finances_table)
		g_pan_lifestyle.AddChild(g_finances_lifestyle_bar)
		g_pan_lifestyle.AddChild(TButton.CreateButton("btn_sell", GetText("finances_Sell").ToUpper(), x + w - 120, y, 120, 36, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonSell, 1.0, 8, ""))
	End Function
