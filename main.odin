package first

import "core:fmt"
import "core:mem"
import "core:math/rand"
import "core:strings"
import "vendor:raylib"

// Vector2 :: distinct [2]f32
// Vector3 :: distinct [3]f32
// Vector4 :: distinct [4]f32
// Quaternion :: distinct quaternion128

Entity :: struct {
// 	id: u64,
// 	name: string,
	position: raylib.Vector2,
 	rotation: f32,

 	derived: any,
}

// Frog :: struct {
// 	using entity: Entity,
// 	jump_height: f32,
// 	poisonous: bool,
// }

// Monster :: struct {
// 	using entity: Entity,
// 	attack_type: int,
// }

Player :: struct {
	using entity: Entity,

	moveSpeed: f32,
}

ConveyorFrame :: struct {
	sourcePosition : raylib.Vector2,
}

verticalConveyor : [8]ConveyorFrame = {
	ConveyorFrame {sourcePosition = raylib.Vector2{32, 0}},
	ConveyorFrame {sourcePosition = raylib.Vector2{16, 16}},
	ConveyorFrame {sourcePosition = raylib.Vector2{64, 16}},
	ConveyorFrame {sourcePosition = raylib.Vector2{32, 32}},
	ConveyorFrame {sourcePosition = raylib.Vector2{0, 48}},
	ConveyorFrame {sourcePosition = raylib.Vector2{48, 48}},
	ConveyorFrame {sourcePosition = raylib.Vector2{16, 64}},
	ConveyorFrame {sourcePosition = raylib.Vector2{64, 64}},
}

player_update :: proc(entity: ^Player, deltaTime: f32) {
	deltaX : f32 = 0.0
	deltaY : f32 = 0.0

	if raylib.IsKeyDown(raylib.KeyboardKey.A) {
		deltaX -= 1.0
	}
	if raylib.IsKeyDown(raylib.KeyboardKey.D) {
		deltaX += 1.0
	}
	if raylib.IsKeyDown(raylib.KeyboardKey.W) {
		deltaY -= 1.0
	}
	if raylib.IsKeyDown(raylib.KeyboardKey.S) {
		deltaY += 1.0
	}

	entity.position.x += deltaX * deltaTime * entity.moveSpeed
	entity.position.y += deltaY * deltaTime * entity.moveSpeed
}

// update_entity :: proc(entity: ^Entity) {
// 	entity.position.x += 1
// 	entity.position.y += 1
// 	entity.position.z += 1
// }

// new_entity :: proc($T: typeid) -> ^Entity {
// 	t := new(T)
// 	t.derived = t^

// 	switch &e in t.derived {
// 		case Frog:
// 			e.jump_height = 10.0
// 		case Monster:
// 			e.attack_type = rand.int_max(10)
// 	}
// 	return t
// }

// vec3_cross :: proc(a, b: Vector3) -> Vector3 {
// 	return (a.yzx * b.zxy) - (a.zxy * b.yzx)
// }

// vec2_cross :: proc(a, b: Vector2) -> Vector2 {
// 	return (a.x * b.y) - (a.y * b.x)
// }

