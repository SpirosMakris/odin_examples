package enumerated_arrays

import "core:fmt"

Nice_People :: enum {
	Bob,
	Rob,
	Tim,
}

main :: proc() {

	fmt.println(typeid_of(Nice_People))

	nice_rating := [Nice_People]int {
		.Bob = 5,
		.Rob = 7,
		.Tim = 4,
	}

	fmt.println(nice_rating)

	bobs_niceness := nice_rating[.Bob]
	fmt.println(bobs_niceness)

	// PARTIAL INIT
	nice_rating = #partial [Nice_People]int {
		.Tim = 10,
	}

	fmt.println(nice_rating)

	// ALL ZEROES
	nice_rating_2: [Nice_People]int
	fmt.println(nice_rating_2)
}
