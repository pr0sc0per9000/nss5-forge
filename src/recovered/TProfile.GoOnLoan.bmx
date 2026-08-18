' TProfile.GoOnLoan
' VA 0x0056cc81   391 bytes   vtable slot 0x140   sig (i)i   KIND=Method
' byte-identical vs NSS5.exe (391/391, original length from Ghidra's inventory)
'
' The physio/loan message String is built BEFORE Self.myclub is reassigned and then
' reassigned into the same register afterwards, so the source reuses one Local `msg`.
	Method GoOnLoan:Int(a0:Int)
		Self.transferlisted = 4
		Self.onloanfrom = Self.clubid
		Self.loanexpires = Self.date.sdate + 182
		If TMyDate.Create(Self.loanexpires, 1, 1).GetYear() > Self.date.GetYear()
			Self.loanexpires = TMyDate.Create(1, 52, Self.date.GetYear()).sdate
		EndIf
		If Self.loanexpires > Self.contractexpires
			Self.loanexpires = Self.contractexpires - 7
		EndIf
		Self.captain = 0
		Self.oldbossrel = Self.relationboss
		Self.oldteamrel = Self.relationteam
		Self.oldfansrel = Self.relationfans
		Self.relationboss = 75
		Self.relationteam = 50
		Self.relationfans = 50
		Local msg:String = GetText("CMESSAGE_LOANSTARTED").Replace("$clubname", Self.myclub.labelname)
		Self.clubid = a0
		Self.myclub = TClub.SelectById(a0)
		Self.CreateNewClubStats(Self.myclub.id)
		msg = msg.Replace("$loanclub", Self.myclub.labelname)
		TScreen.DoMessage(msg, 0, 0)
		TScreen_GameMenu.UpdateNavPanel()
	End Method
