# Deon van Zyl
# This will remove all solutions in a SharePoint Site
######################################
######## Set Variables ###############
######################################
$InstallDIR = "F:\wsp"
 
######################################
#### CODE, No Changes Necessary ######
######################################
Write-Host "Working, Please wait...."
Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue
 
$Dir = get-childitem $InstallDIR -Recurse
$WSPList = $Dir | where {$_.Name -like "*.wsp*"}
Foreach ($wsp in $WSPList )
{
	$WSPFullFileName = $wsp.FullName
	$WSPFileName = $wsp.Name
	clear
	Write-Host -ForegroundColor White -BackgroundColor Blue "Working on $WSPFileName" 
 
	try
	{
		Write-Host -ForegroundColor Green "Checking Status of Solution"
		$output = Get-SPSolution -Identity $WSPFileName -ErrorAction Stop
	}
	Catch
	{
		$DoesSolutionExists = $_
	}
	If (($DoesSolutionExists -like "*Cannot find an SPSolution*") -and ($output.Name -notlike  "*$WSPFileName*"))
	{
		Try
		{
			#do nothing
		}
		Catch
		{
			Write-Error $_
			Write-Host -ForegroundColor Red "Skipping $WSPFileName, Due to an error"
			Read-Host
		}
	}
	Else
	{
		$skip = $null
		$tryagain = $null
		Try
		{
			if ($output.Deployed -eq $true)
			{
			Write-Host -ForegroundColor Green "Retracting Solution"
			#Site you want to target
			Uninstall-SPSolution -WebApplication "https://somesite.com" -Identity $WSPFileName -Confirm:$false -ErrorAction Stop
			}
		}
		Catch
		{
			$tryagain = $_
		}
		Try
		{
			if ($tryagain -ne $null)
			{
				Uninstall-SPSolution -Identity $WSPFileName -Confirm:$false -ErrorAction Stop
			}
		}
		Catch
		{
			Write-Host -ForegroundColor Red "Could not Retract Solution"
		}
 
		Sleep 1
		$dpjobs = Get-SPTimerJob | Where { $_.Name -like "*$WSPFileName*" }
		If ($dpjobs -eq $null)
    	{
        	Write-Host -ForegroundColor Green "No solution deployment jobs found"
    	}
		Else
		{
			If ($dpjobs -is [Array])
			{
				Foreach ($job in $dpjobs)
				{
					$jobName = $job.Name
					While ((Get-SPTimerJob $jobName -Debug:$false) -ne $null)
					{
						Write-Host -ForegroundColor Yellow -NoNewLine "."
						Start-Sleep -Seconds 5
					}
					Write-Host
				}
			}
    		Else
    		{
				$jobName = $dpjobs.Name
				While ((Get-SPTimerJob $jobName -Debug:$false) -ne $null)
				{
					Write-Host -ForegroundColor Yellow -NoNewLine "."
					Start-Sleep -Seconds 5
				}
				Write-Host
    		}
		}		
        
		Try
		{
			Write-Host -ForegroundColor Green "Removing Solution from farm"
			Remove-SPSolution -Identity $WSPFileName -Confirm:$false -ErrorAction Stop
		}
		Catch
		{
			$skip = $_
			Write-Host -ForegroundColor Red "Could not Remove Solution"
			Read-Host
		}
		
    }
}