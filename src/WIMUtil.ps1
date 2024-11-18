# Check if script is running as Administrator
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Try {
        Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit
    }
    Catch {
        Write-Host "Failed to run as Administrator. Please rerun with elevated privileges." -ForegroundColor Red
        Exit
    }
}

# Load required WPF assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Define global variables
# Text Colors
$Script:NeutralColor = "White"
$Script:SuccessColor = "Green"
$Script:ErrorColor = "Red"

# Define the helper functions
function SetStatusText {
    param (
        [string]$message,
        [string]$color,
        [ref]$textBlock
    )
    $textBlock.Value.Text = $message
    $textBlock.Value.Foreground = $color
}

$script:currentScreenIndex = 1

# Fix Internet Explorer Engine is Missing to Ensure GUI Launches
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2 -Force

# Explicitly define the configuration URL for the branch to use (commenting out the one not to use depending on branch)
# $configUrl = "https://raw.githubusercontent.com/memstechtips/WIMUtil/main/config/wimutil-settings.json"  # Main branch
$configUrl = "https://raw.githubusercontent.com/memstechtips/WIMUtil/dev/config/wimutil-settings.json"   # Dev branch

Write-Host "Using Configuration URL: $configUrl" -ForegroundColor Cyan

# Determine branch from the configuration URL
$currentBranch = "unknown"  # Fallback value
if ($configUrl -match "https://raw.githubusercontent.com/memstechtips/WIMUtil/([^/]+)/config/wimutil-settings.json") {
    $currentBranch = $matches[1]
    Write-Host "Branch detected from Configuration URL: $currentBranch" -ForegroundColor Green
}
else {
    Write-Host "Unable to detect branch from Configuration URL. Using fallback." -ForegroundColor Yellow
}

Write-Host "Using branch: $currentBranch" -ForegroundColor Cyan

# Load the configuration from the specified URL
try {
    $config = (Invoke-WebRequest -Uri $configUrl -ErrorAction Stop).Content | ConvertFrom-Json
    Write-Host "Configuration loaded successfully from $configUrl" -ForegroundColor Green
}
catch {
    Write-Host "Failed to load configuration from URL: $configUrl" -ForegroundColor Red
    exit 1
}

# Fetch settings for the current branch
$branchConfig = $config.$currentBranch
if (-not $branchConfig) {
    Write-Host "Branch $currentBranch not found in configuration file. Exiting script." -ForegroundColor Red
    exit 1
}

Write-Host "Branch settings successfully loaded for: $currentBranch" -ForegroundColor Cyan

# Extract configuration settings
$xamlUrl = $branchConfig.xamlUrl
$oscdimgURL = $branchConfig.oscdimgURL
$expectedHash = $branchConfig.expectedHash

# Validate that required keys are present in the configuration
if (-not ($xamlUrl -and $oscdimgURL -and $expectedHash)) {
    Write-Host "Configuration file is missing required settings. Exiting script." -ForegroundColor Red
    exit 1
}

