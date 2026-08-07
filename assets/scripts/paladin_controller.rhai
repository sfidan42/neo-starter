// Third-person, camera-relative character controller for the Paladin.
//
// He is moved by the SIMULATION, not by being put somewhere. `walk()` asks
// his motor to push in a direction and the physics decides what actually
// happens — so he is stopped by walls, slowed by slopes, and pulled down
// by gravity like anything else with weight.
//
// That last one is why this script is shaped the way it is. An earlier
// version called `translate()` every frame, which writes his transform
// directly: while a key was held he was teleported to a new position each
// frame and gravity had nothing to say about it, and the moment the key
// came up the teleporting stopped and he dropped. He only fell when you
// let go. Movement that overwrites a position cannot coexist with physics
// that wants to own it.
//
// The split below follows from that:
//
//   fixed_update  — asking to move. Runs on the simulation's own clock, so
//                   a push means the same thing at any frame rate.
//   update        — how he LOOKS: which way he is facing, which clip is
//                   playing. Every frame, because that is what is drawn.
//
// The camera is a Chase child that the mouse orbits; WASD is read in that
// camera's ground frame, and he turns to face wherever he actually moves.
// Hold Shift to run, Space to jump.
//
// Edit the numbers below in the Viewport's Script tab and hit Save — it
// hot-reloads live while Play is running. (Rhai functions can't see
// top-level consts, so the tunables live inside the functions.)

fn init() {
    // Mixamo art faces +Z (the engine's convention is -Z). Declare it once:
    // face_move and the chase camera then steer his visual front.
    // (The inspector's Transform > forward picker records the same thing.)
    set_forward("+z");
    // The Mixamo clips carry root motion on the hips (they slide forward
    // then snap back on the loop). Hold that bone in place so the motor
    // owns the travelling. Name it once here — the engine guesses no bones.
    discard_root_motion("Hips");
    play("sword and shield idle");
}

// Where WASD points, in the camera's ground frame. Zero length means no
// input at all, which is a real answer: `fixed_update` passes it straight
// to walk() to mean "stop", and `update` reads it as "play idle".
fn wish_dir() {
    let m = move_axis();
    let dir = cam_fwd() * m.z + cam_right() * m.x;
    if dir.length() < 0.001 {
        // Exactly zero, not merely small — this is what `fixed_update`
        // hands to walk() to mean "stop".
        return dir * 0.0;
    }
    // Normalised, so diagonals aren't faster than the cardinals.
    return dir.normalize();
}

fn fixed_update(dt) {
    // A fraction of the motor's own max_speed, so "walking" and "running"
    // are relative to what the character is capable of rather than two
    // more numbers to keep in step with it. NOT named `walk` — that is the
    // function being called below, and a local of the same name shadows it.
    let strolling = 0.45;
    let sprinting = 1.0;

    let effort = strolling;
    if key_down("shift") {
        effort = sprinting;
    }

    // ALWAYS steer — including with no keys down, where `wish_dir()` is
    // zero and this means "come to a stop".
    //
    // Returning early on no input looks tidy and is wrong. The engine
    // leaves an unsteered body ALONE rather than braking it, deliberately,
    // so that a script which only occasionally steers does not fight
    // whatever else is pushing the thing. A frame that says nothing
    // therefore leaves the last push standing, and he slides on at full
    // speed with the idle animation playing. Saying "zero" every frame is
    // the difference between letting go and never having pressed.
    //
    // Push, don't place: gravity keeps the vertical the whole time, which
    // is the entire point of going through the motor.
    walk(wish_dir() * effort);

    if key_down("space") {
        jump();
    }
}

fn update(dt) {
    let turn = 0.18; // how fast he swings to face travel (0..1 per frame)

    let dir = wish_dir();
    if dir.length() < 0.001 {
        play("sword and shield idle");
        return;
    }
    // Turn to face travel. init()'s set_forward("+z") declared where his
    // front is, so the heading goes in un-negated — face_move aims the
    // DECLARED forward along it, whatever axis the art was exported on.
    face_move(dir, turn);

    let clip = "sword and shield walk";
    if key_down("shift") {
        clip = "sword and shield run";
    }
    play(clip);
}
