// R10: third-person chase camera, in script.
//
// A port of the engine's former Rust chase (chase_pose): sit
// `distance` behind the target's mouse-orbit heading and `height` above the
// target, looking at it, with the boom pulled in so the view never clips a
// wall. The stateful, world-touching parts stay in the host — spring_arm()
// returns the already collision-clamped, smoothed boom length; this script
// only composes the pose from it and the orbit angles.
//
// The camera follows its Parent (the object it's a child of): target_x/y/z()
// is that object's world position, rename- and reorder-proof. distance/height
// are the camera's Chase knobs and fov its Camera lens — all edited in the
// inspector, read here.

fn update(dt) {
    let d  = spring_arm(chase_distance());   // host: boom after wall + smoothing
    let cp = cos(orbit_pitch());
    // Boom direction out behind the orbit yaw/pitch (unit): +yaw sweeps around
    // the target, +pitch lifts and looks down. Matches the old Rust `dir`.
    let dx = sin(orbit_yaw()) * cp;
    let dy = sin(orbit_pitch());
    let dz = cos(orbit_yaw()) * cp;
    let px = target_x();
    let py = target_y() + chase_height();    // pivot: height above the target
    let pz = target_z();
    set_eye(px + dx * d, py + dy * d, pz + dz * d);
    look_at(px, py, pz);
    set_fov(lens_fov());
}
