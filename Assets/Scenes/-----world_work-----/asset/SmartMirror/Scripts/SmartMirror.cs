
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
namespace mmmsys {

    public class SmartMirror : UdonSharpBehaviour {
        [SerializeField, HeaderAttribute("Interval to detect")] private int interval = 0;
        [SerializeField, HeaderAttribute("Disable on activate")] private GameObject[] disableObjects;
        [SerializeField, HeaderAttribute("Enable on activate")] private GameObject[] enableObjects;
        [SerializeField, HeaderAttribute("Mirrors")] GameObject frontMirror;
        [SerializeField] private GameObject backMirror, rightMirror, leftMirror, topMirror, bottomMirror;

        [SerializeField, HeaderAttribute("Collidors (none = disable detection)")] GameObject frontCollidor;
        [SerializeField] private GameObject backCollidor, rightCollidor, leftCollidor, topCollidor, bottomCollidor;

        private VRCPlayerApi localPlayer;
        private bool isTracking = false;
        private float rayDistance;
        private RaycastHit hit;
        private int frames = -1;

        void Start() {
            localPlayer = Networking.LocalPlayer;
            rayDistance = Mathf.Sqrt(Mathf.Pow(this.transform.lossyScale.x, 2) + Mathf.Pow(this.transform.lossyScale.y, 2) + Mathf.Pow(this.transform.lossyScale.z, 2)) * 1.1f;
        }
        public void FixedUpdate() {
            if (isTracking) {
                if (++frames >= interval) {
                    if (localPlayer == null) return;
                    if (Physics.Raycast(localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).position, localPlayer.GetTrackingData(VRCPlayerApi.TrackingDataType.Head).rotation * Vector3.forward, out hit, rayDistance)) {
                        if (hit.collider == null) return;
                        if (frontCollidor != null && hit.collider.gameObject == frontCollidor) {
                            if (frontMirror != null) frontMirror.SetActive(true);
                            if (backMirror != null) backMirror.SetActive(false);
                            if (rightMirror != null) rightMirror.SetActive(false);
                            if (leftMirror != null) leftMirror.SetActive(false);
                            if (topMirror != null) topMirror.SetActive(false);
                            if (bottomMirror != null) bottomMirror.SetActive(false);
                        } else if (backCollidor != null && hit.collider.gameObject == backCollidor) {
                            if (frontMirror != null) frontMirror.SetActive(false);
                            if (backMirror != null) backMirror.SetActive(true);
                            if (rightMirror != null) rightMirror.SetActive(false);
                            if (leftMirror != null) leftMirror.SetActive(false);
                            if (topMirror != null) topMirror.SetActive(false);
                            if (bottomMirror != null) bottomMirror.SetActive(false);
                        } else if (rightCollidor != null && hit.collider.gameObject == rightCollidor) {
                            if (frontMirror != null) frontMirror.SetActive(false);
                            if (backMirror != null) backMirror.SetActive(false);
                            if (rightMirror != null) rightMirror.SetActive(true);
                            if (leftMirror != null) leftMirror.SetActive(false);
                            if (topMirror != null) topMirror.SetActive(false);
                            if (bottomMirror != null) bottomMirror.SetActive(false);
                        } else if (leftCollidor != null && hit.collider.gameObject == leftCollidor) {
                            if (frontMirror != null) frontMirror.SetActive(false);
                            if (backMirror != null) backMirror.SetActive(false);
                            if (rightMirror != null) rightMirror.SetActive(false);
                            if (leftMirror != null) leftMirror.SetActive(true);
                            if (topMirror != null) topMirror.SetActive(false);
                            if (bottomMirror != null) bottomMirror.SetActive(false);
                        } else if (topCollidor != null && hit.collider.gameObject == topCollidor) {
                            if (frontMirror != null) frontMirror.SetActive(false);
                            if (backMirror != null) backMirror.SetActive(false);
                            if (rightMirror != null) rightMirror.SetActive(false);
                            if (leftMirror != null) leftMirror.SetActive(false);
                            if (topMirror != null) topMirror.SetActive(true);
                            if (bottomMirror != null) bottomMirror.SetActive(false);
                        } else if (bottomCollidor != null && hit.collider.gameObject == bottomCollidor) {
                            if (frontMirror != null) frontMirror.SetActive(false);
                            if (backMirror != null) backMirror.SetActive(false);
                            if (rightMirror != null) rightMirror.SetActive(false);
                            if (leftMirror != null) leftMirror.SetActive(false);
                            if (topMirror != null) topMirror.SetActive(false);
                            if (bottomMirror != null) bottomMirror.SetActive(true);
                        }
                    }
                    frames = -1;
                }
            }
        }
        public void OnEnable() {

            if (disableObjects.Length > 0) {
                foreach (GameObject obj in disableObjects) {
                    obj.SetActive(false);
                }
            }
            if (enableObjects.Length > 0) {
                foreach (GameObject obj in enableObjects) {
                    obj.SetActive(true);
                }
            }
        }

        public void OnDisable() {

            if (disableObjects.Length > 0) {
                foreach (GameObject obj in disableObjects) {
                    obj.SetActive(true);
                }
            }
            if (enableObjects.Length > 0) {
                foreach (GameObject obj in enableObjects) {
                    obj.SetActive(false);
                }
            }
        }

        public override void OnPlayerTriggerEnter(VRCPlayerApi player) {
            if (player != Networking.LocalPlayer) return;
            isTracking = true;
        }

        public override void OnPlayerTriggerExit(VRCPlayerApi player) {
            if (player != Networking.LocalPlayer) return;
            isTracking = false;
            if (frontMirror != null) frontMirror.SetActive(false);
            if (backMirror != null) backMirror.SetActive(false);
            if (rightMirror != null) rightMirror.SetActive(false);
            if (leftMirror != null) leftMirror.SetActive(false);
            if (topMirror != null) topMirror.SetActive(false);
            if (bottomMirror != null) bottomMirror.SetActive(false);
        }
    }
}