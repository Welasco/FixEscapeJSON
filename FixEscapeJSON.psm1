﻿# This sample scripts is not supported under any Microsoft standard support program or service. 
# The sample scripts are provided AS IS without warranty of any kind. 
# Microsoft disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. 
# In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever 
# (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) 
# arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

# This script use a third party library from Newtonsoft to parser Json files.
# You can download the file here: https://github.com/JamesNK/Newtonsoft.Json/releases
# Current versiont 11/09/2017 - https://github.com/JamesNK/Newtonsoft.Json/releases/download/10.0.3/Json100r3.zip
# After unzip the file copy the file under \Bin\net45\Newtonsoft.Json.dll to a desired location and change the path in the script.

function FixJSONMultiThread {
    param(
        [string]$Folder,
        [int]$Threads,
        [string]$SingleFile
    )

    $ModulePath = Split-Path (Get-Module FixEscapeJSON).Path
    $NewtonsoftDllPath = Join-Path -Path $ModulePath -ChildPath "Newtonsoft.Json.dll"
    # Loading Newtonsoft.Json library *** You may need to change the file Path
    [Reflection.Assembly]::LoadFile($NewtonsoftDllPath) | Out-Null

    # Variable $Jobs used to control how many threads will be executed
    if ($Threads -gt 0) {
        $Jobs = $Threads
    }
    else {
        $Jobs = 4
    }

    $ScriptBlock = {
        param(
            [string]$Path,
            [string]$JobName,
            [string]$NewtonsoftDllPath
        )
        # Loading Newtonsoft.Json library *** You may need to change the file Path
        [Reflection.Assembly]::LoadFile($NewtonsoftDllPath) | Out-Null
    
        $filepath = $Path
        $content = Get-Content $filepath

        $Progress = 100 / $content.Length
        $ProgressCount = 100 / $content.Length

        # Do loop that will be executed until the whole file is fixed.
        do{
            $PerComplete = "{0:0}" -f $Progress
            $CurrentOperation = ("Processing line "+ $line +" of "+ $content.Length + " lines.")
            #Write-Progress -Activity "Processing Job: $JobName" -Status "$PerComplete% Complete" -CurrentOperation $CurrentOperation -PercentComplete $Progress
            Write-Progress -Activity "Processing Job: $JobName" -Status "$PerComplete% Complete" -CurrentOperation $CurrentOperation -PercentComplete ($line/$content.Length*100)
            $file = $content | Out-String
            try{
                #if ($previousline -ne $line) {
                    $Progress = $Progress + $ProgressCount
                #}
                $previousline = $line
                $error.Clear()
                $test = [Newtonsoft.Json.JsonConvert]::DeserializeObject($file)
            }
            catch{
                $exception = $Error[0]
                $line = (($exception -split("line "))[1] -split(","))[0] - 1
                $position = ((($exception -split("line "))[1] -split(","))[1] -split(" "))[2]
                $position = ((($exception -split("line "))[1] -split(","))[1] -split(" "))[2].Substring(0,$position.Length-2) - 1
                $content[$line] = $content[$line].Insert($position,"\")
            }
        }while($Error.count -ne 0)
        $Progress=100 
        $PerComplete=100 
        Write-Progress -Activity "Processing Job: $JobName" -Status "$PerComplete% Complete:" -PercentComplete $Progress
        $content | Set-Content $filepath
    }    

    # Variable with Folder Path of where the Logs are located *** You may need to change this path
    $folderPath = $Folder
    $singlefilePath = $SingleFile

    if ($folderPath) {
        # Collection of files that will be fixed
        $childFiles = Get-ChildItem -Path $folderPath -File        
    }
    else {
        $childFiles = Get-ChildItem $singlefilePath
    }


    # Looping all Json log files in the folder $folderPath
    Foreach($childfile in $childFiles){

        # Do loop to control how many threads will be executing simultaneously
        Do
        {
            $RunningJobs = Get-Job -State Running
            $Job = ($RunningJobs | Measure-Object).count

            foreach($RunningJob in $RunningJobs){
                $JobProgress = $RunningJob.ChildJobs[0].Progress[$RunningJob.ChildJobs[0].Progress.Count-1].PercentComplete
                $CurrentOperation = $RunningJob.ChildJobs[0].Progress[$RunningJob.ChildJobs[0].Progress.Count-1].CurrentOperation
                $RunningJobName = $RunningJob.Name
                if($JobProgress -ge 0){
                    Write-Progress -Id $RunningJob.Id -Activity "Processing file: $RunningJobName" -Status "$JobProgress% Complete:" -CurrentOperation $CurrentOperation -PercentComplete $JobProgress
                    if($JobProgress -eq 100){
                        Write-Progress -Id $RunningJob.Id -Activity "Processing file: $RunningJobName" -Status "Completed" -Completed
                    }
                }
            }            

            Start-Sleep -Seconds 1

        } Until ($Job -lt $Jobs)

        # Creating a new Thread
        Start-Job -Name $childfile.Name -ScriptBlock $ScriptBlock -ArgumentList $childfile.FullName,$childfile.Name,$NewtonsoftDllPath | Out-Null
        # Removing all fineshed Threads
        Get-Job -State Completed | Remove-Job
    }

    Do
    {
        $RunningJobs = Get-Job -State Running
        $Job = ($RunningJobs | Measure-Object).count
    
        foreach($RunningJob in $RunningJobs){
            $JobProgress = $RunningJob.ChildJobs[0].Progress[$RunningJob.ChildJobs[0].Progress.Count-1].PercentComplete
            $CurrentOperation = $RunningJob.ChildJobs[0].Progress[$RunningJob.ChildJobs[0].Progress.Count-1].CurrentOperation
            $RunningJobName = $RunningJob.Name
            if($JobProgress -ge 0){
                Write-Progress -Id $RunningJob.Id -Activity "Processing file: $RunningJobName" -Status "$JobProgress% Complete:" -CurrentOperation $CurrentOperation -PercentComplete $JobProgress
                if($JobProgress -eq 100){
                    Write-Progress -Id $RunningJob.Id -Activity "Processing file: $RunningJobName" -Status "Completed" -Completed
                }
            }
        }            
        Start-Sleep -Seconds 1
    } Until ((Get-Job -State Running).count -eq 0)


    # Cleaning steps
    Wait-Job -State Running | Out-Null
    Get-Job -State Completed | Remove-Job
    Get-Job
    Write-Output "Done!"
}

function Invoke-FixJSON {
    <# 
    .Synopsis
    Invoke-FixJSON
    This PowerShell command'let will Fix a JSON file that doesn't have escape characters behind a special characters.

    .Description
    Invoke-FixJSON
    This PowerShell command'let will Fix a JSON file that doesn't have escape characters behind a special characters.
    Here is the list with all JSON special characters that must be escaped:

        %x22 /          ; "    quotation mark  U+0022
        %x5C /          ; \    reverse solidus U+005C
        %x2F /          ; /    solidus         U+002F
        %x62 /          ; b    backspace       U+0008
        %x66 /          ; f    form feed       U+000C
        %x6E /          ; n    line feed       U+000A
        %x72 /          ; r    carriage return U+000D
        %x74 /          ; t    tab             U+0009
        %x75 4HEXDIG )  ; uXXXX  U+XXXX   

    .Example
    # Fixing all JSON files in a folder
    If you have more than one file in a folder the command will simultaneously (Multithreading) process 4 files by default.
    Invoke-FixJSON -Folder C:\JsonFiles

    .Example
    # Fixing all JSON files in a folder specifing how many files you would like to simultaneously process (Multithreading)
    By default it will process 4 files simultaneously (Multithreading)
    Invoke-FixJSON -Folder C:\JsonFiles -Threads 2
    Invoke-FixJSON -Folder C:\JsonFiles -Threads 6

    .Example
    # Fixing a single JSON file
    Invoke-FixJSON -File C:\JsonFiles\jsonfile.json

    # A URL to the main website for this project.
    ProjectUri = 'https://github.com/welasco/FixEscapeJSON'
    Resource = https://tools.ietf.org/html/rfc7159
    #>      
    [CmdletBinding(DefaultParameterSetName='FolderorFile')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Folder')]
        [System.String]$Folder,

        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [System.String]$File,
        [int]$Threads
    )

    if ($Folder) {
        FixJSONMultiThread -Folder $Folder -Threads $Threads 
    }
    else{
        FixJSONMultiThread -SingleFile $File
    }
}

# Exporting Powershell Functions from this Module
Export-ModuleMember -Function Invoke-FixJSON