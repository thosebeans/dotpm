# DOTPM - a dotfile- and configurations-package-manager, written in Perl6
dotpm is a highly configurable package-manager, to keep track of your dotfiles and automate the configurations of your systems.
## How it works
All file of `dotpm` are located inside `~/DOTPM`.  
This directory will be automatically created, if it doesent exist.
### Packages
All packages are located, directly, inside `~/DOTPM`.  
Packages are Git-repositories.
### Sets
Packages persist out of sets.  
A set is, kind of, a category of a package.  
Sets are normal directories.
### Actions
Sets persist out of actions.  
An action is a directory, located inside a set.  
It persists out of a configuration-file, called `action.dotpm` and a ´source-file´.
#### action.dotpm
Example  
```
action=link
source=bashrc
target=#HOME#/.bashrc
```
##### action
Defines which type of action to execute.
Possible types are **link**, **copy**, **exec**.  

| type | description |
|------|-------------|
| link | symlinks the `source-file` to its target-location, when installed |
| copy | copies the `source-file` to its target-location, when installed |
| exec | executes the `source-file`, **inside**, its action-directory |

##### source
Defines the name of the `source-file`, inside of the action-directory.
Is the file, you imported into a set.

##### target
Defines the location, where your `source-file`, should be copied or linked to, when installed.
