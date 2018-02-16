SS
=====

Thumbnail APIを持っていないサービスに存在する資料のScreenshotを撮って回るクローラ。

[puppeteer]を利用する。このクローラはrootのgearとは別の補助プログラムとしてHeroku(変更の可能性あり)上で稼働する。

[puppeteer]: https://github.com/GoogleChrome/puppeteer

## 認証

Blick gearは`worker_key`という固定文字列の認証鍵をgear configに持っている。
これを同じくgear configに保持されている`encryption_key`で暗号化し、
さらにBase64変換した文字列がSSクローラを認証するAPI Keyとなる。

API(`/api/screenshots`等)を外部ネットワークから使用するには今のところこのAPI Keyが必要。
API Keyの生成には対象環境の`worker_key`と`encryption_key`を取得して`Blick.encrypt_base64/1`を通せばよい。
APIのController moduleにヘルパー関数(`Blick.Plug.Auth.generate_api_key/2`)がある。
