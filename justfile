# macbookair nix-darwin-config: run from ~/nix-darwin-config; `just` lists recipes.

default:
    @just --list

# apply config changes (nh shows a diff + asks first)
switch:
    nh darwin switch .

# bump flake.lock to latest, then switch
update:
    nh darwin switch . --update

# build without activating
check:
    nh darwin build .

# revert to the previous generation
rollback:
    sudo darwin-rebuild --rollback

# list generations
generations:
    darwin-rebuild --list-generations

# op-cached = `op read` + login-Keychain cache: one Touch ID per session, not per read.
# example: pull a file-secret from 1Password (edit the op:// ref + output path)
secret:
    umask 077; { ~/.local/bin/op-cached "op://Private/<item>/<field>"; echo; } > ~/.config/<app>/<file>

# GC is automatic (Determinate); force one with: nh clean all --keep 5 --keep-since 7d
