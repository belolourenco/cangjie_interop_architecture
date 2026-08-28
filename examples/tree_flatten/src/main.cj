package tree_flatten

import std.collection.ArrayList

// These tags are shared with enum FlatExternTag in tree_flatten.h.
let TAG_PAYLOAD: UInt32 = 1
let TAG_MEMBER_ACCESS: UInt32 = 2
let TAG_INDEXED_ACCESS: UInt32 = 3
let TAG_MEMBER_UPDATE: UInt32 = 4
let TAG_INDEXED_UPDATE: UInt32 = 5
let TAG_FUNC_CALL: UInt32 = 6

let FLAT_OK: Int32 = 0

public struct JSValue_ {
    // Opaque JavaScript value handle carried by an Extern operation.
    public let value: UInt64

    public init(value: UInt64) {
        this.value = value
    }
}

public enum Extern {
    | Payload(JSValue_)
    | MemberAccess(Extern, String)
    | IndexedAccess(Extern, JSValue_)
    | MemberUpdate(Extern, String, JSValue_)
    | IndexedUpdate(Extern, JSValue_, JSValue_)
    | FuncCall(Extern, Array<JSValue_>)
}

// One serialized node of an Extern chain. Flattening converts every recursive
// enum case into one of these fixed-size records, ordered from the root payload
// to the final operation. Names and call arguments are referenced as slices in
// FlatExtern's sidecar arrays so the record can cross the C ABI unchanged.
@C
public struct FlatExternOp {
    // FlatExternTag value that selects the operation and field interpretation.
    public let tag: UInt32
    // ABI expansion slot; canonical records always set it to zero.
    public let reserved: UInt32
    // Payload handle, access index, member-update value, or indexed-update index;
    // zero for MemberAccess and FuncCall.
    public let value0: UInt64
    // Indexed-update value; zero for every other operation.
    public let value1: UInt64
    // Member-name start in FlatExtern.bytes or argument start in
    // FlatExtern.values; zero for operations without sidecar data.
    public let offset: UInt64
    // Member-name byte count or function-argument count from offset; zero for
    // operations without sidecar data.
    public let length: UInt64

    public init(tag: UInt32, reserved: UInt32, value0: UInt64, value1: UInt64,
        offset: UInt64, length: UInt64) {
        this.tag = tag
        this.reserved = reserved
        this.value0 = value0
        this.value1 = value1
        this.offset = offset
        this.length = length
    }
}

// C ABI envelope for a complete flattened Extern. It groups the operation
// array with the UTF-8-name and call-argument sidecars that its records refer
// to. Cangjie uses this view to send staged buffers to C and receive the
// independently allocated buffers returned by the C round-trip function.
@C
public struct FlatExternView {
    // Borrowed input or C-owned output pointer to root-to-leaf operation records.
    public let ops: CPointer<FlatExternOp>
    // Number of readable FlatExternOp records at ops; it must be at least one.
    public let opsCount: UInt64
    // Borrowed input or C-owned output pointer to packed UTF-8 member names.
    public let bytes: CPointer<UInt8>
    // Total readable bytes at bytes, used to bounds-check name slices.
    public let bytesCount: UInt64
    // Borrowed input or C-owned output pointer to packed function arguments.
    public let values: CPointer<UInt64>
    // Total readable handles at values, used to bounds-check argument slices.
    public let valuesCount: UInt64

    public init(ops: CPointer<FlatExternOp>, opsCount: UInt64,
        bytes: CPointer<UInt8>, bytesCount: UInt64,
        values: CPointer<UInt64>, valuesCount: UInt64) {
        this.ops = ops
        this.opsCount = opsCount
        this.bytes = bytes
        this.bytesCount = bytesCount
        this.values = values
        this.valuesCount = valuesCount
    }
}

// Managed, owning form of a flattened Extern. flatten produces this value,
// unflatten consumes it, and roundTripFlatThroughC temporarily exposes its
// arrays through FlatExternView. Keeping the storage in managed arrays makes
// the flattened value safe to retain independently of any C call.
public struct FlatExtern {
    // Complete root-to-leaf chain, beginning with exactly one Payload record.
    public let ops: Array<FlatExternOp>
    // Packed UTF-8 member names; records identify names by byte offset and length.
    public let bytes: Array<UInt8>
    // Packed JSValue_ call arguments; FuncCall records identify argument slices.
    public let values: Array<UInt64>

    public init(ops: Array<FlatExternOp>, bytes: Array<UInt8>, values: Array<UInt64>) {
        this.ops = ops
        this.bytes = bytes
        this.values = values
    }
}

foreign func tree_flatten_round_trip(input: CPointer<FlatExternView>, output: CPointer<FlatExternView>): Int32
foreign func tree_flatten_free(value: CPointer<FlatExternView>): Unit

