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
- **`-SourcePath`** (Mandatory): Full path to the folder containing images for processing.
- **`-OutputFormat`** (Mandatory): Desired output format for thumbnails. Options:
  - `png` (High compression, 150 DPI)
  - `jpg` / `jpeg` (95% quality, transparency is filled with white, optimized Huffman tables)
  - `webp` (Maximum quality)
  - `bmp`
  - `gif` (256 colors)

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

The script creates subdirectories for the Output format and for each thumbnail size under the source directory. For example:
```
C:\Image_Test
│   Image1.png
│   Image2.png
│   Image3.jpg
│
└───PNG
    ├───1000px
    │       Image1-1000px.png
    │       Image2-1000px.png
    │       Image3-1000px.png
    │
    ├───1500px
    │       Image1-1500px.png
    │       Image2-1500px.png
    │       Image3-1500px.png
    │
    ├───2000px
    │       Image1-2000px.png
    │       Image2-2000px.png
    │       Image3-2000px.png
    │
    ├───250px
    │       Image1-250px.png
    │       Image2-250px.png
    │       Image3-250px.png
    │
    ├───500px
    │       Image1-500px.png
    │       Image2-500px.png
    │       Image3-500px.png
    │
    └───750px
            Image1-750px.png
            Image2-750px.png
            Image3-750px.png
```

## Format-Specific Optimizations

The script applies optimal settings for each output format:
- **PNG**: Maximum compression (`clevel 9`), 150 DPI.
- **JPG/JPEG**: 95% quality, Transparency is filled with white background, optimized Huffman tables, float DCT for better quality.
- **WebP**: Maximum quality (`q 95`).
- **GIF**: Limited to 256 colors for compatibility.
- **BMP/GIF**: Uses default conversion settings

## Error Handling

The script includes comprehensive error handling:
- Validates NConvert installation
- Checks for valid source directory and images
- Reports individual failures without stopping the entire process
- Provides detailed error information when issues occur
- Shows command-line details for debugging purposes

### Example Output

```
Using NConvert from: C:\GitHub\nConvert-automation\NConvert\nconvert.exe
Source Path: C:\Image_Test
Output Format: png

Searching for image files...
Found 3 image files to process

Processing: image1.png - DONE - Created 4 Thumbnails
Processing: image2.jpg - DONE - Created 3 Thumbnails
Processing: image3.png - SKIPPED (No thumbnails needed)

Total processing time: 00:00:24.585
Total thumbnails created: 7

Conversion completed.
```

### Error Example

```
Processing: image4.png - FAILED
Errors for image4.png:
For 1000px:
    Error: NConvert failed (Exit code: 1). Error: Invalid input format
    Command: C:\path\to\NConvert\nconvert.exe -resize longest 1000 -out webp -o output.webp image4.png

Original dimensions: 3200x2400
```

## Notes
- The script skips creating thumbnails for images smaller than the target dimensions
- Existing thumbnails are overwritten if they already exist
- The script removes metadata and EXIF thumbnails during conversion
- All resizing is done using the Lanczos algorithm for optimal quality

## Contributing
Feel free to submit issues and enhancement requests through the GitHub repository's issue tracker.