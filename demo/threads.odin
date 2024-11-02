package demo

import "core:fmt"
import "core:thread"
import "core:time"

prefix_table := [?]string{"White", "Red", "Green", "Blue", "Octarine", "Black"}

print_mutex := b64(false)

main :: proc() {
	// basic_threads()
	thread_pool()
}

basic_threads :: proc() {
	fmt.println("\n# Basic threads")

	worker_proc :: proc(t: ^thread.Thread) {
		for iteration in 1 ..= 5 {
			fmt.printf("Thread %d is on iteration %d\n", t.user_index, iteration)
			fmt.printf("`%s` : iteration %d\n", prefix_table[t.user_index], iteration)
			time.sleep(1 * time.Second)
		}
	}

	threads := make([dynamic]^thread.Thread, 0, len(prefix_table))
	defer delete(threads)

	for _ in prefix_table {
		if t := thread.create(worker_proc); t != nil {
			t.init_context = context
			t.user_index = len(threads)
			append(&threads, t)
			thread.start(t)
		}
	}

	for len(threads) > 0 {
		for i := 0; i < len(threads); {
			if t := threads[i]; thread.is_done(t) {
				fmt.printf("Thread %d is done\n", t.user_index)
				thread.destroy(t)

				ordered_remove(&threads, i)
			} else {
				i += 1
			}
		}
	}
}
