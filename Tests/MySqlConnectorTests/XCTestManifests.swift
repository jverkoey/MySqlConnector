import XCTest

extension HandshakeDecodingTests {
    static let __allTests = [
        ("testShortv10HandshakeSucceeds", testShortv10HandshakeSucceeds),
        ("testThrowsWithEmptyData", testThrowsWithEmptyData),
        ("testThrowsWithUnsupportedProtocol", testThrowsWithUnsupportedProtocol),
    ]
}

extension LengthEncodedIntegerDecodingTests {
    static let __allTests = [
        ("test0x00Through0xfbIsOneByteInteger", test0x00Through0xfbIsOneByteInteger),
        ("test0xfcIsTwoByteInteger", test0xfcIsTwoByteInteger),
        ("test0xfdIsThreeByteInteger", test0xfdIsThreeByteInteger),
        ("test0xfeIsEightByteInteger", test0xfeIsEightByteInteger),
        ("test0xfeThrowsWithLessThanNineBytesOfData", test0xfeThrowsWithLessThanNineBytesOfData),
        ("test0xffThrows", test0xffThrows),
        ("testThrowsWithEmptyData", testThrowsWithEmptyData),
    ]
}

extension LengthEncodedIntegerEncodingTests {
    static let __allTests = [
        ("testNothing", testNothing),
    ]
}

extension LengthEncodedIntegerInitializationTests {
    static let __allTests = [
        ("test0xfcTwoByteEncoding", test0xfcTwoByteEncoding),
        ("test0xfdTwoByteEncoding", test0xfdTwoByteEncoding),
        ("test0xfeTwoByteEncoding", test0xfeTwoByteEncoding),
        ("testEightByteEncodingMax", testEightByteEncodingMax),
        ("testEightByteEncodingMin", testEightByteEncodingMin),
        ("testOneByteEncoding", testOneByteEncoding),
        ("testThreeByteEncodingMax", testThreeByteEncodingMax),
        ("testThreeByteEncodingMin", testThreeByteEncodingMin),
        ("testTwoByteEncodingMax", testTwoByteEncodingMax),
    ]
}

extension LengthEncodedStringDecodingTests {
    static let __allTests = [
        ("testEightByteStringMin", testEightByteStringMin),
        ("testEightByteStringPerformance", testEightByteStringPerformance),
        ("testEmptyString", testEmptyString),
        ("testNilWithEmptyData", testNilWithEmptyData),
        ("testOneByteString", testOneByteString),
        ("testThreeByteStringMax", testThreeByteStringMax),
        ("testThreeByteStringMin", testThreeByteStringMin),
        ("testTwoByteStringMax", testTwoByteStringMax),
        ("testTwoByteStringMin", testTwoByteStringMin),
    ]
}

extension MySqlConnectorTests {
    static let __allTests = [
        ("testHandshake", testHandshake),
    ]
}

extension PacketDecodingTests {
    static let __allTests = [
        ("testSuccess", testSuccess),
        ("testThrowsWithDataMissingFromPayload", testThrowsWithDataMissingFromPayload),
        ("testThrowsWithEmptyData", testThrowsWithEmptyData),
        ("testThrowsWithMissingPayload", testThrowsWithMissingPayload),
        ("testThrowsWithNoNullTerminatorEvenIfNullTerminatorIsInFollowingPacket", testThrowsWithNoNullTerminatorEvenIfNullTerminatorIsInFollowingPacket),
        ("testThrowsWithPartialPacketHeader", testThrowsWithPartialPacketHeader),
        ("testThrowsWithPartialPayload", testThrowsWithPartialPayload),
        ("testThrowsWithPartialPayloadSize", testThrowsWithPartialPayloadSize),
    ]
}

extension PacketEncodingTests {
    static let __allTests = [
        ("testSucceeds", testSucceeds),
        ("testSucceedsAsPacket", testSucceedsAsPacket),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(HandshakeDecodingTests.__allTests),
        testCase(LengthEncodedIntegerDecodingTests.__allTests),
        testCase(LengthEncodedIntegerEncodingTests.__allTests),
        testCase(LengthEncodedIntegerInitializationTests.__allTests),
        testCase(LengthEncodedStringDecodingTests.__allTests),
        testCase(MySqlConnectorTests.__allTests),
        testCase(PacketDecodingTests.__allTests),
        testCase(PacketEncodingTests.__allTests),
    ]
}
#endif
