/*	Documents\StarCraft II\Accounts\<numbers>\Variables.txt 
	The Account Folder has the Variables.txt file
	and Hotkeys folder


	Within Variables.txt file is a hotkeyprofile= key
	Values For standard (non-modfied SC2 profiles):

	hotkeyprofile=0_Default  		; Standard
	hotkeyprofile=1_NameRightSide	; Standard for Lefties
	hotkeyprofile=2_GridLeftSide	; Grid
	hotkeyprofile=3_GridRightSide	; Grid for Lefties
	hotkeyprofile=4_Classic			; Classic

	If using a user hotkey profiles, it will contain the active hotkey file which is stored in ..\Hotkeys folder
	eg
	hotkeyprofile=Good 				; using the good Hotkey profile


	Default=[nothing] (that would be the Normal Left Side)
	Suffix=_NRS = Normal Right Side (standard for lefties)
	Suffix=_GLS = Grid Left Side
	Suffix=_GRS = Grid Right Side (for lefties)
	Suffix=_SC1 = Classic

	Hotkey file eg Documents\StarCraft II\Accounts\<numbers>\Hotkeys\
	This is pretty much just an ini file containing the altered hotkeys
	
	-	Has a [Settings] section
		If based on grid profile will contian a 
		Grid=1 (this is missing in the other profiles)

	- A "Suffix=" line 
		indicating the standard hotkey profile the active settings are based on 
		(if there's no Suffix line then it's based on "Standard")

		_USDL ...not sure universal? This appears in the mpq extracted hotkeys


	obviously for grid layout commands (command card) 00-14 corresond to the keyboard letters

*/

; aSendKeys stores the keys which can be sent to SC to invoke abilities
; aAHKHotkeys stores AHK compatible hotkeys which can be used to create hotkeys for abilities e.g. when the user presses the select army hotkey

class SC2Keys
{
	static aSendKeys, aAHKHotkeys, aNonInterruptibleKeys, aHotkeySuffix := [], aStarCraftHotkeys := [], debug := [], aKeyReferences := []
	; Do not change any of the above object definitions! i.e. which ones are initialised to objects.
	; stores the keys for individual key lookup (aSendKeys)
	; sets the aAHKHotkeys object
	; sets aStarCraftHotkeys object
	; sets the references
	getAllKeys() 
	{
		this.aStarCraftHotkeys := [] ; set via the below functions
		this.aHotkeySuffix := [] ; clear it so that it may be repopulated on new calls
		this.getHotkeyProfile(file, suffix)
		if (suffix = "_GLS" || suffix = "_GRS")
			obj := this.readProfileGrid(file, suffix)
		else obj := this.readProfileNonGrid(file, suffix)
		this.aAHKHotkeys := []
		for hotkeyReference, sentKey in this.aSendKeys := obj	
			this.aAHKHotkeys[hotkeyReference] := this.convertSendKeysToAHKHotkey(sentKey)
		this.aNonInterruptibleKeys := this.getNonInterruptibleKeys()
		if !this.aKeyReferences.MaxIndex() ; haven't set the keys yet - these never change
		{
			for reference in this.aSendKeys 	
				this.aKeyReferences.Insert(reference)
		}
		return this.aSendKeys
	}
	; Returns an array containing all the hotkey references/IDs 
	getReferences()
	{
		; Could do an object check on aSendKeys, but sometimes that is blanked manually and since the references never change there is no need to call getAllKeys
		if !this.aKeyReferences.MaxIndex() 
			this.getAllKeys()
		return this.aKeyReferences	
	}
	; Returns an AHK compatible string which can be used with the send command
	key(hotkeyReference)
	{
		if !isobject(this.aSendKeys) ; haven't set the keys yet
			this.getAllKeys()
		return this.aSendKeys[hotkeyReference]
	}

