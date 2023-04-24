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
- Update node packages.
- Remove `userid` package.
- Hardcoded to use 15.x version, when setting up using LLVM script, choose 15 as your version. If you want to use 16, you can, just modify setup.sh (15.x to 16.x).

Version 0.0.3

## Credits
Author: Ben Falconer

## License
MIT
