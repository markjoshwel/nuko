const std = @import("std");

pub fn main() void {
    const localTimezone = std.time.Timezone.Local{};

    const currentTimeUTC = std.time.currentTime();
    const currentTimeLocal = localTimezone.toLocalTime(currentTimeUTC);

    const year = currentTimeLocal.year();
    const month = currentTimeLocal.month();
    const day = currentTimeLocal.day();
    const hour = currentTimeLocal.hour();
    const minute = currentTimeLocal.minute();
    const second = currentTimeLocal.second();

    std.debug.print("Local Date and Time: {d}-{d}-{d} {d}:{d}:{d}\n", .{year, month, day, hour, minute, second});
}

