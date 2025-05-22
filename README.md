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
## Reasons
This can be considered an experiment to determine whether it's possible to recreate Dos Navigator using a modern software stack with Unicode support. It is also an experiment in source code analysis and software development using large language models. Jet another goal is to popularize in the free software world rich console applications with UX not inferior to the Windows console ones.
## Advantages

- Uses **fpc** — a free, modern, and actively developed compiler.
- **License purity**: instead of the proprietary Turbo Vision by Borland, a free alternative — **Free Vision** from fpc — is used as the base.
- **Unicode support**: a Unicode-compatible version of Free Vision from the master branch is used.
- **Hotkeys work in any keyboard layout** (at least in Kovd Goyal's kitty, far2l, and Windows Terminal; one blocker still exist [on Free Vision side]https://gitlab.com/freepascal.org/fpc/source/-/issues/41266).
- **Planned support for the system clipboard** (at least in Kovd Goyal's kitty, far2l, and Windows Terminal — the used version of Free Vision already supports it).
- The architecture is based on the source code of the **latest DOS version** of DOS Navigator, so the code will be familiar to anyone who worked with the original DOS version or any of its later forks.
## Hacking
NB! FreeVision Unicode uses UnicodeString type that has UTF-16 inside. Most of modern free operating systems use UTF-8 by default (and even modern Windows versions support it as console "ASCII" charset), so when developing DN3L we proceed from the fact that in variables of the String type we have exactly this charset. And be ready to use UTF8ToUTF16() or UTF16ToUTF8() often as bridges between the worlds. Don't worry about performance: [far2l](https://github.com/elfmz/far2l/) does exactly the same and no one ever noticed any performance problems: modern CPUs are fast enough.
## LLM prompts (feel free to fork)
1. [Initial one](https://aistudio.google.com/app/prompts?state=%7B%22ids%22:%5B%221rbRS_ZbP-y6JhQaZJGEKY2G8hsc8hWEu%22%5D,%22action%22:%22open%22,%22userId%22:%22115224561273124777276%22,%22resourceKeys%22:%7B%7D%7D&usp=sharing)
## Why "3l"?
"l" is for Linux and 3 sounds similar to "free"
