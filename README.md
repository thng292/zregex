# zregex: POSIX's regex bindings for zig

This library wraps the C regex library and provides a convenient API.

Compatible with zig version `0.13.0`

Note: This library used the C's allocator to allocate the memory for `regex_t` struct. More info at [adapter.c](./adapter.c)

## Installation

1. Run `zig fetch --save git+https://github.com/thng292/zregex.git`
2. In your `build.zig`

```zig
const zregex = b.dependency("zregex", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("zregex", zregex.module("zregex"));
```

## Usage / Quick start guide

### 1. Initialize

```zig
const Regex = @import("zregex");

const regex = try Regex.init("[0-9]\\{1\\}", .{});
defer regex.deinit();

```

### 2. Check if some input matches pattern

```zig
try std.testing.expect(regex.match("12312", .{}));
try std.testing.expect(!regex.match("abc", .{}));
```

### 3. Exec iterator

```zig
const regex = try Regex.init("[ab]c", .{});
defer regex.deinit();

var iter = regex.exec("bc cc", .{});
if (iter.next()) |matched| {
    try std.testing.expectEqualStrings("bc", matched);
}
if (iter.next()) |matched| {
    try std.testing.expectEqualStrings("cc", matched);
}
if (iter.next()) |_| {
    unreachable;
}
```

### 4. Get number of sub-expressions

```zig
const regex = try Regex.init("\\([ab]c\\)", .{});
defer regex.deinit();

try std.testing.expectEqual(1, regex.getNumSubexpression());
```

## Error map

```zig
fn cerrToZig(err_num: c_int) Error {
    return switch (err_num) {
        c.REG_NOMATCH => error.NoMatch,
        c.REG_BADPAT => error.InvalidRegex,
        c.REG_ECOLLATE => error.InvalidCollate,
        c.REG_ECTYPE => error.InvalidClassType,
        c.REG_EESCAPE => error.TrailingBackSlash,
        c.REG_ESUBREG => error.InvalidNumberInDigit,
        c.REG_EBRACK => error.BracketImbalance,
        c.REG_EPAREN => error.ParenthesisImbalance,
        c.REG_EBRACE => error.BraceImbalance,
        c.REG_BADBR => error.InvalidContentInBrace,
        c.REG_ERANGE => error.InvalidEndpoint,
        c.REG_ESPACE => error.OutOfMemory,
        c.REG_BADRPT => error.InvalidRepeatQuantifier,
        c.REG_ENOSYS => error.NotImplemented,
        else => error.Unknown,
    };
}
```

## References

- https://cookbook.ziglang.cc/15-01-regex.html
- https://github.com/skota-io/libregex-z
- https://pubs.opengroup.org/onlinepubs/7908799/xsh/regexec.html