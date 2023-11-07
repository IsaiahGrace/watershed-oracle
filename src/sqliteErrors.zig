const std = @import("std");

// Prints an error, if applicable, but does not propagate it.
pub fn log(err: c_int) void {
    check(err) catch |e| {
        std.log.err("{s} --- https://www.sqlite.org/rescode.html", .{@errorName(e)});
    };
}

// Some special logic for running sqlite3_step(), return ROW and DONE, raise others as error
pub fn stepCheck(err: c_int) SqliteError!c_int {
    const errEnum: SqliteErrorEnum = @enumFromInt(err);
    switch (errEnum) {
        .SQLITE_ROW, .SQLITE_DONE => return err,
        else => try check(err),
    }
    return error.UnknownSQLiteError;
}

// Converts an sqlite3 return code into a zig error, if applicable.
pub fn check(err: c_int) SqliteError!void {
    const errEnum: SqliteErrorEnum = @enumFromInt(err);
    switch (errEnum) {
        .SQLITE_OK => return, // This is a non-error return code
        .SQLITE_ERROR => return SqliteError.SQLITE_ERROR,
        .SQLITE_INTERNAL => return SqliteError.SQLITE_INTERNAL,
        .SQLITE_PERM => return SqliteError.SQLITE_PERM,
        .SQLITE_ABORT => return SqliteError.SQLITE_ABORT,
        .SQLITE_BUSY => return SqliteError.SQLITE_BUSY,
        .SQLITE_LOCKED => return SqliteError.SQLITE_LOCKED,
        .SQLITE_NOMEM => return SqliteError.SQLITE_NOMEM,
        .SQLITE_READONLY => return SqliteError.SQLITE_READONLY,
        .SQLITE_INTERRUPT => return SqliteError.SQLITE_INTERRUPT,
        .SQLITE_IOERR => return SqliteError.SQLITE_IOERR,
        .SQLITE_CORRUPT => return SqliteError.SQLITE_CORRUPT,
        .SQLITE_NOTFOUND => return SqliteError.SQLITE_NOTFOUND,
        .SQLITE_FULL => return SqliteError.SQLITE_FULL,
        .SQLITE_CANTOPEN => return SqliteError.SQLITE_CANTOPEN,
        .SQLITE_PROTOCOL => return SqliteError.SQLITE_PROTOCOL,
        .SQLITE_EMPTY => return SqliteError.SQLITE_EMPTY,
        .SQLITE_SCHEMA => return SqliteError.SQLITE_SCHEMA,
        .SQLITE_TOOBIG => return SqliteError.SQLITE_TOOBIG,
        .SQLITE_CONSTRAINT => return SqliteError.SQLITE_CONSTRAINT,
        .SQLITE_MISMATCH => return SqliteError.SQLITE_MISMATCH,
        .SQLITE_MISUSE => return SqliteError.SQLITE_MISUSE,
        .SQLITE_NOLFS => return SqliteError.SQLITE_NOLFS,
        .SQLITE_AUTH => return SqliteError.SQLITE_AUTH,
        .SQLITE_FORMAT => return SqliteError.SQLITE_FORMAT,
        .SQLITE_RANGE => return SqliteError.SQLITE_RANGE,
        .SQLITE_NOTADB => return SqliteError.SQLITE_NOTADB,
        .SQLITE_NOTICE => return SqliteError.SQLITE_NOTICE,
        .SQLITE_WARNING => return SqliteError.SQLITE_WARNING,
        .SQLITE_ROW => return, // This is a non-error return code
        .SQLITE_DONE => return, // This is a non-error return code
    }
    return error.UnknownSQLiteError;
}

const SqliteError = error{
    UnknownSQLiteError,
    SQLITE_ERROR,
    SQLITE_INTERNAL,
    SQLITE_PERM,
    SQLITE_ABORT,
    SQLITE_BUSY,
    SQLITE_LOCKED,
    SQLITE_NOMEM,
    SQLITE_READONLY,
    SQLITE_INTERRUPT,
    SQLITE_IOERR,
    SQLITE_CORRUPT,
    SQLITE_NOTFOUND,
    SQLITE_FULL,
    SQLITE_CANTOPEN,
    SQLITE_PROTOCOL,
    SQLITE_EMPTY,
    SQLITE_SCHEMA,
    SQLITE_TOOBIG,
    SQLITE_CONSTRAINT,
    SQLITE_MISMATCH,
    SQLITE_MISUSE,
    SQLITE_NOLFS,
    SQLITE_AUTH,
    SQLITE_FORMAT,
    SQLITE_RANGE,
    SQLITE_NOTADB,
    SQLITE_NOTICE,
    SQLITE_WARNING,
};

// From sqlite3.h
const SqliteErrorEnum = enum(c_int) {
    SQLITE_OK = 0,
    SQLITE_ERROR = 1,
    SQLITE_INTERNAL = 2,
    SQLITE_PERM = 3,
    SQLITE_ABORT = 4,
    SQLITE_BUSY = 5,
    SQLITE_LOCKED = 6,
    SQLITE_NOMEM = 7,
    SQLITE_READONLY = 8,
    SQLITE_INTERRUPT = 9,
    SQLITE_IOERR = 10,
    SQLITE_CORRUPT = 11,
    SQLITE_NOTFOUND = 12,
    SQLITE_FULL = 13,
    SQLITE_CANTOPEN = 14,
    SQLITE_PROTOCOL = 15,
    SQLITE_EMPTY = 16,
    SQLITE_SCHEMA = 17,
    SQLITE_TOOBIG = 18,
    SQLITE_CONSTRAINT = 19,
    SQLITE_MISMATCH = 20,
    SQLITE_MISUSE = 21,
    SQLITE_NOLFS = 22,
    SQLITE_AUTH = 23,
    SQLITE_FORMAT = 24,
    SQLITE_RANGE = 25,
    SQLITE_NOTADB = 26,
    SQLITE_NOTICE = 27,
    SQLITE_WARNING = 28,
    SQLITE_ROW = 100,
    SQLITE_DONE = 101,
};
