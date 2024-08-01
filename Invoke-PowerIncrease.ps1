function Invoke-PowerIncrease {
<#
.SYNOPSIS
Copies a file to a new location and increases its size by adding random padding bytes. Can also download a file from a URL and inflate it before writing to disk.

.DESCRIPTION
The `Invoke-PowerIncrease` function takes a source file, copies it to a specified destination, 
and increases its size to a target size in megabytes by appending random padding bytes. 
It can also download a file from a URL, inflate it in memory, and then write it to the specified destination.

.PARAMETER SourceFilePath
Specifies the path to the source file that needs to be copied and padded.

.PARAMETER URL
Specifies the URL to download the file from if a source file path is not provided.

.PARAMETER TargetSizeMB
Specifies the target size of the new file in megabytes. This size includes the size of 
the source file plus the random padding.

.PARAMETER DestinationFilePath
Specifies the path to the destination file where the source file will be copied and padded.

.EXAMPLE
Invoke-PowerIncrease -SourceFilePath "C:\buff.exe" -TargetSizeMB 51 -DestinationFilePath "C:\buffnew.exe"

.EXAMPLE
Invoke-PowerIncrease -URL "http://example.com/file.exe" -TargetSizeMB 51 -DestinationFilePath "C:\buffnew.exe"
#>
    param (
        [Parameter(Mandatory=$false)]
        [string]$SourceFilePath,

        [Parameter(Mandatory=$false)]
        [string]$URL,

        [Parameter(Mandatory=$true)]
        [int]$TargetSizeMB,

        [Parameter(Mandatory=$true)]
        [string]$DestinationFilePath
    )

    if (!$SourceFilePath -and !$URL) {
        Write-Error "Either -SourceFilePath or -URL must be specified."
        return
    } elseif ($SourceFilePath -and $URL) {
        Write-Error "-SourceFilePath and -URL cannot be used together. Please specify only one."
        return
    }

    $contentBytes = $null

    if ($URL) {
        try {
            $response = Invoke-WebRequest -Uri $URL -UseBasicParsing
            $contentBytes = $response.Content
            Write-Output "Downloaded content from URL."
        } catch {
            Write-Error "Failed to download file from URL: $_"
            return
        }
    } elseif ($SourceFilePath) {
        if (-not (Test-Path $SourceFilePath)) {
            Write-Error "Source file doesn't exist: $SourceFilePath"
            return
        }
        $contentBytes = [System.IO.File]::ReadAllBytes($SourceFilePath)
        Write-Output "Read content from source file."
    }

    $SourceFileSize = $contentBytes.Length
    Write-Output "Source Content Size: $SourceFileSize bytes"

    if ($TargetSizeMB -lt 0) {
        Write-Error "Target size cannot be negative."
        return
    }

    $RandomPaddingBytes = Get-Random -Minimum 5 -Maximum 200
    $TargetSizeBytes = $TargetSizeMB * 1024 * 1024 + $RandomPaddingBytes
    $PaddingSizeBytes = $TargetSizeBytes - $SourceFileSize

    $PaddingBytes = New-Object byte[] $PaddingSizeBytes
    [System.Random]::new().NextBytes($PaddingBytes)

    try {
        $inflatedContent = New-Object byte[] $TargetSizeBytes
        [System.Buffer]::BlockCopy($contentBytes, 0, $inflatedContent, 0, $SourceFileSize)
        [System.Buffer]::BlockCopy($PaddingBytes, 0, $inflatedContent, $SourceFileSize, $PaddingSizeBytes)

        [System.IO.File]::WriteAllBytes($DestinationFilePath, $inflatedContent)

        Write-Output "File inflated and written to $DestinationFilePath. Total size: $($TargetSizeBytes / 1MB) MB."
    } catch {
        Write-Error "An error occurred: $_"
    }
}
