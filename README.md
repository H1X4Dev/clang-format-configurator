# clang-format-configurator
Interactively create a clang-format configuration while watching how the changes affect your code.
See it in action at http://zed0.co.uk/clang-format-configurator

## Requirements
All requirements should be available through your package manager:
* [Node.js](https://nodejs.org/en)
* [firejail](https://github.com/netblue30/firejail) (assuming you want to sandbox the process)
* Ubuntu 20.04
  * for Windows, please use WSL 2.0

## Installation
The setup script will install the various npm and bower dependencies and then download the clang-format binaries and documentation from the [official releases](http://llvm.org/releases/download.html).
If you want to disable some versions, or add new ones, alter the `clang_versions` variable at the top of `setup.sh`. To setup clang with system binaries for fresh installation use the [official automatic installation script](https://apt.llvm.org/).

```
chmod u+x setup.sh
./setup.sh
```

## Usage
With Node.js:
```
npm start
```

With firejail:
```
server/launch.sh
```

## History
Version 0.0.4
- Node Packages have been updated.
- Removed `userid` package as it was not used.
- Hardcoded the use to 15.x (15.0.7) WSL.
  * This means that you must set it up using the LLVM script and choose 15 as your version. If you would like to use 16 instead of 15, modify `setup.sh` accordingly.
- Improved option handling when `:versionbadge` is present.
- Improved option handling for newer versions.

Version 0.0.3

## Credits
Author: Ben Falconer

## License
MIT
