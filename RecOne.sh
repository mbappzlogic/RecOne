#!/bin/bash

echo -e "\033[1;31m                        ***** ***                               * ***                           "
echo -e "\033[1;31m                      ******  * **                             *  ****                          "
echo -e "\033[1;31m                      **   *  *  **                           *  *  ***                         "
echo -e "\033[1;31m                      *    *  *   **                         *  **   ***                        "
echo -e "\033[1;31m                           *  *    *                        *  ***    ***                       "
echo -e "\033[1;31m                          ** **   *       ***       ****    **   **     ** ***  ****       ***  "
echo -e "\033[1;31m                          ** **  *       * ***     * ***  * **   **     **  **** **** *   * *** "
echo -e "\033[1;31m                          ** ****       *   ***   *   ****  **   **     **   **   ****   *   ***"
echo -e "\033[1;31m                          ** **  ***   **    *** **         **   **     **   **    **   **    ***"
echo -e "\033[1;31m                          ** **    **  ********  **         **   **     **   **    **   ********  "
echo -e "\033[1;31m                          *  **    **  *******   **          **  **     **   **    **   *******   "
echo -e "\033[1;31m                             *     **  **        **           ** *      *    **    **   **        "
echo -e "\033[1;31m                         ****      *** ****    * ***     *     ***     *     **    **   ****    * "
echo -e "\033[1;31m                        *  ****    **   *******   *******       *******      ***   ***   *******  "
echo -e "\033[1;31m                       *    **     *     *****     *****          ***         ***   ***   *****  "
echo -e "\033[1;31m                       *                                                                         "
echo -e "\033[1;31m                        **                                                                       "
echo -e "\033[1;33m                                                      @appzlogic.com                        \033[0m"

while [[ $option != "exit" ]]; do
# Prompt user to provide a choice 
echo " "
echo 
echo  -e "\033[1;32m 1.Subdomain Enumeration & Banner Grabing  \033[0m"
echo  -e "\033[1;32m 2.Indepth Subdomains Enumeration \033[0m"
echo  -e "\033[1;32m 3.Port Scan \033[0m"
echo  -e "\033[1;32m 4.Reconnaissance \033[0m"


#echo -e "\033[1;32m Select: read option \033[0m "
echo
read -p  "Select: " option

#checking options for subdomain finding.
if [ $option -eq 1 ]
then 
read -p $'\e[1;36mEnter domain name (e.g. example.com): \e[0m' target
echo -e "\e[1;32mYou entered: $target\e[0m"

mkdir -p  $target/subdomain


#findomain

if which findomain >/dev/null; then
        echo "finding subdomains using findomain"
        findomain -t $target | tee -a $target/subdomain/$target.subdomain
else
    echo "Findomain is not installed. Please install Findomain to use this script."
fi



#Sublist3r
if which sublist3r >/dev/null; then

   sublist3r -e "baidu,yahoo,google,bing,ask,netcraft,dnsdumpster,threatcrowd,ssl,passivedns" -d  $target | tee -a  $target/subdomain/$target.subdomain

else
    echo "Sublist3r is not installed. Please install Sublist3r to use this script."
fi

#dnsmap
if which dnsmap >/dev/null; then
        echo " "
	echo "finding subdomains using dnsmap"
	dnsmap $target | tee -a $target/subdomain/$target.subdomain
else
    echo "dnsmap is not installed. Please install dnsmap to use this script."
fi


#amass

if which amass >/dev/null; then
	echo " "
	echo "finding subdomains using amass"
        amass enum -d $target | tee -a $target/subdomain/$target.subdomain
else
    echo "amass is not installed. Please install amass to use this script."
fi

#assetfinder

if which assetfinder >/dev/null; then

        assetfinder $target | tee -a  $target/subdomain/$target.subdomain
else
    echo "assetfinder is not installed. Please install assetfinder to use this script."
fi

#subfinder 


if which assetfinder >/dev/null; then

        subfinder -d $target | tee -a $target/subdomain/$target.subdomain
else
    echo "subfinder is not installed. Please install subfinder to use this script."
fi


cat $target/subdomain/$target.subdomain |sort -u | uniq | tee -a $target/subdomain/$target.subdomain

#shuffledns

if which shuffledns >/dev/null; then

	shuffledns -d $target -list $target/subdomain/$target.subdomain -r resolvers.txt   

else
    echo "shuffledns is not installed. Please install shuffledns to use this script."
fi

#checking IP address of subdomains.

echo "Determine IP of the subdomains found"
#finding live subdomains
cat $target/subdomain/$target.subdomain | httpx --silent |sort -u | uniq | tee -a  $target/subdomain/$target.livesubdomain
rm  $target/subdomain/$target.subdomain

input_file="$target/subdomain/$target.livesubdomain"

