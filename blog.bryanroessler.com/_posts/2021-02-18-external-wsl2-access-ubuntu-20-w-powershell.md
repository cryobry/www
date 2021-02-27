---
layout: post
title: 'Restoring external (remote) WSL2 access'
date: 2021-02-18 11:01
tags: [windows, wsl, wsl2, linux, ssh, firewall, ip, ifconfig, powershell]
---

## Cannot access WSL2 instances remotely

If you rely on external (remote) access to the Windows Subsystem for Linux (WSL2) you may have noticed that your manual port forwards have suddenly stopped working. Microsoft has started issuing WSL2 instances a randomized IP address on startup, which makes it difficult to reliably access services hosted in the Linux subsystem. However, it's still possible to probe the WSL2 instance on startup and open the appropriate ports using Powershell.

Most existing solutions rely on legacy `ifconfig`, which has been deprecated in Ubuntu 20.04 (available in WSL2 via an in-place `do-release-upgrade`) in favor of `ip`.

## Allow WSL2 to bypass the Windows Firewall with a Powershell task

Steps:

1. [Download](https://git.bryanroessler.com/bryan/scripts/raw/master/powershell/wsl2-firewall-rules.ps1) or copy-paste the following Powershell script to a local file:

{% highlight powershell %}
{% insert_git_code https://git.bryanroessler.com/bryan/scripts/raw/master/powershell/wsl2-firewall-rules.ps1 %}
{% endhighlight %}

2. Edit the port list to add any additional WSL2 ports you wish to expose
3. Create a startup new task in the Windows Task Scheduler:

    * Name: 'WSL2-Bypass'
    * Triggers: At log on, for any user
    * Actions:
        * Program/Script: `powershell`
        * Add Arguments: `-ExecutionPolicy Bypass C:\Users\Bryan\Path\To\wsl2-firewall-rules.ps1`

4. Save the task and run it

## Starting WSL2 services automatically at login

You can use your `.bashrc` in the WSL2 or simply append the following line to the beginning of your powershell task:

`bash.exe -c "sudo /usr/sbin/service ssh start && sudo /usr/sbin/service unattended-upgrades start"`

You can add or remove services as necessary. In order to be able to use root privileges without entering a password, you will need to edit the sudoers file using `visudo` and adding the following line:

`%sudo ALL=NOPASSWD: /usr/sbin/service`

You can optionally substitute your username for ALL for more granularity.

## 

## Troubleshooting

* Make sure that you have already made the appropriate firewall changes within the instance itself.
* Make sure that your service is running.
* Try probing for the IP address manually and connecting to the service from the Windows machine.

Enjoy unfettered remote access to your WSL2 services again!
