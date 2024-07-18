function Invoke-PowerIncrease {
<#
.SYNOPSIS
Copies a file to a new location and increases its size by adding random padding bytes.

.DESCRIPTION
The `Invoke-PowerIncrease` function takes a source file, copies it to a specified destination, 
and increases its size to a target size in megabytes by appending random padding bytes. 
The function ensures that the target size is not smaller than the source file size and 
adds a small random variation to the padding size to introduce variability.

.PARAMETER SourceFilePath
Specifies the path to the source file that needs to be copied and padded.

.PARAMETER TargetSizeMB
Specifies the target size of the new file in megabytes. This size includes the size of 
the source file plus the random padding.

.PARAMETER DestinationFilePath
Specifies the path to the destination file where the source file will be copied and padded.

.EXAMPLE
Invoke-PowerIncrease -SourceFilePath "C:\buff.exe" -TargetSizeMB 51 -DestinationFilePath "C:\buffnew.exe"

#>
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourceFilePath,

        [Parameter(Mandatory=$true)]
        [int]$TargetSizeMB,

        [Parameter(Mandatory=$true)]
        [string]$DestinationFilePath
    )

    if (-not (Test-Path $SourceFilePath)) {
        Write-Error "Source file doesn't exist: $SourceFilePath"
        return
    }

    $SourceFileInfo = Get-Item $SourceFilePath
    $SourceFileSize = $SourceFileInfo.Length

    Write-Output "Source File Size: $SourceFileSize bytes"

    if ($TargetSizeMB -lt 0) {
        Write-Error "Target size cannot be negative."
        return
    }

    # Calculate target size with random padding in bytes
    $RandomPaddingBytes = Get-Random -Minimum 5 -Maximum 200
    $TargetSizeBytes = $TargetSizeMB * 1024 * 1024 + $RandomPaddingBytes
    $PaddingSizeBytes = $TargetSizeBytes - $SourceFileSize

    $PaddingBytes = New-Object byte[] $PaddingSizeBytes
    [System.Random]::new().NextBytes($PaddingBytes)  # Fill with random bytes

    try {
        $sourceFileStream = [System.IO.FileStream]::new($SourceFilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $destinationFileStream = [System.IO.FileStream]::new($DestinationFilePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)

        try {
            
            $sourceFileStream.CopyTo($destinationFileStream)
            
            # Write random padding bytes to destination file
            $destinationFileStream.Write($PaddingBytes, 0, $PaddingSizeBytes)
        } finally {
            $sourceFileStream.Close()
            $destinationFileStream.Close()
        }

        Write-Output "File copied and padded successfully. Total size: $($TargetSizeBytes / 1MB) MB."
    } catch {
        Write-Error "An error occurred: $_"
    }
}
