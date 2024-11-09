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
	fmt.println(data.parent_type, "start feeding")

	for i in 0 ..< 10 {
		food := Food(Food_From_Mother{mama_food_index = i})
		chan.send(data.mouth^, food)
		time.sleep(100 * time.Millisecond)
	}

	chan.close(data.mouth^)
}


main :: proc() {
	// Create feeding pipe
	// Here we create the channel: [mama_thread]>--Food-->[main_thread]
	mouth, err := chan.create(chan.Chan(Food), context.allocator)
	defer chan.destroy(mouth)

	// Create mama bird
	mama_mouth := chan.as_send(mouth) // mama food data exit

	// Create mama thread
	mama_thread := thread.create(parent_task)
	defer thread.destroy(mama_thread)
	// Init (notice pointer to rx channel)
	mama_thread.init_context = context
	mama_thread.user_index = 1
	mama_thread.data = &Parent_Data{parent_type = .Mother, num_foods = 8, mouth = &mama_mouth}

	// Start threads(long-running tasks)
	thread.start(mama_thread)

	// Receivind end of channel
	kid_mouth := chan.as_recv(mouth)

	for {
		msg, ok := chan.recv(kid_mouth)
		if !ok {
			fmt.println("Mouth closed")
			break
		}

		switch food in msg {
		case Food_From_Father:
			fmt.println("How did we get food from father?")
			break
		case Food_From_Mother:
			fmt.println("Got food from mother: ", food.mama_food_index)
		}
	}

	fmt.println("Finished")

	// @NOTE: just wait a bit for the thread to start
	// This is a known bug
	time.sleep(1 * time.Second)

	thread.join(mama_thread)
}
