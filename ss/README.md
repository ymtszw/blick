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

## デプロイ

Herokuでは[Heroku Scheduler]を使って、2通りのジョブを動かす。

[Heroku Scheduler]: https://devcenter.heroku.com/articles/scheduler

- まだサムネイルが付与されていないMaterialに付与するジョブ。短周期で動かす。(10分毎)
- すでに付与されているサムネイルを更新するジョブ。`REFRESH=true`オプションを付けて長周期で動かす。（1日毎）

[heroku-cli]をインストールしておく必要があるが、Node.jsを`asdf`で管理している場合は多少面倒で、
`brew`を使ってglobalにインストールしようとすると`node`をdependencyとして持ってこようとするため環境が壊れる。
仕方ないので`asdf`管理下の`node`が動いているディレクトリで`npm install -g heroku-cli`して用意する。
ちなみに、最新の[heroku-cli]はnode 8.3+を要求するのでsolomonの環境とは合わない。

[heroku-cli]: https://github.com/heroku/cli

```
heroku apps:add blick-ss-init
heroku buildpacks:set --app=blick-ss-init https://github.com/timanovsky/subdir-heroku-buildpack
heroku buildpacks:add --app=blick-ss-init https://github.com/CoffeeAndCode/puppeteer-heroku-buildpack
heroku addons:add --app=blick-ss-init scheduler:standard
heroku config:set --app=blick-ss-init PROMISES=1 WORKER_ENV=cloud API_KEY=<encrypted_worker_key> PROJECT_PATH=ss/
```

サブディレクトリをデプロイするために、`git-subtree`を使っていたが、
GitHub移行に際して[timanovsky/subdir-heroku-buildpack](https://github.com/timanovsky/subdir-heroku-buildpack)にしてみた。

HerokuのUIからdeploy設定し、GitHub連携を選ぶ。Repositoryをセットして"Enable auto deploy"を設定しておけば、master pushでdeployされる。

`REFRESH=true`付きのジョブについてはapp名を`blick-ss-refresh`と読み替える。
また、`config:set`の際は`REFRESH=true`をつける。

ジョブ設定は[Heroku Scheduler]のUIからしかできないので、そこから設定する。

`Promise`の並列度を`MAX_PROMISES`で制御できるようにしてあるが、heroku上ではfree dynoのメモリ制限だと
`MAX_PROMISES=1`でしか安定稼働しない。2並列でもぎりぎり動くが、時々`Page crashed!`エラーが発生する模様。