echo " "
echo "Finding IP addresses using host command..."
echo " "
# Loop through each subdomain in the input file and obtain its IP addresses using host command
while read subdomain; do
    ipv4=$(host "$subdomain" | awk '/has address/ {print $NF}')
    ipv6=$(host "$subdomain" | awk '/has IPv6 address/ {print $NF}')
    echo "${subdomain}: IPv4: ${ipv4}, IPv6: ${ipv6}" | sort| uniq | tee -a $target/subdomain/$target.IP

done < "$input_file"



#banner grabbing 
mkdir   $target/banner/
# Use Wget to download the target's homepage
wget "http://$target" -O "$target/banner/homepage.html"

# Use cURL to retrieve HTTP headers from the target
curl -I "http://$target" > "$target/banner/http_headers.txt"

# Use Nmap to scan for open ports and output results to a file
nmap --top-ports 100 -sV -Pn -oN $target/banner/nmap.txt "$target"

# Use Nmap to extract a list of open TCP ports and output results to a file
grep -E '^[0-9]+/tcp +open' $target/banner/nmap.txt | cut -d '/' -f 1 | tee $target/banner/open_ports.txt 
#grep -oP '\d{1,5}/open/\S+' $target/banner/nmap.txt | cut -d '/' -f 1,3 > $target/banner/open_ports.txt

# Use Nc to check for open TCP ports
while read port; do
    echo "Checking port $port"
    if nc -vz "$target" "$port" &> /dev/null; then
        nc -vz "$target" "$port" > "$target/banner/port_$port.txt"
    fi
    if [ "$port" -eq "25" ]; then
        echo "Connecting to port $port (SMTP) and retrieving banners for $target"
        (sleep 1; echo "QUIT") | telnet "$target" "$port" | grep -i banner > "$target/banner/banner_smtp_$target.txt" &
    elif [ "$port" -eq "21" ]; then
        echo "Connecting to port $port (FTP) and retrieving banners for $target"
        socat TCP:"$target":"$port" stdio | grep -i version > "$target/banner/banner_ftp_$target.txt" &
    fi
done < $target/banner/open_ports.txt

# Use Nc to check all open TCP ports
echo "Checking all open TCP ports"
nmap --top-ports 100  --open -T4 "$target" | grep 'open' | cut -d '/' -f 1 | while read port; do
    echo "Checking port $port"
    if nc -vzw "$target" "$port" &> /dev/null; then
        nc -vzw "$target" "$port" > "$target/banner/port_$port.txt"
    fi
done


elif [ $option -eq 2 ] 
then 
echo -e "\e[1;32mSubdomain Bruteforcing\e[0m"
echo " "
read -p $'\e[1;36mEnter domain name (e.g. example.com): \e[0m' target
echo -e "\e[1;32mYou entered: $target\e[0m"
echo " "

#bruteforcing subdomains

if which findomain >/dev/null; then

 echo "Bruteforcing subdomains using findomain"

findomain -t $target | tee -a $target/subdomain/$target.subdomain
cat $target/subdomain/$target.subdomain | httpx  |sort -u | uniq | tee -a  $target/subdomain/$target.alivesubdomain

for domain in $(cat $target/subdomain/$target.alivesubdomain); do findomain  -t $domain  -q;done  | tee -a  $target/subdomain/$target.subdomain

cat $target/subdomain/$target.subdomain | httpx -silent  | tee -a $target/subdomain/live-subdomain

else
    	echo "Findomain is not installed. Please install Findomain to use this script."
fi

#subbrute
if locate subbrute.py >/dev/null; then

python3 /home/kali/dump/subbrute/subbrute.py $domain resolvers.txt --output=$target/subdomain/$target.live-subdomains

cat  $target/subdomain/$target.alivesubdomain  | sed 's/https:\/\///' |  sed 's/http:\/\///' | tee -a  $target/subdomain/$target.alivesub   
for domain in $(cat $target/subdomain/$target.alivesub); do python3 /home/kali/dump/subbrute/subbrute.py $domain resolvers.txt ;done | tee -a $target/subdomain/$target.live-subdomains  
cat $target/subdomain/$target.live-subdomains | httpx --silent  | tee -a $target/subdomain/live-subdomain

rm $target/subdomain/$target.subdomain
rm $target/subdomain/$target.alivesubdomain
rm $target/subdomain/$target.alivesub
rm $target/subdomain/$target.live-subdomains
else
    	echo "Subbrute is not installed. Please install Subbrute to use this script."
fi

elif [ $option -eq 3 ]
then

read -p $'\e[1;36mEnter domain name (e.g. example.com): \e[0m' target
echo -e "\e[1;32mYou entered: $target\e[0m"

mkdir -p  $target/$target.portscan

