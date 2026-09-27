# Prompt Collector for Draw Things

A small, offline macOS Finder Quick Action that copies the **positive prompt**
from one or more Draw Things PNG images.

- Select one image: its prompt is copied as plain text.
- Select several images: unique prompts are copied as a Dynamic Prompts choice,
  for example `{a red fox|a grey wolf|a small castle}`.
- The first occurrence wins, so the Finder selection order is kept.
- Files without Draw Things metadata are ignored safely.

It deliberately does **not** copy settings, models, seeds, or negative prompts.
Draw Things already has an excellent “Load Settings?” flow for that job.

## Requirements

- macOS (the script uses the built-in `pbcopy` clipboard command)
- Python 3, included with current macOS developer tools or installable from
  [python.org](https://www.python.org/downloads/macos/)
- PNG images exported by Draw Things

No package, network request, or account is needed after installation.

## Install

1. Download this repository as a ZIP from GitHub and unzip it somewhere you
   will keep it, for example `~/Applications/Prompt-Collector`.
2. In Terminal, make the script executable (adapt the path if needed):

   ```sh
   chmod +x ~/Applications/Prompt-Collector/prompt_collector.py
   ```

3. Open **Automator** → **New Document** → **Quick Action**.
4. Set “Workflow receives current” to **image files** in **Finder**.
5. Add **Run Shell Script**. Set “Pass input” to **as arguments**, then use:

   ```sh
   "$HOME/Applications/Prompt-Collector/prompt_collector.py" "$@"
   ```

6. Save it as **Prompt Collector (Draw Things)**.

Select one or more images in Finder, then choose **Quick Actions → Prompt
Collector (Draw Things)**. The result is immediately in the clipboard.

## Test in Terminal

```sh
~/Applications/Prompt-Collector/prompt_collector.py ~/Desktop/example.png
```

For multiple images, put all file paths after the command. The script reports
how many images and unique prompts it found; Finder still performs the copy
silently.

## Notes

If every selected Draw Things image has the same prompt, it copies that one
plain prompt rather than the redundant `{prompt}` form. Prompts are de-duplicated
only when their trimmed text is exactly identical.

This is an independent community utility, not an official Draw Things product.

## License

[MIT](LICENSE)
