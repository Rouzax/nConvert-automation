# Image Thumbnail Generator with NConvert

This PowerShell script processes images in a specified folder to generate multiple thumbnail versions using the [NConvert](https://www.xnview.com/en/nconvert/) utility. It dynamically creates thumbnails with different resolutions while maintaining the aspect ratio of the original image, with support for multiple output formats including PNG, JPG, WebP, BMP, and GIF.

## Features
- Generates multiple thumbnails of different sizes (2000px, 1500px, 1000px, 750px, 500px, and 250px on the longest side)
- Supports multiple output formats (PNG, JPG, JPEG, WebP, BMP, GIF)
- Creates organized subdirectories for each thumbnail size
- Maintains image quality with format-specific optimizations
- Processes images recursively from a specified folder
- Provides clear, concise progress feedback
- Includes detailed error reporting when issues occur

## Requirements
- [NConvert](https://www.xnview.com/en/nconvert/) must be installed and located in a subfolder called `NConvert` relative to the script's location
- PowerShell (Windows PowerShell or PowerShell Core)

## Usage

### Parameters
- **`$SourcePath`**: (Mandatory) The full path to the folder containing the images to be processed
- **`$OutputFormat`**: (Mandatory) The desired output format for the thumbnails. Valid options are:
  - png (High compression, 300 DPI)
  - jpg/jpeg (95% quality)
  - webp (Maximum quality)
  - bmp
  - gif

### Example Usage

```powershell
# Generate PNG thumbnails
.\nConvert-automation.ps1 -SourcePath "C:\path\to\images" -OutputFormat "png"

# Generate WebP thumbnails
.\nConvert-automation.ps1 -SourcePath "C:\path\to\images" -OutputFormat "webp"

# Generate JPG thumbnails
.\nConvert-automation.ps1 -SourcePath "C:\path\to\images" -OutputFormat "jpg"
```

## Output Structure

The script creates subdirectories for each thumbnail size under the source directory. For example:
```
source_directory/
├── 2000px/
│   ├── image1-2000px.jpg
│   └── image2-2000px.jpg
├── 1500px/
│   ├── image1-1500px.jpg
│   └── image2-1500px.jpg
└── [other size directories...]
```

## Format-Specific Settings

The script applies optimal settings for each output format:
- **PNG**: Uses maximum compression (level 9) and 300 DPI
- **JPG/JPEG**: Uses 95% quality setting
- **WebP**: Uses maximum quality setting
- **BMP/GIF**: Uses default conversion settings

## Error Handling

The script includes comprehensive error handling:
- Validates NConvert installation
- Checks for valid source directory and images
- Reports individual failures without stopping the entire process
- Provides detailed error information when issues occur
- Shows command-line details for debugging purposes

## Console Output

The script provides clear feedback during processing:
```
Starting image conversion to jpg...
Processing: image1.png - DONE - Created 4 Thumbnails
Processing: image2.jpg - DONE - Created 3 Thumbnails
Processing: image3.png - Skipped (No thumbnails needed)
Conversion completed.
```

If an error occurs, detailed information is displayed:
```
Processing: image4.png - FAILED
Detailed error information:
  - Failed at 1000px: [error details]
Command details:
  NConvert path: [path]
  Original dimensions: [dimensions]
  Last command: [command]
```

## Notes
- The script skips creating thumbnails for images smaller than the target dimensions
- Existing thumbnails are overwritten if they already exist
- The script removes metadata and EXIF thumbnails during conversion
- All resizing is done using the Lanczos algorithm for optimal quality
- A 4-second pause is added at the end of processing to review the final output

## Contributing
Feel free to submit issues and enhancement requests through the GitHub repository's issue tracker.
