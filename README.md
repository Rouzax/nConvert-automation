# Image Thumbnail Generator with NConvert

This PowerShell script processes images in a specified folder to generate multiple thumbnail versions using the [NConvert](https://www.xnview.com/en/nconvert/) utility. It is designed to dynamically create thumbnails with different resolutions while maintaining the aspect ratio of the original image. Supported image formats include `gif`, `png`, `jpg`, `webp`, `wep`, and `bmp`.

## Features
- Generates multiple thumbnails of different sizes (2000px, 1500px, 1000px, 750px, 500px, and 250px on the longest side).
- Skips images that already have thumbnails of specified dimensions.
- Maintains image quality and metadata (e.g., ICC profiles and EXIF data).
- Processes images recursively from a specified folder.
- Robust error handling for missing files or failed thumbnail generation.

## Requirements
- [NConvert](https://www.xnview.com/en/nconvert/) must be installed and located in a subfolder called `NConvert` relative to the script's location.
- PowerShell (Windows PowerShell or PowerShell Core).

## Usage

### Parameters:
- **`$SourcePath`**: Mandatory. The full path to the folder containing the images that need to be processed.

### Example Usage:

```powershell
.\nConvert-automation.ps1 -SourcePath "C:\path\to\image\folder"
```

This command will process all supported images inside the specified folder, creating thumbnails for each image that doesn't already have thumbnails in the `2000px`, `1500px`, `1000px`, `750px`, `500px`, or `250px` sizes.

## How It Works

1. **Check for NConvert**: The script first verifies if the `nconvert.exe` executable is located in a folder named `NConvert` in the same directory as the script. If not found, it displays an error and exits.

2. **Specify Dimensions**: The script defines an array of thumbnail sizes, which are used to create multiple resized versions of each image.

3. **File Exclusion**: Images that already have thumbnails with the defined dimensions in their filenames are skipped.

4. **Process Images**: 
   - For each image, the script retrieves the original image's width and height using NConvert.
   - It determines the longest side (width or height) and only creates thumbnails where the longest side is larger than the target thumbnail size.
   - For each thumbnail size, it calls `nconvert.exe` to resize the image proportionally, creating a new thumbnail in the same folder with the size appended to the filename (e.g., `image-500px.jpg`).

5. **Logging and Error Handling**: 
   - If an image fails to process or NConvert cannot retrieve image dimensions, an error is logged, but the script continues processing the rest of the images.
   - If no images are found or no thumbnails are created, it logs a message and exits gracefully.

## Error Handling
- If `nconvert.exe` is not found, the script exits with an error message.
- If there are issues reading image files or creating thumbnails, detailed error messages are shown.
- The script continues processing even if some images encounter errors.