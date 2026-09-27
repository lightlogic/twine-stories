# twine-histoires
Repository pour mes histoires

## Repository layout

This repository holds several [Twine](https://twinery.org/) stories written for the [SugarCube](https://www.motoslave.net/sugarcube/2/) story format. Stories are kept as plain-text [Twee 3](https://github.com/iftechfoundation/twine-specs/blob/master/twee-3-specification.md) source and compiled to HTML with [Tweego](https://www.motoslave.net/tweego/). Every push to `main` builds all stories and publishes them to GitHub Pages.

```
stories/
  <story-name>/
    src/                      # compiled by Tweego
      story.twee              # StoryTitle and StoryData
      special.twee            # SugarCube special passages
      widgets.twee            # <<widget>> definitions, tagged [widget]
      chapter-01.twee         # story content, one file per chapter
      chapter-02.twee
      js/
        01-config.js          # Config.* settings
        02-setup.js           # shared functions and constants on `setup`
        03-macros.js          # custom macros (Macro.add)
      css/
        story.css
    assets/                   # images, audio, fonts (copied as-is)
shared/
  src/                        # code and passages included in every story
    js/
      common-macros.js
    widgets.twee
build.sh                      # builds every story into dist/
.github/workflows/pages.yml   # CI: build and deploy to GitHub Pages
dist/                         # build output (not tracked)
```

### `stories/<story-name>/`

Each story lives in its own folder. The folder name is used as the story's URL:
`https://<user>.github.io/<repo>/<story-name>/`.

### `src/`: story source

Everything in `src/` is passed to Tweego and compiled into a single HTML file.

| File | Contents |
|---|---|
| `story.twee` | The `StoryTitle` and `StoryData` passages. |
| `special.twee` | SugarCube special passages: `StoryInit`, `StoryCaption`, `StoryMenu`, `PassageReady`, `PassageDone`, etc. |
| `widgets.twee` | Widget definitions. Passages must be tagged `[widget]`. |
| `chapter-*.twee` | The story itself. Split by chapter or scene to keep files readable and diffs small. |
| `js/*.js` | Story JavaScript. Tweego concatenates all `.js` files into the Story JavaScript. |
| `css/*.css` | Story Stylesheet. Tweego concatenates all `.css` files. |

The `StoryData` passage contains the story's `ifid`, its permanent identifier. **Never change or regenerate it.** The same passage pins the story format and its version:

```
:: StoryData
{
  "ifid": "…",
  "format": "SugarCube",
  "format-version": "2.37.3",
  "start": "Start"
}
```

### Story JavaScript

JavaScript is kept in real `.js` files, not in a `[script]`-tagged Twee passage. That gives editor support, linting and readable diffs.

Files are prefixed with numbers so that load order is explicit:

- **`01-config.js`**: engine configuration.
  ```js
  Config.history.maxStates = 1;
  Config.passages.nobr = true;
  ```
- **`02-setup.js`**: helper functions and constants. Attach everything to SugarCube's `setup` object instead of creating globals; passages can then call `setup.rollDice()`.
  ```js
  setup.rollDice = (sides = 6) => random(1, sides);
  setup.MAX_HEALTH = 10;
  ```
- **`03-macros.js`**: custom macros defined with `Macro.add()`. They may use anything defined in `setup`.

Code that initialises story variables belongs in the `StoryInit` passage (`special.twee`), not in JavaScript.

> **Importing from the Twine app:** a story exported as Twee from the Twine app contains a `:: Story JavaScript [script]` passage and a `:: Story Stylesheet [stylesheet]` passage. Move their content into `js/` and `css/` and delete the passages, so the code exists in only one place.

### `assets/`: media

Images, audio and fonts go in `assets/`, **outside** `src/`. Tweego would otherwise embed media found in the source folder into the HTML as base64. The build copies `assets/` next to the compiled story, so reference files with relative paths:

```html
<img src="assets/map.png" alt="Map of the valley">
```

Paths are case-sensitive on GitHub Pages, and must not start with `/`.

### `shared/`: code used by several stories

`shared/src/` is compiled into **every** story, alongside the story's own `src/`. Use it for macros, helpers and widgets reused across stories.

- Prefix shared passage names (e.g. `shared-widgets`) to avoid clashes with a story's own passages.
- Shared code should not depend on code defined inside a particular story.

### Third-party libraries

Put a pinned copy of the library in the story's `src/js/`, with a prefix that makes it load first (e.g. `00-lib-howler.min.js`). It is then compiled into the story and works offline. Record the library's version and licence in this README.

Loading a library at runtime with SugarCube's `importScripts()` is possible, but makes the story depend on an external URL.

### Building locally

Requires [Tweego](https://github.com/tmedwards/tweego/releases) in your `PATH`.

```bash
./build.sh
xdg-open dist/index.html
```

`build.sh` compiles every folder in `stories/` to `dist/<story-name>/index.html`, copies its assets, and writes an index page at `dist/index.html` linking to all stories. The GitHub Actions workflow runs the same script.

### Adding a new story

1. Create `stories/<story-name>/src/` and `stories/<story-name>/assets/`.
2. Add a `story.twee` with `StoryTitle` and `StoryData` (generate a new IFID, e.g. by creating the story once in the Twine app or with `uuidgen`, uppercased).
3. Run `./build.sh` and check the result locally.
4. Commit and push to `main`; the story appears on GitHub Pages after the workflow finishes.

## Installing Tweego (Linux)

Stories are compiled with [Tweego](https://www.motoslave.net/tweego/), a command-line compiler for Twee source. Tweego is installed on your machine, **not** in this repository.

### 1. Download and unpack

Download the Linux build from the [Tweego website](https://www.motoslave.net/tweego/) or its [releases page](https://github.com/tmedwards/tweego/releases). Pick the build matching your architecture (`uname -m`: `x86_64` → `linux-x64`).

```bash
mkdir -p ~/.local/share/tweego
unzip ~/Downloads/tweego-2.1.1-linux-x64.zip -d ~/.local/share/tweego
chmod +x ~/.local/share/tweego/tweego
```

The folder now contains the `tweego` binary and a `storyformats/` directory.

### 2. Add Tweego to your `PATH`

```bash
echo 'export PATH="$HOME/.local/share/tweego:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

> Add the folder to `PATH` rather than symlinking the binary elsewhere: Tweego looks for `storyformats/` next to its own executable.

Check the installation:

```bash
tweego --version
tweego --list-formats
```

### 3. Install the required SugarCube version

Each story declares the story format version it needs in its `StoryData` passage (e.g. `"format-version": "2.37.3"`). Tweego only uses a format version **equal to or newer** than the one requested, and the SugarCube bundled with Tweego may be older.

If `tweego --list-formats` shows an older `sugarcube-2`:

1. Download SugarCube 2 (the package for Twine 2 / Tweego) from the [SugarCube downloads page](https://www.motoslave.net/sugarcube/2/#downloads).
2. Replace the bundled copy:
   ```bash
   rm -rf ~/.local/share/tweego/storyformats/sugarcube-2
   unzip ~/Downloads/sugarcube-2.37.3-for-twine-2.1-local.zip -d ~/.local/share/tweego/storyformats/
   ```
3. Make sure `~/.local/share/tweego/storyformats/sugarcube-2/format.js` exists (move the folder up one level if the zip created a wrapper folder), then run `tweego --list-formats` again.

### 4. Build the stories

Run all commands from the repository root.

**All stories**:

```bash
./build.sh
xdg-open dist/index.html
```

**A single story**:

```bash
mkdir -p dist/<story-name>
tweego -o dist/<story-name>/index.html stories/<story-name>/src
cp -r stories/<story-name>/assets dist/<story-name>/
xdg-open dist/<story-name>/index.html
```

Assets must be copied next to the compiled HTML, because stories reference them with relative paths (`assets/…`).

### 5. Watch mode while writing

Tweego can recompile automatically each time a source file changes:

```bash
tweego -w -o dist/<story-name>/index.html stories/<story-name>/src
```

Reload the browser after each save; stop with `Ctrl+C`. Watch mode does not copy assets: run the `cp` command above once, and again after adding new media.

### Troubleshooting

| Problem | Fix |
|---|---|
| `tweego: command not found` | The `PATH` line is missing or the shell wasn't reloaded (`source ~/.bashrc`, or open a new terminal). |
| Story format not found | The installed SugarCube is older than the `format-version` in `StoryData`: see step 3. |
| `Permission denied` | Run `chmod +x ~/.local/share/tweego/tweego`. |
| Images missing in the browser | The `assets/` folder wasn't copied to `dist/<story-name>/`. |