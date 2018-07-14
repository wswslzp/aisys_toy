history clear
set wid1 [get_window_id]
set wid2 [open_file C:/Users/Administrator.9R1GSE8FGUOXC9T/Desktop/pgt180h_aisys/impl/synplify_impl/synplify.srm]
win_activate $wid2
run_tcl -fg C:/Users/Administrator.9R1GSE8FGUOXC9T/Desktop/pgt180h_aisys/impl/conv_unit_tech.tcl
project -close C:/Users/Administrator.9R1GSE8FGUOXC9T/Desktop/pgt180h_aisys/impl/synplify_pro.prj
