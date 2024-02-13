# Cyberark-stuff
Code templates and examples to work with Cyberark
## PasswordManager

Stuff for the CPM

### PowershellTarget.ps1

Use this to change a password on an appliance or similar using an API.   Set it as an imported Target platform that uses CyberArk.TPC.exe as the plugin. I used the UnixSSH platform as the base.


![image](https://github.com/jbalcorn/Cyberark-stuff/assets/7225956/423ac220-88dc-461f-913e-52159880bcce)

![image](https://github.com/jbalcorn/Cyberark-stuff/assets/7225956/29e0afa3-23fe-4ec3-beb7-c1607e140517)

![image](https://github.com/jbalcorn/Cyberark-stuff/assets/7225956/d50d4fc6-17d2-4cfe-beba-d071a4cd37e8)


### PSUsage.....ps1

These are Dependent platforms that use the PSUsageProcess.ini and PSUsagePrompts.ini.  They only handle a 'changepass' action.  Unlike the Target Plaform script, these all use the same Platform PSScript which is then added as a usage to the needed Target platforms.

- PSUsageTestScript.ps1 just makes sure it's working and outputs to a log file
- PSUsageRunTask.ps1 runs a scheduled task (that might have no triggers defined) on the target server
- PSUsageSQLCredential.ps1 Runs a SQL command to push the new password to a SQL Credential

![image](https://github.com/jbalcorn/Cyberark-stuff/assets/7225956/b0600587-17c2-4ac5-8b1a-2383844d19ff)
![image](https://github.com/jbalcorn/Cyberark-stuff/assets/7225956/0d2c08f9-0f7e-470e-b191-7a296ed77b1b)
![image](https://github.com/jbalcorn/Cyberark-stuff/assets/7225956/63aebad8-7a9e-4b56-86a4-8831d5d1ab19)
![image](https://github.com/jbalcorn/Cyberark-stuff/assets/7225956/ec2c0089-8ed1-4007-889f-f13b990ffb43)

![image](https://github.com/jbalcorn/Cyberark-stuff/assets/7225956/27915cef-b8f3-4e60-a4b4-d9bc0b16f2fe)

![image](https://github.com/jbalcorn/Cyberark-stuff/assets/7225956/d23b8c67-5677-4db0-95fb-321f16c02e8b)

## PSM

Stuff for the PSM

### Get-ProperChromeDriver

Script to download and install the correct ChromeDriver.exe to match the 32-bit chrome installed on the PSM.

instructions originally from https://cyberark.my.site.com/s/article/How-to-update-Chrome-Driver-in-PSM-server