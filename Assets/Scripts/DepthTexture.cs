using UnityEngine;

[ExecuteInEditMode]
public class DepthTexture : MonoBehaviour
{

    private Camera camera;

    // Getting the depth value to use later to ouput a colour.
    // Using colour as a gradient to simulate depth.
    void Start()
    {
        camera = GetComponent<Camera>();
        camera.depthTextureMode = DepthTextureMode.Depth;
    }

}