	; To be used with getkeystate
	; Note Command card hotkeys are always 1 key/button, so this will always return the same as AHKHotkey()
	hotkeySuffix(hotkeyReference)
	{
		if !this.aHotkeySuffix.HasKey(hotkeyReference) ; aHotkeySuffix is cleared when getKeys is called
			this.aHotkeySuffix[hotkeyReference] := gethotkeySuffix(this.AHKHotkey(hotkeyReference))
		return this.aHotkeySuffix[hotkeyReference]
	}
	; Returns a string which can be used to create AHK hotkeys to monitor 
	; user input e.g. determine when an ability/action has been used
	AHKHotkey(hotkeyReference)
	{
		if !isobject(this.aSendKeys) ; haven't set the keys yet
			this.getAllKeys()
		return this.aAHKHotkeys[hotkeyReference]
	}
	; Returns the hotkey in the same format as the game (if secondary exists it is comma delimited) - i.e. for debugging/readability
	starCraftHotkey(hotkeyReference)	
	{
		if !isobject(this.aSendKeys) ; haven't set the keys yet
			this.getAllKeys()
		return this.aStarCraftHotkeys[hotkeyReference]		
	}
	checkNonInterruptibleKeys()
	{
		for i, key in this.aNonInterruptibleKeys
		{
			if GetKeyState(key, "P") ; In theory this should be logical state - but I use physical everywhere in code. P is safer
				return True 
		}
		return False
	}

