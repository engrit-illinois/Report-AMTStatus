# Copyright (C) 2007 Intel Corporation

Function Get-AMTHardwareAsset {
<#
  .Synopsis
    Shows hardware information about the system
  .Description
    This Cmdlet returns the hardware information from clients that have Intel Active Management Technology (AMT) firmware version 3.2 or higher.
  .Notes
    Supported AMT Firmware Versions:
    This Cmdlet supports AMT firmware version 3.2 or higher.
    
    AMT Provisioning:
      The vPro client AMT firmware must be provisioned prior to accessing AMT functionality. This CMDLet will fail if it is run against a vPro client that has not been provisioned.
        
    AMT Client Authentication:
      To invoke commands against AMT enabled clients credentials to authenticate must be specified. 
      When no credential is provided as a parameter, the script will use the local logged on Kerberos credential.
      When only the username (Kerberos or Digest) parameter is included the user will be prompted to provide the associated password.
      Credentials should be stored as a PowerShell variable then passed into the Cmdlet with the credential parameter.
      $AMTCredential = get-credential
     
    AMT Client Encryption:
      If the Intel vPro client has been configured to use TLS (a web server certificate has been issued to the Intel Management Engine) the Cmdlet must be called with a -TLS switch.

      When managing an Intel vPro client over TLS (Port 16993) it is important that the computername parameter matchs the primary subject name of the issued TLS certificate. Typically this is the fully qualified domain name (FQDN).

	  If Mutual TLS is desired, the Cmdlet must be called with -TLS switch and with a valid certificate name from the certificate store in the -CertificateName parameter.
    Status:
      Status output designates if the Cmdlet was run successfully. For failed attempts additional status may be provided.
  .Link
    http:\\vproexpert.com
    http:\\www.intel.com\vpro
    http:\\www.intel.com

  .Example
    get-AMTHardwareAsset vProClient.vprodemo.com -Credential $AMTCredential

	ComputerName                  PSParentPath                  Name                          Value
    ------------                  ------------                  ----                          -----
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... Version                       1.16
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... ReleaseDate                   2010/10/21 12:00:00 AM
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... Manufacturer                  American Megatrends Inc.
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... CPUStatus                     CPU Enabled
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... CurrentClockSpeed             2700
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... ExternalBusClockSpeed         100
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... Family                        Intel(R) Core(TM) i7 proce...
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... MaxClockSpeed                 2700
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... UpgradeMethod                 ZIF Socket
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... Manufacturer                  Intel(R) Corporation
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... Version                       Intel(R) Core(TM) i7-2620M...

	
  .example
    Get-AMTHardwareAsset -ComputerName vProClient.vProDemo.com -Credential $AMTCredential | Where-Object -FilterSc#ript {$_.PSPath -like "*BIOS*"}

	ComputerName                  PSParentPath                  Name                          Value
    ------------                  ------------                  ----                          -----
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... Version                       1.16
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... ReleaseDate                   2010/10/21 12:00:00 AM
    vProClient.vprodemo.com       AmtSystem::\HardwareAssets... Manufacturer                  American Megatrends Inc.

    Displays only the results that contain "BIOS" in their path

  .example
    Get-AMTHardwareAsset -ComputerName vProClient.vProDemo.com -Credential $AMTCredential | Where-Object -FilterSc#ript {$_.PSPath -like "*BIOS*"} | format-list

    ComputerName : vProClient.vprodemo.com  
    PSParentPath : AmtSystem::\HardwareAssets\BIOS\Primary BIOS
    Name         : Version
    Value        : 1.16

    ComputerName : vProClient.vprodemo.com 
    PSParentPath : AmtSystem::\HardwareAssets\BIOS\Primary BIOS
    Name         : ReleaseDate
    Value        : 2010/10/21 12:00:00 AM

    ComputerName : vProClient.vprodemo.com 
    PSParentPath : AmtSystem::\HardwareAssets\BIOS\Primary BIOS
    Name         : Manufacturer
    Value        : American Megatrends Inc.

    Displays only the results that contain "BIOS" in their path and formatted into a list.

  .example
    Get-AMTHardwareAsset -ComputerName vProClient -Credential $AMTCredential -TextOutput

    vProClient BIOS
    vProClient  BIOS:Primary BIOS
         Version............. 1.16
         ReleaseDate......... 2010/10/21 12:00:00 AM
         Manufacturer........ American Megatrends Inc.
    vProClient Cpu
    vProClient  Cpu:CPU 0
         CPUStatus........... CPU Enabled
         CurrentClockSpeed... 2700
         ExternalBusClockSpeed 100
         Family.............. Intel(R) Core(TM) i7 processor
         MaxClockSpeed....... 2700
         UpgradeMethod....... ZIF Socket
         Manufacturer........ Intel(R) Corporation
         Version............. Intel(R) Core(TM) i7-2620M CPU @ 2.70GHz

    Displays results formatted as text.
#>
[CmdletBinding()]
	Param (
	  [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true, position=0, HelpMessage="Hostname, FQDN, or IP Address")] [String[]] $ComputerName,
      [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$false, position=1, HelpMessage="Valid Ports are 16992 (non-TLS) or 16993 (TLS)")][ValidateSet("16992", "16993")] [String] $Port,
    [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$false, HelpMessage="Use TLS (Port 16993)")] [switch] $TLS,
	[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$false, HelpMessage="Accept self-signed certificate for TLS connection (skip any certificate checks.)")] [switch] $AcceptSelfSignedCert,
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$false, HelpMessage="Name of certificate. (Use for mutual TLS)")] [string] $CertificateName,
      [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$false, HelpMessage="Digest of Kerberos User")] [string] $Username,
	  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$false, HelpMessage="Digest of Kerberos Password")] [string] $Password,
      [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$false, HelpMessage="Format output to text")] [switch] $TextOutput,
	  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$false, position=2, HelpMessage="PS Credential")] [System.Management.Automation.PSCredential] $Credential
	) 

	PROCESS {

			function Traverse([string]$path, [int]$indentdepth, [string] $header)
			{
				# 2023-05-07: try/ctach block added by mseng3@illinois.edu, because this recursive function can try to traverse invalid containers somehow and will end up returning BOTH a "Get-ChildItem : Object reference not set to an instance of an object" error as well as valid data
				try {
					Get-ChildItem $path | ForEach-Object {						 
						if ($_.Type -eq "Container")
						{			
							$test = $path + "\" + $_.Name
									
							if($header)
							{
							$ContainerName = $header + ":"+ $_.Name
							} 
							else
							{
							$ContainerName = $_.Name
							}
							
							if ($TextOutput.IsPresent){
								Write-Output ($Comp + " ".PadRight($indentdepth, " ") + $ContainerName)
							}
							traverse $test ($indentdepth+2) $ContainerName
						}
						else
						{					
							
							#write-host $tempAMTPSDrive":\HardwareAssets\"$_.Name
							if ($TextOutput.IsPresent){
							Write-output ("".PadRight($indentdepth, " ") + " " + $_.Name.PadRight(20, ".") + " " + $_.Value)
							}
							$obj = New-Object PSObject
							
							$fullName = $header + ":"+ $_.Name
							
							$obj | Add-Member -MemberType noteproperty -Name ComputerName -value $Comp
							$obj | Add-Member -MemberType NoteProperty -Name PSParentPath -Value $_.PSParentPath
							$obj | Add-Member -MemberType noteproperty -Name Name -value $_.Name
							$obj | Add-Member -MemberType noteproperty -Name Value -value $_.Value		                		       
							$global:Results += $obj				
						}
					}
				}
				catch {
					# Just ignore this I guess
				}
			}


        if ($Credential.username.Length -gt 0) {
            
		} elseif ($Username.length -gt 0) {
			if ($Password.length -gt 0) {
                $passwd = ConvertTo-SecureString $Password -AsPlainText –Force
                $Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username,$passwd
			} else {
				$Credential = Get-Credential $Username
			}
		}  
        
        $tlsstring = ""
        if ($TLS.IsPresent)
        {
            $tlsstring = "-TLS"
        }

		if ($Port -eq "16993")
        {
             $tlsstring = "-TLS"
        }
		
		$acceptSelfSigned = ""
        if ($AcceptSelfSignedCert.IsPresent)
        {
            $acceptSelfSigned = "-AcceptSelfSignedCert"
        }
        
		if($CertificateName.Length -gt 0)
		{
			$Connection.Options.SetClientCertificateByCertificateName($CertificateName)
		}

	
		$global:Results = @()
		$rand = New-Object System.Random
        
        ForEach ($Comp in $ComputerName) {
            $tempAMTPSDrive = "AMTDrive"+$rand.next()
            $CannotConnect = $False
            if ($Credential.username.Length -gt 0){
                $expression = "New-PSDrive -Name $tempAMTPSDrive -PSProvider AmtSystem -Root `"\`" -ComputerName `$Comp -Credential `$Credential $tlsstring $acceptSelfSigned -ea Stop"
            } else {
                $expression = "New-PSDrive -Name $tempAMTPSDrive -PSProvider AmtSystem -Root `"\`" -ComputerName `$Comp $tlsstring $acceptSelfSigned -ea Stop"
            }
		try{
 			$null = invoke-expression $expression	
		}
		catch{
			if($_.FullyQualifiedErrorId -eq "WsmanUnauthorizedException,Microsoft.PowerShell.Commands.NewPSDriveCommand")
			{
				Write-Output "Unauthorized to connect to $Comp : Incorrect username or password"
			}

			if($_.FullyQualifiedErrorId -eq "NewDriveProviderException,Microsoft.PowerShell.Commands.NewPSDriveCommand")
			{
				Write-Output "Could not connect to host $Comp : Check Name or IP address"
			}
		    $CannotConnect = $True
	    }

 
		if($CannotConnect -ne $true)
		{
			$temp = $tempAMTPSDrive+":\HardwareAssets"
			traverse $temp 0 
			if (!$TextOutput.IsPresent){
				Write-Output $Results
			}	            			
	            Remove-PSDrive $tempAMTPSDrive
	    	}

		}

	}
}

# SIG # Begin signature block
# MIIoqAYJKoZIhvcNAQcCoIIomTCCKJUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC69zKSxRM02CiS
# j0BDjmlJFORcc8se1TtQ+Kc/OC1K3qCCEe8wggWIMIIEcKADAgECAhAK3oEU12eb
# Bm8tst/S9nrCMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# ExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoT
# D1NlY3RpZ28gTGltaXRlZDEkMCIGA1UEAxMbU2VjdGlnbyBSU0EgQ29kZSBTaWdu
# aW5nIENBMB4XDTIxMDQwNTAwMDAwMFoXDTIzMDQwNTIzNTk1OVowcDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgMCkNhbGlmb3JuaWExFDASBgNVBAcMC1NhbnRhIENsYXJh
# MRowGAYDVQQKDBFJbnRlbCBDb3Jwb3JhdGlvbjEaMBgGA1UEAwwRSW50ZWwgQ29y
# cG9yYXRpb24wggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQDjUVXd0eS2
# a1cJleh4bp6C5ngpid1fyZl3x1O7UH31slBxqjtjD45nsKBbDATVW/ZH0zqbLQ0P
# pQLpLbBVHEFasianjtLSjFXs1pJJ14rfuZCyiOaFFCGYqb/fLQ2ZBq/0riDFgwfC
# YS80SIV7V+hq+XJhpsUms/5QPqRilRnk+OPlbikQktkUVWi1qN7pkjkC5NgTDLnz
# oxGP3OYA6x+ac3/NMQYnRXzbjACLUq70L2hDC8sDwaCQXavaUG29FF4MjwE8MzMx
# DqcjpZmaO/jbTpExgMBfkDa+vqWSb99gdAeJI/JZXAeuYgGQ+66aIhwmRGsqQIXT
# z4ofo+mRQMgSXatXEOtuBrC5q5GZUnWTTrdfnkdxg0oD9CsttmZg6Fhu5mTLYbJ+
# lKrV/JtSjKNgtQdYXCtnV5FRRzlqcjXqsXG+Q1YaY/n0lTEwCAqJyRMyJLuK/S/U
# MUfPw9BvDQbpyB3ARSD4FJ3glwv9UDKd/BmQ2SVGpS+3/7whm633YIMCAwEAAaOC
# AZAwggGMMB8GA1UdIwQYMBaAFA7hOqhTOjHVir7Bu61nGgOFrTQOMB0GA1UdDgQW
# BBS5qxx6xBgtLKbRn3jrB6dtnHz6VDAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/
# BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhCAQEEBAMCBBAwSgYD
# VR0gBEMwQTA1BgwrBgEEAbIxAQIBAwIwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9z
# ZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQQBMEMGA1UdHwQ8MDowOKA2oDSGMmh0dHA6
# Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5nQ0EuY3JsMHMG
# CCsGAQUFBwEBBGcwZTA+BggrBgEFBQcwAoYyaHR0cDovL2NydC5zZWN0aWdvLmNv
# bS9TZWN0aWdvUlNBQ29kZVNpZ25pbmdDQS5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6
# Ly9vY3NwLnNlY3RpZ28uY29tMA0GCSqGSIb3DQEBCwUAA4IBAQBAdvRj4EEZ88QF
# gAGQZABeZB6XbzWNZaFrDGmZMTqREok2QqB6QxdyPSsAFEL5mVfwnD5f8F8iHx+W
# aZXjKHbSvn1f1CAMFMc/i7Byrr984Obp2raebwFNRUO7l2lewLCgkRBlb3+W7Hud
# eTGoTzhJL/Qcvy1jLT0VmhLJbvYjEpBuQ62z7MQH7HltsfjRnDu1RpqKsYWJuCt6
# tOSNn7MZ8vb5nsZEIqRoonucy4Yp1ItP/uXuLc4KcdLh+TzNUiXWWK6qQ6TqeeJp
# Z34IjoS1FvjXLV4ACypUuUvmEIq691NseI4ByVHCZyMa59A6Scpp+kadDUEw0LZj
# t9LGvtWIMIIF9TCCA92gAwIBAgIQHaJIMG+bJhjQguCWfTPTajANBgkqhkiG9w0B
# AQwFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNV
# BAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsx
# LjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkw
# HhcNMTgxMTAyMDAwMDAwWhcNMzAxMjMxMjM1OTU5WjB8MQswCQYDVQQGEwJHQjEb
# MBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgw
# FgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNBIENv
# ZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAIYi
# jTKFehifSfCWL2MIHi3cfJ8Uz+MmtiVmKUCGVEZ0MWLFEO2yhyemmcuVMMBW9aR1
# xqkOUGKlUZEQauBLYq798PgYrKf/7i4zIPoMGYmobHutAMNhodxpZW0fbieW15dR
# hqb0J+V8aouVHltg1X7XFpKcAC9o95ftanK+ODtj3o+/bkxBXRIgCFnoOc2P0tbP
# BrRXBbZOoT5Xax+YvMRi1hsLjcdmG0qfnYHEckC14l/vC0X/o84Xpi1VsLewvFRq
# nbyNVlPG8Lp5UEks9wO5/i9lNfIi6iwHr0bZ+UYc3Ix8cSjz/qfGFN1VkW6KEQ3f
# BiSVfQ+noXw62oY1YdMCAwEAAaOCAWQwggFgMB8GA1UdIwQYMBaAFFN5v1qqK0rP
# VIDh2JvAnfKyA2bLMB0GA1UdDgQWBBQO4TqoUzox1Yq+wbutZxoDha00DjAOBgNV
# HQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHSUEFjAUBggrBgEF
# BQcDAwYIKwYBBQUHAwgwEQYDVR0gBAowCDAGBgRVHSAAMFAGA1UdHwRJMEcwRaBD
# oEGGP2h0dHA6Ly9jcmwudXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZp
# Y2F0aW9uQXV0aG9yaXR5LmNybDB2BggrBgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKG
# M2h0dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENB
# LmNydDAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkq
# hkiG9w0BAQwFAAOCAgEATWNQ7Uc0SmGk295qKoyb8QAAHh1iezrXMsL2s+Bjs/th
# AIiaG20QBwRPvrjqiXgi6w9G7PNGXkBGiRL0C3danCpBOvzW9Ovn9xWVM8Ohgyi3
# 3i/klPeFM4MtSkBIv5rCT0qxjyT0s4E307dksKYjalloUkJf/wTr4XRleQj1qZPe
# a3FAmZa6ePG5yOLDCBaxq2NayBWAbXReSnV+pbjDbLXP30p5h1zHQE1jNfYw08+1
# Cg4LBH+gS667o6XQhACTPlNdNKUANWlsvp8gJRANGftQkGG+OY96jk32nw4e/gdR
# EmaDJhlIlc5KycF/8zoFm/lv34h/wCOe0h5DekUxwZxNqfBZslkZ6GqNKQQCd3xL
# S81wvjqyVVp4Pry7bwMQJXcVNIr5NsxDkuS6T/FikyglVyn7URnHoSVAaoRXxrKd
# sbwcCtp8Z359LukoTBh+xHsxQXGaSynsCz1XUNLK3f2eBVHlRHjdAd6xdZgNVCT9
# 8E7j4viDvXK6yz067vBeF5Jobchh+abxKgoLpbn0nu6YMgWFnuv5gynTxix9vTp3
# Los3QqBqgu07SqqUEKThDfgXxbZaeTMYkuO1dfih6Y4KJR7kHvGfWocj/5+kUZ77
# OYARzdu1xKeogG/lU9Tg46LC0lsa+jImLWpXcBw8pFguo/NbSwfcMlnzh6cabVgw
# ggZmMIIETqADAgECAhMzAAAARLc//O9az6J6AAAAAABEMA0GCSqGSIb3DQEBBQUA
# MH8xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAMT
# IE1pY3Jvc29mdCBDb2RlIFZlcmlmaWNhdGlvbiBSb290MB4XDTE1MDcyMjIxMDM0
# OVoXDTI1MDcyMjIxMDM0OVowgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcg
# SmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJU
# UlVTVCBOZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgUlNBIENlcnRpZmljYXRp
# b24gQXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAgBJl
# FzYOw9sIs9CsVw127c0n00ytUINh4qogTQktZAnczomfzD2p7PbPwdzx07HWezco
# EStH2jnGvDoZtF+mvX2do2NCtnbyqTsrkfjib9DsFiCQCT7i6HTJGLSR1GJk23+j
# BvGIGGqQIjy8/hPwhxR79uQfjtTkUcYRZ0YIUcuGFFQ/vDP+fmyc/xadGL1RjjWm
# p2bIcmfbIWax1Jt4A8BQOujM8Ny8nkz+rwWWNR9XWrf/zvk9tyy29lTdyOcSOk2u
# TIq3XJq0tyA9yn8iNK5+O2hmAUTnAU5GU5szYPeUvlM3kHND8zLDU+/bqv50TmnH
# a4xgk97Exwzf4TKuzJM7UXiVZ4vuPVb+DNBpDxsP8yUmazNt925H+nND5X4OpWax
# KXwyhGNVicQNwZNUMBkTrNN9N6frXTpsNVzbQdcS2qlJC9/YgIoJk2KOtWbPJYjN
# hLixP6Q5D9kCnusSTJV882sFqV4Wg8y4Z+LoE53MW4LTTLPtW//e5XOsIzstAL81
# VXQJSdhJWBp/kjbmUZIO8yZ9HE0XvMnsQybQv0FfQKlERPSZ51eHnlAfV1SoPv10
# Yy+xUGUJ5lhCLkMaTLTwJUdZ+gQek9QmRkpQgbLevni3/GcV4clXhB4PY9bpYrrW
# X1Uu6lzGKAgEJTm4Diup8kyXHAc/DVL17e8vgg8CAwEAAaOB0DCBzTATBgNVHSUE
# DDAKBggrBgEFBQcDAzASBgNVHRMBAf8ECDAGAQH/AgECMB0GA1UdDgQWBBRTeb9a
# qitKz1SA4dibwJ3ysgNmyzALBgNVHQ8EBAMCAYYwHwYDVR0jBBgwFoAUYvsKIVt/
# Q24R2glUUGv10pZx8Z4wVQYDVR0fBE4wTDBKoEigRoZEaHR0cDovL2NybC5taWNy
# b3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0Q29kZVZlcmlmUm9v
# dC5jcmwwDQYJKoZIhvcNAQEFBQADggIBAGsikzw9OVRxZGsO8uQ8MBHFIEpLhg+S
# 8f8zeTrZ5JinDkCgIoB+YbLgpxnPJpUxKmXUak8xhurAxi7FZIw9SFnNCy90PZQm
# ExBC1JeYJ148dtJ4aR0aZOcFcnXg62ZAQ5+PDEb/l2CmyGetEAibYqbpvjqK0wdN
# n3KTJbwGEeAskDg+Zxz9GdeekM49wuDnYazA5QT1HplUDJENAVZxN64n1J5DIqXJ
# J81N5XESOSSlQVaH/7xVFA8lyonux5fl0hP/PX4aoI8/yCzXo3DQx2DA/Ng+UeeX
# xj477c94vorK48Typ6ftnq4IAo+gUttyHtU7w02fjvqbcMf4479sP5Kb5Dc+7GqM
# KfnBor+LPhppZvscY08mAckCxD7S/8NDqBv9mfrUvKW54pMvOwHF0fQ6L2jD4GS3
# WpVeRswHg2m7PAWSVnM1c0WYTnzYEqW3QumiY/ZCYBhw0TtvMcCHx+Zx4fNGFun1
# uHKz6W0fYiZJo0mL3WjHi2hW9978+ockuAOBF4/l8WdqHa7TdPeMpV2zC45CKZbO
# ScR3fmZ8ARcabBQkw7AXdwXYGkC3hmvY5HtArH7fTm8k+SCAgowz5+X6Kdid2otw
# XSvJHYJMC2fLhEGe5wZ+EYNELYoZ7vR/mt15HDcZHp8/jCm6DVwQhjdsSM1FXc1w
# vLzRTV3Yxbh2MYIWDzCCFgsCAQEwgZAwfDELMAkGA1UEBhMCR0IxGzAZBgNVBAgT
# EkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMP
# U2VjdGlnbyBMaW1pdGVkMSQwIgYDVQQDExtTZWN0aWdvIFJTQSBDb2RlIFNpZ25p
# bmcgQ0ECEAregRTXZ5sGby2y39L2esIwDQYJYIZIAWUDBAIBBQCgfDAQBgorBgEE
# AYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgu5KCIojmbsI4XGRL
# ElXhoS2HNoGhjJdedvJgTpWsX3AwDQYJKoZIhvcNAQEBBQAEggGAi+bW1RZ1lg7F
# sQ+k5NXW8hr3kUAQWv5KQDsh1tskWVuXHCSmEHgmfGtWRUqB9OgMNrYh4cgHexZZ
# zXyGqh5uaC7BQTf8LqRRRYxFTlw3IAwVGj2JbxbsfMPq+xrU5PzK4pP6NxyPA7zH
# FNWoGL5rNMmKV0DElRUMyTRvBl/fCA0jCgE6jPQYDo0X8evoedyGxAEHQKGdjAQM
# P1MyOaPY4XrSzzJbEFUfO30jeAKYIKC1jMIlgJOxTu3VU8LCm7VZlChgjyjlHDRs
# HgM0TrNLqsBWVuQqr0DREgONek/VPCsiKqEjnOCRhor275OVTWL/r+yFAj8eXqR9
# 7Xp3GDDMLJBcw58Xl/QLcQANejY/DtLSCIC+RU/zZzBL+8LJxVfB1W4GcU1GgeGN
# gEIYJ8BeiSHqlhogLQWOFshcRjfqL23m/CZ9PfP/Eg6cdaNM/ZP00aHQSkskFbpC
# 7lY/fZ64m7p2ptNzwn7K+wvIkt+kRGPCsbtSdp7sjnfpoK4wghstoYITUTCCE00G
# CisGAQQBgjcDAwExghM9MIITOQYJKoZIhvcNAQcCoIITKjCCEyYCAQMxDzANBglg
# hkgBZQMEAgIFADCB8AYLKoZIhvcNAQkQAQSggeAEgd0wgdoCAQEGCisGAQQBsjEC
# AQEwMTANBglghkgBZQMEAgEFAAQg+40qZHGmvycqngyxJyZ83ibdpFpJyTmax4/F
# xiFZNJACFQCXRlfVjNo2cTx+fvW5r+v0jPmGzxgPMjAyMzA0MDQxNDMyMDhaoG6k
# bDBqMQswCQYDVQQGEwJHQjETMBEGA1UECBMKTWFuY2hlc3RlcjEYMBYGA1UEChMP
# U2VjdGlnbyBMaW1pdGVkMSwwKgYDVQQDDCNTZWN0aWdvIFJTQSBUaW1lIFN0YW1w
# aW5nIFNpZ25lciAjM6CCDeowggb2MIIE3qADAgECAhEAkDl/mtJKOhPyvZFfCDip
# QzANBgkqhkiG9w0BAQwFADB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRl
# ciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdv
# IExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0Ew
# HhcNMjIwNTExMDAwMDAwWhcNMzMwODEwMjM1OTU5WjBqMQswCQYDVQQGEwJHQjET
# MBEGA1UECBMKTWFuY2hlc3RlcjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSww
# KgYDVQQDDCNTZWN0aWdvIFJTQSBUaW1lIFN0YW1waW5nIFNpZ25lciAjMzCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJCycT954dS5ihfMw5fCkJRy7Vo6
# bwFDf3NaKJ8kfKA1QAb6lK8KoYO2E+RLFQZeaoogNHF7uyWtP1sKpB8vbH0uYVHQ
# jFk3PqZd8R5dgLbYH2DjzRJqiB/G/hjLk0NWesfOA9YAZChWIrFLGdLwlslEHzld
# nLCW7VpJjX5y5ENrf8mgP2xKrdUAT70KuIPFvZgsB3YBcEXew/BCaer/JswDRB8W
# KOFqdLacRfq2Os6U0R+9jGWq/fzDPOgNnDhm1fx9HptZjJFaQldVUBYNS3Ry7qAq
# MfwmAjT5ZBtZ/eM61Oi4QSl0AT8N4BN3KxE8+z3N0Ofhl1tV9yoDbdXNYtrOnB78
# 6nB95n1LaM5aKWHToFwls6UnaKNY/fUta8pfZMdrKAzarHhB3pLvD8Xsq98tbxpU
# UWwzs41ZYOff6Bcio3lBYs/8e/OS2q7gPE8PWsxu3x+8Iq+3OBCaNKcL//4dXqTz
# 7hY4Kz+sdpRBnWQd+oD9AOH++DrUw167aU1ymeXxMi1R+mGtTeomjm38qUiYPvJG
# DWmxt270BdtBBcYYwFDk+K3+rGNhR5G8RrVGU2zF9OGGJ5OEOWx14B0MelmLLsv0
# ZCxCR/RUWIU35cdpp9Ili5a/xq3gvbE39x/fQnuq6xzp6z1a3fjSkNVJmjodgxpX
# fxwBws4cfcz7lhXFAgMBAAGjggGCMIIBfjAfBgNVHSMEGDAWgBQaofhhGSAPw0F3
# RSiO0TVfBhIEVTAdBgNVHQ4EFgQUJS5oPGuaKyQUqR+i3yY6zxSm8eAwDgYDVR0P
# AQH/BAQDAgbAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgw
# SgYDVR0gBEMwQTA1BgwrBgEEAbIxAQIBAwgwJTAjBggrBgEFBQcCARYXaHR0cHM6
# Ly9zZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQQCMEQGA1UdHwQ9MDswOaA3oDWGM2h0
# dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1JTQVRpbWVTdGFtcGluZ0NBLmNy
# bDB0BggrBgEFBQcBAQRoMGYwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQuc2VjdGln
# by5jb20vU2VjdGlnb1JTQVRpbWVTdGFtcGluZ0NBLmNydDAjBggrBgEFBQcwAYYX
# aHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEMBQADggIBAHPa7Why
# y8K5QKExu7QDoy0UeyTntFsVfajp/a3Rkg18PTagadnzmjDarGnWdFckP34PPNn1
# w3klbCbojWiTzvF3iTl/qAQF2jTDFOqfCFSr/8R+lmwr05TrtGzgRU0ssvc7O1q1
# wfvXiXVtmHJy9vcHKPPTstDrGb4VLHjvzUWgAOT4BHa7V8WQvndUkHSeC09NxKoT
# j5evATUry5sReOny+YkEPE7jghJi67REDHVBwg80uIidyCLxE2rbGC9ueK3EBbTo
# hAiTB/l9g/5omDTkd+WxzoyUbNsDbSgFR36bLvBk+9ukAzEQfBr7PBmA0QtwuVVf
# R745ZM632iNUMuNGsjLY0imGyRVdgJWvAvu00S6dOHw14A8c7RtHSJwialWC2fK6
# CGUD5fEp80iKCQFMpnnyorYamZTrlyjhvn0boXztVoCm9CIzkOSEU/wq+sCnl6jq
# tY16zuTgS6Ezqwt2oNVpFreOZr9f+h/EqH+noUgUkQ2C/L1Nme3J5mw2/ndDmbhp
# LXxhL+2jsEn+W75pJJH/k/xXaZJL2QU/bYZy06LQwGTSOkLBGgP70O2aIbg/r6ay
# UVTVTMXKHxKNV8Y57Vz/7J8mdq1kZmfoqjDg0q23fbFqQSduA4qjdOCKCYJuv+P2
# t7yeCykYaIGhnD9uFllLFAkJmuauv2AV3Yb1MIIG7DCCBNSgAwIBAgIQMA9vrN1m
# mHR8qUY2p3gtuTANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVU
# aGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTkwNTAyMDAwMDAwWhcNMzgwMTE4MjM1
# OTU5WjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAj
# BgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQDIGwGv2Sx+iJl9AZg/IJC9nIAhVJO5z6A+U++z
# WsB21hoEpc5Hg7XrxMxJNMvzRWW5+adkFiYJ+9UyUnkuyWPCE5u2hj8BBZJmbyGr
# 1XEQeYf0RirNxFrJ29ddSU1yVg/cyeNTmDoqHvzOWEnTv/M5u7mkI0Ks0BXDf56i
# XNc48RaycNOjxN+zxXKsLgp3/A2UUrf8H5VzJD0BKLwPDU+zkQGObp0ndVXRFzs0
# IXuXAZSvf4DP0REKV4TJf1bgvUacgr6Unb+0ILBgfrhN9Q0/29DqhYyKVnHRLZRM
# yIw80xSinL0m/9NTIMdgaZtYClT0Bef9Maz5yIUXx7gpGaQpL0bj3duRX58/Nj4O
# MGcrRrc1r5a+2kxgzKi7nw0U1BjEMJh0giHPYla1IXMSHv2qyghYh3ekFesZVf/Q
# OVQtJu5FGjpvzdeE8NfwKMVPZIMC1Pvi3vG8Aij0bdonigbSlofe6GsO8Ft96XZp
# kyAcSpcsdxkrk5WYnJee647BeFbGRCXfBhKaBi2fA179g6JTZ8qx+o2hZMmIklnL
# qEbAyfKm/31X2xJ2+opBJNQb/HKlFKLUrUMcpEmLQTkUAx4p+hulIq6lw02C0I3a
# a7fb9xhAV3PwcaP7Sn1FNsH3jYL6uckNU4B9+rY5WDLvbxhQiddPnTO9GrWdod6V
# QXqngwIDAQABo4IBWjCCAVYwHwYDVR0jBBgwFoAUU3m/WqorSs9UgOHYm8Cd8rID
# ZsswHQYDVR0OBBYEFBqh+GEZIA/DQXdFKI7RNV8GEgRVMA4GA1UdDwEB/wQEAwIB
# hjASBgNVHRMBAf8ECDAGAQH/AgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBEGA1Ud
# IAQKMAgwBgYEVR0gADBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLnVzZXJ0
# cnVzdC5jb20vVVNFUlRydXN0UlNBQ2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmww
# dgYIKwYBBQUHAQEEajBoMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVz
# dC5jb20vVVNFUlRydXN0UlNBQWRkVHJ1c3RDQS5jcnQwJQYIKwYBBQUHMAGGGWh0
# dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQEMBQADggIBAG1UgaUz
# XRbhtVOBkXXfA3oyCy0lhBGysNsqfSoF9bw7J/RaoLlJWZApbGHLtVDb4n35nwDv
# QMOt0+LkVvlYQc/xQuUQff+wdB+PxlwJ+TNe6qAcJlhc87QRD9XVw+K81Vh4v0h2
# 4URnbY+wQxAPjeT5OGK/EwHFhaNMxcyyUzCVpNb0llYIuM1cfwGWvnJSajtCN3wW
# eDmTk5SbsdyybUFtZ83Jb5A9f0VywRsj1sJVhGbks8VmBvbz1kteraMrQoohkv6o
# b1olcGKBc2NeoLvY3NdK0z2vgwY4Eh0khy3k/ALWPncEvAQ2ted3y5wujSMYuaPC
# Rx3wXdahc1cFaJqnyTdlHb7qvNhCg0MFpYumCf/RoZSmTqo9CfUFbLfSZFrYKiLC
# S53xOV5M3kg9mzSWmglfjv33sVKRzj+J9hyhtal1H3G/W0NdZT1QgW6r8NDT/LKz
# H7aZlib0PHmLXGTMze4nmuWgwAxyh8FuTVrTHurwROYybxzrF06Uw3hlIDsPQaof
# 6aFBnf6xuKBlKjTg3qj5PObBMLvAoGMs/FwWAKjQxH/qEZ0eBsambTJdtDgJK0kH
# qv3sMNrxpy/Pt/360KOE2See+wFmd7lWEOEgbsausfm2usg1XTN2jvF8IAwqd661
# ogKGuinutFoAsYyr4/kKyVRd1LlqdJ69SK6YMYIELTCCBCkCAQEwgZIwfTELMAkG
# A1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMH
# U2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSUwIwYDVQQDExxTZWN0
# aWdvIFJTQSBUaW1lIFN0YW1waW5nIENBAhEAkDl/mtJKOhPyvZFfCDipQzANBglg
# hkgBZQMEAgIFAKCCAWswGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMBwGCSqG
# SIb3DQEJBTEPFw0yMzA0MDQxNDMyMDhaMD8GCSqGSIb3DQEJBDEyBDBLdvgBMPS1
# ZqWM5yvJREnghM7NreQy+032AO3bQ43JGSI0papnbdQG2ZOJARew1Gcwge0GCyqG
# SIb3DQEJEAIMMYHdMIHaMIHXMBYEFKs0ATqsQJcxnwga8LMY4YP4D3iBMIG8BBQC
# 1luV4oNwwVcAlfqI+SPdk3+tjzCBozCBjqSBizCBiDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQK
# ExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0Eg
# Q2VydGlmaWNhdGlvbiBBdXRob3JpdHkCEDAPb6zdZph0fKlGNqd4LbkwDQYJKoZI
# hvcNAQEBBQAEggIAW4tGsyhtnF5rmfoi31xBo96Ewr0aq3bQxYyQ+Kkad+lanKZv
# VM/zgOt3NmTxezI31BXxvmlpfchSqTjYVXz60E6cMRT+zH8+e2e2I6KItMkD2H8u
# ZbcpDDBPwYrE1CNVlXU6/6s5ZOXIHFsQidFYdIDBVRKy62kqCHUBS+0qWmzpxnNy
# 6SYohJznPx86MN7rGlr/w7vxPpIegO5BjHSSqx2KO+0IuoeVqgNMzqDkuECGPr1e
# KtyWQwV93EOA4uVObKzuG0YAkP0kob0cWF2382HJMStRDlhTb5AG3x8ycb0mSeg1
# TNsX9+b3ETm0RDXsTtATi8T1F24/QUYzVQfb17Y+2occeSjq6hI7A2YoLsVZARJ8
# 7E8st2klrk3HmBBs8LdyDT7P4oft4DSTvP04JutAfRBx7J/u8jHeHvVr8/2N4s0l
# +85aGlk2HNzZK3ILy9F/9+4DIKzHHBCs7y2kODVz6LBTRFQ/TJWQUB7/+aWtm3bK
# APGNrQuwD7BezQWxAUPZX0K4ZB7OGJEuZjN1LVaYzn/KI6efcsF6hWMNnEZBLEj7
# rFTxV7Q7ZjLrl64iuVaWXFXIfW51S2aNhZX8A6lwKiQB2PnT6zsDgLclkQ/iX7U8
# iqJqB3xiRQdChJFhQNG+2zFjWXktkx4I1Ud8nNSZYFm8VF88mxi5fv+Qn7o=
# SIG # End signature block
