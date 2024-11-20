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
$configUrl = "https://raw.githubusercontent.com/memstechtips/WIMUtil/main/config/wimutil-settings.json"  # Main branch
# $configUrl = "https://raw.githubusercontent.com/memstechtips/WIMUtil/dev/config/wimutil-settings.json"   # Dev branch

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

    function RefreshGUI {
        [System.Windows.Forms.Application]::DoEvents()
    }

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

        RefreshGUI 
    }
    
    ShowScreen    

    # Close button function
    function CleanupAndExit {
        # Check if the working directory exists
        $workingDirExists = $Script:WorkingDirectory -and (Test-Path -Path $Script:WorkingDirectory)
    
        # If the directory doesn't exist, skip the cleanup prompt
        if (-not $workingDirExists) {
            Write-Host "No directories to clean up. Exiting without cleanup prompt."
            $window.Close()  # Close the window
            return
        }
    
        # Show a confirmation popup with Yes, No, and Cancel options
        $result = [System.Windows.MessageBox]::Show(
            "Do you want to clean up the working directory to free up space? 
            - Selecting 'Yes' will delete the working directory. 
            - Selecting 'No' will exit without cleanup. 
            - Selecting 'Cancel' will allow you to return to the application.", 
            "Cleanup Confirmation", 
            [System.Windows.MessageBoxButton]::YesNoCancel, 
            [System.Windows.MessageBoxImage]::Question
        )
    
        # Handle the user's response
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            # Attempt to delete the working directory
            if ($workingDirExists) {
                try {
                    Write-Host "Attempting to delete the working directory: $Script:WorkingDirectory"
                    Remove-Item -Path $Script:WorkingDirectory -Recurse -Force -ErrorAction Stop
                    Write-Host "Working directory cleaned up successfully."
                }
                catch {
                    Write-Host "Failed to clean up the working directory: $_"
                    [System.Windows.MessageBox]::Show(
                        "Failed to delete the working directory. Error: $($_.Exception.Message)", 
                        "Cleanup Error", 
                        [System.Windows.MessageBoxButton]::OK, 
                        [System.Windows.MessageBoxImage]::Error
                    )
                }
            }
            # Close the application after cleanup
            $window.Close()
        }
        elseif ($result -eq [System.Windows.MessageBoxResult]::No) {
            # Close the application without cleanup
            Write-Host "User chose not to clean up. Exiting without cleanup."
            $window.Close()
        }
        elseif ($result -eq [System.Windows.MessageBoxResult]::Cancel) {
            # Allow the user to continue the application
            Write-Host "User canceled the cleanup process. Returning to the application."
        }
    }
    
    # Helper Functions
    function QuotePath {
        param (
            [string]$Path
        )
        if ($Path -match '\s' -and $Path -notmatch '^".*"$') {
            return '"' + $Path + '"'
        }
        return $Path
    }      
    
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
            [string]$Mode = "Folder", # Accepts "Folder", "File", or "Save"
            [string]$Title = "Select a location",
            [string]$Filter = "All Files (*.*)|*.*" # Applicable only for File or Save modes
        )
    
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
        elseif ($Mode -eq "Save") {
            $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
            $SaveFileDialog.Title = $Title
            $SaveFileDialog.Filter = $Filter
    
            if ($SaveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                return $SaveFileDialog.FileName
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
                SetStatusText -message "Working directory created. Click Start to continue." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                $WorkingDirectoryTextBox.Text = "Working directory created: $Script:WorkingDirectory"
                RefreshGUI
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
            SetStatusText -message "Windows ISO file selected. Select a working directory next." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
            $ISOPathTextBox.Text = "Windows ISO file selected at $Script:SelectedISO"
            RefreshGUI
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
            RefreshGUI
    
            # Clear the working directory if it already exists
            if (Test-Path -Path $Script:WorkingDirectory) {
                SetStatusText -message "Deleting existing working directory..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                RefreshGUI
                Remove-Item -Path $Script:WorkingDirectory -Recurse -Force
            }
    
            # Create a fresh working directory
            SetStatusText -message "Creating new working directory..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
            RefreshGUI
            New-Item -ItemType Directory -Path $Script:WorkingDirectory -Force | Out-Null
    
            try {
                # Mount the ISO
                SetStatusText -message "Mounting $Script:SelectedISO..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                RefreshGUI
                $mountResult = Mount-DiskImage -ImagePath $Script:SelectedISO -PassThru
                $driveLetter = ($mountResult | Get-Volume).DriveLetter + ":"
    
                # Copy files from the mounted ISO to the working directory
                SetStatusText -message "Copying files from ISO. This might take a while, please wait..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                RefreshGUI
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
                SetStatusText -message "Dismounting ISO, please wait..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                RefreshGUI
                Dismount-DiskImage -ImagePath $Script:SelectedISO
    
                # Mark extraction as completed
                SetStatusText -message "Extraction completed. Click Next to Continue." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                RefreshGUI
    
                # Enable the Next Button now that extraction is complete
                $NextButton.IsEnabled = $true
            }
            catch {
                SetStatusText -message "Extraction failed: $_" -color $Script:ErrorColor -textBlock ([ref]$ExtractISOStatusText)
                RefreshGUI
                Dismount-DiskImage -ImagePath $Script:SelectedISO -ErrorAction SilentlyContinue
            }
        }
        else {
            SetStatusText -message "Not enough space on the selected drive for extraction." -color $Script:ErrorColor -textBlock ([ref]$ExtractISOStatusText)
            RefreshGUI
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
        RefreshGUI
    
        $url = "https://github.com/memstechtips/UnattendedWinstall/raw/main/autounattend.xml"
        $destination = Join-Path -Path $Script:WorkingDirectory -ChildPath "autounattend.xml"
    
        try {
            (New-Object System.Net.WebClient).DownloadFile($url, $destination)
            SetStatusText -message "Latest UnattendedWinstall XML file added. Click Next to Continue." -color $Script:SuccessColor -textBlock ([ref]$AddXMLStatusText)
    
            # Update the DownloadUWTextBox content with the success message
            $DownloadUWTextBox.Text = "Answer file added to: $destination"
        }
        catch {
            SetStatusText -message "Failed to download the file: $_" -color $Script:ErrorColor -textBlock ([ref]$AddXMLStatusText)
        }
        RefreshGUI
    }
    


    # SelectXMLFile function
    function SelectXMLFile {
        SetStatusText -message "Please select an XML file..." -color $Script:SuccessColor -textBlock ([ref]$AddXMLStatusText)
        RefreshGUI
    
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
                SetStatusText -message "Selected XML file added successfully. Click Next to Continue." -color $Script:SuccessColor -textBlock ([ref]$AddXMLStatusText)
    
                # Update the ManualXMLPathTextBox with the success message
                $ManualXMLPathTextBox.Text = "Answer file added to: $destination"
            }
            catch {
                SetStatusText -message "Failed to add the selected file: $_" -color $Script:ErrorColor -textBlock ([ref]$AddXMLStatusText)
            }
        }
        RefreshGUI
    }
    
    
    # Working on this later
    function ConvertEsdToWim {
        param (
            [string]$ImageFile
        )
    
        if ($ImageFile -imatch '\.esd$') {
            $convertedWimFile = [System.IO.Path]::ChangeExtension($ImageFile, '.wim')
            SetStatusText -message "Detected .esd file. Converting to .wim: $convertedWimFile" -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
            try {
                # Ensure paths are properly quoted
                $quotedImageFile = QuotePath -Path $ImageFile
                $quotedConvertedWimFile = QuotePath -Path $convertedWimFile
    
                # Construct the DISM command
                $dismCommand = "/export-image /sourceimagefile:$quotedImageFile /SourceIndex:2 /destinationimagefile:$quotedConvertedWimFile /compress:recovery /CheckIntegrity"
    
                # Log the command for debugging
                Write-Host "Executing DISM Command: dism $dismCommand"
    
                # Execute the DISM command
                Start-Process -FilePath 'dism' -ArgumentList $dismCommand -NoNewWindow -Wait
    
                Write-Host "Conversion completed successfully."
                SetStatusText -message "Conversion completed successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
    
                # Remove the original .esd file
                Remove-Item -Path $ImageFile -Force
                Write-Host "Original .esd file deleted successfully."
    
                # Return the converted WIM file path
                Write-Host "Debug: Returning converted WIM file path: $convertedWimFile"
                return $convertedWimFile
            }
            catch {
                Write-Error "Error during ESD-to-WIM conversion: $_"
                SetStatusText -message "Error during ESD-to-WIM conversion: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
                return $null
            }
        }
    
        # If the file is not .esd, return it unmodified
        Write-Host "Debug: Returning original ImageFile path: $ImageFile"
        return $ImageFile
    }
    
    function ExportDrivers {
        # Validate that $Script:WorkingDirectory is set
        if (-not $Script:WorkingDirectory) {
            Write-Error "Error: WorkingDirectory is not set. Please select a working directory first."
            return $false
        }
    
        # Construct the DriversDir path with literal $OEM$ and $1
        $DriversDir = Join-Path -Path $Script:WorkingDirectory -ChildPath 'Sources\$OEM$\$1\Drivers'
    
        try {
            # Ensure the target directory exists, create it if necessary
            if (-not (Test-Path -Path $DriversDir)) {
                Write-Host "Directory does not exist. Creating directory: $DriversDir"
                New-Item -ItemType Directory -Path $DriversDir -Force | Out-Null
            }
            else {
                Write-Host "Directory already exists: $DriversDir"
            }
    
            # Notify the user about the export process
            SetStatusText -message "Exporting drivers, please wait..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Exporting drivers to $DriversDir, please wait..."
    
            # Quote the DriversDir path to handle spaces
            $quotedDriversDir = "`"$DriversDir`""
    
            # Execute the DISM command to export drivers
            $dismCommand = "/online /export-driver /destination:$quotedDriversDir"
            Write-Host "Executing DISM command: dism $dismCommand"
    
            Start-Process -FilePath 'dism' -ArgumentList $dismCommand -NoNewWindow -Wait
    
            # Notify the user about successful completion
            SetStatusText -message "Drivers exported successfully. Click Next to Continue." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            Write-Host "Drivers exported successfully to $DriversDir."
            return $true
        }
        catch {
            # Handle any errors during the process
            $errorMessage = "Error exporting drivers: $($_.Exception.Message)"
            SetStatusText -message $errorMessage -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Error $errorMessage
            return $false
        }
    }
    
    # Working on this later
    function MountWimImage {
        param (
            [string]$WimFile,
            [string]$MountDir
        )
    
        if (-not (Get-Command 'dism' -ErrorAction SilentlyContinue)) {
            Write-Error "DISM is not available. Please ensure it is installed."
            SetStatusText -message "DISM is not available. Please ensure it is installed." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return $false
        }
    
        # Validate WimFile
        if ($WimFile -isnot [string]) {
            Write-Error "Error: WimFile parameter is not a valid string. Value: $WimFile"
            SetStatusText -message "Error: WimFile parameter is not valid. Value: $WimFile" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return $false
        }
    
        # Verify that the WIM file exists
        if (!(Test-Path -Path $WimFile)) {
            Write-Error "Error: WIM file not found at $WimFile"
            SetStatusText -message "WIM file not found at $WimFile" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return $false
        }
    
        # Ensure the mount directory exists
        if (!(Test-Path -Path $MountDir)) {
            New-Item -ItemType Directory -Path $MountDir -Force | Out-Null
        }
    
        try {
            # Properly quote paths
            $quotedWimFile = QuotePath -Path $WimFile
            $quotedMountDir = QuotePath -Path $MountDir
    
            # Log the DISM command
            Write-Host "DISM Command: dism /mount-wim /wimfile:$quotedWimFile /index:1 /mountdir:$quotedMountDir"
            SetStatusText -message "Mounting WIM file..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
            # Execute the DISM command
            Start-Process -FilePath 'dism' -ArgumentList "/mount-wim /wimfile:$quotedWimFile /index:1 /mountdir:$quotedMountDir" -NoNewWindow -Wait
    
            Write-Host "WIM mounted successfully."
            SetStatusText -message "WIM mounted successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            return $true
        }
        catch {
            Write-Error "Error during WIM mounting: $_"
            SetStatusText -message "Error during WIM mounting: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return $false
        }
    }

    # Working on this later
    function AddDriversToDriverStore {
        param (
            [string]$DriverPath,
            [string]$MountDir
        )
    
        try {
            $quotedDriverPath = QuotePath -Path $DriverPath
            $quotedMountDir = QuotePath -Path $MountDir
    
            Write-Host "Adding drivers from $quotedDriverPath to the Driver Store in $quotedMountDir..."
            SetStatusText -message "Adding drivers to the Driver Store..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
            Start-Process -FilePath 'dism' -ArgumentList "/image:$quotedMountDir /add-driver /driver:$quotedDriverPath /recurse" -NoNewWindow -Wait
    
            Write-Host "Drivers added to the Driver Store successfully."
            SetStatusText -message "Drivers added to the Driver Store successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            return $true
        }
        catch {
            Write-Error "Error adding drivers to the Driver Store: $_"
            SetStatusText -message "Error adding drivers to the Driver Store: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return $false
        }
    }
    
    # Working on this later
    function CommitAndUnmountWim {
        param (
            [string]$MountDir
        )
    
        if (-not (Get-Command 'dism' -ErrorAction SilentlyContinue)) {
            Write-Error "DISM is not available. Please ensure it is installed."
            SetStatusText -message "DISM is not available. Please ensure it is installed." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return $false
        }
    
        try {
            $quotedMountDir = QuotePath -Path $MountDir
    
            Write-Host "Committing changes and unmounting WIM image..."
            SetStatusText -message "Committing changes and unmounting WIM image..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
            Start-Process -FilePath 'dism' -ArgumentList "/unmount-wim /mountdir:$quotedMountDir /commit" -NoNewWindow -Wait
    
            Write-Host "WIM image unmounted and changes committed successfully."
            SetStatusText -message "WIM image unmounted and changes committed successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            return $true
        }
        catch {
            Write-Error "Error unmounting WIM image: $_"
            SetStatusText -message "Error unmounting WIM image: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return $false
        }
    }
    
    # Working on this later
    function AddDriversToImage {
        param (
            [string]$ImageFile = (Join-Path -Path $Script:WorkingDirectory -ChildPath 'sources\install.esd'),
            [string]$MountParentDir = (Split-Path -Parent $Script:WorkingDirectory)
        )
    
        # Validate input parameters
        if (-not $WorkingDirectory -or -not $ImageFile -or -not $MountParentDir) {
            SetStatusText -message 'Error: Required parameters are missing.' -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Error 'Error: Required parameters are missing.'
            return $false
        }
    
        # Define paths
        $MountDir = Join-Path -Path $MountParentDir -ChildPath 'WIMMount'
        $WimDestination = Join-Path -Path $WorkingDirectory -ChildPath 'sources\install.wim'
    
        # Step 1: Convert ESD to WIM
        SetStatusText -message 'Starting ESD-to-WIM conversion...' -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
        Write-Host 'Starting ESD-to-WIM conversion...'
        $ImageFile = ConvertEsdToWim -ImageFile $ImageFile

        # Debugging output for ImageFile
        Write-Host "Debug: After conversion, ImageFile is $ImageFile"

        if (-not $ImageFile) {
            SetStatusText -message 'Error: Failed to convert ESD to WIM.' -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Error 'Error: Failed to convert ESD to WIM.'
            return $false
        }
    
        # Step 2: Export Drivers
        if (-not (ExportDrivers -DriversDir $DriversDir)) {
            Write-Error "Error: Failed to export drivers."
            return $false
        }

        # Step 3: Mount the WIM
        SetStatusText -message 'Mounting WIM image...' -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
        Write-Host "Debug: Mounting WIM image with ImageFile: $ImageFile and MountDir: $MountDir"

        # Validate ImageFile before calling MountWimImage
        if ($ImageFile -isnot [string]) {
            Write-Error "Error: ImageFile is not a valid string. Value: $ImageFile"
            SetStatusText -message 'Error: Invalid ImageFile path.' -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return $false
        }

        # Call MountWimImage
        if (-not (MountWimImage -WimFile $ImageFile -MountDir $MountDir)) {
            SetStatusText -message 'Error mounting WIM image.' -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Error 'Error mounting WIM image.'
            return $false
        }

        # Step 4: Add Drivers
        SetStatusText -message 'Adding drivers to WIM...' -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
        Write-Host 'Adding drivers to WIM...'
        if (-not (AddDriversToDriverStore -DriverPath $DriversDir -MountDir $MountDir)) {
            SetStatusText -message 'Error adding drivers to WIM.' -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Error 'Error adding drivers to WIM.'
            return $false
        }
    
        # Step 5: Commit and Unmount WIM
        SetStatusText -message 'Committing and unmounting WIM...' -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
        Write-Host 'Committing and unmounting WIM...'
        if (-not (CommitAndUnmountWim -MountDir $MountDir)) {
            SetStatusText -message 'Error committing and unmounting WIM.' -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Error 'Error committing and unmounting WIM.'
            return $false
        }
    
        # Step 6: Copy Updated WIM
        SetStatusText -message 'Copying updated WIM...' -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
        Write-Host 'Copying updated WIM...'
        try {
            Copy-Item -Path $ImageFile -Destination $WimDestination -Force
            SetStatusText -message 'Updated WIM copied successfully.' -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
        }
        catch {
            SetStatusText -message "Error copying WIM: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Error "Error copying WIM: $_"
            return $false
        }
    
        # Step 7: Clean Up Mount Directory
        SetStatusText -message 'Cleaning up mount directory...' -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
        Write-Host 'Cleaning up mount directory...'
        try {
            if (Test-Path -Path $MountDir) {
                Remove-Item -Path $MountDir -Recurse -Force
                Write-Host 'Mount directory cleaned up successfully.'
            }
        }
        catch {
            SetStatusText -message "Error cleaning up mount directory: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            Write-Error "Error cleaning up mount directory: $_"
        }
    
        SetStatusText -message 'Driver injection process completed successfully!' -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
        Write-Host 'Driver injection process completed successfully!'
        return $true
    }
    
    
    # Working on this later
    function AddRecommendedDrivers {
        SetStatusText -message "Checking for driver directory..." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
        RefreshGUI
    
        # Define driver directory with escaped $ symbols
        $winpeDriverDir = "C:\WIMUtil\`$WinpeDriver`$"
    
        # Check if the directory exists; if not, create it
        if (!(Test-Path -Path $winpeDriverDir)) {
            New-Item -ItemType Directory -Path $winpeDriverDir | Out-Null
            SetStatusText -message "Created driver directory: $winpeDriverDir" -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            SetStatusText -message "Essential storage and network drivers added successfully." -color $Script:NeutralColor -textBlock ([ref]$AddRecDriversTextBox)
            RefreshGUI
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

                RefreshGUI
    
                (New-Object System.Net.WebClient).DownloadFile($url, $destinationPath)
                SetStatusText -message "$fileName downloaded successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)

                RefreshGUI
            }
            catch {
                SetStatusText -message "Error downloading ${fileName}: $($_)" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)

                RefreshGUI
            }
        }
    
        SetStatusText -message "All recommended drivers added successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)

        RefreshGUI
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
            SetStatusText -message "oscdimg detected. Select a save location to Continue." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
            $GetoscdimgButton.IsEnabled = $false
            $CreateISOButton.IsEnabled = $true
        }
        else {
            SetStatusText -message "oscdimg not found. Please download it." -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
            $GetoscdimgButton.IsEnabled = $true
            $CreateISOButton.IsEnabled = $false
        }

        RefreshGUI  # Refresh the UI
    }

    # Function to download and validate oscdimg
    function DownloadOscdimg {
        SetStatusText -message "Preparing to download oscdimg..." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
        RefreshGUI

        $adkOscdimgPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
        $oscdimgFullPath = Join-Path -Path $adkOscdimgPath -ChildPath "oscdimg.exe"

        # Ensure the ADK directory exists
        if (!(Test-Path -Path $adkOscdimgPath)) {
            New-Item -ItemType Directory -Path $adkOscdimgPath -Force | Out-Null
            SetStatusText -message "Created directory for oscdimg at: $adkOscdimgPath" -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
            RefreshGUI
        }

        # Download oscdimg to the ADK path
        try {
            SetStatusText -message "Downloading oscdimg from: $oscdimgURL" -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
            RefreshGUI

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
            SetStatusText -message "oscdimg verified. Select a save location to Continue." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
            $GetoscdimgButton.IsEnabled = $false
            $CreateISOButton.IsEnabled = $true
        }
        catch {
            SetStatusText -message "Failed to download oscdimg: $($_.Exception.Message)" -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
        }

        RefreshGUI
    }
 
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
        $Script:ISOPath = SelectLocation -Mode "Save" -Title "Save the new ISO file" -Filter "ISO Files (*.iso)|*.iso"
    
        if ($Script:ISOPath) {
            # Extract the drive letter from the ISO path
            $driveLetter = (Split-Path -Qualifier $Script:ISOPath).TrimEnd(":")
    
            try {
                # Validate that the drive exists
                $drive = Get-PSDrive -Name $driveLetter
                if (-not $drive) {
                    throw "Drive not found for the selected ISO save location."
                }
    
                # Check if there's sufficient space available
                if ($drive.Free -ge $requiredSpace) {
                    # Update the TextBox with the selected save location
                    SetStatusText -message "Location Selected. Click Create ISO to continue." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
                    $CreateISOTextBox.Text = "Location selected at $Script:ISOPath"
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
            catch {
                # Handle cases where the drive cannot be found
                $Script:ISOPath = $null
                [System.Windows.MessageBox]::Show(
                    "Could not determine the selected drive. Please select a valid location.", 
                    "Drive Error", 
                    [System.Windows.MessageBoxButton]::OK, 
                    [System.Windows.MessageBoxImage]::Error
                )
                Write-Error "Error: $_"
            }
        }
    }
       
    # Updated CreateISO function
    function CreateISO {
        # Ensure ISO path is set
        if (-not $Script:ISOPath) {
            SetStatusText -message "No save location selected." -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
            return
        }
    
        # Ensure working directory is set
        if (-not $Script:WorkingDirectory -or -not (Test-Path -Path $Script:WorkingDirectory)) {
            SetStatusText -message "Working directory is not set or does not exist." -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
            return
        }
    
        SetStatusText -message "Creating ISO file. This might take a while, please wait..." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
        RefreshGUI
    
        # Define paths dynamically
        $sourceDir = "$Script:WorkingDirectory"
        $oscdimgPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        $etfsbootPath = "$sourceDir\boot\etfsboot.com"         # BIOS boot image
        $efisysPath = "$sourceDir\efi\microsoft\boot\efisys.bin"  # UEFI boot image
    
        # Validate paths
        if (-not (Test-Path -Path $oscdimgPath)) {
            SetStatusText -message "Oscdimg.exe not found at $oscdimgPath. Please ensure it is installed." -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
            return
        }
        if (-not (Test-Path -Path $etfsbootPath)) {
            SetStatusText -message "Boot file not found: $etfsbootPath. Ensure your working directory is correct." -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
            return
        }
        if (-not (Test-Path -Path $efisysPath)) {
            SetStatusText -message "UEFI boot file not found: $efisysPath. Ensure your working directory is correct." -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
            return
        }
    
        # Construct the arguments with dual boot support
        $arguments = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$etfsbootPath`"#pEF,e,b`"$efisysPath`" `"$sourceDir`" `"$Script:ISOPath`""
    
        try {
            # Use Start-Process to run oscdimg with the correct arguments for dual boot support
            Start-Process -FilePath $oscdimgPath -ArgumentList $arguments -NoNewWindow -Wait
            SetStatusText -message "Done! ISO file successfully saved at $Script:ISOPath." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
            RefreshGUI
        }
        catch {
            # Handle errors during the process
            SetStatusText -message "Failed to create ISO: $($_.Exception.Message)" -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
            RefreshGUI
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
    $AddDriversToImageButton.Add_Click({ ExportDrivers })
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