// Verilator has no vendor HDL backdoor API. Frontdoor UVM operation remains
// fully usable; these functions fail explicitly rather than breaking linkage.
int uvm_hdl_check_path(char *path) { (void)path; return 0; }
int uvm_hdl_read(char *path, p_vpi_vecval value) { (void)path; (void)value; return 0; }
int uvm_hdl_deposit(char *path, p_vpi_vecval value) { (void)path; (void)value; return 0; }
int uvm_hdl_force(char *path, p_vpi_vecval value) { (void)path; (void)value; return 0; }
int uvm_hdl_release_and_read(char *path, p_vpi_vecval value) { (void)path; (void)value; return 0; }
int uvm_hdl_release(char *path) { (void)path; return 0; }
