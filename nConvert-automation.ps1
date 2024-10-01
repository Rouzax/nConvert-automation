param(
    [Parameter(
        mandatory = $true
    )]
    [string]    $SourcePath
)

# Get the full path to nconvert.exe relative to the script location
$nconvertPath = Join-Path $PSScriptRoot 'NConvert\nconvert.exe'

# Validate if the nconvert executable exists
if (-not (Test-Path $nconvertPath)) {
    Write-Host "Error: NConvert executable not found at: $($nconvertPath)" -ForegroundColor Red
    Exit 1
}

# Define desired image dimensions for thumbnails
$Dimensions = @(2000, 1500, 1000, 750, 500, 250)

# Create the exclude patterns dynamically based on dimensions
$ExcludePatterns = $Dimensions | ForEach-Object { "*${_}px*" }

# Get image file paths excluding the patterns and including only specified extensions
try {
    $ImageFilePaths = Get-ChildItem -Path $SourcePath -Recurse -Exclude $ExcludePatterns -Include *.gif, *.png, *.jpg, *.webp, *.wep, *.bmp -Attributes !Directory
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
    $ImageRootFolder = Split-Path -Path $ImagePath -Parent
    Write-Host 'Processing:' $($ImagePath.Name) -ForegroundColor Yellow -NoNewline

    try {
        # Get the original dimensions of the image
        $imageInfo = &$nconvertPath -info $ImagePath
        if (-not $imageInfo) {
            throw "Unable to retrieve image info for $($ImagePath.FullName)"
        }

        $originalWidth = ($imageInfo | Select-String -Pattern 'Width.*: (\d+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }) -as [int]
        $originalHeight = ($imageInfo | Select-String -Pattern 'Height.*: (\d+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }) -as [int]
        $longestSide = [Math]::Max($originalWidth, $originalHeight)
        
        if (-not $originalWidth -or -not $originalHeight) {
            throw "Invalid dimensions for image $($ImagePath.FullName)"
        }

        # Initialize a counter for the number of thumbnails created
        $createdThumbnailsCount = 0

        foreach ($Dimension in $Dimensions) {
            # Only resize and save if the longest side is greater than the target dimension
            if ($longestSide -gt $Dimension) {
                try {
                    &$nconvertPath -quiet -clevel 9 -keep_icc -rmeta -buildexifthumb -ratio -rtype lanczos -resize longest $Dimension -dpi 300 -rflag decr -overwrite -o $ImageRootFolder\$Dimension"px"\$($ImagePath.BaseName)-$Dimension"px"$($ImagePath.Extension) $ImagePath
                    $createdThumbnailsCount++
                } catch {
                    Write-Host "Error: Failed to create thumbnail for $($ImagePath.FullName) at $Dimension px. $_" -ForegroundColor Red
                }
            }
        }

        if ($createdThumbnailsCount -eq 0) {
            Write-Host " - Skipped (No thumbnails created)" -ForegroundColor Yellow
        } else {
            Write-Host " - DONE - Created $createdThumbnailsCount Thumbnails" -ForegroundColor Green
        }

    } catch {
        Write-Host "Error: Processing failed for $($ImagePath.FullName). $_" -ForegroundColor Red
    }
}

Start-Sleep 10
