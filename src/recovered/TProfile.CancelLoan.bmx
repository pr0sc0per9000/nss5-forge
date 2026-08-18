' TProfile.CancelLoan
' VA 0x0056ce08   227 bytes   vtable slot 0x144   sig ()i
' byte-identical vs NSS5.exe (227/227, original length from Ghidra's inventory)
' Slots: 0x00c59e0c = TClub+0x60 = SelectById; 0x00c61cc0 = TScreen+0x94 = DoMessage;
'        0x00c66918 = TScreen_GameMenu+0x3c = UpdateNavPanel
	Method CancelLoan:Int()
		Local msg:String = GetText("CMESSAGE_LOANENDED").Replace("$loanclub",Self.myclub.labelname)
		Self.clubid = Self.onloanfrom
		Self.myclub = TClub.SelectById(Self.onloanfrom)
		msg = msg.Replace("$clubname",Self.myclub.labelname)
		TScreen.DoMessage(msg,0,0)
		Self.onloanfrom = 0
		Self.loanexpires = 0
		Self.transferlisted = 0
		Self.relationboss = Self.oldbossrel
		Self.relationteam = Self.oldteamrel
		Self.relationfans = Self.oldfansrel
		TScreen_GameMenu.UpdateNavPanel()
	End Method
