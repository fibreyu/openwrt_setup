#!/bin/sh
#
# 用于阿里云解析的DNS更新脚本
# 阿里云解析API文档 https://help.aliyun.com/document_detail/29739.html
#
# 本脚本由 dynamic_dns_functions.sh 内的函数 send_update() 调用
# 
# 需要在 /etc/config/ddns 中设置的选项
# option username - 阿里云API访问账号 Access Key ID。可通过 aliyun.com 帐号管理的 accesskeys 获取, 或者访问 https://ak-console.aliyun.com
# option password - 阿里云API访问密钥 Access Key Secret
# option domain   - 完整的域名。建议主机与域名之间使用 @符号 分隔，否则将以第一个 .符号 之前的内容作为主机名
#

# 检查传入参数
[ -z "$username" ] && write_log 14 "Configuration error! The 'username' that holds the Alibaba Cloud API access account cannot be empty"
[ -z "$password" ] && write_log 14 "Configuration error! The 'password' that holds the Alibaba Cloud API access account cannot be empty"

# 在 dynamic_dns_functions.sh 已定义如下变量
# CURL=$(command -v curl)
# CURL_SSL not empty then SSL support available
# CURL_SSL=$($CURL -V 2>/dev/null | grep -F "https")
# CURL_PROXY not empty then Proxy support available
# CURL_PROXY=$(find /lib /usr/lib -name libcurl.so* -exec strings {} 2>/dev/null \; | grep -im1 "all_proxy")

# 检查外部调用工具
[ -n "$CURL" ] || write_log 13 "Alibaba Cloud API communication require cURL support. Please install"
[ $use_https = 1 ] && [ -z "$CURL_SSL" ] && write_log 13 "Alibaba Cloud API communication require cURL with SSL support. Please install"
[ -n "$CURL_PROXY" ] || write_log 13 "cURL: libcurl compiled without Proxy support"
command -v sed >/dev/null 2>&1 || write_log 13 "Sed support is required to use Alibaba Cloud API, please install first"
command -v openssl >/dev/null 2>&1 || write_log 13 "Openssl-util support is required to use Alibaba Cloud API, please install first"

# 变量声明
local __HOST __DOMAIN __TYPE __CMDBASE __STATUS __RECID __RECIP __TTL __SEPARATOR __URLARGS __URLBASE
local __TTL=600

# 设置get请求参数分隔符
local __SEPARATOR="&"

# 设置记录类型
[ $use_ipv6 = 0 ] && __TYPE="A" || __TYPE="AAAA"
[ $use_https = 0 ] && __URLBASE="http://alidns.aliyuncs.com/" || __URLBASE="https://alidns.aliyuncs.com/"

# 从 $domain 分离主机和域名
[ "${domain:0:2}" = "@." ] && domain="${domain/./}" # 主域名处理，以@.开头，去掉.
[ "$domain" = "${domain/@/}" ] && domain="${domain/./@}" # 未找到分隔符，兼容常用域名格式，即不存在@的，把第一个.替换为@
__HOST="${domain%%@*}"  # 删除最后一个@和@之后的东西
__DOMAIN="${domain#*@}"  # 删除第一个@和@之前的东西
[ -z "$__HOST" -o "$__HOST" = "$__DOMAIN" ] && __HOST="@"  # 主机名和域名相同即输入了域名如com

