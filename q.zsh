function qfcz (){
	zdirselect=`z | sort -g -r | peco | cut -d  ' ' -f 2- | sed 's/ //g'`
	if [ `echo "$LBUFFER" | wc -w | tr -d ' '` -eq 0 ];then
		cd $zdirselect
		case $1 in
			t) ls -altr ;;
			g) gls -slhAF --color ;;
			a|"") ls -slhAF ;;
			*) ls ;;
		esac
	
		zle reset-prompt
	else
		LBUFFER+="$zdirselect"
	fi
}
zle -N qfcz
bindkey '^j' qfcz

function cdup_dir() {
	if [[ -z "$BUFFER" ]]; then
		echo
		cd ..
		ls -aF
		zle reset-prompt
	else
		zle self-insert 'k'
	fi
}
zle -N cdup_dir
bindkey '^k' cdup_dir

function qfcz-select (){
	com='$SHELL -c "ls -AF . | grep / "'
	while [ $? = 0 ]
	do
		cdir=`eval $com | peco`
		if [ $? = 0 ];then
			#LBUFFER+="$cdir"
			#CURSOR=$#BUFFER
			cd $cdir
			eval $com
		else
			break
		fi
	done
	zle reset-prompt
}
zle -N qfcz-select
bindkey '^j^j' qfcz-select

function qfcz-select-file (){
	case $1 in
		"q") unset zdirs;;
		"") zdirs=`z | sort -g -r | peco | cut -d  ' ' -f 2- | sed 's/ //g'`;;
	esac
	
	if [ -z "$zdirs" ];then
		zfiles=`ls -trAF1|grep -v /`
	else
		zfiles=`zsh -c "cd $zdirs;ls -trAF1|grep -v /"`
	fi
	if [ "$zfiles" = "total 0" ] || [ -z "$zfiles" ];then
		qfcz-select
		zfiles=`zsh -c "ls -trAF1"|grep -v /`
	fi

	zfiles=`echo "$zfiles"|peco|sed 's/*$//g'`

	if [ `echo "$zfiles"|wc -l` -eq 1 ];then
		zfiles=`echo "$zfiles"|tr '\n' ','|sed 's/,$//g'`
	else
		zfiles={`echo "$zfiles"|tr '\n' ','|sed 's/,$//g'`}
		echo "$zfiles"
	fi
	if [ -z "$zdirs" ];then
		BUFFER+=" ${zfiles}"
	else
		BUFFER+=" ${zdirs}/${zfiles}"
	fi
}
zle -N qfcz-select-file
bindkey '^j^k' qfcz-select-file

function peco-current-dir-file (){
	if zsh -c "ls -trAF1"|grep -v / > /dev/null 2>&1;then
		zfiles=`zsh -c "ls -trAF1"|grep -v /`
		if [ "$zfiles" != "total 0" ] || [ -z "$zfiles" ];then
			zfiles=`echo "$zfiles"|peco`
			if [ `echo "$zfiles"|wc -l` -eq 1 ];then
				zfiles=`echo "$zfiles"|tr '\n' ','|sed 's/*$//g'`
				BUFFER+="${zfiles%,}"
			else
				zfiles=`echo "$zfiles"|tr '\n' ','|sed 's/*$//g'`
				BUFFER+="{${zfiles%,}}"
			fi

		fi
	else
		qfcz-select-file q
	fi
}
zle -N peco-current-dir-file 
bindkey '^f' peco-current-dir-file

function peco-select-file (){
	qfcz
	case $1 in
		f) zfileselect=`zsh -c "ls -trAF1|grep -v /"|peco|tr '\n' ','|sed 's/*$//g'`;;
		s) zfileselect=`zsh -c "ls -trFA1|grep '\*$'"|peco|sed 's/*$//g'|tr '\n' ','`;;
		d) zfileselect=`find . -maxdepth 1 -type d|peco|tr '\n' ','`;;
		a|"") zfileselect=`zsh -c "ls -trA1"|peco|tr '\n' ','`;;
	esac
	LBUFFER+="{${zfileselect%,}}"
}
zle -N peco-select-file 
bindkey '^f^f' peco-select-file

function peco-select-file-option (){
	s=`echo -e "file\nscript\ndirectory\nall"|peco|cut -b 1`
	peco-select-file $s
}
zle -N peco-select-file-option
bindkey '^f^p' peco-select-file-option

case $OSTYPE in
	linux*)
		function peco-select-history() {
			local tac
			if which tac > /dev/null; then
				tac="tac"
			else
				tac="tail -r"
			fi
			BUFFER=$(\history -rn 1 | \
				eval $tac | \
				peco --query "$LBUFFER")
			CURSOR=$#BUFFER
			zle clear-screen
		}
		;;
	darwin*)
		function peco-select-history() {
			BUFFER=`history -rn 1 | peco`
			CURSOR=$#BUFFER
			zle clear-screen
		}
		;;
esac
zle -N peco-select-history
bindkey '^h^j' peco-select-history
