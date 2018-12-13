using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Floating : MonoBehaviour {

    // Twice as much as default gravity
    public float force = 12.74f;

    Rigidbody rb;
    bool isInWater = false;


	// Use this for initialization
	void Start ()
    {
        rb = GetComponent<Rigidbody>();	
	}

    private void OnTriggerEnter(Collider other)
    {
        isInWater = true;
        rb.drag = 5f;
    }

    private void OnTriggerExit(Collider other)
    {
        isInWater = false;
        rb.drag = 0.05f;
    }


    void FixedUpdate ()
    {

        if (isInWater)
        {
            //Apply force:
            rb.AddRelativeForce(transform.up * force, ForceMode.Acceleration);
        }
		
	}
}
