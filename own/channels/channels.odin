package channels

import "core:log"
import "core:mem"
import "core:sync/chan"
import "core:thread"
import "core:time"

Pipeline_Event :: union {
	Index_Cmd,
	Embed_Cmd,
}

Index_Cmd :: struct {
	embeds:     [128]f32,
	collection: string,
}

Embed_Cmd :: struct {
	text:  string,
	model: string,
}


Update_Channel_BI :: chan.Chan(Pipeline_Event)
Update_Channel_TX :: chan.Chan(Pipeline_Event, .Send)

// T :: struct {
//     channel:
// }

TRACK_LEAKS :: true

MAX_CHAN_SIZE :: 10
main :: proc() {
	context.logger = log.create_console_logger()

	// Init leak tracking
	when TRACK_LEAKS {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		// Leak tracking results
		defer {
			// Display leaks
			if len(track.allocation_map) > 0 {
				log.errorf("=== Allocations not freed: %d ===\n", len(track.allocation_map))

				// Display leaks
				for _, leak in track.allocation_map {
					log.errorf("%v leaked %v bytes\n", leak.location, leak.size)
				}
			}

			// Display bad frees
			if len(track.bad_free_array) > 0 {
				log.errorf("=== Bad frees: %d ===\n", len(track.bad_free_array))

				// Display bad frees
				for bad_free in track.bad_free_array {
					log.errorf(
						"%v allocation %p was freed badly\n",
						bad_free.location,
						bad_free.memory,
					)
				}
			}

			log.infof("Peak memory allocated: %v bytes", track.peak_memory_allocated)
			log.infof("Num allocations: %v", track.total_allocation_count)
			mem.tracking_allocator_destroy(&track)
		}
	}

	// simple_send_recv()
	thread_send_to_main_intra()
}

thread_send_to_main_intra :: proc() {
	Task_Channel_BI :: chan.Chan([2]u32)
	State :: struct {
		global_data: [12]u32,
		channel:     Task_Channel_BI,
	}

	// Define thread work proc
	worker_proc :: proc(t: ^thread.Thread) {
		state := cast(^State)t.data
		// tx := chan.as_send(state.channel)

		log.debug("[W] Start worker proc")
		log.debug("[W] Iterations: ", len(state.global_data))

		for i in 0 ..< len(state.global_data) {
			log.debug("[W] i = ", i)
			state.global_data[i] = u32(i) + 1
			ok := chan.send(state.channel, [2]u32{state.global_data[i], state.global_data[i] + 3})
			if !ok {
				log.errorf("[W] Thread failed to send results")
				return
			}
			// time.sleep(100 * time.Millisecond)
		}

		log.debug("[W] Thread proc done")
	}
	// Setup the state
	state := State{}
	alloc_err: mem.Allocator_Error
	state.channel, alloc_err = chan.create_buffered(
		Task_Channel_BI,
		MAX_CHAN_SIZE,
		allocator = context.allocator,
	)
	if alloc_err != nil {
		log.errorf("Failed to initialize state channel: %s", alloc_err)
	}

	// Create thread
	t := thread.create(worker_proc)
	if t == nil {
		log.error("Failed to created thread")
	}
	t.init_context = context
	t.data = &state

	// Start thread
	thread.start(t)

	for !thread.is_done(t) || chan.len(state.channel) > 0 {

		for data in chan.try_recv(state.channel) {
			log.debugf("[M] data: %v", data)
		}
		// time.sleep(1 * time.Second)
	}

	log.info("Thread finished")
	thread.destroy(t)
	chan.destroy(state.channel)

	// Check what happened to the data in state
	log.debugf("End Global Data: %v", state.global_data)
}

simple_send_recv :: proc() {
	// Play around with a default channel
	Embd_Channel_BI :: chan.Chan([2]f32)
	c, alloc_err := chan.create_buffered(Embd_Channel_BI, MAX_CHAN_SIZE, context.allocator)
	if alloc_err != nil {
		log.errorf("Failed to allocate buffered channel: %s", alloc_err)
		return
	}

	defer chan.destroy(c)

	// Pipe stuff into it
	tx := chan.as_send(c)
	if !chan.can_send(tx.impl) {
		log.errorf("tx cannot send")
		return
	}

	for i in 0 ..< MAX_CHAN_SIZE {
		data: [2]f32 = {f32(i), f32(i + 1)}
		chan.send(tx, data)
	}

	log.info("Send data to channel")

	// Read it the other way
	rx := chan.as_recv(c)
	if !chan.can_recv(rx.impl) {
		log.errorf("rx cannon receive")
		return
	}

	for data in chan.try_recv(rx) {
		log.infof("data: %v", data)
	}
}
