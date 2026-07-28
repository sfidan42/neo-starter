#!/usr/bin/env bash
# Stage the starter cut —
# every committed scene and script, plus EXACTLY the models the scenes
# reference — and produce the release-versioned pair
#
#   target/neo-starter.tar.zst        deterministic tar (sorted entries,
#                                     fixed mtime, no owners), zstd -19
#   target/neo-starter.manifest.ron   content_hash  = sha256 over the sorted
#                                     per-file sha256 list (stable across
#                                     tar/zstd re-runs — the "did the content
#                                     change?" key); archive_sha256 = the
#                                     uploaded bytes (the download guard)
#
# The archive attaches to a GitHub release ONLY when content differs from
# the newest previous release that shipped one: pass that release's
# manifest as `--prev <file>` and the script removes its outputs and exits
# 0 when the hash matches.
#
# Run from the repo root. Sources $NEO_STARTER_STORE (default ./assets).
set -euo pipefail

prev=""
if [ "${1:-}" = "--prev" ]; then
    prev=$2
    shift 2
fi
store=${NEO_STARTER_STORE:-assets}

if ! ls "$store"/scenes/*.ron >/dev/null 2>&1; then
    echo "no starter content under '$store' — nothing to pack" >&2
    exit 0
fi

out=target
stage=$out/starter
rm -rf "$stage" "$out/neo-starter.tar.zst" "$out/neo-starter.manifest.ron"
mkdir -p "$stage/assets/models" "$stage/assets/scenes" "$stage/assets/scripts" \
         "$stage/assets/prefabs"

cp "$store"/scenes/*.ron "$stage/assets/scenes/"
cp "$store"/scripts/*.rhai "$stage/assets/scripts/" 2>/dev/null || true
cp "$store"/prefabs/*.ron "$stage/assets/prefabs/" 2>/dev/null || true
cp "$store"/render_config.ron "$stage/assets/" 2>/dev/null || true
# The manifest sits above assets/, so the unpacked tree opens as a project.
cp "$store"/../neo.ron "$stage/" 2>/dev/null || true

# Models referenced by any scene (files or whole model dirs) — the full
# models dir carries multi-GB source folders no scene can open, and a
# GitHub release asset caps at 2 GiB.
grep -ho 'assets/models/[^"]*' "$store"/scenes/*.ron | sort -u | while read -r ref; do
    src=$store/${ref#assets/}
    if [ -d "$src" ]; then
        cp -r "$src" "$stage/assets/models/"
    elif [ -f "$src" ]; then
        cp "$src" "$stage/assets/models/"
    else
        echo "warning: scene references missing model: $ref" >&2
    fi
done

# A cut containing LFS pointers would ship stubs — refuse it.
if grep -rlq "git-lfs.github.com/spec" "$stage/assets/models" 2>/dev/null; then
    echo "error: staged models contain git-lfs pointers — run 'git lfs pull' first" >&2
    exit 1
fi

# Deterministic archive: fixed entry order, epoch-ish mtime, no owners —
# byte-equal content stages produce byte-equal archives.
tar --sort=name --owner=0 --group=0 --numeric-owner \
    --mtime='2026-01-01 00:00Z' \
    -C "$stage" -cf "$out/neo-starter.tar" .
zstd -19 -T0 -q -f "$out/neo-starter.tar" -o "$out/neo-starter.tar.zst"
rm "$out/neo-starter.tar"

content_hash=$( (cd "$stage" && find . -type f -print0 | sort -z \
    | xargs -0 sha256sum) | sha256sum | cut -d' ' -f1)

if [ -n "$prev" ] && grep -q "content_hash: \"$content_hash\"" "$prev"; then
    echo "starter content unchanged since the previous release ($content_hash) — not attaching"
    rm -f "$out/neo-starter.tar.zst"
    exit 0
fi

archive_sha=$(sha256sum "$out/neo-starter.tar.zst" | cut -d' ' -f1)
files=$(find "$stage" -type f | wc -l)
size=$(stat -c%s "$out/neo-starter.tar.zst")

# Field-for-field the engine's starter::StarterManifest.
cat > "$out/neo-starter.manifest.ron" <<EOF
(
    version: 1,
    content_hash: "$content_hash",
    archive_sha256: "$archive_sha",
    size_bytes: $size,
    files: $files,
)
EOF

echo "packed $files files, $(du -h "$out/neo-starter.tar.zst" | cut -f1) → $out/neo-starter.tar.zst"
echo "content $content_hash"
