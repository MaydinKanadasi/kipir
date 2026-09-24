/// Tekrar saldırısı (replay) koruması için kayan pencere.
///
/// Görülen en yüksek sıra numarası ve ondan önceki `size` numara takip edilir.
/// UDP paketleri sırasız gelebildiği için pencere içindeki eski ama ilk kez
/// görülen numaralar kabul edilir; pencerenin gerisinde kalanlar ve tekrarlar
/// reddedilir.
///
/// `accept(_:)` yalnızca şifre doğrulaması başarılı olan paketler için
/// çağrılmalıdır; aksi halde sahte paketler pencereyi ileri kaydırabilir.
public struct ReplayWindow: Sendable {
    public static let size: UInt32 = 64

    private var highest: UInt32?
    /// i. bit: `highest - i` numaralı paket görüldü.
    private var seen: UInt64 = 0

    public init() {}

    /// Paket yeni ise kaydeder ve `true` döner; tekrar veya çok eskiyse `false`.
    public mutating func accept(_ sequence: UInt32) -> Bool {
        guard let highest else {
            self.highest = sequence
            seen = 1
            return true
        }

        if sequence > highest {
            let shift = sequence - highest
            seen = shift >= Self.size ? 1 : (seen << UInt64(shift)) | 1
            self.highest = sequence
            return true
        }

        let offset = highest - sequence
        guard offset < Self.size else { return false }
        let mask: UInt64 = 1 << UInt64(offset)
        guard seen & mask == 0 else { return false }
        seen |= mask
        return true
    }

    /// Yeni oturumda (yeniden eşleşme/bağlanma) pencereyi sıfırlar.
    public mutating func reset() {
        highest = nil
        seen = 0
    }
}
