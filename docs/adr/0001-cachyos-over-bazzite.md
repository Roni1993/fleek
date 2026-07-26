# CachyOS over Bazzite for the gaming PC

The gaming PC runs CachyOS (Arch-based, mutable, BORE-scheduler kernel) instead of Bazzite (Fedora OSTree immutable). Initially recommended Bazzite for its gaming-first image, gamescope-session (Steam Deck UI), and atomic updates. Switched to CachyOS after revisiting the Nix integration picture.

**Why it matters**: The base OS is the hardest thing to change — requires a full reinstall. It determines which Nix installer works, how gaming packages are sourced, and the update model.

**What pushed the decision**:
- Determinate Systems Nix installer is broken on OSTree filesystems (Bazzite's base). Single-user Nix works on both, but the Determinate installer is the recommended pathway and its unavailability on Bazzite signals deeper OSTree/Nix friction down the road.
- CachyOS's custom kernel (BORE scheduler) and x86-64-v3 optimized packages give measurable gaming performance wins over Fedora's stock kernel — relevant for an RTX 3060 Ti gaming build.
- AUR access means gaming tools (proton-ge-custom, gamescope-git, gamescope-session-git, etc.) are one `paru` away rather than layered via rpm-ostree or confined to Flatpak.
- The fleek HM config is distribution-agnostic. There's no lock-in to either OS — the profile works the same on both.

**What we lose vs Bazzite**:
- Atomic updates and rollback. Mitigated by CachyOS's snapshot tooling and the fact that HM manages userland, so system breakage is recoverable.
- Bazzite's curated gaming OOTB (MangoHud, gamemode, etc. pre-configured). Mitigated by declaring all of these in the HM gaming profile.

**What we do NOT lose** (available via AUR on CachyOS):
- gamescope-session (Steam Deck Game Mode UI): available as `gamescope-session-git` from AUR.
- Decky Loader: available via AUR or manual install.
- EmuDeck: standalone installer, works on any Arch distro.
