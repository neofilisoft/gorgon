# Gorgon Library API Reference

## 1. C Public API

Header file: `#include <gorgon.h>`

### Data Types

#### `GorgonStatus`
Enumeration of status and error return codes:
- `GORGON_STATUS_OK (0)`: Operation succeeded.
- `GORGON_STATUS_INVALID_ARGUMENT (1)`: Null pointer or invalid argument passed.
- `GORGON_STATUS_OPERATION_FAILED (2)`: Cryptographic operation or system call failed.
- `GORGON_STATUS_BUFFER_TOO_SMALL (3)`: Destination buffer insufficient.
- `GORGON_STATUS_AUTH_FAILED (4)`: Decryption authentication failed (corrupted data or wrong password).
- `GORGON_STATUS_OUT_OF_MEMORY (5)`: Memory allocation failed.

#### `GorgonMetadata`
Cryptographic parameters struct:
```c
typedef struct GorgonMetadata {
    uint8_t salt[16];           // 16-byte random salt
    uint8_t iv_primary[16];     // 16-byte AES-256-CBC IV
    uint8_t iv_secondary[16];   // 16-byte Serpent-256-CBC IV
    uint32_t iterations;        // PBKDF2 iteration count (default 50,000)
} GorgonMetadata;
```

#### `GorgonBuffer`
Dynamically allocated byte buffer:
```c
typedef struct GorgonBuffer {
    uint8_t* data;
    size_t size;
} GorgonBuffer;
```

---

### Functions

#### `gorgon_version`
```c
const char* gorgon_version(void);
```
Returns static library version string (e.g. `"1.0.0"`).

#### `gorgon_create_metadata`
```c
GorgonStatus gorgon_create_metadata(
    GorgonMetadata* out_metadata,
    uint32_t iterations,
    char* error_buffer,
    size_t error_buffer_size);
```
Populates `out_metadata` with fresh CSPRNG random bytes. Pass `0` for `iterations` to use the default of 50,000.

#### `gorgon_encrypt`
```c
GorgonStatus gorgon_encrypt(
    const uint8_t* plain_data,
    size_t plain_size,
    const char* password,
    const GorgonMetadata* metadata,
    GorgonBuffer* out_cipher,
    char* error_buffer,
    size_t error_buffer_size);
```
Encrypts `plain_data` using the Gorgon dual-cipher. Allocates `out_cipher->data`. Must be freed with `gorgon_free_buffer`.

#### `gorgon_decrypt`
```c
GorgonStatus gorgon_decrypt(
    const uint8_t* cipher_data,
    size_t cipher_size,
    const char* password,
    const GorgonMetadata* metadata,
    uint64_t expected_plain_size,
    GorgonBuffer* out_plain,
    char* error_buffer,
    size_t error_buffer_size);
```
Decrypts `cipher_data`. Verifies PKCS#7 padding and length matches `expected_plain_size`. Allocates `out_plain->data`. Must be freed with `gorgon_free_buffer`.

#### `gorgon_free_buffer`
```c
void gorgon_free_buffer(GorgonBuffer* buffer);
```
Frees memory allocated in `buffer->data` and zeroes `buffer->size`.

---

## 2. Wyrm API (`src.gorgon`)

Module file: `use src.gorgon;`

### Functions

- `gorgon_init(dll_path: string): bool`: Loads `gorgon.dll`. Pass `null` for auto-discovery.
- `gorgon_version(): string`: Returns the native library version.
- `gorgon_encrypt_text(text: string, password: string): GorgonPackage`: Encrypts text and returns a `GorgonPackage` struct.
- `gorgon_decrypt_text(pkg: GorgonPackage, password: string): string`: Decrypts `GorgonPackage` back to plaintext.
- `gorgon_encrypt_file(source: string, dest: string, password: string): bool`: Encrypts file to disk in JSON container format.
- `gorgon_decrypt_file(source: string, dest: string, password: string): bool`: Decrypts JSON container format to original file on disk.
