Blick
=========

[![solomon gear](https://img.shields.io/badge/solomon--gear-blick-blue.svg?style=flat)](https://github.com/access-company/solomon)
[![Made with Elm](https://img.shields.io/badge/Elm-0.18-brightgreen.svg?style=flat)](http://elm-lang.org)
[![Made with Bulma](made-with-bulma-s.png)](https://bulma.io)

社内で行われる勉強会やらプレゼン大会やら何やらの資料へのアクセスハブとなることを目指すgear

ベースとなるレポジトリはクラウドのBitBucketプライベートレポジトリに変えたので、社内GitBucketはミラーとします。
もしIssueがあれば下記のTrello boardの招待リンクを踏んでTrelloにカードを作るか、HipChat部屋に投稿してください。

- Repository: https://bitbucket.org/aYuMatsuzawa/blick
    - [Mirror](http://gitbucket.tok.access-company.com:8080/Yu.Matsuzawa/blick)
- Trello board: https://trello.com/b/WrovoYZN/blick
    - [Invite link](https://trello.com/invite/b/WrovoYZN/d40543bb2fcb7279069524ba40bb8f94/blick)
    - [直でTrelloにタスクをする依頼メールアドレス](mailto:yumatsuzawa+qowrqt3mrbbw9aonnryj@boards.trello.com)
- HipChat: https://access-jp.hipchat.com/chat/room/1787150

## Dev

0. [asdf]を入れておく
    - 必要に応じてpluginを入れる。Erlang, Elixir, Nodejsは必須
1. `git clone http://gitbucket.tok.access-company.com:8080/git/Yu.Matsuzawa/blick.git`
2. `asdf install`
3. `npm install`
4. `mix deps.get; mix deps.get`
5. `npm start`

[asdf]: https://github.com/asdf-vm/asdf
