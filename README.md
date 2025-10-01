# Lean Slides

`Lean Slides` is a tool to 
automatically generate `reveal.js` slides 
from Markdown comments in the Lean editor.

![LeanSlides](https://github.com/0art0/lean-slides/assets/18333981/29029c7b-f586-45a1-b203-ffdc66a41049)

See `Demo.lean` for more details.

# Dependencies

`Lean Slides` works by combining together several tools:

- [`reveal.js`](https://revealjs.com/) (no install required)

- [`pandoc`](https://pandoc.org/) (commit >= `7c6dbd3`)

- [`node.js`](https://nodejs.org/en)

- [`browser-sync`](https://browsersync.io/)

Note that `LeanSlides` may have issues with older versions of `pandoc`.
A manual intervention using
```lean
#set_pandoc_options "-V" "revealjs-url=\"https://unpkg.com/reveal.js@^4/\""
```
may fix the issues in such cases.

# Usage

To use `Lean Slides`, first install all the dependencies listed above.

`Lean Slides` can be added to an existing Lean repository
by inserting the following lines in the `lakefile.toml` file:

```toml
[[require]]
name = "lean-slides"
git = "https://github.com/0art0/lean-slides.git"
```

If the repository uses a `lakefile.lean` instead, try:

```lean
require «lean-slides» from git "https://github.com/0art0/lean-slides"@"master"
```

---

In any file that imports `LeanSlides`, type

```lean
#slides +draft Test /-!
  <Markdown text>
-/
```

**Run `lake run lean-slides/serve-slides` from the command line
to start the HTTP server for the slides.**

Any slides that are not in draft mode should now be rendered.

The port used by `Lean Slides` can be modified through
an environment variable with the name `LEANSLIDES_PORT`.

# Features

`Lean Slides` turns comments written in the above format
into `reveal.js` slides which are rendered in the infoview
as a [`Widget`](https://github.com/EdAyers/ProofWidgets4).

The tool also features a code action to 
go in and out of draft mode.

The generated `reveal.js` slides
render mathematics by default
using `KaTeX`.

## Custom styling

To enable custom CSS styling for the `reveal.js` presentation, insert a file named `style.css` in the `slides` folder (which is usually automatically generated in the home directory of your project by `Lean Slides`). A sample style sheet is shown below.

```css
.reveal h1,
.reveal h2,
.reveal h3,
.reveal h4,
.reveal h5,
.reveal h6 {
  text-transform: none;
}

.reveal code {
  background-color: #5b5b5b;
  padding: 0.1em 0.2em;
  border-radius: 6px;
}

.reveal pre code {
  background-color: #5b5b5b;
  display: block;
  padding: 1em;
  border-radius: 6px;
  overflow: auto;
}
```
