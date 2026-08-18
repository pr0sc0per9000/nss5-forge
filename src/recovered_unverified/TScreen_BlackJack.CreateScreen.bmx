' TScreen_BlackJack.CreateScreen
' VA 0x00576333   1290 bytes   sig ()i   class-table slot 0x30   KIND=Function (static)
' NOT YET BYTE-VERIFIED. Reconstructed from extracted/decomp/TScreen_BlackJack.CreateScreen@00576333.c,
'
' REFINEMENT PASS (oracle score 4.8%, first-diff at byte 3): the prior version of this body
' wrote the dealer/player panel+label coordinates as flat literals (580, 135, 200, 30, 100,
' 590, 175, 180, 80, ...). That undershoots the original's own prologue -- `python
' scripts/disasm.py 0x00576333 400` shows `sub esp,0xC; push ebx; push esi; push edi`
' immediately after `push ebp; mov ebp,esp`, i.e. THREE callee-saved registers plus THREE
' spilled dword slots are live across the whole function, which flat literals never need.
' Walking that disassembly instruction-by-instruction (not just the decompile, which folds
' all of this to constants) shows the original declares four Int Locals right after
' `g_bj_screen.AddGadget(g_pan_stable)` -- `mov esi,0x244`/`mov ebx,0x87`/
' `mov [ebp-0xC],0xC8`/`mov edi,0x64`, i.e. `Local x=580`, `Local y=135`, `Local w=200`,
' `Local h=100`, in that declaration order -- and reuses them for BOTH the dealer and player
' panel/label pairs:
'   - x=esi, y=ebx: used for the panel's own x/y, then `x :+ 10` / `y :+ 40` (in that
'     order) before the matching label's x/y, then reset with a plain `x = 580` / `y = 335`
'     (not a fresh Local -- `mov esi,0x244` not `mov [new-slot],...`) before the player block.
'   - h=edi: passed BARE as CreatePanel's 12th ("i2") argument (both blocks, unchanged
'     value 100) and as `h - 20` for both labels' height (`mov eax,edi; sub eax,0x14`) --
'     confirmed by runtime SUBTRACTION instructions, which only happen if the source
'     computes an expression from a variable; a literal 80 would just be `push 0x50`.
'   - w=[ebp-0xC] (SPILLED to the stack, not a register): passed as CreatePanel's w
'     argument for pan_dealer (`push dword ptr [ebp-0xC]`) and as `w - 20` for BOTH labels'
'     width -- but for pan_player's own w argument the disassembly shows a bare immediate
'     `push 0xC8` (200), NOT `push dword ptr [ebp-0xC]`. Same value, different source
'     expression (literal `200` typed a second time instead of reusing `w`) -- an asymmetric
'     quirk of the original, reproduced as found, not tidied (same class of quirk the
'     byte-verified TScreen_Roulette.CreateScreen.bmx and TScreen_Casino.CreateScreen.bmx
'     headers document for their own x/y/w/h Locals). w is the one of the four that spills
'     to the stack because it has the FEWEST references (4, vs x/y's 8 and h's 5) -- the
'     exact same "lowest reference count spills" rule TScreen_Roulette.CreateScreen.bmx's
'     header documents for its own w Local, independently reproduced here.
' Everything from the navpanel CreatePanel onward (already literal-only in the original --
' no further x/y/w/h reuse anywhere past the two labels, confirmed by disassembly) was
' already correct against the decompile and is unchanged by this pass.
'
' Original header below is otherwise unchanged by this pass -- the call targets, globals,
' and argument shapes it documents (including the dealer/player labels' own globals) are
' all still accurate; only the x/y/w/h coordinate mechanics described above changed:
' cross-checked line-for-line against the already-byte-identical siblings
' TScreen_Slots.CreateScreen@00577e66.c (near-identical shape: image-cache guard, then
' TScreen.CreateScreen, then a run of CreatePanel/CreateButton calls) and
' TScreen_Roulette.CreateScreen / TScreen_Casino.CreateScreen for the CreatePanel/
' CreateButton/CreateLabel argument shapes. Staged in recovered_pending pending an oracle
' pass; not yet claimed byte-identical. Writing this revives the dead-Global dereference
' sites in TScreen_BlackJack.SetUpScreen, ButtonPlay, ButtonQuit, UpdateScoreLabels, Win,
' Tie, Lose and TBlackJack.Hold/Update, none of which ever had a constructor for the
' objects they read.
'
' Builds the "blackjack" screen: a cached background image, the dealer/player score
' panels+labels, the shared nav bar, the Quit button, the Hold/Hit action buttons and the
' Play/Bet button, all AddGadget'd onto the new TScreen.
'
' GHIDRA ARGUMENT-LIST CAVEAT (project-wide, see every annotated CreateScreen header):
' GetText is a single-String-argument call. Every place below where Ghidra prints
' `FUN_004c5549(<key>, <lots more literals...>)` immediately followed by a 2-argument
' CreatePanel/CreateButton call, the "lots more literals" are actually that following
' call's OWN x/y/w/h/color/.../scale/etc. arguments -- Ghidra just misattributes the
' pushes to the wrong callee. Confirmed against TPanel.CreatePanel's 13-arg and
' TButton.CreateButton's 15-arg signatures (vtable_map.tsv) at every site below; the two
' CLEAN (non-corrupted) calls -- the navpanel CreatePanel and the "btn_play" CreateButton
' -- print their own full argument lists with no adjacent GetText, and match those
' signatures directly with no re-shuffling needed.
'
' CALL TARGETS (class-table base + slot, cross-checked against extracted/class_tables.tsv
' and extracted/vtable_map.tsv so every PTR_FUN_00cXXXXX below is a proven slot, not a
' guess):
'   0x00C61C64 = TScreen+0x38        CreateScreen ($,:TImage,()i,()i):TScreen
'   0x00C63294 = TPanel+0x88         CreatePanel  ($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'   0x00C634C0 = TLabel+0x88         CreateLabel  ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'   0x00C623CC = TButton+0x88        CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'   TScreen slot 0x40 = AddGadget(:TGadget)i          (virtual, dispatched on the new TScreen)
'   TBlackJack class table = 0x00C6C2E8 (class_tables.tsv):
'     0x00C6C31C = +0x34 Update ()i        0x00C6C33C = +0x54 Draw ()i
'     0x00C6C328 = +0x40 Play ()i          0x00C6C338 = +0x50 Hold ()i
'   TScreen_BlackJack class table = 0x00C6C118 (class_tables.tsv):
'     0x00C6C150 = +0x38 ButtonPlay ()i    0x00C6C154 = +0x3C ButtonQuit ()i
'     (same-Type callback values written bare, matching the established house style --
'     see e.g. TScreen_EditMenu.CreateScreen.bmx's own header note and body.)
'   0x004BC372 = LoadImageChecked($,i):TImage (already-recovered module Function; its
'     2nd argument, -1, is one of the literals Ghidra folds into the guard block).
'   0x004C5549 = GetText($):String (module Function; see the argument-list caveat above).
'
' GLOBALS -- addresses are fact (read directly out of this function's own decompile);
' names are chosen by consulting python scripts/explain_global.py plus
' extracted/global_alias_map.tsv / global_alias_unified.tsv / global_alias_adjudicated.tsv,
' in that order of authority, with two documented departures below where the alias tables
' disagree with directly-observable evidence:
'
'   0x00C6C014 TImage  g_bj_imgBg      -- ZERO names resolved anywhere in the corpus for
'     this address (explain_global.py). First body to touch it; name chosen to match the
'     sibling convention (g_slots_imgBg @ TScreen_Slots.CreateScreen.bmx, g_roulette_imgBg
'     @ TScreen_Roulette.CreateScreen.bmx) -- same "cache the background once" guard shape,
'     same LoadImageChecked(g_datapath + "GameMedia/Images/Casino/<Game>/bg.png", -1) call.
'
'   0x00C6C018 TScreen g_bj_screen     -- construction site. Matches
'     TScreen_BlackJack.SetUpScreen.bmx's own use of the same name/address (STRONG,
'     unify_names.py; the competing name "g_object752" from ButtonPlay.bmx resolves to the
'     same address but SetUpScreen is the closer, same-purpose sibling).
'
'   0x00C6C01C/20/24/28 TButton g_object753/754/755/756 -- NOT g_bj_btn1..4. This function
'     is the construction site and settles, by direct unambiguous read of ITS OWN
'     decompile, which address is which button:
'       0x00C6C01C = Quit  (callback TScreen_BlackJack.ButtonQuit, name "btn_quit")
'       0x00C6C020 = Hold  (callback TBlackJack.Hold,               name "btn_hold")
'       0x00C6C024 = Hit   (callback TBlackJack.Play,                name "btn_hit")
'       0x00C6C028 = Play/Bet (callback TScreen_BlackJack.ButtonPlay, name "btn_play")
'     extracted/global_alias_adjudicated.tsv independently flags g_bj_btn1/2/3/4 as
'     UNSAFE: TScreen_BlackJack.SetUpScreen's own forced 6/6 identity disagrees with what
'     TBlackJack.Hold and TBlackJack.Update separately force for the same spellings (e.g.
'     SetUpScreen forces g_bj_btn2=0x00C6C028 while Hold forces g_bj_btn2=0x00C6C024), and
'     resolves ALL FOUR to the position-neutral g_objectNNN spelling instead -- which is
'     also exactly what the already-live TScreen_BlackJack.ButtonPlay.bmx uses, and its
'     Show()/Hide() calls on g_Object753/754/755/756 line up perfectly with the roles this
'     function's own construction proves (Play hides Quit+Play, shows Hold+Hit).
'
'   0x00C6C02C TLabel g_bjDealerLabel, 0x00C6C030 TLabel g_bjPlayerLabel -- STRONG,
'     unconflicted, and are exactly the two labels TScreen_BlackJack.UpdateScoreLabels.bmx
'     already calls .SetText() on (same names, same addresses).
'
'   0x00C6B858 TPanel g_casino_panel -- CERTAIN in both global_alias_unified.tsv and
'     global_alias_adjudicated.tsv (over the weaker single-body g_bj_panel / g_object729 /
'     g_gada / g_slot_panel). Confirmed against the actual writer,
'     TScreen_Casino.CreateScreen.bmx, which already assigns this exact name at this exact
'     address (`g_casino_panel = TPanel.CreatePanel("pan_stake", ...)`) -- this is the
'     shared casino stake panel, AddGadget'd last onto every casino sub-screen.
'
'   0x00C66768 TPanel g_pan_stable -- CERTAIN, 13 bodies, unconflicted.
'
'   0x00C6F194 TImage g_img_quit -- global_alias_adjudicated.tsv: canonical over
'     "g_iconBack" (the spelling TScreen_Kits/Roulette/Slots.CreateScreen use), which is
'     independently flagged AMBIGUOUS in global_address_map.tsv (used for 3 different
'     addresses across the corpus). This is the same icon those three back/quit buttons
'     use; "btn_quit" is in fact this button's own internal gadget name too.
'
'   0x00C6F274 TImage g_img_play -- the dominant, unconflicted spelling across 15 already
'     recovered CreateScreen bodies (TScreen_Roulette, TScreen_Kits, TScreen_Negotiate,
'     etc.), including two rows in global_alias_adjudicated.tsv that independently confirm
'     it as canonical. global_alias_overrides.tsv has one row proposing "g_object868"
'     instead (reasoning: "module body loads Tick.png into that slot"), but no recovered
'     body anywhere currently writes either name, and departing from the 15-body live
'     convention risks the opposite failure (this function's own icon reads would then be
'     the ONE dissenting body). Kept as g_img_play; flagged here for a future writer to
'     settle definitively.
'
'   0x00C6E950 String g_datapath -- global_alias_map.tsv/unified.tsv nominate
'     "g_mediaprefix" (from only 3 bodies' worth of evidence, one of which is
'     TBlackJack.SetUp.bmx itself), but "g_datapath" is STRONG in
'     global_address_map.tsv with 17/20 agreeing bodies and is the spelling roughly twenty
'     already-recovered, live files use for this exact address (TEngine.SetUp, TCard.SetUp,
'     TClub/TCompetition/TContinent/TNation.LoadData, TProfile.StartCareer, etc.). Using
'     "g_mediaprefix" here would silently read a Global nothing populates. Kept as
'     g_datapath; TBlackJack.SetUp.bmx's "g_mediaprefix" is a pre-existing, not-mine-to-fix
'     mismatch at the same address (same class of issue as g_screen_int21/22 below).
'
'   0x00C6EFDC Int g_screen_int21 (screen WIDTH), 0x00C6EFE0 Int g_screen_int22 (screen
'     HEIGHT) -- both global_alias_map.tsv and global_alias_unified.tsv converge on these
'     names regardless of which of the six raw spellings (g_screenwidth/g_screen_width/
'     g_screen_x resp. g_screenheight/g_screen_height/g_screen_y) a given body used, and
'     TScreen_EditMenu.CreateScreen.bmx (staged alongside this file in recovered_pending)
'     already uses g_screen_int21 at this same address for the same reason. Independently
'     confirmed against TScreen_Slots.CreateScreen@00577e66.c's identical navpanel call
'     (`DAT_00c6efe0 + -0x3c` supplies CreatePanel's y, `DAT_00c6efdc` supplies its w, and
'     TScreen_Kits.CreateScreen.bmx / TScreen_Pairs.CreateScreen.bmx / TScreen_Casino.
'     CreateScreen.bmx all reproduce that same y=height-role/w=width-role split for these
'     two addresses) -- i.e. EFDC is definitely the width-valued cell and EFE0 the
'     height-valued one, which is what fixes which of the two int21/int22 names goes where.
'
'!Global g_bj_imgBg:TImage
'!Global g_bj_screen:TScreen
'!Global g_object753:TButton
'!Global g_object754:TButton
'!Global g_object755:TButton
'!Global g_object756:TButton
'!Global g_bjDealerLabel:TLabel
'!Global g_bjPlayerLabel:TLabel
'!Global g_casino_panel:TPanel
'!Global g_pan_stable:TPanel
'!Global g_img_quit:TImage
'!Global g_img_play:TImage
'!Global g_datapath:String
'!Global g_screen_int21:Int
'!Global g_screen_int22:Int

If Not g_bj_imgBg
	g_bj_imgBg = LoadImageChecked(g_datapath + "GameMedia/Images/Casino/BlackJack/bg.png", -1)
EndIf
g_bj_screen = TScreen.CreateScreen("blackjack", g_bj_imgBg, TBlackJack.Draw, TBlackJack.Update)
g_bj_screen.AddGadget(g_pan_stable)
Local x:Int = 580
Local y:Int = 135
Local w:Int = 200
Local h:Int = 100
g_bj_screen.AddGadget(TPanel.CreatePanel("pan_dealer", GetText("blackjack_DealersHand"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, h, 0))
x :+ 10
y :+ 40
g_bjDealerLabel = TLabel.CreateLabel("lbl_dealer", "0", x, y, w - 20, h - 20, 3, "FFFFFF", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
g_bj_screen.AddGadget(g_bjDealerLabel)
x = 580
y = 335
g_bj_screen.AddGadget(TPanel.CreatePanel("pan_player", GetText("blackjack_PlayersHand"), x, y, 200, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, h, 0))
x :+ 10
y :+ 40
g_bjPlayerLabel = TLabel.CreateLabel("lbl_player", "0", x, y, w - 20, h - 20, 3, "FFFFFF", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
g_bj_screen.AddGadget(g_bjPlayerLabel)
g_bj_screen.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screen_int22 - 60, g_screen_int21, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
g_object753 = TButton.CreateButton("btn_quit", "", 10, g_screen_int22 - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_quit, ButtonQuit, 1.0, 1, GetText("tt_Back"))
g_object754 = TButton.CreateButton("btn_hold", GetText("blackjack_Hold"), 255, g_screen_int22 - 50, 140, 40, 1, 3, "FF0000", "FFFFFF", Null, TBlackJack.Hold, 1.0, 1, "")
g_object755 = TButton.CreateButton("btn_hit", GetText("blackjack_Hit"), 405, g_screen_int22 - 50, 140, 40, 1, 3, "00FF00", "FFFFFF", Null, TBlackJack.Play, 1.0, 1, "")
g_object756 = TButton.CreateButton("btn_play", "", g_screen_int21 - 130, g_screen_int22 - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, ButtonPlay, 1.0, 1, GetText("tt_Play"))
g_bj_screen.AddGadget(g_object753)
g_bj_screen.AddGadget(g_object754)
g_bj_screen.AddGadget(g_object755)
g_bj_screen.AddGadget(g_object756)
g_bj_screen.AddGadget(g_casino_panel)
Return 0
