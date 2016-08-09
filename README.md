# sekimiya-fusion

ホント無理

## Demo
https://twitter.com/sekimiya_fusion

## Usage
0. Dockerをインストールする

1. config.yml.sampleをconfig.ymlにリネームして中身を編集する

2. ```docker build -t sekimiya_fusion .```

3. ```docker run --rm -it sekimiya-fusion```  
  (バックグラウンドで動かす時は ```docker run --rm -d sekimiya-fusion```)

Dockerで動かさない場合は手動でAnimeFace(Ruby版)をインストールする必要があります。
http://ultraist.hatenablog.com/entry/20110426/1303836863

## License
NYSL
