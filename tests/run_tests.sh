
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_executable>"
    exit 1
fi

TARGET=$1

# Function to run a test and check the output
run_test() {
    local description="$1"
    local command="$2"
    local expected="$3"
    local output

    output=$(eval "$command")

    if [[ "$output" == "$expected" ]]; then
        echo "  [✔] $description"
    else
        echo "  [✖] $description"
        echo "      expected: '$expected'"
        echo "      got: '$output'"
    fi
}

# Function to run a test and check for a specific error message
run_error_test() {
    local description="$1"
    local command="$2"
    local expected_error="$3"
    local output

    output=$(eval "$command" 2>&1)

    if [[ "$output" == *"$expected_error"* ]]; then
        echo "  [✔] $description"
    else
        echo "  [✖] $description"
        echo "      expected error containing: '$expected_error'"
        echo "      got: '$output'"
    fi
}

echo "--- running comprehensive test suite ---"

if [ ! -f "$TARGET" ]; then
    echo "Error: $TARGET not found. Build failed."
    exit 1
fi

echo "testing basic conversions..."
run_test "255 (10) -> FF (16)" "$TARGET 255 10 16" "FF"
run_test "10 (10) -> 1010 (2)" "$TARGET 10 10 2" "1010"
run_test "11111111 (2) -> FF (16)" "$TARGET 11111111 2 16" "FF"
run_test "101010 (2) -> 42 (10)" "$TARGET 101010 2 10" "42"

echo "testing edge cases..."
run_test "0 (10) -> 0 (2)" "$TARGET 0 10 2" "0"
run_test "1 (10) -> 1 (2)" "$TARGET 1 10 2" "1"
run_test "1234567890 (10) -> 499602D2 (16)" "$TARGET 1234567890 10 16" "499602D2"

echo "testing all bases..."
run_test "1Z (36) -> 71 (10)" "$TARGET 1Z 36 10" "71"
run_test "71 (10) -> 1Z (36)" "$TARGET 71 10 36" "1Z"

echo "testing error handling..."
run_error_test "invalid base (lower bound)" "$TARGET 123 1 10" "error: base must be between 2 and 36"
run_error_test "invalid base (upper bound)" "$TARGET 123 10 37" "error: base must be between 2 and 36"
run_error_test "invalid digit for base" "$TARGET 129 2 10" "error: invalid digit for specified base"
run_error_test "invalid digit for base (hex)" "$TARGET G 16 10" "error: invalid digit for specified base"
run_error_test "incorrect number of arguments" "$TARGET 10 10" "usage: base_converter <number> <from_base> <to_base>"

echo "testing mixed case..."
run_test "aBcDeF (16) -> 11259375 (10)" "$TARGET aBcDeF 16 10" "11259375"

echo "--- test suite finished ---"