nmap -sV -p- $target -Pn | tee -a  $target/$target.portscan/$target.nmap.allports 


cat $target.livesubdomain | httpx --silent  |sort -u | uniq >  $target/$target.portscan/$target.livesubdomains

cat $target/$target.portscan/$target.livesubdomains | awk  '{print$1}' | awk -F'//' '{print $2}' | sort -u | uniq >  $target/$target.portscan/$target.finalsubdomains

cat $target/$target.portscan/$target.subdomains  | sort -u |uniq | tee  $target.subdomains

echo "Finding open ports using nmap "
nmap -sV -v -iL $target/$target.portscan/$target.finalsubdomains -Pn  | tee -a $target/$target.portscan/$target.nmap.allports

#echo "open ports list====>"
echo ""
cat $target/$target.portscan/$target.nmap.allports | grep "Nmap scan report\|open"  | tee -a $target/$target.portscan/$target.nmap.openports

for domain in $(cat $target/$target.portscan/$target.finalsubdomains ); do  rustscan -a $domain --range 1-2000  | tee -a $target/$target.portscan/$target.rustscan.allports ; done
cat $target/$target.portscan/$target.rustscan.allports | grep "Nmap scan report\|open"  | tee -a  $target/$target.portscan/$target.rustscan.openports


cat $target/$target.portscan/$target.nmap.allports | grep "Nmap scan report" |  awk -F'[()]' '{print $2}' | sort -u | uniq |  tee  $target/$target.portscan/$target.ips

for domain in $(cat $target/$target.portscan/$target.ips ); do  sudo masscan $domain -p1-2000 | tee -a $target/$target.portscan/$target.masscan.openports ; done


cat $target/$target.portscan/$target.nmap.allports | tee -a $target/$target.portscan/$target.allopenports
cat $target/$target.portscan/$target.rustscan.allports | tee -a  $target/$target.portscan/$target.allopenports
cat $target/$target.portscan/$target.masscan.openports | tee -a $target/$target.portscan/$target.allopenports

cat $target/$target.portscan/$target.allopenports | grep "Nmap scan report for\|open" | sed '/Discovered/d' | sed '/Looks/d' |  awk '!x[$0]++' >>  $target/$target.portscan/$target.allopenport

rm $target/$target.portscan/$target.finalsubdomains
rm $target/$target.portscan/$target.nmap.allports
rm $target/$target.portscan/$target.rustscan.allports
rm $target/$target.portscan/$target.rustscan.openports
rm $target/$target.portscan/$target.masscan.openports
rm $target/$target.portscan/$target.ips
rm $target/$target.portscan/$target.allopenports
rm $target/$target.portscan/$target.livesubdomains
rm $target/$target.portscan/$target.nmap.openports


echo ""
echo -e "\033[1;32m Results are saved in $target/$target.portscan/$target.allopenport \033[0m " 
echo ""
#cat $target/$target.portscan/$target.allopenports 
echo ""


elif [ $option -eq 4 ]
then 
echo " "
read -p $'\e[1;36mEnter domain name (e.g. example.com): \e[0m' target
echo -e "\e[1;32mYou entered: $target\e[0m"

#touch $target.links

mkdir $target/Reconnaissance

if which gau >/dev/null; then
	echo " "
        echo "Finding Links using Gau "
	gau $target -subs |  sort | uniq  | tee -a  $target/Reconnaissance/$target.links

else
echo " gau is not installed. Please install gau to use this script."
fi

if which gauplus >/dev/null; then
        echo " "
	echo "Finding Links using Gauplus"
	cat $target/subdomain/$target.livesubdomain | gauplus -t 30 | sort | uniq | tee -a  $target/Reconnaissance/$target.links
else
echo " gauplus is not installed. Please install gauplus to use this script."
fi

if which hakrawler >/dev/null; then
        echo " "
	echo "Finding links using hakrawler"
	cat $target/subdomain/$target.livesubdomain | hakrawler -t 30 | sort | uniq | tee -a  $target/Reconnaissance/$target.links

else
echo " hakrawler is not installed. Please install hakrawler to use this script."
fi

if locate linkfinder.py >/dev/null; then
        echo " "
	linkfinder_path=$(locate linkfinder.py | head -n 1 )
	
	echo "$linkfinder_path"  
	echo " "
	echo "Finding links using linkfinder"
	python3 $linkfinder_path -i $target/subdomain/$target.livesubdomain -o cli  |  sort | uniq |  tee -a $target/Reconnaissance/$target.links

else
echo " linkfinder is not installed. Please install linkfinder to use this script."
fi


if which subjs >/dev/null; then
	echo " "
        echo "Finding Links Using subjs"
	echo " "
        cat $target/subdomain/$target.livesubdomain | subjs | sort | uniq | tee -a  $target/Reconnaissance/$target.links
