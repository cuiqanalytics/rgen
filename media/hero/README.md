# Hero video

52-second silent, captioned demo of rgen: Docker install → one-line table → linked tables
→ digital twin.

```bash
./build.sh                                    # → ../rgen-hero.mp4, ../rgen-hero-square.mp4,
                                              #   ../rgen-hero-poster.jpg, ../rgen-hero.gif
./build.sh stills 5,15,31,42                  # PNG stills in out/, for a quick look
./build.sh capture                            # only refresh content.js
```

Needs `docker` with the `ghcr.io/cuiqanalytics/rgen` image (or network access to pull it),
`duckdb`, `ffmpeg`, `node` and a global `playwright` with Chromium. No license is needed;
every beat uses free features.

Nothing on screen is mocked. `build.sh` runs the real commands through the container
(`rgen --version`, `rgen run`, `rgen run --config`, `rgen twin`), runs the real `duckdb`
join, and computes the histogram and summary stats from the real outputs. `stage.js` only
animates that content on a deterministic timeline. `render.mjs` screenshots it frame by
frame, so every run is identical. The typing and the Galton-board background are staged.

**`docker pull` caveat:** until the image is published on ghcr.io, `build.sh` pushes the
local image to a throwaway local registry and captures a genuine pull from it, rewriting
`localhost:5555/` to `ghcr.io/` in the text. Once the image is public, re-run `build.sh`
and it captures the real ghcr.io pull instead.

Open `stage.html` in a browser (after one `build.sh capture`) to watch it loop live, or
`stage.html?aspect=square` for the 1:1 cut. Timings live in `stage.js` (`CAPS` and the
`t >= …` gates).
