---
layout: "post"
title: "JRiver Media Center: the client-client model"
subtitle:
#bigimg: /img/path.jpg
tags: [jriver, syncthing, x2go]
---

### Introduction

My goals for using JRiver Media Center (JRMC) successfully are as follows:

1. Enjoy my music when I want, where I want
    - Make it easy to access
    - Keep my media library organized
    - Make it easy to add and remove media
    - Keep my media library consistent across many devices
2. Minimize the impact on my home's bandwidth and ISP data caps
3. Automatically create redundant backups of my media
4. Make it stable
5. Make it automated

In the course of achieving these goals, my JRMC network has been in a state of flux for several years. However, I have eventually settled into a configuration that I have found works very well: pairing continuous file synchronization with JRMC automatic read and write tagging to synchronize media libraries among two or more JRMC clients, which I have termed the **client-client model**.

### Pairing JRMC with continuous file synchronization

JRMC contains a powerful [Media Server](https://wiki.jriver.com/index.php/Media_Server) that enables clients to play and manage media in JRMC as if they were using a local copy of the library. It is certainly possible to use JRMC Media Server exclusively to manage and play your media from the server to your clients in the traditional server-client model.

JRMC Media Server pros:
1. Tag changes are synced seamlessly between all devices
2. Client devices are easy to add/remove

JRMC Media Server cons:

1. Internet-connectivity, bandwidth and latency. Media must always be streamed from the server to the playback clients, which means that clients must have internet connectivity to access the library. I travel frequently so streaming is not always a feasible option. Also, file operations will not be as responsive as using a local library because the library will need to buffer media during playback and sync tag changes.
2. Adding new music to the server must still be done through a third-party tool (e.g. sftp, rsync, etc.)

Con #1 can be alleviated by maintaining a duplicate local copy of the media files on a client device and enabling the option to *Options>Media Network>Client Options>Play local file if one that matches Library Server file is found* on the client's copy of JRMC. However, this feature necessitates that the client and server file structures are identical, which is problematic for clients and servers running on different platforms (hopefully this limitation can be fixed at some point in the future by the JRMC developers).

Luckily, both cons can be eliminated if we introduce a third-party tool to keep the media libraries continuously in sync, so that 1) newly added media is propagated between the server and clients and 2) directory structure and filenames are always identical. The answer here is [Syncthing](https://syncthing.net/), an open-source multi-platform tool for continuous file synchronization between many clients.

### Syncthing

Syncthing is easily the most important tool in my arsenal to keep all of my various devices working in harmony. I use it on my smartphone (well, [syncthing-fork](https://f-droid.org/en/packages/com.github.catfriend1.syncthingandroid) for better battery life) to sync podcasts, photos, and documents to my laptop and desktop. I use it on my high-performance workstations to create rolling off-site backups. I use it on my servers to share configuration settings and dotfiles. Every second of every day I have bytes floating through my Syncthing cloud and it has yet to fail me.

Syncthing configuration is relatively straight-forward, thus I will not go into much depth here other than to highlight a few important settings for improving the reliability. If you have a client device that will not be adding or tagging media (in essence, a read-only client), then make sure to set the Syncthing share to "receive only" instead of the default "send and receive," which will save a few CPU cycles and prevent read-only clients from accidentally altering your media library. Additionally, make sure that the filesystem watcher is enabled so that any changes to your media files are propagated as quickly as possible to other devices.

![Syncthing shares](../assets/images/2019/05/syncthing-shares.png)

At this point you will have a fully in-sync media library residing on one or more computers. The real magic comes next when we start using JRMC to apply changes to file tags, which will also be propagated to other devices since tag changes will alter the file checksums. Since Syncthing is a block-based synchronization tool, any changes to a file's tags will not necessitate the entire file to be transferred to other clients, only a small block of data (typically a few KB), which makes it fast and bandwidth-friendly.

![Syncthing music folder configuration](../assets/images/2019/06/syncthing-music-folder-configuration.png)

### Client-client model versus the traditional server-client model

Although our media files are now in sync, and we have configured JRMC to use local file playback to save bandwidth and improve latency, the server-client model using JRMC Media Server still requires internet connectivity to function, which limits its reliability. However, we can eschew the JRMC Media Server altogether and instead utilize Syncthing to keep the separate libraries on our clients nearly identical via file tags, with one caveat:

**When using the client-client model, traditional playlists will not be automatically synced among clients** since they are stored in the JRMC library and are only exported as files when manually triggered. Later on I will describe a method later on in this guide that can replace playlist functionality using JRMC smartlists and file tags.

**Rant:** *On several occasions, I have asked the JRMC developers to consider adding an automatic playlist export core command so that Syncthing could also sync the playlist files, but they have chosen not to do so thus far. You can get close by using [the RESTful MCWS interface](https://wiki.jriver.com/index.php/Web_Service_Interface) and appropriate [JRMC core command](https://wiki.jriver.com/index.php/Media_Center_Core_Commands): `curl -s -o /dev/null -u username:password http://localhost:52199/MCWS/v1/Control/MCC?Command=20004,1`, however MC will still prompt you for the export directory and playlist format so it cannot be automated.*

The benefits of the client-client model over the server-client model include:

* Automatic redundancy of the media library
* Each client has access to the media library even when offline
* Each client can maintain its own set of views, playlists, and smartlists
    * Useful if you want to give read-only access to a client and allow it to store and display its own set of ratings from a custom tag
* Low bandwidth and low latency for playback
* Cross-platform since file structure does not have to be identical

All that must be done to enable this functionality is to set up Auto-Import on each client to point at your shared (via Syncthing) media folder!

### Consistent tagging is the key to the client-client model

The real magic here is to store as much information as possible in the file tags so that they are synced via Syncthing between JRMC clients. This can include basic information like ratings, artwork, audio analysis data (R128 normalization) or more advanced information like user-defined fields that can be used to keep smartlists in sync (see [Advanced tagging](#advanced-tagging) below for more information).

##### Sending metadata

To propagate changes from a client to other clients, we will need to enable *Edit>Edit File Tags When File Info Changes* on any JRMC client that we want to have read-write access to the file metadata. If you leave this option unchecked on a client then that client will maintain its own set of metadata in the JRMC database without propagating changes. If you want to edit the actual file tags without affecting other clients (e.g. you are moving files on the client to a handheld device), then go ahead and enable the option but set your Syncthing client to Receive Only so that it maintains its own local database state. I also recommend enabling automatic file tagging during file analysis upon Auto-Import *Options>Library & Folders>Configure auto-import>Tasks>Write file tags when analyzing audio...* so that analysis only needs to be performed once on the client that performs the initial file import.

##### Receiving metadata

In order to receive metadata updates from other clients, you'll want to use JRMC Auto-Import to watch the Syncthing music directory for changes and enable *Options>Library & Folders>Configure auto-import>Tasks>Update for external changes*.

![Auto-import settings](../assets/images/2019/06/auto-import-settings.png)

### Advanced tagging

Below I will describe two examples of expanding the functionality of the client-client model using file tags.

##### Tracking newly added media

Sometimes it is useful to keep track of which client has added a particular file to the Syncthing network. You can do this by creating a custom user-defined string field in JRMC (*Options>Library & Folders>Manage Library Fields*) named *Imported From* and check the box to *Save in file tags (when possible)*. Then configure each client to apply their specific client name to the field upon auto-import: In *Options>Library & Folders>Configure auto-import* select your auto-import directory that you are sharing with Syncthing, click *Edit...* and under *Apply these tags (optional)>Add>Custom* select the field you just created and enter the client name as the value. For instance I have named my clients *HTPC*, *Laptop*, *VPS*, and *Work*. In this manner you can track where your files were originally imported from.

![Imported From custom field](../assets/images/2019/06/imported-from-custom-field.png)

It can also be useful to use a smartlist to track newly imported media to make sure that you actually listen to it before it falls to the proverbial wayside. In this case, follow the strategy above to create a check field called *Newly Imported* that is tagged as "1" upon auto-import. Then just create a smartlist on each client that lists files with a *Newly Imported* value of 1 (optionally sorted by \[Date Imported\]). After you watch or listen to the file, simply clear the *Newly Imported* field to remove it from the smartlist on every client!

##### Smartlists as pseudo-playlists

As I outlined above it is possible use file tags in conjunction with smartlists to keep advanced file information and file lists in sync between clients. In this manner it is also possible to partially restore the ability to sync playlists between clients. In order to do this, create a new User Field named *User Playlists* with a data type of *List*. Use this field to create a semi-colon delimited list of pseudo-playlists. On each client, create a smartlist that only displays files with the matching string in the *User Playlists* field. When you want to add a file to the pseudo-playlist, simply add that playlist string to the *User Playlists* field. One drawback of this method is that it is not easy to manually reorder the smartlist for specific track ordering, but it can be done if necessary using additional user fields and/or smartlist rules to maintain the track order.

![User Playlists Field](../assets/images/2019/06/user-playlists-field.png)

![Top Hits Today Playlist](../assets/images/2019/06/top-hits-today-playlist.png)

This is just the tip of the iceberg when it comes to using file tags to share library information between clients in the client-client model.

### Conclusions

In this guide you have been shown the benefits of using a client-client JRMC network model over the traditional server-client network model used by JRMC Media Server. The client-client model allow individual clients to maintain their own instances of the file library and JRMC database, while propagating changes to other clients using file-based synchronization.
