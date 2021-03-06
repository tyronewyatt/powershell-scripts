<#
.SYNOPSIS
    Convert Compass OnDemand export from a former school to new school.
.DESCRIPTION
   Perform an export on OnDemand data following the Compass guide from a former school.
   The student key in the export from the former school won't match student key of the new school.
   Use this script with the eduHub ST_xxxx.csv files of both schools to convert student cNAPes with matching VSN numbers.
.NOTES
    File Name      : ST_NAPLAN-Questions.ps1
    Author         : T Wyatt (wyatt.tyrone.e@edumail.vic.gov.au)
    Prerequisite   : PowerShell V2 over Vista and upper.
    Copyright      : 2018 - Tyrone Wyatt / Department of Education Victoria
.LINK
    Repository     : https://github.com/tyronewyatt/PowerShell-Scripts/
.EXAMPLE
    .\ST_NAPLAN-Questions.ps1 
.EXAMPLE
    .\ST_NAPLAN-Questions.ps1 -oldschoolid 6229 -newschoolid 8370 
 #>
Param(
	[String]$OldSchoolID = $(Read-Host 'Enter Old School ID (XXXX)'),
	[String]$NewSchoolID = $(Read-Host 'Enter New School ID (XXXX)'),
	[String]$AppendOutput = $(Read-Host 'Append Output File? (YES/No)')
	)

$Path = (Resolve-Path .\).Path
$OldSTCSV = $Path + '\ST_' + $OldSchoolID + '.csv'
$NewSTCSV = $Path + '\ST_' + $NewSchoolID + '.csv'
$OldNAPCSV = $Path + '\NAP_' + $OldSchoolID + '_Questions.csv'
$NewNAPCSV = $Path + '\NAP_' + $NewSchoolID + '_Questions.csv'

If (-Not($OldSTCSV | Test-Path))
	{Write-Error "$OldSTCSV not found"}
ElseIf (-Not($NewSTCSV | Test-Path))
	{Write-Error "$NewSTCSV not found"}
ElseIf (-Not($OldNAPCSV | Test-Path))
	{Write-Error "$OldNAPCSV not found"}
Else
	{
	$OldSTStudents = Import-Csv -Delimiter "," -Path $OldSTCSV | Where-Object {$_.STATUS -Match 'LVNG|LEFT' -And $_.SCHOOL_YEAR -Eq '06' -And $_.VSN -NotMatch 'NEW|UNKNOWN'}
	$NewSTStudents = Import-Csv -Delimiter "," -Path $NewSTCSV | Where-Object {$_.STATUS -Match 'FUT|ACTV' -And $_.SCHOOL_YEAR -Eq '07' -And $_.VSN -NotMatch 'NEW|UNKNOWN'} 
	$OldNAPStudents = Import-Csv -Delimiter "," -Path $OldNAPCSV
	}

If ($AppendOutput -Match 'False|No|0') 
	{
	Write-Output 'APS Year,Reporting Test,Question Number,Dimension Name,Student Score,Cases ID' | Out-File -FilePath $NewNAPCSV
	}
	
Write-Host 'OldSTStudentKey NewSTStudentKey NewSTStudentVSN'
ForEach ($NewSTStudent In $NewSTStudents)
    {
	$NewSTStudentKey = $NewSTStudent.'STKEY'
	$NewSTStudentVSN = $NewSTStudent.'VSN'
	If (($OldSTStudents | Where-Object {$_.VSN -Eq $NewSTStudentVSN}) -Ne $Null)
		{
		ForEach ($OldSTStudent In $OldSTStudents)
			{
			$OldSTStudentKey = $OldSTStudent.'STKEY'
			$OldSTStudentVSN = $OldSTStudent.'VSN'
			If (($NewSTStudents | Where-Object {$OldSTStudentVSN -Eq $NewSTStudentVSN}) -Ne $Null)
				{
				Write-Host "$OldSTStudentKey $NewSTStudentKey $NewSTStudentVSN"
				ForEach ($OldNAPStudent In $OldNAPStudents)
					{				
					$OldNAPStudentYear = $OldNAPStudent.'APS Year'
					$OldNAPStudentTest = $OldNAPStudent.'Reporting Test'
					$OldNAPStudentQuestion = $OldNAPStudent.'Question Number'
					$OldNAPStudentDimension = $OldNAPStudent.'Dimension Name'
					$OldNAPStudentScore = $OldNAPStudent.'Student Score'
					$OldNAPStudentCasesID = $OldNAPStudent.'Cases ID'
					If ($OldNAPStudentCasesID -Eq $OldSTStudentKey)
						{
						#Write-Host  $OldNAPStudentYear $OldNAPStudentTest $OldNAPStudentQuestion $OldNAPStudentDimension $OldNAPStudentScore $NewSTStudentKey
						Write-Output "$OldNAPStudentYear,$OldNAPStudentTest,$OldNAPStudentQuestion,$OldNAPStudentDimension,$OldNAPStudentScore,$NewSTStudentKey" | Out-File -FilePath $NewNAPCSV -Append
						}
					}
				}
			}
		}
	}
	
	