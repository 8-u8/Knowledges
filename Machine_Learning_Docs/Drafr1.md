# 目的
- 本にする価値もないので、勉強メモとしての記録をgithubにでも公開する。
- 勾配ブースティングの数理的な理解
  - 【個人的な課題】GBDTは「決定木っぽい」「速くて精度が良い」以外の情報を知らない。
    - なんで過学習しづらいとかそういうのがあるのかよく知らない
- XGBoost / LightGBMの理解、及び特性について学ぶ

# どこから？
- 決定木から。
  - Random Forest の前段階から極めていく必要が出てきた。
  - まず決定木の数理的定式化とアルゴリズムの理解をする。
- ランダムフォレスト
  - コイツも謎。何がおきているんだ
  - 謎なので調べつつお気持ちを理解しよう
- 勾配ブースティング
  - まず勾配って何かを理解しないといけない

# 読みがちな文献(随時更新)
- [カステラ本](https://www.kyoritsu-pub.co.jp/bookdetail/9784320123625)
  - 数理的な基本文献はここだろうと思う
  - 主に決定木系の基礎理論から掴みに行く
- [Hoxomaxwell氏のわかりやすい資料](https://speakerdeck.com/hoxomaxwell/dive-into-xgboost)
  - 理解・解釈向け
- [XGBoostとLightGBMに関する記述](https://www.codexa.net/lightgbm-beginner/amp/?__twitter_impression=true)
  - 理解の補強
- [XGBoost原著？](https://www.kdd.org/kdd2016/papers/files/rfp0697-chenAemb.pdf)
- [LightGBM原著？](https://papers.nips.cc/paper/6907-lightgbm-a-highly-efficient-gradient-boosting-decision-tree.pdf)