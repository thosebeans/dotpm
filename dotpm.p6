#!/usr/bin/env perl6

my Str $dotpmDir = "%*ENV<HOME>/DOTPM";

mkdir "{$dotpmDir}";

my Str @packages;
for (dir $dotpmDir) -> $i {
    if $i.d {
        @packages.append($i.basename)
    }
}

sub nameCheck(Str $name) returns Bool {
    if ("{$name}" ~~ / (\/) || (\.\.) || (\s) /) || ("{$name}" ~~ "." || "{$name}" ~~ "") {
        return False
    } else {
        return True
    }
}

sub getRandomString returns Str {
    my Str $randStr = "";
    for (0..4) -> $i {
        my Str $randChar = ("a".."z")[(1000..9999).rand.Int % 26];
        $randStr = "{$randStr}{$randChar}"
    }
    return "{$randStr}"
}

sub getCleanName(Str $file) returns Str {
    my Str $cleanName = $file.IO.basename;
    $cleanName = $cleanName.subst(/ (\.) || (\/) /, "");
    return $cleanName;
}

class dotpmAction {
    has Str $.path;
    has Str $.action;
    has Str $.source;
    has Str $.target;

    method install {
        chdir self.path;
        if (self.action ~~ "link") || (self.action ~~ "copy") {
            mkdir self.target.IO.dirname
        }
        given self.action {
            when "link" {
                if self.target.IO.d {
                    self.target.IO.rmdir
                } elsif self.target.IO.e {
                    self.target.IO.unlink
                }
                self.source.IO.symlink(self.target);
            }
            when "copy" {
                if self.target.IO.d {
                    self.target.IO.rmdir
                } elsif self.target.e {
                    self.target.IO.unlink
                }
                copy self.source, self.target
            }
            when "exec" {
                run "./{self.source}"
            }
        }
    }

    method mk {
        mkdir self.path;
        my Str $targetPath = self.target.subst(%*ENV<HOME>, "#HOME#");
        my Str $configFile = "action={self.action}
source={self.source}
target={$targetPath}";
        spurt "{self.path}/action.dotpm", $configFile;
        copy self.target, "{self.path}/{self.source}";
        if self.action ~~ "link" {
            self.target.IO.unlink;
            "{self.path}/{self.source}".IO.symlink(self.target);
        }
    }
}

class dotpmSet {
    has Str $.path;
    has Str @.actions;

    method getActions {
        for (dir self.path) -> $i {
            if $i.d {
                self.actions.append($i.basename)
            }
        }
    }

    method install {
        for self.actions -> $i {
            my Str $configFile = slurp "{self.path}/{$i}/action.dotpm";
            my $a = dotpmAction.new(
                path => "{self.path}/{$i}",
                action => ($configFile ~~ / [^^"action="] ("link"|"copy"|"exec") /)[0].Str,
                source => ($configFile ~~ / [^^"source="] (\N+) /)[0].Str,
                target => (($configFile ~~ / [^^"target="] (\N+) /)[0].Str).subst("#HOME#", %*ENV<HOME>),
            );
            $a.install;
        }
    }

    method mkAction(Str $action, Str $file) {
        my Str $cleanName = getCleanName($file);
        my Str $source = $cleanName;
        if $source  ~~ "action.dotpm" {
            $source = "$(getRandomString){$}"
        }
        my $a = dotpmAction.new(
            path => "{self.path}/$(getRandomString)-{$cleanName}",
            action => $action,
            source => $source,
            target => $file.IO.absolute
        );
        $a.mk;
    }
}

class dotpmPackage {
    has Str $.path;
    has Str @.sets;

    method get(Str $package) {
        for @packages -> $i {
            if $i ~~ $package {
                return dotpmPackage.new(
                    path => "{$dotpmDir}/{$package}"
                )
            }
        }
        die "invalid package"
    }

    method getSets {
        for (dir self.path) -> $i {
            if $i.d && $i.basename !~~ ".git" {
                self.sets.append($i.basename)
            }
        }
    }

    method init(Str $package) {
        unless nameCheck($package) { die "invalid package" }
        for @packages -> $i {
            if $package ~~ $i { die "package already exists" }
        } 
        run "git", "init", "{$dotpmDir}/{$package}"
    }

    method commit(Str $commitMessage) {
        chdir self.path;
        run "git", "add", "-A";
        run "git", "commit", "-m", $commitMessage;
    }

    method push {
        chdir self.path;
        run "git", "push";
    }

    method getNewSet(Str $set) {
        unless nameCheck($set) { die "invalid set" }
        unless (mkdir "{self.path}/{$set}").d { die "invalid set" }
        return dotpmSet.new(path => "{self.path}/{$set}".IO.absolute)
    }

    method getSet(Str $set) {
        for self.sets -> $i {
            if $i ~~ $set {
                return dotpmSet.new(
                    path => "{self.path}/{$set}"
                )
            }
        }
        die "invalid set"
    }
}

sub listPackages {
    say "Packages:";
    for @packages -> $i {
        say "    {$i}"
    }
}

#| add <file> to <package>/<set>/ACTION and replace it with a symlink; <file> will be symlinked from <package>/<set>/ACTION when installed
multi MAIN("link", Str $package, Str $set, Str $file) {
    my $p = dotpmPackage.get($package);
    my $s = $p.getNewSet($set);
    $s.mkAction("link", $file);
}

#| add <file> to <package>/<set>/ACTION; FILE will be copied form <package>/<set>/ACTION when installed
multi MAIN("copy", Str $package, Str $set, Str $file) {
    my $p = dotpmPackage.get($package);
    my $s = $p.getNewSet($set);
    $s.mkAction("copy", $file);
}

#| add <file> to <package>/<set>/ACTION; FILE will be executed inside <package>/<set>/ACTION when installed
multi MAIN("exec", Str $package, Str $set, Str $file) {
    my $p = dotpmPackage.get($package);
    my $s = $p.getNewSet($set);
    $s.mkAction("exec", $file);
}

#| performs all ACTIONS in <package>/<set>
multi MAIN("install", Str $package, Str $set) {
    my $p = dotpmPackage.get($package);
    $p.getSets;
    my $s = $p.getSet($set);
    $s.getActions;
    $s.install;
}

#| clones the git-repository from <location> into ~/DOTPM, using its default name
multi MAIN("clone", Str $location) {
    chdir $dotpmDir;
    run "git", "clone", $location;
}

#| clones the git-repository from <location> into ~/DOTPM, using <package> as its name
multi MAIN("clone", Str $location, Str $package) {
    unless nameCheck($package) { die "invalid package" }
    for @packages -> $i {
        if $i ~~ $package { die "invalid package" }
    }
    chdir $dotpmDir;
    run "git", "clone", $package;
}

#| creates an emtpy package <package> inside ~/DOTPM
multi MAIN("init", Str $package) {
    dotpmPackage.init($package)
}

#| adds all new files to <package> and commits all changes, if <commitMessage> is omitted, it will be randomly generated
multi MAIN("commit", Str $package, Str $commitMessage="$(getRandomString)") {
    my $p = dotpmPackage.get($package);
    $p.commit($commitMessage);
}

#| pushs <package> to its remote-repository
multi MAIN("push", Str $package) {
    my $p = dotpmPackage.get($package);
    $p.push;
}

#| lists all packages
multi MAIN("list") {
    listPackages;
}

#| lists all sets of <package>
multi MAIN("list", Str $package) {
    my $p = dotpmPackage.get($package);
    $p.getSets;
    say "{$package}:";
    for $p.sets -> $i {
        say "    {$i}"
    }
}