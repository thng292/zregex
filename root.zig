const std = @import("std");
pub const c = @cImport({
    @cInclude("adapter.h");
});

const Regex = @This();

pub const InitFlag = packed struct {
    extended: bool = false,
    ignore_case: bool = false,
    nosub: bool = false,
    newline: bool = false,

    fn construct(flag: InitFlag) c_int {
        var res: c_int = 0;
        if (flag.extended) res |= c.REG_EXTENDED;
        if (flag.ignore_case) res |= c.REG_ICASE;
        if (flag.newline) res |= c.REG_NEWLINE;
        if (flag.nosub) res |= c.REG_NOSUB;
        return res;
    }
};

pub const ExecFlag = packed struct {
    not_bol: bool = false,
    not_eol: bool = false,

    fn construct(flag: ExecFlag) c_int {
        var res: c_int = 0;
        if (flag.not_bol) res |= c.REG_NOTBOL;
        if (flag.not_eol) res |= c.REG_NOTEOL;
        return res;
    }
};

inner: *c.regex_t,

pub fn init(pattern: [:0]const u8, flag: InitFlag) !Regex {
    const inner = try (c.alloc_regex_t() orelse error.OutOfMemory);
    const c_err = c.regcomp(inner, pattern, flag.construct());
    if (c_err != 0) {
        return cerrToZig(c_err);
    }
    return .{
        .inner = inner,
    };
}

pub fn deinit(self: Regex) void {
    c.free_regex_t(self.inner);
}

pub fn getNumSubexpression(self: Regex) usize {
    return c.getNumSubexpression(self.inner);
}

pub fn exec(self: Regex, input: [:0]const u8, flag: ExecFlag) ExecIter {
    return ExecIter{
        .regex = self.inner,
        .input = input,
        .flag = flag.construct(),
    };
}

pub fn match(self: Regex, input: [:0]const u8, flag: ExecFlag) bool {
    return 0 == c.regexec(self.inner, input, 0, null, flag.construct());
}

pub const ExecIter = struct {
    regex: *c.regex_t,
    input: [:0]const u8,
    flag: c_int,

    pub fn next(self: *ExecIter) ?[]const u8 {
        const match_size = 1;
        var match_pos = [match_size]c.regmatch_t{std.mem.zeroInit(c.regmatch_t, .{})};
        const err = c.regexec(
            self.regex,
            self.input,
            match_size,
            &match_pos,
            self.flag,
        );
        if (err != 0) {
            return null;
        }
        const start: usize = @intCast(match_pos[0].rm_so);
        const end: usize = @intCast(match_pos[0].rm_eo);
        const res = self.input[start..end];
        self.input = self.input[end..];
        return res;
    }
};

test "Exec Iterator" {
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
}

test "Exec Iterator 2" {
    const regex = try Regex.init("John.*o", .{ .newline = true });
    defer regex.deinit();

    const input =
        \\ 1) John Driverhacker;
        \\ 2) John Doe;
        \\ 3) John Foo;
    ;

    var iter = regex.exec(input, .{});
    if (iter.next()) |matched| {
        try std.testing.expectEqualStrings("John Do", matched);
    }
    if (iter.next()) |matched| {
        try std.testing.expectEqualStrings("John Foo", matched);
    }
    if (iter.next()) |_| {
        unreachable;
    }
}

test "Match" {
    const regex = try Regex.init("[0-9]\\{1\\}", .{});
    defer regex.deinit();

    try std.testing.expect(regex.match("12312", .{}));
    try std.testing.expect(!regex.match("abc", .{}));
}

test "Get number of subexpression" {
    const regex = try Regex.init("\\([ab]c\\)", .{});
    defer regex.deinit();

    try std.testing.expectEqual(1, regex.getNumSubexpression());
}

pub const Error = error{
    NoMatch,
    InvalidRegex,
    InvalidCollate,
    InvalidClassType,
    TrailingBackSlash,
    InvalidNumberInDigit,
    BracketImbalance,
    ParenthesisImbalance,
    BraceImbalance,
    InvalidContentInBrace,
    InvalidEndpoint,
    OutOfMemory,
    InvalidRepeatQuantifier,
    NotImplemented,
    Unknown,
};

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
