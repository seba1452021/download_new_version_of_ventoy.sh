#!/bin/sh

 if [ ! -e "/dev/null" ]; then exit 1; fi
 if [ -z "$PATH" ]; then exit 1; fi

 exist_curl=n exist_toybox=n exist_busybox=n exist_wget=n

 if [ "$(toybox --help 2>/dev/null)" != "" ]; then exist_toybox=y; fi
 if [ "$(busybox --help 2>/dev/null)" != "" ]; then exist_busybox=y; fi
 if [ "$(curl --help 2>/dev/null)" != "" ]; then exist_curl=y; fi
 if [ "$(wget --help 2>/dev/null)" != "" ]; then exist_wget=y; fi

 are_there_any="$exist_curl $exist_toybox $exist_busybox $exist_wget"
 case $are_there_any in *y*) ;; *) exit 1 ;; esac

 if [ "$(wget --help 2>/dev/null)" = "" ]; then
 if [ "$exist_busybox" = "y" ]; then alias wget='busybox wget'; fi
 if [ "$exist_toybox" = "y"  ]; then alias wget='toybox wget'; fi
 program_to_download="wget"
 elif [ "$(curl --help 2>/dev/null)" != "" ];
 then program_to_download="curl"
 fi
 
 case $program_to_download in curl) last_args="-s" ;; wget) first_args="-O -" && last_args="-q" ;; esac && export last_args

 reading () { url="${1}"; $program_to_download $first_args $url $last_args; }
 
 url="https://github.com/ventoy/Ventoy/releases"
 
 if [ "$(reading ${url})" = "" ]; then exit 1; fi
 
 export data=$(reading ${url} | grep 'linux.tar.gz: ' | head -n +1); 
 export sha_256_sum=$(echo $data | cut -d ' ' -f 2); 
 export file=$(echo $data | sed -e 's/://g' | cut -d ' ' -f 1);
 export version=$(echo $file | sed -e 's/ventoy-/v/g' -e 's/-linux.tar.gz//g');
 if [ -f releases ]; then rm releases; fi
 
 export new_url="https://github.com/ventoy/Ventoy/releases/download/${version}/${file}"; echo "URL: ${new_url}" && echo "SHA-256: ${sha_256_sum}"
 
 download_ventoy () {
 first_args="" seconds_args="" url="${1}" && export archive="${2}";
 case $program_to_download in curl) first_args="-O" ;; wget) seconds_args="-O" ;; esac
 $program_to_download $first_args $url $seconds_args $archive $last_args
 }
 
 check_download () { file_sum="$(dirname $archive)/sha256.txt"; echo "$sha_256_sum" >> $file_sum; sha256sum -c $file_sum 2>/dev/null; }
 
 download_ventoy ${new_url} ventoy-linux.tar.gz; if [ "$(sha256sum --help 2>/dev/null)" != "" ]; then check_download; fi
  
 if [ -f "$archive" ]; then num=0; else echo "Error, $archive no fue obtenido.." && echo "Programa usado: $program_to_download " && num=1; fi
 
 if [ "$num" != "1" ]; then file ${archive} | cut -d ',' -f 1; fi | sed -e "s,$(dirname ${archive})/,,g"
 
 exit $num
 
 #unpack  ventoy-linux.tar.gz --> tar xzf download/ventoy-linux.tar.gz
