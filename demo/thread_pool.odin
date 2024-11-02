package demo

import "core:log"
import "core:thread"
import "core:time"

NUM_THREADS :: 3
NUM_TASKS :: 30

thread_pool :: proc() {
	context.logger = log.create_console_logger()

	log.info("Thread Pool example")

	// Create a thread pool with eg. 3 threads
	pool: thread.Pool
	thread.pool_init(&pool, allocator = context.allocator, thread_count = NUM_THREADS)
	defer thread.pool_destroy(&pool)

	// Add tasks, eg 30
	for i in 0 ..< NUM_TASKS {
		// be mindfull of the allocator used for tasks. The allocator needs to be thread-safe,
		// or be owned by the task for exclusive use.
		thread.pool_add_task(
			&pool,
			allocator = context.allocator,
			procedure = task_proc,
			data = nil,
			user_index = i,
		)
	}

	// Start the pool
	thread.pool_start(&pool)

	// time.sleep(5 * time.Second)
	thread.yield()

	thread.pool_finish(&pool)
}

// Like raw threads, we need to define a "worker" function
// which is a Task_Proc aka proc::(task: Task)
task_proc :: proc(t: thread.Task) {
	for i in 1 ..= 2 {
		log.infof("Worker Task %d is on iteration %d", t.user_index, i)
		time.sleep(1 * time.Millisecond)
	}

	log.infof("Worker task %d FINISHED", t.user_index)
}
