#include "tree_flatten.h"

#include <stddef.h>
#include <stdlib.h>
#include <string.h>

_Static_assert(sizeof(FlatExternOp) == 40, "FlatExternOp ABI changed");
_Static_assert(offsetof(FlatExternOp, value0) == 8, "FlatExternOp.value0 ABI changed");
_Static_assert(offsetof(FlatExternOp, offset) == 24, "FlatExternOp.offset ABI changed");
_Static_assert(sizeof(FlatExternView) == 48, "FlatExternView ABI changed");

/* Check a slice without allowing offset + length to overflow. */
static int slice_is_valid(uint64_t offset, uint64_t length, uint64_t total)
{
    return offset <= total && length <= total - offset;
}

static int has_pointer_for_count(const void *pointer, uint64_t count)
{
    return count == 0 || pointer != NULL;
}

int32_t tree_flatten_validate(const FlatExternView *value)
{
    uint64_t i;

    if (value == NULL) {
        return FLAT_EXTERN_INVALID_ARGUMENT;
    }
    if (value->ops_count == 0 ||
        !has_pointer_for_count(value->ops, value->ops_count) ||
        !has_pointer_for_count(value->bytes, value->bytes_count) ||
        !has_pointer_for_count(value->values, value->values_count)) {
        return FLAT_EXTERN_INVALID_LAYOUT;
    }

    /* A valid chain starts with one payload followed by non-payload ops. */
    for (i = 0; i < value->ops_count; ++i) {
        const FlatExternOp *op = &value->ops[i];

        if (op->reserved != 0) {
            return FLAT_EXTERN_INVALID_LAYOUT;
        }
        if ((i == 0 && op->tag != FLAT_EXTERN_PAYLOAD) ||
            (i != 0 && op->tag == FLAT_EXTERN_PAYLOAD)) {
            return FLAT_EXTERN_INVALID_LAYOUT;
        }

        switch (op->tag) {
            case FLAT_EXTERN_PAYLOAD:
                if (op->value1 != 0 || op->offset != 0 || op->length != 0) {
                    return FLAT_EXTERN_INVALID_LAYOUT;
                }
                break;
            case FLAT_EXTERN_MEMBER_ACCESS:
                if (op->value0 != 0 || op->value1 != 0 ||
                    !slice_is_valid(op->offset, op->length, value->bytes_count)) {
                    return FLAT_EXTERN_INVALID_LAYOUT;
                }
                break;
            case FLAT_EXTERN_INDEXED_ACCESS:
                if (op->value1 != 0 || op->offset != 0 || op->length != 0) {
                    return FLAT_EXTERN_INVALID_LAYOUT;
                }
                break;
            case FLAT_EXTERN_MEMBER_UPDATE:
                if (op->value1 != 0 ||
                    !slice_is_valid(op->offset, op->length, value->bytes_count)) {
                    return FLAT_EXTERN_INVALID_LAYOUT;
                }
                break;
            case FLAT_EXTERN_INDEXED_UPDATE:
                if (op->offset != 0 || op->length != 0) {
                    return FLAT_EXTERN_INVALID_LAYOUT;
                }
                break;
            case FLAT_EXTERN_FUNC_CALL:
                if (op->value0 != 0 || op->value1 != 0 ||
                    !slice_is_valid(op->offset, op->length, value->values_count)) {
                    return FLAT_EXTERN_INVALID_LAYOUT;
                }
                break;
            default:
                return FLAT_EXTERN_INVALID_LAYOUT;
        }
    }
    return FLAT_EXTERN_OK;
}

void tree_flatten_free(FlatExternView *value)
{
    if (value == NULL) {
        return;
    }
    /* All three buffers are allocated by tree_flatten_round_trip. */
    free(value->ops);
    free(value->bytes);
    free(value->values);
    memset(value, 0, sizeof(*value));
}

static int32_t clone_buffer(void **output, const void *input, uint64_t count, size_t element_size)
{
    size_t byte_count;

    *output = NULL;
    if (count == 0) {
        return FLAT_EXTERN_OK;
    }
    if (count > (uint64_t)(SIZE_MAX / element_size)) {
        return FLAT_EXTERN_OUT_OF_MEMORY;
    }

    byte_count = (size_t)count * element_size;
    *output = malloc(byte_count);
    if (*output == NULL) {
        return FLAT_EXTERN_OUT_OF_MEMORY;
    }
    memcpy(*output, input, byte_count);
    return FLAT_EXTERN_OK;
}

int32_t tree_flatten_round_trip(const FlatExternView *input, FlatExternView *output)
{
    int32_t status;

    if (output == NULL) {
        return FLAT_EXTERN_INVALID_ARGUMENT;
    }
    memset(output, 0, sizeof(*output));

    status = tree_flatten_validate(input);
    if (status != FLAT_EXTERN_OK) {
        return status;
    }

    /* Return an independent, C-owned copy of every input buffer. */
    output->ops_count = input->ops_count;
    output->bytes_count = input->bytes_count;
    output->values_count = input->values_count;

    status = clone_buffer((void **)&output->ops, input->ops,
                          input->ops_count, sizeof(*input->ops));
    if (status == FLAT_EXTERN_OK) {
        status = clone_buffer((void **)&output->bytes, input->bytes,
                              input->bytes_count, sizeof(*input->bytes));
    }
    if (status == FLAT_EXTERN_OK) {
        status = clone_buffer((void **)&output->values, input->values,
                              input->values_count, sizeof(*input->values));
    }
    if (status != FLAT_EXTERN_OK) {
        tree_flatten_free(output);
    }
    return status;
}
