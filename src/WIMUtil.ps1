# Check if script is running as Administrator
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Try {
        Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit
    } Catch {
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
} else {
    Write-Host "Unable to detect branch from Configuration URL. Using fallback." -ForegroundColor Yellow
}

Write-Host "Using branch: $currentBranch" -ForegroundColor Cyan

# Load the configuration from the specified URL
try {
    $config = (Invoke-WebRequest -Uri $configUrl -ErrorAction Stop).Content | ConvertFrom-Json
    Write-Host "Configuration loaded successfully from $configUrl" -ForegroundColor Green
} catch {
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
} catch {
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
    function Close_Click {
        $workingDir = "C:\WIMUtil"
        
        # Check if the working directory exists
        if (Test-Path -Path $workingDir) {
            # Show a confirmation popup to ask for cleanup
            $result = [System.Windows.MessageBox]::Show("Do you want to clean up the working directory to free up space?", 
                "Cleanup Confirmation", 
                [System.Windows.MessageBoxButton]::YesNo, 
                [System.Windows.MessageBoxImage]::Question)
    
            # If the user chooses "Yes," attempt to delete the working directory
            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                try {
                    Remove-Item -Path $workingDir -Recurse -Force
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
    

    # Select ISO function
    function SelectISO_Click {
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "ISO Files (*.iso)|*.iso"
        if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $Script:SelectedISO = $OpenFileDialog.FileName
            Write-Host "Selected ISO: $Script:SelectedISO"
            
            # Update the ISOPathTextBox with the selected ISO file path
            $ISOPathTextBox.Text = "Windows ISO file selected at $Script:SelectedISO"
    
            # Extract selected ISO file contents
            ExtractISO
        }
    }
    

    # Function to extract ISO
    function ExtractISO {
        $drive = Get-PSDrive -Name C
        $requiredSpace = 15GB
        if ($drive.Free -gt $requiredSpace) {
            SetStatusText -message "Sufficient space available. Preparing working directory..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
            [System.Windows.Forms.Application]::DoEvents()
    
            $workingDir = "C:\WIMUtil"
            if (Test-Path -Path $workingDir) {
                SetStatusText -message "Deleting existing working directory..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                [System.Windows.Forms.Application]::DoEvents()
                Remove-Item -Path $workingDir -Recurse -Force
            }
    
            SetStatusText -message "Creating new working directory..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
            [System.Windows.Forms.Application]::DoEvents()
            New-Item -ItemType Directory -Path $workingDir -Force
    
            try {
                SetStatusText -message "Mounting $Script:SelectedISO..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                [System.Windows.Forms.Application]::DoEvents()
                $mountResult = Mount-DiskImage -ImagePath $Script:SelectedISO -PassThru
                $driveLetter = ($mountResult | Get-Volume).DriveLetter + ":"
    
                SetStatusText -message "Copying files from mounted ISO ($driveLetter) to $workingDir..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                [System.Windows.Forms.Application]::DoEvents()
                
                # Copy all files from the mounted ISO to the working directory
                Copy-Item -Path "$driveLetter\*" -Destination $workingDir -Recurse -Force
    
                # Explicitly check and remove autounattend.xml if it exists in the working directory
                $autounattendPath = Join-Path -Path $workingDir -ChildPath "autounattend.xml"
                if (Test-Path -Path $autounattendPath) {
                    try {
                        Remove-Item -Path $autounattendPath -Force -ErrorAction Stop
                        SetStatusText -message "autounattend.xml from the ISO was successfully removed from the working directory." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                    }
                    catch {
                        SetStatusText -message "Failed to delete autounattend.xml: $_" -color $Script:ErrorColor -textBlock ([ref]$ExtractISOStatusText)
                    }
                }
    
                SetStatusText -message "Dismounting ISO..." -color $Script:SuccessColor -textBlock ([ref]$ExtractISOStatusText)
                [System.Windows.Forms.Application]::DoEvents()
                Dismount-DiskImage -ImagePath $Script:SelectedISO
    
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
            SetStatusText -message "Not enough space on drive C: for extraction." -color $Script:ErrorColor -textBlock ([ref]$ExtractISOStatusText)
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
    
    

    # DownloadUWXML function
    function DownloadUWXML {
        SetStatusText -message "Downloading the latest UnattendedWinstall XML file..." -color $Script:SuccessColor -textBlock ([ref]$AddXMLStatusText)
        [System.Windows.Forms.Application]::DoEvents()
        $url = "https://github.com/memstechtips/UnattendedWinstall/raw/main/autounattend.xml"
        $destination = "C:\WIMUtil\autounattend.xml"

        try {
        (New-Object System.Net.WebClient).DownloadFile($url, $destination)
            SetStatusText -message "Latest UnattendedWinstall XML file added successfully." -color $Script:SuccessColor -textBlock ([ref]$AddXMLStatusText)
        
            # Update the DownloadUWTextBox content with the success message
            SetStatusText -message "Latest UnattendedWinstall Answer file added to Windows Installation Media" -color $Script:NeutralColor -textBlock ([ref]$DownloadUWTextBox)
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
    
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "XML Files (*.xml)|*.xml"
        
        if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selectedFile = $OpenFileDialog.FileName
            $destination = "C:\WIMUtil\autounattend.xml"
    
            # Check for existing autounattend.xml file and delete it if found
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
                SetStatusText -message "Selected Answer file added to Windows Installation Media" -color $Script:NeutralColor -textBlock ([ref]$ManualXMLPathTextBox)
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
                Start-Process -FilePath "dism" -ArgumentList "/export-image /sourceimagefile:$ImageFile /sourceindex:1 /destinationimagefile:$convertedWimFile /compress:max /checkintegrity" -NoNewWindow -Wait
                SetStatusText -message "Conversion to .wim completed successfully: $convertedWimFile" -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
                [System.Windows.Forms.Application]::DoEvents()
                return $convertedWimFile
            }
            catch {
                SetStatusText -message "Error converting .esd to .wim: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
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
            [string]$WimFile,   # Path to the WIM file
            [string]$MountDir   # Path to the mount directory
        )
    
        if (!(Test-Path -Path $MountDir)) {
            New-Item -ItemType Directory -Path $MountDir -Force | Out-Null
        }
    
        try {
            SetStatusText -message "Mounting WIM image: $WimFile to $MountDir..." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            Start-Process -FilePath "dism" -ArgumentList "/mount-wim /wimfile:$WimFile /index:1 /mountdir:$MountDir" -NoNewWindow -Wait
            SetStatusText -message "WIM image mounted successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            [System.Windows.Forms.Application]::DoEvents()
            return $true
        }
        catch {
            SetStatusText -message "Error mounting WIM image: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return $false
        }
    }

    function AddDriversToDriverStore {
        param (
            [string]$DriverPath,  # Path to the exported drivers
            [string]$MountDir     # Path to the mounted WIM directory
        )
    
        try {
            SetStatusText -message "Adding drivers from $DriverPath to the Driver Store in $MountDir..." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            Start-Process -FilePath "dism" -ArgumentList "/image:$MountDir /add-driver /driver:$DriverPath /recurse" -NoNewWindow -Wait
            SetStatusText -message "Drivers added to the Driver Store successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
            [System.Windows.Forms.Application]::DoEvents()
            return $true
        }
        catch {
            SetStatusText -message "Error adding drivers to the Driver Store: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
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
            [string]$ExportDir = "C:\WIMUtil\ExportedDrivers",
            [string]$ImageFile = "C:\WIMUtil\sources\install.esd",
            [string]$MountDir = "C:\WIMUtil\Mount"
        )
    
        Write-Host "Starting AddDriversToImage process..." -ForegroundColor $Script:NeutralColor
    
        # Step 1: Check and convert .esd to .wim if necessary
        Write-Host "Step 1: Checking if ImageFile needs conversion from .esd to .wim..." -ForegroundColor $Script:NeutralColor
        SetStatusText -message "Step 1: Checking and converting ImageFile if needed..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
        $ImageFile = ConvertEsdToWim -ImageFile $ImageFile
        if (-not $ImageFile) {
            Write-Host "Error: ImageFile conversion failed. Aborting process." -ForegroundColor $Script:ErrorColor
            SetStatusText -message "Error: ImageFile conversion failed." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return
        }
        Write-Host "ImageFile is ready: $ImageFile" -ForegroundColor $Script:SuccessColor
        SetStatusText -message "Step 1 completed: ImageFile is ready: $ImageFile" -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
    
        # Step 2: Export current system drivers
        Write-Host "Step 2: Exporting current system drivers to $ExportDir..." -ForegroundColor $Script:NeutralColor
        SetStatusText -message "Step 2: Exporting current system drivers..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
        if (!(Test-Path -Path $ExportDir)) {
            Write-Host "Export directory not found. Creating $ExportDir..." -ForegroundColor $Script:NeutralColor
            New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null
        }
    
        try {
            Start-Process -FilePath "dism" -ArgumentList "/online /export-driver /destination:$ExportDir" -NoNewWindow -Wait
            Write-Host "Drivers exported successfully to $ExportDir" -ForegroundColor $Script:SuccessColor
            SetStatusText -message "Step 2 completed: Drivers exported successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
        }
        catch {
            Write-Host "Error: Failed to export drivers. $_" -ForegroundColor $Script:ErrorColor
            SetStatusText -message "Error: Failed to export drivers: $_" -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return
        }
    
        # Step 3: Mount the WIM image
        Write-Host "Step 3: Mounting the WIM image at $MountDir..." -ForegroundColor $Script:NeutralColor
        SetStatusText -message "Step 3: Mounting the WIM image..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
        if (-not (MountWimImage -WimFile $ImageFile -MountDir $MountDir)) {
            Write-Host "Error: Failed to mount WIM image." -ForegroundColor $Script:ErrorColor
            SetStatusText -message "Error: Failed to mount WIM image." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return
        }
        Write-Host "WIM image mounted successfully at $MountDir" -ForegroundColor $Script:SuccessColor
        SetStatusText -message "Step 3 completed: WIM image mounted successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
    
        # Step 4: Add drivers to the mounted WIM image
        Write-Host "Step 4: Adding drivers to the mounted WIM image..." -ForegroundColor $Script:NeutralColor
        SetStatusText -message "Step 4: Adding drivers to the WIM image..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
        if (-not (AddDriversToDriverStore -DriverPath $ExportDir -MountDir $MountDir)) {
            Write-Host "Error: Failed to add drivers to WIM image." -ForegroundColor $Script:ErrorColor
            SetStatusText -message "Error: Failed to add drivers to WIM image." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return
        }
        Write-Host "Drivers added successfully to the WIM image." -ForegroundColor $Script:SuccessColor
        SetStatusText -message "Step 4 completed: Drivers added successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
    
        # Step 5: Commit changes and unmount the WIM image
        Write-Host "Step 5: Committing changes and unmounting the WIM image..." -ForegroundColor $Script:NeutralColor
        SetStatusText -message "Step 5: Committing changes and unmounting the WIM image..." -color $Script:NeutralColor -textBlock ([ref]$AddDriversStatusText)
    
        if (-not (CommitAndUnmountWim -MountDir $MountDir)) {
            Write-Host "Error: Failed to unmount the WIM image. Manual cleanup may be required." -ForegroundColor $Script:ErrorColor
            SetStatusText -message "Error: Failed to unmount the WIM image." -color $Script:ErrorColor -textBlock ([ref]$AddDriversStatusText)
            return
        }
        Write-Host "WIM image unmounted and changes committed successfully." -ForegroundColor $Script:SuccessColor
        SetStatusText -message "Step 5 completed: WIM image unmounted successfully." -color $Script:SuccessColor -textBlock ([ref]$AddDriversStatusText)
    
        Write-Host "AddDriversToImage process completed successfully!" -ForegroundColor $Script:SuccessColor
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
    } catch {
        SetStatusText -message "Failed to download oscdimg: $($_.Exception.Message)" -color $Script:ErrorColor -textBlock ([ref]$CreateISOStatusText)
    }

    [System.Windows.Forms.Application]::DoEvents()
}

    # Define the location selection function
    function SelectNewISOLocation {
        # Prompt the user for ISO save location
        $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $SaveFileDialog.Filter = "ISO Files (*.iso)|*.iso"
        $SaveFileDialog.Title = "Save the new ISO file"
    
        if ($SaveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $Script:ISOPath = $SaveFileDialog.FileName
            SetStatusText -message "Location selected. Ready to Create ISO." -color $Script:SuccessColor -textBlock ([ref]$CreateISOStatusText)
        
            # Update the TextBox with the selected path and enable the Create ISO button
            $CreateISOTextBox.Text = $Script:ISOPath
            $CreateISOButton.IsEnabled = $true
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
    $SelectISOButton.Add_Click({ SelectISO_Click })
    $DownloadWin10Button.Add_Click({ DownloadWindows10ISO })
    $DownloadWin11Button.Add_Click({ DownloadWindows11ISO })

    $CloseButton.Add_Click({ Close_Click })
    $DownloadUWXMLButton.Add_Click({ DownloadUWXML })
    $SelectXMLFileButton.Add_Click({ SelectXMLFile })
    $AddDriversToImageButton.Add_Click({ AddDriversToImage })
    $AddRecDriversButton.Add_Click({ AddRecommendedDrivers })
    $GetoscdimgButton.Add_Click({ DownloadOscdimg })
    $SelectISOLocationButton.Add_Click({ SelectNewISOLocation })
    $CreateISOButton.Add_Click({ CreateISO })

    # Event handler for the Next button
    # Next button to navigate to the next screen
    $NextButton.Add_Click({
            if ($script:currentScreenIndex -eq 4) {
                # Show a confirmation popup when "Exit" is clicked on the last screen
                $result = [System.Windows.MessageBox]::Show("Do you want to clean up the working directory to free up space?", 
                    "Cleanup Confirmation", 
                    [System.Windows.MessageBoxButton]::YesNo, 
                    [System.Windows.MessageBoxImage]::Question)
    
                if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                    try {
                        Remove-Item -Path "C:\WIMUtil" -Recurse -Force
                        Write-Host "Working directory cleaned up successfully."
                    }
                    catch {
                        Write-Host "Failed to clean up the working directory: $_"
                    }
                }
    
                # Close the application after cleanup
                $window.Close()
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