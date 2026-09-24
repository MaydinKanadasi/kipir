import Foundation

/// Paketin ilk baytı: mesaj tipi.
public enum MessageType: UInt8, Sendable, CaseIterable {
    case move = 0x01
    case click = 0x02
    case scroll = 0x03
    case key = 0x04
    case ping = 0x05
    case ack = 0x06
    case pong = 0x07
}

public enum MouseButton: UInt8, Sendable, CaseIterable {
    case left = 0
    case right = 1
    case middle = 2
}

public enum ButtonPhase: UInt8, Sendable, CaseIterable {
    case down = 0
    case up = 1
}

/// Tek bir fare butonu olayı. Tıklama = `down` + `up` çifti; sürükleme için
/// arada hareket paketleri gönderilir. `clickCount` çift tıkta 2 olur
/// (macOS tarafında `CGEvent` `clickState` alanına yazılır).
public struct ClickEvent: Equatable, Sendable {
    public var button: MouseButton
    public var phase: ButtonPhase
    public var clickCount: UInt8

    public init(button: MouseButton, phase: ButtonPhase, clickCount: UInt8 = 1) {
        self.button = button
        self.phase = phase
        self.clickCount = clickCount
    }
}

/// Paketin taşıdığı mesaj.
public enum Message: Equatable, Sendable {
    /// İmleç deltası (piksel). Filtre ve hassasiyet iPhone'da uygulanmış olarak gelir.
    case move(dx: Float, dy: Float)
    case click(ClickEvent)
    /// Kaydırma deltası (piksel).
    case scroll(dx: Float, dy: Float)
    /// iOS klavyesinden gelen tek bir Unicode karakteri (geri silme 0x08, enter 0x0D).
    case key(scalar: UInt32)
    case ping
    /// `sequence` numaralı paketin alındığını bildirir.
    case ack(sequence: UInt32)
    /// Ping'e yanıt; RTT hesabı için ping'in sıra numarası ve zaman damgası geri yollanır.
    case pong(pingSequence: UInt32, pingTimestamp: UInt64)

    public var type: MessageType {
        switch self {
        case .move: .move
        case .click: .click
        case .scroll: .scroll
        case .key: .key
        case .ping: .ping
        case .ack: .ack
        case .pong: .pong
        }
    }

    /// Kaybolması kullanıcı tarafından fark edilen mesajlar ACK ile güvenceye alınır.
    public var requiresAck: Bool {
        switch self {
        case .click, .key: true
        default: false
        }
    }
}

public enum PacketCodingError: Error, Equatable {
    case truncated
    case unknownMessageType(UInt8)
    case invalidValue
    case trailingBytes
}

/// Ağ üzerinden giden tek paket.
///
/// İkili format (big-endian):
///
/// | Alan         | Boyut  |
/// |--------------|--------|
/// | Tip          | 1 bayt |
/// | Sıra no      | 4 bayt |
/// | Zaman damgası| 8 bayt (µs) |
/// | Veri         | 0–12 bayt, tipe göre |
public struct Packet: Equatable, Sendable {
    public static let headerSize = 13

    public var sequence: UInt32
    /// Gönderim anı, mikrosaniye (`KipirClock.nowMicroseconds()`).
    public var timestamp: UInt64
    public var message: Message

    public init(sequence: UInt32, timestamp: UInt64 = KipirClock.nowMicroseconds(), message: Message) {
        self.sequence = sequence
        self.timestamp = timestamp
        self.message = message
    }

    public func encoded() -> Data {
        var writer = ByteWriter()
        writer.write(message.type.rawValue)
        writer.write(sequence)
        writer.write(timestamp)

        switch message {
        case let .move(dx, dy), let .scroll(dx, dy):
            writer.write(dx)
            writer.write(dy)
        case let .click(event):
            writer.write(event.button.rawValue)
            writer.write(event.phase.rawValue)
            writer.write(event.clickCount)
        case let .key(scalar):
            writer.write(scalar)
        case .ping:
            break
        case let .ack(acked):
            writer.write(acked)
        case let .pong(pingSequence, pingTimestamp):
            writer.write(pingSequence)
            writer.write(pingTimestamp)
        }
        return writer.data
    }

    public init(decoding data: Data) throws {
        var reader = ByteReader(data)
        let rawType = try reader.read(UInt8.self)
        guard let type = MessageType(rawValue: rawType) else {
            throw PacketCodingError.unknownMessageType(rawType)
        }
        sequence = try reader.read()
        timestamp = try reader.read()

        switch type {
        case .move:
            message = .move(dx: try reader.readFiniteFloat(), dy: try reader.readFiniteFloat())
        case .scroll:
            message = .scroll(dx: try reader.readFiniteFloat(), dy: try reader.readFiniteFloat())
        case .click:
            guard let button = MouseButton(rawValue: try reader.read()),
                  let phase = ButtonPhase(rawValue: try reader.read())
            else { throw PacketCodingError.invalidValue }
            let clickCount: UInt8 = try reader.read()
            guard clickCount > 0 else { throw PacketCodingError.invalidValue }
            message = .click(ClickEvent(button: button, phase: phase, clickCount: clickCount))
        case .key:
            let scalar: UInt32 = try reader.read()
            guard Unicode.Scalar(scalar) != nil else { throw PacketCodingError.invalidValue }
            message = .key(scalar: scalar)
        case .ping:
            message = .ping
        case .ack:
            message = .ack(sequence: try reader.read())
        case .pong:
            message = .pong(pingSequence: try reader.read(), pingTimestamp: try reader.read())
        }

        guard reader.remaining == 0 else { throw PacketCodingError.trailingBytes }
    }
}
