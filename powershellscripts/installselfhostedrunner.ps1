# Create a folder under the drive root
mkdir C:\actions-runner
cd C:\actions-runner

# Download the latest runner package
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.322.0/actions-runner-win-x64-2.322.0.zip -OutFile actions-runner-win-x64-2.322.0.zip

# Optional: Validate the hash
if ((Get-FileHash -Path actions-runner-win-x64-2.322.0.zip -Algorithm SHA256).Hash.ToUpper() -ne 'ACE5DE018C88492CA80A2323AF53FF3F43D2C82741853EFB302928F250516015'.ToUpper()) {
    throw 'Computed checksum did not match'
}

# Extract the installer
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("C:\actions-runner\actions-runner-win-x64-2.322.0.zip", "C:\actions-runner")

# Create the runner and start the configuration experience
Start-Process -FilePath "C:\actions-runner\config.cmd" -ArgumentList "--url https://github.com/atea/azurelocalsolutioniac --token AMHJMQ37WWMIXEVKLUMRGNLHYBNSG" -NoNewWindow -Wait

# Run the runner
Start-Process -FilePath "C:\actions-runner\run.cmd" -NoNewWindow