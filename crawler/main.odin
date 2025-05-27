package crawler

//TODO show atlas
//TODO setup draw with tooling
//TODO setup spall

import "base:runtime"
import "core:log" //TODO remove me and use debug
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
	log.logf(level, "SDL {}: {}", category, message) //TODO remove me and use debug
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
	window: ^sdl.Window = sdl.CreateWindow("Exterminate", 1280, 720, window_flags)
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


	//last_ticks := sdl.GetTicks()

	game_loop: for {

	//	new_ticks := sdl.GetTicks()
	//	delta_time := f32(new_ticks - last_ticks) / 1000
	//	last_ticks = new_ticks

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

		// update game state
		// draw
		sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255)
		sdl.RenderClear(renderer)
		sdl.RenderPresent(renderer)
		sdl.Delay(16) // ~60 FPS

	}
}
