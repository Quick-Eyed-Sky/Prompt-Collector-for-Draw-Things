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

## Install

No Terminal commands and no Automator setup are required.

1. Download the latest release from the **Releases** section on the right of
   this GitHub page. Do not use the green **Code** button.
2. Double-click the downloaded ZIP; macOS creates a folder next to it.
3. Open that folder and double-click **Install Prompt Collector.command**.
4. A small Terminal window confirms that it is installed. Press Return to
   close it.

If macOS says the installer cannot be opened because it is from an unidentified
developer, Control-click it, choose **Open**, then choose **Open** again. This
is expected for an unsigned, open-source utility.

Select one or more images in Finder, then choose **Quick Actions → Prompt
Collector (Draw Things)**. The result is immediately in the clipboard.

## Requirements

- macOS
- PNG images exported by Draw Things
- Python 3 (included with current macOS developer tools; the installer will
  explain if it is unavailable)

## Notes

If every selected Draw Things image has the same prompt, it copies that one
plain prompt rather than the redundant `{prompt}` form. Prompts are de-duplicated
only when their trimmed text is exactly identical.

This is an independent community utility, not an official Draw Things product.

## License

[MIT](LICENSE)
