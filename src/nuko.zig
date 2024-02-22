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
fn handleArgs(_alloc: ?std.mem.Allocator) !Behaviour {
    var alloc: std.mem.Allocator = undefined;

    if (_alloc == null) {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        alloc = gpa.allocator();
        defer {
            const check = gpa.deinit();
            if (check == .leak) @panic("memory leak!");
        }
    } else {
        alloc = _alloc.?;
    }

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    var targets = std.ArrayList([]const u8).init(alloc);
    defer targets.deinit();

    // TODO: use real album links for examples
    const help =
        \\usage: {s} [-h] [-l] [-t {{1,12,24,72}}] [-u USERHASH] [-d] [FILE, ...]
        \\
        \\a small file uploader to [litter.]catbox.moe
        \\
        \\positional arguments:
        \\  file                path(s) to file to read
        \\
        \\optional arguments:
        \\  -h, --help          show this help message and exit
        \\  -v, --version       show program's version number and exit
        \\  -l, --litterbox     use litterbox.catbox.moe instead of catbox.moe
        \\  -t {{1,12,24,72}}, --time {{1,12,24,72}}
        \\                      (for litterbox) how long the file should be kept, defaults
        \\                        to 1 hour as per the website
        \\  -u USERHASH, --userhash USERHASH
        \\                      (for catbox) specify a userhash for non-anonymous uploads.
        \\                        give one if you want to manage your files/albums later.
        \\  -a [SHORT], --album [SHORT]
        \\                      (for catbox) create a new album if short is not specified
        \\                        add an '/edit' '/add' or '/remove' suffix to edit images,
        \\                        add images to and remove images from an already existing
        \\                        album respectively.
        \\                        when given, files passed to nuko are the shorts of files
        \\                        already on catbox.
        \\  -d, --delete        (for catbox) delete a file or album already on catbox.
        \\                        for non-album uploads, the first file given to nuko will
        \\                        be considered as the file short.
        \\
        \\notes:
        \\  '/edit' is VERY powerful. the album will be overwritten with the files given.
        \\
        \\  a short is the the short identifier of catbox files/albums, including any
        \\  extensions. it is the last part of the url.
        \\    e.g., the short of 'https://files.catbox.moe/jd8xsr.jpg'
        \\          is 'jd8xsr.jpg'                        ^^^^^^^^^^
        \\    same goes for albums, but without the preceding '.../c/'
        \\    e.g., the short of 'https://catbox.moe/c/album'
        \\          is 'album'                         ^^^^^
        \\
        \\examples:
        \\  {s} -l -t 24 cats.webm dogs.webm
        \\    upload 'cats.webm' and 'dogs.webm' to litterbox for 24 hours
        \\  {s} cats.webm
        \\    upload 'cats.webm' to catbox
        \\  {s} -u a_very_unique_userhash short1.png short2.png --album
        \\    make a new catbox album with the already uploaded files located at
        \\    files.catbox.moe/short1.png and files.catbox.moe/short2.png
        \\    important: -a/--album must be the last flag or the next argument to it will
        \\               be considered as the short of the album (which does not exist yet)
        \\  {s} -u a_very_unique_userhash -a ALBUM/add short3.jpeg
        \\    you know what? add files.catbox.moe/short3.jpeg to the album located at
        \\    catbox.moe/c/ALBUM
        \\  {s} -u a_very_unique_userhash -a ALBUM --delete
        \\    nevermind, delete the album catbox.moe/c/ALBUM
    ;

    switch (args.len) {
        0 => {
            log.err(
                \\recieved zero arguments not including program name
                \\see '{s} --help' for more information.
            , .{args[0]});
            std.os.exit(255);
        },
        1 => {
            log.err(
                \\no arguments given
                \\see '{s} --help' for more information.
            , .{args[0]});
            std.os.exit(1);
        },
        else => {},
    }

    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            try std.io.getStdOut().writer().print(help, .{ args[0], args[0], args[0], args[0], args[0], args[0] });
            std.os.exit(0);
        }

        if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            try std.io.getStdOut().writer().print(
                "nuko v{s} ({s}@{s}, {s})\n",
                .{ VERSION, BUILD_HASH, BUILD_BRANCH, BUILD_DATE },
            );
            std.os.exit(0);
        }

        // TODO: handle this bullshit like in the old one

        try targets.append(arg[0..arg.len]);
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
        defer {
            const check = gpa.deinit();
            if (check == .leak) @panic("memory leak!");
        }
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
        defer {
            const check = gpa.deinit();
            if (check == .leak) @panic("memory leak!");
        }
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
    defer {
        const check = gpa.deinit();
        if (check == .leak) @panic("memory leak!");
    }

    const operation = handleArgs(alloc) catch |err| {
        log.err("error when handling arguments: {any}", .{err});
        std.os.exit(1);
    };
    _ = operation;
}