func flatOp(tag: UInt32, value0!: UInt64 = 0, value1!: UInt64 = 0,
    offset!: UInt64 = 0, length!: UInt64 = 0): FlatExternOp {
    FlatExternOp(tag, 0, value0, value1, offset, length)
}

func appendName(bytes: ArrayList<UInt8>, name: String): (UInt64, UInt64) {
    // Store strings as UTF-8 slices rather than passing managed String values.
    let raw = unsafe { name.rawData() }
    let offset = UInt64(bytes.size)
    bytes.add(all: raw)
    return (offset, UInt64(raw.size))
}

func flattenInto(value: Extern, ops: ArrayList<FlatExternOp>,
    bytes: ArrayList<UInt8>, values: ArrayList<UInt64>): Unit {
    // Recurse into the base first to produce root-to-leaf operation order.
    match (value) {
        case Extern.Payload(payload) =>
            ops.add(flatOp(TAG_PAYLOAD, value0: payload.value))
        case Extern.MemberAccess(base, name) =>
            flattenInto(base, ops, bytes, values)
            let (offset, length) = appendName(bytes, name)
            ops.add(flatOp(TAG_MEMBER_ACCESS, offset: offset, length: length))
        case Extern.IndexedAccess(base, index) =>
            flattenInto(base, ops, bytes, values)
            ops.add(flatOp(TAG_INDEXED_ACCESS, value0: index.value))
        case Extern.MemberUpdate(base, name, newValue) =>
            flattenInto(base, ops, bytes, values)
            let (offset, length) = appendName(bytes, name)
            ops.add(flatOp(TAG_MEMBER_UPDATE, value0: newValue.value,
                offset: offset, length: length))
        case Extern.IndexedUpdate(base, index, newValue) =>
            flattenInto(base, ops, bytes, values)
            ops.add(flatOp(TAG_INDEXED_UPDATE, value0: index.value,
                value1: newValue.value))
        case Extern.FuncCall(base, arguments) =>
            flattenInto(base, ops, bytes, values)
            let offset = UInt64(values.size)
            for (argument in arguments) {
                values.add(argument.value)
            }
            ops.add(flatOp(TAG_FUNC_CALL, offset: offset,
                length: UInt64(arguments.size)))
    }
}

public func flatten(value: Extern): FlatExtern {
    let ops = ArrayList<FlatExternOp>()
    let bytes = ArrayList<UInt8>()
    let values = ArrayList<UInt64>()
    flattenInto(value, ops, bytes, values)
    return FlatExtern(ops.toArray(), bytes.toArray(), values.toArray())
}

func invalid(message: String): Nothing {
    throw IllegalArgumentException("invalid flat Extern: ${message}")
}

func checkSlice(offset: UInt64, length: UInt64, total: UInt64, name: String): Unit {
    if (offset > total || length > total - offset) {
        invalid("${name} slice is out of bounds")
    }
}

public func validateFlat(value: FlatExtern): Unit {
    // Require the canonical layout expected by both Cangjie and C.
    if (value.ops.size == 0) {
        invalid("operation array is empty")
    }

    let bytesCount = UInt64(value.bytes.size)
    let valuesCount = UInt64(value.values.size)
    for (i in 0..value.ops.size) {
        let op = value.ops[i]
        if (op.reserved != 0) {
            invalid("reserved field is non-zero at operation ${i}")
        }
        if ((i == 0 && op.tag != TAG_PAYLOAD) ||
            (i != 0 && op.tag == TAG_PAYLOAD)) {
            invalid("payload must be the first and only payload operation")
        }

        match (op.tag) {
            case 1 =>
                if (op.value1 != 0 || op.offset != 0 || op.length != 0) {
                    invalid("payload has non-canonical fields")
                }
            case 2 =>
                if (op.value0 != 0 || op.value1 != 0) {
                    invalid("member access has non-canonical fields")
                }
                checkSlice(op.offset, op.length, bytesCount, "member access")
            case 3 =>
                if (op.value1 != 0 || op.offset != 0 || op.length != 0) {
                    invalid("indexed access has non-canonical fields")
                }
            case 4 =>
                if (op.value1 != 0) {
                    invalid("member update has non-canonical fields")
                }
                checkSlice(op.offset, op.length, bytesCount, "member update")
            case 5 =>
                if (op.offset != 0 || op.length != 0) {
                    invalid("indexed update has non-canonical fields")
                }
            case 6 =>
                if (op.value0 != 0 || op.value1 != 0) {
                    invalid("function call has non-canonical fields")
                }
                checkSlice(op.offset, op.length, valuesCount, "function call")
            case _ => invalid("unknown operation tag ${op.tag}")
        }
    }
}

