# ufw
在啟用後，ufw 會把記錄寫到 /var/log/ufw.log 日誌檔。
sudo ufw logging on
Read more: http://www.arthurtoday.com/2013/12/ubuntu-ufw-add-firewall-rules.html#ixzz48gaxFoJ7


/etc/default/ufw


ufw <enable|disable|reset>
ufw status [verbose]


`ufw default <allow|deny|reject> <incoming|outgoing|routed>`

`ufw [delete] <allow|deny> <app>`
`ufw [delete] <allow|deny> [<port_start>:]<port>/<tcp|udp>`
`ufw [delete] <allow|deny> from <ip>[:<port>]`
