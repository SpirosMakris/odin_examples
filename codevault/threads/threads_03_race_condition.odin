package pthreads

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"
import "core:sys/posix"

Data_Context_3 :: struct {
	ctx:   runtime.Context,
	mails: int,
}

routine_3 :: proc "c" (data: rawptr) -> rawptr {
	dc := cast(^Data_Context_3)data
	context = dc.ctx

	for i in 0 ..< 1_000_000 {
		dc.mails += 1
		// increment =
		// read the value
		// increment (in register)
		// write it back to mails variable
	}

	return nil
}

main :: proc() {
	dc := Data_Context_3 {
		ctx   = context,
		mails = 0,
	}

	fmt.println("Main Thread")

	t1, t2: posix.pthread_t
	if posix.pthread_create(&t1, nil, routine_3, &dc) != .NONE {
		log.error("Failed creating thread 1")
		os.exit(1)
	}
	if posix.pthread_create(&t2, nil, routine_3, &dc) != .NONE {
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
