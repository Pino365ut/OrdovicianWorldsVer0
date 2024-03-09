using UnityEngine;
using System.Collections;

public class SkyboxMoving : MonoBehaviour {
    float curRot = 0f;
    float rotSpeed = -0.25f;

    void Update () {
        curRot += rotSpeed * Time.deltaTime;
        curRot %= 360f;
        RenderSettings.skybox.SetFloat("_Rotation", curRot);
    }
}