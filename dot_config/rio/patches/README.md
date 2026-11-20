# Rio local patches

## sugarloaf-fullscreen-freeze.patch

**Problem:** on the WebGPU backend (`[renderer] backend = "Webgpu"`, required for
the CRT shader), going fullscreen freezes the window on NVIDIA + Wayland/GNOME.
Rio keeps running but nothing on screen updates anymore.

**Cause:** after the fullscreen resize, `wgpu::Surface::get_current_texture()`
returns `Outdated`. Upstream `sugarloaf::render_wgpu` silently drops the frame
and never reconfigures the surface, so every later frame fails the same way.

**Fix:** on any acquire failure (`Outdated`, `Lost`, `Timeout`, ...), log a
warning (`PATCH surface acquire failed: ...`) and reconfigure the surface at
the current size. The next frame renders normally.

- Patches: `sugarloaf` crate, `src/sugarloaf.rs`, function `render_wgpu`
- Written against: rioterm / sugarloaf **0.5.32** (wgpu 30.0.2)
- Upstream status: not reported yet

## Usage

Rebuild and install the patched Rio (default version 0.5.32):

```bash
~/.config/rio/patches/build-patched-rio.sh          # 0.5.32
~/.config/rio/patches/build-patched-rio.sh 0.5.33   # another version
```

The script:
1. fetches the `rioterm` and `sugarloaf` sources for that version into the cargo cache
2. copies them to `~/.local/src/rio-patched/` (override with `RIO_PATCHED_SRC=...`)
3. applies the patch to `sugarloaf`
4. adds `[patch.crates-io] sugarloaf = { path = "../sugarloaf" }` to rioterm's `Cargo.toml`
5. runs `cargo install --path ... --features wgpu`

Then restart Rio once.

**Manual steps** (same thing by hand):

```bash
REG=$(ls -d ~/.cargo/registry/src/index.crates.io-*/ | head -1)
mkdir -p ~/.local/src/rio-patched && cd ~/.local/src/rio-patched
cp -r $REG/rioterm-0.5.32 rioterm && cp -r $REG/sugarloaf-0.5.32 sugarloaf && chmod -R u+w .
patch -d sugarloaf -p1 < ~/.config/rio/patches/sugarloaf-fullscreen-freeze.patch
printf '\n[patch.crates-io]\nsugarloaf = { path = "../sugarloaf" }\n' >> rioterm/Cargo.toml
cargo install --path rioterm --features wgpu
```

## Check that the patched build is installed

```bash
grep -a -c 'PATCH surface acquire failed' "$(which rio)"   # 1 = patched, 0 = not
```

## Upgrading Rio

- **Do not** run a plain `cargo install rioterm`. It drops the patch, and fullscreen
  will freeze again. Also always build with `--features wgpu`, or the CRT shader
  stops working.
- On a new version, first check whether upstream fixed it. Look in
  `sugarloaf/src/sugarloaf.rs` → `render_wgpu`: if failures other than
  `Success`/`Suboptimal` now reconfigure the surface, the patch is no longer needed.
- If the patch does not apply (`patch` reports a failed hunk), re-apply the same
  change by hand: in the `_ =>` arm after `get_current_texture()`, call
  `ctx.resize(ctx.size.width as u32, ctx.size.height as u32)` before `self.reset(); return;`.

## Undo

```bash
cargo install rioterm --features wgpu --force   # upstream build (fullscreen freeze returns on Webgpu)
```
or set `backend = "Vulkan"` in `config.toml` (fullscreen works, CRT shader does not).
