# voronoi-nannou

GPU-accelerated animated Voronoi diagram in Rust with [Nannou](https://nannou.cc/).

<video src="voronoi.mp4" width="600" loop muted playsinline></video>

## Run

```bash
cargo run
```

## How it works

- **1,024 Voronoi sites** are randomized and animated with orbital motion.
- A **WGSL fragment shader** computes the nearest site per pixel on the GPU.
- Colors are procedurally generated from the site index.

## Stack

- Rust + [Nannou](https://nannou.cc/) 0.19
- wgpu / WGSL shaders
