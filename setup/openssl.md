# OpenSSL

### conclusion

free CA only one domain at a time => multiple pem for each domain is too hard to manag. Wildcard CA is too expensive

stop for this moment.

### unknown

- extension?
- serial file?
- https://www.sslforfree.com/

### definition

http://serverfault.com/a/9717

- x.509 , ref : RFC5280
  - PEM , Privacy Enhanced Mail
  - DER , Distinguished Encoding Rules
- key , private key or public key
- crt , Certificate in Unix
- cer , Certificate in Window
- csr , Certificate Signing Request
- PFX/P12 - predecessor of PKCS#12,对\*nix服务器来说,一般CRT和KEY是分开存放在不同文件中的,但Windows的IIS则将它们存在一个PFX文件中,(因此这个文件包含了证书及私钥)这样会不会不安全？应该不会,PFX通常会有一个"提取密码",你想把里面的东西读取出来的话,它就要求你提供提取密码,PFX使用的时DER编码,如何把PFX转换为PEM编码？
- JKS - 即Java Key Storage,这是Java的专利,跟OpenSSL关系不大,利用Java的一个叫"keytool"的工具,可以将PFX转为JKS,当然了,keytool也能直接生成JKS,不过在此就不多表了.

### rsa , dsa , ecc

- http://blog.sina.com.cn/s/blog_6f31085901015agu.html
- http://sls.weco.net/blog/jeffean/30-oct-2009/13652

### how to make ca.crt pem key

http://www.ichiayi.com/wiki/tech/openssl_caserver

### pem trust chain

```
-----BEGIN CERTIFICATE-----
(Your Primary SSL certificate: your_domain_name.crt)
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
(Your Intermediate certificate: DigiCertCA.crt)
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
(Your Root certificate: TrustedRoot.crt)
-----END CERTIFICATE-----
```

### cli

[source](http://ijecorp.blogspot.tw/2014/03/openssl.html)

使用 openssl 產生私有金鑰 (private key) 的指令如下：
`openssl [genrsa|gendsa] [-aes128|-aes256|-des|-des3] -out [RootCA|ServerCA].key [1024|2048|4096]`

`openssl req -new -key [RootCA|ServerCA].key -out [RootCA|ServerCA].req`
產生 CSR 後, 可以透過 openssl 來檢測 CSR的內容是否正確，指令如下：
`openssl req -text -in [RootCA|ServerCA].req -noout`

在確認 CSR 內容正確後，就可以將 CSR 傳送到公認且有公信力的 CA 單位，並請求該單位為此 CSR 產生憑證 (Certificate)。一旦取得 CA 為此 CSR 產生的憑證後, 就可以將它安裝在需要支援 SSL 的伺服器上。

但是，如果只是開發階段需要測試，或只是自己的想要使用並不是要公開對外支援 SSL時候，可以自行產生一個所謂 Self-signed 的憑證。產生 Self-signed 憑證的方式如下：

`openssl x509 -req -days 365 -in CSR.csr -signkey private.key -out self-signed.crt`

`openssl x509 -req -days 1000 -sha1 -extensions v3_req -CA RootCA.crt -CAkey RootCA.key -CAserial RootCA.srl -CAcreateserial -in ServerCA.req -out ServerCA.crt`

無論你是透過 CA 取得憑證或是自行產生 self-signed 的憑證, 都可以透過 openssl 指令來檢測憑證的內容，透過以下的指令：
`openssl x509 -text -in self-signed.crt -noout`

### bugs

koverflow.com/questions/94445/using-openssl-what-does-unable-to-write-random-state-mean>