# 百分号编码
percentEncode() {
	# 将制定字符替换为空字符
	if [ -z "${1//[A-Za-z0-9_.~-]/}" ]; then
		echo -n "$1"
	else
		local string=$1; local i=0; local ret chr
		while [ $i -lt ${#string} ]; do
			chr=${string:$i:1}

			# 参考 https://www.gnu.org/software/bash/manual/bash.html#index-printf
			# Arguments to non-string format specifiers are treated as C language constants, 
			# except that a leading plus or minus sign is allowed, 
			# and if the leading character is a single or double quote, 
			# the value is the ASCII value of the following character.
			# etc. ord() {printf "%d" "\"$1"}
			# chr() {printf "\x$(printf "%x" "$1")"}
			[ -z "${chr#[^A-Za-z0-9_.~-]}" ] && chr=$(printf '%%%02X' "'$chr")
			ret="$ret$chr"
			i=$(( $i + 1 ))
		done
		echo -n "$ret"
	fi
}

# 构造基本通信命令
build_command() {
	__CMDBASE="$CURL -Ss"
	# 绑定用于通信的主机网卡，如果设置了逻辑网口
	if [ -n "$bind_network" ]; then
		local __DEVICE
		# 本函数在 ./lib/functions/network.sh
		network_get_physdev __DEVICE $bind_network  || write_log 13 "Can not detect local device using 'network_get_physdev $bind_network' - Error: '$?'"
		write_log 7 "Force communication via device '$__DEVICE'"
		__CMDBASE="$__CMDBASE --interface $__DEVICE"
	fi
	# 强制设定IP版本
	if [ $force_ipversion = 1 ]; then
		[ $use_ipv6 = 0 ] && __CMDBASE="$__CMDBASE -4" || __CMDBASE="$__CMDBASE -6"
	fi
	# 设置CA证书参数
	if [ $use_https = 1 ];then
		if [ "$cacert" = IGNORE ];then
			__CMDBASE="$__CMDBASE --insecure"
		elif [ -f "$cacert" ];then
			__CMDBASE="$__CMDBASE --cacert $cacert"
		elif [ -d "$cacert" ];then
			__CMDBASE="$__CMDBASE --capath $cacert"
		elif [ -n "$cacert" ];then
			write_log 14 "No valid certificate(s) found at '$cacert' for HTTPS communication"
		fi
	fi
	# 如果没有设置，禁用代理
	[ -z "$proxy" ] && __CMDBASE="$__CMDBASE --noproxy '*'"
}

# 构造阿里云通用解析请求参数
build_Request() {
	local args=$*; local string
	local HTTP_METHOD="GET"

	# 添加请求参数
	__URLARGS=
	for string in $args; do
		case "${string%%=*}" in
			Format|TTL|Version|AccessKeyId|SignatureMethod|Timestamp|SignatureVersion|SignatureNonce|Signature) ;; # 过滤公共参数
			*) __URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}");;
		esac
	done
	# 去掉第一个字符&
	__URLARGS="${__URLARGS:1}"

	# 附加公共参数
	string="Format=JSON"; __URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="TTL=$__TTL";__URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Version=2015-01-09"; __URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="AccessKeyId=$username"; __URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureMethod=HMAC-SHA1"; __URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ'); __URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureVersion=1.0"; __URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureNonce="$(cat '/proc/sys/kernel/random/uuid'); __URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Line=default";__URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")

	# 对请求参数进行排序，用于生成签名
	# 先按分隔符 & 将参数分行
	# 's/\'"${__SEPARATOR}"'/\n/g' 的理解是 's/\' + "${__SEPARATOR}" + '/\n/g' 即 s/\&/\n/g  即 sed 's/\&/\n/g'  &在匹配串中可不转义，在替换串中必须转义否则表示前面的整个字符串用于追加字符
	# 然后按行进行排序
	# 最后再整合
	# :label 读取第一行到模式空间并打上标签  N 读取下一行到模式空间  然后替换换行为分隔符  b label是返回标签处
	# 类似的有
	# sed ':a;N;$!ba;s/\n/ /g' file
	# :a create a label 'a'
	# N append the next line to the pattern space
	# $! if not the last line, ba branch (go to) label 'a'
	# s substitute, /\n/ regex for new line, / / by a space, /g global match (as many times as it can)
	# sed will loop through step 1 to 3 until it reach the last line, getting all lines fit in the pattern space where sed will substitute all \n characters
	string=$(echo -n "$__URLARGS" | sed 's/\'"${__SEPARATOR}"'/\n/g' | sort | sed ':label; N; s/\n/\'"${__SEPARATOR}"'/g; b label')
	# 构造用于计算签名的字符串
	string="${HTTP_METHOD}${__SEPARATOR}"$(percentEncode "/")"${__SEPARATOR}"$(percentEncode "$string")
	# 字符串计算签名HMAC值
	local signature=$(echo -n "$string" | openssl dgst -sha1 -hmac "${password}&" -binary | openssl base64)

	# 附加签名参数
	string="Signature=$signature"; __URLARGS="$__URLARGS${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
}

