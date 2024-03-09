
using System;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
namespace mmmsys {

    public class FT_TeleportSwitch : UdonSharpBehaviour {

        [SerializeField, HeaderAttribute("FT_FadeObject (deny none)")] private GameObject FadeObject;
        [SerializeField, HeaderAttribute("テレポート先座標 Z+が前 (deny none)")] private GameObject teleportPoint;
        [SerializeField, HeaderAttribute("テレポート中無効化するオブジェクト (deny none)")] private GameObject[] disableObjects;

        private bool isTeleporting = false;
        private bool canMove;
        private float startTime;
        private float fadein_end;
        private float teleportTime;
        private float dark_end;
        private float fadeout_end;
        private float interval_end;
        private float positionMargin;

        private Material fadeMaterial;
        private AudioClip teleportSE;
        private AudioSource audioSource;
        private bool playSEOnTeleport;
        public void Start() {
            startTime = Time.time;
        }

        public override void Interact() {
            if (!isTeleporting) {
                UdonBehaviour udon = (UdonBehaviour)FadeObject.GetComponent(typeof(UdonBehaviour));
                fadein_end = (float)udon.GetProgramVariable("fadeinTime");
                dark_end = (float)udon.GetProgramVariable("darkTime") + fadein_end;
                teleportTime = (float)udon.GetProgramVariable("darkTime") / 2 + fadein_end;
                if (teleportTime <= 0) teleportTime = 0.1f;
                fadeout_end = (float)udon.GetProgramVariable("fadeoutTime") + dark_end;
                interval_end = (float)udon.GetProgramVariable("intervalTime") + fadeout_end;
                canMove = (bool)udon.GetProgramVariable("canMove");
                teleportSE = (AudioClip)udon.GetProgramVariable("teleportSE");
                playSEOnTeleport = (bool)udon.GetProgramVariable("playSEOnTeleport");
                audioSource = FadeObject.GetComponent<AudioSource>();
                positionMargin = (float)udon.GetProgramVariable("positionMargin");

                FadeObject.SetActive(true);
                FadeObject.transform.position = this.transform.position;
                fadeMaterial = FadeObject.GetComponent<Renderer>().sharedMaterial;
                fadeMaterial.SetFloat("_fade", 0f);
                if (disableObjects.Length > 0) {
                    foreach (GameObject obj in disableObjects) {
                        if (obj != null) obj.SetActive(false);
                    }
                }
                if (!canMove) Networking.LocalPlayer.Immobilize(true);
                if (teleportSE != null && !playSEOnTeleport) audioSource.PlayOneShot(teleportSE);
                isTeleporting = true;
                startTime = Time.time;
            }
        }

        private void Update() {

            if (isTeleporting) {
                float t = Time.time - startTime;

                if (teleportTime > 0 && t > teleportTime) {
                    if (teleportSE != null && playSEOnTeleport) audioSource.PlayOneShot(teleportSE);
                    FadeObject.transform.position = teleportPoint.transform.position;
                    teleportPlayer(); 
                    teleportTime = -1f;
                }

                if (t <= fadein_end) {
                    fadeMaterial.SetFloat("_fade", t / fadein_end);
                    return;
                }
                if (t <= dark_end) {
                    fadeMaterial.SetFloat("_fade", 1f);
                    return;
                }
                if (t <= fadeout_end) {
                    fadeMaterial.SetFloat("_fade", 1 - (t - dark_end) / (fadeout_end - dark_end));
                    return;
                }
                if (fadeout_end > 0) {
                    fadeMaterial.SetFloat("_fade", 0f);
                    FadeObject.SetActive(false);
                    fadeout_end = -1;
                    if (!canMove) Networking.LocalPlayer.Immobilize(false);
                    return;
                }
                if (t > interval_end) {
                    if (disableObjects.Length > 0) {
                        foreach (GameObject obj in disableObjects) {
                            if (obj != null) obj.SetActive(true);
                        }
                    }
                    isTeleporting = false;
                    return;
                }
            }
        }
        private void teleportPlayer() {
            BoxCollider col = teleportPoint.GetComponent<BoxCollider>();
            Vector3 marginPos = new Vector3(0, 0, 0);
            if (col != null && positionMargin > 0f && teleportPoint.transform.lossyScale.sqrMagnitude > 0f) {
                Vector3[] hitPlayersPos = GetPlayersInCollider(col);
                if (hitPlayersPos.Length > 0) {
                    for (int i = 0; i < 9; i++) {
                        marginPos.x = UnityEngine.Random.Range(-col.transform.lossyScale.x / 2, col.transform.lossyScale.x / 2);
                        marginPos.z = UnityEngine.Random.Range(-col.transform.lossyScale.z / 2, col.transform.lossyScale.z / 2);
                        bool isCollided = false;
                        foreach (Vector3 playerPos in hitPlayersPos) {
                            if (playerPos != null) {
                                if (Vector3.Distance(playerPos, teleportPoint.transform.position + marginPos) < positionMargin) {
                                    isCollided = true;
                                    break;
                                }
                            }
                        }
                        if (isCollided) {
                            if (i == 8) {
                                marginPos = new Vector3(0, 0, 0);
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                }
            }
            Networking.LocalPlayer.TeleportTo(teleportPoint.transform.position + marginPos, teleportPoint.transform.rotation);
        }

        private Vector3[] GetPlayersInCollider(Collider col) {
            if (col == null) return new Vector3[0];
            Vector3[] result = new Vector3[VRCPlayerApi.GetPlayerCount()];
            VRCPlayerApi[] players = new VRCPlayerApi[VRCPlayerApi.GetPlayerCount()];
            VRCPlayerApi.GetPlayers(players);
            int j = 0;
            for (int i = 0; i < players.Length; i++) {
                if (players[i] == null) continue;
                if (players[i] == Networking.LocalPlayer) continue;
                Vector3 closestPoint = col.ClosestPoint(players[i].GetPosition());
                if ((closestPoint.x == players[i].GetPosition().x && closestPoint.z == players[i].GetPosition().z) && Mathf.Abs(closestPoint.y - players[i].GetPosition().y) < 0.5) result[j++] = players[i].GetPosition();
            }
            if (j == 0) return new Vector3[0];
            return result;
        }
    }
}