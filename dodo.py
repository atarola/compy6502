DOIT_CONFIG = {
    "default_tasks": ["build", "test"],
}


def task_build():
    return {
        "actions": ["./src/asm/build.sh"],
        "file_dep": [
            "src/asm/build.sh",
            "src/asm/compy6502.x",
            "src/asm/include/compy6502.inc",
            "src/asm/kernel/vectors.s",
            "src/asm/main.s",
            "src/asm/wozmon.s",
        ],
        "targets": ["bin/compy6502.bin"],
    }


def task_test():
    return {
        "actions": ["uv run pytest"],
        "task_dep": ["build"],
    }
