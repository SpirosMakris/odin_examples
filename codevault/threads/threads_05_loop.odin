package pthreads

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"
import "core:sync"
import "core:sys/posix"

Data_Context_5 :: struct {
	ctx:   runtime.Context,
	mails: int,
	mutex: sync.Mutex,
}

routine_5 :: proc "c" (data: rawptr) -> rawptr {
	dc := cast(^Data_Context_5)data
	context = dc.ctx

	for _ in 0 ..< 1_000_000 {
		sync.mutex_lock(&dc.mutex)
		dc.mails += 1
		sync.mutex_unlock(&dc.mutex)
	}

	return nil
}


main :: proc() {
	dc := Data_Context_5 {
		ctx   = context,
		mails = 0,
	}

	fmt.println("Main Thread")

	th: [4]posix.pthread_t

	for i in 0 ..< len(th) {
		if posix.pthread_create(&th[i], nil, routine_5, &dc) != .NONE {
			log.errorf("Failed created thread at idx: %d", i)
			os.exit(i)
		}

		fmt.printfln("Thread %d has been created", i)

		// if posix.pthread_join(th[i], nil) != .NONE {
		// 	log.errorf("Failed to join thread at idx: %d", i)
		// 	os.exit(i + len(th))
		// }

		// fmt.printfln("Thread %d has finished", i)
		fmt.printfln("Mails: %d", dc.mails)
	}

	for i in 0 ..< len(th) {
		if posix.pthread_join(th[i], nil) != .NONE {
			log.errorf("Failed to join thread at idx: %d", i)
			os.exit(i + len(th))
		}

		fmt.printfln("Thread %d has finished", i)
	}


	fmt.printfln("Mails: %d", dc.mails)
}
