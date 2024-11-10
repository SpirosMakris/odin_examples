package threaded_channels

// https://rm4n0s.github.io/posts/2-go-devs-should-learn-odin/

import "core:fmt"
import "core:sync"
import "core:sync/chan"
import "core:thread"
import "core:time"

EParent :: enum {
	Father,
	Mother,
}

Food_From_Father :: struct {
	papa_food_index: int,
}

Food_From_Mother :: struct {
	mama_food_index: int,
}

Food :: union {
	Food_From_Father,
	Food_From_Mother,
}

// Data for each Task, along with appropriate channel ends
// and sync primitives required

Kid_Data :: struct {
	kids_wait_group: ^sync.Wait_Group,
	mouth:           ^chan.Chan(Food, chan.Direction.Recv),
}

Parent_Data :: struct {
	parent_type:        EParent,
	num_foods:          int,
	parents_wait_group: ^sync.Wait_Group,
	mouth:              ^chan.Chan(Food, chan.Direction.Send),
	mouth_mutex:        ^sync.Mutex,
}


// Threads for long running tasks
parent_task :: proc(t: ^thread.Thread) {
	data := cast(^Parent_Data)t.data
	fmt.println(data.parent_type, "starts feeding")

	for i in 0 ..< data.num_foods {
		food: Food

		switch data.parent_type {
		case .Mother:
			food = Food_From_Mother {
				mama_food_index = i,
			}
		case .Father:
			food = Food_From_Father {
				papa_food_index = i,
			}
		}

		// if you don't add mutex, then at least once,
		// a parent will send the same food index to two kids
		// while the other parent does not send any food
		// for the same food index (which I don't understand why)
		sync.mutex_lock(data.mouth_mutex)
		chan.send(data.mouth^, food)
		sync.mutex_unlock(data.mouth_mutex)

		// Wait to throw up new food
		time.sleep(500 * time.Millisecond)
	}

	sync.wait_group_done(data.parents_wait_group)
	fmt.printfln("[PARENT] %v's feeding stopped", data.parent_type)
}

kid_task :: proc(t: thread.Task) {
	data := cast(^Kid_Data)t.data

	fmt.println("Kid", t.user_index, "opens mouth")

	for {
		msg, ok := chan.recv(data.mouth^)
		if !ok {
			fmt.println("mouth closed for kid", t.user_index)
			break
		}

		switch food in msg {
		case Food_From_Father:
			fmt.println(
				">>> kid",
				t.user_index,
				"received food",
				food.papa_food_index,
				"from father",
			)
		case Food_From_Mother:
			fmt.println(
				">>> kid",
				t.user_index,
				"received food",
				food.mama_food_index,
				"from mother",
			)
		}

		// Wait to chew their food
		time.sleep(time.Second)
	}

	fmt.println("kid", t.user_index, "finished eating")
	sync.wait_group_done(data.kids_wait_group)

	fmt.printfln("kid %d when to bed", t.user_index)
}

main :: proc() {
	// Wait groups
	parents_wg: sync.Wait_Group
	kids_wg: sync.Wait_Group
	num_kids := 5

	// Create feeding pipe
	// Here we create the channel: [mama/papa_thread]>--Food-->[kids thread pool]
	mouth, err := chan.create(chan.Chan(Food), context.allocator)
	defer chan.destroy(mouth)
	mouth_mutex := sync.Mutex{}

	// Create mama bird
	mama_mouth := chan.as_send(mouth) // mama food data exit

	// Create mama thread
	mama_thread := thread.create(parent_task)
	defer thread.destroy(mama_thread)
	// Init (notice pointer to rx channel)
	mama_thread.init_context = context
	mama_thread.user_index = 1
	mama_thread.data =
	&Parent_Data {
		parent_type = .Mother,
		num_foods = 5,
		parents_wait_group = &parents_wg,
		mouth = &mama_mouth,
		mouth_mutex = &mouth_mutex,
	}

	// create lazy father thread
	papa_mouth := chan.as_send(mouth)
	papa_thread := thread.create(parent_task)
	defer thread.destroy(papa_thread)
	// Init
	papa_thread.init_context = context
	papa_thread.user_index = 2
	papa_thread.data =
	&Parent_Data {
		parent_type = .Father,
		num_foods = 3,
		parents_wait_group = &parents_wg,
		mouth = &papa_mouth,
		mouth_mutex = &mouth_mutex,
	}


	// Setup wait groups before starting threads
	sync.wait_group_add(&parents_wg, 2)

	// Start threads(long-running tasks)
	thread.start(mama_thread)
	thread.start(papa_thread)

	// Create a nest for kids
	nest: thread.Pool
	thread.pool_init(&nest, allocator = context.allocator, thread_count = num_kids)
	defer thread.pool_destroy(&nest)

	sync.wait_group_add(&kids_wg, num_kids)
	for i in 1 ..= num_kids {
		kid_mouth := chan.as_recv(mouth)

		data := &Kid_Data{kids_wait_group = &kids_wg, mouth = &kid_mouth}

		// Add kid to the nest
		thread.pool_add_task(
			&nest,
			allocator = context.allocator,
			procedure = kid_task,
			data = rawptr(data),
			user_index = i,
		)
	}

	thread.pool_start(&nest)

	// Wait for any parents to finish
	sync.wait_group_wait(&parents_wg)
	fmt.println("All parents stopped feeding them")

	// Everybody closestheir mouths
	chan.close(mouth)
	fmt.println("kids close their mouths")

	// we wait for all the kids to sleep
	sync.wait_group_wait(&kids_wg)

	fmt.println("all kids slept")

	// run this or the program will never close
	thread.pool_finish(&nest)
}