else 
echo " subjs is not installed. Please install subjs to use this script."
fi

cat  $target/Reconnaissance/$target.links | httpx --silent | tee -a  $target/Reconnaissance/$target.links

echo "Sensitive files"
cat  $target/Reconnaissance/$target.links | grep ".xls\|.xlsx\|.sql\|.csv\|.env\|.msql\|.bak\|.bkp\|.bkf\|.old\|.temp\|.db\|.mdb\|.config\|.yaml\|.zip\|.tar\|.git\|.xz\|.asmx\|.vcf\|.pem" | uro | sort | uniq  >>  $target/Reconnaissance/sensitive-file.txt
echo -e "\033[1;32m Results are saved in  $target/Reconnaissance/sensitive-file.txt \033[0m " 
echo " "

echo "Panels"
cat  $target/Reconnaissance/$target.links | grep -i "login\|singup\|admin\|dashboard\|wp-admin\|singin\|administrator\|dana-na\|login/?next/=" | sort | uniq | uro >  $target/Reconnaissance/panel.txt
echo  -e "\033[1;33m Results saved to  $target/Reconnaissance/panel.txt \033[0m"
echo " "

echo "Third Party Assets"
cat  $target/Reconnaissance/$target.links | grep -i "jira\|jenkins\|grafana\|mailman\|+CSCOE+\|+CSCOT+\|+CSCOCA+\|symfony\|graphql\|debug\|gitlab\|phpmyadmin\|phpMyAdmin" | sort | uniq | uro >  $target/Reconnaissance/third-party-assets.txt
echo  -e "\033[1;33m Results saved to  $target/Reconnaissance/third-party-assets.txt \033[0m"
echo " "

echo
echo "E-mails and User-names"  

if which emailfinder >/dev/null; then
        echo " "
	emailfinder -d  $target >  $target/Reconnaissance/emails-usernames.txt

else
    echo "emailfinder is not installed. Please install emailfinder to use this script."
fi
cat  $target/Reconnaissance/$target.links | grep "@" | sort | uniq | uro >>  $target/Reconnaissance/emails-usernames.txt
echo  -e "\033[1;33m Results saved to  $target/Reconnaissance/third-party-assets.txt \033[0m"
echo " "

echo " "
echo "Error(Sensitive-data-exposure)"
cat  $target/Reconnaissance/$target.links | grep "error." | sort | uniq | uro >  $target/Reconnaissance/error.txt
echo  -e "\033[1;33m Results saved to  $target/Reconnaissance/error.txt \033[0m"

echo
echo "Sensitive Path"
cat  $target/Reconnaissance/$target.links | grep -i "root\| internal\| private\|secret" | sort | uniq | uro >  $target/Reconnaissance/sensitive-path.txt
echo  -e "\033[1;33m Results saved to   $target/Reconnaissance/sensitive-path.txt \033[0m"

echo
echo "Robots.txt"
cat  $target/Reconnaissance/$target.links | grep -i robots.txt | sort | uniq | uro >  $target/Reconnaissance/robots.txt
echo  -e "\033[1;33m Results saved to  $target/Reconnaissance/robots.txt \033[0m"
echo

echo "Subdomains"
cat  $target/Reconnaissance/$target.links | cut -d'/' -f3 | cut -d':' -f1 | uro | sed 's/^\(\|s\):\/\///g' >>  $target/Reconnaissance/subdomains.txt
cat  $target/Reconnaissance/$target.links | grep -oP '(?<=://)([^/]+)\.com'| sort | uniq | >>  $target/Reconnaissance/subdomains.txt
echo  -e "\033[1;33m Results saved to  $target/Reconnaissance/subdomains.txt \033[0m"

echo
echo "Paths for directory brute-force"

cat  $target/Reconnaissance/$target.links | rev | cut -d '/' -f 1 | rev | uro | sed 's/^\(\|s\):\/\///g' | sed '/=\|.js\|.gif\|.html\|.rss\|.cfm\|.htm\|.jpg\|.mp4\|.css\|.jpeg\|.png\|:\|%/d' >  $target/Reconnaissance/wordlist.txt
echo  -e "\033[1;33m Results saved to  $target/Reconnaissance/wordlist.txt \033[0m"

echo 
echo "All js files"
cat  $target/Reconnaissance/$target.links | grep  '\.js' | tee -a   $target/Reconnaissance/jsfiles.txt
echo  -e "\033[1;33m Results saved to  $target/Reconnaissance/jsfiles.txt \033[0m"
rm $target/Reconnaissance/$target.links

elif [[ $choice == "5" ]]; then
    # User wants to go back, exit the loop
    break


#main loop
else
	echo -e "\033[1;31m              Enter a valid choice          \033[0m"
fi
    
done
# Code after the loop executes when the user selects "back"
echo " "