package landfall

//TODO show atlas
//TODO setup draw with tooling
//TODO setup spall

import "base:runtime"
import "core:log"
import "core:mem"
import sdl "vendor:sdl3"


sdl_log :: proc "c" (
	userdata: rawptr,
	category: sdl.LogCategory,
	priority: sdl.LogPriority,
	message: cstring,
) {
	context = (cast(^runtime.Context)userdata)^
	level: log.Level
	switch priority {
	case .INVALID, .TRACE, .VERBOSE, .DEBUG:
		level = .Debug
	case .INFO:
		level = .Info
	case .WARN:
		level = .Warning
	case .ERROR:
		level = .Error
	case .CRITICAL:
		level = .Fatal
	}
	log.logf(level, "SDL {}: {}", category, message)
}

main :: proc() {
	context.logger = log.create_console_logger()
	log.debug("starting game")

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				log.error("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					log.error("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				log.error("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					log.error("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	SDL_INIT_FLAGS :: sdl.INIT_VIDEO
	if (sdl.Init(SDL_INIT_FLAGS)) == false {
		log.error("SDL_Init failed: {}", sdl.GetError())
		return
	}
	defer sdl.Quit()


	window_flags: sdl.WindowFlags
	window_flags += {.RESIZABLE}
	window: ^sdl.Window = sdl.CreateWindow("ODIN ASCII CRAWLER WITH SDL3", 1280, 720, window_flags)
	defer sdl.DestroyWindow(window)
	if window == nil {
		log.error("SDL_CreateWindow failed: {}", sdl.GetError())
		return
	}

	s: cstring : "SDL_CreateRenderer"
	renderer: ^sdl.Renderer = sdl.CreateRenderer(window, nil)
	defer sdl.DestroyRenderer(renderer)
	if renderer == nil {
		log.error("SDL_CreateRenderer failed: {}", sdl.GetError())
		return
	}

	TARGET_FPS: u64 : 60
	TARGET_FRAME_TIME: u64 : 1000 / TARGET_FPS

	last_ticks := sdl.GetTicks()

	game_loop: for {

		// process events
		ev: sdl.Event
		for sdl.PollEvent(&ev) {

			#partial switch ev.type {
			case .QUIT:
				break game_loop
			case .KEY_DOWN:
				if ev.key.scancode == .ESCAPE do break game_loop
			}
		}

		new_ticks := sdl.GetTicks()
		dt: f32 = f32(new_ticks - last_ticks) / 1000

		game_update(dt)
		game_draw(renderer)


		frame_time := sdl.GetTicks() - last_ticks
		if frame_time < TARGET_FRAME_TIME {
			sdl.Delay(u32(TARGET_FRAME_TIME - frame_time))
		}

		last_ticks = new_ticks
	}

	game_update :: proc(dt: f32) {

	}

	game_draw :: proc(renderer: ^sdl.Renderer) {
		sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255)
		sdl.RenderClear(renderer)


		sdl.RenderPresent(renderer)
	}
}
