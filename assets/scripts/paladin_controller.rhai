// Third-person, camera-relative character controller for the Paladin.
//
// He is a physical body, not a moved transform: give him a Character
// (right-click him in the Level tree -> Add -> Character) and this steers the
// motor rather than teleporting him. He accelerates because his feet push on
// the ground, he stops when he walks into a wall, and he stays on whatever he
// is standing on. Without a Character he simply does not move — walk() has
// nothing to push.
//
// The two callbacks do different jobs, on different clocks:
//
//   fixed_update(dt)  once per 1/60 s simulation step. Pushing goes here, so
//                     the same push means the same thing at 30 fps and 144.
//   update(dt)        once per frame. Looking at things goes here — the turn
//                     and the animation, which are about what he LOOKS like
//                     and should be as smooth as the display allows.
//
// Edit the numbers below in the Viewport's Script tab and hit Save — it
// hot-reloads live while Play is running. (Rhai functions can't see top-level
// consts, so the tunables live inside each function.)

fn init() {
    // Mixamo art faces +Z (the engine's convention is -Z). Declare it once:
    // face_move/move_local and the chase camera then steer his visual front.
    // (The inspector's Transform > forward picker records the same thing.)
    set_forward("+z");
    // The Mixamo clips carry root motion on the hips (they slide forward then
    // snap back on the loop). Hold that bone in place so the simulation's
    // movement owns the travelling. Name it once here — the engine guesses
    // no bones.
    discard_root_motion("Hips");
    play("sword and shield idle");
}

// Where WASD is asking to go, in world XZ: the camera's ground frame, so W is
// always "into the view". Zero-length when nothing is held.
fn wish() {
    let m = move_axis();
    let dir = cam_fwd() * m.z + cam_right() * m.x;
    if dir.length() < 0.001 {
        return vec3(0.0, 0.0, 0.0);
    }
    // Normalised, so diagonals aren't faster than the cardinals.
    let d = dir.normalize();
    return vec3(d.x, 0.0, d.z);
}

fn fixed_update(dt) {
    let stroll = 0.45;   // fraction of the motor's top speed when not running

    let dir = wish();
    // Walking is a full-speed request scaled by the length of what is asked
    // for: hold Shift and he asks for all of it, otherwise a fraction. The
    // motor turns that into a force his legs and the ground can both supply,
    // which is why he does not reach top speed instantly and cannot reach it
    // at all on ice.
    if key_down("shift") {
        walk(dir);
    } else {
        walk(dir * stroll);
    }
    // Jump only lands if he is standing on something — the motor checks, so
    // this can ask freely.
    if key_down("space") {
        jump();
    }
}

fn update(dt) {
    let turn = 0.18;   // how fast he swings to face travel (0..1 per frame)

    // Face where he is actually GOING, not where the stick is pointing: the
    // two differ when he is sliding along a wall, and the body is the honest
    // answer. Below a crawl there is no travel direction to face.
    let raw = velocity();
    let v = vec3(raw.x, 0.0, raw.z);
    if v.length() > 0.2 {
        // init()'s set_forward("+z") declared where his front is, so the
        // heading goes in un-negated — face_move aims the DECLARED forward
        // along it, whatever axis the art was exported on.
        face_move(v, turn);
    }

    // The clip follows the speed he is really moving at, so walking into a
    // wall stops the legs too.
    let speed = v.length();
    if !grounded() {
        play("sword and shield idle");
    } else if speed > 3.0 {
        play("sword and shield run");
    } else if speed > 0.2 {
        play("sword and shield walk");
    } else {
        play("sword and shield idle");
    }
}