# 用于阿里云API的通信函数
aliyun_transfer() {
	local __PARAM=$*
	local __CNT=0
	local __RUNPROG __ERR PID_SLEEP __ERR_CODE
	local __RESP

	[ $# = 0 ] && write_log 12 "'aliyun_transfer()' Error - wrong number of parameters"

	# 执行 $cnt 次尝试
	while : ; do

		# 生成请求链接，链接跟时间有关，每次都要重新生成
		build_Request $__PARAM
		__RUNPROG="$__CMDBASE '${__URLBASE}?${__URLARGS}'"
		write_log 7 "#> $__RUNPROG"

		# 发送请求
		__RESP=`eval $__RUNPROG 2>&1`
		__ERR=$?
		[ $__ERR = 0 ] && { write_log 5 "get response: $__RESP"; break; }
		
		# get error
		write_log 3 "[$__RESP]" 
		write_log 3 "curl error code: '$__ERR'"
		# write_log 7 "$(cat $ERRFILE)"

		if [ $VERBOSE -gt 1 ];then
			write_log 4 "Transfer failed - detailed mode: $VERBOSE - Do not try again after an error"
			return 1
		fi

		__CNT=$(( $__CNT + 1 ))
		[ $retry_count -gt 0 -a $__CNT -gt $retry_count ] && \
			write_log 14 "Transfer failed after $retry_count retries"

		write_log 4 "Transfer failed - $__CNT Try again in $RETRY_SECONDS seconds"
		sleep $RETRY_SECONDS &
		PID_SLEEP=$!
		wait $PID_SLEEP
		PID_SLEEP=0
	done
	__ERR_CODE=`jsonfilter -s "$__RESP" -e "@.Code"`
	# 没有错误码则返回获取的结果
	[ -z "$__ERR_CODE" ] && { echo $__RESP; return 0; }
	
	# 分析错误码
	case $__ERR_CODE in
		LastOperationNotFinished)
			write_log 4 "Last operation was not completed, retrying after 2 seconds.";;
		InvalidTimeStamp.Expired)
			write_log 4 "Timestamp error, retrying after 2 seconds.";;
		InvalidAccessKeyId.NotFound)
			__ERR_CODE="Invalid AccessKey ID";;
		SignatureDoesNotMatch)
			__ERR_CODE="Invalid AccessKey Secret";;
		InvalidDomainName.NoExist)
			__ERR_CODE="The domain name you are operating on no longer exists.";;
		InvalidDomainName.Format)
			__ERR_CODE="Domain name format is incorrect.";;
		DomainRecordConflict)
			__ERR_CODE="There is a conflict with another record and it cannot be added.";;
		Forbidden.NotHichinaDomain)
			__ERR_CODE="The domain name is not an Alibaba Cloud domain.";;
		DomainRecordLocked)
			__ERR_CODE="Prohibition operation: Resolution records are locked.";;
		chgRRfail)
			__ERR_CODE="Failed to modify the resolution record.";;	
		delRRfail)
			__ERR_CODE="Failed to delete the resolution record.";;
		addSoafail)
			__ERR_CODE="Failed to create domain name.";;
	esac
	
	local __info="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR : [$__ERR_CODE] - Process Terminated"
	# printf "%s\n" " $__info" >> $LOGFILE
	write_log 13 ${__info}
	return 1
}

