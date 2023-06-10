package crossplane.example

allow := true {                                     # allow is true if...
    count(violation) == 0                           # there are zero violations.
}
# DBInstances with engine mysql must not be larger than 20GB.
#deny[msg] {
violation[msg] {
    input.request.kind.kind = "DBInstance"
    input.request.operation = "CREATE"
    engine := input.request.object.spec.forProvider.engine
    size := input.request.object.spec.forProvider.allocatedStorage
    size >= 20
    msg = sprintf("database size of %d GB is larger than limit of 20 GB", [size])
}
