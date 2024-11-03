package threaded_channels

// https://rm4n0s.github.io/posts/2-go-devs-should-learn-odin/

import "core:sync"
import "core:sync/chan"

EParent :: enum {
	Father,
	Mother,
}

Food_From_Father :: struct {
	papa_index: int,
}

Food_From_Mother :: struct {
	mama_index: int,
}

Food :: union {
	Food_From_Father,
	Food_From_Mother,
}

Kid_Data :: struct {
	kids_wait_group: ^sync.Wait_Group,
	mouth:           ^chan.Chan(Food, .Recv),
}

Parent_Data :: struct {
	parent_type:        EParent,
	num_foods:          int,
	parents_wait_group: ^sync.Wait_Group,
	mouth:              ^chan.Chan(Food, .Send),
	mouth_mutex:        ^sync.Mutex,
}

// parent_task