# 添加解析记录
add_domain() {
	local __VALUE
	local __RECID
	__VALUE=`aliyun_transfer "Action=AddDomainRecord" "DomainName=${__DOMAIN}" "RR=${__HOST}" "Type=${__TYPE}" "Value=${__IP}"`
	[ $? = 1 ] && { write_log 7 "network error to add domain record."; return 1; }
	__RECID=`jsonfilter -s "$__VALUE" -e "@.RecordId"`
	[ -z "$__RECID" ] && write_log 14 "Failed to add a new resolution record."
	write_log 7 "Successfully added resolution record.: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN]-[$__IP]"
	return 0
}


# 修改解析记录
update_domain() {
	local __VALUE
	local __RECID
	__VALUE=`aliyun_transfer "Action=UpdateDomainRecord" "RecordId=${__RECID}" "RR=${__HOST}" "Type=${__TYPE}" "Value=${__IP}" "TTL=$__TTL"`
	[ $? = 1 ] && { write_log 7 "network error to update domain record."; return 1; }
	__RECID=`jsonfilter -s "$__VALUE" -e "@.RecordId"`
	[ -z "$__RECID" ] && write_log 14 "Failed to modify the resolution record."
	write_log 7 "Successfully modified the resolution record: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN]-[IP:$__IP]-[TTL:$__TTL]"
	return 0
}

# 启用解析记录
enable_domain() {
	local __VALUE
	local __STATUS
	__VALUE=`aliyun_transfer "Action=SetDomainRecordStatus" "RecordId=${__RECID}" "Status=Enable"`
	[ $? = 1 ] && { write_log 7 "network error to enable domain record."; return 1; }
	__STATUS=`jsonfilter -s "$__VALUE" -e "@.Status"`
	[ "$__STATUS" != "Enable" ] && write_log 14 "Failed to enable resolution record."
	write_log 7 "Successfully enabled resolution record."
	return 0
}

# 获取子域名解析记录列表
describe_domain() {
	local __RESP
	local ret=0
	__RESP=`aliyun_transfer "Action=DescribeSubDomainRecords" "SubDomain=${__HOST}.${__DOMAIN}" "Type=$__TYPE" "DomainName=${__DOMAIN}"`
	[ $? != 0 ] && return -1
	write_log 7 "Get the resolution record: $__RESP" 
	__RESP=`jsonfilter -s "$__RESP" -e "@.DomainRecords.Record[@]"`
	if [ -z $__RESP ]; then
		write_log 7 "Resolution record does not exist: [$([ "$__HOST" = @ ] || echo $__HOST.)$__DOMAIN]"
		ret=1
	else
		__STATUS=`jsonfilter -s "$__RESP" -e "@.Status"`
		__RECIP=`jsonfilter -s "$__RESP" -e "@.Value"`
		__RECID=`jsonfilter -s "$__RESP" -e "@.RecordId"`
		if [ "$__STATUS" != "ENABLE" ];then
			write_log 7 "The resolution record is disabled."
			ret=$(( $ret | 2 ))
		fi
		if [ "$__RECIP" != "$__IP" ];then
			__TTL=`jsonfilter -s "$__RESP" -e "@.TTL"`
			write_log 7  "The resolution record needs to be updated: [Resolution record IP:$__RECIP] [Local IP:$__IP]"
			ret=$(( $ret | 4 ))
		fi
	fi
	return $ret
}


build_command
describe_domain
ret=$?

if [ $ret = 0 ]; then
	write_log 7 "Resolution record does not need to be updated: [Resolution record IP:$__RECIP] [Local IP:$__IP]"
elif [ $ret = -1 ]; then
	write_log 7 "network error to get resolution record."
elif [ $ret = 1 ]; then
	write_log 7 "add domain."
	sleep 3 && add_domain
else
	[ $(( $ret & 2 )) -ne 0 ] && { sleep 3; write_log 7 "enable domain."; enable_domain; }
	[ $(( $ret & 4 )) -ne 0 ] && { sleep 3; write_log 7 "update domain."; update_domain; }
fi

return 0