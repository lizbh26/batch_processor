const ExecutionContext = @import("~").models.Context.ExecutionContext;
pub const ContextValidator = *const (fn (str: []const u8, ctx: *ExecutionContext) []const u8);

const Validators = @import("validators.zig");

pub fn validateUniqueId(str: []const u8, ctx: *ExecutionContext) []const u8 {
    if (Validators.checkEmpty(str)) |msg| return msg;
    if (!ctx.isUniqueId(str)) return "Esta ID ya ha sido usada";
    return "";
}
