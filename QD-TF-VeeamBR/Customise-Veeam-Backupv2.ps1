# Function to get the first unused drive letter starting from F
function Get-FirstUnusedDriveLetter {
    $usedDriveLetters = Get-Partition | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
    $alphabet = "FGHIJKLMNOPQRSTUVWXYZ"  # Start from F and skip A to E

    foreach ($letter in $alphabet.ToCharArray()) {
        if ($usedDriveLetters -notcontains $letter) {
            return $letter
        }
    }

    return $null  # No available drive letters
}

# Initialize all uninitialized disks
Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' } | Initialize-Disk -PartitionStyle GPT

# Get all disks without a drive letter that are online
$onlineDisksWithoutDriveLetter = Get-Disk | Where-Object { $_.PartitionStyle -eq 'GPT' -and $_.IsOffline -eq $false -and !$_.DriveLetter }

# Assign drive letters starting from F to online disks without a drive letter and add them as backup repositories
foreach ($disk in $onlineDisksWithoutDriveLetter) {
    $driveLetter = Get-FirstUnusedDriveLetter
    if (-not $driveLetter) {
        Write-Host "No available drive letters for disk $($disk.Number). Skipping..."
        continue
    }
    $partition = $disk | New-Partition -AssignDriveLetter -UseMaximumSize  # Assigns the next available drive letter
    $partition | Format-Volume -FileSystem ReFS -AllocationUnitSize 64KB -Confirm:$false
}

# Import the Veeam Backup PowerShell module
Import-Module Veeam.Backup.PowerShell

# Connect to Veeam backup server.
$hostname = [Net.Dns]::GetHostName()
$Server = Get-VBRServer -Name $hostname

# Add each initialized disk as a Veeam backup repository
$initializedDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'GPT' -and $_.IsOffline -eq $false }
foreach ($disk in $initializedDisks) {
    $driveLetter = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
    if ($driveLetter) {
        $folderPath = $driveLetter + ":\"
        Add-VBRBackupRepository -Name "Local Backups $folderPath" -Server $Server -Folder $folderPath -Type WinLocal
    } else {
        Write-Host "No drive letter found for disk $($disk.Number). Skipping..."
    }
}
