package json_unmarshal_to_map

import "core:encoding/json"
import "core:log"


main :: proc() {
	context.logger = log.create_console_logger()

	// res := make(Coll_Res)
	// defer delete(res)

	// Coll_Res :: map[string]string
	res: json.Object

	JSON_STRING: string : `{
    "time": 0.002,
    "status": "ok"
    }`

	err := json.unmarshal(transmute([]u8)JSON_STRING[:], &res)
	log.debug("JSON error: %v", err)

	log.infof("Unmarshalled: %v", res)
}
