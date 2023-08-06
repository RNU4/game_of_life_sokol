import time
import rand
import sokol
import sokol.sapp
import sokol.gfx
import sokol.sgl
struct Grid {
mut:
	current        [][]int
	next           [][]int
	check_neighbor [][]int
	width          int
	height         int
	pause bool
	mouse_pressed int
	mouse_last_pressed_key sapp.MouseButton
	mouse_x f32
	mouse_y f32
}

struct AppState {
	pass_action C.sg_pass_action
	grid        Grid
}

const (
	used_import = sokol.used_import
)

fn (mut grid Grid) neighbors(x, y int) int {
	mut neighbors_count := 0
	//Warps
	for _, element in grid.check_neighbor {
		mut xx := x + element[0]
		mut yy := y + element[1]
		if xx < 0 {
			xx = grid.width - 1
		} else if xx > grid.width - 1 {
			xx = 0
		}
		if yy < 0 {
			yy = grid.height - 1
		} else if yy > grid.height - 1 {
			yy = 0
		}

		if grid.current[xx][yy] == 1 {
			neighbors_count++
		}
	}
	return neighbors_count
}

fn (mut grid Grid) cell(x, y int) {
	neighbors_count := grid.neighbors(x, y)
	if grid.current[x][y] == 0 {
		if neighbors_count == 3 {
			// life is born
			grid.next[x][y] = 1
		}
	} else {
		if neighbors_count < 2 || neighbors_count > 3 {
			// underpopulation & overpopulation
			grid.next[x][y] = 0
		} else {
			grid.next[x][y] = 1
		}
	}
}

fn (mut grid Grid) simulation() {
	for x := 0; x < grid.width; x++ {
		for y := 0; y < grid.height; y++ {
			grid.cell(x, y)
		}
	}
}

fn create_grid(mut grid Grid) {
	//Height
	grid.height = sapp.height() / 8
	//Width
	grid.width = sapp.width() / 8
	//Neighbor positions to check
	grid.check_neighbor = [[1, 0], [0, 1], [1, 1], [-1, 1], [1, -1], [-1, -1], [0, -1], [-1,0]]

	//Create the 2d grid
	for i:=0; i <= grid.width; i++{
		grid.next << [0].repeat(grid.height)
		grid.current << [0].repeat(grid.height)
	}

	//Create a seed from time.ticks for a new seed every time
	//time.ticks returns number of ticks since the computer was started
	rand.seed(int(time.ticks()))

	//Create Random Noise by iterating through grid
	for x := 0; x < grid.width; x++ {
		for y := 0; y < grid.height; y++ {
			//populate grid with numbers from 1 to 0
			//grid.current[x][y] = rand.next(2)
		}
	}
}

fn init(user_data voidptr) {
	desc := C.sg_desc{
		mtl_device: sapp.metal_get_device()
		mtl_renderpass_descriptor_cb: sapp.metal_get_renderpass_descriptor
		mtl_drawable_cb: sapp.metal_get_drawable
		d3d11_device: sapp.d3d11_get_device()
		d3d11_device_context: sapp.d3d11_get_device_context()
		d3d11_render_target_view_cb: sapp.d3d11_get_render_target_view
		d3d11_depth_stencil_view_cb: sapp.d3d11_get_depth_stencil_view
	}
	//Get Data from user_data
	mut state := &AppState(user_data)
	//Create grid
	create_grid(mut &state.grid)

	//sokol setup
	gfx.setup(&desc)
	sgl_desc := C.sgl_desc_t{}
	sgl.setup(&C.sgl_desc)
}

fn frame(user_data voidptr) {
	
	// Get Data from user_data
	mut state := &AppState(user_data)

	//Run simulation and draw the result
	draw(mut &state.grid)

	//sokol drawing
	gfx.begin_default_pass(&state.pass_action, sapp.width(), sapp.height())
	sgl.draw()
	gfx.end_pass()
	gfx.commit()
}

fn draw_filled_rect(x, y, w, h f32) {
	sgl.begin_quads()
	sgl.v2f(x, y)
	sgl.v2f(x + w, y)
	sgl.v2f(x + w, y + h)
	sgl.v2f(x, y + h)
	sgl.end()
}
fn draw_hollow_rect(x, y, w, h f32) {
	sgl.begin_line_strip()
	sgl.v2f(x, y)
	sgl.v2f(x + w, y)
	sgl.v2f(x + w, y + h)
	sgl.v2f(x, y + h)
	sgl.v2f(x, y)
	sgl.end()
}
fn draw(mut grid Grid) {
	// first, reset and setup ortho projection
	sgl.defaults()
	sgl.matrix_mode_projection()
	//Create view
	sgl.ortho(0.0, f32(sapp.width()), f32(sapp.height()), 0.0, -1.0, 1.0)
	//Limits fps to varible
	if grid.pause==false{
	fps:=20
	time.sleep_ms(1000/fps)
	
	grid.simulation()}
	for x := 0; x < grid.width; x++ {
		for y := 0; y < grid.height; y++ {
			if grid.current[x][y] == 1 {
				//color
				sgl.c3b(255, 255, 255)
				draw_filled_rect(x * 8, y * 8, 8, 8)
			}
			if grid.pause==false{
				//Set grid to the updated grid
				grid.current[x][y] = grid.next[x][y]
				//Reset the updated grid
				//grid.next[x][y] = 0
			}
		}
	}
	draw_hollow_rect(int(grid.mouse_x)/8*8,int(grid.mouse_y)/8*8,8,8)
	
}

fn handle_input(mut grid Grid,ev &C.sapp_event){

	grid.mouse_x=ev.mouse_x
	grid.mouse_y=ev.mouse_y
	if ev.mouse_button == sapp.MouseButton.left{
		grid.mouse_last_pressed_key=ev.mouse_button
		if grid.mouse_pressed==0{
		grid.mouse_pressed++
		}else if grid.mouse_pressed==1{
		grid.mouse_pressed=0	
		}
		
	}else if ev.mouse_button == sapp.MouseButton.right{
		grid.mouse_last_pressed_key=ev.mouse_button
		if grid.mouse_pressed==0{
		grid.mouse_pressed++
		}else if grid.mouse_pressed==1{
		grid.mouse_pressed=0	
		}
	}
	
	if grid.mouse_pressed==1 && grid.mouse_last_pressed_key==sapp.MouseButton.left{
		grid.current[int(ev.mouse_x)/8][int(ev.mouse_y)/8]=1
	}
	if grid.mouse_pressed==1 && grid.mouse_last_pressed_key==sapp.MouseButton.right{
		grid.current[int(ev.mouse_x)/8][int(ev.mouse_y)/8]=0
	}
	if ev.char_code==112{ //p
		grid.pause=!grid.pause
	}
}

fn input(ev &C.sapp_event) {
	mut state := &AppState(sapp.userdata())
	handle_input(mut &state.grid,ev)
}
fn main() {
	mut grid := Grid{}
	mut state := &AppState{
		pass_action: gfx.create_clear_pass(0.1, 0.1, 0.1, 1.0)
		grid: grid
	}
	title := 'Game Of Life'
	desc := C.sapp_desc{
		user_data: state
		init_userdata_cb: init
		frame_userdata_cb: frame
		window_title: title.str
		event_cb: input
		html5_canvas_name: title.str
	}
	sapp.run(&desc)
}
