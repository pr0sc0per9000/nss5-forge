' TScreen_Relationships.CreateScreen
' VA 0x0053F6D0   3776 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
' Verified 3776/3776 (original length from Ghidra's inventory), reloc_masked=375, and
' re-verified MATCH under NSS5_NO_LEARN=1 (learned_helpers=None), so no call operand was
' masked by a name this body taught the helper table.
'
' ASSUMPTIONS
'   Module Globals: the ADDRESSES are fact, the NAMES are ours (module Globals have no debug
'   record). The declared TYPE is load-bearing -- it selects the vtable slot for every call
'   made through it.
'     0x00C66B80 g_screen_relationships:TScreen   <- TScreen.CreateScreen construction site
'     0x00C66B84 g_rel_imgBoss:TImage             <- LoadImageChecked construction site
'     0x00C66B88 g_rel_imgTeam:TImage             <- ditto
'     0x00C66B8C g_rel_imgFans:TImage             <- ditto
'     0x00C66B90 g_rel_imgFriends:TImage          <- ditto ("Relationships.png"; it is the
'                     FRIENDS button's icon, hence the name -- the file name is not the role)
'     0x00C66B94 g_rel_imgGirlfriend:TImage       <- ditto
'     0x00C66B98 g_rel_imgSponsors:TImage         <- ditto
'     0x00C66B9C g_rel_imgCasino:TImage           <- ditto (used by btn_TeamCasino)
'     0x00C66BA0 g_rel_imgStable:TImage           <- ditto (used by btn_FriendsRacing)
'     0x00C66BA4 g_rel_panRelations:TPanel        <- TPanel.CreatePanel construction site
'     0x00C66BA8/AC/B0/B4/B8/BC/C0 g_rel_prg{Boss,Team,Fans,Friends,Girlfriend,Sponsors,
'                     Happiness}:TProgressBar     <- CreateProgressBar construction sites
'     0x00C66BC4/C8/CC/D0/D4/D8/DC/E0/E4 g_rel_btn{Boss,Team,TeamCasino,Fans,Friends,
'                     FriendsRacing,Girlfriend,GirlfriendEnd,Sponsors}:TButton
'                                                 <- CreateButton construction sites
'     0x00C66768 g_pan_stable:TPanel   0x00C667B0 g_pan_money:TPanel
'                     Both are HUD panels built by OTHER screens and only re-added here; the
'                     names guess the role, the Type comes from their construction sites.
'                     (The same pair is named g_pan_stable/g_pan_money in
'                     TScreen_Abilities.CreateScreen and g_pan_money in TScreen_Stable.)
'     0x00C6F170 g_iconPath:String     the button-icon path prefix. globals_final.tsv calls
'                     it Int and is WRONG -- it is the left operand of _bbStringConcat eight
'                     times here. Same Global as TScreen_Abilities' g_mediapath.
'     0x00C6EFDC g_screenWidth:Int     bare dword read, no refcount traffic -> Int.
'     0x00C6F254 g_img_endRelationship:TImage   the icon for btn_GirlfriendEnd. This one is
'                     NOT loaded here (it belongs to another screen's asset block); it is
'                     only read, and it is passed in CreateButton's :TImage slot.
'
'   Class-table slots resolved through class_tables.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38       CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C63294 = TPanel+0x88        CreatePanel ($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C634C0 = TLabel+0x88        CreateLabel ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f)
'     0x00C637A8 = TProgressBar+0x88  CreateProgressBar ($,$,i,i,i,i,i,$,$,$,f,i,:TImage)
'     0x00C623CC = TButton+0x88       CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$)
'     0x00C638BC = THelpBox+0x30      Create (:TGadget,i,i,i,i,$,i,i):THelpBox
'     slot 0x40 on a TScreen = TScreen.AddGadget (:TGadget)i
'     slot 0x74 on a TPanel  = TGadget.AddChild (:TGadget)i   (inherited)
'     slot 0x44 on TScreen.lHelp (field +0x1c, :TList) = TList.AddLast (:Object)
'     0x00C66D08/0C/10/14 = TScreen_Relationships+0x38/0x3C/0x40/0x44 = ButtonRelationship /
'       ButtonGirlEnd / ButtonTeamCasino / ButtonFriendsRacing. Same Type -> bare names,
'       no `TScreen_Relationships.` prefix.
'
'   E8 targets: 0x004A7C20 _bbStringConcat, 0x004A8590 GC free (inlined BBRELEASE, never
'   written in source), 0x004BC372 LoadImageChecked, 0x004C5549 GetText. Both module
'   Functions are already recovered in src/recovered_module/.
'
'   String literals were all read out of NSS5.exe with harness.read_string. The oracle masks
'   a literal's ADDRESS, so their CONTENTS are NOT certified by the MATCH -- they are read,
'   not inferred. 0x00C5D680 = "FFFFFF", 0x00C6E904 = "00FF00". 0x00C5D284 and 0x005C7D40
'   are both zero-length BBStrings, i.e. ""; bcc picks a different empty-string constant per
'   argument slot and the source is "" either way (same unresolved detail noted in
'   TScreen_Stable.CreateScreen).
'
' SHAPE NOTES (each is byte-observable and was read off the disassembly)
'   * TScreen.CreateScreen runs BEFORE the asset guard, not after.
'   * The asset guard is the 21-byte `If Not g` form of section 10.3
'     (mov/cmp/setne/movzx/cmp/jne at 0x0053F714), not the 12-byte `If g = Null`.
'   * Seven Locals, in the original's initialisation order: y(70), bw(50), h(50), w(120),
'     wbar(300), tw, x. bcc puts y/tw/x... in ebx/esi and bw/h/w/wbar across [ebp-4..-0x10];
'     the allocation follows from the declaration order, so the order is load-bearing.
'   * `tw = w + wbar + bw * 2 + 40` emits `shl edx,1` -- it is a MULTIPLY. The Happiness
'     bar's width on the other hand is `wbar + bw + bw + 20`, two separate `add`s. The two
'     spellings are not interchangeable and both occur in this one function.
'   * `x = g_screenWidth / 2 - tw / 2` is two independent signed halvings
'     (cdq / and edx,1 / add / sar eax,1), left operand first. Not `(g_screenWidth - tw) / 2`.
'   * After the panel is created: `y :+ 40`, `x :+ 10`, and ONLY THEN AddGadget. That
'     ordering is in the bytes at 0x0053F9DF..0x0053F9F4.
'   * Column arithmetic is recomputed at every site because bcc does no CSE:
'     bar x = `x + w`; first button x = `x + w + wbar + 10`; second button x =
'     `x + w + wbar + bw + 20`. Written in the original's exact left-to-right add order.
'   * Per row the statement order is: AddChild(inline CreateLabel), create+assign the bar,
'     create+assign the button(s), AddChild each of them, then `y :+ h + 10`. The label is
'     added inline (its receiver is loaded into esi before the CreateLabel pushes); the bar
'     and buttons are added by re-reading their Globals.
'   * The last row (Happiness) has a wide bar and NO button, and no trailing `y :+`.
'   * The four THelpBoxes pass the button Globals directly -- unlike
'     TScreen_Abilities.CreateScreen, which looks its anchors up with GetGadgetByName.
'!Global g_screen_relationships:TScreen
'!Global g_rel_imgBoss:TImage
'!Global g_rel_imgTeam:TImage
'!Global g_rel_imgFans:TImage
'!Global g_rel_imgFriends:TImage
'!Global g_rel_imgGirlfriend:TImage
'!Global g_rel_imgSponsors:TImage
'!Global g_rel_imgCasino:TImage
'!Global g_rel_imgStable:TImage
'!Global g_rel_panRelations:TPanel
'!Global g_rel_prgBoss:TProgressBar
'!Global g_rel_prgTeam:TProgressBar
'!Global g_rel_prgFans:TProgressBar
'!Global g_rel_prgFriends:TProgressBar
'!Global g_rel_prgGirlfriend:TProgressBar
'!Global g_rel_prgSponsors:TProgressBar
'!Global g_rel_prgHappiness:TProgressBar
'!Global g_rel_btnBoss:TButton
'!Global g_rel_btnTeam:TButton
'!Global g_rel_btnTeamCasino:TButton
'!Global g_rel_btnFans:TButton
'!Global g_rel_btnFriends:TButton
'!Global g_rel_btnFriendsRacing:TButton
'!Global g_rel_btnGirlfriend:TButton
'!Global g_rel_btnGirlfriendEnd:TButton
'!Global g_rel_btnSponsors:TButton
'!Global g_pan_stable:TPanel
'!Global g_pan_money:TPanel
'!Global g_iconPath:String
'!Global g_screenWidth:Int
'!Global g_img_endRelationship:TImage
	Function CreateScreen()
		g_screen_relationships = TScreen.CreateScreen("relationships", Null, Null, Null)
		If Not g_rel_imgBoss
			g_rel_imgBoss = LoadImageChecked(g_iconPath + "Boss.png", -1)
			g_rel_imgTeam = LoadImageChecked(g_iconPath + "Team.png", -1)
			g_rel_imgFans = LoadImageChecked(g_iconPath + "Fans.png", -1)
			g_rel_imgFriends = LoadImageChecked(g_iconPath + "Relationships.png", -1)
			g_rel_imgGirlfriend = LoadImageChecked(g_iconPath + "Girlfriend.png", -1)
			g_rel_imgSponsors = LoadImageChecked(g_iconPath + "Sponsors.png", -1)
			g_rel_imgCasino = LoadImageChecked(g_iconPath + "Casino.png", -1)
			g_rel_imgStable = LoadImageChecked(g_iconPath + "Stable.png", -1)
		End If
		g_screen_relationships.AddGadget(g_pan_stable)
		g_screen_relationships.AddGadget(g_pan_money)
		Local y:Int = 70
		Local bw:Int = 50
		Local h:Int = 50
		Local w:Int = 120
		Local wbar:Int = 300
		Local tw:Int = w + wbar + bw * 2 + 40
		Local x:Int = g_screenWidth / 2 - tw / 2
		g_rel_panRelations = TPanel.CreatePanel("pan_relations", GetText("Relationships"), x, y, tw, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 0)
		y :+ 40
		x :+ 10
		g_screen_relationships.AddGadget(g_rel_panRelations)
		g_rel_panRelations.AddChild(TLabel.CreateLabel("lbl_Boss", GetText("Boss"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_rel_prgBoss = TProgressBar.CreateProgressBar("prg_Boss", "", x + w, y, wbar, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 5, Null)
		g_rel_btnBoss = TButton.CreateButton("btn_Boss", "", x + w + wbar + 10, y, bw, h, 1, 2, "FFFFFF", "FFFFFF", g_rel_imgBoss, ButtonRelationship, 1.0, 1, GetText("tt_RelationsBoss"))
		g_rel_panRelations.AddChild(g_rel_prgBoss)
		g_rel_panRelations.AddChild(g_rel_btnBoss)
		y :+ h + 10
		g_rel_panRelations.AddChild(TLabel.CreateLabel("lbl_Team", GetText("Team"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_rel_prgTeam = TProgressBar.CreateProgressBar("prg_Team", "", x + w, y, wbar, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 5, Null)
		g_rel_btnTeam = TButton.CreateButton("btn_Team", "", x + w + wbar + 10, y, bw, h, 1, 2, "FFFFFF", "FFFFFF", g_rel_imgTeam, ButtonRelationship, 1.0, 1, GetText("tt_RelationsTeam"))
		g_rel_btnTeamCasino = TButton.CreateButton("btn_TeamCasino", "", x + w + wbar + bw + 20, y, bw, h, 1, 2, "FFFFFF", "FFFFFF", g_rel_imgCasino, ButtonTeamCasino, 1.0, 1, GetText("tt_RelationsTeamCasino"))
		g_rel_panRelations.AddChild(g_rel_prgTeam)
		g_rel_panRelations.AddChild(g_rel_btnTeam)
		g_rel_panRelations.AddChild(g_rel_btnTeamCasino)
		y :+ h + 10
		g_rel_panRelations.AddChild(TLabel.CreateLabel("lbl_Fans", GetText("Fans"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_rel_prgFans = TProgressBar.CreateProgressBar("prg_Fans", "", x + w, y, wbar, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 5, Null)
		g_rel_btnFans = TButton.CreateButton("btn_Fans", "", x + w + wbar + 10, y, bw, h, 1, 2, "FFFFFF", "FFFFFF", g_rel_imgFans, ButtonRelationship, 1.0, 1, GetText("tt_RelationsFans"))
		g_rel_panRelations.AddChild(g_rel_prgFans)
		g_rel_panRelations.AddChild(g_rel_btnFans)
		y :+ h + 10
		g_rel_panRelations.AddChild(TLabel.CreateLabel("lbl_Friends", GetText("Friends"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_rel_prgFriends = TProgressBar.CreateProgressBar("prg_Friends", "", x + w, y, wbar, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 5, Null)
		g_rel_btnFriends = TButton.CreateButton("btn_Friends", "", x + w + wbar + 10, y, bw, h, 1, 2, "FFFFFF", "FFFFFF", g_rel_imgFriends, ButtonRelationship, 1.0, 1, GetText("tt_RelationsFriends"))
		g_rel_btnFriendsRacing = TButton.CreateButton("btn_FriendsRacing", "", x + w + wbar + bw + 20, y, bw, h, 1, 2, "FFFFFF", "FFFFFF", g_rel_imgStable, ButtonFriendsRacing, 1.0, 1, GetText("tt_RelationsFriendsRacing"))
		g_rel_panRelations.AddChild(g_rel_prgFriends)
		g_rel_panRelations.AddChild(g_rel_btnFriends)
		g_rel_panRelations.AddChild(g_rel_btnFriendsRacing)
		y :+ h + 10
		g_rel_panRelations.AddChild(TLabel.CreateLabel("lbl_Girlfriend", GetText("Girlfriend"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_rel_prgGirlfriend = TProgressBar.CreateProgressBar("prg_Girlfriend", "", x + w, y, wbar, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 5, Null)
		g_rel_btnGirlfriend = TButton.CreateButton("btn_Girlfriend", "", x + w + wbar + 10, y, bw, h, 1, 2, "FFFFFF", "FFFFFF", g_rel_imgGirlfriend, ButtonRelationship, 1.0, 1, GetText("tt_RelationsGirl"))
		g_rel_btnGirlfriendEnd = TButton.CreateButton("btn_GirlfriendEnd", "", x + w + wbar + bw + 20, y, bw, h, 1, 2, "FFFFFF", "FFFFFF", g_img_endRelationship, ButtonGirlEnd, 1.0, 1, GetText("tt_RelationsGirlEnd"))
		g_rel_panRelations.AddChild(g_rel_prgGirlfriend)
		g_rel_panRelations.AddChild(g_rel_btnGirlfriend)
		g_rel_panRelations.AddChild(g_rel_btnGirlfriendEnd)
		y :+ h + 10
		g_rel_panRelations.AddChild(TLabel.CreateLabel("lbl_Sponsors", GetText("Sponsors"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_rel_prgSponsors = TProgressBar.CreateProgressBar("prg_Sponsors", "", x + w, y, wbar, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 5, Null)
		g_rel_btnSponsors = TButton.CreateButton("btn_Sponsors", "", x + w + wbar + 10, y, bw, h, 1, 2, "FFFFFF", "FFFFFF", g_rel_imgSponsors, ButtonRelationship, 1.0, 1, GetText("tt_RelationsSponsors"))
		g_rel_panRelations.AddChild(g_rel_prgSponsors)
		g_rel_panRelations.AddChild(g_rel_btnSponsors)
		y :+ h + 10
		g_rel_panRelations.AddChild(TLabel.CreateLabel("lbl_Happiness", GetText("Happiness"), x, y, w, h, 3, "FFFFFF", "FFFFFF", 1.0, 4, 1, 0, 1, Null, 1, 0, 0, 0, "", 0))
		g_rel_prgHappiness = TProgressBar.CreateProgressBar("prg_Happiness", "", x + w, y, wbar + bw + bw + 20, h, 3, "FFFFFF", "00FF00", "FFFFFF", 0.8, 5, Null)
		g_rel_panRelations.AddChild(g_rel_prgHappiness)
		g_screen_relationships.lHelp.AddLast(THelpBox.Create(g_rel_btnBoss, 0, 0, 0, 0, GetText("CHELP_RELATIONSHIPBUTTONS"), 1, 2))
		g_screen_relationships.lHelp.AddLast(THelpBox.Create(g_rel_btnTeamCasino, 0, 0, 0, 0, GetText("CHELP_CASINOBUTTON"), 1, 2))
		g_screen_relationships.lHelp.AddLast(THelpBox.Create(g_rel_btnFriendsRacing, 0, 0, 0, 0, GetText("CHELP_STABLEBUTTON"), 1, 2))
		g_screen_relationships.lHelp.AddLast(THelpBox.Create(g_rel_btnGirlfriendEnd, 0, 0, 0, 0, GetText("CHELP_ENDRELATIONSHIP"), 1, 2))
	End Function
