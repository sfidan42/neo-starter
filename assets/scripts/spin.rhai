// CP90 scripting demo. Proves the init/update lifecycle runs live against the
// object's transform. Edit these numbers in the Viewport's Script tab and hit
// Save — it hot-reloads while Play is running, no restart.

fn init() {
    log("spin.rhai: init ran");
}

// dt is seconds since last frame. yaw()/set_yaw() read/write the object's
// Y rotation (radians); it spins ~1 turn every ~6 seconds.
fn update(dt) {
    set_yaw(yaw() + dt);
}

// Signal handler: a fresh key press is delivered here in Play mode. Tap R to
// snap the spin back to zero.
fn on_key(key) {
    if key == "r" { set_yaw(0.0); }
}
