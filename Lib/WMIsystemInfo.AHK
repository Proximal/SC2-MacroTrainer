; These functions return an object or a string containing associated properties
; There can be more than 1 item in the object e.g. ram-sticks/dual-CPU, so check ItemCount if using retrieving an object
; WMISystemInfo_Summary() returns a string with basic system information
; WMISystemInfo_Retrieve() can be called directly if you know the WQLQuery and propertyList. The property list must be pipe delimited.

WMISystemInfo_OperatingSystem(object := True, byRef itemCount := "")
{
	return WMISystemInfo_Retrieve("Win32_OperatingSystem", object, itemCount)
}
;http://msdn.microsoft.com/en-us/library/aa394347%28v=vs.85%29.aspx
WMISystemInfo_Ram(object := True, byRef itemCount := "")
{
	return WMISystemInfo_Retrieve("Win32_PhysicalMemory", object, itemCount)
}
;http://msdn.microsoft.com/en-us/library/aa394072%28v=vs.85%29.aspx
WMISystemInfo_Motherboard(object := True, byRef itemCount := "")
{
	return WMISystemInfo_Retrieve("Win32_BaseBoard", object, itemCount)
}
;http://msdn.microsoft.com/en-us/library/aa394373%28v=vs.85%29.aspx
WMISystemInfo_CPU(object := True, byRef itemCount := "")
{
	return WMISystemInfo_Retrieve("Win32_Processor", object, itemCount)
}
;http://msdn.microsoft.com/en-us/library/aa394373%28v=vs.85%29.aspx
WMISystemInfo_VideoCard(object := True, byRef itemCount := "")
{
	return WMISystemInfo_Retrieve("Win32_VideoController", object, itemCount)
}
WMISystemInfo_Summary()
{
	aQuery := {	"1Win32_OperatingSystem": "BuildNumber|Caption|CountryCode|CSDVersion|Locale|MaxProcessMemorySize|OSLanguage|"
										. "OSType|ServicePackMajorVersion|ServicePackMinorVersion|Version|TotalVisibleMemorySize|TotalVirtualMemorySize|SystemDrive|WindowsDirectory"
			, 	"2Win32_Processor": "CurrentClockSpeed|MaxClockSpeed|Name|NumberOfCores|NumberOfLogicalProcessors"
			,	"3Win32_PhysicalMemory": "Capacity|Manufacturer|Model|PartNumber|Speed"
			,	"4Win32_BaseBoard": "Manufacturer|Model|Product"
			, 	"5Win32_VideoController": "AdapterCompatibility|Name|VideoModeDescription" }
	for WQLQuery, propertyList in aQuery
	{
		WQLQuery := substr(WQLQuery, instr(WQLQuery, "Win32")) ; get rid of the number prefix which is used to set the order in the for loop
		s .= (A_Index > 1 ?"`n`n" : "") (title := substr(WQLQuery, StrLen("Win32_") + 1)) "`n"
		loop, % strlen(title)
			s .= "="
		s .= "`n" WMISystemInfo_Retrieve(WQLQuery, False,, propertyList, True)
	}
	return s
}

