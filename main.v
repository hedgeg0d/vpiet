module main

import os
import gx

fn gen_header(mut file os.File, width u32, height u32) {
	file.write_string('P3\n#generated\n${width} ${height}\n255\n') or {panic(err)}
}

const colors_light = [
	[255, 192, 192],	// red
	[255, 255, 192],	// yellow
	[192, 255, 192], 	// green
	[192, 255, 255],	// cyan
	[192, 192, 255],	// red
	[255, 192, 255]		// magenta
]

const colors = [
	[255, 0, 0], 	// red 
	[255, 255, 0], 	// yellow
	[0, 255, 0],  	// green
	[0, 255, 255],	// cyan
	[0, 0, 255],	// blue
	[255, 0, 255]	// magenta
]

const colors_dark = [
	[192, 0, 0],	// red
	[192, 192, 0],	// yellow
	[0, 192, 0],	// green
	[0, 192, 192],	// cyan
	[0, 0, 192],	// blue
	[192, 0, 192],	// magenta
]

enum Funcs {
	push
	pop
	add
	sub
	mul
	div
	mod
	not
	dup
	roll
	great
	pointer
	switch
	inn		// cin number	(0-255)
	inc		// cin char 	(ASCII)
	outn	// cout num		(0-255)
	outc	// cout char	(ASCII)
}

fn gen_pixel(mut c gx.Color, f Funcs) {
	mut hue, mut brightness := rgb_to_params(c)
	match f {
		.push {brightness++}
		.pop  {brightness+=2}
		
		.add {hue++}
		.sub {hue++; hue++}
		.mul {brightness+=2; hue++}
		
		.div {hue+=2}
		.mod {hue+=2; brightness++}
		.not {hue+=2; brightness+=2}
		
		.great   {hue+=3}
		.pointer {hue+=3; brightness++}
		.switch  {hue+=3; brightness+=2}
		
		.dup  {hue+=4}
		.roll {hue+=4; brightness++}
		.inn  {hue+=4; brightness+=2}

		.inc  {hue+=5}
		.outn {hue+=5; brightness++}
		.outc {hue+=5; brightness+=2}
		else {}
	}
	c = get_color(hue % 6, brightness % 3)
}

fn rgb_to_params(c gx.Color) (u8, u8) {
	for n, _ in colors {
		r := colors[n][0]; g := colors[n][1]; b := colors[n][2]
		if gx.rgb(u8(r), u8(g), u8(b)) == c {return u8(n), 1}
	}
	for n, _ in colors_light {
		r := colors_light[n][0]; g := colors_light[n][1]; b := colors_light[n][2]
		if gx.rgb(u8(r), u8(g), u8(b)) == c {return u8(n), 0}
	}
	for n, _ in colors_dark {
		r := colors_dark[n][0]; g := colors_dark[n][1]; b := colors_dark[n][2]
		if gx.rgb(u8(r), u8(g), u8(b)) == c {return u8(n), 2}
	}
	return 228, 228
}

fn get_color(hue u8, brightness u8) gx.Color {
	mut r, mut g, mut b := 0, 0, 0
	match brightness {
		0 {r, g, b = colors_light[hue][0], colors_light[hue][1], colors_light[hue][2]}
		1 {r, g, b = colors[hue][0], colors[hue][1], colors[hue][2]}
		2 {r, g, b = colors_dark[hue][0], colors_dark[hue][1], colors_dark[hue][2]}
		else {}
	}
	return gx.rgb(u8(r), u8(g), u8(b))
}

fn write_pixel(mut file os.File, col gx.Color) {
	file.write_string("${col.r} ${col.g} ${col.b}\n") or {panic(err)}
}

const width  = 4
const height = 4

fn main() {
	mut out 	:= os.create("main.ppm") or {panic(err)}
	mut curr_color 	:= gx.rgb(192, 0, 0)
	mut rsp := u32(0)
	gen_header(mut out, width, height)
	write_pixel(mut out, curr_color)
	rsp++

	gen_pixel(mut curr_color, .push)
	write_pixel(mut out, curr_color)
	rsp++

	gen_pixel(mut curr_color, .outn)
	write_pixel(mut out, curr_color)
	rsp++

	black := gx.rgb(0, 0, 0)
	write_pixel(mut out, black)
	rsp++
	write_pixel(mut out, black)
	rsp++
	write_pixel(mut out, curr_color)
	rsp++
	write_pixel(mut out, curr_color)
	rsp++
	write_pixel(mut out, black)
	rsp++

	write_pixel(mut out, black)
	rsp++

	write_pixel(mut out, black)
	rsp++

	write_pixel(mut out, black)
	rsp++

	write_pixel(mut out, black)
	rsp++


	for  i := 0; i < (width * height - rsp); i++ {
		write_pixel(mut out, gx.rgb(255, 255, 255))
	}
}