func decodeName(value: FlatExtern, op: FlatExternOp): String {
    let start = Int64(op.offset)
    let bytes = Array<UInt8>(Int64(op.length)) { i => value.bytes[start + i] }
    return String.fromUtf8(bytes)
}

func decodeArguments(value: FlatExtern, op: FlatExternOp): Array<JSValue_> {
    let start = Int64(op.offset)
    return Array<JSValue_>(Int64(op.length)) { i => JSValue_(value.values[start + i]) }
}

public func unflatten(value: FlatExtern): Extern {
    validateFlat(value)
    // Fold each operation over the root payload to rebuild the recursive enum.
    var current = Extern.Payload(JSValue_(value.ops[0].value0))

    for (i in 1..value.ops.size) {
        let op = value.ops[i]
        current = match (op.tag) {
            case 2 => Extern.MemberAccess(current, decodeName(value, op))
            case 3 => Extern.IndexedAccess(current, JSValue_(op.value0))
            case 4 => Extern.MemberUpdate(current, decodeName(value, op), JSValue_(op.value0))
            case 5 => Extern.IndexedUpdate(current, JSValue_(op.value0), JSValue_(op.value1))
            case 6 => Extern.FuncCall(current, decodeArguments(value, op))
            case _ => invalid("unexpected operation while rebuilding")
        }
    }
    return current
}

func emptyView(): FlatExternView {
    FlatExternView(CPointer<FlatExternOp>(), 0, CPointer<UInt8>(), 0,
        CPointer<UInt64>(), 0)
}

func copyReturnedFlat(value: FlatExternView): FlatExtern {
    // Copy C-owned buffers back into managed arrays before freeing them.
    let ops = ArrayList<FlatExternOp>()
    for (i in 0..Int64(value.opsCount)) {
        ops.add(unsafe { value.ops.read(i) })
    }
    let bytes = ArrayList<UInt8>()
    for (i in 0..Int64(value.bytesCount)) {
        bytes.add(unsafe { value.bytes.read(i) })
    }
    let values = ArrayList<UInt64>()
    for (i in 0..Int64(value.valuesCount)) {
        values.add(unsafe { value.values.read(i) })
    }
    return FlatExtern(ops.toArray(), bytes.toArray(), values.toArray())
}

public func roundTripFlatThroughC(value: FlatExtern): FlatExtern {
    validateFlat(value)

    // Stage managed arrays in C memory; empty sidecars still get a safe pointer.
    let inputPointer = unsafe { LibC.malloc<FlatExternView>(count: 1) }
    let outputPointer = unsafe { LibC.malloc<FlatExternView>(count: 1) }
    let opsPointer = unsafe { LibC.malloc<FlatExternOp>(
        count: if (value.ops.size == 0) { 1 } else { value.ops.size }) }
    let bytesPointer = unsafe { LibC.malloc<UInt8>(
        count: if (value.bytes.size == 0) { 1 } else { value.bytes.size }) }
    let valuesPointer = unsafe { LibC.malloc<UInt64>(
        count: if (value.values.size == 0) { 1 } else { value.values.size }) }

    if (inputPointer.isNull() || outputPointer.isNull() || opsPointer.isNull() ||
        bytesPointer.isNull() || valuesPointer.isNull()) {
        unsafe { LibC.free(inputPointer) }
        unsafe { LibC.free(outputPointer) }
        unsafe { LibC.free(opsPointer) }
        unsafe { LibC.free(bytesPointer) }
        unsafe { LibC.free(valuesPointer) }
        throw IllegalMemoryException("could not allocate C input buffers")
    }

    for (i in 0..value.ops.size) {
        unsafe { opsPointer.write(i, value.ops[i]) }
    }
    for (i in 0..value.bytes.size) {
        unsafe { bytesPointer.write(i, value.bytes[i]) }
    }
    for (i in 0..value.values.size) {
        unsafe { valuesPointer.write(i, value.values[i]) }
    }

    unsafe { outputPointer.write(emptyView()) }
    let inputView = FlatExternView(opsPointer, UInt64(value.ops.size),
        bytesPointer, UInt64(value.bytes.size),
        valuesPointer, UInt64(value.values.size))
    unsafe { inputPointer.write(inputView) }
    let status = unsafe { tree_flatten_round_trip(inputPointer, outputPointer) }

    // C has deep-copied the input, so the staging buffers can now be released.
    unsafe { LibC.free(valuesPointer) }
    unsafe { LibC.free(bytesPointer) }
    unsafe { LibC.free(opsPointer) }
    unsafe { LibC.free(inputPointer) }

    if (status != FLAT_OK) {
        unsafe { tree_flatten_free(outputPointer) }
        unsafe { LibC.free(outputPointer) }
        throw IllegalArgumentException("C rejected flat Extern with status ${status}")
    }

    let returnedView = unsafe { outputPointer.read() }
    let returned = copyReturnedFlat(returnedView)
    // tree_flatten_free releases all buffers owned by the returned C view.
    unsafe { tree_flatten_free(outputPointer) }
    unsafe { LibC.free(outputPointer) }
    validateFlat(returned)
    return returned
}

