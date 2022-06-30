<#Note, this only checks if the folder name exists in AD. Some users may have a folder, but their H Drive is not set in HomeDirectory
This will not matter, as their H Drive would not be in use or accessible by the user anyway.
#>

$ErrorActionPreference= "silentlycontinue"
$HDrivefolderBase = "\\hassell.local\USERDATA\UD01\" #Sets the H Drive folder base, in case you ever need to change it.
$userFolders = Get-ChildItem -Path "$HDrivefolderBase" | Where-Object{ $_.PSIsContainer} | select-object -ExpandProperty Name #Gets all subfolders (only) in the $HDriveFolderBase folder.

Foreach($folder in $userFolders) { #loops through each of the $userFolders folders
    if($folder -like "*.HASSELLS" -or "*.ASIA"){  #this part removes any suffixes
        clear-Variable -name "existCheckAsiaBool","ExistCheckHassellBool","ExistCheckTrue","enabledCheckAsia","enabledCheckHassell","enabledCheckAsiaBool","enabledCheckHassellBool","userAsia","userHassell","CSVExportFormatObject"#clears variables to prevent incorrectly logging duplicate data
        $folderRename = ($folder).Replace(".HASSELLS","").replace(".ASIA","").replace(".asia","") #searches and removed the .hassells or .asia suffix from the folder name on line 21
        $userAsia = (Get-ADUser -server AS2-P-DC-03 -filter "homeDirectory -like '*$folderRename*'") #queries the AD Server for the suer, cannot use Global LDAP Catalogue, does not return homeDirectory Data. Therefore storing in it's own variable
        $userHassell = (Get-ADUser -filter "homeDirectory -like '*$folderRename*'") #as above
        $ExistCheckAsiaBool = [boolean]$userAsia #sets the boolean Value of $userAsia to $exist Check Asia. If the user Exists and has data AT ALL, the $ExistCheckAsiabool is set to True
        $ExistCheckHassellBool = [boolean]$userHassell #as above

        if (($ExistCheckAsiaBool -eq $true) -or ($ExistCheckHassellBool -eq $true)) { #Checks the Boolean Value of $ExistCheckAsiabool, or $$ExistCheckHassellBool, if either is True, sets an additional value $ExistCheckTrue to True
            $ExistCheckTrue = $true
            }elseif (($ExistCheckAsiaBool -eq $false) -or ($ExistCheckHassellBool -eq $false)) {#if Does not exist, sets to false, and so it skips the next if statement.
                $ExistCheckTrue = $false
                write-host -ForegroundColor Red "User with homDirectory $folder donesn't exist in AD, Deleting"
                Remove-Item -path "$HDrivefolderBase$folder" -recurse -WhatIf
                #Deletes the folder because the homeDirectory from $folder does not exist anywhere in AD. \
                #Input Delete command here
            }
        if ($ExistCheckTrue -eq $true) { #protip: do not go $existCheckTrue = $true. You may spend 45M Wondering why it's not working. Thank you Tom.)
            #one of the below will error, only one of the users will actually have data inside of it. "Get-ADUser : Cannot validate argument on parameter 'Identity'. The argument is null or an element of the argument collection contains a null value."
            $enabledCheckAsia = (Get-ADUser -Identity $userAsia -properties Enabled).enabled 
            $enabledCheckHassell = (Get-ADUser -Identity $userHassell -properties Enabled).enabled
            if ($enabledCheckAsia -eq $false -or $enabledCheckHassell -eq $false) {
                #Checks if the user is disabled, if disabled, it will go to the next else and delete the folder.
                $enabledCheckAsiaBool = $false
                $enabledCheckHassellBool = $false
                write-host -ForegroundColor Red "User with homeDirectory $folder Exists, but is not Enabled, Deleting."
                Remove-Item -path "$HDrivefolderBase$folder" -recurse -WhatIf
                }else {
                    $enabledCheckAsiaBool = $true
                    $enabledCheckHassellBool = $true
                }
        }
        if ($enabledCheckAsiaBool -eq $true -or $enabledCheckHassellBool -eq $true) {
            write-host -ForegroundColor Green "User with homeDirectory $folder exists and is enabled ignoring folder."
            }else { 
                #area to format the data for export into CSV.
                $PSOPath = (-join("$HDrivefolderBase","$folder")) #Creates and stores the path
                $CSVExportFormatObject = New-Object PSObject #Creates a PSObject to create array of data.
                Add-Member -InputObject $CSVExportFormatObject -MemberType NoteProperty -Name "Path" -Value $PSOPath
            }    
        if (($userAsia).name -ne $null) { #uses -ne $null to log something if ANYTHING exists. Something will exist if the user exists
            Add-Member -InputObject $CSVExportFormatObject -MemberType NoteProperty -Name "Name" -Value ($userAsia).Name
            }elseif (($userHassell).name -ne $null) {
                Add-Member -InputObject $CSVExportFormatObject -MemberType NoteProperty -Name "Name" -Value ($userHassell).Name
                }else {
                    Add-Member -InputObject $CSVExportFormatObject -MemberType NoteProperty -Name "Name" -Value "Null"
                }
        
        if (($userAsia).Enabled -ne $null) {
            Add-Member -InputObject $CSVExportFormatObject -MemberType NoteProperty -Name "Enabled" -Value ($userAsia).Enabled
            }elseif (($userHassell).Name -ne $null) {
                Add-Member -InputObject $CSVExportFormatObject -MemberType NoteProperty -Name "Enabled" -Value ($userHassell).Enabled
                }else {
                    Add-Member -InputObject $CSVExportFormatObject -MemberType NoteProperty -Name "Enabled" -Value "Null"
                }

        Add-Member -InputObject $CSVExportFormatObject -MemberType NoteProperty -Name "Exist" -Value $ExistCheckTrue
        #Write-Host -ForegroundColor Yellow "Writing $folder to Export Log"
        $CSVExportFormatObject | Export-csv "C:\Users\hastx\OneDrive - HASSELL\Documents\1. Notes\Script\HDriveCleanup\Export3.csv" -append -NoTypeInformation          
        }
    }