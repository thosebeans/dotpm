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

    method getSet(Str $set) {
        unless nameCheck($set) { die "invalid set" }
        unless (mkdir "{self.path}/{$set}").d { die "invalid set" }
        return dotpmSet.new(path => "{self.path}/{$set}".IO.absolute)
    }
}

sub listPackages {
    say "Packages:";
    for @packages -> $i {
        say "    {$i}"
    }
}

sub showHelp {
    say "dotpm - help
dotpm link PACKAGE SET FILE - add FILE to PACKAGE/SET/ACTION and replace it with a symlink; FILE will be symlinked from PACKAGE/SET/ACTION when installed
dotpm copy PACKAGE SET FILE - add FILE to PACKAGE/SET/ACTION; FILE will be copied form PACKAGE/SET/ACTION when installed
dotpm exec PACKAGE SET FILE - add FILE to PACKAGE/SET/ACTION; FILE will be executed inside PACKAGE/SET/ACTION when installed
dotpm init PACKAGE          - creates an emtpy package
dotpm commit PACKAGE COMMITMESSAGE - adds all new files to a package and commits all its changes; if COMMITMESSAGE is omitted, it will be randomly generated
dotpm push PACKAGE          - pushs the changes of PACKAGE to its remote-repository
dotpm list PACKAGE          - lists all sets of PACKAGE; if PACKAGE is omitted, all packages will be listed
dotpm help                  - show this"
}

multi MAIN("link", Str $package, Str $set, Str $file) {
    my $p = dotpmPackage.get($package);
    my $s = $p.getSet($set);
    $s.mkAction("link", $file);
}

multi MAIN("copy", Str $package, Str $set, Str $file) {
    my $p = dotpmPackage.get($package);
    my $s = $p.getSet($set);
    $s.mkAction("copy", $file);
}

multi MAIN("exec", Str $package, Str $set, Str $file) {
    my $p = dotpmPackage.get($package);
    my $s = $p.getSet($set);
    $s.mkAction("exec", $file);
}

multi MAIN("init", Str $package) {
    dotpmPackage.init($package)
}

multi MAIN("commit", Str $package, Str $commitMessage="$(getRandomString)") {
    my $p = dotpmPackage.get($package);
    $p.commit($commitMessage);
}

multi MAIN("push", Str $package) {
    my $p = dotpmPackage.get($package);
    $p.push;
}

multi MAIN("list") {
    listPackages;
}

multi MAIN("list", Str $package) {
    my $p = dotpmPackage.get($package);
    $p.getSets;
    say "{$package}:";
    for $p.sets -> $i {
        say "    {$i}"
    }
}

multi MAIN("help") {
    showHelp;
}