WMISystemInfo_getPropertyList(WQLQuery)
{
	if (WQLQuery = "Win32_OperatingSystem")
	{
		return "BuildNumber|BuildType|Caption|CountryCode|CreationClassName|CSDVersion|CSName|CurrentTimeZone|Distributed"
			. "|EncryptionLevel|FreePhysicalMemory|FreeSpaceInPagingFiles|FreeVirtualMemory|InstallDate|LargeSystemCache"
			. "|LastBootUpTime|LocalDateTime|Locale|Manufacturer|MaxNumberOfProcesses|MaxProcessMemorySize|Name|NumberOfLicensedUsers"
			. "|NumberOfProcesses|NumberOfUsers|Organization|OSLanguage|OSType|Primary|ProductType|RegisteredUser|SerialNumber"
			. "|ServicePackMajorVersion|ServicePackMinorVersion|SizeStoredInPagingFiles|Status|SuiteMask|SystemDevice|SystemDirectory"
			. "|SystemDrive|TotalSwapSpaceSize|TotalVirtualMemorySize|TotalVisibleMemorySize|Version|WindowsDirectory"
	}	
	else if (WQLQuery = "Win32_PhysicalMemory")
	{
		return "BankLabel|Capacity|Caption|CreationClassName|DataWidth|Description|DeviceLocator|FormFactor|"
		    . "HotSwappable|InstallDate|InterleaveDataDepth|InterleavePosition|Manufacturer|MemoryType|Model|Name|"
		    . "OtherIdentifyingInfo|PartNumber|PositionInRow|PoweredOn|Removable|Replaceable|SerialNumber|SKU|Speed|"
		    . "Status|Tag|TotalWidth|TypeDetail|Version"
	}	
	else if (WQLQuery = "Win32_BaseBoard")
	{
		return "Caption|CreationClassName|Depth|Description|Height|HostingBoard|HotSwappable|InstallDate|"
			. "Manufacturer|Model|Name|OtherIdentifyingInfo|PartNumber|PoweredOn|Product|Removable|Replaceable|"
			. "RequirementsDescription|RequiresDaughterBoard|SerialNumber|SKU|SlotLayout|SpecialRequirements|"
			. "Status|Tag|Version|Weight|Width"
	}
	else if (WQLQuery = "Win32_Processor")
	{
		return "AddressWidth|Architecture|Availability|Caption|ConfigManagerErrorCode|"
			. "ConfigManagerUserConfig|CpuStatus|CreationClassName|CurrentClockSpeed|CurrentVoltage|"
			. "DataWidth|Description|DeviceID|ErrorCleared|ErrorDescription|ExtClock|Family|InstallDate|"
			. "L2CacheSize|L2CacheSpeed|L3CacheSize|L3CacheSpeed|LastErrorCode|Level|LoadPercentage|"
			. "Manufacturer|MaxClockSpeed|Name|NumberOfCores|NumberOfLogicalProcessors|OtherFamilyDescription|"
			. "PNPDeviceID|PowerManagementSupported|ProcessorId|ProcessorType|Revision|Role|SocketDesignation|"
			. "Status|StatusInfo|Stepping|SystemCreationClassName|SystemName|UniqueId|UpgradeMethod|Version|VoltageCaps"
	}
	else if (WQLQuery = "Win32_VideoController")
	{
		return "AdapterCompatibility|AdapterDACType|AdapterRAM|Availability|Caption|ColorTableEntries|ConfigManagerErrorCode|"
			. "ConfigManagerUserConfig|CreationClassName|CurrentBitsPerPixel|CurrentHorizontalResolution|CurrentNumberOfColors|"
			. "CurrentNumberOfColumns|CurrentNumberOfRows|CurrentRefreshRate|CurrentScanMode|CurrentVerticalResolution|Description|"
			. "DeviceID|DeviceSpecificPens|DitherType|DriverDate|DriverVersion|ErrorCleared|ErrorDescription|ICMIntent|ICMMethod|"
			 . "InfFilename|InfSection|InstallDate|InstalledDisplayDrivers|LastErrorCode|MaxMemorySupported|MaxNumberControlled|"
			 . "MaxRefreshRate|MinRefreshRate|Monochrome|Name|NumberOfColorPlanes|NumberOfVideoPages|PNPDeviceID|"
			 . "PowerManagementSupported|ProtocolSupported|ReservedSystemPaletteEntries|SpecificationVersion|Status|StatusInfo|"
			 . "SystemCreationClassName|SystemName|SystemPaletteEntries|TimeOfLastReset|VideoArchitecture|VideoMemoryType|"
			 . "VideoMode|VideoModeDescription|VideoProcessor"
	}
	else return
}

WMISystemInfo_Retrieve(WQLQuery, object := True, byRef itemCount := "", PropertyList := "", insertTab := False)
{
	objWMIService := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\" A_ComputerName "\root\cimv2")
	colInfo := objWMIService.ExecQuery("Select * From " WQLQuery)._NewEnum
	if object
		result := []
	if (PropertyList = "" && !PropertyList := WMISystemInfo_getPropertyList(WQLQuery))
		return -1
	While colInfo[obj]
	{
		itemCount := A_Index	
		if object
			result[itemCount] := []
		else if (itemCount > 1)
			result .= "`n`t-------------`n"
		Loop, Parse, PropertyList, |
			object 	? result[itemCount, A_LoopField] := obj[A_LoopField] 
					: result .= (A_Index > 1 ? "`n" : "") (insertTab ? A_Tab : "") A_LoopField ": " obj[A_LoopField]		
	}
	return result	
}