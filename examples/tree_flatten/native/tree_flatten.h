#ifndef TREE_FLATTEN_H
#define TREE_FLATTEN_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum FlatExternTag {
    /* Root payload; value0 contains the JS value handle. */
    FLAT_EXTERN_PAYLOAD = 1,
    /* Named read; offset/length select UTF-8 bytes. */
    FLAT_EXTERN_MEMBER_ACCESS = 2,
    /* Indexed read; value0 contains the index handle. */
    FLAT_EXTERN_INDEXED_ACCESS = 3,
    /* Named write; value0 is the value and offset/length select the name. */
    FLAT_EXTERN_MEMBER_UPDATE = 4,
    /* Indexed write; value0 is the index and value1 is the new value. */
    FLAT_EXTERN_INDEXED_UPDATE = 5,
    /* Function call; offset/length select argument handles. */
    FLAT_EXTERN_FUNC_CALL = 6
};

/*
 * One serialized node of an Extern chain. Records are stored root-to-leaf;
 * fixed operands are inline, while offset/length selects variable data from
 * the FlatExternView sidecars. The fixed layout is shared with Cangjie.
 */
typedef struct FlatExternOp {
    /* FlatExternTag value selecting the operation and field interpretation. */
    uint32_t tag;
    /* ABI expansion slot; canonical records set it to zero. */
    uint32_t reserved;
    /* Payload, index, or update operand; tag determines its exact meaning. */
    uint64_t value0;
    /* Indexed-update value; zero for all other tags. */
    uint64_t value1;
    /* Name-byte or call-argument sidecar offset; zero when unused. */
    uint64_t offset;
    /* Name-byte or call-argument sidecar length; zero when unused. */
    uint64_t length;
} FlatExternOp;

/*
 * C ABI envelope for a complete flattened Extern. It keeps the operation
 * records and their UTF-8-name and call-argument sidecars together. Input
 * pointers are borrowed; tree_flatten_round_trip returns a C-owned deep copy.
 */
typedef struct FlatExternView {
    /* Borrowed input or C-owned output root-to-leaf operation array. */
    FlatExternOp *ops;
    /* Number of readable records at ops; must be at least one. */
    uint64_t ops_count;
    /* Borrowed input or C-owned output packed UTF-8 member names. */
    uint8_t *bytes;
    /* Total readable bytes at bytes for validating name slices. */
    uint64_t bytes_count;
    /* Borrowed input or C-owned output packed function arguments. */
    uint64_t *values;
    /* Total readable handles at values for validating argument slices. */
    uint64_t values_count;
} FlatExternView;

enum FlatExternStatus {
    /* The operation completed successfully. */
    FLAT_EXTERN_OK = 0,
    /* A required top-level pointer was NULL. */
    FLAT_EXTERN_INVALID_ARGUMENT = 1,
    /* A tag, field, pointer, or sidecar slice was invalid. */
    FLAT_EXTERN_INVALID_LAYOUT = 2,
    /* A deep-copy allocation failed or was too large. */
    FLAT_EXTERN_OUT_OF_MEMORY = 3
};

int32_t tree_flatten_validate(const FlatExternView *value);
/* Deep-copies input into output; release output with tree_flatten_free. */
int32_t tree_flatten_round_trip(const FlatExternView *input, FlatExternView *output);
void tree_flatten_free(FlatExternView *value);

#ifdef __cplusplus
}
#endif

#endif
