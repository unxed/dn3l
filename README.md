# dn3l
Dos Navigator recreation (using LLMs, based on fpc and Free Vision)
## How to build (Ubuntu 24.04+)
```
sudo apt install fpc
git clone https://gitlab.com/freepascal.org/fpc/source.git
cd source/packages/fv
git clone https://github.com/unxed/dn3l.git
cd dn3l
./build.sh
```
## LLM prompt (feel free to fork)
https://aistudio.google.com/app/prompts?state=%7B%22ids%22:%5B%221rbRS_ZbP-y6JhQaZJGEKY2G8hsc8hWEu%22%5D,%22action%22:%22open%22,%22userId%22:%22115224561273124777276%22,%22resourceKeys%22:%7B%7D%7D&usp=sharing
## Advantages

- Uses **fpc** — a free, modern, and actively developed compiler.
- **License purity**: instead of the proprietary Turbo Vision by Borland, a free alternative — **Free Vision** from fpc — is used as the base.
- **Unicode support**: a Unicode-compatible version of Free Vision from the master branch is used.
- **Hotkeys work in any keyboard layout** (at least in Kovd Goyal's kitty, far2l, and Windows Terminal).
- **Planned support for the system clipboard** (at least in Kovd Goyal's kitty, far2l, and Windows Terminal — the used version of Free Vision already supports it).
- The architecture is based on the source code of the **latest DOS version** of DOS Navigator, so the code will be familiar to anyone who worked with the original DOS version or any of its later forks.
