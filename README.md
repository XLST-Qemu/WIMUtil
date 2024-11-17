# Memory's Windows Installation Media Utility 🧰
The **Windows Installation Media Utility** (*not .WIM - Windows Imaging Format Utility*) is a simple tool designed to help optimize and customize Windows Installation Media, streamlining your Windows installs.

Contributions to this project are welcome! However, please understand that I prefer to develop and work on these projects independently. I do value other people's insights and appreciate any feedback, so don't take it personally if a pull request is not accepted.

## Current Features 🛠️
- **Select Windows 10/11 ISO File**
- **Add `autounattend.xml` Answer File**
- **Extract and Add Drivers**
- **Create New ISO File** with [`oscdimg.exe`](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/oscdimg-command-line-options) 

> [!NOTE]
> This tool is currently in alpha, and it's a work in progress. Any issues can be reported using the Issues tab.

### Versions

[![Latest Version](https://img.shields.io/badge/Version-0.0.2Alpha%20Latest-0078D4?style=for-the-badge&logo=github&logoColor=white)](https://github.com/memstechtips/WIMUtil/releases/tag/v0.0.2)

### Support the Project

If **WIMUtil** has been useful to you, consider supporting the project—it truly helps!

[![Support via PayPal](https://img.shields.io/badge/Support-via%20PayPal-FFD700?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/memstech)

### Feedback and Community

If you have feedback, suggestions, or need help with WIMUtil, please join the discussion on GitHub or our Discord community:

[![Join the Discussion](https://img.shields.io/badge/Join-the%20Discussion-2D9F2D?style=for-the-badge&logo=github&logoColor=white)](https://github.com/memstechtips/WIMUtil/discussions)
[![Join Discord Community](https://img.shields.io/badge/Join-Discord%20Community-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://www.discord.gg/zWGANV8QAX)

## Requirements 💻
- Windows 10/11
- PowerShell (run as Administrator)

## Usage Instructions 📜

To use **WIMUtil**, follow these steps to launch PowerShell as an Administrator and run the installation script:

1. **Open PowerShell as Administrator:**
   - **Windows 10/11**: Right-click on the **Start** button and select **Windows PowerShell (Admin)** or **Windows Terminal (Admin)**. </br> PowerShell will open in a new window.

2. **Confirm Administrator Privileges**: 
   - If prompted by the User Account Control (UAC), click **Yes** to allow PowerShell to run as an administrator.

3. **Paste and Run the Command**:
   - Copy the following command:
     ```powershell
     irm "https://github.com/memstechtips/WIMUtil/raw/main/src/WIMUtil.ps1" | iex
     ```
   - To paste into PowerShell, **Right-Click** or press **Ctrl + V** in the PowerShell or Terminal window. </br> This should automatically paste your copied command.
   - Press **Enter** to execute the command.

This command will download and execute the **WIMUtil** script directly from GitHub.


## Application Overview 🧩
Once launched, **WIMUtil** guides you through a four-part wizard:

1. **Select or Download Windows ISO**: Choose an existing ISO or download the latest Windows 10 or Windows 11 ISO from Microsoft.

2. **Add Answer File**:
   - Download and add the latest UnattendedWinstall Answer File.
   - Optionally, add a custom answer file `autounattend.xml` not `unattend.xml` manually.

3. **Extract and Add Drivers**:
   - Extract and add current device drivers to the installation media.
   - Add recommended Storage and Network drivers (Coming Soon).

4. **Create New ISO**:
   - Download the official `oscdimg.exe` from the WIMUtil repo if not already installed.
   - Select a save location for the ISO and create the file.

5. **Cleanup on Exit**: After creating your ISO, WIMUtil prompts to clean up the working directory. Selecting **Yes** is recommended to free up space.

## Using the Bootable ISO 🖥️

Once your bootable ISO is created, it can be used to install Windows on a Virtual Machine or create a bootable USB flash drive. I recommend using [Ventoy](https://github.com/ventoy/Ventoy). Here’s a quick guide:

- **Ventoy**
  - Download and Run `Ventoy2Disk.exe`.
  - Format your USB drive with Ventoy.
  - Simply copy the ISO to the USB drive.
  - Boot from the USB flash drive and choose your ISO.
  - Install Windows.
---
