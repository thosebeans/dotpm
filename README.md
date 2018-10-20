# DOTPM - a dotfile- and configurations-package-manager, written in Perl6
dotpm is a highly configurable package-manager, to keep track of your dotfiles and automate the configurations of your systems.

## Installation
1. Clone the Repository
```
git clone https://github.com/thosebeans/dotpm.git
```
2. Install it
```
sudo make install
```
or copy `dotpm.p6` into your `PATH`.

### Dependecies
- A working Perl6-Distribution, eg. [Rakudo](https://perl6.org/).
- Git

## How it works
All file of `dotpm` are located inside `~/DOTPM`.  
This directory will be automatically created, if it doesent exist.

| component | description |
|--|--|
| Packages | All packages are located, directly, inside `~/DOTPM`.<br>Packages are Git-repositories. |
| Sets | Packages persist out of sets.<br>Sets are normal directories. |
| Actions | Packages persist out of sets.<br>An action is a directory, located inside a set.<br>It persists out of a configuration-file, called `action.dotpm` and a ´source-file´. |

Example `~/DOTPM`:
```
~/DOTPM/
  mydotfiles/
    bash/
      ioqba-bashrc/
        action.dotpm
        bashrc
      oquup-profile/
        action.dotpm
        profile
    nvim/
      qribs-initvim
        action.dotpm
        initvim
      install-vimplug
        action.dotpm
        install.sh
  rickswallpapers/
    anime/
      ioqyy-sao1jpg/
        action.dotpm
        sao1jpg
      iqqcv-deathnote233/
        action.dotpm
        deathnote233
```

#### action.dotpm
Example  
```
action=link
source=bashrc
target=#HOME#/.bashrc
```

| tag | example | description |
|--|--|--|
| action - link | action=link | symlinks the `source-file` to its target-location, when installed |
| action - copy | action=copy | copies the `source-file` to its target-location, when installed |
| action - exec | action=exec | executes the `source-file`, **inside**, its action-directory |
| source | source=bashrc | Defines the name of the `source-file`, inside of the action-directory.<br>Is the file, you imported into a set. |
| target | target=#HOME#/.bashrc | Defines the location, where your `source-file`, should be copied or linked to, when installed. |

## Usage
### Creating a new Package
| command | description |
|--|--|
| dotpm init `PACKAGE` | Creates the package `PACKAGE`. |

### Cloning a package
| command | description |
|--|--|
| dotpm clone `LOCATION` | Clone the repository from `LOCATION`, into `~/DOTPM`, using its default name. |
| dotpm clone `LOCATION` `PACKAGE` | Clone the repository from `LOCATION`, into `~/DOTPM`, using `PACKAGE` as its name. |

### Commiting all changes of a package
| command | description |
|--|--|
| dotpm commit `PACKAGE` | Commits all changes of `PACKAGE`. The commit-message will be randomly generated |
| dotpm commit `PACKAGE` `COMMIT-MESSAGE` | Commits all changes of `PACKAGE`. `COMMIT-MESSAGE` will be used as commit-message. |

### Pushing a package, to its remote-repository 
| command | description |
|--|--|
| dotpm push `PACKAGE` | Pushs the changes of `PACKAGE`, to its default remote-repository. |

### Pulling changes of a package
| command | description |
|--|--|
| dotpm pull `PACKAGE` | Pulls the changes of `PACKAGE` from its remote-repository. |

### Adding actions
| command | description |
|--|--|
| dotpm link `PACKAGE` `SET` `FILE` | Copy `FILE` into `PACKAGE`/`SET`. Replace file with a symlink, to its copy in `SET`. `FILE` will be symlinked, when installed. |
| dotpm copy `PACKAGE` `SET` `FILE` | Copy `FILE` into `PACKAGE`/`SET`. `FILE` will be copied, when installed. |
| dotpm exec `PACKAGE` `SET` `FILE` | Copy `FILE` into `PACKAGE`/`SET`. `FILE` will be excuted, when installed. |

### Installing a set
| command | description |
|--|--|
| dotpm install `PACKAGE` `SET` | Perform all actions inside `PACKAGE`/`SET`. |

### List all packages 
| command | description |
|--|--|
| dotpm list | Lists all packages. |
| dotpm list `PACKAGE` | Lists all sets of `PACKAGE`. |

### Show help
All inputs, that dont match one of the above commands, will show the help-message.
