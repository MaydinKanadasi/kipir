import Foundation

/// iOS ve macOS uygulamalarının ortak kullandığı sabitler.
public enum KipirConstants {
    /// Protokol sürümü. Şifrelemede ek doğrulanmış veri (AAD) olarak kullanılır;
    /// sürümü farklı iki uygulamanın paketleri birbirine açılmaz.
    public static let protocolVersion: UInt8 = 1

    /// Mac uygulamasının yayınladığı Bonjour servis tipi (hareket kanalı).
    public static let bonjourServiceType = "_kipir._udp"

    /// Hareket verisinin en yüksek gönderim sıklığı (Hz).
    public static let motionSendRate: Double = 120

    /// Onay (ACK) gelmeyen tıklama/tuş paketinin yeniden gönderilme aralığı (s).
    public static let ackRetryInterval: TimeInterval = 0.030

    /// Onay beklenen bir paket için en fazla deneme sayısı.
    public static let maxSendAttempts = 5

    /// Ping gönderim aralığı (s).
    public static let pingInterval: TimeInterval = 1.0

    /// Bu süre boyunca yanıt gelmezse bağlantı koptu sayılır (s).
    public static let connectionTimeout: TimeInterval = 3.0

    /// Eşleştirme anahtarının uzunluğu (bayt).
    public static let pairingKeyLength = 32
}
