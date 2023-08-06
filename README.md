# Lean Slides

`Lean Slides` is a tool to 
automatically generate `reveal.js` slides 
from Markdown comments in the Lean editor.

![LeanSlides](https://github.com/0art0/lean-slides/assets/18333981/29029c7b-f586-45a1-b203-ffdc66a41049)

See `Demo.lean` for more details.

# Dependencies

`Lean Slides` works by combining together several tools:

- [`reveal.js`](https://revealjs.com/) (no install required)

- [`pandoc`](https://pandoc.org/)

- [`node.js`](https://nodejs.org/en)

- [`browser-sync`](https://browsersync.io/)

# Usage

To use `Lean Slides`, first install all the dependencies
and clone [the repository](https://github.com/0art0/lean-slides/).

Change to the root folder and build the repository.
**Run the script `./build/bin/launchServer` from the command line.**
Alternatively, run the following from the command-line:
```bash
browser-sync . --port 3000 --watch --no-open
```

---

In any file that imports `LeanSlides`, type

```lean
#slides +draft Test /-!
  <Markdown text>
-/
```

# Features

`Lean Slides` turns comments written in the above format
into `reveal.js` slides which are rendered in the infoview
as a [`Widget`](https://github.com/EdAyers/ProofWidgets4).

The tool also features a code action to 
go in and out of draft mode.

The generated `reveal.js` slides
render mathematics by default
using `KaTeX`.
