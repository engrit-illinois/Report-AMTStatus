# Documentation home: https://github.com/engrit-illinois/Report-AMTStatus
# By mseng3

function Report-AMTStatus {

	param (
		[Parameter(Position=0,Mandatory=$true,ParameterSetName="Array")]
		[string[]]$Computers,
		
		[string]$OUDN = "OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu",
		
		[Parameter(Position=0,Mandatory=$true,ParameterSetName="Collection")]
		[string]$Collection,
		
		[string[]]$Username,
		
		[string[]]$Password,
		
		[switch]$SkipPing,
		
		[switch]$SkipModel,
		
		[int]$Pings=1, # Number of times to ping before giving up
		
		[switch]$NoCSV,
		
		[switch]$ForceBootIfOff,
		
		[switch]$ForceBootIfHibernated,
		
		[switch]$SkipFWVer,
		
		[switch]$NoLog,
		
		[string]$LogPath="c:\engrit\logs\Report-AMTStatus_$(Get-Date -Format `"yyyy-MM-dd_HH-mm-ss-ffff`").log",
		
		[int]$Verbosity=0,
		
		[string]$SiteCode="MP0",
		
		[string]$Provider="sccmcas.ad.uillinois.edu",
		
		[string]$CMPSModulePath="$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
	)
	
	function log {
		param (
			[string]$msg,
			[int]$l=0, # level (of indentation)
			[int]$v=0, # verbosity level
			[switch]$nots, # omit timestamp
			[switch]$nnl # No newline after output
		)
		
		if(!(Test-Path -PathType leaf -Path $LogPath)) {
			$shutup = New-Item -ItemType File -Force -Path $LogPath
		}
		
		for($i = 0; $i -lt $l; $i += 1) {
			$msg = "    $msg"
		}
		if(!$nots) {
			$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss:ffff"
			$msg = "[$ts] $msg"
		}
		
		if($v -le $Verbosity) {
			if($nnl) {
				Write-Host $msg -NoNewline
			}
			else {
				Write-Host $msg
			}
			
			if(!$NoLog) {
				if($nnl) {
					$msg | Out-File $LogPath -Append -NoNewline
				}
				else {
					$msg | Out-File $LogPath -Append
				}
			}
		}
	}

	function Prep-SCCM {
		log "Preparing connection to SCCM..."
		$initParams = @{}
		if((Get-Module ConfigurationManager) -eq $null) {
			Import-Module $CMPSModulePath @initParams 
		}
		if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
			New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $Provider @initParams
		}
		Set-Location "$($SiteCode):\" @initParams
		log "Done prepping connection to SCCM." -v 2
	}
	
	function Log-Error($e, $l) {
		log "$($e.Exception.Message)" -l $l
		log "$($e.InvocationInfo.PositionMessage.Split("`n")[0])" -l ($l + 1)
	}
	
	function Get-CompNameString($compNames) {
		$list = ""
		foreach($name in @($compNames)) {
			$list = "$list, $name"
		}
		$list = $list.Substring(2,$list.length - 2) # Remove leading ", "
		$list
	}
	
	function Get-CompNames {
		log "Getting list of computer names..."
		if($Computers) {
			log "List was given as an array." -l 1 -v 1
			$compNames = @()
			foreach($query in @($Computers)) {
				$thisQueryComps = (Get-ADComputer -Filter "name -like '$query'" -SearchBase $OUDN | Select Name).Name
				$compNames += @($thisQueryComps)
			}
			$list = Get-CompNameString $compNames
			log "Found $($compNames.count) computers in given array: $list." -l 1
		}
		elseif($Collection) {
			log "List was given as a collection. Getting members of collection: `"$Collection`"..." -l 1 -v 1
		
			$myPWD = $pwd.path
			Prep-SCCM
				
			$colObj = Get-CMCollection -Name $Collection
			if(!$colObj) {
				log "The given collection was not found!" -l 1
			}
			else {
				# Get comps
				$comps = Get-CMCollectionMember -CollectionName $Collection | Select Name,ClientActiveStatus
				if(!$comps) {
					log "The given collection is empty!" -l 1
				}
				else {
					# Sort by active status, with active clients first, just in case inactive clients might come online later
					# Then sort by name, just for funsies
					$comps = $comps | Sort -Property @{Expression = {$_.ClientActiveStatus}; Descending = $true}, @{Expression = {$_.Name}; Descending = $false}
					
					$compNames = $comps.Name
					$list = Get-CompNameString $compNames
					log "Found $($compNames.count) computers in `"$Collection`" collection: $list." -l 1
				}
			}
			
			Set-Location $myPWD
		}
		else {
			log "Somehow neither the -Computers, nor -Collection parameter was specified!" -l 1
		}
		
		log "Done getting list of computer names." -v 2
		
		$compNames
	}
	
	function Get-Creds {
		log "Getting credentials..."
		
		if($Username -and $Password) {
			log "-Username and -Password were both specified." -l 1 -v 2
			
			$creds = @()
			
			if(@($Username).count -ne @($Password).count) {
				log "-Username and -Password contain a different number of values!" -l 1
				log "To specify multiple sets of credentials, format these parameters like so:" -l 2 
				log "-Username `"user1name`",`"user2name`" -Password `"user1pass`",`"user2pass`"" -l 2
			}
			else {
				log "Building credentials..." -l 1
				if(@($Username).count -gt 1) {
					log "Multiple sets of credentials were specified." -l 2
				}
				
				for($i = 0; $i -lt @($Username).count; $i += 1) {
					$user = @($Username)[$i]
					$pass = @($Password)[$i]
					$securePass = ConvertTo-SecureString $pass -AsPlainText -Force
					$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user,$securePass
					$creds += @($cred)
				}
			}
		}
		else {
			log "-Username and/or -Password was not specified. Prompting for credentials." -l 1 -v 2
			if($Username) {
				$creds = Get-Credential $Username
			}
			else {
				$creds = Get-Credential
			}
		}
		log "Done getting credentials." -v 2
		$creds
	}
	
	function Get-State($comp, $creds, $credNum=0) {
		$cred = @($creds)[$credNum]
		log "Calling Get-AMTPowerState with credential set #$($credNum + 1)/$(@($creds).count) (user: `"$($cred.UserName)`")..." -l 2
		
		try {
			$state = Get-AMTPowerState -ComputerName $comp -Credential $cred
		}
		catch {
			log "Get-AMTPowerState call failed!" -l 3
			Log-Error $_ 4
		}
		
		$workingCred = -1
		$forceBooted = "No"
		
		# If there was any result
		if($state) {
			log "Get-AMTPowerState call returned a result." -l 3 -v 1
			$desc = $state."Power State Description"
			$id = $state."Power State ID"
			
			# If the result has the data we want
			if($desc) {
				log "Get-AMTPowerState call received response: `"$desc`"." -l 3
				# If it didn't respond
				if($desc -eq "Cannot connect") {
					log "AMT didn't respond." -l 4
				}
				# If it responded, but didn't auth
				elseif($desc -eq "Unauthorized") {
					log "Credentials not authorized." -l 4
					$newCredNum = $credNum + 1
					if($newCredNum -ge @($creds).count) {
						log "No more credentials to try." -l 5
					}
					else {
						log "Trying next set of credentials..." -l 5
						$newState = Get-State $comp $creds $newCredNum
						$id = $newState.id
						$desc = $newState.desc
						$workingCred = $newState.workingCred
						$forceBooted = $newState.forceBooted
					}
				}
				# If it responds and is powered on
				elseif($desc -eq "On (S0)") {
					log "Computer is already powered on." -l 4
					$workingCred = $credNum
				}
				# If it responds and is powered off
				elseif($desc -eq "Off (S5)") {
					log "Computer is powered off." -l 4
					$workingCred = $credNum
					$forceBooted = Force-Boot $ForceBootIfOff $comp $cred
				}
				# If it responds and is hibernated
				elseif($desc -eq "Hibernate (S4)") {
					log "Computer is hibernated." -l 4
					$workingCred = $credNum
					$forceBooted = Force-Boot $ForceBootIfHibernated $comp $cred
				}
				elseif($desc -eq "Standby (S3)") {
					log "Computer is in standby." -l 4
					$workingCred = $credNum
				}
				else {
					log "Unrecognized result." -l 4
					# Could potentially return valid states I don't know about
					# In which case $workingCred would incorrectly be -1
					# So newly discovered valid states should be given their own elseif block
					# However in a sample of 400+ computers, I never saw anything not accounted for above
				}
			}
			else {
				log "Get-AMTPowerState call returned an unexpected result!" -l 3
				$desc = "Unexpected result"
			}
		}
		else {
			log "Get-AMTPowerState returned no result." -l 3
			$desc = "Call failed"
		}
		log "Done calling Get-AMTPowerState." -l 2 -v 2
		
		$result = [PSCustomObject]@{
			id = $id
			desc = $desc
			workingCred = $workingCred
			forceBooted = $forceBooted
		}
		$result
	}
	
	function Force-Boot($requested, $comp, $cred) {
		$forceBooted = "No"
		if($requested) {
			log "-ForceBootIfOff was specified. Booting computer with Invoke-AMTForceBoot..." -l 4
			$captureForceBootResult = Invoke-AMTForceBoot $comp -Operation PowerOn -Device HardDrive -Credential $cred
			$forceBooted = "Yes"
		}
		else {
			log "-ForceBootIfOff was not specified." -l 4 -v 1
		}
		$forceBooted
	}
	
	function Get-FW($comp, $cred) {
		#log "Calling Get-AMTFirmwareVersion with credential set #$($credNum + 1)/$(@($creds).count) (user: `"$($cred.UserName)`")..." -l 2
		log "Calling Get-AMTFirmwareVersion with known good credentials..." -l 2
		try {
			$fw = Get-AMTFirmwareVersion -ComputerName $comp -Credential $cred
		}
		catch {
			log "Get-AMTFirmwareVersion call failed!" -l 3
			Log-Error $_ 4
		}
		
		# If there was any result
		if($fw) {
			log "Get-AMTFirmwareVersion call returned a result." -l 3 -v 1
			$value = $fw."Value"
			
			# If the result has the data we want
			if($value) {
				log "Get-AMTFirmwareVersion call received response: `"$value`"." -l 3
				# If it didn't respond
				if($value -eq "Cannot connect") {
					log "AMT didn't respond." -l 4
				}
				# If it responded, but didn't auth
				elseif($value -eq "Unauthorized") {
					log "Credentials not authorized." -l 4
					
					# Now I'm only running this function with known good creds
					# So this should never happen
					<#
					$newCredNum = $credNum + 1
					if($newCredNum -ge @($creds).count) {
						log "No more credentials to try." -l 5
					}
					else {
						log "Trying next set of credentials..." -l 5
						$value = Get-FW $comp $creds $newCredNum
					}
					#>
				}
				# If it responds with an unrecognized value
				else {
					# It's probably a version number
					if($value -match '^\d*\.\d*\.\d*\.\d*$') {
						log "Result looks like a version number." -l 4
					}
					else {
						log "Result not recognized as a version number!" -l 4
					}
				}
			}
			else {
				log "Get-AMTFirmwareVersion call returned an unexpected result!" -l 3
				$value = "Unexpected result"
			}
		}
		else {
			log "Get-AMTFirmwareVersion returned no result." -l 3
			$value = "Call failed"
		}
		log "Done calling Get-AMTFirmwareVersion." -l 2 -v 2
		$value
	}
	
	function Get-HW($comp, $cred) {
		#log "Calling Get-AMTHardwareAsset with credential set #$($credNum + 1)/$(@($creds).count) (user: `"$($cred.UserName)`")..." -l 2
		log "Calling Get-AMTHardwareAsset with known good credentials..." -l 2
		try {
			$hw = Get-AMTHardwareAsset -ComputerName $comp -Credential $cred
			
		}
		catch {
			log "Get-AMTHardwareAsset call failed!" -l 3
			Log-Error $_ 4
		}
		
		# If there was any result
		if($hw) {
			log "Get-AMTHardwareAsset call returned a result." -l 3 -v 1

			# If it didn't respond
			if($hw -eq "Could not connect to host $comp : Check Name or IP address") {
				log "AMT didn't respond." -l 3
				$error = "AMT didn't respond"
			}
			# If it responded, but didn't auth
			elseif($hw -eq "Unauthorized to connect to $comp : Incorrect username or password") {
				log "Credentials not authorized." -l 3
				$error = "Credentials not authorized"
				
				# Now I'm only running this function with known good creds
				# So this should never happen
				<#
				$newCredNum = $credNum + 1
				if($newCredNum -ge @($creds).count) {
					log "No more credentials to try." -l 5
				}
				else {
					log "Trying next set of credentials..." -l 5
					$value = Get-HW $comp $creds $newCredNum
				}
				#>
			}
			# If it responds with an unrecognized value
			else {
				# It's probably a the object we wanted
				
				# If the result has the data we want
				$hwCS = $hw | Where { $_.PSParentPath -like "IntelvPro\AmtSystem::\HardwareAssets\ComputerSystem*" }
				if($hwCS) {
					$make = ($hwCS | Where { $_.Name -eq "Manufacturer" }).Value
					if($make) {
						$model = ($hwCS | Where { $_.Name -eq "Model" }).Value
						if($model) {
							log "Make: $make, Model: $model" -l 3
						}
						else {
							log "Get-AMTHardwareAsset call returned an unexpected result! No Model info." -l 3
							$error = "Unexpected result: no model"
						}
					}
					else {
						log "Get-AMTHardwareAsset call returned an unexpected result! No Manufacturer info." -l 3
						$error = "Unexpected result: no manufacturer"
					}
				}
				else {
					log "Get-AMTHardwareAsset call returned an unexpected result! No ComputerSystem info." -l 3
					$error = "Unexpected result: no computersystem"
				}
			}
		}
		else {
			log "Get-AMTHardwareAsset returned no result." -l 3
			$value = "Call failed"
		}
		log "Done calling Get-AMTHardwareAsset." -l 2 -v 2
		
		$result = [PSCustomObject]@{
			"Make" = $make
			"Model" = $model
			"Error" = $error
		}
		$result
	}
	
	function Get-CompData($comp, $creds, $progress) {
		log "Processing computer $progress`: `"$comp`"..." -l 1
	
		# Determine whether machine is online
		# Ping machine. AMT can be configured to respond to pings, but ours are not it seems, which is useful here
		$ponged = "Unknown"
		if($SkipPing) {
			log "-SkipPing was specified. Skipping ping." -l 2 -v 1
			$ponged = "Skipped"
		}
		else {
			log "Pinging computer... " -l 2 -nnl
			$ponged = "False"
			if(Test-Connection -ComputerName $comp -Count $Pings -Quiet) {
				log "Responded to ping." -nots
				$ponged = "True"
			}
			# If machine is offline
			else {
				log "Did not respond to ping." -nots
			}
		}
		
		$state = Get-State $comp $creds
		log "state: `"$state`"" -v 3
		
		$error = ""
		$stateID = $state.id
		$stateDesc = $state.desc
		$workingCred = $state.workingCred
		$forceBooted = $state.forceBooted
		log "id: `"$stateID`", desc: `"$stateDesc`", workingCred: `"$workingCred`", forceBooted: `"$forceBooted`"" -v 3
		# Don't bother with more calls if we know they're not going to succeed
		if($state.workingCred -lt 0) {
			log "AMT on computer did not respond, or denied authentication for Get-AMTPowerState call. Skipping further AMT calls." -l 2
			$error = $stateDesc
			$stateID = ""
			$stateDesc = ""
			$fwv = ""
			$make = ""
			$model = ""
		}
		else {
			log "Get-AMTPowerState succeeded." -l 2
			if($SkipFWVer) {
				log "-SkipFWVer was specified. Skipping Get-AMTFirmwareVersion call." -l 2 -v 1
				$fwv = "Skipped"
			}
			else {
				log "Continuing with Get-AMTFirmwareVersion call." -l 2
				$fwv = Get-FW $comp $creds[$state.workingCred]
			}
			
			if($SkipModel) {
				log "-SkipModel was specified. Skipping Get-AMTHardwareAsset call." -l 2 -v 1
				$make = "Skipped"
				$model = "Skipped"
			}
			else {
				log "Continuing with Get-AMTHardwareAsset call." -l 2
				$hw = Get-HW $comp $creds[$state.workingCred]
				if($hw.Error) {
					$make = "Error"
					$model = "Error"
				}
				else {
					$make = $hw.Make
					$model = $hw.Model
				}
			}
		}
		
		$compData = [PSCustomObject]@{
			"ComputerName" = $comp
			"Ponged" = $ponged
			"KnownError" = $error
			"Make" = $make
			"Model" = $model
			"PowerStateID" = $stateID
			"PowerStateDesc" = $stateDesc
			"ForceBooted" = $forceBooted
			"Firmware" = $fwv
			"WorkingCred" = ($state.workingCred + 1) # Translating from index to human speech
		}
		
		log "Done processing computer: `"$comp`"." -l 1 -v 2
		$compData
	}
	
	function Get-CompsData($comps, $creds) {
		$compsData = @()
		if(@($comps).count -gt 0) {
			log "Looping through computers..."
			$i = 1
			$count = @($comps).count
			foreach($comp in $comps) {
				$percent = [math]::Round(($i - 1)/$count,2)*100
				$progress = "$i/$count ($percent%)"
				$compData = Get-CompData $comp $creds $progress
				$compsData += @($compData)
				$i += 1
			}
			log "Done looping through computers." -v 2
		}
		$compsData
	}
	
	function Export-CompsData($compsData) {
		if($NoCSV) {
			log "-NoCSV was specified. Skipping export of gathered data." -v 1
		}
		else {
			if($compsData) {
				$csvPath = $LogPath.Replace('.log','.csv')
				$compsData = $compsData | Select ComputerName,Ponged,Firmware,WorkingCred,KnownError,Make,Model,PowerStateID,PowerStateDesc,ForceBooted
				log "Exporting data to: `"$csvPath`"..."
				$compsData | Export-Csv -Encoding ascii -NoTypeInformation -Path $csvPath
				log "Done exporting data." -v 2
			}
			else {
				log "There was no data to export to CSV."
			}
		}
	}
	
	function Print-CompsData($compsData) {
		$compsData | Format-Table
	}
	
	function Do-Stuff {
		$creds = Get-Creds
		if(@($creds).count -gt 0) {
			$comps = Get-CompNames
			$compsData = Get-CompsData $comps $creds
			Export-CompsData $compsData
			Print-CompsData $compsData
		}
	}
	
	Do-Stuff
	
	log "EOF"
}