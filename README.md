# Gorgon - Hybrid Dual-Cipher Encryption Library

[![License: MIT](https://img.shields.io/badge/License-MIT-333333.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-B10C1A)](https://github.com/winzox/gorgon/releases)
[![Build: CMake](https://img.shields.io/badge/build-CMake%20%7C%20Ninja-blue.svg)](CMakeLists.txt)
[![Language: C99 / Wyrm](https://img.shields.io/badge/language-C99%20%7C%20Wyrm-orange.svg)](src/)

**Gorgon** is an open-source, high-security symmetric encryption library designed on a defense-in-depth **Dual-Cipher Split** architecture. It combines two of the world's most rigorously analyzed ciphers:
- **AES-256-CBC** (NIST FIPS 197)
- **Serpent-256-CBC** (AES Finalist, 32-round ultra-high security margin)

Gorgon is completely self-contained with **zero external dependencies** (similar to zlib), builds into a native shared library (`gorgon.dll` / `libgorgon.so`), and provides seamless integration with the **Wyrm** programming language.

---

## 1. Key Features

- **Dual-Engine Symmetric Security**: Plaintext is partitioned and encrypted using two distinct mathematical algorithms. Breaking one cipher provides zero advantage toward breaking the other.
- **Independent Key Derivations**: AES and Serpent keys are derived independently using PBKDF2-HMAC-SHA256 with non-linear salt mutation.
- **Zero External Dependencies**: Standalone implementation of AES-256, Serpent-256, and SHA-256 KDF. No need to install or configure OpenSSL or Nettle.
- **Cross-Language Support**:
  - Clean C99 Public Header ([include/gorgon.h](include/gorgon.h)) for C, C++, Rust, Go.
  - Python interoperability via `ctypes`.
  - Native **Wyrm** package ([src/gorgon.wyr](src/gorgon.wyr)) with direct `std.ffi` calling convention.
- **Stand-alone CLI**: `gorgon-tool` utility for encrypting and decrypting files from the command line.

---

## 2. Directory Layout

```text
gorgon/
├── CMakeLists.txt             # CMake multi-target build system
├── wyrpkg.toml                # Wyrm package manager configuration
├── LICENSE                    # MIT Open-Source License
├── README.md                  # This documentation
├── include/
│   └── gorgon.h               # Public C API header
├── src/
│   ├── gorgon.c               # Core Gorgon dual-cipher implementation
│   ├── gorgon_aes.c / .h      # Self-contained AES-256 engine
│   ├── gorgon_serpent.c / .h  # Self-contained Serpent-256 engine
│   ├── gorgon_kdf.c / .h      # PBKDF2-HMAC-SHA256 key derivation
│   ├── wyrm_bridge.c          # Wyrm Extension ABI bridge
│   └── gorgon.wyr             # Wyrm native module
├── doc/
│   ├── ALGORITHM.md           # Cryptographic specification & math
│   └── API.md                 # Complete API reference
├── examples/
│   ├── example_c.c            # C usage example
│   ├── example_wyrm.wyr       # Wyrm usage example
│   └── example_python.py      # Python ctypes example
└── utils/
    └── gorgon_cli.c           # Command-line file encryption utility
```

---

## 3. Building Gorgon

### Windows (GCC / MinGW / MSYS2 UCRT64 + Ninja)

```powershell
# 1. Configure build with CMake
cmake -S . -B build -G Ninja -DCMAKE_C_COMPILER=gcc

# 2. Compile shared library (gorgon.dll), examples, and CLI
cmake --build build
```

The build produces:
- `build/gorgon.dll` (Shared Library)
- `build/libgorgon.dll.a` (Import Library)
- `build/libgorgon_static.a` (Static Library)
- `build/gorgon_example_c.exe` (C Demo Program)
- `build/gorgon-tool.exe` (CLI Utility)

---

## 4. Usage Examples

### C Usage

```c
#include <gorgon.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    GorgonMetadata meta;
    GorgonBuffer cipher, plain;
    const char* secret = "Confidential data";
    const char* pass = "MyStrongPassword";

    // Generate random Salt and IVs
    gorgon_create_metadata(&meta, 50000, NULL, 0);

    // Encrypt
    gorgon_encrypt((const uint8_t*)secret, strlen(secret), pass, &meta, &cipher, NULL, 0);

    // Decrypt
    gorgon_decrypt(cipher.data, cipher.size, pass, &meta, strlen(secret), &plain, NULL, 0);
    printf("Decrypted: %.*s\n", (int)plain.size, (char*)plain.data);

    // Clean up
    gorgon_free_buffer(&cipher);
    gorgon_free_buffer(&plain);
    return 0;
}
```

### Wyrm Usage

```wyrm
use src.gorgon;

fn main() {
    gorgon_init("gorgon.dll")

    var secret = "Top Secret Message"
    var password = "WyrmPassword2026"

    var pkg = gorgon_encrypt_text(secret, password)
    print("Encrypted payload:", pkg.cipher_hex)

    var decrypted = gorgon_decrypt_text(pkg, password)
    print("Decrypted message:", decrypted)
}
```

### Command-Line Utility (`gorgon-tool`)

```bash
# Encrypt a file
gorgon-tool enc document.pdf document.pdf.gorgon "MasterPassphrase" 50000

# Decrypt a file
gorgon-tool dec document.pdf.gorgon restored_document.pdf "MasterPassphrase"
```

---

## 5. Cryptographic Design

For in-depth mathematical proofs, state transformations, and security bounds, see [doc/ALGORITHM.md](doc/ALGORITHM.md).

---
