# KipirShared

Kıpır iOS ve macOS uygulamalarının ortak kullandığı Swift paketi: mesaj formatı, şifreleme, tekrar koruması ve eşleştirme.

| Dosya | İçerik |
| --- | --- |
| `Packet.swift` | Mesaj tipleri ve ikili kodlama/çözme |
| `PacketCipher.swift` | ChaCha20-Poly1305 ile şifreleme ve doğrulama (CryptoKit) |
| `ReplayWindow.swift` | Sıra numarasıyla tekrar saldırısı koruması (64 paketlik kayan pencere) |
| `PairingPayload.swift` | QR kod içeriği: `kipir://pair?v=1&k=<anahtar>&n=<Mac adı>` |
| `KipirClock.swift` | Mikrosaniye zaman damgası, sıra numarası sayacı |
| `KipirConstants.swift` | Bonjour servis tipi, zaman aşımları, gönderim sıklığı |

## Paket formatı

Tüm alanlar big-endian.

| Alan | Boyut | Açıklama |
| --- | --- | --- |
| Tip | 1 bayt | `0x01` hareket, `0x02` tıklama, `0x03` scroll, `0x04` tuş, `0x05` ping, `0x06` ACK, `0x07` pong |
| Sıra no | 4 bayt | Artan sayaç |
| Zaman damgası | 8 bayt | Gönderim anı (µs, monoton saat) |
| Veri | 0–12 bayt | Tipe göre, aşağıda |

| Tip | Veri |
| --- | --- |
| Hareket / scroll | `dx`, `dy` — Float32 (8 bayt) |
| Tıklama | buton (sol/sağ/orta), faz (down/up), tık sayısı — 3 bayt |
| Tuş | Unicode karakter — UInt32 |
| Ping | — |
| ACK | onaylanan sıra no — UInt32 |
| Pong | ping'in sıra no'su + zaman damgası — 12 bayt |

Hareket paketi 21 bayt, şifrelenince 49 bayttır (+12 nonce, +16 etiket).

## Kullanım

```swift
import KipirShared

// Mac: eşleştirme anahtarı üret, QR olarak göster
let key = PacketCipher.generateKey()
let qrText = PairingPayload(key: key, deviceName: Host.current().localizedName ?? "Mac").url.absoluteString

// iPhone: QR'ı çöz, paket gönder
guard let pairing = PairingPayload(string: scannedText) else { return }
let cipher = try PacketCipher(key: pairing.key)
var sequence = SequenceCounter()
let datagram = try cipher.seal(Packet(sequence: sequence.next(), message: .move(dx: 4, dy: -2)))

// Mac: aç, doğrula, tekrarları ele
var replay = ReplayWindow()
let packet = try cipher.openPacket(datagram)
guard replay.accept(packet.sequence) else { return }
```

## Testler

```bash
cd Shared
swift test
```
