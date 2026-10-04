# L431_RC_Periph

A small ArduPilot DroneCAN peripheral board built around the STM32L431, under the [MadManUAV](https://github.com/MadManUAV) org.

**Status:** work in progress — hardware design.

## What it is

An `AP_Periph` CAN node: an STM32L431 paired with a TCAN CAN transceiver that hangs off a flight controller's CAN bus and handles RC/servo peripheral duties, running ArduPilot's AP_Periph firmware.

## Repo layout

- KiCad project — schematic (`L431_RC_Periph.kicad_sch`, with `AP_Periph` and `TCAN` sheets) and board (`L431_RC_Periph.kicad_pcb`).
- Shared symbols and footprints come from the [`mad_lib`](https://github.com/Cimos/mad_lib) submodule — clone with `--recurse-submodules`.
- KiBot CI (`options.yaml`, `build-panel.yaml`) builds the PCB, renders images, diffs revisions, panelises, and cuts a release datapack via the workflows in `.github/workflows`.

## License

GPL-3.0 — see [LICENSE.md](LICENSE.md).
