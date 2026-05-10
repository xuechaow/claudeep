#!/usr/bin/env bats
load test_helper

@test "valid key starting with sk-" {
    run validate_api_key "sk-abc123def456"
    [ "$status" -eq 0 ]
}

@test "rejects empty key" {
    run validate_api_key ""
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot be empty"* ]]
}

@test "rejects key without sk- prefix" {
    run validate_api_key "abc123"
    [ "$status" -ne 0 ]
    [[ "$output" == *"start with 'sk-'"* ]]
}

@test "rejects key with special characters" {
    run validate_api_key "sk-abc@123#"
    [ "$status" -ne 0 ]
    [[ "$output" == *"alphanumeric"* ]]
}

@test "accepts key with mixed case" {
    run validate_api_key "sk-AbCdEf123"
    [ "$status" -eq 0 ]
}
