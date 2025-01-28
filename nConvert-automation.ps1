param(
    [Parameter(
        Mandatory = $true
    )]
    [string] $SourcePath,

    [Parameter(
        Mandatory = $true
    )]
    [ValidateSet('png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif')]
    [string] $OutputFormat
)

# Get the full path to nconvert.exe relative to the script location
$nconvertPath = Join-Path $PSScriptRoot 'NConvert\nconvert.exe'

# Validate if the nconvert executable exists
if (-not (Test-Path $nconvertPath)) {
    Write-Host "Error: NConvert executable not found at: $($nconvertPath)" -ForegroundColor Red
    Exit 1
}

Write-Host "Using NConvert from: $nconvertPath" -ForegroundColor Cyan
Write-Host "Source Path: $SourcePath" -ForegroundColor Cyan
Write-Host "Output Format: $OutputFormat" -ForegroundColor Cyan

# Define desired image dimensions for thumbnails
$Dimensions = @(2000, 1500, 1000, 750, 500, 250)

# Create the exclude patterns dynamically based on dimensions
$ExcludePatterns = $Dimensions | ForEach-Object { "*${_}px*" }

# Get image file paths excluding the patterns and including only specified extensions
try {
    $ImageFilePaths = Get-ChildItem -Path $SourcePath -Recurse -Exclude $ExcludePatterns -Include *.gif, *.png, *.jpg, *.jpeg, *.webp, *.wep, *.bmp -Attributes !Directory
} catch {
    Write-Host "Error: Unable to retrieve image files from $SourcePath. $_" -ForegroundColor Red
    Exit 1
}

# Check if any image files were found
if ($ImageFilePaths.Count -eq 0) {
    Write-Host "No valid image files found in the source directory." -ForegroundColor Yellow
    Exit 0
}

foreach ($ImagePath in $ImageFilePaths) {
    Write-Host 'Processing:' $($ImagePath.Name) -ForegroundColor Yellow -NoNewline
    
    try {
        # Get the original dimensions of the image
        $imageInfo = &$nconvertPath -info $ImagePath
        if (-not $imageInfo) {
            throw "Unable to retrieve image info"
        }

        $originalWidth = ($imageInfo | Select-String -Pattern 'Width.*: (\d+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }) -as [int]
        $originalHeight = ($imageInfo | Select-String -Pattern 'Height.*: (\d+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }) -as [int]
        $longestSide = [Math]::Max($originalWidth, $originalHeight)
        
        if (-not $originalWidth -or -not $originalHeight) {
            throw "Invalid dimensions for image"
        }

        $ImageRootFolder = Split-Path -Path $ImagePath -Parent
        $createdThumbnailsCount = 0
        $errors = @()

        foreach ($Dimension in $Dimensions) {
            if ($longestSide -gt $Dimension) {
                try {
                    $OutputDirectory = Join-Path $ImageRootFolder "$Dimension`px"
                    if (-not (Test-Path $OutputDirectory)) {
                        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
                    }

                    $OutputFile = Join-Path $OutputDirectory "$($ImagePath.BaseName)-$Dimension`px.$OutputFormat"
                    
                    # Convert 'jpg' to 'jpeg' for NConvert command but keep original extension for output file
                    $nconvertFormat = if ($OutputFormat -eq 'jpg') { 'jpeg' } else { $OutputFormat }

                    $Arguments = @(
                        "-quiet", "-rmeta", "-rexifthumb", "-ratio", "-rtype", "lanczos",
                        "-resize", "longest", $Dimension, "-rflag", "decr", "-out", $nconvertFormat
                    )

                    switch ($nconvertFormat) {
                        'png' {
                            $Arguments += @("-clevel", "9", "-dpi", "300")
                        }
                        'webp' {
                            $Arguments += @("-q", "-1")
                        }
                        'jpeg' {
                            $Arguments += @("-q", "95")
                        }
                    }

                    $Arguments += @("-overwrite", "-o", $OutputFile, $ImagePath)

                    $processOutput = &$nconvertPath @Arguments 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "NConvert failed with exit code $LASTEXITCODE. Output: $processOutput"
                    }

                    if (Test-Path $OutputFile) {
                        $createdThumbnailsCount++
                    } else {
                        throw "Output file was not created"
                    }
                } catch {
                    $errors += "Failed at $Dimension`px: $_"
                }
            }
        }

        if ($errors.Count -eq 0) {
            if ($createdThumbnailsCount -gt 0) {
                Write-Host " - DONE - Created $createdThumbnailsCount Thumbnails" -ForegroundColor Green
            } else {
                Write-Host " - Skipped (No thumbnails needed)" -ForegroundColor Yellow
            }
        } else {
            Write-Host " - FAILED" -ForegroundColor Red
            Write-Host "Detailed error information:" -ForegroundColor Red
            foreach ($error in $errors) {
                Write-Host "  - $error" -ForegroundColor Red
            }
            Write-Host "Command details:" -ForegroundColor Red
            Write-Host "  NConvert path: $nconvertPath" -ForegroundColor Red
            Write-Host "  Original dimensions: ${originalWidth}x${originalHeight}" -ForegroundColor Red
            Write-Host "  Last command: $nconvertPath $($Arguments -join ' ')" -ForegroundColor Red
        }

    } catch {
        Write-Host " - FAILED" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

Write-Host "`nConversion completed." -ForegroundColor Cyan

 Start-Sleep 4