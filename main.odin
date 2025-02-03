#+feature dynamic-literals

package first

import "core:fmt"
import "core:unicode/utf8"
import "core:mem"
// import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"
import mu "vendor:microui"

Entity :: struct {
	position: rl.Vector2,
 	rotation: f32,

 	derived: any,
}

Player :: struct {
	using entity: Entity,

	moveSpeed: f32,
}

ConveyorDirection :: enum {
	N = 1,
	E = 2,
	S = 4,
	W = 8,
	OUT = 16,
}

Conveyor :: struct {
	position: MapPosition,
	from : ConveyorDirection,
	to : ConveyorDirection,
}

ConveyorFrame :: struct {
	sourcePosition : rl.Vector2,
}

conveyorAnimation1 : [8]ConveyorFrame = {
	ConveyorFrame{sourcePosition = rl.Vector2{0, 0}},
	ConveyorFrame{sourcePosition = rl.Vector2{64, 0}},
	ConveyorFrame{sourcePosition = rl.Vector2{32, 16}},
	ConveyorFrame{sourcePosition = rl.Vector2{0, 32}},
	ConveyorFrame{sourcePosition = rl.Vector2{48, 32}},
	ConveyorFrame{sourcePosition = rl.Vector2{16, 48}},
	ConveyorFrame{sourcePosition = rl.Vector2{64, 48}},
	ConveyorFrame{sourcePosition = rl.Vector2{32, 64}},
}
conveyorAnimation2 : [8]ConveyorFrame = {
	ConveyorFrame{sourcePosition = rl.Vector2{16, 0}},
	ConveyorFrame{sourcePosition = rl.Vector2{0, 16}},
	ConveyorFrame{sourcePosition = rl.Vector2{48, 16}},
	ConveyorFrame{sourcePosition = rl.Vector2{16, 32}},
	ConveyorFrame{sourcePosition = rl.Vector2{64, 32}},
	ConveyorFrame{sourcePosition = rl.Vector2{32, 48}},
	ConveyorFrame{sourcePosition = rl.Vector2{0, 64}},
	ConveyorFrame{sourcePosition = rl.Vector2{48, 64}},
}

ConveyorPiece :: struct {
	frames : ^[8]ConveyorFrame,
	rotation : f32,
	flipX : bool,
	flipY : bool,
}

ConveyorPieceSize : i32 : 32 

conveyorPieces : map[int]ConveyorPiece = {
	int(ConveyorDirection.S | ConveyorDirection.E * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation1,
		rotation = 0,
		flipX = false,
		flipY = false,
	},
	int(ConveyorDirection.S | ConveyorDirection.N * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation2,
		rotation = -90,
		flipX = false,
		flipY = false,
	},
	int(ConveyorDirection.S | ConveyorDirection.W * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation1,
		rotation = 0,
		flipX = true,
		flipY = false,
	},
	int(ConveyorDirection.W | ConveyorDirection.S * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation1,
		rotation = 90,
		flipX = false,
		flipY = false,
	},
	int(ConveyorDirection.W | ConveyorDirection.E * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation2,
		rotation = 0,
		flipX = false,
		flipY = false,
	},
	int(ConveyorDirection.W | ConveyorDirection.N * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation1,
		rotation = -90,
		flipX = false,
		flipY = true,
	},

	int(ConveyorDirection.N | ConveyorDirection.W * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation1,
		rotation = 0,
		flipX = true,
		flipY = true,
	},
	int(ConveyorDirection.N | ConveyorDirection.S * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation2,
		rotation = 90,
		flipX = false,
		flipY = false,
	},
	int(ConveyorDirection.N | ConveyorDirection.E * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation1,
		rotation = 0,
		flipX = false,
		flipY = true,
	},
	int(ConveyorDirection.E | ConveyorDirection.N * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation1,
		rotation = -90,
		flipX = false,
		flipY = false,
	},
	int(ConveyorDirection.E | ConveyorDirection.W * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation2,
		rotation = 0,
		flipX = true,
		flipY = false,
	},
	int(ConveyorDirection.E | ConveyorDirection.S * ConveyorDirection.OUT) = ConveyorPiece{
		frames = &conveyorAnimation1,
		rotation = -90,
		flipX = true,
		flipY = false,
	},
}

