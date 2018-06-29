---
layout: post
title: Strategies for maximizing a low-end VPS
subtitle: It can do it!
#bigimg: /img/path.jpg
tags: [vps]
---

The rapidly deflating prices of cloud storage (or other low-end) VPS services means that it is more economical than ever to roll your own off-site backup solution, free from the limitations of third-party backup providers that offer middling workflow integration, questionable security, and expensive bandwidth. As an added bonus, these cheap storage VPS instances can also integrate a variety of lightweight web services, such as dynamic DNS, git repos, filesharing, or **even a web site**!

VPS deal aggregate sites, such as [lowendbox](lowendbox.com), regularly provide offers on storage VPS services that rival shared web hosting or dedicated cloud backup providers. However, while the costs of cloud storage space have dropped dramatically, the CPU and memory configurations offered with the most storage VPS configurations are usually quite limited. Oftentimes a VPS provider will limit virtualized storage VPS instances to only 1 CPU core and <1GB memory (512MB is also common), since the intended use case is to simply provide enough resources for effective backup and retrieval.

### Selecting an OS
For the purposes of minimizing RAM consumption on a low-end VPS, it is imperative to select an OS  that is lightweight, flexible, well-supported, and capable of running your intended services. Unfortunately, while most compute VPS instances provide a seemingly endless selection of server OSes to choose from, choices are usually limited on storage VPS instances by comparison. Windows Server is not a great choice because of its large memory footprint compared to its Linux-based equivalents. **Ubuntu Server LTS, CentOS, or Debian are usually safe bets**, but make sure to check that any third-party software (_i.e._ not in the repositories) that you intend to run are compatible with the libraries that ship with your Linux distribution of choice. The most common problem is trying to use newer software on older, stable Linux distributions. For example, [JRiver Media Center](https://yabb.jriver.com/interact/index.php/board,58.0.html) is built on Debian 8 Jessie but will not run on CentOS 7 because it ships with older C++ libraries. I prefer Redhat distributions (for reasons I will explain in a later post) but [my storage VPS host](www.time4vps.com) does not offer Fedora as an option (likely due to its short release cycle), which meant that my choices were limited to either Ubuntu 16.04 LTS or Debian 8. Expect for a base Linux OS installation to use ~125MB of RAM.

### Selecting a web server
[Digital Ocean](https://www.digitalocean.com/community/tutorials/apache-vs-nginx-practical-considerations) offers an in-depth comparison of the two major web servers, Apache and Nginx. Long story short, **Nginx provides better performance and uses fewer resources than Apache** thanks to its asynchronous design. The Nginx process itself is single-threaded, which is perfect for a low-end VPS with only a single CPU core. Nginx can also be used as a [reverse proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/) (using the `proxy_pass` block) to act as a secure front-end for other web services.

### Selecting a website generator
In the past, web development for the layman necessitated using heavy content management systems like [Wordpress](wordpress.com) to handle website design and editing. Unfortunately, **a single instance of Wordpress can easily use up >256MB of RAM**, which would quickly gobble up the available resources on a low-end VPS. Additionally, Wordpress creates dynamic sites that chew up CPU cycles on the server to serve dynamic content whenever the site is accessed. Luckily there has recently been a shift among (primarily smaller) sites to using static site generators such as [**Jekyll**](https://jekyllrb.com/) (my favorite) or [HUGO](https://gohugo.io/) that compile sites beforehand and only serve static HTML/CSS versions of the page. This results in much lower overhead and resources, since post-compile there is nothing actually running except your web server (of course your OS may cache the site in memory to speed up future accesses).

It's certainly possible to generate your sites locally and only transfer the output to your server's /www directory. However, since content creation in Jekyll is primarily some variation of Markdown language, I prefer using **Git** to push to the server and using post-hooks to generate the site remotely. It only takes a few seconds to generate most sites and as a result your source content is safely duplicated and version controlled on the storage VPS (that is the point of using a storage VPS in the first place, _right_?). As an alternative to git post-hooks (and for a slightly higher performance overhead), you can also use Jekyll's `--incremental` and `--watch` switches to easily and automatically regenerate selected site folders.

### Additional Services
In addition to a lightweight web server, consider adding the following useful services:
* Private Dynamic DNS
 * Use [MiniDynDNS](https://github.com/arkanis/minidyndns) to listen for IP address updates from your other computers (running a dynamic DNS client).
* File syncing
 * Run an [rsync daemon](https://www.atlantic.net/cloud-hosting/how-to-setup-rsync-daemon-linux-server/) to cache large numbers of incrementally-updated files without opening and closing an ssh connection.
 * For a slightly higher performance penalty, consider using [syncthing](https://syncthing.net/) to keep directories automatically synced between one or more computers. This can be useful when transferring static sites from a build server to the production server. Make sure to enable the file watcher functionality and decrease the full-scan interval to keep the cpu cycles to a minimum.
* Code repository
 * Following Microsoft's recent acquisition of GitHub, many free software advocates are looking to plan B solutions or storing their git repositories online. [GitLab](https://about.gitlab.com/) is a popular alternative, but self-hosting can also make a lot of sense for small or personal projects. While GitLab is available to run on your own site, it is quite resource heavy, making it a poor choice for low-end storage VPS's. Lightweight alternatives include [**Gogs**](https://gogs.io/) and [cgit](https://git.zx2c4.com/cgit/). cgit is the lightest of the bunch, but Gogs presents a more familiar "Github-like" interface that is more comfortable for collaborators or others trying to view or clone your code.  
* Certbot
 * Keep your LetsEncrypt HTTPS certificates automatically up-to-date. If you are using Nginx as a reverse proxy with subdomains, the new LetsEncrypt wildcard certificates can be used to secure all of your subdomains in one go. Don't forget to also include the root of your site in the certificate!
* Media server
 * This can be as simple as an FTP server or as complicated as a dedicated media server program like the aforementioned JRiver Media Center.
