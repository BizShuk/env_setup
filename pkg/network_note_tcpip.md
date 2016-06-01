### TCP/IP (Transmission Control Protocol / Internet Protocol)



##### OSI(Reference Model for Open System Interconnection)

- Application （應用層）
- Presentation（表現層）
- Session     （會談層）
- Transport   （傳輸層）
- Network     （網路層）
- Data Link   （資料鏈結層）
- Physical    （實體層）

UNIX分層
- 應用層（Application layer：telnet、ftp 等）
- 主機到主機的傳輸層（Transport layer：TCP、UDP）
- 網際網路層（Internet layer：IP 與路由遶送）
- 網路存取層（Network Access Layer：Ethernet、wi-fi、諸如此類）

Router（路由器）會解開封包的 IP header，參考自己的 routing table（路由表）




##### byte order
b34f => big end
f43b => little end


##### stream socket , TCP
with sequential => send 1 2  , arrive 1 2 with sequential
ex: telnet http

封包過大 切成多個 TCP segment

##### datagram socket , UDP
host or router在IP層切割成IP fragment => 接收端重組IP封包
ex:tftp , 多人遊戲,串流音樂 ,影像會議
比較快