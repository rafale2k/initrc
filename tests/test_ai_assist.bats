#!/usr/bin/env bats

setup() {
    # Source the script to test its functions
    source ./common/_ai_assist.sh
}

@test "_is_safe_command allows safe commands" {
    run _is_safe_command "echo hello world"
    [ "$status" -eq 0 ]

    run _is_safe_command "ls -la /"
    [ "$status" -eq 0 ]

    run _is_safe_command "rm -rf ./myfolder"
    [ "$status" -eq 0 ]

    run _is_safe_command "rm -f /tmp/file"
    [ "$status" -eq 0 ]

    run _is_safe_command "mkfifo /tmp/myfifo"
    [ "$status" -eq 0 ]
}

@test "_is_safe_command blocks destructive commands to root and absolute paths" {
    run _is_safe_command "rm -rf /"
    [ "$status" -eq 1 ]

    run _is_safe_command "rm  -rf   /"
    [ "$status" -eq 1 ]

    run _is_safe_command "rm -rf /var/log"
    [ "$status" -eq 1 ]
}

@test "_is_safe_command blocks destructive commands to HOME variable" {
    run _is_safe_command "rm -rf \$HOME"
    [ "$status" -eq 1 ]

    run _is_safe_command "rm -rf \$HOME/"
    [ "$status" -eq 1 ]
}

@test "_is_safe_command blocks destructive commands to top-level directories" {
    run _is_safe_command "rm -rf /var"
    [ "$status" -eq 1 ]

    run _is_safe_command "rm -rf /etc "
    [ "$status" -eq 1 ]

    run _is_safe_command "rm -rf /usr"
    [ "$status" -eq 1 ]
}

@test "_is_safe_command blocks mkfs commands" {
    run _is_safe_command "sudo mkfs.ext4 /dev/sda1"
    [ "$status" -eq 1 ]

    run _is_safe_command "mkfs -t vfat /dev/sdb1"
    [ "$status" -eq 1 ]
}

@test "_is_safe_command blocks dd commands that write zero" {
    run _is_safe_command "dd if=/dev/zero of=/dev/sda"
    [ "$status" -eq 1 ]
}

@test "_is_safe_command blocks fork bombs" {
    run _is_safe_command ":(){:|:&};:"
    [ "$status" -eq 1 ]
}
