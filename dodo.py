from pathlib import Path
import subprocess


FPGA_PART = "lp8k"
FPGA_PACKAGE = "cm81"
FPGA_FREQ_MHZ = "16"
ASM_PROGRAM_ROOT = Path("src/asm/programs")
ASM_PROGRAM_BUILD_ROOT = Path("build/asm/programs")


def fpga_targets():
    root = Path("src/fpga")
    return sorted(path.name for path in root.iterdir() if path.is_dir())


def run(*cmd):
    subprocess.run(cmd, check=True)


def asm_program_sources():
    return sorted(ASM_PROGRAM_ROOT.glob("**/*.s"))


def asm_program_outputs(source):
    relative = source.relative_to(ASM_PROGRAM_ROOT)
    output = ASM_PROGRAM_BUILD_ROOT / relative.with_suffix("")
    return {
        "object": output.with_suffix(".o"),
        "listing": output.with_suffix(".lst"),
        "srec": output.with_suffix(".srec"),
    }


def compile_asm_programs():
    sources = asm_program_sources()
    if not sources:
        raise FileNotFoundError(f"no asm programs found under {ASM_PROGRAM_ROOT}/")

    for source in sources:
        outputs = asm_program_outputs(source)
        outputs["object"].parent.mkdir(parents=True, exist_ok=True)
        run(
            "ca65",
            "--cpu",
            "65c02",
            "--list-bytes",
            "255",
            "-I",
            "./src/asm",
            "-I",
            "./src",
            "-l",
            outputs["listing"],
            "-o",
            outputs["object"],
            source,
        )
        run("python", "src/tools/srec.py", outputs["listing"], "-o", outputs["srec"])


def fpga_paths(target):
    src_dir = Path("src/fpga") / target
    build_dir = Path("build/fpga") / target
    verilog_files = sorted(src_dir.glob("*.v"))
    testbenches = sorted(src_dir.glob("*_tb.v"))

    return {
        "src_dir": src_dir,
        "build_dir": build_dir,
        "top": src_dir / "top.v",
        "verilog_files": verilog_files,
        "design_files": [path for path in verilog_files if not path.name.endswith("_tb.v")],
        "testbenches": testbenches,
        "pins": src_dir / "pins.pcf",
        "json": build_dir / f"{target}.json",
        "asc": build_dir / f"{target}.asc",
        "bin": build_dir / f"{target}.bin",
    }


def require_files(paths, *names):
    missing = [str(paths[name]) for name in names if not paths[name].exists()]
    if missing:
        raise FileNotFoundError("missing FPGA input files: " + ", ".join(missing))


def fpga_sim(paths):
    require_files(paths, "top")
    if not paths["testbenches"]:
        raise FileNotFoundError(f"no FPGA testbenches found under {paths['src_dir']}/*_tb.v")

    for testbench in paths["testbenches"]:
        output = paths["build_dir"] / f"{testbench.stem}.vvp"
        run("iverilog", "-g2012", "-o", output, testbench, *paths["design_files"])
        run("vvp", output)


def fpga_synth(paths):
    require_files(paths, "top")
    run(
        "yosys",
        "-p",
        "read_verilog -sv "
        + " ".join(str(path) for path in paths["design_files"])
        + f"; synth_ice40 -top top -json {paths['json']}",
    )


def fpga_pnr(paths):
    require_files(paths, "pins", "json")
    run(
        "nextpnr-ice40",
        f"--{FPGA_PART}",
        "--package",
        FPGA_PACKAGE,
        "--freq",
        FPGA_FREQ_MHZ,
        "--pcf",
        paths["pins"],
        "--json",
        paths["json"],
        "--asc",
        paths["asc"],
    )


def fpga_pack(paths):
    require_files(paths, "asc")
    run("icepack", paths["asc"], paths["bin"])


def fpga_build(paths):
    fpga_synth(paths)
    fpga_pnr(paths)
    fpga_pack(paths)


def run_fpga_target(target, action):
    actions = {
        "sim": fpga_sim,
        "synth": fpga_synth,
        "pnr": fpga_pnr,
        "pack": fpga_pack,
        "build": fpga_build,
    }

    if action not in actions:
        valid_actions = ", ".join(actions.keys())
        raise ValueError(f"unknown FPGA action {action!r}; expected one of: {valid_actions}")

    paths = fpga_paths(target)
    paths["build_dir"].mkdir(parents=True, exist_ok=True)
    actions[action](paths)


def run_fpga(action, target):
    targets = [target] if target else fpga_targets()
    if not targets:
        raise ValueError("no FPGA targets found under src/fpga/")

    for fpga_target in targets:
        run_fpga_target(fpga_target, action)


def task_fpga():
    params = [
        {
            "name": "target",
            "short": "t",
            "long": "target",
            "default": "",
            "help": "FPGA target under src/fpga/. Defaults to all targets except for program.",
        },
    ]

    for action in ("sim", "synth", "pnr", "pack", "build"):
        yield {
            "name": action,
            "params": params,
            "actions": [(run_fpga, [action])],
            "verbosity": 2,
        }


def task_asm():
    program_sources = asm_program_sources()
    program_outputs = [output for source in program_sources for output in asm_program_outputs(source).values()]

    yield {
        "name": "build",
        "actions": ["./src/asm/eeprom/build.sh"],
        "file_dep": [
            "src/asm/eeprom/build.sh",
            "src/asm/eeprom/compy6502.x",
            "src/asm/include/compy6502.inc",
            "src/asm/eeprom/kernel/vectors.s",
            "src/asm/eeprom/main.s",
            "src/asm/eeprom/wozmon.s",
        ],
        "targets": ["bin/compy6502.bin"],
    }

    yield {
        "name": "test",
        "actions": ["uv run pytest"],
        "task_dep": ["asm:build"],
    }

    yield {
        "name": "programs",
        "actions": [compile_asm_programs],
        "file_dep": [
            "src/tools/srec.py",
            "src/asm/include/compy6502.inc",
            *program_sources,
        ],
        "targets": program_outputs,
    }