player_update :: proc(entity: ^Player, deltaTime: f32) {
	deltaX : f32 = 0.0
	deltaY : f32 = 0.0

	if rl.IsKeyDown(rl.KeyboardKey.A) {
		deltaX -= 1.0
	}
	if rl.IsKeyDown(rl.KeyboardKey.D) {
		deltaX += 1.0
	}
	if rl.IsKeyDown(rl.KeyboardKey.W) {
		deltaY -= 1.0
	}
	if rl.IsKeyDown(rl.KeyboardKey.S) {
		deltaY += 1.0
	}

	entity.position.x += deltaX * deltaTime * entity.moveSpeed
	entity.position.y += deltaY * deltaTime * entity.moveSpeed
}

// new_entity :: proc($T: typeid) -> ^Entity {
// 	t := new(T)
// 	t.derived = t^
// 	return t
// }

MapPosition :: struct {
	x: i32,
	y: i32,
}

uiState := struct {
	muContext: mu.Context,
	log_buf: [1<<16]byte,
	log_buf_len: int,
	log_buf_updated: bool,
	bg: mu.Color,
	atlasTexture: rl.Texture2D,
}{
	bg = {90, 95, 100, 255},
}

orientation := ConveyorDirection.E

addConveyor :: proc(conveyorList: ^[dynamic]Conveyor, conveyorMap: ^map[MapPosition]^Conveyor, gridPositionX: i32, gridPositionY: i32) {
	hasConveyor := MapPosition{gridPositionX, gridPositionY} in conveyorMap
	if !hasConveyor {
		conveyorN := conveyorMap[MapPosition{gridPositionX, gridPositionY - 1}]
		conveyorE := conveyorMap[MapPosition{gridPositionX + 1, gridPositionY}]
		conveyorS := conveyorMap[MapPosition{gridPositionX, gridPositionY + 1}]
		conveyorW := conveyorMap[MapPosition{gridPositionX - 1, gridPositionY}]

		// conveyorArray : [4]^Conveyor = {conveyorN, conveyorE, conveyorS, conveyorW}

		fmt.println("North: ", conveyorN)
		fmt.println("East: ", conveyorE)
		fmt.println("South: ", conveyorS)
		fmt.println("West: ", conveyorW)

		conveyorFrom := ConveyorDirection.E
		conveyorTo := ConveyorDirection.W
		#partial switch(orientation){
			case .N:
				conveyorFrom = .S
				conveyorTo = .N
			case .E:
				conveyorFrom = .W
				conveyorTo = .E
			case .S:
				conveyorFrom = .N
				conveyorTo = .S
			case .W:
				conveyorFrom = .E
				conveyorTo = .W
		}

		append_elem(conveyorList, Conveyor {
			position = MapPosition{gridPositionX, gridPositionY},
			from = conveyorFrom,
			to = conveyorTo,
		})
	
		fmt.println("Inserted item: ", conveyorList[len(conveyorList) - 1])
		conveyorMap[MapPosition{gridPositionX, gridPositionY}] = &conveyorList[len(conveyorList) - 1]
	}
}

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	conveyorList : [dynamic]Conveyor
	defer delete_dynamic_array(conveyorList)
	// append(&conveyorList, Conveyor {
	// 	position = MapPosition{1.0, 1.0},
	// 	from = ConveyorDirection.S,
	// 	to = ConveyorDirection.N,
	// })

	// fmt.println("Test: ", conveyorList)

	conveyorMap : map[MapPosition]^Conveyor
	defer delete_map(conveyorMap)
	// conveyorMap[{1,1}] = nil
	// conveyorMap[{1,2}] = 5
	// conveyorMap[{1,3}] = 2
	// conveyorMap[{1,4}] = 5

	screenWidth :i32 = 1280
	screenHeight : i32 = 720

	player := Player {
		position = rl.Vector2 {50.0, 50.0},
		moveSpeed = 100.0,
	}
	player.derived = &player

	numFrames := 8
	currentFrame := 0
	framesCounter : f32 = 0.0
	framesSpeed : f32 = 60.0

	TILE_SIZE :: 16

	rl.InitWindow(screenWidth, screenHeight, "Conveyor")
	defer rl.CloseWindow()

	pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT)
	defer delete(pixels)

	for alpha, i in mu.default_atlas_alpha {
		pixels[i] = {0xff, 0xff, 0xff, alpha}
	}

	image := rl.Image{
		data = raw_data(pixels),
		width = mu.DEFAULT_ATLAS_WIDTH,
		height = mu.DEFAULT_ATLAS_HEIGHT,
		mipmaps = 1,
		format = .UNCOMPRESSED_R8G8B8A8,
	}
	uiState.atlasTexture = rl.LoadTextureFromImage(image)
	defer rl.UnloadTexture(uiState.atlasTexture)

	mu.init(&uiState.muContext)
	uiState.muContext.text_width = mu.default_atlas_text_width
	uiState.muContext.text_height = mu.default_atlas_text_height

	conveyorTexture := rl.LoadTexture("Conveyor.png")

	rl.SetWindowState({rl.ConfigFlag.WINDOW_RESIZABLE})

	// SetTargetFPS(60)

	camera := rl.Camera2D {
		target = rl.Vector2 {0, 0},
		zoom = 1,
	}

	for !rl.WindowShouldClose() {
		deltaTime := rl.GetFrameTime()

		framesCounter += deltaTime

		if framesCounter >= (60.0 / framesSpeed) {
			framesCounter -= (60.0 / framesSpeed)
			currentFrame += 1

			if currentFrame >= numFrames do currentFrame = 0
		}

		if uiState.muContext.focus_id == 0 {
			player_update(&player, deltaTime)

			if rl.IsKeyDown(rl.KeyboardKey.RIGHT) do framesSpeed += 5.0
			if rl.IsKeyDown(rl.KeyboardKey.LEFT) do framesSpeed -= 5.0
	
			if framesSpeed > 10000.0 do framesSpeed = 10000.0
			if framesSpeed < 30.0 do framesSpeed = 30.0

			if rl.IsKeyPressed(rl.KeyboardKey.R) {
				#partial switch orientation {
					case .N:
						orientation = .E
					case .E:
						orientation = .S
					case .S:
						orientation = .W
					case .W:
						orientation = .N
				}
			}
		}

		ballPosition := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

		{ // text input
			text_input: [512]byte = ---
			text_input_offset := 0
			for text_input_offset < len(text_input) {
				ch := rl.GetCharPressed()
				if ch == 0 {
					break
				}
				b, w := utf8.encode_rune(ch)
				copy(text_input[text_input_offset:], b[:w])
				text_input_offset += w
			}
			mu.input_text(&uiState.muContext, string(text_input[:text_input_offset]))
		}

		// mouse coordinates
		mousePos := [2]i32{rl.GetMouseX(), rl.GetMouseY()}
		mu.input_mouse_move(&uiState.muContext, mousePos.x, mousePos.y)
		mu.input_scroll(&uiState.muContext, 0, i32(rl.GetMouseWheelMove() * -30))

		// mouse buttons
		@static buttons_to_key := [?]struct{
			rl_button: rl.MouseButton,
			mu_button: mu.Mouse,
		}{
			{.LEFT, .LEFT},
			{.RIGHT, .RIGHT},
			{.MIDDLE, .MIDDLE},
		}
		for button in buttons_to_key {
			if rl.IsMouseButtonPressed(button.rl_button) { 
				mu.input_mouse_down(&uiState.muContext, mousePos.x, mousePos.y, button.mu_button)
			} else if rl.IsMouseButtonReleased(button.rl_button) { 
				mu.input_mouse_up(&uiState.muContext, mousePos.x, mousePos.y, button.mu_button)
			}
		}

		// keyboard
		@static keys_to_check := [?]struct{
			rl_key: rl.KeyboardKey,
			mu_key: mu.Key,
		}{
			{.LEFT_SHIFT,    .SHIFT},
			{.RIGHT_SHIFT,   .SHIFT},
			{.LEFT_CONTROL,  .CTRL},
			{.RIGHT_CONTROL, .CTRL},
			{.LEFT_ALT,      .ALT},
			{.RIGHT_ALT,     .ALT},
			{.ENTER,         .RETURN},
			{.KP_ENTER,      .RETURN},
			{.BACKSPACE,     .BACKSPACE},
		}
		for key in keys_to_check {
			if rl.IsKeyPressed(key.rl_key) {
				mu.input_key_down(&uiState.muContext, key.mu_key)
			} else if rl.IsKeyReleased(key.rl_key) {
				mu.input_key_up(&uiState.muContext, key.mu_key)
			}
		}

		mu.begin(&uiState.muContext)
		all_windows(&uiState.muContext)
		mu.end(&uiState.muContext)

		gridPositionX := i32(ballPosition.x / f32(ConveyorPieceSize))
		gridPositionY := i32(ballPosition.y / f32(ConveyorPieceSize))

		if uiState.muContext.hover_root == nil {
			if (rl.IsMouseButtonPressed(rl.MouseButton.LEFT)) {
				addConveyor(&conveyorList, &conveyorMap, gridPositionX, gridPositionY)
			}
		}

		builder := strings.builder_make()
		defer strings.builder_destroy(&builder)

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()
			rl.BeginMode2D(camera)
			defer rl.EndMode2D()

			currentScreenWidth := rl.GetScreenWidth()
			currentScreenHeight := rl.GetScreenHeight()

			rl.ClearBackground(rl.RAYWHITE)
			for y : i32 = 0; y < currentScreenHeight; y += TILE_SIZE {
				for x : i32 = 0; x < currentScreenWidth; x += TILE_SIZE {
					rl.DrawRectangle(x, y, TILE_SIZE, TILE_SIZE, rl.ColorFromNormalized(rl.Vector4 {f32(x) / f32(currentScreenWidth), f32(y) / f32(currentScreenHeight), 0, 1}))
				}
			}

			// draw conveyors
			for conveyor in conveyorList {
				conveyorInfo := conveyorPieces[int(conveyor.from | conveyor.to * ConveyorDirection.OUT)]
				rl.DrawTexturePro(
					conveyorTexture,
					rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)},
					rl.Rectangle{f32(conveyor.position.x * ConveyorPieceSize + ConveyorPieceSize / 2), f32(conveyor.position.y * ConveyorPieceSize + ConveyorPieceSize / 2), f32(ConveyorPieceSize), f32(ConveyorPieceSize)},
					rl.Vector2{f32(ConveyorPieceSize) / 2, f32(ConveyorPieceSize) / 2}, conveyorInfo.rotation, rl.WHITE)
			}
			// conveyorInfo := conveyorPieces[int(ConveyorDirection.W | ConveyorDirection.S * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 2, 64 * 1, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.W | ConveyorDirection.E * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 3, 64 * 1, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.W | ConveyorDirection.N * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 4, 64 * 1, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.S | ConveyorDirection.E * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 2, 64 * 2, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.S | ConveyorDirection.N * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 3, 64 * 2, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.S | ConveyorDirection.W * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 4, 64 * 2, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.E | ConveyorDirection.N * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 2, 64 * 3, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.E | ConveyorDirection.W * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 3, 64 * 3, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.E | ConveyorDirection.S * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 4, 64 * 3, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.N | ConveyorDirection.W * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 2, 64 * 4, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.N | ConveyorDirection.S * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 3, 64 * 4, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// conveyorInfo = conveyorPieces[int(ConveyorDirection.N | ConveyorDirection.E * ConveyorDirection.OUT)]
			// rl.DrawTexturePro(conveyorTexture, rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)}, rl.Rectangle{64 * 4, 64 * 4, 64, 64}, rl.Vector2{32, 32}, conveyorInfo.rotation, rl.WHITE)

			// draw player
			rl.DrawRectangle(i32(player.position.x), i32(player.position.y), 16, 16, rl.GREEN)

			if uiState.muContext.hover_root == nil {
				// rl.DrawCircleV(ballPosition, 20, rl.ColorAlpha(rl.MAROON, 0.5))
				conveyorFrom := ConveyorDirection.E
				conveyorTo := ConveyorDirection.W
				#partial switch(orientation){
					case .N:
						conveyorFrom = .S
						conveyorTo = .N
					case .E:
						conveyorFrom = .W
						conveyorTo = .E
					case .S:
						conveyorFrom = .N
						conveyorTo = .S
					case .W:
						conveyorFrom = .E
						conveyorTo = .W
				}
				conveyorInfo := conveyorPieces[int(conveyorFrom | conveyorTo * ConveyorDirection.OUT)]
				rl.DrawTexturePro(
					conveyorTexture,
					rl.Rectangle{conveyorInfo.frames[currentFrame].sourcePosition.x, conveyorInfo.frames[currentFrame].sourcePosition.y, 16 * (conveyorInfo.flipX ? -1 : 1), 16 * (conveyorInfo.flipY ? -1 : 1)},
					rl.Rectangle{f32(gridPositionX * ConveyorPieceSize + ConveyorPieceSize / 2), f32(gridPositionY * ConveyorPieceSize + ConveyorPieceSize / 2), f32(ConveyorPieceSize), f32(ConveyorPieceSize)},
					rl.Vector2{f32(ConveyorPieceSize) / 2, f32(ConveyorPieceSize) / 2}, conveyorInfo.rotation, rl.ColorAlpha(rl.WHITE, 0.5))

				rl.DrawRectangleLines(gridPositionX * ConveyorPieceSize, gridPositionY * ConveyorPieceSize, ConveyorPieceSize, ConveyorPieceSize, rl.RED)
			}

			render_windows(&uiState.muContext)

			rl.DrawText("Testing", 190, 200, 20, rl.LIGHTGRAY)

			fps := int(rl.GetFPS())

			strings.builder_reset(&builder)
			strings.write_string(&builder, "FPS: ")
			strings.write_int(&builder, fps)
			fpsString := strings.to_cstring(&builder)

			fpsStringLength := rl.MeasureText(fpsString, 20)
			rl.DrawText(fpsString, currentScreenWidth - fpsStringLength - 20, 20, 20, rl.WHITE)
		}
	}
}

