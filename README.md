# oh_rome

[ROME](https://github.com/rometools/rome), the Java RSS/Atom/OPML library, ported to ArkTS for HarmonyOS and published
on OHPM as **`@explore-in-hmos/oh_rome`**.

```shell
ohpm install @explore-in-hmos/oh_rome
```

Usage, supported formats and modules, and the differences from ROME are in [`oh_rome/README.md`](oh_rome/README.md).

## What's here

| Directory | What it is |
|---|---|
| `oh_rome/` | The library (`@explore-in-hmos/oh_rome`), a HAR module, with its unit tests (`src/test`) and on-device tests (`src/ohosTest`) |
| `entry/` | Sample app: samples for the main formats and modules, conversion, generation, OPML, real feeds |
| `fixtures/`, `tools/` | ROME's test feeds and the tools that generate golden tests by running ROME itself |
| `scripts/` | `check.sh` builds the HAR and the sample app and runs the unit tests (the only trustworthy pass/fail signal); `pack-license.sh` builds the packed license file |

## Run the sample app

Open the repository root in DevEco Studio, turn on automatic signing (File → Project Structure → Signing Configs) and
run `entry`.

## Develop

Open the repository root in DevEco Studio, or from a shell:

```shell
ohpm install --all
./scripts/check.sh
```

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) before changing the library: it has the porting rules and how the golden tests work.

## Release

1. Set the version in `oh_rome/oh-package.json5` and add it to `oh_rome/CHANGELOG.md`. The HAR's bytecode embeds the
   package version, and registries may check it against the package (ohpm-repo does), so build only after this step.
2. If `LICENSE`, `NOTICE` or `LICENSE-JDOM` changed, run `scripts/pack-license.sh`. It rewrites `oh_rome/LICENSE`, the
   only license file the HAR packs. `check.sh` fails while that file is out of date.
3. Build the HAR with `hvigorw --mode module -p module=oh_rome@default -p product=default -p buildMode=release assembleHar`, then run
   `ohpm prepublish` and `ohpm publish` on `oh_rome/build/default/outputs/default/oh_rome.har`.

## License

Apache-2.0, like ROME. See [`LICENSE`](LICENSE), [`NOTICE`](NOTICE) (which also carries the Apache Xerces notices
for the XML parser) and, for the XML writer that follows JDOM, [`LICENSE-JDOM`](LICENSE-JDOM).