// cross :: proc {vec3_cross, vec2_cross}

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

	using raylib

	screenWidth :i32 = 1280
	screenHeight : i32 = 720

	player := Player {
		position = Vector2 {50.0, 50.0},
		moveSpeed = 100.0,
	}
	player.derived = &player

	numFrames := 8
	currentFrame := 0
	framesCounter : f32 = 0.0
	framesSpeed : f32 = 60.0

	TILE_SIZE :: 16

	InitWindow(screenWidth, screenHeight, "Conveyor")
	defer CloseWindow()

	conveyorTexture := LoadTexture("Conveyor.png")

	SetWindowState({ConfigFlag.WINDOW_RESIZABLE})

	// SetTargetFPS(60)

	camera := Camera2D {
		target = Vector2 {0, 0},
		zoom = 1,
	}

	for !WindowShouldClose() {
		deltaTime := GetFrameTime()

		framesCounter += deltaTime

		if framesCounter >= (60.0 / framesSpeed) {
			fmt.println("Frame")
			framesCounter -= (60.0 / framesSpeed)
			currentFrame += 1

			if currentFrame >= numFrames do currentFrame = 0
		}

		if (IsKeyDown(KeyboardKey.RIGHT)) do framesSpeed += 5.0
		if (IsKeyDown(KeyboardKey.LEFT)) do framesSpeed -= 5.0

		if (framesSpeed > 10000.0) do framesSpeed = 10000.0
		if (framesSpeed < 30.0) do framesSpeed = 30.0

		player_update(&player, deltaTime)

		ballPosition := GetScreenToWorld2D(GetMousePosition(), camera)

		builder := strings.builder_make()
		defer strings.builder_destroy(&builder)

		{
			BeginDrawing()
			defer EndDrawing()
			BeginMode2D(camera)
			defer EndMode2D()

			ClearBackground(RAYWHITE)
			for y : i32 = 0; y < GetScreenHeight(); y += TILE_SIZE {
				for x : i32 = 0; x < GetScreenWidth(); x += TILE_SIZE {
					DrawRectangle(x, y, TILE_SIZE, TILE_SIZE, ColorFromNormalized(Vector4 {f32(y) / f32(GetScreenHeight()), f32(x) / f32(GetScreenWidth()), 0, 1}))
				}
			}
			DrawCircleV(ballPosition, 40, MAROON)
			DrawRectangle(i32(player.position.x), i32(player.position.y), 16, 16, GREEN)
			DrawText("Testing", 190, 200, 20, LIGHTGRAY)
			fps := int(GetFPS());

			strings.builder_reset(&builder)
			strings.write_string(&builder, "FPS: ")
			strings.write_int(&builder, fps)
			fpsString := strings.to_cstring(&builder)

			fpsStringLength := MeasureText(fpsString, 20)
			DrawText(fpsString, GetScreenWidth() - fpsStringLength - 20, 20, 20, WHITE)

			DrawTextureRec(conveyorTexture, Rectangle{verticalConveyor[currentFrame].sourcePosition.x, verticalConveyor[currentFrame].sourcePosition.y, 16, 16}, Vector2{16, 16}, WHITE)
			DrawTexturePro(conveyorTexture, Rectangle{verticalConveyor[currentFrame].sourcePosition.x, verticalConveyor[currentFrame].sourcePosition.y, 16, 16}, Rectangle{128, 128, 64, 64}, Vector2{32, 32}, 0, WHITE)
		}
	}

	// fmt.println("Hello ODIN!")

	// array := [?]int{1, 2, 3}

	// list: [dynamic]int
	// defer delete(list)
	// append(&list, 1, 2, 3)
	// append(&list, ..array[:])

	// fmt.println(list)

	// frog := new_entity(Frog)
	// defer free(frog)

	// monster := new_entity(Monster)
	// defer free(monster)

	// update_entity(frog)
	// update_entity(frog)

	// fmt.println(frog.derived)

	// frog.position *= frog.position

	// fmt.println(frog.derived)


	// switch e in frog.derived {
	// 	case Frog:
	// 		fmt.println("Ribbit")
	// 	case Monster:
	// 		fmt.println("I'm a monster using {}", e.attack_type)
	// }

	// switch e in monster.derived {
	// 	case Frog:
	// 		fmt.println("Ribbit")
	// 	case Monster:
	// 		fmt.printfln("I'm a monster using %i attack type", e.attack_type)
	// }

	// val: int = ---

	// fmt.println(val)

	// vec2a : Vector2 = {5, 6}
	// vec2b : Vector2 = {1, 2}

	// vec3a : Vector3 = {2, 3, 4}
	// vec3b : Vector3 = {1, 2, 3}

	// fmt.println("Vector2 Test")
	// fmt.println("a:", vec2a)
	// fmt.println("b:", vec2b)
	// fmt.println("a x b:", cross(vec2a, vec2b))
	// fmt.println("a.b:", vec2a * vec2b)

	// fmt.println("Vector3 Test")
	// fmt.println("a:", vec3a)
	// fmt.println("b:", vec3b)
	// fmt.println("a x b:", cross(vec3a, vec3b))
	// fmt.println("a.b:", vec3a * vec3b)
}
