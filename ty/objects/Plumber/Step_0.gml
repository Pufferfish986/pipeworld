// ---------------
// -- constants --
// ---------------

// the number of frames per second
#macro FPS 60

// the number of microseconds in a second
#macro MS 1000000

// -- move tuning --
#macro MOVE_WALK_ACCELERATION  1.8 * FPS
#macro MOVE_RUN_ACCELERATION   3.4 * FPS
#macro MOVE_AIR_ACCELERATION   2.4 * FPS
#macro MOVE_DECELERATION       4.8 * FPS

// -- jump tuning --
#macro JUMP_IMPULSE            4  * FPS * FPS
#macro JUMP_GRAVITY            16 * FPS
#macro JUMP_HOLD_GRAVITY       8  * FPS

// -- input --
#macro INPUT_LEFT  ord("A")
#macro INPUT_RIGHT ord("D")
#macro INPUT_RUN   vk_shift
#macro INPUT_JUMP  vk_space

// -- i/state
enum INPUT_STATE {
	NONE  = 0,
	PRESS = 1,
	HOLD  = 2
}

// ---------------
// -- get input --
// ---------------

// in this section, we'll read player input to use later when
// we update the character

// add input direction; add left input and right input so that
// if both buttons are pressed, the input direction is 0
var _input_move = 0;
if (keyboard_check(INPUT_LEFT)) {
	_input_move -= 1;
}

if (keyboard_check(INPUT_RIGHT)) {
	_input_move += 1;
}

// get run button input
var _input_run = keyboard_check(INPUT_RUN);

// get jump buttton input
var _input_jump = INPUT_STATE.NONE;
if (keyboard_check_pressed(INPUT_JUMP)) {
	_input_jump = INPUT_STATE.PRESS;
} else if (keyboard_check(INPUT_JUMP)) {
	_input_jump = INPUT_STATE.HOLD;
}

// ------------------
// -- add "forces" --
// ------------------

// in this section, we'll run most of our "game logic". what forces
// and other physical changes we make in response to player input.

// start with 0 forces every frame!
var _ax = 0;
var _ay = 0;

// add move acceleration
var _move_acceleration = MOVE_WALK_ACCELERATION;
if (!is_on_ground) {
	_move_acceleration = MOVE_AIR_ACCELERATION;
} else if (_input_run) {
	_move_acceleration = MOVE_RUN_ACCELERATION;
}

_ax += _move_acceleration * _input_move;


// add jump acceleration
var _event_jump = false;

// if jump was just pressed on the ground, add impulse
if (_input_jump == INPUT_STATE.PRESS && is_on_ground) {
	_ay -= JUMP_IMPULSE;
	_event_jump = true;
}
// if we're holding jump & moving upwards, add lower gravity
else if (_input_jump = INPUT_STATE.HOLD && vy < 0) {
	_ay += JUMP_HOLD_GRAVITY;
}
// otherwise, add full gravity
else {
	_ay += JUMP_GRAVITY;
}

// ---------------
// -- integrate --
// ---------------

// here's where we "do physics"! given the forces and changes we
// calculated in the previous step, update the character's velocity
// and position to their new state.

// get fractional delta time
var _dt = delta_time / MS;

// integrate acceleration into velocity
// v1 = v0 + a * t
vx += _ax * _dt;
vy += _ay * _dt;

// break down velocity into speed and direction
var _vx_mag = abs(vx);
var _vx_dir = sign(vx);

// apply deceleration if there is no player input
if (_input_move == 0) {
	_vx_mag -= MOVE_DECELERATION * _dt;
	_vx_mag = max(_vx_mag, 0);
}

vx = _vx_mag * _vx_dir;

// integrate velocity into position
// p1 = p0 + v * t
px += vx * _dt;
py += vy * _dt;

// ------------------
// -- update state --
// ------------------

// update any plumber state that may have changed and that wasn't set
// during integration

// increment frame forever
frame_index += 1;

// capture the move state
input_move = _input_move;

// if there is any move input, face that direction
if (_input_move != 0 && is_on_ground) {
	look_dir = _input_move;
}

// when the jump event fires, begin the jump animation
if (_event_jump) {
	anim_is_jumping = true;
}