# dn3l
Dos Navigator recreation (using LLMs, based on fpc and Free Vision)
![Screenshot](/screenshots/0002.png)
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

- Uses [Free Pascal (fpc)](https://www.freepascal.org/) — a **free, modern, and actively developed** compiler.
- **License purity**: instead of the proprietary Turbo Vision by Borland, a free alternative — [Free Vision](https://wiki.freepascal.org/Free_Vision) from fpc — is used as the base.
- **Unicode support**: a [Unicode-compatible version](https://wiki.freepascal.org/Free_Vision#Unicode_version) of Free Vision from the master branch is used. We also incorporating LazUTF8 module originating from Lazarus  source code for operations like UTF8FindNearestCharStart()
- **Hotkeys will work in any keyboard layout** (some day, at least in Kovd Goyal's [kitty, far2l](https://gitlab.com/freepascal.org/fpc/source/-/issues/40673), and probably Windows Terminal [as soon as it will be ready in FV](https://gitlab.com/freepascal.org/fpc/source/-/issues/40672); also [this issue](https://gitlab.com/freepascal.org/fpc/source/-/issues/41266) should be resolved).
- **System clipboard will be supported** (some day, at least in Kovd Goyal's kitty, far2l, and Windows Terminal — the used version of Free Vision already [supports it](https://gitlab.com/freepascal.org/fpc/source/-/issues/40671)).
- The architecture is based on the source code of the **latest DOS version** of DOS Navigator, so the code will be familiar to anyone who worked with the original DOS version or any of its later forks.
## Alternative: Porting DN OSP to FPC and FreeVision
(as it done in [dn2l](https://github.com/unxed/dn2l))

### Drawbacks:
- DN OSP uses Virtual Pascal, which is closed-source and no longer maintained. To port DN OSP directly, one would need to at least emulate the Virtual Pascal standard library and replace all constructs unsupported by fpc with supported equivalents. This alone is a significant amount of work.
- Even after that, port would still be unusable in practice because DN OSP operates internally with single-byte strings (a legacy of DOS Turbo Vision, on which it is based). Consequently, we would also have to use the non-Unicode version of FreeVision, meaning we could only work with files that have Latin names.
- Okay, so we decide to port directly to Unicode FreeVision, adding encoding conversions where needed. But this same approach can be taken with dn3l, gradually migrating functionality from DN OSP. The key advantage of dn3l is that, unlike a direct port, it can run and work at every stage, which adds motivation and allows debugging in small increments. With a direct port, the entire codebase must be ported before anything works, and we can only _hope_ it runs correctly at the end. And when it doesn’t, we’ll have to spend even more effort just to get it to start up.
## Hacking
NB! FreeVision Unicode uses UnicodeString type that has UTF-16 inside. Most of modern UNIX-like operating systems use UTF-8 by default (and even modern Windows versions support it as console "ASCII" charset), so when developing DN3L we proceed from the fact that in variables of the String type we have exactly this charset. To avoid frequent charset conversions, we are adding LazUTF8 module which does all needed UTF8<>UTF16 conversions automatically and can work as a bridge between the worlds (this module is made of several Lazarus modules merged together). Don't worry about performance: [far2l](https://github.com/elfmz/far2l/) does exactly the same and no one ever noticed any performance problems: modern CPUs are fast enough.

DN does not use Object Pascal syntax, so we do not use it either.

Most of Free Vision Unicode units have U prefix, like UViews. Please note that Free Vision does not have UObjects unit, use Objects unit instead.
## LLM prompts (feel free to fork)
1. [Initial one](https://aistudio.google.com/app/prompts?state=%7B%22ids%22:%5B%221GQ9l2sUkHcqpOxEbw1uAjctHS68IKHUk%22%5D,%22action%22:%22open%22,%22userId%22:%22115224561273124777276%22,%22resourceKeys%22:%7B%7D%7D&usp=sharing)
## Full list of related fpc issues
- https://gitlab.com/freepascal.org/fpc/source/-/issues/40671
- https://gitlab.com/freepascal.org/fpc/source/-/issues/40672
- https://gitlab.com/freepascal.org/fpc/source/-/issues/40673
- https://gitlab.com/freepascal.org/fpc/source/-/issues/41266
- https://gitlab.com/freepascal.org/fpc/source/-/issues/41268
- https://gitlab.com/freepascal.org/fpc/source/-/issues/41269
## Why "3l"?
"l" is for Linux and 3 sounds similar to "free"