# Load XAML GUI
try {
    if (-not $xamlUrl) {
        throw "XAML URL is not set in the configuration."
    }
    # Download XAML content as a string
    $xamlContent = (Invoke-WebRequest -Uri $xamlUrl -ErrorAction Stop).Content

    # Load the XAML using XamlReader.Load with a MemoryStream
    $encoding = [System.Text.Encoding]::UTF8
    $xamlBytes = $encoding.GetBytes($xamlContent)
    $xamlStream = [System.IO.MemoryStream]::new($xamlBytes)

    # Parse the XAML content
    $window = [System.Windows.Markup.XamlReader]::Load($xamlStream)
    $readerOperationSuccessful = $true

    # Clean up stream
    $xamlStream.Close()
    Write-Host "XAML GUI loaded successfully." -ForegroundColor Green
}
catch {
    Write-Host "Error loading XAML from URL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Define the drag behavior for the window
function Window_MouseLeftButtonDown {
    param (
        $sender, 
        $eventArgs
    )
    # Start dragging the window
    $window.DragMove()
}

function Update-ProgressIndicator {
    param (
        [int]$currentScreen
    )
    # Set colors based on the current screen
    $ProgressStep1.Fill = if ($currentScreen -ge 1) { "#FFDE00" } else { "#FFEB99" }
    $ProgressStep2.Fill = if ($currentScreen -ge 2) { "#FFDE00" } else { "#FFEB99" }
    $ProgressStep3.Fill = if ($currentScreen -ge 3) { "#FFDE00" } else { "#FFEB99" }
    $ProgressStep4.Fill = if ($currentScreen -ge 4) { "#FFDE00" } else { "#FFEB99" }
}

# Check if XAML loaded successfully
if ($readerOperationSuccessful) {
    # Define Controls consistently using $window
    $ProgressStep1 = $window.FindName("ProgressStep1")
    $ProgressStep2 = $window.FindName("ProgressStep2")
    $ProgressStep3 = $window.FindName("ProgressStep3")
    $ProgressStep4 = $window.FindName("ProgressStep4")
    $SelectISOScreen = $window.FindName("SelectISOScreen")
    $ISOPathTextBox = $window.FindName("ISOPathTextBox")
    $WorkingDirectoryTextBox = $window.FindName("WorkingDirectoryTextBox")
    $DownloadWin10Button = $window.FindName("DownloadWin10Button")
    $DownloadWin11Button = $window.FindName("DownloadWin11Button")
    $AddXMLFileScreen = $window.FindName("AddXMLFileScreen")
    $DownloadUWTextBox = $window.FindName("DownloadUWTextBox")
    $ManualXMLPathTextBox = $window.FindName("ManualXMLPathTextBox")
    $AddDriversScreen = $window.FindName("AddDriversScreen")
    $CreateISOScreen = $window.FindName("CreateISOScreen")
    $CloseButton = $window.FindName("CloseButton")
    $NextButton = $window.FindName("NextButton")
    $NextButton.IsEnabled = $false
    $BackButton = $window.FindName("BackButton")
    $SelectISOButton = $window.FindName("SelectISOButton")
    $SelectWorkingDirectoryButton = $window.FindName("SelectWorkingDirectoryButton")
    $StartISOExtractionButton = $window.FindName("StartISOExtractionButton")
    $ExtractISOStatusText = $window.FindName("ExtractISOStatusText")
    $AddXMLStatusText = $window.FindName("AddXMLStatusText")
    $DownloadUWXMLButton = $window.FindName("DownloadUWXMLButton")
    $SelectXMLFileButton = $window.FindName("SelectXMLFileButton")
    $AddDriversStatusText = $window.FindName("AddDriversStatusText")
    $AddDriversToImageButton = $window.FindName("AddDriversToImageButton")
    $AddRecDriversButton = $window.FindName("AddRecDriversButton")
    $AddDriversToImageTextBox = $window.FindName("AddDriversToImageTextBox")
    $AddRecDriversTextBox = $window.FindName("AddRecDriversTextBox")
    $CreateISOStatusText = $window.FindName("CreateISOStatusText")
    $GetoscdimgButton = $window.FindName("GetoscdimgButton")
    $CreateISOButton = $window.FindName("CreateISOButton")
    $SelectISOLocationButton = $window.FindName("SelectISOLocationButton")
    $CreateISOTextBox = $window.FindName("CreateISOTextBox")


    function ShowScreen {
        Write-Host "Current Screen Index: $script:currentScreenIndex"  # Debugging line
    
        # Update the progress indicator
        Update-ProgressIndicator -currentScreen $script:currentScreenIndex
    
        # Hide all screens initially
        $SelectISOScreen.Visibility = [System.Windows.Visibility]::Collapsed
        $AddXMLFileScreen.Visibility = [System.Windows.Visibility]::Collapsed
        $AddDriversScreen.Visibility = [System.Windows.Visibility]::Collapsed
        $CreateISOScreen.Visibility = [System.Windows.Visibility]::Collapsed
    
        # Show the target screen based on the current index
        switch ($script:currentScreenIndex) {
            1 { 
                $SelectISOScreen.Visibility = [System.Windows.Visibility]::Visible
                $BackButton.IsEnabled = $false 
                $NextButton.Content = "Next"
                $NextButton.IsEnabled = $true  
            }
            2 { 
                $AddXMLFileScreen.Visibility = [System.Windows.Visibility]::Visible
                $BackButton.IsEnabled = $true  
                $NextButton.Content = "Next"
                $NextButton.IsEnabled = $true
            }
            3 { 
                $AddDriversScreen.Visibility = [System.Windows.Visibility]::Visible
                $BackButton.IsEnabled = $true  
                $NextButton.Content = "Next"
                $NextButton.IsEnabled = $true
            }
            4 { 
                $CreateISOScreen.Visibility = [System.Windows.Visibility]::Visible
                $BackButton.IsEnabled = $true  
                $NextButton.Content = "Exit"  # Change "Next" to "Exit" on the last screen
                $NextButton.IsEnabled = $true
    
                # Check if oscdimg is available when the "Create New ISO" screen loads
                CheckOscdimg
            }
        }
    
        [System.Windows.Forms.Application]::DoEvents() 
    }
    
    ShowScreen    

    # Close button function
    function CleanupAndExit {
        # Check if the working directory or drivers folder exists
        $DriversDir = Join-Path -Path (Split-Path -Parent $Script:WorkingDirectory) -ChildPath "Drivers"
        $workingDirExists = $Script:WorkingDirectory -and (Test-Path -Path $Script:WorkingDirectory)
        $driversDirExists = Test-Path -Path $DriversDir
    
        # If neither directory exists, skip the cleanup prompt
        if (-not $workingDirExists -and -not $driversDirExists) {
            Write-Host "No directories to clean up. Exiting without cleanup prompt."
            $window.Close()
            return
        }
    
        # Show a confirmation popup to ask for cleanup
        $result = [System.Windows.MessageBox]::Show(
            "Do you want to clean up the working directory to free up space? (Drivers folder will not be deleted; please remove manually if needed.)", 
            "Cleanup Confirmation", 
            [System.Windows.MessageBoxButton]::YesNo, 
            [System.Windows.MessageBoxImage]::Question
        )
    
        # If the user chooses "Yes," attempt to delete the working directory
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            if ($workingDirExists) {
                try {
                    Remove-Item -Path $Script:WorkingDirectory -Recurse -Force
                    Write-Host "Working directory cleaned up successfully."
                }
                catch {
                    Write-Host "Failed to clean up the working directory: $_"
                }
            }
        }
    
        # Close the application
        $window.Close()
    }
  

    # Helper Functions
    function UpdateStartISOExtractionButtonState {
        if ($Script:SelectedISO -and $Script:WorkingDirectory) {
            $StartISOExtractionButton.IsEnabled = $true
        }
        else {
            $StartISOExtractionButton.IsEnabled = $false
        }
    }
    

    function SelectLocation {
        param (
            [string]$Mode = "Folder", # Accepts "Folder" or "File"
            [string]$Title = "Select a location",
            [string]$Filter = "All Files (*.*)|*.*" # Applicable only for File mode
        )
    
        Add-Type -AssemblyName System.Windows.Forms
    
        if ($Mode -eq "Folder") {
            $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $FolderBrowserDialog.Description = $Title
            $FolderBrowserDialog.ShowNewFolderButton = $true
    
            if ($FolderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                return $FolderBrowserDialog.SelectedPath
            }
        }
        elseif ($Mode -eq "File") {
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $OpenFileDialog.Title = $Title
            $OpenFileDialog.Filter = $Filter
    
            if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                return $OpenFileDialog.FileName
            }
        }
    
        return $null # User canceled
    }
    

    function SelectWorkingDirectory {
        # Prompt the user to select a working directory
        $baseDirectory = SelectLocation -Mode "Folder" -Title "Select a directory for working files"
    
        if ($baseDirectory) {
            $Script:WorkingDirectory = Join-Path -Path $baseDirectory -ChildPath "WIMUtil"
    
            # Extract the drive letter and ensure it's valid
            $driveLetter = (Split-Path -Qualifier $baseDirectory).TrimEnd(":")
            try {
                $drive = Get-PSDrive -Name $driveLetter
                if (-not $drive) {
                    throw "Drive not found for the selected directory."
                }
            }
            catch {
                $Script:WorkingDirectory = $null
                $WorkingDirectoryTextBox.Text = "Error determining drive space. Please try again."
                [System.Windows.MessageBox]::Show(
                    "Could not determine free space for the selected directory. Please try again.", 
                    "Error", 
                    [System.Windows.MessageBoxButton]::OK, 
                    [System.Windows.MessageBoxImage]::Error
                )
                return
            }
    
            # Free space validation
            $requiredSpace = 10GB
            if ($drive.Free -ge $requiredSpace) {
                # Create the WIMUtil directory if it doesn't already exist
                if (-not (Test-Path -Path $Script:WorkingDirectory)) {
                    New-Item -ItemType Directory -Path $Script:WorkingDirectory -Force | Out-Null
                }
    
                # Update the TextBox with the actual working directory path
                $WorkingDirectoryTextBox.Text = "Working directory created: $Script:WorkingDirectory"
            }
            else {
                $Script:WorkingDirectory = $null
                $WorkingDirectoryTextBox.Text = "Insufficient space. Please select a directory with at least 10GB of free space."
                [System.Windows.MessageBox]::Show(
                    "The selected drive/partition does not have enough space. Please select a different directory.", 
                    "Insufficient Space", 
                    [System.Windows.MessageBoxButton]::OK, 
                    [System.Windows.MessageBoxImage]::Error
                )
            }
        }
        UpdateStartISOExtractionButtonState
    }
    
    


    # Select ISO function
    function SelectISO {
        $Script:SelectedISO = SelectLocation -Mode "File" -Title "Select an ISO file" -Filter "ISO Files (*.iso)|*.iso"
        if ($Script:SelectedISO) {
            Write-Host "Selected ISO: $Script:SelectedISO"
            $ISOPathTextBox.Text = "Windows ISO file selected at $Script:SelectedISO"
        }
        UpdateStartISOExtractionButtonState
    }
    
    
    # Function to extract ISO
    function ExtractISO {
        # Ensure the working directory is set and exists
        if (-not $Script:WorkingDirectory -or -not (Test-Path -Path $Script:WorkingDirectory)) {
            SetStatusText -message "Please select a working directory first." -color $Script:ErrorColor -textBlock ([ref]$ExtractISOStatusText)
            return
        }
    
        # Extract and validate the drive
        $driveLetter = (Split-Path -Qualifier $Script:WorkingDirectory).TrimEnd(":")
        try {
            $drive = Get-PSDrive -Name $driveLetter
            if (-not $drive) {
                throw "Drive not found for the selected directory."
            }
        }
        catch {
            SetStatusText -message "Error determining free space for the selected directory. Please try again." -color $Script:ErrorColor -textBlock ([ref]$ExtractISOStatusText)
            return
        }
    
        # Check if the drive has enough free space
        $requiredSpace = 10GB
        if ($drive.Free -ge $requiredSpace) {
            SetStatusText -message "Sufficient space available. Preparing working directory..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
            [System.Windows.Forms.Application]::DoEvents()
    
            # Clear the working directory if it already exists
            if (Test-Path -Path $Script:WorkingDirectory) {
                SetStatusText -message "Deleting existing working directory..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                [System.Windows.Forms.Application]::DoEvents()
                Remove-Item -Path $Script:WorkingDirectory -Recurse -Force
            }
    
            # Create a fresh working directory
            SetStatusText -message "Creating new working directory..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
            [System.Windows.Forms.Application]::DoEvents()
            New-Item -ItemType Directory -Path $Script:WorkingDirectory -Force | Out-Null
    
            try {
                # Mount the ISO
                SetStatusText -message "Mounting $Script:SelectedISO..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                [System.Windows.Forms.Application]::DoEvents()
                $mountResult = Mount-DiskImage -ImagePath $Script:SelectedISO -PassThru
                $driveLetter = ($mountResult | Get-Volume).DriveLetter + ":"
    
                # Copy files from the mounted ISO to the working directory
                SetStatusText -message "Copying files from mounted ISO ($driveLetter) to $Script:WorkingDirectory..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                [System.Windows.Forms.Application]::DoEvents()
                Copy-Item -Path "$driveLetter\*" -Destination $Script:WorkingDirectory -Recurse -Force
    
                # Remove autounattend.xml if it exists
                $autounattendPath = Join-Path -Path $Script:WorkingDirectory -ChildPath "autounattend.xml"
                if (Test-Path -Path $autounattendPath) {
                    try {
                        Remove-Item -Path $autounattendPath -Force -ErrorAction Stop
                        SetStatusText -message "autounattend.xml from the ISO was successfully removed from the working directory." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                    }
                    catch {
                        SetStatusText -message "Failed to delete autounattend.xml: $_" -color $Script:ErrorColor -textBlock ([ref]$ExtractISOStatusText)
                    }
                }
    
                # Dismount the ISO
                SetStatusText -message "Dismounting ISO..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                [System.Windows.Forms.Application]::DoEvents()
                Dismount-DiskImage -ImagePath $Script:SelectedISO
    
                # Mark extraction as completed
                SetStatusText -message "Extraction completed. Click Next to Continue." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                [System.Windows.Forms.Application]::DoEvents()
    
                # Enable the Next Button now that extraction is complete
                $NextButton.IsEnabled = $true
            }
            catch {
                SetStatusText -message "Extraction failed: $_" -color $Script:ErrorColor -textBlock ([ref]$ExtractISOStatusText)
                [System.Windows.Forms.Application]::DoEvents()
                Dismount-DiskImage -ImagePath $Script:SelectedISO -ErrorAction SilentlyContinue
            }
        }
        else {
            SetStatusText -message "Not enough space on the selected drive for extraction." -color $Script:ErrorColor -textBlock ([ref]$ExtractISOStatusText)
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    
    
    # Download ISO functions
    function DownloadWindows10ISO {
        Start-Process "https://www.microsoft.com/software-download/windows10"
    }
    
    function DownloadWindows11ISO {
        Start-Process "https://www.microsoft.com/software-download/windows11"
    }
    
    

    # Download UnattendedWinstall XML File function
    function DownloadUWXML {
        SetStatusText -message "Downloading the latest UnattendedWinstall XML file..." -color $Script:SuccessColor -textBlock ([ref]$AddXMLStatusText)
        [System.Windows.Forms.Application]::DoEvents()
    
        $url = "https://github.com/memstechtips/UnattendedWinstall/raw/main/autounattend.xml"
        $destination = Join-Path -Path $Script:WorkingDirectory -ChildPath "autounattend.xml"
    
        try {
            (New-Object System.Net.WebClient).DownloadFile($url, $destination)
            SetStatusText -message "Latest UnattendedWinstall XML file added successfully." -color $Script:SuccessColor -textBlock ([ref]$AddXMLStatusText)
    
            # Update the DownloadUWTextBox content with the success message
            $DownloadUWTextBox.Text = "Answer file added to: $destination"
        }
        catch {
            SetStatusText -message "Failed to download the file: $_" -color $Script:ErrorColor -textBlock ([ref]$AddXMLStatusText)
        }
        [System.Windows.Forms.Application]::DoEvents()
    }
    


    # SelectXMLFile function
    function SelectXMLFile {
        SetStatusText -message "Please select an XML file..." -color $Script:SuccessColor -textBlock ([ref]$AddXMLStatusText)
        [System.Windows.Forms.Application]::DoEvents()
    
        # Use the SelectLocation function for file selection
        $selectedFile = SelectLocation -Mode "File" -Title "Select an XML file" -Filter "XML Files (*.xml)|*.xml"
    
        if ($selectedFile) {
            $destination = Join-Path -Path $Script:WorkingDirectory -ChildPath "autounattend.xml"
    
            # Check if an existing autounattend.xml file is present and delete it
            if (Test-Path -Path $destination) {
                try {
                    Remove-Item -Path $destination -Force
                    Write-Host "Existing autounattend.xml file deleted."
                }
                catch {
                    SetStatusText -message "Failed to delete existing autounattend.xml file: $_" -color $Script:ErrorColor -textBlock ([ref]$AddXMLStatusText)
                    return
                }
            }
    
            try {
                # Copy the selected file to the destination
                Copy-Item -Path $selectedFile -Destination $destination -Force
                SetStatusText -message "Selected XML file added successfully." -color $Script:SuccessColor -textBlock ([ref]$AddXMLStatusText)
    
                # Update the ManualXMLPathTextBox with the success message
                $ManualXMLPathTextBox.Text = "Answer file added to: $destination"
            }
            catch {
                SetStatusText -message "Failed to add the selected file: $_" -color $Script:ErrorColor -textBlock ([ref]$AddXMLStatusText)
            }
        }
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    

    function ConvertEsdToWim {
        param (
            [string]$ImageFile  # Path to the image file (WIM or ESD)
        )
    
        if ($ImageFile -like "*.esd") {
            $convertedWimFile = [System.IO.Path]::ChangeExtension($ImageFile, ".wim")
            SetStatusText -message "Detected .esd file. Converting to .wim: $convertedWimFile" -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
            [System.Windows.Forms.Application]::DoEvents()
    
            try {
                # Ensure paths with spaces are properly quoted
                $quotedImageFile = "`"$ImageFile`""
                $quotedConvertedWimFile = "`"$convertedWimFile`""
                Start-Process -FilePath "dism" -ArgumentList "/export-image /sourceimagefile:$quotedImageFile /sourceindex:1 /destinationimagefile:$quotedConvertedWimFile /compress:max /checkintegrity" -NoNewWindow -Wait
                SetStatusText -message "Conversion to .wim completed successfully: $convertedWimFile" -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
                [System.Windows.Forms.Application]::DoEvents()
    
                # Delete the original ESD file
                Write-Host "Deleting original .esd file: $ImageFile..."
                Remove-Item -Path $ImageFile -Force
                Write-Host "Original .esd file deleted successfully."
                SetStatusText -message "Original .esd file deleted successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
    
                return $convertedWimFile
            }
            catch {
                SetStatusText -message "Error converting .esd to .wim: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
                Write-Host "Error: $_"
                return $null
            }
        }
        else {
            # If it's already a WIM file, return it as-is
            return $ImageFile
        }
    }
    
    
    
    function MountWimImage {
        param (
            [string]$WimFile, # Path to the WIM file
            [string]$MountDir   # Path to the mount directory
        )
    
        if (!(Test-Path -Path $MountDir)) {
            New-Item -ItemType Directory -Path $MountDir -Force | Out-Null
        }
    
        try {
            # Ensure paths with spaces are properly quoted
            $quotedWimFile = "`"$WimFile`""
            $quotedMountDir = "`"$MountDir`""
            SetStatusText -message "Mounting WIM image: $WimFile to $MountDir..." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Mounting WIM image: $WimFile to $MountDir..."
            Start-Process -FilePath "dism" -ArgumentList "/mount-wim /wimfile:$quotedWimFile /index:1 /mountdir:$quotedMountDir" -NoNewWindow -Wait
            SetStatusText -message "WIM image mounted successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "WIM image mounted successfully."
            return $true
        }
        catch {
            SetStatusText -message "Error mounting WIM image: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Error mounting WIM image: $_"
            return $false
        }
    }
    
    

    function AddDriversToDriverStore {
        param (
            [string]$DriverPath, # Path to the exported drivers
            [string]$MountDir     # Path to the mounted WIM directory
        )
    
        try {
            # Ensure paths with spaces are properly quoted
            $quotedDriverPath = "`"$DriverPath`""
            $quotedMountDir = "`"$MountDir`""
            SetStatusText -message "Adding drivers from $DriverPath to the Driver Store in $MountDir..." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            Start-Process -FilePath "dism" -ArgumentList "/image:$quotedMountDir /add-driver /driver:$quotedDriverPath /recurse" -NoNewWindow -Wait
            SetStatusText -message "Drivers added to the Driver Store successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            [System.Windows.Forms.Application]::DoEvents()
            return $true
        }
        catch {
            SetStatusText -message "Error adding drivers to the Driver Store: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Error adding drivers to the Driver Store: $_"
            return $false
        }
    }
    

    function CommitAndUnmountWim {
        param (
            [string]$MountDir   # Path to the mount directory
        )
    
        try {
            SetStatusText -message "Committing changes and unmounting WIM image..." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            Start-Process -FilePath "dism" -ArgumentList "/unmount-wim /mountdir:$MountDir /commit" -NoNewWindow -Wait
            SetStatusText -message "WIM image unmounted and changes committed successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            [System.Windows.Forms.Application]::DoEvents()
            return $true
        }
        catch {
            SetStatusText -message "Error unmounting WIM image: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return $false
        }
    }
    
    function AddDriversToImage {
        param (
            [string]$WorkingDirectory = $Script:WorkingDirectory, # Default to global variable if not provided
            [string]$ImageFile = (Join-Path -Path $Script:WorkingDirectory -ChildPath "sources\install.esd"), # Default ImageFile
            [string]$MountParentDir = (Split-Path -Parent $Script:WorkingDirectory) # Default to parent of working directory
        )
        
        # Validate input parameters
        if (-not $WorkingDirectory) {
            SetStatusText -message "Error: Working directory is not set." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Error: Working directory is not set."
            return
        }
    
        if (-not $ImageFile) {
            SetStatusText -message "Error: Image file is not set." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Error: Image file is not set."
            return
        }
    
        if (-not $MountParentDir) {
            SetStatusText -message "Error: Mount parent directory is not set." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Error: Mount parent directory is not set."
            return
        }
    
        # Define paths
        $DriversDir = Join-Path -Path (Split-Path -Parent $WorkingDirectory) -ChildPath "Drivers"
        $MountDir = Join-Path -Path $MountParentDir -ChildPath "WIMMount"
        $WimDestination = Join-Path -Path (Join-Path -Path $WorkingDirectory -ChildPath "sources") -ChildPath "install.wim"
    
        # Validate mount directory and working directory
        if ($MountDir -eq $WorkingDirectory) {
            SetStatusText -message "Error: Mount directory cannot be the same as the working directory." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Error: Mount directory cannot be the same as the working directory."
            return
        }
    
        # Check free space (10GB minimum)
        $driveLetter = (Split-Path -Qualifier $MountParentDir).TrimEnd(":")
        try {
            $drive = Get-PSDrive -Name $driveLetter
            if (-not $drive) {
                throw "Drive not found for the mount parent directory."
            }
        }
        catch {
            SetStatusText -message "Error: Could not determine free space for the selected mount parent directory." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Error: Could not determine free space for the selected mount parent directory."
            return
        }
    
        if ($drive.Free -lt 10GB) {
            SetStatusText -message "Error: Not enough free space for mounting WIM." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Error: Not enough free space for mounting WIM."
            return
        }
    
        # Start the driver injection process
        Write-Host "Starting AddDriversToImage process..." -ForegroundColor $Script:NeutralColor
        SetStatusText -message "Starting driver injection process..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
        # Step 1: Convert ESD to WIM if needed
        $ImageFile = ConvertEsdToWim -ImageFile $ImageFile
        if (-not $ImageFile) {
            SetStatusText -message "Error: Failed to convert ImageFile." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Error: Failed to convert ImageFile."
            return
        }
    
        # Step 2: Export drivers
        if (!(Test-Path -Path $DriversDir)) {
            New-Item -ItemType Directory -Path $DriversDir -Force | Out-Null
        }
    
        Write-Host "Exporting drivers to external folder: $DriversDir..."
        SetStatusText -message "Exporting drivers to external folder: $DriversDir..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
        try {
            # Ensure paths with spaces are properly quoted
            $quotedDriversDir = "`"$DriversDir`""
            Start-Process -FilePath "dism" -ArgumentList "/online /export-driver /destination:$quotedDriversDir" -NoNewWindow -Wait
            Write-Host "Drivers exported successfully to $DriversDir."
            SetStatusText -message "Drivers exported successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
        }
        catch {
            SetStatusText -message "Error exporting drivers: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Error exporting drivers: $_"
            return
        }
    
        # Step 3: Mount the WIM
        $quotedMountDir = "`"$MountDir`""
        $quotedImageFile = "`"$ImageFile`""
        if (-not (MountWimImage -WimFile $quotedImageFile -MountDir $quotedMountDir)) {
            Write-Host "Error: Failed to mount WIM image."
            SetStatusText -message "Error: Failed to mount WIM image." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return
        }
    
        # Step 4: Inject drivers
        Write-Host "Adding drivers to WIM image..."
        SetStatusText -message "Adding drivers to WIM image..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
        if (-not (AddDriversToDriverStore -DriverPath $quotedDriversDir -MountDir $quotedMountDir)) {
            Write-Host "Error: Failed to add drivers to WIM image."
            SetStatusText -message "Error: Failed to add drivers to WIM image." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return
        }
    
        # Step 5: Unmount and commit
        if (-not (CommitAndUnmountWim -MountDir $quotedMountDir)) {
            Write-Host "Error: Failed to unmount WIM image."
            SetStatusText -message "Error: Failed to unmount WIM image." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return
        }
    
        # Step 6: Copy updated WIM back to the working directory
        Write-Host "Copying updated WIM to $WimDestination..."
        SetStatusText -message "Copying updated WIM to $WimDestination..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
        try {
            Copy-Item -Path $ImageFile -Destination $WimDestination -Force
            Write-Host "Updated WIM copied to $WimDestination successfully."
            SetStatusText -message "Updated WIM copied to working directory successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
        }
        catch {
            Write-Host "Error copying updated WIM: $_"
            SetStatusText -message "Error copying updated WIM: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return
        }
    
        # Step 7: Clean up the WIMMount directory
        Write-Host "Cleaning up WIMMount directory: $MountDir..."
        SetStatusText -message "Cleaning up WIMMount directory..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
        try {
            Remove-Item -Path $MountDir -Recurse -Force
            Write-Host "WIMMount directory cleaned up successfully."
            SetStatusText -message "WIMMount directory cleaned up successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
        }
        catch {
            Write-Host "Error cleaning up WIMMount directory: $_"
            SetStatusText -message "Error cleaning up WIMMount directory: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
        }
    
        Write-Host "Driver injection process completed successfully!" -ForegroundColor $Script:SuccessColor
        SetStatusText -message "Driver injection completed successfully!" -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
    }
    
    
    
    
    function AddRecommendedDrivers {
        SetStatusText -message "Checking for driver directory..." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
        [System.Windows.Forms.Application]::DoEvents()
    
        # Define driver directory with escaped $ symbols
        $winpeDriverDir = "C:\WIMUtil\`$WinpeDriver`$"
    
        # Check if the directory exists; if not, create it
        if (!(Test-Path -Path $winpeDriverDir)) {
            New-Item -ItemType Directory -Path $winpeDriverDir | Out-Null
            SetStatusText -message "Created driver directory: $winpeDriverDir" -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            SetStatusText -message "Essential storage and network drivers added successfully." -color $Script:NeutralColor -textBlock ([ref]$AddRecDriversTextBox)
            [System.Windows.Forms.Application]::DoEvents()
        }
    
        # Placeholder URLs for downloading drivers
        $driverURLs = @(
            "https://github.com/yourrepo/IRSTdriver.zip",
            "https://github.com/yourrepo/VMDdriver.zip",
            "https://github.com/yourrepo/WiFidriver.zip"
        )
    
        # Download each driver file
        foreach ($url in $driverURLs) {
            try {
                $fileName = [System.IO.Path]::GetFileName($url)
                $destinationPath = Join-Path -Path $winpeDriverDir -ChildPath $fileName  
                SetStatusText -message "Downloading $fileName..." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)

                [System.Windows.Forms.Application]::DoEvents()
    
                (New-Object System.Net.WebClient).DownloadFile($url, $destinationPath)
                SetStatusText -message "$fileName downloaded successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)

                [System.Windows.Forms.Application]::DoEvents()
            }
            catch {
                SetStatusText -message "Error downloading ${fileName}: $($_)" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)

                [System.Windows.Forms.Application]::DoEvents()
            }
        }
    
        SetStatusText -message "All recommended drivers added successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)

        [System.Windows.Forms.Application]::DoEvents()
    }

    # Function to get the SHA-256 hash of a file
    function Get-FileHashValue {
        param (
            [string]$filePath
        )

        if (Test-Path -Path $filePath) {
            $hashObject = Get-FileHash -Path $filePath -Algorithm SHA256
            return $hashObject.Hash
        }
        else {
            Write-Host "File not found at path: $filePath"
            return $null
        }
    }

    # Check if oscdimg exists on the system without checking hash or date
    function CheckOscdimg {
        $oscdimgPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"

        if (Test-Path -Path $oscdimgPath) {
            SetStatusText -message "oscdimg is present on the system." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
            $GetoscdimgButton.IsEnabled = $false
            $CreateISOButton.IsEnabled = $true
        }
        else {
            SetStatusText -message "oscdimg not found. Please download it." -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
            $GetoscdimgButton.IsEnabled = $true
            $CreateISOButton.IsEnabled = $false
        }

        [System.Windows.Forms.Application]::DoEvents()  # Refresh the UI
    }

    # Function to download and validate oscdimg
    function DownloadOscdimg {
        SetStatusText -message "Preparing to download oscdimg..." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
        [System.Windows.Forms.Application]::DoEvents()

        $adkOscdimgPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
        $oscdimgFullPath = Join-Path -Path $adkOscdimgPath -ChildPath "oscdimg.exe"

        # Ensure the ADK directory exists
        if (!(Test-Path -Path $adkOscdimgPath)) {
            New-Item -ItemType Directory -Path $adkOscdimgPath -Force | Out-Null
            SetStatusText -message "Created directory for oscdimg at: $adkOscdimgPath" -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
            [System.Windows.Forms.Application]::DoEvents()
        }

        # Download oscdimg to the ADK path
        try {
            SetStatusText -message "Downloading oscdimg from: $oscdimgURL" -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
            [System.Windows.Forms.Application]::DoEvents()

        (New-Object System.Net.WebClient).DownloadFile($oscdimgURL, $oscdimgFullPath)
            Write-Host "oscdimg downloaded successfully from: $oscdimgURL"

            # Verify the file's hash
            $actualHash = Get-FileHashValue -filePath $oscdimgFullPath
            if ($actualHash -ne $expectedHash) {
                SetStatusText -message "Hash mismatch! oscdimg may not be from Microsoft." -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
                Write-Host "Expected Hash: $expectedHash"
                Write-Host "Actual Hash: $actualHash"
                Remove-Item -Path $oscdimgFullPath -Force
                return
            }

            # File is valid, enable the Create ISO button
            SetStatusText -message "oscdimg verified and ready for use." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
            $GetoscdimgButton.IsEnabled = $false
            $CreateISOButton.IsEnabled = $true
        }
        catch {
            SetStatusText -message "Failed to download oscdimg: $($_.Exception.Message)" -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
        }

        [System.Windows.Forms.Application]::DoEvents()
    }

    # Define the location selection function
    function SelectNewISOLocation {
        # Ensure the working directory is set and exists
        if (-not $Script:WorkingDirectory -or -not (Test-Path -Path $Script:WorkingDirectory)) {
            [System.Windows.MessageBox]::Show(
                "Working directory is not set or does not exist. Please select a valid working directory first.", 
                "Missing Working Directory", 
                [System.Windows.MessageBoxButton]::OK, 
                [System.Windows.MessageBoxImage]::Error
            )
            return
        }
    
        # Calculate the size of the working directory
        $workingDirSize = (Get-ChildItem -Path $Script:WorkingDirectory -Recurse | Measure-Object -Property Length -Sum).Sum
        $requiredSpace = $workingDirSize + 1GB
    
        # Prompt the user to select the save location for the new ISO file
        $Script:ISOPath = SelectLocation -Mode "File" -Title "Save the new ISO file" -Filter "ISO Files (*.iso)|*.iso"
    
        if ($Script:ISOPath) {
            # Get the drive or partition of the selected ISO path
            $drive = Get-PSDrive -Name (Split-Path -Qualifier $Script:ISOPath)
    
            # Check if there's sufficient space available
            if ($drive.Free -ge $requiredSpace) {
                # Update the TextBox with the selected save location
                $CreateISOTextBox.Text = $Script:ISOPath
                $CreateISOButton.IsEnabled = $true
            }
            else {
                # Reset the ISO path and show an error message
                $Script:ISOPath = $null
                $CreateISOTextBox.Text = "Insufficient space. Please select a location with at least $([math]::Round($requiredSpace / 1GB, 2)) GB free space."
                
                # Display a popup message
                [System.Windows.MessageBox]::Show(
                    "The selected drive/partition does not have enough space. Please select a different location.", 
                    "Insufficient Space", 
                    [System.Windows.MessageBoxButton]::OK, 
                    [System.Windows.MessageBoxImage]::Error
                )
            }
        }
    }
    
    

    # Updated CreateISO function
    function CreateISO {
        if (-not $Script:ISOPath) {
            SetStatusText -message "No save location selected." -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
            return
        }

        SetStatusText -message "Creating ISO file..." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
        [System.Windows.Forms.Application]::DoEvents()

        # Define paths for the boot files
        $sourceDir = "C:\WIMUtil"
        $oscdimgPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        $etfsbootPath = "$sourceDir\boot\etfsboot.com"         # BIOS boot image
        $efisysPath = "$sourceDir\efi\microsoft\boot\efisys.bin"  # UEFI boot image

        # Construct the arguments with dual boot support
        $arguments = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$etfsbootPath`"#pEF,e,b`"$efisysPath`" `"$sourceDir`" `"$Script:ISOPath`""

        try {
            # Use Start-Process to run oscdimg with the correct arguments for dual boot support
            Start-Process -FilePath $oscdimgPath -ArgumentList $arguments -NoNewWindow -Wait
            SetStatusText -message "ISO file successfully saved at $Script:ISOPath." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
        }
        catch {
            SetStatusText -message "Failed to create ISO: $($_.Exception.Message)" -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
        }
    }

    # Attach Event Handlers after functions are defined
    $window.Add_MouseLeftButtonDown({ Window_MouseLeftButtonDown $args[0] $args[1] })
    $SelectWorkingDirectoryButton.Add_Click({ SelectWorkingDirectory })
    $SelectISOButton.Add_Click({ SelectISO })
    $StartISOExtractionButton.Add_Click({ ExtractISO })
    $DownloadWin10Button.Add_Click({ DownloadWindows10ISO })
    $DownloadWin11Button.Add_Click({ DownloadWindows11ISO })
    $CloseButton.Add_Click({ CleanupAndExit })
    $DownloadUWXMLButton.Add_Click({ DownloadUWXML })
    $SelectXMLFileButton.Add_Click({ SelectXMLFile })
    $AddDriversToImageButton.Add_Click({ AddDriversToImage })
    $AddRecDriversButton.Add_Click({ AddRecommendedDrivers })
    $GetoscdimgButton.Add_Click({ DownloadOscdimg })
    $SelectISOLocationButton.Add_Click({ SelectNewISOLocation })
    $CreateISOButton.Add_Click({ CreateISO })

    # Event handler for the Next button
    $NextButton.Add_Click({
            if ($script:currentScreenIndex -eq 4) {
                # On the last screen, execute the CleanupAndExit function for "Exit"
                CleanupAndExit
            }
            else {
                # Increment to the next screen and show it
                $script:currentScreenIndex++
                ShowScreen
            }
        })
    
    
    # Event handler for the Back button
    $BackButton.Add_Click({
            Write-Host "Back button clicked"
            Write-Host "Current Screen Index before decrement: $script:currentScreenIndex"  # Debugging line
    
            if ($script:currentScreenIndex -gt 0) {
                $script:currentScreenIndex--  # Decrement the screen index to move backward
                Write-Host "Current Screen Index after decrement: $script:currentScreenIndex"  # Debugging line
                ShowScreen  # Update the visible screen
            }
            else {
                Write-Host "Back button cannot decrement as currentScreenIndex is already 0"
            }
        })

    # Force disable NextButton before showing the window
    $NextButton.IsEnabled = $false
    $window.ShowDialog()

}
else {
    Write-Host "Failed to load the XAML file. Exiting script." -ForegroundColor Red
    Pause
    exit 1
}