fn isNumber(char: u8) bool {
    return (char >= '0' and char <= '9');
}
fn isOnlyNumbers(str: []const u8) bool {
    for (str) |char| {
        if (!isNumber(char)) return false;
    }
    return true;
}
fn isNotZero(str: []const u8) bool {
    for (str) |char| {
        if (char != '0') return true;
    }
    return false;
}

pub fn checkEmpty(str: []const u8) ?[]const u8 {
    return if (str.len == 0) "Este campo es requerido" else null;
}

pub fn validateStringField(str: []const u8) []const u8 {
    if (checkEmpty(str)) |msg| return msg;
    return "";
}

pub fn validateNaturalNumberField(str: []const u8) []const u8 {
    if (checkEmpty(str)) |msg| return msg;
    if (!isOnlyNumbers(str)) return "Este campo solo admite digitos";
    if (!isNotZero(str)) return "No puede ser 0";

    return "";
}
