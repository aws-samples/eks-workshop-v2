package crossplane

default allow = false

allow := true {           # allow is true if...
    count(violation) == 0 # there are zero violations.
}

violation[msg] {
	input.request.kind.kind = "DBInstance"
	input.request.operation = "CREATE"
	size := input.request.object.spec.forProvider.allocatedStorage
	size >= 20
	msg = sprintf("database size of %d GB is larger than limit of 20 GB", [size])
}
