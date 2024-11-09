package timestamp_file

import "core:fmt"
import "core:log"
import "core:time"
import "core:time/datetime"
import "core:time/timezone"


main :: proc() {
	context.logger = log.create_console_logger()

	now_t := time.now()
	year, month, day := time.date(now_t)
	hour, min, sec := time.clock(now_t)

	filename_utc := fmt.tprintf("%d_%d_%d__%d_%d_%d.txt", year, month, day, hour, min, sec)
	defer free_all(context.temp_allocator)

	log.infof("Filename (UTC): `%s`", filename_utc)

	dt, _ := datetime.components_to_datetime(year, month, day, hour, min, sec)
	log.infof("Datetime: %s", timezone.datetime_to_str(dt))

	local_utc, succ := timezone.datetime_to_utc(dt)
	log.infof("Datetime to utc: %v", local_utc)
}
