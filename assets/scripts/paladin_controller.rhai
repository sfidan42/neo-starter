// CP90: third-person, camera-relative character controller for the Paladin.
//
// Flat-ground assumption (no physics): the mover only touches X/Z, so his feet
// stay on whatever Y the scene placed him at. The camera is a Chase
// child that the mouse orbits; WASD is read in that camera's ground frame, and
// the Paladin turns to face wherever he actually moves. Hold Shift to run.
//
// Edit the numbers below in the Viewport's Script tab and hit Save — it
// hot-reloads live while Play is running. (Rhai functions can't see top-level
// consts, so the tunables live inside update().)

fn init() {
    // Mixamo art faces +Z (the engine's convention is -Z). Declare it once:
    // face_move/move_local and the chase camera then steer his visual front.
    // (The inspector's Transform > forward picker records the same thing.)
    set_forward("+z");
    // The Mixamo clips carry root motion on the hips (they slide forward then
    // snap back on the loop). Hold that bone in place so this script's movement
    // owns the travelling. Name it once here — the engine guesses no bones.
    discard_root_motion("Hips");
    play("sword and shield idle");
}

fn update(dt) {
    let walk = 2.0;    // metres / second
    let run  = 4.5;
    let turn = 0.18;   // how fast he swings to face travel (0..1 per frame)

    // WASD intent projected onto the camera's horizontal basis: W/S runs into
    // the view, A/D across it.
    let m = move_axis();
    let dir = cam_fwd() * m.z + cam_right() * m.x;

    if dir.length() < 0.001 {
        play("sword and shield idle");
        return;
    }
    // Normalised, so diagonals aren't faster than the cardinals.
    dir = dir.normalize();

    let spd = walk;
    let clip = "sword and shield walk";
    if key_down("shift") {
        spd = run;
        clip = "sword and shield run";
    }

    translate(dir * (spd * dt));
    // Turn to face travel. init()'s set_forward("+z") declared where his
    // front is, so the heading goes in un-negated — face_move aims the
    // DECLARED forward along it, whatever axis the art was exported on.
    face_move(dir, turn);

    play(clip);
}
