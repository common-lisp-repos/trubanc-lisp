REM Usage is: "trubanc [slimeport]"
ccl -e "(load \"trubanc-loader.lisp\")" -e "(when (find-package :trubanc) (in-package :trubanc))" -e "(trubanc-loader:load-swank %1)"