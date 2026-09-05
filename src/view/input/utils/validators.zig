pub fn required(str: []const u8) bool {
    return str.len != 0;
}
pub fn is_number(char: u8) bool {
    return (char >= '0' and char <= '9');
}
pub fn only_numbers(str: []const u8) bool {
    for (str) |char| {
        if (!is_number(char)) return false;
    }
    return true;
}
pub fn not_zero(str: []const u8) bool {
    for (str) |char| {
        if (char != '0') return true;
    }
    return false;
}

pub fn validateStringField(str: []const u8) []const u8 {
    if (!required(str)) return "Este campo es requerido";
    return "";
}

pub fn validateNaturalNumberField(str: []const u8) []const u8 {
    if (!required(str)) return "Este campo es requerido";
    if (!only_numbers(str)) return "Este campo solo admite digitos";
    if (!not_zero(str)) return "No puede ser 0";

    return "";
}
