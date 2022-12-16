param(
    [Parameter(
        mandatory = $true
    )]
    [string]    $SourcePath
)

$nconvertPath = Join-Path $PSScriptRoot 'NConvert\nconvert.exe'

$Dimensions = @(2048, 1024, 512, 256)
$ImageFilePaths = (Get-ChildItem $SourcePath -Recurse -Exclude *2048*, *1024*, *512*, *256* -Attributes !Directory)


foreach ($ImagePath in $ImageFilePaths) {
    $ImageRootFolder = Split-Path -Path $ImagePath -Parent
    Write-Host 'Processing:'$($ImagePath.Name) -ForegroundColor Yellow -NoNewline
    foreach ($Dimension in $Dimensions) {
        &$nconvertPath -quiet -clevel 9 -keep_icc -rmeta -buildexifthumb -ratio -rtype lanczos -resize longest $Dimension -dpi 300 -rflag decr -overwrite -o $ImageRootFolder\$Dimension"px"\$($ImagePath.BaseName)-$Dimension"px"$($ImagePath.Extension) $ImagePath
    }
    Write-Host ' - DONE - Created'$($Dimensions.Length)'Tumbnails'-ForegroundColor Green
}
Start-Sleep 10