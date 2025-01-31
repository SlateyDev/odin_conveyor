package first

import "core:fmt"
import "core:mem"
// import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

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
	N,
	E,
	S,
	W,
}

Conveyor :: struct {
	position: MapPosition,
	from : ConveyorDirection,
	to : ConveyorDirection,
}

ConveyorFrame :: struct {
	sourcePosition : rl.Vector2,
}

verticalConveyor : [8]ConveyorFrame = {
	ConveyorFrame {sourcePosition = rl.Vector2{32, 0}},
	ConveyorFrame {sourcePosition = rl.Vector2{16, 16}},
	ConveyorFrame {sourcePosition = rl.Vector2{64, 16}},
	ConveyorFrame {sourcePosition = rl.Vector2{32, 32}},
	ConveyorFrame {sourcePosition = rl.Vector2{0, 48}},
	ConveyorFrame {sourcePosition = rl.Vector2{48, 48}},
	ConveyorFrame {sourcePosition = rl.Vector2{16, 64}},
	ConveyorFrame {sourcePosition = rl.Vector2{64, 64}},
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
			fmt.println("Frame")
			framesCounter -= (60.0 / framesSpeed)
			currentFrame += 1

			if currentFrame >= numFrames do currentFrame = 0
		}

		if (rl.IsKeyDown(rl.KeyboardKey.RIGHT)) do framesSpeed += 5.0
		if (rl.IsKeyDown(rl.KeyboardKey.LEFT)) do framesSpeed -= 5.0

		if (framesSpeed > 10000.0) do framesSpeed = 10000.0
		if (framesSpeed < 30.0) do framesSpeed = 30.0

		player_update(&player, deltaTime)

		ballPosition := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

		gridPositionX := i32(ballPosition.x / 16)
		gridPositionY := i32(ballPosition.y / 16)
		// fmt.printfln("Grid Position: (%d, %d, %d)", gridPositionX, gridPositionY, conveyorMap[MapPosition{gridPositionX, gridPositionY}])
		// fmt.printfln("Exists %t", MapPosition{gridPositionX, gridPositionY} in conveyorMap)

		if (rl.IsMouseButtonPressed(rl.MouseButton.LEFT)) {
			append(&conveyorList, Conveyor {
				position = MapPosition{gridPositionX, gridPositionY},
				from = ConveyorDirection.S,
				to = ConveyorDirection.N,
			})
		
			fmt.printf("Inserted item: ", conveyorList[len(&conveyorList) - 1])
			conveyorMap[MapPosition{gridPositionX, gridPositionY}] = &conveyorList[len(&conveyorList) - 1]
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

			for conveyor in conveyorList {
				rl.DrawTextureRec(conveyorTexture, rl.Rectangle{verticalConveyor[currentFrame].sourcePosition.x, verticalConveyor[currentFrame].sourcePosition.y, 16, 16}, rl.Vector2{f32(conveyor.position.x), f32(conveyor.position.y)} * 16, rl.WHITE)
			}
			rl.DrawTexturePro(conveyorTexture, rl.Rectangle{verticalConveyor[currentFrame].sourcePosition.x, verticalConveyor[currentFrame].sourcePosition.y, 16, 16}, rl.Rectangle{128, 128, 64, 64}, rl.Vector2{32, 32}, 0, rl.WHITE)

			rl.DrawCircleV(ballPosition, 20, rl.ColorAlpha(rl.MAROON, 0.5))
			rl.DrawRectangle(i32(player.position.x), i32(player.position.y), 16, 16, rl.GREEN)

			rl.DrawRectangleLines(gridPositionX * 16, gridPositionY * 16, 16, 16, rl.RED)

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
