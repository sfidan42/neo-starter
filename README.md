# neo-starter

Demo content for the [Neo](https://github.com/sfidan42/neo) engine — models,
scenes, scripts and prefabs. Neo ships no content of its own; the editor
downloads a release from here on first run.

```
neo.ron              project manifest
assets/models/       source models (Git LFS)
assets/scenes/       scenes; startup_scene points at one
assets/scripts/      Rhai controllers
assets/prefabs/      prefab definitions
assets/render_config.ron
```

## Using it

Clone with LFS (`git lfs install` once), then open it from a neo checkout:

```
NEO_PROJECT=/path/to/neo-starter cargo run
```

Or let the editor fetch the packed release: the launcher's Download button,
or `NEO_FETCH_STARTER=1 neo`.

## Releasing

Push a `vX.Y.Z` tag. CI packs `neo-starter.tar.zst` + `neo-starter.manifest.ron`
and attaches them to the release. Neo resolves the newest tag **at or below**
its own engine version, so tag in step with the engine release the content
targets (`engine_version` in `neo.ron`).
