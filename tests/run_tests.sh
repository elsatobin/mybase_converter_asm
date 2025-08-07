
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_executable>"
    exit 1
fi

TARGET=$1

# detect if running in github actions
IS_GITHUB_ACTIONS=${GITHUB_ACTIONS:-false}

# github actions formatting functions
gh_notice() {
    if [ "$IS_GITHUB_ACTIONS" = "true" ]; then
        echo "::notice::$1"
    else
        echo "  [✔] $1"
    fi
}

gh_error() {
    if [ "$IS_GITHUB_ACTIONS" = "true" ]; then
        echo "::error::$1"
    else
        echo "  [✖] $1"
    fi
}

gh_group() {
    if [ "$IS_GITHUB_ACTIONS" = "true" ]; then
        echo "::group::$1"
    else
        echo "$1"
    fi
}

gh_endgroup() {
    if [ "$IS_GITHUB_ACTIONS" = "true" ]; then
        echo "::endgroup::"
    fi
}

# Function to run a test and check the output
run_test() {
    local description="$1"
    local command="$2"
    local expected="$3"
    local output

    output=$(eval "$command")

    if [[ "$output" == "$expected" ]]; then
        gh_notice "$description"
    else
        gh_error "$description"
        if [ "$IS_GITHUB_ACTIONS" = "true" ]; then
            echo "      expected: '$expected'"
            echo "      got: '$output'"
        else
            echo "      expected: '$expected'"
            echo "      got: '$output'"
        fi
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
        gh_notice "$description"
    else
        gh_error "$description"
        if [ "$IS_GITHUB_ACTIONS" = "true" ]; then
            echo "      expected error containing: '$expected_error'"
            echo "      got: '$output'"
        else
            echo "      expected error containing: '$expected_error'"
            echo "      got: '$output'"
        fi
    fi
}

if [ "$IS_GITHUB_ACTIONS" = "true" ]; then
    echo "::notice::running comprehensive test suite"
else
    echo "--- running comprehensive test suite ---"
fi

if [ ! -f "$TARGET" ]; then
    if [ "$IS_GITHUB_ACTIONS" = "true" ]; then
        echo "::error::$TARGET not found. Build failed."
    else
        echo "Error: $TARGET not found. Build failed."
    fi
    exit 1
fi

gh_group "testing basic conversions..."
run_test "255 (10) -> FF (16)" "$TARGET 255 10 16" "FF"
run_test "10 (10) -> 1010 (2)" "$TARGET 10 10 2" "1010"
run_test "11111111 (2) -> FF (16)" "$TARGET 11111111 2 16" "FF"
run_test "101010 (2) -> 42 (10)" "$TARGET 101010 2 10" "42"
gh_endgroup

gh_group "testing edge cases..."
run_test "0 (10) -> 0 (2)" "$TARGET 0 10 2" "0"
run_test "1 (10) -> 1 (2)" "$TARGET 1 10 2" "1"
run_test "1234567890 (10) -> 499602D2 (16)" "$TARGET 1234567890 10 16" "499602D2"
gh_endgroup

gh_group "testing all bases..."
run_test "1Z (36) -> 71 (10)" "$TARGET 1Z 36 10" "71"
run_test "71 (10) -> 1Z (36)" "$TARGET 71 10 36" "1Z"
gh_endgroup

gh_group "testing error handling..."
run_error_test "invalid base (lower bound)" "$TARGET 123 1 10" "error: base must be between 2 and 36"
run_error_test "invalid base (upper bound)" "$TARGET 123 10 37" "error: base must be between 2 and 36"
run_error_test "invalid digit for base" "$TARGET 129 2 10" "error: invalid digit for specified base"
run_error_test "invalid digit for base (hex)" "$TARGET G 16 10" "error: invalid digit for specified base"
run_error_test "incorrect number of arguments" "$TARGET 10 10" "usage: base_converter <number> <from_base> <to_base>"
gh_endgroup

gh_group "testing mixed case..."
run_test "aBcDeF (16) -> 11259375 (10)" "$TARGET aBcDeF 16 10" "11259375"
gh_endgroup

if [ "$IS_GITHUB_ACTIONS" = "true" ]; then
    echo "::notice::test suite finished"
else
    echo "--- test suite finished ---"
fi
