Import-Module ActiveDirectory

$WarningPasswordAge = '30'
$OrganisationalUnit = 'OU=Services,OU=Domain Users,DC=tallangatta-sc,DC=vic,DC=edu,DC=au'
$DomainPolicyMaxPasswordAge = ((Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge).Days
$SmtpServer = 'tscmx01.tallangatta-sc.vic.edu.au'
$MailTo = 'Netbook Admin <netbookadmin@tallangatta-sc.vic.edu.au>'
$MailFrom = 'ICT Helpdesk <ict.helpdesk@tallangatta-sc.vic.edu.au>'
$MailSignature = `
"ICT Helpdesk
Tallangatta Secondary College
145 Towong Street Tallangatta, 3700, VIC
t: 02 6071 5000 | f: 02 6071 2445
e: ict.helpdesk@tallangatta-sc.vic.edu.au
w: www.tallangatta-sc.vic.edu.au"

$Users = Get-ADUser `
	-SearchBase $OrganisationalUnit `
	-Filter {Enabled -eq $True -And PasswordNeverExpires -eq $False} `
	-Properties samAccountName,pwdLastSet,msDS-UserPasswordExpiryTimeComputed

ForEach ($User In $Users)
{
	$AccountName = $User.'samAccountName'.ToUpper()
	$pwdLastSet = $User.'pwdLastSet'
	$UserPasswordExpiryTimeComputed = $User.'msDS-UserPasswordExpiryTimeComputed'
	
	If ($UserPasswordExpiryTimeComputed -ne $Null)
	{
	$UserPasswordExpiryTime = [datetime]::fromFileTime($UserPasswordExpiryTimeComputed)
	$DaysToExipre = (New-TimeSpan -Start (Get-Date) -End $UserPasswordExpiryTime).Days
	}
	ElseIf ($DomainPolicyMaxPasswordAge -ne $Null)
	{
	$pwdLastSet = [datetime]::fromFileTime($pwdLastSet)
	$PasswordAgeDays = (New-TimeSpan -Start $pwdLastSet -End (Get-Date)).Days
	$DaysToExipre = $DomainPolicyMaxPasswordAge-$PasswordAgeDays
	}
	Else
	{
	$DaysToExipre = $Null
	}
	
	$DaysExpired = $DaysToExipre.ToString().SubString(1)
	
If 	($Users | Where-Object `
		{ `
		$DaysToExipre -le $WarningPasswordAge
		}
	)
	{
	If ($DaysToExipre -le '-2')
		{
		Write-Host "$AccountName password expired $DaysExpired days ago."
		$MailBody += @("`n$AccountName password expired $DaysExpired days ago.")
		}
	ElseIf ($DaysToExipre -eq '-1')
		{
		Write-Host "$AccountName password expired yesterday."
		$MailBody += @("`n$AccountName password expired yesterday.")
		}
	ElseIf ($DaysToExipre -eq '0')
		{
		Write-Host "$AccountName password expired today."
		$MailBody += @("`n$AccountName password expired today.")
		}
	ElseIf ($DaysToExipre -eq '1')
		{
		Write-Host "$AccountName password expires tomorrow."
		$MailBody += @("`n$AccountName password expires tomorrow.")
		}
	ElseIf ($DaysToExipre -ge '2')
		{
		Write-Host "$AccountName password expires in $DaysToExipre days."
		$MailBody += @("`n$AccountName password expires in $DaysToExipre days.")
		} 
	}
}

If ($MailBody -ne $Null)
	{
	$NumberAccountsDisabled = ($MailBody).count
	If ($NumberAccountsDisabled -eq '1') 
		{
		$MailSubject = "Password change required for 1 service account"
		$MailHeading = "The following service account require your attention:"
		}
	Else
		{
		$MailSubject = "Password change required for $NumberAccountsDisabled service accounts"
		$MailHeading = "The following service accounts require your attention:"
		}
	ForEach ($MailBody In $MailBodys)
		{
		$MailBody = $MailBody
		}
		
$MailBody = `
"Hello Administrator,

$MailHeading
$MailBody

$MailSignature"	
		
	Send-MailMessage `
		-To "$MailTo" `
		-From "$MailFrom" `
		-Subject "$MailSubject" `
		-SmtpServer "$SmtpServer" `
		-Body "$MailBody"
	}
