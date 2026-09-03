---
layout: post
title: Implementing dynamic code blocks in jekyll using liquid tags
subtitle: Keep your tutorials in sync with upstream code
#bigimg: /img/path.jpg
tags: [jekyll, ruby, liquid, tags, git]
---

### Overview

Blogs are a great way to share code with users searching for solutions to similar problems. However, most code is ever-evolving, and as any programmer will tell you, "code is only finished when it is abandoned." Writing static journal entries containing copy-and-pasted code blocks will lead to divergence from your code repositories as you continue to improve your software.

**Wouldn't it be great if your blog's code blocks could dynamically track the code residing in your version control repository?**

### Github, Gogs, and GitLab

If you are using Github to host your code, there are likely plenty of existing third-party solutions for updating your code blocks in your blogging platform. If you find that the existing solutions do not work then you can also use a similar solution to the one I provide here using [ruby](https://www.ruby-lang.org/en/) and [jekyll](https://jekyllrb.com/). I prefer self-hosting my code using lightweight [gogs](https://gogs.io/) while others prefer [Gitlab](https://about.gitlab.com/) or the myriad other repository solutions that may not have existing third-party solutions for dynamic code blocks.

### Jekyll and other blogging platforms

In this example I will be using jekyll, a lightweight blogging platform built on ruby. Generally, ruby is an easy web language to write and understand with some deficiencies in documentation and debugging, which is why I would like to provide more ready-made solutions to common problems. I generally prefer [python](https://www.python.org/) for most projects but the existing functionality provided by ruby out-of-the-box for web development still outpaces [django](https://www.djangoproject.com/). If you are using a different platform and/or framework then you may be able to adapt my admittedly simple ruby solution to whichever language you require.

### `insert_git_here` ruby plugin

If you are using jekyll to build the site you wish to contain dynamic code blocks, ruby plugins will be read in automatically from the `_plugins` directory located in the root of your build.

**Note:** The `github-pages` gem disallows loading ruby plugins from the `_plugins` directory by default. In this case, you will need to set set the env `DISABLE_WHITELIST=true` or remove `github-pages` and replace it with the vanilla `jekyll` gem in your Gemfile.

In `_plugins`, create the following file:

[insert_git_code.rb](https://git.bryanroessler.com/bryan/www/raw/branch/main/blog.bryanroessler.com/_plugins/insert_git_code.rb)

{% highlight ruby %}
{% insert_git_code https://git.bryanroessler.com/bryan/www/raw/branch/main/blog.bryanroessler.com/_plugins/insert_git_code.rb %}
{% endhighlight %}

This is a fairly simple Liquid tags plugin that just returns the text in a raw text file from a url.

### Using your tag

In your markdown post or page, include something similar to the following (which is the code verbatim I used to display the dynamic code block shown above):

{% highlight markdown %}
{{ "{% highlight ruby " }}%}
{{ "{% insert_git_code https://git.bryanroessler.com/bryan/www/raw/branch/main/blog.bryanroessler.com/_plugins/insert_git_code.rb " }}%}
{{ "{% endhighlight " }}%}
{% endhighlight %}

I'm actually using the plugin to display the `insert_git_code.rb` code block above, so if you can see it you can be guaranteed that the plugin is functional.

You can always change the highlighting implementation to match your dynamic code block. The next steps are to add line number slicing for code snippet support, display a link to download the script automatically, error checking, and improving code format detection. By the time that you read this maybe some of these features will have already been implemented in the `insert_git_code` dynamic code block above! Just remember that you will need to restart jekyll in order to load your new plugin (still not fixed upstream) and regenerate your site to pull your updated code.

### Conclusions

In this tutorial we implemented a dynamic code block using a ruby plugin and liquid tags within the jekyll web framework. This strategy can be adapted to other web frameworks in order to keep instructional blog posts in sync with upstream code.
