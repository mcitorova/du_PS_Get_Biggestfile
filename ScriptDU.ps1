<#
.Synopsis
   Get 10 biggest files in the path
.DESCRIPTION
   Get requred required amount of the biggest files in the path
   of supplied Computer names
   The outpust is displayed as hostname, name, length, directory, creationtime
.EXAMPLE
   PS> Get-BiggestFile 
   CompuerName	Name		Length	Directory		CreationTime
   Host		file1.txt 	55555 	C:\Users\Documents 	3/7/2022 12:00:00 PM
.EXAMPLE
   PS> Get-BiggestFile -Name "Server1" -FilePath "C:\custom\path"
   CompuerName	Name		Length	Directory	CreationTime
   Server1 	file1.txt 	55555 	C:\custom\path 	3/7/2022 12:00:00 PM
.NOTES
   Zadanie 6.
   miroslava.citorova@t-systems.com
   dominika.bernatova@telekom.com
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
	[String[]]
        $ComputerNames = @($env:COMPUTERNAME),

        # Param2 Path to the file of the start of the search
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias('Path', 'File', 'p')]
	[String]
        $FilesPath = 'C:\Users\',

        # Param3 Number of files returned
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias('n', 'Number')]
	[int]
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
            $OneOutput | Add-Member -MemberType AliasProperty -Name Size -Value Length -Force
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
