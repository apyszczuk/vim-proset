# vim-proset: Project Settings Loader and Creator

## Introduction
Have you ever wondered how to handle project configuration in Vim?
Unfortunately there is no built-in solution for that. Vim does not have Project
Management concept implemented - too bad, but having possibility to extend Vim
using scripting language, it is possible and it has been done here in this plugin.

Proset plugin introduces Project Management idea which means you are
able to store project specific configuration directly inside your project
sources, just like IDEs do. No need to mess up your general configuration
stored in vimrc file is a big advantage.

Projects - of course - can be of different kinds (types), for example it can be
a C++ project, Vim plugin project, HTML project, etc. Each of them will naturally
give you different functionalities and options to configure. This is very
similar to IDEs since C++ one will give you completely different set of
functionalities and options than the one used for Web development.

Load functionality of Proset plugin means to choose specific project type from
registered types (supported directly by plugin or registered on your own) based
on project configuration parameter called `proset_settings`.

Each project that wants to use this plugin has to have at least one required
configuration file that has above configuration parameter. Value of such
parameter is a name of project type you want to load. When project type you
chose was registered in the plugin, it is loaded and your configuration
(from file) is read and applied.

In plugin documentation project types are rather referred as Settings
Dictionaries or Settings Objects.

Proset plugin has public API (functions and commands) that operates on concrete
Settings Object (which has to implement some interface). Such operations are
common for all Settings Objects and are accessed via Proset API.
Functionalities of Settings Objects are NOT accessible via Proset API, you have
to use concrete Settings Dictionary API to get what you want.


## Proset API
Normally on your terminal you change working directory to project root path and
start Vim, project will be loaded automatically, if possible. You can also do
this manually using `:ProsetLoad`.

To be able to load project you have to have a project.  It would be very
inconvenient if dummy project could not be created using this plugin, so the
option is of course available using `:ProsetCreate`.

If project configuration have changed, you may want to reload it, you can close
Vim and start over or you can `:ProsetReload`.

Also if you do not want to develop project any longer, you can close Vim, but
you can also `:ProsetClose`.

Full API is described in documentation of course.

## Example

Best way to show you Proset plugin in action is to do this on a screencast. This
example presents `cxx-cmake` Settings Object which is used for C++ projects.
You may or may not be familiar with C++ but I hope you get the
point.

https://github.com/user-attachments/assets/f4d53cf6-2210-4ac1-b034-75c51e707674


## Installation

Using Vim's built-in package manager:

```
mkdir -p ~/.vim/pack/vim-proset/start
cd ~/.vim/pack/vim-proset/start
git clone https://github.com/apyszczuk/vim-proset.git
vim -u NONE -c "helptags vim-proset/doc" -c q
```

## Supported Settings Dictionaries

For now there is only one Settings Dictionary supported by the plugin:
    
* `cxx-cmake` - for development of C++ project using CMake as build system.

## Further Information

Plugin and Settings Dictionaries are described in great detail in
documentation.  Firstly, read about the plugin itself (`:help proset`) to be
more familiar with design, idea and terms, then choose appropriate Settings
Dictionary documentation to find out what you can get from it (for now only
`:help cxx-cmake`).

## Contribute

If you see a bug, or something that can be improved, or have an idea of a new
Settings Dictionary or even better you have already written one and want it to
be supported by Proset plugin directly, just let me know via GitHub or email.
 

## License
Copyright © Artur Pyszczuk. Distributed under the same terms as Vim itself. See
`:help license`.
