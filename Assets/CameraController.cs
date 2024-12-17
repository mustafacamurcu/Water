using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public float speed = 1;
    public float rotationSpeed = 600;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        float forward = Input.GetAxis("Vertical") * speed * Time.deltaTime;
        float horizontal = Input.GetAxis("Horizontal") * speed* Time.deltaTime;
        float vertical = 0;
        if (Input.GetKey(KeyCode.Tab)) {
            vertical = speed * Time.deltaTime;
        } else if(Input.GetKey(KeyCode.LeftShift)) {
            vertical = -speed * Time.deltaTime;
        }

        float rotation = 0;
        if (Input.GetKey(KeyCode.E)) {
            rotation = rotationSpeed * Time.deltaTime;
        } else if(Input.GetKey(KeyCode.Q)) {
            rotation = -rotationSpeed * Time.deltaTime;
        }
        
        transform.Rotate(0.0f, rotation, 0.0f);
        transform.Translate(transform.forward * forward);
        transform.Translate(transform.up * vertical);
        transform.Translate(transform.right * horizontal);

    }
}
