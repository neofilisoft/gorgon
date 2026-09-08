# Gorgon Cryptographic Algorithm Specification

## 1. Overview & Architecture

Gorgon is a high-security defense-in-depth symmetric cipher designed to provide robust security against cryptanalytic breakthroughs in any single block cipher.

Instead of relying on a single encryption standard, Gorgon utilizes a **Hybrid Dual-Cipher Split** architecture combining two of the most thoroughly analyzed and vetted block ciphers in modern cryptography:
- **AES-256** (Rijndael, FIPS 197)
- **Serpent-256** (Ross Anderson, Eli Biham, Lars Knudsen - First Runner-Up in the NIST AES competition, known for its exceptionally high security margin with 32 full rounds)

```text
                           [ Plaintext Data (N bytes) ]
                                        |
                 +----------------------+----------------------+
                 |                                             |
       [ First Half (0..N/2) ]                       [ Second Half (N/2..N) ]
                 |                                             |
         (PKCS#7 Padding)                              (PKCS#7 Padding)
                 |                                             |
           [ AES-256-CBC ]                              [ Serpent-256-CBC ]
           Primary Key                                   Secondary Key
           Primary IV                                    Secondary IV
                 |                                             |
                 +----------------------+----------------------+
                                        |
                           [ Concatenated Ciphertext ]
```

---

## 2. Key Derivation & Salt Mutation

Gorgon derives independent 256-bit cryptographic keys for AES and Serpent from the master passphrase using PBKDF2-HMAC-SHA256 (RFC 8018) with a minimum of 50,000 iterations:

1. **Primary Salt**: 16 bytes of cryptographically secure pseudo-random entropy generated via the OS CSPRNG (`CryptGenRandom` / `/dev/urandom`).
2. **Primary Key ($K_{AES}$)**:
   $$K_{AES} = \text{PBKDF2-HMAC-SHA256}(\text{Password}, \text{Salt}_{Primary}, \text{Iterations}, 32)$$
3. **Secondary Salt Mutation**: The secondary salt is derived from the primary salt via byte-order inversion and non-linear permutation:
   $$\text{Salt}_{Secondary}[i] = \text{Salt}_{Primary}[15 - i] \oplus (0x5A + i)$$
4. **Secondary Key ($K_{Serpent}$)**:
   $$K_{Serpent} = \text{PBKDF2-HMAC-SHA256}(\text{Password}, \text{Salt}_{Secondary}, \text{Iterations}, 32)$$

This guarantees that:
- $K_{AES} \neq K_{Serpent}$ even with identical passwords.
- A compromise of one key schedule yields zero mathematical advantage in determining the other key schedule.

---

## 3. Block Cipher Specifications

### AES-256-CBC
- **Block Size**: 128 bits (16 bytes)
- **Key Size**: 256 bits (32 bytes)
- **Rounds**: 14 rounds
- **Chaining**: CBC (Cipher Block Chaining) mode with $\text{IV}_{Primary}$
- **Padding**: PKCS#7

### Serpent-256-CBC
- **Block Size**: 128 bits (16 bytes)
- **Key Size**: 256 bits (32 bytes)
- **Rounds**: 32 rounds (8 S-Boxes: $S_0$ through $S_7$, evaluated 4 times each with bitslice Boolean logic and linear transformations)
- **Chaining**: CBC mode with $\text{IV}_{Secondary}$
- **Padding**: PKCS#7

---

## 4. Decryption & Boundary Calculation

Because PKCS#7 padding appends between 1 and 16 bytes per block cipher half, the exact boundary between the two cipher halves in the ciphertext stream can be determined deterministically given the original unencrypted size $S$:

$$S_{FirstHalf} = \lfloor S / 2 \rfloor$$
$$\text{CipherSize}_{FirstHalf} = (\lfloor S_{FirstHalf} / 16 \rfloor + 1) \times 16$$

The first $\text{CipherSize}_{FirstHalf}$ bytes are decrypted with AES-256-CBC and validated. The remainder of the ciphertext is decrypted with Serpent-256-CBC and validated. Finally, both plaintext buffers are merged to reproduce the exact original data.

---

## 5. Security Properties

1. **Dual-Break Resistance**: To breach the privacy of the complete message, an adversary must break **both** AES-256 and Serpent-256. If either cipher is hypothetically compromised or weakened by algebraic attacks, the remaining half of the data remains mathematically secure.
2. **Independent IVs**: Both halves utilize independent 128-bit Initialization Vectors, preventing identical ciphertext patterns across multiple encryptions of identical inputs.
3. **No External Library Dependencies**: The core algorithms are self-contained, avoiding supply-chain tampering and library bloat.
