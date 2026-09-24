import CryptoKit
import Foundation

public enum PacketCipherError: Error, Equatable {
    case invalidKeyLength
}

/// Paketleri ChaCha20-Poly1305 ile şifreler ve doğrular.
///
/// Şifreli paket: `nonce (12) + şifreli veri + etiket (16)`, yani düz pakete
/// göre `overhead` bayt fazladır. Nonce her pakette rastgele üretilir.
public struct PacketCipher {
    public static let overhead = 12 + 16

    private static let associatedData = Data("kipir".utf8) + [KipirConstants.protocolVersion]

    private let key: SymmetricKey

    public init(key: SymmetricKey) throws {
        guard key.bitCount == KipirConstants.pairingKeyLength * 8 else {
            throw PacketCipherError.invalidKeyLength
        }
        self.key = key
    }

    public init(keyData: Data) throws {
        try self.init(key: SymmetricKey(data: keyData))
    }

    /// Eşleştirme için yeni rastgele 256 bit anahtar üretir.
    public static func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    public func seal(_ plaintext: Data) throws -> Data {
        try ChaChaPoly.seal(plaintext, using: key, authenticating: Self.associatedData).combined
    }

    /// Doğrulama başarısızsa (yanlış anahtar, değiştirilmiş paket) hata fırlatır.
    public func open(_ sealed: Data) throws -> Data {
        let box = try ChaChaPoly.SealedBox(combined: sealed)
        return try ChaChaPoly.open(box, using: key, authenticating: Self.associatedData)
    }

    public func seal(_ packet: Packet) throws -> Data {
        try seal(packet.encoded())
    }

    public func openPacket(_ sealed: Data) throws -> Packet {
        try Packet(decoding: open(sealed))
    }
}
