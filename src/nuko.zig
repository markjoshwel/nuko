const std = @import("std");
const File = std.fs.File;
const log = std.log;

const VERSION = "0.1.0";
const BUILD_HASH = "unknown";
const BUILD_BRANCH = "unknown";
const BUILD_DATE = "unknown";

const OperationMode = enum {
    catbox, // = "https://catbox.moe/user/api.php",
    litterbox, // = "https://litterbox.catbox.moe/resources/internals/api.php",
};

const Album = struct {
    short: []const u8, // identifier part of album link
    mode: AlbumMode,
    files: std.ArrayList([]const u8),
};

const AlbumMode = enum {
    createalbum,
    editalbum,
    addtoalbum,
    removefromalbum,
};

const TimeValue = enum(u8) {
    hour = 1,
    halfday = 12,
    day = 24,
    threedays = 72,
};

pub fn main() !void {

    // argument handling
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const help =
        \\usage: {s} [-h] [-l] [-t {{1,12,24,72}}] [file, ...]
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
        \\                      (for litterbox) how long the file should be kept
        \\  -u USERHASH, --userhash USERHASH
        \\                      (for catbox) specify a userhash for non-anonymous uploads
        \\  -a [SHORT], --album [SHORT]
        \\                      (for catbox) create a new album if short is not specified
        \\                      add an '/edit' '/add' or 'remove' suffix to edit images,
        \\                      add images to and remove images from an already existing
        \\                      album respectively. 
        \\                      when given, files parameter are shorts of files already on
        \\                      catbox.
        \\
        \\                      shorts are the short identifiers of catbox files.
        \\                      e.g., the short of 'https://files.catbox.moe/0k6bpc.jpg'
        \\                      is '0k6bpc.jpg'
        \\                      same goes for albums, but without the preceding '.../c/'
        \\
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

    var currently_a_time_arg: bool = false;
    var currently_a_userhash_arg: bool = false;
    var currently_a_album_arg: bool = false;

    var option_mode: OperationMode = OperationMode.catbox;
    var option_files = std.ArrayList([]const u8).init(allocator);
    var option_litterbox_time: TimeValue = TimeValue.hour;
    var option_catbox_userhash: []const u8 = "";
    var option_catbox_is_album: bool = false;
    var option_catbox_album: Album = Album{
        .short = "",
        .mode = AlbumMode.createalbum,
        .files = option_files,
    };
    defer option_files.deinit();

    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            try std.io.getStdOut().writer().print(help, .{args[0]});
            std.os.exit(0);
        }

        if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            try std.io.getStdOut().writer().print(
                "nuko v{s} ({s}@{s}, {s})\n",
                .{ VERSION, BUILD_HASH, BUILD_BRANCH, BUILD_DATE },
            );
            std.os.exit(0);
        }

        if (std.mem.startsWith(u8, arg, "-t=") or std.mem.startsWith(u8, arg, "--time=") or currently_a_time_arg) {
            if (std.mem.eql(u8, arg, "-l")) {
                log.err(
                    \\premature ending of time flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(3);
            } else if (std.mem.eql(u8, arg, "--litterbox")) {
                log.err(
                    \\premature ending of time flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(3);
            } else if (std.mem.eql(u8, arg, "-a")) {
                log.err(
                    \\premature ending of time flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(3);
            } else if (std.mem.eql(u8, arg, "--album")) {
                log.err(
                    \\premature ending of time flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(3);
            } else if (std.mem.eql(u8, arg, "-u")) {
                log.err(
                    \\premature ending of time flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(3);
            } else if (std.mem.eql(u8, arg, "--userhash")) {
                log.err(
                    \\premature ending of time flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(3);
            }

            var split_iter = std.mem.splitBackwardsSequence(u8, arg, "=");

            while (split_iter.next()) |sarg| {
                if (std.mem.eql(u8, sarg, "1")) {
                    option_litterbox_time = TimeValue.hour;
                } else if (std.mem.eql(u8, sarg, "12")) {
                    option_litterbox_time = TimeValue.halfday;
                } else if (std.mem.eql(u8, sarg, "24")) {
                    option_litterbox_time = TimeValue.day;
                } else if (std.mem.eql(u8, sarg, "72")) {
                    option_litterbox_time = TimeValue.threedays;
                } else {
                    log.err(
                        \\invalid time value '{s}' (choose from 1, 12, 24, 72)
                        \\see '{s} --help' for more information.
                    , .{ sarg, args[0] });
                    std.os.exit(3);
                }
                currently_a_time_arg = false;
                break;
            }
            continue;
        }

        if (std.mem.startsWith(u8, arg, "-a=") or std.mem.startsWith(u8, arg, "--album=") or currently_a_album_arg) {
            if (std.mem.eql(u8, arg, "-t")) {
                currently_a_album_arg = false;
                currently_a_time_arg = true;
                continue;
            } else if (std.mem.eql(u8, arg, "--time")) {
                currently_a_album_arg = false;
                currently_a_time_arg = true;
                continue;
            } else if (std.mem.eql(u8, arg, "-u")) {
                currently_a_album_arg = false;
                currently_a_userhash_arg = true;
                continue;
            } else if (std.mem.eql(u8, arg, "--userhash")) {
                currently_a_album_arg = false;
                currently_a_userhash_arg = true;
                continue;
            }

            var split_iter = std.mem.splitBackwardsSequence(u8, arg, "=");
            var i: isize = 0;

            while (split_iter.next()) |sarg| {
                var split_album_iter = std.mem.splitBackwardsSequence(u8, sarg, "/");
                while (split_album_iter.next()) |sam| {
                    // xxxxx/{edit,add,remove}
                    if (i == 0) {
                        option_catbox_album.short = sam;
                    } else if (i == 2) {
                        break;
                    }

                    if (std.mem.eql(u8, sam, "edit")) {
                        option_catbox_album.mode = AlbumMode.editalbum;
                    } else if (std.mem.eql(u8, sam, "add")) {
                        option_catbox_album.mode = AlbumMode.addtoalbum;
                    } else if (std.mem.eql(u8, sam, "remove")) {
                        option_catbox_album.mode = AlbumMode.removefromalbum;
                    } else {
                        option_catbox_album.short = sam;
                    }
                }
                break;
            }
            currently_a_album_arg = false;
            continue;
        }

        if (std.mem.startsWith(u8, arg, "-u=") or std.mem.startsWith(u8, arg, "--userhash=") or currently_a_userhash_arg) {
            if (std.mem.eql(u8, arg, "-l")) {
                log.err(
                    \\premature ending of userhash flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(4);
            } else if (std.mem.eql(u8, arg, "--litterbox")) {
                log.err(
                    \\premature ending of userhash flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(4);
            } else if (std.mem.eql(u8, arg, "-a")) {
                log.err(
                    \\premature ending of userhash flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(4);
            } else if (std.mem.eql(u8, arg, "--album")) {
                log.err(
                    \\premature ending of userhash flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(4);
            } else if (std.mem.eql(u8, arg, "-t")) {
                log.err(
                    \\premature ending of userhash flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(4);
            } else if (std.mem.eql(u8, arg, "--time")) {
                log.err(
                    \\premature ending of userhash flag
                    \\see '{s} --help' for more information.
                , .{args[0]});
                std.os.exit(4);
            }

            var split_iter = std.mem.splitBackwardsSequence(u8, arg, "=");

            while (split_iter.next()) |sarg| {
                option_catbox_userhash = sarg;
                currently_a_userhash_arg = false;
                break;
            }
            continue;
        }

        if (std.mem.eql(u8, arg, "-t") or std.mem.eql(u8, arg, "--time")) {
            currently_a_time_arg = true;
            continue;
        } else {
            currently_a_time_arg = false;
        }

        if (std.mem.eql(u8, arg, "-u") or std.mem.eql(u8, arg, "--u")) {
            currently_a_userhash_arg = true;
            continue;
        } else {
            currently_a_userhash_arg = false;
        }

        if (std.mem.eql(u8, arg, "-a") or std.mem.eql(u8, arg, "--album")) {
            currently_a_album_arg = true;
            option_catbox_is_album = true;
            continue;
        } else {
            currently_a_album_arg = false;
        }

        if (std.mem.eql(u8, arg, "-l") or std.mem.eql(u8, arg, "--litterbox")) {
            option_mode = OperationMode.litterbox;
            continue;
        }

        try option_files.append(arg[0..arg.len]);
    }

    if (currently_a_time_arg) {
        log.err(
            \\premature ending of time flag
            \\see '{s} --help' for more information.
        , .{args[0]});
        std.os.exit(3);
    } else if (currently_a_userhash_arg) {
        log.err(
            \\premature ending of userhash flag
            \\see '{s} --help' for more information.
        , .{args[0]});
        std.os.exit(4);
    }

    // log.debug("operation_mode={any}", .{option_mode});
    // log.debug("litterbox_time={any}", .{option_litterbox_time});
    // log.debug("catbox_userhash={any}", .{option_catbox_userhash});
    // log.debug("catbox_is_album={any}", .{option_catbox_is_album});
    // log.debug("catbox_album={any}", .{option_catbox_album});
    // log.debug("files={any}", .{option_files});

    // check if any files were given
    if (option_files.items.len == 0) {
        log.err(
            \\no files given
            \\see '{s} --help' for more information.
        , .{args[0]});
        std.os.exit(5);
    }

    // TODO: check if files exists
    for (option_files.items) |target| {
        _ = target;
    }

    if (option_catbox_is_album) {
        manageAlbum(option_catbox_album, option_catbox_userhash);
    } else {
        for (option_files.items) |file| {
            uploadFile(file, option_mode, option_litterbox_time, option_catbox_userhash);
        }
    }
    // upload files
}

fn uploadFile(path: []const u8, mode: OperationMode, time: TimeValue, userhash: []const u8) void {
    _ = userhash;
    _ = mode;
    _ = time;

    nosuspend std.io.getStdErr().writer().print("uploading '{s}'... ", .{path}) catch return;

    // TODO

    nosuspend std.io.getStdErr().writer().print("done\n", .{}) catch return;
}

fn manageAlbum(album: Album, userhash: []const u8) void {
    _ = album;
    _ = userhash;

    // TODO
    log.err("album management is not implemented yet", .{});
    std.os.exit(255);
}
