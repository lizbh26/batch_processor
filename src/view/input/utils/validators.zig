pub const Validators = struct {
    pub fn required(str: []const u8) bool {
        return str.len == 0;
    }
    pub fn is_number(char: u8) bool {
        return (char >= '0' or char <= '9');
    }
    pub fn only_numbers(str: []const u8) bool {
        for (str) |char| {
            if (!Validators.is_number(char)) return false;
        }
        return true;
    }
};
