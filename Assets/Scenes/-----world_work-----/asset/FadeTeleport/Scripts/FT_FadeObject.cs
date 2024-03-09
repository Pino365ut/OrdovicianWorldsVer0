
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
namespace mmmsys {

    public class FT_FadeObject : UdonSharpBehaviour {
        [SerializeField, HeaderAttribute("ポータル滞在判定時間(s)")] public float stayTimeToTeleport;
        [SerializeField, HeaderAttribute("フェードイン時間(s)")] public float fadeinTime;
        [SerializeField, HeaderAttribute("暗転時間(s)この間にテレポート")] public float darkTime;
        [SerializeField, HeaderAttribute("フェードアウト時間(s)")] public float fadeoutTime;
        [SerializeField, HeaderAttribute("ボタン無効化時間(s)")] public float intervalTime;
        [SerializeField, HeaderAttribute("テレポート中の移動を許可")] public bool canMove;
        [SerializeField, HeaderAttribute("テレポート効果音")] public AudioClip teleportSE;
        [SerializeField, HeaderAttribute("テレポートする瞬間に効果音を再生")] public bool playSEOnTeleport;
        [SerializeField, HeaderAttribute("重なり防止距離(m) 0で位置ずらし機能無効")] public float positionMargin;
    }
}