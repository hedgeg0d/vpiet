module main

import os
import gx

fn gen_header(mut file os.File, width u32, height u32) {
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

enum Direction {
	right
	down
	left
	up
}


fn min(a int, b int) int {
	return if a < b { a } else { b }
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

struct CompCtx {
	debug		bool
	width		u32
	height		u32
mut:
	out			os.File
	curr_color	gx.Color
	fcounter	u32
	lx			u32
	ly			u32
	dir			Direction
	code		[][]gx.Color
}

fn (mut c CompCtx) dmesg(str string) {
	if !c.debug {return}
	println("Debug: ${str}")
}

fn (mut c CompCtx) write_header() {
	c.out.write_string('P3\n#generated\n${c.width} ${c.height}\n255\n') or {panic(err)}
	//write_pixel(mut c.out, start_color)
	//c.fcounter++
	c.dmesg("header created")
}

fn (mut c CompCtx) update_direction() {
	layer := min(min(c.lx, c.width - 1 - c.lx), min(c.ly, c.height - 1 - c.ly))
	layer_width := c.width - 2 * layer
	layer_height := c.height - 2 * layer
	local_x := c.lx - layer
	local_y := c.ly - layer

	if local_y == 0 && local_x < layer_width - 1 {
		c.dir = .right
	} else if local_x == layer_width - 1 && local_y < layer_height - 1 {
		c.dir = .down
	} else if local_y == layer_height - 1 && local_x > 0 {
		c.dir = .left
	} else if local_x == 0 && local_y > 1 {
		c.dir = .up
	} else {
		// Этот случай возникает, когда мы завершаем внутренний слой
		// и должны начать новый слой, двигаясь вправо
		c.dir = .right
	}
}

fn (mut c CompCtx) gen_pixel(f Funcs) {
	mut hue, mut brightness := rgb_to_params(c.curr_color)
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
	}
	c.curr_color = get_color(hue % 6, brightness % 3)
}

fn (mut c CompCtx) invoke(f Funcs) {
	//gen_pixel(mut c.curr_color, f)
	//write_pixel(mut c.out, c.curr_color)
	c.update_direction()
	match c.dir {
		.right	{c.lx++}
		.left	{c.lx--}
		.up		{c.ly--}
		.down	{c.ly++}
	}
	c.gen_pixel(f)
	c.code[c.ly][c.lx] = c.curr_color
	c.fcounter++
	c.dmesg("${f} invoked")
}

fn (mut c CompCtx) fill() {
	for i := 0; i < (c.width * c.height - c.fcounter); i++ {
		write_pixel(mut c.out, gx.rgb(255, 255, 255))
	}
	c.dmesg("filled ${c.width * c.height - c.fcounter} empty pixels")
}

fn (mut c CompCtx) init() {
	println("${c.width} ${c.height}")
	c.write_header()
	for _ in 0 .. c.height {
		c.code << []gx.Color{init: gx.rgb(255, 255, 255), len: int(c.width)}
	}
	c.code[0][0] = start_color
}

fn (mut c CompCtx) end() {
	for i in 0 .. c.height {
		for j in 0 .. c.width {
			c.out.write_string('${c.code[i][j].r} ${c.code[i][j].g} ${c.code[i][j].b}   ') or {panic(err)}
		}
		c.out.write_string('\n') or {panic(err)}
	}
}

const width  = 6
const height = 6
const start_color = gx.rgb(255, 192, 192)

fn main() {
	mut c := CompCtx {
		width:		width
		height:		height
		debug:		true
		out:		os.create("main.ppm") or {panic(err)}
		curr_color: start_color
	}

	c.init()
	// some test invokes
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.push)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.add)
	c.invoke(.push)
	c.end()
}