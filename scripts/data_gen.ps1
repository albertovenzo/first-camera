# Define the output binary file path
$binaryFilePath = ".\pattern.bin"

# Define the repetitive pattern as a byte array (e.g., 0xAA, 0xBB, 0xCC)
$pattern = [byte[]](0xFF, 0x11, 0x77)

# Define how many times to repeat the pattern
$repeatCount = 640*480*3

# Create a memory stream to hold the data
$memoryStream = New-Object System.IO.MemoryStream

# Write the pattern repeatedly
for ($i = 0; $i -lt $repeatCount; $i++) {
    $memoryStream.Write($pattern, 0, $pattern.Length)
}

# Write the memory stream to the binary file
[System.IO.File]::WriteAllBytes($binaryFilePath, $memoryStream.ToArray())

# Optional: Access and modify a specific byte in the pattern
# Example: Change the 10th byte to 0xFF
$bytes = [System.IO.File]::ReadAllBytes($binaryFilePath)
$bytes[9] = 0xFF  # Indexing starts at 0
[System.IO.File]::WriteAllBytes($binaryFilePath, $bytes)

Write-Host "Binary file created at $binaryFilePath with repetitive pattern."
