// R10: free-fly game camera, in script.
//
// A game camera (distinct from the editor's built-in viewport fly cam): the
// mouse aims it (orbit_yaw/pitch, fed while it is the Play camera) and WASD
// flies it along that aim. The eye lives in this entity's own Transform, so it
// persists across frames without any script-side state — WASD moves the
// Transform, and the view is placed at it each frame looking down the aim.

fn update(dt) {
    let speed = 4.0;                         // metres / second (× dt below)
    let cp = cos(orbit_pitch());
    // Aim (unit): where the mouse points the camera.
    let fx = sin(orbit_yaw()) * cp;
    let fy = sin(orbit_pitch());
    let fz = cos(orbit_yaw()) * cp;
    // Horizontal right of the aim (fwd × up), for strafing.
    let rx =  fz;
    let rz = -fx;
    // WASD in the aim's ground frame; Shift doubles the speed.
    let s = speed * dt * (if key_down("shift") { 2.0 } else { 1.0 });
    let f = input_z() * s;                    // W/S along the aim
    let r = input_x() * s;                    // A/D strafe
    let ex = pos_x() + fx * f + rx * r;
    let ey = pos_y() + fy * f;                // vertical follows the aim's pitch
    let ez = pos_z() + fz * f + rz * r;
    set_pos(ex, ey, ez);
    set_eye(ex, ey, ez);
    look_at(ex + fx, ey + fy, ez + fz);
    set_fov(lens_fov());
}
