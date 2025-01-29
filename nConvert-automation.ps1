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

function Write-StatusMessage {
    param(
        [string]$Status,
        [string]$Color,
        [string]$AdditionalInfo = ""
    )
    Write-Host " - " -NoNewline
    Write-Host $Status -ForegroundColor $Color -NoNewline
    if ($AdditionalInfo) {
        Write-Host " - $AdditionalInfo"
    } else {
        Write-Host ""
    }
}

function Write-LabeledValue {
    param(
        [string]$Label,
        [string]$Value,
        [string]$LabelColor = "Cyan",
        [string]$ValueColor = "White",
        [switch]$NoNewline
    )
    Write-Host "$Label" -ForegroundColor $LabelColor -NoNewline
    if ($NoNewline) {
        Write-Host $Value -ForegroundColor $ValueColor -NoNewline
    } else {
        Write-Host $Value -ForegroundColor $ValueColor
    }
}

function Write-ErrorDetail {
    param(
        [string]$Dimension,
        [string]$ErrorMessage,
        [string]$Command
    )
    Write-Host "For " -NoNewline
    Write-Host "$($Dimension)px" -ForegroundColor Cyan -NoNewline
    Write-Host ":"
    Write-Host "    Error: " -ForegroundColor Red -NoNewline
    Write-Host $ErrorMessage
    Write-Host "    Command: " -ForegroundColor DarkGray -NoNewline
    Write-Host $Command
}

function Write-ProcessingStart {
    param([string]$Filename)
    Write-Host "Processing: " -NoNewline
    Write-Host $Filename -ForegroundColor Yellow -NoNewline
}

# Start the stopwatch
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Initialize total thumbnails counter
$totalThumbnails = 0

# Get the full path to nconvert.exe relative to the script location
$nconvertPath = Join-Path $PSScriptRoot 'NConvert\nconvert.exe'

# Validate if the nconvert executable exists
if (-not (Test-Path $nconvertPath)) {
    Write-LabeledValue "Error: " "NConvert executable not found at: $($nconvertPath)" "Red"
    Exit 1
}

Write-LabeledValue "Using NConvert from: " $nconvertPath
Write-LabeledValue "Source Path: " $SourcePath
Write-LabeledValue "Output Format: " $OutputFormat

# Define desired image dimensions for thumbnails
$Dimensions = @(2000, 1500, 1000, 750, 500, 250)

# Create the exclude patterns dynamically based on dimensions
$ExcludePatterns = $Dimensions | ForEach-Object { "*${_}px*" }

# Get image file paths excluding the patterns and including only specified extensions
try {
    Write-Host "`nSearching for image files..." -ForegroundColor Cyan
    $ImageFilePaths = Get-ChildItem -Path $SourcePath -Recurse -Exclude $ExcludePatterns -Include *.gif, *.png, *.jpg, *.jpeg, *.webp, *.wep, *.bmp, *.emf -Attributes !Directory
    Write-Host "Found " -NoNewline
    Write-Host $ImageFilePaths.Count -ForegroundColor White -NoNewline
    Write-Host " image files to process"
} catch {
    Write-LabeledValue "Error: " "Unable to retrieve image files from $SourcePath. $_" "Red"
    Exit 1
}

# Check if any image files were found
if ($ImageFilePaths.Count -eq 0) {
    Write-Host "No valid image files found in the source directory." -ForegroundColor Yellow
    Exit 0
}

