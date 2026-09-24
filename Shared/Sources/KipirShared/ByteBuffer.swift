import Foundation

/// Tamsayıları ağ bayt sırasıyla (big-endian) yazar.
struct ByteWriter {
    private(set) var bytes: [UInt8] = []

    init(capacity: Int = 32) {
        bytes.reserveCapacity(capacity)
    }

    mutating func write<T: FixedWidthInteger & UnsignedInteger>(_ value: T) {
        withUnsafeBytes(of: value.bigEndian) { bytes.append(contentsOf: $0) }
    }

    mutating func write(_ value: Float) {
        write(value.bitPattern)
    }

    var data: Data { Data(bytes) }
}

/// `ByteWriter` ile yazılan veriyi okur; eksik veri için hata fırlatır.
struct ByteReader {
    private let bytes: [UInt8]
    private var offset = 0

    init(_ data: Data) {
        bytes = [UInt8](data)
    }

    var remaining: Int { bytes.count - offset }

    mutating func read<T: FixedWidthInteger & UnsignedInteger>(_: T.Type = T.self) throws -> T {
        let size = MemoryLayout<T>.size
        guard remaining >= size else { throw PacketCodingError.truncated }
        var value: T = 0
        for byte in bytes[offset..<offset + size] {
            value = value << 8 | T(byte)
        }
        offset += size
        return value
    }

    /// Sonlu (NaN veya sonsuz olmayan) bir Float okur.
    mutating func readFiniteFloat() throws -> Float {
        let value = Float(bitPattern: try read(UInt32.self))
        guard value.isFinite else { throw PacketCodingError.invalidValue }
        return value
    }
}