	getHotkeyProfile(byRef file := "", byRef suffix := "")
	{
		file := suffix := ""
		accountFolder := getAccountFolder()
		variablesFilePath := accountFolder "Variables.txt"
		Loop, Read, %variablesFilePath%
		{
			if instr(A_LoopReadLine, "hotkeyprofile=")
				hotkeyProfile := SubStr(A_LoopReadLine, 15)
		} until hotkeyProfile != ""
		file := accountFolder "Hotkeys\" hotkeyProfile ".SC2Hotkeys"

		if hotkeyProfile in 0_Default,1_NameRightSide,2_GridLeftSide,3_GridRightSide,4_Classic
		{
			if !FileExist(file) ; Although extremely unlikely, you can save a hotkeyProfile with these names i.e. 0_Default.SC2Hotkeys
			{
				if (hotkeyProfile = "1_NameRightSide")
					suffix := "_NRS"
				else if (hotkeyProfile = "2_GridLeftSide")
					suffix := "_GLS"
				else if (hotkeyProfile = "3_GridRightSide")
					suffix := "_GRS"
				else if (hotkeyProfile = "4_Classic")
					suffix := "_SC1"
				else suffix := "Standard" ; 0_Default
			}
		}
		if !suffix
			IniRead, suffix, %file%, Settings, Suffix, Standard		

		; used by the debugging GUI and bug reporter
		this.debug.accountFolder := accountFolder
		this.debug.variablesFilePath := variablesFilePath
		this.debug.hotkeyProfile := file
		this.debug.hotkeySuffix := suffix

		if FileExist(variablesFilePath) && getTime()
		{
			settimer, _SC2KeysFileModificationCheck, 2000
			FileGetTime, modifiedTime, %variablesFilePath%
			this.debug.VariablesModifiedTime := modifiedTime
		}
		else settimer, _SC2KeysFileModificationCheck, Off
		return 
		
		; Monitor modification date and update keys. 
		; This changes every time 'accept' is pressed in the options menu, as well as 'accept' in the hotkey menu. (even if nothing changes)
		_SC2KeysFileModificationCheck:
		if !getTime()
			settimer, _SC2KeysFileModificationCheck, Off 
		else 
		{
			FileGetTime, modifiedTime, % SC2Keys.debug.variablesFilePath
			if SC2Keys.debug.VariablesModifiedTime != modifiedTime
			{
				; Some hotkeys rely on the SC hotkey layout, so we must disable them before updating the SC2 hotkeys
				disableAllHotkeys()
				SC2Keys.getAllKeys()
				CreateHotkeys()
			}
		}
		return
	}
	; sc ability/command-card hotkeys can only be 1 key
	getDefaultCommandKeys(suffix)
	{
		; Section and key columns are not used by grid layout! (except for the Cancel hotkey)***
		; The Cancel hotkey is quite interesting and unique.  All default layouts use Escape as a primary or secondary hotkey
		; Standard = Escape
		; _SC1 = Escape 
		; _NRS = F12,Escape 
		; _GLS  b,Escape
		; _GRS /,f12,Escape - 3 hotkeys!
		; It gets more interesting with gridlayouts 
		; The default grid layouts hotkeys are as stated above, however the in game hotkey menu only displays the primary hotkey, but the tooltip on the cancel button UI
		; displays all of them.
		; if you add a secondary hotkey to CommandButton14, or change the primary hotkey then escape no longer works or displayed in the tooltip!!!!!
		; All cancel command cards occur on CommandButton14, except for infestors who are using neural parasite.
		; There seems to be a SC hotkey/bug when the infestor casts neural parasite. With the _GLS grid layout pressing b causes the burrow icon to flash (if it's been researched) 
		; but the infestor ignores this, if burrow isn't researched the 'b' does nothing - in either case pressing b does not cancel the neural parasite - however pressing escape does.
		; After pressing escape, if the infestor was queued to burrow (from pressing 'b') it will burrow automatically.
		; Which is important as a couple of units have the command button located at 13 rather than position 14. This also makes sense from a playing perspective
		; If however you assign one or more custom hotkeys to CommandButton14 this does not effect that cancel hotkey (as its at CommandButton13), if you change CommandButton13
		; then that will alter the hotkeys.
		; In summary, if a user has change gridlayout keys for CommandButton13 then escape will not cancel the action (target reticle isn't present so should cause issues for me)
		; however if user changes one or both of CommandButton14 hotkeys then escape will not work to cancel targeting reticles
		static keys := "
		( LTrim c 					
			;myLookupReference					|Standard 			|_NRS 				|_SC1 				|grid							|section 				|key
			;									| all layouts share the escape key
			Cancel 								|Escape				|Escape				|Escape				|Cancel 						|Commands 				|Cancel
			ReturnCargo 						|c 					|c					|c 					|CommandButton06				|Commands 				|ReturnCargo
			SCV 								|s 					|j					|s 					|CommandButton00				|Commands 				|SCV		
			Marine/Barracks						|a 					|m					|m 					|CommandButton00				|Commands 				|Marine/Barracks
			Reaper/Barracks						|r 					|p					|e 					|CommandButton01				|Commands 				|Reaper/Barracks
			Marauder/Barracks		 			|d					|u					|f					|CommandButton02				|Commands 				|Marauder/Barracks
			Ghost/Barracks						|g  				|g					|g 					|CommandButton03				|Commands 				|Ghost/Barracks
			Hellion/Factory						|e 					|h					|v 					|CommandButton00				|Commands 				|Hellion/Factory
			WidowMine/Factory					|d 					|u					|d 					|CommandButton01				|Commands 				|WidowMine/Factory
			SiegeTank/Factory					|s 					|i					|t 					|CommandButton02				|Commands 				|SiegeTank/Factory
			HellionTank/Factory					|r 					|p					|h	 				|CommandButton03				|Commands 				|HellionTank/Factory
			Thor/Factory						|t 					|d					|g 					|CommandButton04				|Commands 				|Thor/Factory
			VikingFighter/Starport				|v	 				|k					|w 					|CommandButton00				|Commands 				|VikingFighter/Starport
			Medivac/Starport					|d 					|m					|d 					|CommandButton01				|Commands 				|Medivac/Starport
			Raven/Starport						|r 					|v					|v 					|CommandButton02				|Commands 				|Raven/Starport
			Banshee/Starport					|e 					|n					|e 					|CommandButton03				|Commands 				|Banshee/Starport
			Battlecruiser/Starport 				|b 					|b					|b 					|CommandButton04				|Commands 				|Battlecruiser/Starport
			Probe/Nexus 						|e 					|p 					|p 					|CommandButton00				|Commands 				|Probe/Nexus
			Zealot		  						|z 					|o					|z 					|CommandButton00				|Commands 				|Zealot 				; Gateway units lack the /structure
			Sentry 		  						|e 					|n					|e 					|CommandButton01				|Commands 				|Sentry 				; SC has a menu for both gateway & warpgate
			Stalker 	  						|s 					|l					|d 					|CommandButton02				|Commands 				|Stalker 				; But it doesn't seem like you can change them individually
			HighTemplar 						|t 					|h					|t 					|CommandButton05				|Commands 				|HighTemplar
			DarkTemplar 						|d 					|k					|k 					|CommandButton06				|Commands 				|DarkTemplar
			Phoenix/Stargate					|x 					|p					|e 					|CommandButton00				|Commands 				|Phoenix/Stargate
			Oracle/Stargate						|e 					|b					|l 					|CommandButton01				|Commands 				|Oracle/Stargate
			VoidRay/Stargate					|v 					|d					|o 					|CommandButton02				|Commands 				|VoidRay/Stargate
			Tempest/Stargate					|t 					|u					|t 					|CommandButton03				|Commands 				|Tempest/Stargate
			Carrier/Stargate					|c 					|i					|c 					|CommandButton04				|Commands 				|Carrier/Stargate
			Observer/RoboticsFacility			|b 					|o					|o 					|CommandButton00				|Commands 				|Observer/RoboticsFacility
			WarpPrism/RoboticsFacility			|a 					|p					|s 					|CommandButton01				|Commands 				|WarpPrism/RoboticsFacility
			Immortal/RoboticsFacility			|i 					|i					|i 					|CommandButton02				|Commands 				|Immortal/RoboticsFacility
			Colossus/RoboticsFacility			|c 					|l					|v 					|CommandButton03				|Commands 				|Colossus/RoboticsFacility
			Queen 								|q 					|u					|e 					|CommandButton01				|Commands 				|Queen 		; SC only allows same key for hatch/lair/hive
			UpgradeToWarpGate/Gateway 			|g 					|g					|g 					|CommandButton10				|Commands 				|UpgradeToWarpGate/Gateway 		
			; The key 'BunkerUnloadAll' is shared between bunkers, medivacs, warp prisms, and overlords.
			; **Note  the command button is 13 for medivacs, warp prisms, and overlords but 14 for bunkers! 
			; This would cause issues with grid layouts if I ever did anything with bunkers, would need a separate lookup reference for bunkers (with the correct command button)
			TransportUnloadAll					|d 					|d					|u 					|CommandButton13				|Commands 				|BunkerUnloadAll		
			QueenSpawnLarva						|v 					|l					|v 					|CommandButton11				|Commands 				|MorphMorphalisk/Queen		
			TimeWarp/Nexus						|c 					|n					|c 					|CommandButton10				|Commands 				|TimeWarp/Nexus			
		)"

		if suffix not in Standard,_NRS,_SC1,_GLS,_GRS
			suffix :=  "Standard" ; lets just try to use standard - should shrow and error somewhere to alert user
		obj := []
		arrayPos := suffix = "_NRS" ? 3 : suffix = "_SC1" ? 4 : suffix = "_GLS" || suffix = "_GRS" ? 5 : 2
		loop, parse, keys, `n, %A_Tab%
		{
			a := StrSplit(A_LoopField, "|", A_Tab A_Space)
			obj.insert(a.1, {"MyReference": a.1, "hotkey": a[arrayPos], "section": a[6], "inikey": a[7]})
		}
		return obj
	}

	readProfileHotkeysSection(file, suffix)
	{
		; Add all new hotkey section SC hotkeys here (excluding grid keys)
		; It seems Standard and _GLS are the same._SC1/classic seems to for these hotkeys but that wasn't necessarily the case with command hotkeys.
		; _NRS and _GRS seem to match too. 
		keys := "
		( LTrim c 					
			;myLookupReference				|Standard 					|_NRS  						|_SC1 					|_GLS (Grid)			|_GRS (Grid For Lefties)		|key
			TargetCancel 					|RightMouseButton			|RightMouseButton			|RightMouseButton		|RightMouseButton		|RightMouseButton 				|TargetCancel
			TargetChoose 					|LeftMouseButton			|LeftMouseButton			|LeftMouseButton		|LeftMouseButton		|LeftMouseButton 				|TargetChoose
			ChatDefault 					|Enter,Slash				|Tab,Slash					|Enter,Slash			|Enter,Slash			|Tab 							|ChatDefault
			SubgroupNext 					|Tab 						|BackSlash					|Tab					|Tab					|BackSlash						|SubgroupNext
			SubgroupPrev 					|Shift+Tab 					|Shift+BackSlash			|Shift+Tab				|Shift+Tab 				|Shift+BackSlash				|SubgroupPrev
			ArmySelect 	 					|F2 	 					|F5							|F2 					|F2 					|F5								|ArmySelect
			; SelectionCancelDrag has two default keys for _NRS F12,Escape! 
			SelectionCancelDrag 			|Escape						|F12						|Escape					|Escape					|F12							|SelectionCancelDrag								
			TownCamera 	 					|Backspace 					|BracketClose				|Backspace 				|Backspace				|BracketClose					|TownCamera
			AlertRecall	 					|Space 						|Space 						|Space  				|Space 					|Space 							|AlertRecall
			PauseGame 	 					|Pause 						|Pause						|Pause 					|Pause 					|Pause							|PauseGame
			CameraSave1 					|Control+F5 				|Control+F8 				|Control+F5 			|Control+F5 			|Control+F8 					|CameraSave0
			CameraSave2 					|Control+F6 				|Control+F9 				|Control+F6 			|Control+F6 			|Control+F9 					|CameraSave1
			CameraSave3 					|Control+F7 				|Control+F10				|Control+F7				|Control+F7 			|Control+F10					|CameraSave2
			CameraSave4 					|Control+F8 				|Control+F11				|Control+F8				|Control+F8 			|Control+F11					|CameraSave3
			CameraSave5 					|Control+Shift+F5 			|Control+Shift+F8 			|Control+Shift+F5 		|Control+Shift+F5		|Control+Shift+F8 				|CameraSave4
			CameraSave6 					|Control+Shift+F6 			|Control+Shift+F9 			|Control+Shift+F6		|Control+Shift+F6		|Control+Shift+F9 				|CameraSave5
			CameraSave7 					|Control+Shift+F7 			|Control+Shift+F10 			|Control+Shift+F7 		|Control+Shift+F7		|Control+Shift+F10				|CameraSave6
			CameraSave8 					|Control+Shift+F8 			|Control+Shift+F11			|Control+Shift+F8		|Control+Shift+F8		|Control+Shift+F11				|CameraSave7
			CameraView1 					|F5 						|F8	 						|F5						|F5 					|F8	 							|CameraView0
			CameraView2 					|F6 			 			|F9							|F6 					|F6 			 		|F9								|CameraView1
			CameraView3 					|F7 			 			|F10						|F7						|F7 			 		|F10							|CameraView2
			CameraView4 					|F8 			 			|F11						|F8 					|F8 			 		|F11							|CameraView3
			CameraView5 					|Shift+F5		 			|Shift+F8					|Shift+F5				|Shift+F5		 		|Shift+F8						|CameraView4
			CameraView6 					|Shift+F6		 			|Shift+F9					|Shift+F6				|Shift+F6		 		|Shift+F9						|CameraView5
			CameraView7 					|Shift+F7		 			|Shift+F10					|Shift+F7				|Shift+F7		 		|Shift+F10						|CameraView6
			CameraView8 					|Shift+F8		 			|Shift+F11					|Shift+F8				|Shift+F8		 		|Shift+F11						|CameraView7																																			
		)"

		aLookUp := []
		arrayPos := suffix = "_NRS" ? 3 : suffix = "_SC1" ? 4 : suffix = "_GLS" ? 5 : suffix = "_GRS" ? 6 : 2
		loop, parse, keys, `n, %A_Tab%
		{
			a := StrSplit(A_LoopField, "|", A_Tab A_Space)
			aLookUp.insert(a.1, {"MyReference": a.1,  "hotkey": a[arrayPos], "inikey": a[7]})
		}

		; Add the control group hotkeys
		if (suffix = "_NRS" || suffix = "_GRS")
			aControlGroupSuffix := [3, 4, 5, 6, 7, 8, 9, 0, "-", "="]
		else ; Standard and _GLS (grid for lefties) are the same
			aControlGroupSuffix := [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
		loop, 10
		{
			group := Mod(A_Index, 10) ; Group 10 has the inikey number 0
			MyReference := iniKey := "ControlGroupAssign" group
			defaultKey := "Control+" aControlGroupSuffix[A_index]
			aLookUp.insert(MyReference, {"MyReference": MyReference,  "hotkey": defaultKey, "inikey": iniKey})
			
			MyReference := iniKey := "ControlGroupRecall" group
			defaultKey := aControlGroupSuffix[A_index]
			aLookUp.insert(MyReference, {"MyReference": MyReference,  "hotkey": defaultKey, "inikey": iniKey})	
			
			MyReference := iniKey := "ControlGroupAppend" group
			defaultKey := "Shift+" aControlGroupSuffix[A_index]
			aLookUp.insert(MyReference, {"MyReference": MyReference,  "hotkey": defaultKey, "inikey": iniKey})						
		}


		obj := []
		fileExists := FileExist(file) ; This isn't required due to inireads default value, but there's little point if the file doesn't exist
		for myReference, item in aLookUp 
		{
			if fileExists
			{
				IniRead, hotkey, %file%, Hotkeys, % item.inikey, % item.hotkey
				obj[myReference] := this.convertHotkey(hotkey)
				this.aStarCraftHotkeys[myReference] := hotkey
			}
			else 
			{
				obj[myReference] := this.convertHotkey(item.hotkey)
				this.aStarCraftHotkeys[myReference] := item.hotkey
			}
		}
		return obj
	}
	
	readProfileNonGrid(file, suffix)
	{
		obj := this.getDefaultCommandKeys(suffix)
		if FileExist(file) ; This isn't required due to inireads default value, but theres little point if the file doesn't exist
		{
			for k, item in obj 
			{
				IniRead, hotkey, %file%, % item.section, % item.inikey, % item.hotkey
				obj[k].hotkey := hotkey
			}
		}
	 ; I need to think carefully about how this obj is constructed. But can always improve it after writing the auto production functions
	 ; Should most likely use a unitID or unitName lookup 
		for k, item in obj
		{
			this.aStarCraftHotkeys[k] := item.hotkey
			obj[k] := this.convertHotkey(item.hotkey)
		}
		return this.combineSimpleObjects(obj, this.readProfileHotkeysSection(file, suffix))
	}
	readProfileGrid(file, suffix)
	{
		obj := this.getDefaultCommandKeys(suffix)
		keys := suffix = "_GRS" ? "uiop[jkl;'nm,./" : "qwertasdfgzxcvp"
		aLookup := []
		loop, parse, keys
		{
			IniRead, key, %file%, Hotkeys, % "CommandButton" (id := (A_Index-1 < 10 ? "0" : "") A_Index-1), %A_LoopField%
			aLookup["CommandButton" id] := key	
		}

		; This ensures we use escape to cast cancel, unless user has changed one or more hotkeys for CommandButton14
		; Refer to other hotkey section for more details
		IniRead, key, %file%, Hotkeys, CommandButton14, Escape
		aLookup["Cancel"] := key ; The obj.Cancel.hotkey  = Cancel so it works below
		for i, item in obj 
		{
			this.aStarCraftHotkeys[i] := aLookup[item.hotkey]
			obj[i] := this.convertHotkey(aLookup[item.hotkey])
		}
		return this.combineSimpleObjects(obj, this.readProfileHotkeysSection(file, suffix))					
	}
	; No multiLevel objects!
	combineSimpleObjects(objects*)
	{
		nObj := []
		for i, obj in objects
		{
			for k, v in obj 
				nObj[k] := v
		}
		return nObj
	}
	; I forgot to include a way to map SC hotkeys to AHK hotkeys (not sent keys).
	; It's easiest just to convert the AHK send key string back to a hotkey and store it in another object rather than playing around with the way this class already works
	convertSendKeysToAHKHotkey(sendString)
	{
		RegExMatch(sendString, "i)\{(.+)}", suffix) ; gets the suffix if it's inside brackets
		hotkey := RegExReplace(sendString, "i)\{.+}") suffix1 ; gets the hotkey prefix if it has one. Leaves the suffix if its not inside brackets
		return hotkey
	}

	getNonInterruptibleKeys()
	{
		aSuffixes := []
		for i, reference in ["ChatDefault", "SubgroupNext", "SubgroupPrev", "TownCamera", "AlertRecall", "PauseGame"]
		{
			primary := this.convertHotkey(this.starCraftHotkey(reference), secondary := "")
			if (primary != "")
				suffsixList .= gethotkeySuffix(this.convertSendKeysToAHKHotkey(primary)) "|"
			if (secondary != "")
				suffsixList .= gethotkeySuffix(this.convertSendKeysToAHKHotkey(secondary)) "|"
		}
		suffsixList .= RTrim(suffsixList, "|")
		sort, suffsixList, D| U ; Remove duplicate suffixes
		loop, parse, suffsixList, |
		{
			if getKeyName(A_LoopField) != "" ; prevents inserting nulls and invalid keys (though this shouldn't occur)
				aSuffixes.insert(A_LoopField)
		}
		return aSuffixes
	}

	; Wrote this a few years ago, but lets roll with it
	; I really need to spend some time checking that it covers all cases correctly
	convertHotkey(SCHotkey, byRef secondaryHotkey := "")
	{
							;	"SC2Key": "AhkKey"
		static aTranslate := {	"PageUp": "PgUp"
							,	"PageDown": "PgDn"
							,	"NumPadMultiply": "NumpadMult"
							,  	"NumPadDivide": "NumpadDiv"
							,	"NumPadPlus": "NumpadAdd"				
							,	"NumPadMinus": "NumpadSub"

							, 	"Grave": "``" ;note needs escape character!
							, 	"Minus": "-"
							, 	"Equals": "="
							, 	"BracketOpen": "["
							, 	"BracketClose": "]"
							,	"BackSlash": "\"						
							, 	"SemiColon": ";"
							, 	"Apostrophe": "'"
							, 	"Comma": ","
							, 	"Period": "."
							,	"Slash": "/"

							, 	"LeftMouseButton": "LButton"
							, 	"RightMouseButton": "RButton"
							,	"MiddleMouseButton": "MButton"
							, 	"ForwardMouseButton": "XButton1"
							, 	"BackMouseButton": "XButton2" }
							; apparently nothing can be bound to the wheel (i thought you COULD do that in sc2....)

		; NumpadDel maps to real delete key, same for NumpadIns, Home, End and num-UP,Down,Left,Right, and Num-PageUp/Down and enter
		; {NumpadClear} (num5 with numlock off) doesnt map to anything
		; nothing can be mapped to windows keys or app keys
		secondaryHotkey := "" ; ensure it's blanked in case the variable already contains data
		; when two hotkeys are present "hotkey,alternateHokey" - note SC stores literal , keys as comma so this is safe 
		loop, parse, SCHotkey, `,
		{
			String := A_LoopField
			if (string = "") ; could break sd there will be no second key if the first one is blank
				continue
			; Easier to use string replace here and have the modifiers separate and outside of the
			; aTranslate associative array. As AHK Associative arrays are indexed alphabetically (not in order in which keys were added)
			; so this would result in modifier strings being incorrectly converted
			; SC2 Hotkeys are done in this Order Control+Alt+Shift+Keyname
			StringReplace, String, String, Control+, ^, All ;use modifier+ so if user actually has something bound to it wont cause issue
			StringReplace, String, String, Alt+, !, All 
			StringReplace, String, String, Shift+, +, All 	;this will also act to remove SC2's joining '+'

			; string replace accounts for differences between AHK send Syntax and SC2 hotkey storage

			for SC2Key, AhkKey in aTranslate
				StringReplace, String, String, %SC2Key%, %AhkKey%, All 

			; I don't think this is required as you can't bind those characters
			; At least, they're not written to the hotkey file like that
			;if String in !,#,+,^,{,} ; string must be 1 character length to match
			;	return "{" String "}"

			aModifiers := ["+", "^", "!"]
			;lets remove the modifiers so can see command length
			for index, modifier in aModifiers
			{
				if inStr(string, modifier)
				{
					StringReplace, String, String, %modifier%,, All
					StringModifiers .= modifier
				}
			}
			; lets correct for any difference in the command names
			; CapsLock ScrollLock NumLock
			; cant bind anything to windows key or appskey in game

			if (StrLen(string) > 1)
				string := StringModifiers "{" string "}" ; as AHK commands > 1 are enclosed in brackets
			else string := StringModifiers string

			if (string = "+=") 		; AHK cant send this correctly != and +- work fine
				string := "+{=}" 	; +!= works fine too as does !+= and ^+=

			; lower-case, if want to use with AHKs sendinput a 'H' is equivalent to '+H'
			StringLower, string, string
			if A_Index = 1
				primaryHotkey := string
			else secondaryHotkey := string

		}
		return primaryHotkey
	}

}
/*
Preset Type: None
No Custom Keybinds Found

*** Keybinds ***
Move: None
MoveHoldPosition: None
Attack: None
Stop: None
Patrol: None
Lift: None
Land: None
CalldownMULE/OrbitalCommand: None
ReturnCargo: None
Snipe/Ghost: None
SiegeMode: None
Unsiege: None
AutoTurret/Raven: None
HunterSeekerMissile/Raven: None
TimeWarp/Nexus: None
Blink/Stalker: None
GravitonBeam/Phoenix: None
InfestedTerrans/Infestor: None
MorphMorphalisk/Queen: None
BurrowDown: None
BurrowUp: None
WidowMineBurrow/WidowMine: None
WidowMineUnburrow/WidowMine: None
Larva: None
Cancel: None
ArmySelect: None
SCV: None
Marine/Barracks: None
Marauder/Barracks: None
Reaper/Barracks: None
Ghost/Barracks: None
Hellion/Factory: None
HellionTank/Factory: None
WidowMine/Factory: None
SiegeTank/Factory: None
Thor/Factory: None
VikingFighter/Starport: None
Medivac/Starport: None
Raven/Starport: None
Banshee/Starport: None
Battlecruiser/Starport: None
Probe/Nexus: None
Zealot: None
Sentry: None
Stalker: None
HighTemplar: None
DarkTemplar: None
Observer/RoboticsFacility: None
WarpPrism: None
Immortal/RoboticsFacility: None
Colossus/RoboticsFacility: None
Phoenix/Stargate: None
Oracle/Stargate: None
VoidRay/Stargate: None
Tempest/Stargate: None
Carrier/Stargate: None
MothershipCore/Nexus: None
Queen: None
Drone/Larva: None
Overlord/Larva: None
Zergling/Larva: None
Roach/Larva: None
Hydralisk/Larva: None
Infestor/Larva: None
Mutalisk/Larva: None
Corruptor/Larva: None
Ultralisk/Larva: None
SwarmHostMP/Larva: None
Viper/Larva: None
TerranInfantryWeaponsLevel1/EngineeringBay: None
TerranInfantryArmorLevel1/EngineeringBay: None
TerranShipWeaponsLevel1/Armory: None
TerranShipPlatingLevel1: None
TerranVehicleWeaponsLevel1: None
TerranVehiclePlatingLevel1: None
: None
: None
SubgroupNext: None
SubgroupPrev: None
CameraSave0: None
CameraSave1: None
CameraSave2: None
CameraSave3: None
CameraSave4: None
CameraSave5: None
CameraSave6: None
CameraSave7: None
CameraView0: None
CameraView1: None
CameraView2: None
CameraView3: None
CameraView4: None
CameraView5: None
CameraView6: None
CameraView7: None
ControlGroupAssign0: None
ControlGroupAssign1: None
ControlGroupAssign2: None
ControlGroupAssign3: None
ControlGroupAssign4: None
ControlGroupAssign5: None
ControlGroupAssign6: None
ControlGroupAssign7: None
ControlGroupAssign8: None
ControlGroupAssign9: None
ControlGroupRecall0: None
ControlGroupRecall1: None
ControlGroupRecall2: None
ControlGroupRecall3: None
ControlGroupRecall4: None
ControlGroupRecall5: None
ControlGroupRecall6: None
ControlGroupRecall7: None
ControlGroupRecall8: None
ControlGroupRecall9: None
ControlGroupAppend0: None
ControlGroupAppend1: None
ControlGroupAppend2: None
ControlGroupAppend3: None
ControlGroupAppend4: None
ControlGroupAppend5: None
ControlGroupAppend6: None
ControlGroupAppend7: None
ControlGroupAppend8: None
ControlGroupAppend9: None