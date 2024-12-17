using System;
using System.Collections;
using System.Collections.Generic;
using System.Net;
using UnityEngine;
using static System.Runtime.InteropServices.Marshal;

public class WaveGenerator : MonoBehaviour
{
    private Material waterMaterial;
    public float dirMin;
    public float dirMax;
    public float frequency;
    public float freqFactor = 1.1f;
    public float height;
    public float heightFactor = 0.9f;
    public float speedMin;
    public float speedMax;
    public int waveCount;
    public Color waterColor;
    
    private Wave[] waves;
    private ComputeBuffer waveBuffer;

    public struct Wave {
        public Vector3 direction;
        public float freq;
        public float amp;
        public float speed;
        public float timeOffset;

        public Wave(float freq, float amp, float speed, float directionAngle) {
            float x = Mathf.Cos(Mathf.Deg2Rad * directionAngle);
            float z = Mathf.Sin(Mathf.Deg2Rad * directionAngle);
            this.direction = new Vector3(x,0.0f,z);
            this.freq = freq;
            this.amp = amp;
            this.speed = speed;
            this.timeOffset = UnityEngine.Random.Range(0,5);
        }
    }

    void SetMaterial() {
        waterMaterial = GetComponent<MeshRenderer>().material;
        waterMaterial.SetInt("_WaveCount", waveCount);
        waterMaterial.SetInt("_ShowNormals", 0);
        waterMaterial.SetVector("_SunDirection", new Vector3(0,-1,-1));
        waterMaterial.SetVector("_WaterColor", waterColor);
    }

    void CreateWaveBuffer() {
        if (waveBuffer != null) return;

        waveBuffer = new ComputeBuffer(waveCount, SizeOf(typeof(Wave)));

        waterMaterial.SetBuffer("_Waves", waveBuffer);
    }
    
    void GenerateWaves() {
        waves = new Wave[waveCount];
        float freq = frequency;
        float amp = height;
        for (int i = 0 ; i < waveCount; i++) {
            float speed = UnityEngine.Random.Range(speedMin, speedMax);
            float dirAngle = UnityEngine.Random.Range(dirMin, dirMax);
            waves[i] = new Wave(freq, amp, speed, dirAngle);
            freq *= freqFactor;
            amp *= heightFactor;
        }
        waveBuffer.SetData(waves);
        waterMaterial.SetBuffer("_Waves", waveBuffer);
    }

    // Start is called before the first frame update
    void Start()
    {
        SetMaterial();
        CreateWaveBuffer();
        GenerateWaves();
    }

    void OnDisable() {
        if (waterMaterial != null) {
            Destroy(waterMaterial);
            waterMaterial = null;
        }

        if (waveBuffer != null) {
            waveBuffer.Release();
            waveBuffer = null;
        }
    }
}
