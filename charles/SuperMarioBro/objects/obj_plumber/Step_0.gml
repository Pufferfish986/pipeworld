var _dt = delta_time/1000000;
var _move_acc = 0.1 * fps;
var _decc = 0.002 * fps;

var _rightkey = keyboard_check(vk_right);
var _leftkey = keyboard_check(vk_left);
var _jump = keyboard_check_pressed(ord("X"));
var _jump_hold = keyboard_check(ord("X"));
var _run = keyboard_check(ord("Z"));

var _horizontal = _rightkey - _leftkey;

//saves horizontal for flipping xscale
if(_horizontal != 0 && state != "is_jumping")
{
	last_horizontal = _horizontal;
}

//check horizontal input
if(!_rightkey && !_leftkey)
{
	horizontal_input = false;
}
else if(_horizontal != 0)
{
	horizontal_input = true;
}

//starts falling when jump button is released
if(!_jump_hold && vy < 0)
{
	vy = max(vy, 0);
}

//start jumping when jump button pressed
if(_jump && is_grounded)
{
	vy = jump_vel;
	obj_sound_manager.play_one_shot(snd_mario_jump);
	state = "is_jumping";
}
else if(vy > 0 && is_grounded)
{
	state = "is_idle";
}

//changes gravity accordingly
if(vy < 0)
{
	grav = up_grav;
}
else
{
	grav = down_grav;
}

if(horizontal_input)
{
	var _acc_x = _move_acc  * _horizontal;
	vx += _acc_x * _dt;
	
	if(state != "is_jumping")
	{
		//change state based on inputs
		if(_run)
		{
			state = "is_running";
		}
		else
		{
			state = "is_walking";
		}
	
		if(sign(last_horizontal) != sign(vx) && state != "is_idle")
		{
			state = "is_turning";
			vx_max = turning_spd;
		}
	}
	
}
else
{
	//decelerating according to last facing direction
	if(last_horizontal > 0)
	{
		if(vx > 0)
		{
			vx -= _decc;
		}
		else
		{
			vx = 0;
		}
	}
	else
	{
		if(vx < 0)
		{
			vx += _decc;
		}
		else
		{
			vx = 0;
		}
	}
	
	if(vx == 0 && state != "is_jumping")
	{
		state = "is_idle";
	}
}

//changes y velocity with gravity
vy += grav * _dt;

vx = clamp(vx, -vx_max, vx_max);

//y collision
if(place_meeting(x, y + vy, ground_tiles))
{
	y = floor(y);
	vy = 0;
}

//x collision
if(place_meeting(x + vx, y, ground_tiles))
{
	vx = 0;
}

//checks if it is grounded
if(place_meeting(x, y + 2, ground_tiles))
{
	is_grounded = true;
}
else
{
	is_grounded = false;
}

//screen border
if(x <= -sprite_width/2 || x >= room_width - sprite_width/2)
{
	vx = 0;
}
if(y < 0 || y >= room_height - sprite_height)
{
	vy = 0;
}

//flips xscale
image_xscale = sign(last_horizontal);

//character state
switch(state)
{
	case "is_idle":
		image_speed = 1;
		sprite_index = spr_mario_idle;
		vx_max = walking_spd;
	break;
	case "is_walking":
		image_speed = 1;
		sprite_index = spr_mario_walking;
		vx_max = walking_spd;
	break;
	case "is_running":
		image_speed = 2;
		sprite_index = spr_mario_walking;
		vx_max = running_spd;
	break;
	case "is_turning":
		image_speed = 1;
		sprite_index = spr_mario_turning;
	break;
	case "is_jumping":
		image_speed = 1;
		sprite_index = spr_mario_jump;
	break;
}

x += vx;
y += vy;

x = clamp(x, sprite_width/2, room_width + sprite_width/2);
y = clamp(y, 0, room_height + sprite_height/2);

if(vy < 0)
{
	frame++;
}

show_debug_message(frame);

