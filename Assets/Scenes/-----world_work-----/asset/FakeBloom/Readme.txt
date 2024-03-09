Unity上で使用可能のオブジェクト単位でBloomのような表現を実装できるシェーダーです。
Mobile端末など負荷の都合でBloomが実装できない環境や、VRChatのアバターのような自分でBloomを実装できない環境で使用してください。

～規約
・著作権は製作者に帰属します。
・本製品を使って発生した問題に対しては製作者は一切の責任を負いません。
許可事項
・改変・解析
・二次配布(連絡あったらうれしい)(クレジットは"ほたて@HHOTATEA_VRC")
禁止事項
・迷惑行為等

～連絡先
Twitter : HHOTATEA_VRC
Discord : hhotatea #0333
何かあればいつでも連絡ください。


～Propaty
MainTexture : メインのオブジェクトのテクスチャ
Color : メインオブジェクトの色

CullMode : カリングモード(いじって自分のイメージに合うものを選択、frontだと元オブジェクトが露出します)
BaseMode : 基本的にはScaleModeでOKですが、形が複雑なモデルデータなどに適用するときはNormalModeにしてください。
BloomTexture : ブルームのテクスチャ(基本的にはMainTextureと同じ設定でOK)
BloomColor : ブルームの色(基本的にはColorと同じ設定でOK)
Range : ブルーム効果の範囲
Brightness : ブルーム効果の大きさ
Kee : ブルームのかかり方
SoftKee : ブルームのかかり方
Threshold : ブルームのかかるしきい値

～詳細設定
シェーダーファイル内の67行目
	#define roop 48
の数字(48)を小さくすることで負荷軽減が見込めます。ただし小さくすればするほど、Bloom効果のクオリティが下がります。

2019/05/22 配布開始
