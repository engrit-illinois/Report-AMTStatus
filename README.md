# Summary

This Powershell module queries a list of computers to find out whether they respond to AMT queries, using cmdlets provided by the IntelvPro Powershell module. For more info about this module, see here: https://wiki.illinois.edu/wiki/display/engritprivate/Using+Powershell+to+control+Intel+AMT.
If so, various AMT information about the computer is gathered and output.  
Additionally, computers which are found to respond to AMT queries, and which are powered off, or in hibernation can optionally be force booted.  

# Input
It takes an list of computer names (or an SCCM collection name), and a one or more sets of credentials, used to authenticate to AMT on the given computers.

# Output
Progress is output to screen and logged to a log file.  
Results and gathered data are output to screen and exported to a csv file.  

# Behavior

For each computer, the following is recorded:  
- The result of a ping
- The result of querying AMT for the PowerState
- Whether the computer was force booted
- The result of querying AMT for the FirmwareVersion
- The result of querying AMT for the Make/Model
- Which given set of credentials worked

# Usage
1. Download and install the Intelvpro PowerShell module from the Intel AMT SDK. This custom module was most recently tested and developed for version 16.0.5.1 of the AMT SDK. How to do that is outside the scope of this readme.
2. If using v16.0.5.1 (and probably other versions) of the AMT SDK, overwrite the contents of the Intelvpro module's `Get-AMTHardwareAsset.ps1` file with the contents of the `Get-AMTHardwareAsset-fixed.ps1` file provided in this repo. It fixes bugs caused by poor error checking in that Intelvpro module file. Not doing this may cause a lot of information to be missing from the generated report.
3. Download `Report-AMTStatus.psm1` to the appropriate subdirectory of your PowerShell [modules directory](https://github.com/engrit-illinois/how-to-install-a-custom-powershell-module).
4. Run it, e.g.:
    - `Report-AMTStatus -Computers "computer-name-01"`
	- `Report-AMTStatus -Computers "computer-name-*"`
    - `Report-AMTStatus -Computers "computer-name-01","computer-name-3*" -Username "admin"`
    - `Report-AMTStatus -Collection "Collection Name" -Username "user" -Password "pass"`
    - `Report-AMTStatus -Collection "Collection Name" -Username "user1","user2" -Password "user1pass","user2pass"`

# Prerequisites
- If using the `-Collection` parameter, Powershell console must be run by a user with read permissions to the relevant content in SCCM.

# Parameters

## Primary parameters

### -Computers
Required if not using `-Collection`. An array of strings representing computer names on which to query AMT.

### -OUDN
Optional string.  
The distinguished name of the OU to limit the computername search to.  
Default is `"OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu"`.  
Only relevant if using `-Computers`.  

### -Collection
Required if not using `-Computers`. A string representing an SCCM collection from which to pull a list of computer names on which to query AMT.

### -Username
Optional string.  
An array of strings representing the usernames of defined sets of credentials to use while attempting to authenticate to AMT.  

### -Password
Optional string.  
An array of strings representing the passwords of defined sets of credentials to use while attempting to authenticate to AMT.  

### Notes about credential parameters

- If specifying more than one, an equal number of usernames and passwords must be specified.  
- The first username specified will be paired with the first password specified. The second username specified will be paired with the second password specified, and so on.  
- To use the same username with multiple passwords, or vice versa, you must still specify each full set, e.g.:  
  - `-Username "user","user" -Password "pass1","pass2"`
  - `-Username "user1","user2" -Password "pass","pass"`
- When querying AMT, these credential sets will be used in order until one succeeds, or the sets are exhausted.  
- The number of the working credential set for each computer will be recorded in the output CSV in the `WorkingCred` field.
  - A value of `1` means the first set of credentials worked. A value of `2` means the second set of credentials worked, and so on.
  - A value of `0` means that none of the credential sets worked.  
- If `-Username` and/or `-Password` are omitted, the script will prompt for a single username and password to be used when polling all computers.
  - Remember, this is for the `-Username` and `-Password` parameter that will be passed to the IntelvPro cmdlets (i.e. the credentials to authenticate to AMT on the endpoints), and NOT your own credentials.  
- Intentionally leaving this unspecified is useful if you want to avoid passing in plaintext credentials to this module. However be advised that, if I'm not mistaken, these credentials are NOT encrypted when being passed over the network to the endpoints. This is just how the IntelvPro module works (the web interface also uses HTTP). It might be possible to configure AMT on the endpoints to use a cert to secure communications, but I've not investigated that.

## Optional force boot parameters

### -ForceBootIfOff
Optional switch. If specified, force boots computers which respond, and are in the Off (S5) state.

### -ForceBootIfHibernated
Optional switch. If specified, force boots computers which respond, and are in the Hibernated (S4) state.

### -WakeIfStandby
Optional switch. If specified, wakes computers which respond, and are in the Standby (S3) state.

### Notes about force boot/wake parameters
The force boot functionality was added as a special feature, since it doesn't really belong in a script intended for reporting.  
It was just more convenient to add this functionality than to recreate all of the logic in a separate script.  
If you're using the script solely to boot computers which are powered off/in hibernation/standby, then you may want to make use of the following optional switches, which are only useful for gathering information.  
- `-NoLog`
- `-NoCSV`
- `-SkipPing`
- `-SkipFWVer`
- `-SkipModel`

It's recommended to run the script without specifying any force boot parameter first, in order to gather data.  

## Functionality parameters

### -Pings
Optional integer. The number of times to ping a computer before giving up.  
Has no effect if `-SkipPing` is specified.  
Default is `1`.

### -SkipPing
Optional switch. If specified, the script doesn't bother pinging the computers.  

### -SkipFWVer
Optional switch. If specified, the script doesn't bother querying AMT for the AMT firmware version.  

### -SkipModel
Optional switch. If specified, the script doesn't bother querying AMT for the make and model of the hardware.  

### -NoLog
Optional switch. If specified, no log file will be generated.  

### -LogPath
Optional. A string representing the full filepath to a text file.  
Default is `c:\engrit\logs\Report-AMTStatus_$(Get-Date -Format ``"yyyy-MM-dd_HH-mm-ss-ffff``").log`.  
The output CSV file will use the same filepath, but with a `.csv` extension.

### -NoCSV
Optional switch. If specified, no CSV file will be generated.  

### -Verbosity
Optional integer. The level of verbosity to use when outputting progress to the screen and to the log file.  
Only useful for debugging the script.

## SCCM parameters

### -SiteCode
Optional. A string representing the Site Code ID for your SCCM site.  
Default value is `MP0`, because that's the author's site.  
You can change the default value near the top of the script.  

### -Provider
Optional. A string representing the hostname of your provider.  
Use whatever you use in the console GUI application.  
Default value is `sccmcas.ad.uillinois.edu`, because that's the author's provider.  
You can change the default value near the top of the script.  

### -CMPSModulePath
Optional. A string representing the local path where the ConfigurationManager Powershell module exists.  
Default value is `$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1`, because there's where it is for us.  
You may need to change this, depending on your SCCM (Console) version. The path has changed across various versions of SCCM, but the environment variable used by default should account for those changes in most cases.  
You can change the default value near the top of the script.  

# Notes
- Whether a computer responds to a ping is more or less irrelevant, as computers with AMT configured should respond regardless. This behavior can be disabled, but is on by default. This information is provided in the output CSV just for reference.
- If a computer fails to respond to an AMT query, or none of the provided credential sets were successful, subsequent AMT queries will be skipped, to save on time.
- The script is optimized so that subsequent AMT queries will use the known good credentials from previous queries to the same computer, if there are any.
- The script is intentionally designed to query computers sequentially, to avoid invasive busts of network traffic. For querying large collections, expect to run it overnight.
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
