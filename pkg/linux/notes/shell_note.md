[variable string method](http://www.thegeekstuff.com/2010/07/bash-string-manipulation/)

##### getopts


```
while getopts “a:b:c:?” argv  
do  
     case $argv in  
         a)  
             VAR1=$OPTARG  
             ;;  
         b)  
             VAR2=$OPTARG  
             ;;  
         c)  
             VAR3=$OPTARG  
             ;;  
         ?)  
             usage  
             exit  
             ;;  
     esac  
done  
```

##### # set
list all include shell variable and function

##### # && || 執行順序

    true   && echo "true &&"   # output
    true   || echo "true ||"
    false  && echo "false &&"
    false  || echo "false ||"  # output
output:
    true &&
    false ||




### 特殊作用符號

- stdin , stdout , stderr  
    - stdin ,  0 as < filename
    - stdout , 1 as > or >>(append)
    - stderr , 2 as 

2>&1 將stderr append 到 stdout
echo "test" > outputfile 2>error_log



ref. [link](http://tobala.net/x/Linux2008/Linux-01SYS-200906.html)
- bash script

[bash toturial](http://linuxcommand.org/index.php)

#### split string to array

    sentence="this is a story"
    stringarray=($sentence) => (this,is,a,story)
    echo ${stringarray[0]} => this

    echo "$array[@]: -1:1}
    echo "${array[-1]}"
    echo "${#array[@]}"

    IN="bla@some.com;john@home.com"
    arrIN=(${IN//;/ }
    )for index in "${!array[@]}"
    do
        echo "$index ${array[index]}"
    done



[] condition 
gt ge lt le eq nq || &&  ! 
comparsion http://www.tldp.org/LDP/abs/html/comparison-ops.html

it_ver=($(git --version))   
                   
git_ver=(${git_ver[2]//./ }) 
echo ${git_ver[0]}                                                  
echo ${git_ver[1]}                                                
echo ${git_ver[2]}  



 make -C /path/to/dir

bash prompt(PS1):
	export PS1="ps1 format";
	ps1 generator , https://www.kirsle.net/wizards/ps1.html

	ex:
	export PS1="\[$(tput bold)\]\[$(tput setaf 3)\]\u\[$(tput sgr0)\]@\[$(tput bold)\]\[$(tput setaf 2)\]\h\[$(tput sgr0)\]\[$(tput bold)\] > \[$(tput sgr0)\]";
	export PS1='\033[1;33m[\u@\h]\033[0m \@ \033[0;36m\w\033[0m\$ ';

bash_profile


[bash history expansion](http://www.thegeekstuff.com/2011/08/bash-history-expansion/)


Bash 內建環境變數
Name	Function
USER	The name of the logged-in user
UID	The numeric user id of the logged-in user
HOME	The user's home directory
PWD	The current working directory
SHELL	The name of the shell
$	The process id (or PIDof the running bash shell (or other) process
PPID	The process id of the process that started this process (that is, the id of the parent process)
?	The exit code of the last command


vim colortheme and syntax  on comment






### # shell script syntax

##### # basic

function
func_name () {
    $1 $2 for function parameter
}



##### # parameters

standard input
```
$1 $2 .... ,
$# for total count
```


Option  Meaning 中文解釋
-a  The variables are treated as arrays 當成 arrays 使用
-f  Use function names only 用來顯示目前所定義的 function names ; 含 function 內容
-F  Display function names without defintions   只顯示目前所定義的 function names
-i  The variables are treated as integers   當成整數使用
-r  Makes the variables read-only   宣告成唯讀變數
-x  Marks the variables for export via the environment  將變數透過 export 成為環境變數




##### # syntax
for variable
`${var}`

for cmd
`$(mv a b) = `mv a b``



##### # I/O redirection


`ls > file`
append to file
`ls >> file`

file as a std input to sort and output result to files
`sort < file > file2`

pipeline , as std input to less
`ls -ls | less`






##### # array
declare -i i=100 j=3
declare -ar array=(1 2 3 4 5 6 7 8 9 0) # set array (read only array)

name=(hatter [5]=duchess alice)
=>  count=3 , ${name[@]}==(hatter duchess alice) ,
    ${name[0]}==hatter , ${name[5]}==duchess , ${name[6]}==alice

    ${name[@]}==hatter duchess alice
    ${#name[@]}==3

##### # loop
for i in 1 2 3 4 5 .. N do
done

for i in {1..5} do
done


seperator
```
IFS='
'
```

output /etc/hosts and seperate with IFS
```
for i in `cat /etc/hosts` ; do
    read file and seperate by IFS
done
```

read from file /etc/hosts
```
{ while read line ; do
} < /etc/hosts
```



##### # if else

```
if [ $(($i > $j)) = 1 ] ; then
else
fi
```
