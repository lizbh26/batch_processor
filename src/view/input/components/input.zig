const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Window = vaxis.Window;
const TextInput = vaxis.widgets.TextInput;
const Label = @import("../../components/label.zig").LabelWidget;

const Arena = std.heap.ArenaAllocator;
const usize_to = @import("~").utils.usize_to;
const leftpad = @import("~").utils.leftpad;

const ExecutionContext = @import("~").models.Context.ExecutionContext;

const MAX_INPUT_SIZE = 50;

const Validators = @import("../utils/validators.zig");
const CtxValidators = @import("../utils/ctx_validators.zig");

pub const InputType = enum { text, number, operation };
pub const WidgetConfig = struct { label: []const u8, maxInputSize: ?u16, type: InputType, ctxValidator: ?CtxValidators.ContextValidator = null, ctx: ?*ExecutionContext = null };

pub const InputWidget = struct {
    arena: Arena,

    fieldLabel: Label,
    errorLabel: Label,

    input: TextInput,
    focused: bool = false,

    config: WidgetConfig,

    pub fn init(self: *InputWidget, extern_alloc: std.mem.Allocator, maxLabelSize: ?u16, config: WidgetConfig) void {
        self.arena = Arena.init(extern_alloc);

        const alloc = self.arena.allocator();

        var padded_label = config.label;
        if (maxLabelSize) |max_size| {
            if (config.label.len < max_size)
                padded_label = leftpad(config.label, max_size - config.label.len, ' ', alloc);
        }

        self.config = config;
        self.config.label = padded_label;

        self.fieldLabel.init(alloc);
        self.fieldLabel.changeText(padded_label) catch unreachable;

        self.errorLabel.init(alloc);
        self.errorLabel.updateStyle(.{ .fg = .{ .index = 1 } });

        self.input = TextInput.init(alloc);
        self.focused = false;
    }

    pub fn deinit(self: *InputWidget) void {
        self.arena.deinit();
    }

    pub fn reset(self: *InputWidget) void {
        self.input.clearAndFree();
    }

    pub fn handleInput(self: *InputWidget, key: vaxis.Key) !void {
        try self.input.update(.{ .key_press = key });
        if (self.config.maxInputSize != null and self.getInputLength() > self.config.maxInputSize.?) {
            self.input.deleteBeforeCursor();
        }
    }

    pub fn focus(self: *InputWidget) void {
        self.focused = true;
    }
    pub fn unfocus(self: *InputWidget) void {
        self.focused = false;
    }

    pub fn getInputText(self: *InputWidget, alloc: std.mem.Allocator) []const u8 {
        return self.input.toOwnedContents(alloc) catch "";
    }
    pub fn getInputLength(self: *InputWidget) u16 {
        const alloc = self.arena.allocator();
        const text = self.getInputText(alloc);
        defer alloc.free(text);

        return usize_to(u16, text.len);
    }

    fn validateInput(self: *InputWidget) []const u8 {
        const alloc = self.arena.allocator();
        const inputText = self.getInputText(alloc);
        defer alloc.free(inputText);

        if (self.config.ctxValidator != null and self.config.ctx != null)
            return self.config.ctxValidator.?(inputText, self.config.ctx.?);

        switch (self.config.type) {
            .text => return Validators.validateStringField(inputText),
            .number => return Validators.validateNaturalNumberField(inputText),
            else => return "",
        }
    }

    pub fn isEmpty(self: *InputWidget) bool {
        const alloc = self.arena.allocator();

        const text = self.getInputText(alloc);
        defer alloc.free(text);

        return text.len == 0;
    }
    pub fn isValid(self: *InputWidget) bool {
        const errorText = self.validateInput();
        return errorText.len == 0;
    }

    fn getInputWidth(self: *InputWidget) u16 {
        return (self.config.maxInputSize orelse MAX_INPUT_SIZE) + 1;
    }
    fn getLabelWidth(self: *InputWidget) u16 {
        return usize_to(u16, self.fieldLabel.getWidth());
    }
    fn getErrorWidth(self: *InputWidget) u16 {
        return usize_to(u16, self.errorLabel.getWidth());
    }
    pub fn getWidth(self: *InputWidget) u16 {
        return self.getLabelWidth() + 1 + @max(self.getInputWidth(), self.getErrorWidth());
    }
    pub fn getHeight(self: *InputWidget) u16 {
        return if (self.errorLabel.isEmpty()) 2 else 3;
    }

    pub fn draw(self: *InputWidget, win: vaxis.Window) !void {
        const labelWidth = self.getLabelWidth();
        const inputWidth = self.getInputWidth();
        const height = self.getHeight();

        const container = win.child(.{ .y_off = 0, .x_off = 0, .width = self.getWidth(), .height = height });

        const labelChild = container.child(.{ .x_off = 0, .y_off = 0, .width = labelWidth, .height = 1 });
        self.fieldLabel.draw(labelChild);

        const inputChild = container.child(.{ .x_off = labelWidth + 1, .y_off = 0, .width = inputWidth, .height = 2, .border = .{ .where = .bottom, .style = .{ .fg = .{ .index = if (self.focused) 255 else 56 } } } });
        self.input.draw(inputChild);

        try self.errorLabel.changeText(self.validateInput());
        if (!self.errorLabel.isEmpty()) {
            const errorChild = container.child(.{ .x_off = labelWidth + 1, .y_off = 2, .width = self.getErrorWidth(), .height = 1 });
            self.errorLabel.draw(errorChild);
        }
    }
};
