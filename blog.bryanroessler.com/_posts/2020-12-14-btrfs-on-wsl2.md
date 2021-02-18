---
layout: post
title: 'BTRFS on WSL2'
date: '2020-12-14 15:36'
subtitle: It works
tags:
  - BTRFS
  - wsl2
  - windows
  - fedora
---


### Introduction

Recently I needed to move 20TB worth of data stored on my last remaining Windows HTPC server over to a BTRFS-powered NAS running a *BTRFSized* Fedora 33. However, I was quite limited by the wi-fi speeds of the embedded server running the data array and benchmarks indicated it would take several days to complete. Instead of moving displays around, I figured I would see if it was possible to connect the BTRFS drive array directly to the Windows server using WSL2. Of course, such a situation would've been unthinkable a year ago, but now thanks to the ability to use a full Linux kernel in WSL2, the process is relatively simple as long as you are willing to upgrade to a bleeding edge Windows 10 developer edition to enable the ability to mount block devices in WSL2.

### WSL2

In version 2 of the Windows Subsystem for Linux (WSL2), Microsoft started shipping a full linux kernel on top of its virtualization stack. Since BTRFS is baked into recent Linux kernels, suddenly these "Linux-only" filesystems could now be used on Windows via the WSL2. Unfortunately it was still impossible to interact with hardware block devices (and thus mount multi-drive BTRFS device arrays) until Windows 10 [Build 20211](https://docs.microsoft.com/en-us/windows/wsl/release-notes), which is still a preview build. This means you will need to enable some Microsoft telemetry, join their Insider Program (their unpaid beta testing team), and upgrade to the latest developer build to enable the `wsl --mount` feature. Since this will be the *coup d'état* for this server, I don't worry much about the long-term privacy concerns or stability risks. If this is not the case for you, **it may be a good idea to wait** until all of these awesome features trickle down to more stable builds.

1. Upgrade to a Windows Build >= 20211 by joining the Insider Program from the Windows settings (entails several reboots)

Additional steps I had to perform in Windows:

1. Enable WSL2 VM support: `dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart`
2. Set my default WSL to version 2: `wsl --set-default-version 2`
3. If you have an existing WSL installation, you will need to convert it from WSL1 to WSL2: `wsl --set-version Ubuntu 2`

### The array

The BTRFS array consists of 5 disks in a **RAID1c3** configuration that was created on a Fedora 33 server. So-called "3-Copy" support was added to **Linux 5.5** and adds some additional redundancy. Unfortunately, the WSL2 currently ships with a Linux 4.9 by default. It's possible to upgrade the kernel to some extent using [a package from Microsoft](https://docs.microsoft.com/en-us/windows/wsl/install-win10#step-4---download-the-linux-kernel-update-package), but I was still stuck on 5.4 even after installing the update package.

It's certainly possible to build your own Linux kernel from Microsoft's [Linux 5.4 source repository](https://github.com/microsoft/WSL2-Linux-Kernel/tree/linux-msft-wsl-5.4.y) if you wanted to go that route. In my case the BTRFS version in the kernel would still not be able to read my RAID1c3 array.

Luckily, [Nathan Chance](https://github.com/nathanchance/WSL2-Linux-Kernel) has a public repository available of WSL2-compatible Linux kernels tracking upstream. You can build it using his toolchain or use one of his latest pre-compiled [releases](https://github.com/nathanchance/WSL2-Linux-Kernel/releases). As I mentioned earlier, I'm not too concerned with performance or security here so I'm willing to use a third-party solution to save time as this is a one-shot operation. Thanks, Nathan.

After downloading the bzImage you will need to point WSL2 at the new kernel by placing a file at `C:\Users\username\.wslconfig` containing:

```(text)
[wsl2]
kernel = C:\\Users\\username\\Downloads\\bzImage
```

Yes, those are **double slashes**, because Windows.

Now you can restart your wsl instance (`wsl --shutdown`) or just reboot and you should be running a sparkling fresh kernel (confirm with `uname -a`). At the time of this writing, Linux 5.10 kernels were already available.

### Passthrough the BTRFS device (or partition) to WSL2

Now that our tools are up-to-date we can go ahead and mount (passthrough) our block devices and BTRFS partitions. In Windows you will need to identify the **DeviceID** of the disk(s) you wish to passthrough to WSL2 using `wmic diskdrive list brief` in an elevated prompt. In Windows fashion the nomenclature is nonsensical (probably, `\\.\PHYSICALDRIVE2`).

In my case I had to passthrough all five drives in the array. WSL2 does have the ability to mount btrfs partitions directly using the `-t` option, but we will just be passing the bare drives as block devices instead:

```(powershell)
wsl --mount \\.\PHYSICALDRIVE5 --bare
wsl --mount \\.\PHYSICALDRIVE6 --bare
wsl --mount \\.\PHYSICALDRIVE7 --bare
wsl --mount \\.\PHYSICALDRIVE8 --bare
wsl --mount \\.\PHYSICALDRIVE9 --bare
```

These will all become block devices in `/dev/sd*`.

### Mount the BTRFS filesystem and transfer your data

After adding your drives to the WSL2, for good measure run a `sudo btrfs device scan` to make the kernel aware of their existence.

Check for device blocks:

```(shell)
$ sudo blkid
/dev/sda: UUID="3255683f-53a2-4fdf-91cf-b4c1041e2a62" TYPE="ext4"
/dev/sdb: UUID="3255683f-53a2-4fdf-91cf-b4c1041e2a62" TYPE="ext4"
/dev/sdc: LABEL="array" UUID="6f7065bf-3f6c-4950-b305-e5d3565b9385" UUID_SUB="bdfea478-7826-48ed-b000-04894aac221d" TYPE="btrfs"
/dev/sdd: LABEL="array" UUID="6f7065bf-3f6c-4950-b305-e5d3565b9385" UUID_SUB="95615881-0962-4318-b04d-6aa21d991a33" TYPE="btrfs"
/dev/sde: LABEL="array" UUID="6f7065bf-3f6c-4950-b305-e5d3565b9385" UUID_SUB="abc9baa8-4b76-4630-a1d5-e91852dca20c" TYPE="btrfs"
/dev/sdf: LABEL="array" UUID="6f7065bf-3f6c-4950-b305-e5d3565b9385" UUID_SUB="e06ddecc-57cd-4458-a4a7-22689f940b02" TYPE="btrfs"
/dev/sdg: LABEL="array" UUID="6f7065bf-3f6c-4950-b305-e5d3565b9385" UUID_SUB="08f00c39-b1bc-4b01-9f1d-e1efb8686fd4" TYPE="btrfs"
```

BTRFS is smart enough to mount the whole device array even when specifying a single disk member. So just create a sensible mount point and mount any of your btrfs devices: `sudo mkdir /mnt/array && sudo mount /dev/sdc /mnt/array`.

`cd /mnt/array` into your mounted BTRFS array to make sure everything looks good and your subvolumes are present: `sudo btrfs subvolume list /`

If everything looks good, go ahead and start transferring your data over from your Windows partitions, which are also conveniently mounted in `/mnt` (as you have probably spotted by now if you've been following along).

By default the Windows filesystems are `a+rwx` so it is pretty easy to pull data from them with rsync without too many permission hassles using the `-a` archive option: `rsync -a --info=progress2 /mnt/d/media/ /mnt/e/media/ /mnt/array/media`

As you can see in the above rsync command, I chose to chain several source directories together to simplify the transfer to the new array.

### Cleanup

After you are finished moving data around:

1. Unmount the array in WSL: `sudo umount /dev/array` **Note:** Make sure you aren't currently in the mount point or you will get `target is busy` errors when trying to unmount. `cd ~` first.
2. Back in Windows, unshare the drive with the WSL2:

```(powershell)
wsl --unmount \\.\PHYSICALDRIVE5
wsl --unmount \\.\PHYSICALDRIVE6
wsl --unmount \\.\PHYSICALDRIVE7
wsl --unmount \\.\PHYSICALDRIVE8
wsl --unmount \\.\PHYSICALDRIVE9
```

And voilà, you are done!

### Conclusions

Even though my aging Windows server was limited to 5 GB/s USB throughput, I was still able to complete the transfer in a matter of hours (not days) and without putting tremendous load on my network for an extended period of time. It is also perhaps bittersweet that I exit the ecosystem just as it achieves some useful level of compatibility with my preferred workflow. In theory one could even share BTRFS devices between Windows and Linux as long as they were not simultaneously mounted. Of course, in most cases it would be more sensible to use a network-based solution but for those seeking optimal performance, the WSL2 offers a compelling option.
