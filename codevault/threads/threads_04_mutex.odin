package pthreads

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"
import "core:sync"
import "core:sys/posix"

Data_Context_4 :: struct {
	ctx:   runtime.Context,
	mails: uint,
	mutex: sync.Mutex,
}

routine_4 :: proc "c" (data: rawptr) -> rawptr {
	dc := cast(^Data_Context_4)data
	context = dc.ctx

	for _ in 0 ..< 1_000_000 {
		// Lock "mutex"
		sync.mutex_lock(&dc.mutex)

		// Critical Section
		dc.mails += 1

		// Unlock "mutex"
		sync.mutex_unlock(&dc.mutex)
	}

	return nil
}

main :: proc() {
	dc := Data_Context_4 {
		ctx   = context,
		mails = 0,
	}

	fmt.println("Main Thread")

	t1, t2: posix.pthread_t
	if posix.pthread_create(&t1, nil, routine_4, &dc) != .NONE {
		log.error("Failed creating thread 1")
		os.exit(1)
	}
	if posix.pthread_create(&t2, nil, routine_4, &dc) != .NONE {
		log.error("Failed creating thread 2")
		os.exit(2)
	}

	if posix.pthread_join(t1, nil) != .NONE {
		log.error("Failed joining thread 1")
		os.exit(3)
	}

	if posix.pthread_join(t2, nil) != .NONE {
		log.error("Failed joining thread 2")
		os.exit(4)
	}

	fmt.printfln("Mails: %d", dc.mails)
}
