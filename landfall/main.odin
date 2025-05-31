package landfall

//TODO setup draw tooling
//TODO show mouse position in debug overlay

import "base:runtime"
import "core:log"
import "core:mem"
import sdl "vendor:sdl3"
import image "vendor:sdl3/image"


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

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		if len(track.allocation_map) > 0 {
			log.error("LANDFALL | **%v allocations not freed: **\n", len(track.allocation_map))
			for _, entry in track.allocation_map {
				log.error("- %v bytes @ %v\n", entry.size, entry.location)
			}
		}
		if len(track.bad_free_array) > 0 {
			log.error("LANDFALL | ** %v incorrect frees: **\n", len(track.bad_free_array))
			for entry in track.bad_free_array {
				log.error("- %p @ %v\n", entry.memory, entry.location)
			}
		}
		mem.tracking_allocator_destroy(&track)
	}

	SDL_INIT_FLAGS :: sdl.INIT_VIDEO
	if (sdl.Init(SDL_INIT_FLAGS)) == false {
		log.error("LANDFALL | SDL_Init failed: {}", sdl.GetError())
		return
	}

	defer sdl.Quit()

	window_flags: sdl.WindowFlags
	window_flags += {.RESIZABLE}
	window: ^sdl.Window = sdl.CreateWindow("ODIN SIMPLE RTS WITH SDL3", 1280, 720, window_flags)
	defer sdl.DestroyWindow(window)
	if window == nil {
		log.error("LANDFALL | SDL_CreateWindow failed: {}", sdl.GetError())
		return
	}

	renderer: ^sdl.Renderer = sdl.CreateRenderer(window, nil)
	defer sdl.DestroyRenderer(renderer)
	if renderer == nil {
		log.error("LANDFALL | SDL_CreateRenderer failed: {}", sdl.GetError())
		return
	}

	atlas_surface: ^sdl.Surface = image.LoadPNG_IO(sdl.IOFromFile("assets/atlas.png", "r"))
	defer sdl.DestroySurface(atlas_surface)
	if atlas_surface == nil {
		log.error("LANDFALL | SDL_CreateTextureFromSurface failed: {}", sdl.GetError())
		return
	}

	atlas_texture: ^sdl.Texture = sdl.CreateTextureFromSurface(renderer, atlas_surface)
	if atlas_texture == nil {
		log.error("LANDFALL | SDL_CreateTextureFromSurface failed: {}", sdl.GetError())
		return
	}
	defer sdl.DestroyTexture(atlas_texture)

	sdl.SetTextureScaleMode(atlas_texture, .NEAREST) // pixel perfect

	TARGET_FPS: u64 : 60
	TARGET_FRAME_TIME: u64 : 1000 / TARGET_FPS
	SCALE_FACTOR: f32 : 20.0

	entity_manager: EntityManager = entity_create_entity_manager()

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
		game_draw(renderer, atlas_texture, entity_manager)

		frame_time := sdl.GetTicks() - last_ticks
		if frame_time < TARGET_FRAME_TIME {
			sdl.Delay(u32(TARGET_FRAME_TIME - frame_time))
		}

		last_ticks = new_ticks
	}

	game_update :: proc(dt: f32) {

	}

	//TODO set pixel perfect snap or something
	game_draw :: proc(
		renderer: ^sdl.Renderer,
		atlas_texture: ^sdl.Texture,
		entity_manager: EntityManager,
	) {
		sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255) //black
		sdl.RenderClear(renderer)


		//TODO is batch rendering enabled?
		for _ in entity_manager.entities {
			//TODO draw entity corredct instead of just the atlas

			source : Maybe(^sdl.FRect) = &sdl.FRect{
				x = 0,
				y = 0,
				w = 16 ,
				h = 16 ,
			}

			destination : Maybe(^sdl.FRect) = &sdl.FRect{
				x = 0,
				y = 0,
				w = 16 * SCALE_FACTOR,
				h = 16 * SCALE_FACTOR,
			}

			sdl.RenderTexture(
				renderer,
				atlas_texture,
				source,
				destination,
			)

			sdl.SetRenderDrawColor(renderer, 255, 255, 255, 255) //white
			sdl.RenderDebugText(
				renderer,
				210,
				210,
				"stuffffffff",
			)
			sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255) //black again

			sdl.RenderPresent(renderer)
		}
	}
}
