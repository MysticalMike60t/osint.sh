_insane_verbose() {
    var_details() {
        ls -lh $1
    }
    
    _verbose
    var_details $ERRORS
}