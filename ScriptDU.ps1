<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

function Get-BiggestFile
{
    [CmdletBinding()]

    Param
    (
        # Param1 Computer name or names of targeted machines
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias('cn', 'ComputerName', 'Name', 'Names')]
        $ComputerNames = @($env:COMPUTERNAME),

        # Param2 Path to the file of the start of the search
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias('Path', 'File', 'p')]
        $FilesPath = 'C:\Users\',

        # Param3 Number of files returned
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias('n', 'Number')]
        $NumberOfFiles = 10,

        # SwitchParam1 If the test of the conections should be executed
        [Alias('t', 'NoTest')]
        [switch] $NoTestConection
        
    )

    Begin
    {
    # Definition of outpud Array
    $OutputObj = @()
    # Definition of Array of connected machines
    $Connected = @()

        # Testing if switch parameter NoTestConnection is active
        if ($NoTestConection.IsPresent){
            forEach ($ComputerName in $ComputerNames) {
                $Connected += $ComputerName
            } 
        }
        else{
            Write-Host "Testing Connection ..."
            Write-Host " "
            forEach ($ComputerName in $ComputerNames) {
                # Testing if there is a host name of computer executing the function 
                # if so automaticli set it conected
                # else test conection
                if ($ComputerName -eq $env:COMPUTERNAME){
                   $Connected += $ComputerName
                }
                else {
                    if (Test-Connection -Quiet $ComputerName) {
                       $Connected += $ComputerName
                    }
                    else {
                        # If Computer is not connected write out a warning
                        Write-Warning ('Computer: "' + $ComputerName + '" NOT connected')
                    }
                }
            }
        }
    }

    Process
    {
        forEach ($ComputerName in $Connected){
            # Testing if there is a hostname of the computer executing the function
            # if so it just execute the get comand and save the output
            if ($ComputerName -eq $env:COMPUTERNAME) {
                $OneOutput = @()
                # The "-in *" means include everything = it goes deeper in the directories
                $OneOutput += Get-ChildItem -re -in * -Path $FilesPath | 
                # if it is a directory then exclude it
                ?{ -not $_.PSIsContainer } | 
                sort Length -Descending | 
                Select-Object -First $NumberOfFiles
            }
            # if it is not a host its needed to invoke command on another machine
            else {
                $OneOutput += (Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                    param($FilesPath, $NumberOfFiles)
                    Get-ChildItem -re -in * -Path $FilesPath | 
                    ?{ -not $_.PSIsContainer } | 
                    sort Length -Descending | 
                    select -First $NumberOfFiles
                    # Passing the local variables to another machine
                } -ArgumentList ($FilesPath, $NumberOfFiles) 
                )
            }
            # Making alias for property length because it gots swapped out with length of the Array later on
            $OneOutput | Add-Member -MemberType AliasProperty -Name Size -Value Length
            forEach ($line in $OneOutput) {
                # Getting wanted properties of the output
                $format = @{
                    ComputerName = $ComputerName
                    Name = $line.Name
                    Length = $line.Size
                    Directory = $line.Directory
                    CreationTime = $line.CreationTime
                }
                $OutputObj += New-Object -TypeName psobject -Property $format
            }
            # The gup between different machines
            $OutputObj += " "
        }
        
    }
    End
    {
        # Formating the output to the eazy human readable table
        Write-Output ($OutputObj | Format-Table -Property ComputerName, Name, Length, Directory, CreationTime )
    }
}