# Prototype comparisons

The prototypes described below are implemented in `examples`. The initial implementation, prototype1, follows the [spec](https://github.com/danghica/interop/blob/main/The%20Cangjie%20Extern%20type.md) as closely as possible.

- `prototype1`: as close as possible to the spec
- `prototype2`: functions in `Runtime` interface receive and return `Handle` instead of `Extern`. This is motivated by the mutual recursion between `Extern` and `Runtime` and also to make interpolation in quote easier: e.g. `extModule.lookup(lat, long)` is desugared into `DummyRuntime.eval(parseExpr(quote($(extModule.handle).lookup($(e_lat.handle), $(e_long.handle)))))`, where `e_lat` and `e_long` are of type `Extern<DummyRuntime>`.
- `prototype3`: use custom defined enum for `Expr`. This is motivated by the fact that `quote(${left} = ${right})` (corresponding to something like `quote(42 = 64)`) is not a valid Cangjie AST.