public func roundTripThroughC(value: Extern): Extern {
    return unflatten(roundTripFlatThroughC(flatten(value)))
}

func assertTrue(condition: Bool, message: String): Unit {
    if (!condition) {
        throw Exception("assertion failed: ${message}")
    }
}

func assertOpEqual(expected: FlatExternOp, actual: FlatExternOp, message: String): Unit {
    assertTrue(expected.tag == actual.tag &&
        expected.reserved == actual.reserved &&
        expected.value0 == actual.value0 &&
        expected.value1 == actual.value1 &&
        expected.offset == actual.offset &&
        expected.length == actual.length, message)
}

func assertFlatEqual(expected: FlatExtern, actual: FlatExtern, message: String): Unit {
    assertTrue(expected.ops.size == actual.ops.size, "${message}: operation count")
    assertTrue(expected.bytes.size == actual.bytes.size, "${message}: byte count")
    assertTrue(expected.values.size == actual.values.size, "${message}: value count")

    for (i in 0..expected.ops.size) {
        assertOpEqual(expected.ops[i], actual.ops[i], "${message}: operation ${i}")
    }
    for (i in 0..expected.bytes.size) {
        assertTrue(expected.bytes[i] == actual.bytes[i], "${message}: byte ${i}")
    }
    for (i in 0..expected.values.size) {
        assertTrue(expected.values[i] == actual.values[i], "${message}: value ${i}")
    }
}

// Round-trip tests intentionally live at the end of this file.

func assertRoundTrip(name: String, value: Extern): Unit {
    let expected = flatten(value)
    let rebuilt = roundTripThroughC(value)
    let actual = flatten(rebuilt)
    assertFlatEqual(expected, actual, name)
    println("PASS: ${name}")
}

func testAbiLayout(): Unit {
    // Catch accidental layout drift between the Cangjie and C definitions.
    assertTrue(sizeOf<FlatExternOp>() == 40, "FlatExternOp is 40 bytes")
    assertTrue(sizeOf<FlatExternView>() == 48, "FlatExternView is 48 bytes")
    println("PASS: C ABI layout")
}

func testPayload(): Unit {
    assertRoundTrip("payload", Extern.Payload(JSValue_(42)))
}

func testAccessChain(): Unit {
    let value = Extern.IndexedAccess(
        Extern.MemberAccess(Extern.Payload(JSValue_(100)), "children"),
        JSValue_(7))
    let flat = flatten(value)
    assertTrue(flat.ops.size == 3, "access chain is three flat operations")
    assertTrue(flat.ops[0].tag == TAG_PAYLOAD &&
        flat.ops[1].tag == TAG_MEMBER_ACCESS &&
        flat.ops[2].tag == TAG_INDEXED_ACCESS,
        "operations are stored root-to-leaf")
    assertRoundTrip("member and indexed access", value)
}

func testUpdates(): Unit {
    let value = Extern.IndexedUpdate(
        Extern.MemberUpdate(Extern.Payload(JSValue_(1)), "enabled", JSValue_(2)),
        JSValue_(3), JSValue_(4))
    assertRoundTrip("member and indexed updates", value)
}

func testFunctionCalls(): Unit {
    let emptyCall = Extern.FuncCall(Extern.Payload(JSValue_(9)), Array<JSValue_>())
    assertRoundTrip("empty function call", emptyCall)

    let call = Extern.FuncCall(
        Extern.MemberAccess(Extern.Payload(JSValue_(10)), "invoke"),
        [JSValue_(11), JSValue_(12), JSValue_(13)])
    assertRoundTrip("function call arguments", call)
}

func testUnicodeMember(): Unit {
    let value = Extern.MemberAccess(Extern.Payload(JSValue_(55)), "café_树")
    assertRoundTrip("UTF-8 member name", value)
}

func testMalformedFlatIsRejected(): Unit {
    let malformed = FlatExtern(
        [flatOp(TAG_MEMBER_ACCESS, offset: 0, length: 1)],
        Array<UInt8>(), Array<UInt64>())
    var rejected = false
    try {
        validateFlat(malformed)
    } catch (e: IllegalArgumentException) {
        rejected = true
    }
    assertTrue(rejected, "malformed flat representation is rejected")
    println("PASS: malformed flat representation")
}

main(): Int64 {
    println("Starting tree_flatten round-trip tests...")
    testAbiLayout()
    testPayload()
    testAccessChain()
    testUpdates()
    testFunctionCalls()
    testUnicodeMember()
    testMalformedFlatIsRejected()
    println("All tree_flatten round-trip tests passed.")
    return 0
}