render_windows :: proc(ctx: ^mu.Context) {
	render_texture :: proc(rect: mu.Rect, pos: [2]i32, color: mu.Color) {
		source := rl.Rectangle{
			f32(rect.x),
			f32(rect.y),
			f32(rect.w),
			f32(rect.h),
		}
		position := rl.Vector2{f32(pos.x), f32(pos.y)}
		
		rl.DrawTextureRec(uiState.atlasTexture, source, position, transmute(rl.Color)color)
	}
	
	rl.BeginScissorMode(0, 0, rl.GetScreenWidth(), rl.GetScreenHeight())
	defer rl.EndScissorMode()
	
	command_backing: ^mu.Command
	for variant in mu.next_command_iterator(ctx, &command_backing) {
		switch cmd in variant {
		case ^mu.Command_Text:
			pos := [2]i32{cmd.pos.x, cmd.pos.y}
			for ch in cmd.str do if ch&0xc0 != 0x80 {
				r := min(int(ch), 127)
				rect := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
				render_texture(rect, pos, cmd.color)
				pos.x += rect.w
			}
		case ^mu.Command_Rect:
			rl.DrawRectangle(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h, transmute(rl.Color)cmd.color)
		case ^mu.Command_Icon:
			rect := mu.default_atlas[cmd.id]
			x := cmd.rect.x + (cmd.rect.w - rect.w)/2
			y := cmd.rect.y + (cmd.rect.h - rect.h)/2
			render_texture(rect, {x, y}, cmd.color)
		case ^mu.Command_Clip:
			rl.EndScissorMode()
			rl.BeginScissorMode(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h)
		case ^mu.Command_Jump: 
			unreachable()
		}
	}
}


