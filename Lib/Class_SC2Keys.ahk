class SC2Keys
{
	static aCurrentHotkeys, debug := []
	getAllKeys() ; stores the keys as well for individual key lookup
	{
		this.getHotkeyProfile(file, suffix)
		if (suffix = "_GLS" || suffix = "_GRS")
			obj := this.readProfileGrid(file, suffix)
		else obj := this.readProfileNonGrid(file, suffix)	
		return this.aCurrentHotkeys := obj
	}
	key(hotkeyReference)
	{
		if !isobject(this.aCurrentHotkeys) ; haven't set the keys yet
			this.getAllKeys()
		return this.aCurrentHotkeys[hotkeyReference]
	}
	getHotkeyProfile(byRef file, byRef suffix)
	{
		file := suffix := ""
		accountFolder := getAccountFolder()
		variablesFilePath := accountFolder "Variables.txt"
		Loop, Read, %variablesFilePath%
		{
			if instr(A_LoopReadLine, "hotkeyprofile=")
				hotkeyProfile := SubStr(A_LoopReadLine, 15)
		} until hotkeyProfile
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

		; used by the debugging GUI
		this.debug.accountFolder := accountFolder
		this.debug.variablesFilePath := variablesFilePath
		this.debug.hotkeyProfile := file
		this.debug.hotkeySuffix := suffix
		return 
	}
	getDefaultKeys(suffix)
	{
		; Section and key columns are not used by grid layout!
		; column 1 isnt used either currently
		static keys := "
			( LTrim c 					;			Standard 			_NRS 				_SC1 				grid							section 				key & myLookupReference
				trainMarine 						|a 					|m					|m 					|CommandButton00				|Commands 				|Marine/Barracks
				trainReaper 						|r 					|p					|e 					|CommandButton01				|Commands 				|Reaper/Barracks
				trainMarauder			 			|d					|u					|f					|CommandButton02				|Commands 				|Marauder/Barracks
				trainGhost 							|g  				|g					|g 					|CommandButton03				|Commands 				|Ghost/Barracks
				trainHellion 						|e 					|h					|v 					|CommandButton00				|Commands 				|Hellion/Factory
				trainWidowMine 						|d 					|u					|d 					|CommandButton01				|Commands 				|WidowMine/Factory
				trainSiegeTank 						|s 					|i					|t 					|CommandButton02				|Commands 				|SiegeTank/Factory
				trainHellionTank 					|r 					|p					|h	 				|CommandButton03				|Commands 				|HellionTank/Factory
				trainThor 							|t 					|d					|g 					|CommandButton04				|Commands 				|Thor/Factory
				trainVikingFighter 					|v	 				|k					|w 					|CommandButton00				|Commands 				|VikingFighter/Starport
				trainMedivac 						|d 					|m					|d 					|CommandButton01				|Commands 				|Medivac/Starport
				trainRaven 							|r 					|v					|v 					|CommandButton02				|Commands 				|Raven/Starport
				trainBanshee 						|e 					|n					|e 					|CommandButton03				|Commands 				|Banshee/Starport
				trainBattlecruiser  				|b 					|b					|b 					|CommandButton04				|Commands 				|Battlecruiser/Starport
				trainZealot  						|z 					|o					|z 					|CommandButton00				|Commands 				|Zealot 				; Gateway units lack the /structure
				trainSentry  						|e 					|n					|e 					|CommandButton01				|Commands 				|Sentry 				; SC has a menu for both gateway & warpgate
				trainStalker  						|s 					|l					|d 					|CommandButton02				|Commands 				|Stalker 				; But it doesn't seem like you can change them individually
				trainHighTemplar					|t 					|h					|t 					|CommandButton05				|Commands 				|HighTemplar
				trainDarkTemplar					|d 					|k					|k 					|CommandButton06				|Commands 				|DarkTemplar
				trainPhoenix						|x 					|p					|e 					|CommandButton00				|Commands 				|Phoenix/Stargate
				trainOracle 						|e 					|b					|l 					|CommandButton01				|Commands 				|Oracle/Stargate
				trainVoidRay 						|v 					|d					|o 					|CommandButton02				|Commands 				|VoidRay/Stargate
				trainTempest 						|t 					|u					|t 					|CommandButton03				|Commands 				|Tempest/Stargate
				trainCarrier						|c 					|i					|c 					|CommandButton04				|Commands 				|Carrier/Stargate
				trainObserver						|b 					|o					|o 					|CommandButton00				|Commands 				|Observer/RoboticsFacility
				trainWarpPrism						|a 					|p					|s 					|CommandButton01				|Commands 				|WarpPrism/RoboticsFacility
				trainImmortal						|i 					|i					|i 					|CommandButton02				|Commands 				|Immortal/RoboticsFacility
				trainColossus						|c 					|l					|v 					|CommandButton03				|Commands 				|Colossus/RoboticsFacility
				trainQueen							|q 					|u					|e 					|CommandButton01				|Commands 				|Queen 		; SC only allows same key for hatch/lair/hive
			)"

		if suffix not in Standard,_NRS,_SC1,_GLS,_GRS
			suffix :=  "Standard" ; lets just try to use standard - should shrow and error somewhere to alert user
		obj := []
		arrayPos := suffix = "_NRS" ? 3 : suffix = "_SC1" ? 4 : suffix = "_GLS" || suffix = "_GRS" ? 5 : 2
		loop, parse, keys, `n, %A_Tab%
		{
			a := StrSplit(A_LoopField, "|", A_Tab A_Space)
			obj.insert(a.7, {"hotkey": a[arrayPos], "section": a[6], "key": a[7]})
		}
		return obj
	}

	readProfileHotkeysSection(file)
	{
		obj := []
		; Add all new hotkey section SC hotkeys here (excluding grid keys)
		obj.SubgroupNext := "Tab"
		obj.SubgroupPrev := "Shift+Tab"
		loop, 10 ; Set default control group keys
		{
			group := A_Index - 1
			obj["ControlGroupRecall" group] := group
			obj["ControlGroupAppend" group] := "Shift+" group
			obj["ControlGroupAssign" group] := "Control+" group		
		}
		if FileExist(file) ; This isn't required due to inireads default value, but theres little point if the file doesn't exist
		{
			for k, value in obj 
			{
				IniRead, hotkey, %file%,  Hotkeys, %k%, %value%
				obj[k] := hotkey
			}
		}
		for k, hotkey in obj
			obj[k] := this.convertHotkey(hotkey)
		return obj
	}
	
	readProfileNonGrid(file, suffix)
	{
		obj := this.getDefaultKeys(suffix)
		if FileExist(file) ; This isn't required due to inireads default value, but theres little point if the file doesn't exist
		{
			for k, item in obj 
			{
				IniRead, hotkey, %file%, % item.section, % item.key, % item.hotkey
				obj[k].hotkey := hotkey
			}
		}
	 ; I need to think carefully about how this obj is constructed. But can always improve it after writing the auto production functions
	 ; Should most likely use a unitID or unitName lookup 
		for k, item in obj
			obj[k] := this.convertHotkey(item.hotkey)
		return this.combineSimpleObjects(obj, this.readProfileHotkeysSection(file))
	}
	readProfileGrid(file, suffix)
	{
		
		obj := this.getDefaultKeys(suffix)
		keys := suffix = "_GRS" ? "uiop[jkl;'nm,./" : "qwertasdfgzxcvp"
		aLookup := []
		loop, parse, keys
		{
			IniRead, key, %file%, Hotkeys, % "CommandButton" (id := (A_Index-1 < 10 ? "0" : "") A_Index-1), %A_LoopField%
			aLookup["CommandButton" id] := key	
		}
		for i, item in obj 
			obj[i] := this.convertHotkey(aLookup[item.hotkey])
		return this.combineSimpleObjects(obj, this.readProfileHotkeysSection(file))					
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
	; Wrote this over a year ago, but lets roll with it
	; I really need to spend some time checking that it covers all cases correctly
	convertHotkey(String)
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

	; when two hotkeys are present "hotkey,alternateHokey" - note SC stores literal , keys as comma so this is safe 
	if p := instr(String, ",")
		String := SubStr(String, 1, p-1)

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
		for index, modifier in 	aModifiers
			if inStr(string, modifier)
			{
				StringReplace, String, String, %modifier%,, All
				StringModifiers .= modifier
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
		return string
	}

}
