# Home Manager Flake

This repo is a plain Home Manager flake.

## What this repo contains

- Shared modules: `home.nix`, `programs.nix`, `path.nix`, `shell.nix`, `user.nix`
- User identity modules: `users/roni.nix`, `users/nixos.nix`
- Environment modules: `profiles/work.nix`, `profiles/private.nix`
- Flake entrypoint: `flake.nix`

`flake.nix` exports these Home Manager targets:

- `roni@work`
- `nixos@work`
- `roni@private`

## Prerequisites

- Nix with flakes enabled
- Home Manager installed (or use the pinned flake app in this repo)

## One-command install from git

If Home Manager is already installed, you can apply directly from GitHub without cloning the repo:

```bash
home-manager switch --flake github:Roni1993/fleek#roni@work
home-manager switch --flake github:Roni1993/fleek#nixos@work
home-manager switch --flake github:Roni1993/fleek#roni@private
```

If Home Manager is not installed yet, use the pinned app exported by this flake:

```bash
nix run github:Roni1993/fleek#apply-work
nix run github:Roni1993/fleek#apply-private
```

There is also a default app that asks whether this machine is a `work` or `private` environment and then chooses the matching configuration for the current user:

```bash
nix run github:Roni1993/fleek
```

That prompt can resolve to one of these targets:

- `roni@work`
- `nixos@work`
- `roni@private`

Examples:

- user `roni` + `work` -> `roni@work`
- user `roni` + `private` -> `roni@private`
- user `nixos` + `work` -> `nixos@work`

## Adjusting Git identity

If you want different Git emails for work and private usage, edit:

- `profiles/work.nix`
- `profiles/private.nix`

## Local checkout workflow

Clone only if you want to edit the config locally:

```bash
git clone https://github.com/Roni1993/fleek.git home-manager-config
cd home-manager-config
nix flake show
```

Apply locally:

```bash
home-manager switch --flake .#roni@work
nix run .#apply-work
nix run .#apply-private
nix run .#apply-current
```

You do not need shell aliases for these commands; the flake apps are the primary interface.

## Daily workflow

After editing files, apply and inspect changes:

```bash
nix run .#apply-current
git --no-pager diff
```

If evaluation fails, use a trace:

```bash
nix run .#apply-current -- --show-trace
```

## Where to edit

- Edit shared customizations in `user.nix`
- Edit work/private differences in `profiles/*.nix`
- Edit username/home directory in `users/*.nix`
- Keep `flake.nix` for wiring inputs/targets/modules

## References

- [Home Manager manual](https://nix-community.github.io/home-manager/)
- [Home Manager options](https://nix-community.github.io/home-manager/options.html)
