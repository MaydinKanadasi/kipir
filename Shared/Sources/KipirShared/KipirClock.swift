import Foundation

public enum KipirClock {
    /// Monoton saat, mikrosaniye. Cihazlar arası karşılaştırılamaz; gecikme
    /// ping/pong ile aynı cihazda ölçülen gidiş-dönüş süresinden hesaplanır.
    public static func nowMicroseconds() -> UInt64 {
        DispatchTime.now().uptimeNanoseconds / 1_000
    }
}

/// Gönderilen paketler için artan sıra numarası üretir.
public struct SequenceCounter: Sendable {
    private var current: UInt32

    public init(startingAt first: UInt32 = 1) {
        current = first &- 1
    }

    public mutating func next() -> UInt32 {
        current &+= 1
        return current
    }
}
