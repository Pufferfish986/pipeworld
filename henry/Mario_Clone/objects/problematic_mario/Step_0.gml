if keyboard_check_pressed(vk_escape) {game_end()}



#region ty's scary nightmare code

///*

////get state
//////////
frame += 1;

state = game.state;

//increment frame forever
state.frame_index += 1;

#region constants

// constants
#macro FPS 60
#macro MS 1000000

//move constants

#macro MOVE_WALK_ACCEL 2.2 * FPS
#macro MOVE_RUN_ACCEL 6 * FPS
#macro MOVE_AIR_ACCEL 1.8 * FPS
#macro MOVE_AIR_RUN_ACCEL 2.6 * FPS
#macro MOVE_AIR_DECEL 3 * FPS
#macro MOVE_DECEL 4 * FPS
#macro SKID_DECEL 7 * FPS

//max speeds
#macro MAX_WALK_SPD 170
#macro MAX_RUN_SPD 500
#macro MAX_AIR_SPD 100
#macro MAX_AIR_RUN_SPD 400
#macro MAX_SLOW_ANIM_SPD 50


//jump tuning
#macro JUMP_GRAVITY 19 * FPS
#macro JUMP_HOLD_GRAVITY /*3.8*/ 8 * FPS
#macro JUMP_IMPULSE /*2.9*/ 4.1 * FPS

//input constants
#macro INPUT_LEFT ord("A")
#macro INPUT_RIGHT ord("D")
#macro INPUT_RUN vk_shift
#macro INPUT_JUMP ord ("W")

// i/state
enum INPUT_STATE {
	NONE = 0,
	PRESS = 1,
	HOLD = 2,
}

// - - - - - - - - - 
// - - get state - - 
// - - - - - - - - - 
state = God.state;

#endregion

// if we're paused, do nothing
if (game.is_paused()) {
	return;
}


// - - - - - - - - - 
// - - get inputs - - 
// - - - - - - - - - 
var _input_dir = 0;

//if they're pressing a direction then say hey the input's goin that way
if keyboard_check(ord("A")) {_input_dir -= 1}
if keyboard_check(ord("D")) {_input_dir += 1}

//are we runnin?
var _input_run  = keyboard_check(INPUT_RUN);

//are we jumpin? how high?
var _input_jump = INPUT_STATE.NONE;

if keyboard_check_pressed(INPUT_JUMP) {
	_input_jump = INPUT_STATE.PRESS;
}

else if keyboard_check(INPUT_JUMP) {
	_input_jump = INPUT_STATE.HOLD;
}

// set the forces to 0 at the start of the frame
var _ax = 0;
var _ay = 0;
var _iy = 0;

//define where the bottom of the character is
var _y1 = state.py + sprite_height;

// - - - - - - - --  
//set the accellerations 
// - - - - - - - --  

//settings: move accelleration and whether or not sprint is held
var _move_accel = MOVE_WALK_ACCEL;
var _is_sprinting = false;

//if we're not in the air
if !state.is_jumping {
	_move_accel = MOVE_WALK_ACCEL;
	
	//and we're running
	if (_input_run) {
		_move_accel = MOVE_RUN_ACCEL;
	}
}
//if we are in the air
else if (state.is_jumping == 1){
	_move_accel = MOVE_AIR_ACCEL;
	
	//and we're running
	if (_input_run) {
		_move_accel = MOVE_AIR_RUN_ACCEL;
	}
}
//set whether or not we're sprinting to whether or not shift is held
_is_sprinting = _input_run

_ax += _move_accel * _input_dir;

// add jump accelleration
var _event_jump = false;

//if we're not holding jump then let state know jump isn't being held
var _is_jump_held = state.is_jump_held;

if (_input_jump == INPUT_STATE.HOLD) {
	_is_jump_held = true;
}
else {
	_is_jump_held = false;
}

//if the clicked jump and we're on the ground
if (_input_jump == INPUT_STATE.PRESS) && (state.is_on_ground) {
	_iy -= JUMP_IMPULSE;
	_event_jump = true;
	show_debug_message("frame: {0} - jump", frame);
}

//if they're holding jump then lower the gravity
else if (_is_jump_held) && (state.vy < 0) {
	_ay += JUMP_HOLD_GRAVITY;
}

//if there's no jump input, let the plumber be affected by gravity
else
{
	_ay += JUMP_GRAVITY;
}

//show_debug_message(_input_jump);

//if we  start a new jump, track that it's held
if (_event_jump){
	_is_jump_held = true;
}

// get fractional delta time
var _dt = delta_time / MS;

//this'll help debug
var _previous_vy = state.vy;

//velocity: v = u + at
state.vx += _ax * _dt;
state.vy += _ay * _dt + _iy;


//set max speeds
var _curr_vx = state.vx;
var _max_vx = state.vx;

if !state.is_jumping {
	if (abs(_curr_vx) > MAX_WALK_SPD) && !(_is_sprinting) {
		_max_vx = MAX_WALK_SPD;
	}

	if (abs(_curr_vx) > MAX_RUN_SPD) && !(_is_sprinting) {
		_max_vx = MAX_RUN_SPD;
	}
}
else if state.is_jumping {
	if (abs(_curr_vx) > MAX_AIR_SPD) && !(_is_sprinting) {
		_max_vx = MAX_AIR_SPD;
	}

	if (abs(_curr_vx) > MAX_AIR_RUN_SPD) && !(_is_sprinting) {
		_max_vx = MAX_AIR_RUN_SPD;
	}
}

//if any of these triggered, update the speed accordingly
if (_curr_vx != _max_vx) {
	state.vx = _max_vx * _input_dir;
}

//show the frame where we go from rising to falling
if (_previous_vy < 0 && state.vy >= 0) {
	show_debug_message("frame: {0} - fall", frame);
}

//add deceleration 
//Break down velocity into speed and direction
var _vx_mag = abs(state.vx);
var _vx_dir = sign(state.vx);

//apply deceleration if no input
var _dv = _ax * _dt;

if (_input_dir == 0) {
	_vx_mag -= MOVE_DECEL * _dt;
	_vx_mag = max (_vx_mag, 0);
}
//make skidding decel faster
else if (sign (_input_dir) + sign(state.vx) == 0) {
	_vx_mag -= SKID_DECEL * _dt;
	_vx_mag = max (_vx_mag, 0);
}

//redo vx
state.vx = _vx_mag * _vx_dir; 

//position: p1 = p0 + vt
state.px += state.vx * _dt;
state.py += state.vy * _dt;

// - - - - - -- 
//update state!!
// - - - - - - 


//capture the move state
state.input_dir = _input_dir;
state._is_jump_held = _is_jump_held;
state.is_sprinting = _is_sprinting;

if level_collision(x, y+sprite_height) == TILES_NONE {
	state.is_jumping = true;
}
else {state.is_jumping = false;}

//if there is move input, face that direction
if (_input_dir !=0) && (!state.is_jumping) {
	state.look_dir = _input_dir;
}


//update actual x
x = state.px;
y = state.py;

show_debug_message(state.vx)

//show_debug_message(state.vx);

#endregion