u8_slider :: proc(ctx: ^mu.Context, val: ^u8, lo, hi: u8) -> (res: mu.Result_Set) {
	mu.push_id(ctx, uintptr(val))
	
	@static tmp: mu.Real
	tmp = mu.Real(val^)
	res = mu.slider(ctx, &tmp, mu.Real(lo), mu.Real(hi), 0, "%.0f", {.ALIGN_CENTER})
	val^ = u8(tmp)
	mu.pop_id(ctx)
	return
}

write_log :: proc(str: string) {
	uiState.log_buf_len += copy(uiState.log_buf[uiState.log_buf_len:], str)
	uiState.log_buf_len += copy(uiState.log_buf[uiState.log_buf_len:], "\n")
	uiState.log_buf_updated = true
}

read_log :: proc() -> string {
	return string(uiState.log_buf[:uiState.log_buf_len])
}
reset_log :: proc() {
	uiState.log_buf_updated = true
	uiState.log_buf_len = 0
}


all_windows :: proc(ctx: ^mu.Context) {
	@static opts := mu.Options{.NO_CLOSE}
	
	if mu.window(ctx, "Demo Window", {40, 40, 300, 450}, opts) {
		if .ACTIVE in mu.header(ctx, "Window Info") {
			win := mu.get_current_container(ctx)
			mu.layout_row(ctx, {54, -1}, 0)
			mu.label(ctx, "Position:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))
			mu.label(ctx, "Size:")
			mu.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))
		}
		
		if .ACTIVE in mu.header(ctx, "Window Options") {
			mu.layout_row(ctx, {120, 120, 120}, 0)
			for opt in mu.Opt {
				state := opt in opts
				if .CHANGE in mu.checkbox(ctx, fmt.tprintf("%v", opt), &state)  {
					if state {
						opts += {opt}
					} else {
						opts -= {opt}
					}
				}
			}
		}
		
		if .ACTIVE in mu.header(ctx, "Test Buttons", {.EXPANDED}) {
			mu.layout_row(ctx, {86, -110, -1})
			mu.label(ctx, "Test buttons 1:")
			if .SUBMIT in mu.button(ctx, "Button 1") { write_log("Pressed button 1") }
			if .SUBMIT in mu.button(ctx, "Button 2") { write_log("Pressed button 2") }
			mu.label(ctx, "Test buttons 2:")
			if .SUBMIT in mu.button(ctx, "Button 3") { write_log("Pressed button 3") }
			if .SUBMIT in mu.button(ctx, "Button 4") { write_log("Pressed button 4") }
		}
		
		if .ACTIVE in mu.header(ctx, "Tree and Text", {.EXPANDED}) {
			mu.layout_row(ctx, {140, -1})
			mu.layout_begin_column(ctx)
			if .ACTIVE in mu.treenode(ctx, "Test 1") {
				if .ACTIVE in mu.treenode(ctx, "Test 1a") {
					mu.label(ctx, "Hello")
					mu.label(ctx, "world")
				}
				if .ACTIVE in mu.treenode(ctx, "Test 1b") {
					if .SUBMIT in mu.button(ctx, "Button 1") { write_log("Pressed button 1") }
					if .SUBMIT in mu.button(ctx, "Button 2") { write_log("Pressed button 2") }
				}
			}
			if .ACTIVE in mu.treenode(ctx, "Test 2") {
				mu.layout_row(ctx, {53, 53})
				if .SUBMIT in mu.button(ctx, "Button 3") { write_log("Pressed button 3") }
				if .SUBMIT in mu.button(ctx, "Button 4") { write_log("Pressed button 4") }
				if .SUBMIT in mu.button(ctx, "Button 5") { write_log("Pressed button 5") }
				if .SUBMIT in mu.button(ctx, "Button 6") { write_log("Pressed button 6") }
			}
			if .ACTIVE in mu.treenode(ctx, "Test 3") {
				@static checks := [3]bool{true, false, true}
				mu.checkbox(ctx, "Checkbox 1", &checks[0])
				mu.checkbox(ctx, "Checkbox 2", &checks[1])
				mu.checkbox(ctx, "Checkbox 3", &checks[2])
				
			}
			mu.layout_end_column(ctx)
			
			mu.layout_begin_column(ctx)
			mu.layout_row(ctx, {-1})
			mu.text(ctx, 
				"Lorem ipsum dolor sit amet, consectetur adipiscing "+
				"elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus "+
				"ipsum, eu varius magna felis a nulla.",
		        )
			mu.layout_end_column(ctx)
		}
		
		if .ACTIVE in mu.header(ctx, "Background Colour", {.EXPANDED}) {
			mu.layout_row(ctx, {-78, -1}, 68)
			mu.layout_begin_column(ctx)
			{
				mu.layout_row(ctx, {46, -1}, 0)
				mu.label(ctx, "Red:");   u8_slider(ctx, &uiState.bg.r, 0, 255)
				mu.label(ctx, "Green:"); u8_slider(ctx, &uiState.bg.g, 0, 255)
				mu.label(ctx, "Blue:");  u8_slider(ctx, &uiState.bg.b, 0, 255)
			}
			mu.layout_end_column(ctx)
			
			r := mu.layout_next(ctx)
			mu.draw_rect(ctx, r, uiState.bg)
			mu.draw_box(ctx, mu.expand_rect(r, 1), ctx.style.colors[.BORDER])
			mu.draw_control_text(ctx, fmt.tprintf("#%02x%02x%02x", uiState.bg.r, uiState.bg.g, uiState.bg.b), r, .TEXT, {.ALIGN_CENTER})
		}
	}
	
	if mu.window(ctx, "Log Window", {350, 40, 300, 200}, opts) {
		mu.layout_row(ctx, {-1}, -28)
		mu.begin_panel(ctx, "Log")
		mu.layout_row(ctx, {-1}, -1)
		mu.text(ctx, read_log())
		if uiState.log_buf_updated {
			panel := mu.get_current_container(ctx)
			panel.scroll.y = panel.content_size.y
			uiState.log_buf_updated = false
		}
		mu.end_panel(ctx)
		
		@static buf: [128]byte
		@static buf_len: int
		submitted := false
		mu.layout_row(ctx, {-70, -1})
		if .SUBMIT in mu.textbox(ctx, buf[:], &buf_len) {
			mu.set_focus(ctx, ctx.last_id)
			submitted = true
		}
		if .SUBMIT in mu.button(ctx, "Submit") {
			submitted = true
		}
		if submitted {
			write_log(string(buf[:buf_len]))
			buf_len = 0
		}
	}
	
	if mu.window(ctx, "Style Window", {350, 250, 300, 240}) {
		@static colors := [mu.Color_Type]string{
			.TEXT         = "text",
			.BORDER       = "border",
			.WINDOW_BG    = "window bg",
			.TITLE_BG     = "title bg",
			.TITLE_TEXT   = "title text",
			.PANEL_BG     = "panel bg",
			.BUTTON       = "button",
			.BUTTON_HOVER = "button hover",
			.BUTTON_FOCUS = "button focus",
			.BASE         = "base",
			.BASE_HOVER   = "base hover",
			.BASE_FOCUS   = "base focus",
			.SCROLL_BASE  = "scroll base",
			.SCROLL_THUMB = "scroll thumb",
			.SELECTION_BG = "selection bg",
		}
		
		sw := i32(f32(mu.get_current_container(ctx).body.w) * 0.14)
		mu.layout_row(ctx, {80, sw, sw, sw, sw, -1})
		for label, col in colors {
			mu.label(ctx, label)
			u8_slider(ctx, &ctx.style.colors[col].r, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].g, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].b, 0, 255)
			u8_slider(ctx, &ctx.style.colors[col].a, 0, 255)
			mu.draw_rect(ctx, mu.layout_next(ctx), ctx.style.colors[col])
		}
	}
}