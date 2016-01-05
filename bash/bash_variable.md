# variable


## array

```bash
echo $t 
#1 2 3 4 5 6

ta=($t)
tb="($t)"
tc=("$tc")

echo $ta
#1

echo $tb
#(1 2 3 4 5 6)

echo $tc
#1 2 3 4 5 6

echo ${ta[0]},${ta[1]},${ta[2]},${ta[3]},${ta[4]},${ta[5]}
#1,2,3,4,5,6

\echo ${tb[0]},${tb[1]},${tb[2]},${tb[3]},${tb[4]},${tb[5]}
#(1 2 3 4 5 6),,,,,

echo ${tc[0]},${tc[1]},${tc[2]},${tc[3]},${tc[4]},${tc[5]}
#1 2 3 4 5 6,,,,,
```


## variable meaning
- `$#` , parameter's count
- `$*` , no diff with $@ , but "$@" => "" for each one parameter
- `$@` , no diff with $* , but "$*" => "" for all parameter together
- `$!` , last job id
- `$$` , current shell id
- `$_` , last argument in last command

## variable operation

`${<var>:<start>:<length>}` , get substring  
`${<var>//<search>/<replacement>}` , replace substring  
  
`${<var>:-<default>}` , output: default , "$var" != "<default>"  
`${<var>:=<default>}` , output: default , "$var" == "<default>"  
