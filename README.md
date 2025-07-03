# Memory的Windows安装媒体实用程序🧰
**Windows安装媒体实用程序**（*不是.WIM-Windows映像格式实用程序*）是一个简单的工具，旨在帮助优化和自定义Windows安装媒体，简化Windows安装。

欢迎为这个项目捐款！但是，请理解，我更喜欢独立开发和处理这些项目。我确实重视其他人的见解，并感谢任何反馈，所以如果拉取请求未被接受，不要把它当作个人恩怨。

##当前功能🛠️
-**选择Windows 10/11 ISO文件**
-**添加`autounattend.xml `应答文件**
-**提取和添加驱动程序**
-**使用[`oscdmg.exe `]创建新的ISO文件**(https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/oscdimg-command-line-options) 

>[！注意]
>该工具目前处于alpha版本，正在开发中。任何问题都可以使用“问题”选项卡报告。
>此外，我不是开发人员，我只是喜欢边玩边学习。

### 版本

[！[最新版本](https://img.shields.io/badge/Version-0.0.3Alpha%20Latest-0078D4？style=徽章和徽标=github和徽标颜色=白色）](https://github.com/memstechtips/WIMUtil/releases/tag/v0.0.3)

### 支持项目

如果**WIMUtil**对你有用，考虑支持这个项目——它真的很有帮助！

[！[通过PayPal提供支持](https://img.shields.io/badge/Support-via%20PayPal-FFD700？style=徽章和徽标=贝宝和徽标颜色=白色）](https://paypal.me/memstech)

### 反馈和社区

如果您对WIMUtil有任何反馈、建议或需要帮助，请加入GitHub或我们的Discord社区的讨论：

[！[加入讨论](https://img.shields.io/badge/Join-the%20Discussion-2D9F2D？style=徽章和徽标=github和徽标颜色=白色）](https://github.com/memstechtips/WIMUtil/discussions)
[！[加入Discord社区](https://img.shields.io/badge/Join-Discord%20Community-5865F2？style=徽章和徽标=不和谐和徽标颜色=白色）](https://www.discord.gg/zWGANV8QAX)

## 要求💻
-Windows 10/11
-PowerShell（以管理员身份运行）

## 使用说明📜

要使用**WIMUtil**，请按照以下步骤以管理员身份启动PowerShell并运行安装脚本：

1.**以管理员身份打开PowerShell：**
-**Windows 10/11**：右键单击**开始**按钮，然后选择**Windows PowerShell（管理员）**或**Windows终端（管理员）***</br>PowerShell将在新窗口中打开。

2.**确认管理员权限**：
-如果用户帐户控制（UAC）提示，请单击**是**以允许PowerShell以管理员身份运行。

3.**粘贴并运行命令**：
-复制以下命令：
```powershell
irm”https://github.com/memstechtips/WIMUtil/raw/main/src/WIMUtil.ps1“|iex
```
-要粘贴到PowerShell中，**右键单击**或在PowerShell或终端窗口中按**Ctrl+V**</br>这应该会自动粘贴您复制的命令。
-按**Enter**执行命令。

此命令将直接从GitHub下载并执行**WIMUtil**脚本。


## 应用程序概述🧩
一旦启动，**WIMUtil**将引导您完成一个由四部分组成的向导：

1.**选择或下载Windows ISO**：选择现有的ISO或从Microsoft下载最新的Windows 10或Windows 11 ISO。

2.**添加应答文件**：
-下载并添加最新的无人值守Winstall应答文件。
-（可选）手动添加自定义应答文件`autounattend.xml `而不是`unattend.xml`。

3.**提取和添加驱动程序**：
-提取当前设备驱动程序并将其添加到安装介质中。
-添加推荐的存储和网络驱动程序（即将推出）。

4.**创建新的ISO**：
-如果尚未安装，请从WIMUtil仓库下载官方的“oscdmg.exe”。
-为ISO选择一个保存位置并创建文件。

5.**退出时清理**：创建ISO后，WIMUtil会提示清理工作目录。建议选择**是**以释放空间。

## 使用可引导ISO🖥️

创建可引导ISO后，可以使用它在虚拟机上安装Windows或创建可引导USB闪存驱动器。我建议使用[Ventoy](https://github.com/ventoy/Ventoy). 以下是一个快速指南：

-**Ventoy**
-下载并运行“Ventoy2Disk.exe”。
-使用Ventoy格式化您的USB驱动器。
-只需将ISO复制到USB驱动器即可。
-从USB启动盘启动并选择ISO。
-安装Windows。
---
