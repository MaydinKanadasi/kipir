import CryptoKit
import Foundation

/// Mac'in QR kodunda gösterdiği eşleştirme bilgisi.
///
/// Biçim: `kipir://pair?v=1&k=<base64url anahtar>&n=<Mac adı>`
public struct PairingPayload: Equatable, Sendable {
    public static let scheme = "kipir"
    public static let host = "pair"

    public var keyData: Data
    public var deviceName: String

    public init(keyData: Data, deviceName: String) {
        self.keyData = keyData
        self.deviceName = deviceName
    }

    public init(key: SymmetricKey, deviceName: String) {
        self.init(keyData: key.withUnsafeBytes { Data($0) }, deviceName: deviceName)
    }

    public var key: SymmetricKey { SymmetricKey(data: keyData) }

    public var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.queryItems = [
            URLQueryItem(name: "v", value: String(KipirConstants.protocolVersion)),
            URLQueryItem(name: "k", value: keyData.base64URLEncodedString()),
            URLQueryItem(name: "n", value: deviceName),
        ]
        return components.url!
    }

    /// QR koddan okunan metni çözer; Kıpır'a ait değilse veya bozuksa `nil`.
    public init?(string: String) {
        guard let components = URLComponents(string: string),
              components.scheme == Self.scheme,
              components.host == Self.host
        else { return nil }

        let items = components.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }

        guard value("v") == String(KipirConstants.protocolVersion),
              let encodedKey = value("k"),
              let keyData = Data(base64URLEncoded: encodedKey),
              keyData.count == KipirConstants.pairingKeyLength,
              let name = value("n"), !name.isEmpty
        else { return nil }

        self.init(keyData: keyData, deviceName: name)
    }
}

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        self.init(base64Encoded: base64)
    }
}
