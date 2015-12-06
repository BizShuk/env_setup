# variable

## variable meaning
- `$#` , parameter's count
- `$*` , no diff with $@ , but "$@" => "" for each one parameter
- `$@` , no diff with $* , but "$*" => "" for all parameter together


## variable operation

`${<var>:<start>:<length>}` , get substring  
`${<var>//<search>/<replacement>}` , replace substring  
  
`${<var>:-<default>}` , output: default , "$var" != "<default>"  
`${<var>:=<default>}` , output: default , "$var" == "<default>"  