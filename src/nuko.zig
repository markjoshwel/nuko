// nuko: a small file uploader to [litter.]catbox.moe
// --------------------------------------------------
// mark joshwel <mark@joshwel.co>
//
//  This is free and unencumbered software released into the public domain.
//
//  Anyone is free to copy, modify, publish, use, compile, sell, or
//  distribute this software, either in source code form or as a compiled
//  binary, for any purpose, commercial or non-commercial, and by any
//  means.
//
//  In jurisdictions that recognize copyright laws, the author or authors
//  of this software dedicate any and all copyright interest in the
//  software to the public domain. We make this dedication for the benefit
//  of the public at large and to the detriment of our heirs and
//  successors. We intend this dedication to be an overt act of
//  relinquishment in perpetuity of all present and future rights to this
//  software under copyright law.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
//  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//
//  For more information, please refer to <http://unlicense.org/>
//
// with all my heart, 2024 x

const std = @import("std");
const File = std.fs.File;
const log = std.log;

const VERSION = "0.1.0";
const BUILD_HASH = "unknown";
const BUILD_BRANCH = "unknown";
const BUILD_DATE = "unknown";

// unified tagged union struct used in nuko functions
pub const Operation = union(OperationMode) {
    litterbox: LitterboxOperation,
    catbox_file: CatboxFileOperation,
    catbox_album: CatboxAlbumOperation,
};

// operation mode enum to be used with the operation tagged union struct
pub const OperationMode = enum {
    litterbox,
    catbox_file,
    catbox_album,
};

pub const LitterboxOperation = struct {
    time: TimeValue = TimeValue.hour,
};

pub const CatboxFileOperation = struct {
    userhash: []const u8 = "",
    delete: bool = false,
};

pub const CatboxAlbumOperation = struct {
    userhash: []const u8 = "",
    album: Album,
};

pub const Album = struct {
    short: []const u8 = "", // identifier part of album link
    mode: AlbumMode = AlbumMode.createalbum,
};

pub const AlbumMode = enum {
    createalbum,
    editalbum,
    addtoalbum,
    removefromalbum,
    deletealbum,
};

pub const TimeValue = enum(u8) {
    hour = 1,
    halfday = 12,
    day = 24,
    threedays = 72,
};

pub const Behaviour = struct {
    targets: std.ArrayList([]const u8),
    operation: Operation,
};

// argument handling function
// - handles arguments (really? no way!)
// - prints help and version information
// - validates arguments (a la was a valid choice given to --time)
// - if targets are local paths, checks if they exist
fn handleArgs(_alloc: ?std.mem.Allocator) Behaviour {
    var alloc: std.mem.Allocator = undefined;

    if (_alloc == null) {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        alloc = gpa.allocator();
        defer gpa.deinit();
    } else {
        alloc = _alloc.?;
    }

    return Behaviour{
        .targets = std.ArrayList([]const u8).init(alloc),
        .operation = Operation{
            .litterbox = LitterboxOperation{
                .time = TimeValue.hour,
            },
        },
    };
}

// uploads data to litterbox/catbox
// arguments:
//   data: []u8
//     data to upload
//   operation: Operation
//     operation to perform on the data
pub fn uploadData(data: []u8, operation: Operation, _alloc: ?std.mem.Allocator) bool {
    var alloc: std.mem.Allocator = undefined;

    if (_alloc == null) {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        alloc = gpa.allocator();
        defer gpa.deinit();
    } else {
        alloc = _alloc.?;
    }

    _ = data;
    _ = operation;

    // TODO
    log.err("album management is not implemented yet", .{});
    std.os.exit(255);

    return true;
}

// manages a catbox album
// arguments:
//   file_shorts: std.ArrayList([]const u8)
//      list of file short identifiers
//  operation: Operation
//      operation to perform on the album
pub fn manageAlbum(file_shorts: std.ArrayList([]const u8), operation: Operation, _alloc: ?std.mem.Allocator) void {
    var alloc: std.mem.Allocator = undefined;

    if (_alloc == null) {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        alloc = gpa.allocator();
        defer gpa.deinit();
    } else {
        alloc = _alloc.?;
    }

    _ = file_shorts;
    _ = operation;

    // TODO
    log.err("album management is not implemented yet", .{});
    std.os.exit(255);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer gpa.deinit();

    const operation = handleArgs(alloc);
    _ = operation;
}
