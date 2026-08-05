// R10: free-fly game camera, in script.
//
// A game camera (distinct from the editor's built-in viewport fly cam): the
// mouse aims it (orbit_yaw/pitch, fed while it is the Play camera) and WASD
// flies it along that aim. The eye lives in this entity's own Transform, so it
// persists across frames without any script-side state — WASD moves the
// Transform, and the view is placed at it each frame looking down the aim.

fn update(dt) {
    let speed = 4.0;                         // metres / second (× dt below)
    // Aim (unit): where the mouse points the camera.
    let cp = cos(orbit_pitch());
    let fwd = vec3(sin(orbit_yaw()) * cp, sin(orbit_pitch()), cos(orbit_yaw()) * cp);
    // Horizontal right of the aim, for strafing.
    let right = vec3(fwd.z, 0.0, -fwd.x);
    // WASD in the aim's ground frame; Shift doubles the speed.
    let s = speed * dt * (if key_down("shift") { 2.0 } else { 1.0 });
    let m = move_axis();
    let eye = pos() + fwd * (m.z * s) + right * (m.x * s);
    set_pos(eye);
    set_eye(eye);
    look_at(eye + fwd);
    set_fov(lens_fov());
}
