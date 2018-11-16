﻿<#
.Synopsis
    Gets passwords from dinopass.com website.
	
.Description
    The dinopass Cmdlet downloads passwords from the kids passwords generator website dinopas.com. 
    
    These passwords can be created singly or in bulk, with simple or strong password complexity and displayed on screen or exported to CSV.

.Notes
    File Name      : dinopass.ps1
    Author         : Tyrone Wyatt (tyrone.wyatt@gmail.com)
    Prerequisite   : PowerShell V3 over Windows 7 and upper
    Copyright      : Tyrone Wyatt 2018
	Version        : 1.4
	Creation Date  : 16/11/2018
	Purpose/Change : First stable build cmdlet with general enhancements

.link
    Repository     : https://github.com/tyronewyatt/PowerShell-Scripts/

.Example
	# Create a simple password
    dinopass

.Example
	# Create 5 strong passwords
    dinopass -quantity 5 -strong

.Example
	# Create 30 strong passwords and export to CSV
    dinopass -quantity 30 -strong -outfile '.\passwords.csv'
 #>
Function dinopass
{
	# Set varibles
	Param(
		[Int]$Quantity = '1',
		[switch]$Strong,
		[string]$OutFile
	)

	# Set default password strength
	If ($Strong -Eq $True) {$Strength = 'strong'} Else {$Strength = 'simple'}

	# Set dinopass API URL
	$DinoPassURL = 'https://dinopass.com/password'

	# Generate multiple passwords from website
	$Passwords = For( ` 
			$Counter=1
			$Counter -le $Quantity
			$Counter++ `
			) {Invoke-WebRequest $DinoPassURL/$Strength}

	# Change title from Content to Password
	$Passwords = $Passwords | Add-Member -MemberType AliasProperty -Name Password -Value Content -PassThru

	# Change title from RawContentLength to PasswordLength
	$Passwords = $Passwords | Add-Member -MemberType AliasProperty -Name PasswordLength -Value RawContentLength -PassThru

	# Export to CSV
	If ($OutFile) {$Passwords | Select-Object Password, PasswordLength | Export-CSV -NoTypeInformation -Path $OutFile}

	# Write to Screen
	If (!$OutFile) {Write-Output $Passwords | Select-Object Password}
}
Export-ModuleMember -Function dinopass