const std = @import("std");
const zeit = @import("zeit");

const Operation = @import("operation.zig");

pub const ProcessStage = enum { new, ready, blocked, executing, finalized };
pub fn processStageToString(s: ProcessStage) []const u8 {
    switch (s) {
        .new => return "NUEVO",
        .ready => return "LISTO",
        .blocked => return "BLOQUEADO",
        .executing => return "EJECUTANDO",
        .finalized => return "FINALIZADO",
    }
}

pub const Process = struct {
    id: []const u8,

    operation: Operation.Operation,

    estimated_time_ms: i128,
    service_time_ms: i128 = 0, // Tiempo de servicio

    arrival_time_ms: i128, // Tiempo de llegada
    response_time_ms: ?i128, // Tiempo de respuesta
    finalization_time_ms: i128, // Tiempo de finalizacion

    pub fn seed(self: *Process, random: std.Random, alloc: std.mem.Allocator, data: struct { id: usize }) !void {
        self.id = try std.fmt.allocPrint(alloc, "{d}", .{data.id});
        self.operation.seed(random);

        self.estimated_time_ms = random.intRangeAtMost(i128, 5, 20) * 1000;
        self.service_time_ms = 0;

        self.arrival_time_ms = 0;
        self.response_time_ms = null;
        self.finalization_time_ms = 0;
    }

    pub fn isDone(self: *const Process) bool {
        return self.estimated_time_ms <= self.service_time_ms;
    }

    // Tiempo de retorno
    pub fn getReturnTimeMs(self: *const Process) !i128 {
        if (self.finalization_time_ms <= self.arrival_time_ms) return error.InvalidAccess;
        return self.finalization_time_ms - self.arrival_time_ms;
    }

    // Tiempo de espera
    pub fn getWaitTimeMs(self: *const Process) !i128 {
        const return_time = try self.getReturnTimeMs();
        if (return_time <= self.service_time_ms) return error.InvalidAccess;
        return return_time - self.service_time_ms;
    }
};

const BLOCKED_TIME_MS = 8000;
pub const BlockedProcess = struct {
    p: *Process,
    ellapsed_ms: i128,

    pub fn init(self: *BlockedProcess, p: *Process) void {
        self.p = p;
        self.ellapsed_ms = 0;
    }

    pub fn isDone(self: *const BlockedProcess) bool {
        return self.ellapsed_ms > BLOCKED_TIME_MS;
    }
};