foreach ($ImagePath in $ImageFilePaths) {
    Write-ProcessingStart $ImagePath.Name
    
    $imageErrors = @()  # Errors specific to this image
    $createdThumbnailsCount = 0
    
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

        foreach ($Dimension in $Dimensions) {
            if ($longestSide -gt $Dimension) {
                try {
                    $OutputDirectory = Join-Path $ImageRootFolder "$Dimension`px"
                    if (-not (Test-Path $OutputDirectory)) {
                        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
                    }

                    $OutputFile = Join-Path $OutputDirectory "$($ImagePath.BaseName)-$Dimension`px.$OutputFormat"
                    
                    # Convert 'jpg' to 'jpeg' for NConvert command but keep original extension for output file
                    $nconvertFormat = if ($OutputFormat -eq 'jpg') {
                        'jpeg' 
                    } else {
                        $OutputFormat 
                    }

                    $Arguments = @(
                        "-quiet", # Quiet mode - suppress output
                        "-rmeta", # Remove all metadata (EXIF/IPTC/...)
                        "-rexifthumb", # Remove EXIF thumbnail specifically
                        "-ratio", # Keep the aspect ratio for scaling
                        "-rtype", "lanczos", # Lanczos resampling - high quality downsampling algorithm
                        "-resize", "longest", $Dimension, # Target dimension for longest side
                        "-rflag", "decr", # Decrease only - won't upscale images
                        "-out", $nconvertFormat # Specified output format (png/webp/jpeg)
                    )
                    
                    switch ($nconvertFormat) {
                        'png' {
                            $Arguments += @(
                                "-clevel", "9", # PNG Compression level (max compression, range 0-9)
                                "-dpi", "300" # Set the resolution in DPI
                            )
                        }
                        'webp' {
                            $Arguments += @(
                                "-q", "85" # WebP quality (default: 85) - balance of quality/size
                            )
                        }
                        'jpeg' {
                            $Arguments += @(
                                "-q", "90", # JPEG quality (default: 85) - higher quality setting
                                "-dct", "2", # DCT method (0:Slow, 1:Fast, 2:Float) - using float for better quality
                                "-opthuff", # Optimize Huffman Table (JPEG) - better compression
                                "-subsampling", "1" # Subsampling factor (0:2x2,1x1,1x1, 1:2x1,1x1,1x1, 2:1x1,1x1,1x1)
                                # Using 2x1,1x1,1x1 for better quality while maintaining good compression
                            )
                        }
                        'gif' {
                            $Arguments += @(
                                "-colors", "256" # GIF color count (default: 256)
                            )
                        }
                    }

                    $Arguments += @("-overwrite", "-o", $OutputFile, $ImagePath)

                    $processOutput = & $nconvertPath @Arguments 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        $errorMessage = ($processOutput | Out-String).Trim()
                        $imageErrors += @{
                            Dimension = $Dimension
                            Error     = "NConvert failed (Exit code: $LASTEXITCODE). Error: $errorMessage"
                            Command   = "$nconvertPath $($Arguments -join ' ')"
                        }
                        continue
                    }

                    if (Test-Path $OutputFile) {
                        $createdThumbnailsCount++
                        $totalThumbnails++ # Increment the total counter
                    } else {
                        $imageErrors += @{
                            Dimension = $Dimension
                            Error     = "Output file was not created"
                            Command   = "$nconvertPath $($Arguments -join ' ')"
                        }
                    }
                } catch {
                    $imageErrors += @{
                        Dimension = $Dimension
                        Error     = $_.Exception.Message
                        Command   = "$nconvertPath $($Arguments -join ' ')"
                    }
                }
            }
        }

        if ($imageErrors.Count -eq 0) {
            if ($createdThumbnailsCount -gt 0) {
                Write-StatusMessage "DONE" "Green" "Created $createdThumbnailsCount Thumbnails"
            } else {
                Write-StatusMessage "SKIPPED" "Yellow" "(No thumbnails needed)"
            }
        } else {
            Write-StatusMessage "FAILED" "Red"
            Write-LabeledValue "Errors for " "$($ImagePath.Name):" "White" "Yellow"
            
            foreach ($errormsg in $imageErrors) {
                Write-ErrorDetail -Dimension $errormsg.Dimension -ErrorMessage $errormsg.Error -Command $errormsg.Command
            }
            Write-LabeledValue "Original dimensions: " "${originalWidth}x${originalHeight}"
        }

    } catch {
        Write-StatusMessage "FAILED" "Red"
        Write-Host "Error processing " -NoNewline
        Write-Host $ImagePath.Name -ForegroundColor Yellow -NoNewline
        Write-Host ": " -NoNewline
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
# Stop the stopwatch
$stopwatch.Stop()

# Display the elapsed time and total thumbnails created
Write-Host "`nConversion completed." -ForegroundColor Cyan
Write-LabeledValue "Total processing time: " $stopwatch.Elapsed.ToString('hh\:mm\:ss\.fff')
Write-LabeledValue "Total thumbnails created: " $totalThumbnails

Start-Sleep 4