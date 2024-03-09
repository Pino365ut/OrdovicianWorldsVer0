
using System;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
namespace mmmsys {
    public class DesktopSmoother : UdonSharpBehaviour {
        [SerializeField, HeaderAttribute("*必須* VRCWorld (deny none)")] private UdonBehaviour VRCWorldObject;
        [SerializeField, HeaderAttribute("加速時間 [sec]")] private float accelTime;
        [SerializeField, HeaderAttribute("速度変化 [0 to 1]")] private AnimationCurve accelCurve;
        private VRCPlayerApi localPlayer;
        private bool isVR;
        private bool isAccelerating = false;
        private float startTime;
        void Start() {
            localPlayer = Networking.LocalPlayer;
            if (localPlayer == null) return;
            isVR = localPlayer.IsUserInVR();
        }

        void InputMoveHorizontal(float value, VRC.Udon.Common.UdonInputEventArgs args) {
            if (isVR || isAccelerating) return;
            if (value != 0 && !Input.GetKey(KeyCode.LeftShift) && !Input.GetKey(KeyCode.RightShift)) {
                isAccelerating = true;
                startTime = Time.time;
                setVariableSpeed(0f);
            } else {
                isAccelerating = false;
                setDefaultSpeed();
            }
        }
        void InputMoveVertical(float value, VRC.Udon.Common.UdonInputEventArgs args) {
            if (isVR || isAccelerating) return;
            if (value != 0 && !Input.GetKey(KeyCode.LeftShift) && !Input.GetKey(KeyCode.RightShift)) {
                isAccelerating = true;
                startTime = Time.time;
                setVariableSpeed(0f);
            } else {
                isAccelerating = false;
                setDefaultSpeed();
            }
        }

        void setDefaultSpeed() {
            if (localPlayer == null) return;

            localPlayer.SetWalkSpeed((float)VRCWorldObject.GetProgramVariable("walkSpeed"));
            localPlayer.SetRunSpeed((float)VRCWorldObject.GetProgramVariable("runSpeed"));
            localPlayer.SetStrafeSpeed((float)VRCWorldObject.GetProgramVariable("strafeSpeed"));
        }
        void setVariableSpeed(float weight) {
            if (localPlayer == null) return;

            localPlayer.SetWalkSpeed((float)VRCWorldObject.GetProgramVariable("walkSpeed") * accelCurve.Evaluate(weight));
            localPlayer.SetRunSpeed((float)VRCWorldObject.GetProgramVariable("runSpeed") * accelCurve.Evaluate(weight));
            localPlayer.SetStrafeSpeed((float)VRCWorldObject.GetProgramVariable("strafeSpeed") * accelCurve.Evaluate(weight));
        }

        private void Update() {
            if (!isVR && isAccelerating) {

                float t = Time.time - startTime;

                if (t >= accelTime || Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift) || !(Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.D))) {
                    setDefaultSpeed();
                    isAccelerating = false;
                    return;
                }

                setVariableSpeed(t / accelTime);
            }
        }
    }
}