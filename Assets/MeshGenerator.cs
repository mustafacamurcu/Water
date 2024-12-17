using System.Collections;
using System.Collections.Generic;
using UnityEngine;
public class MeshGenerator : MonoBehaviour {
    Mesh mesh;
    Vector3[] vertices;
    int[] triangles;
    public int xSize = 100;
    public int zSize = 100;
    public float edgeSize = 1f;
    // Start is called before the first frame update
    void Start()
    {
        mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;
        CreateShape();
        UpdateMesh();
    }

    void CreateShape() {
        vertices = new Vector3[(xSize + 1) * (zSize + 1)];
        for (int z = 0, i = 0 ; z < zSize + 1 ; z++) {
            for (int x = 0; x < xSize + 1; x++, i++) {
                vertices[i] = new Vector3((x-xSize/2)*edgeSize, 0, (z-zSize/2)*edgeSize);
            }
        }
        triangles = new int[(xSize)*(zSize) * 6];
        int tris = 0;
        for (int i = 0 ; i < xSize ; i++) {
            for (int j = 0 ; j < zSize ; j++) {
                triangles[tris++] = i * (zSize+1) + j;
                triangles[tris++] = (i + 1) * (zSize+1) + j;
                triangles[tris++] = i * (zSize+1) + j + 1;
                triangles[tris++] = i * (zSize+1) + j + 1;
                triangles[tris++] = (i + 1) * (zSize+1) + j;
                triangles[tris++] = (i + 1) * (zSize+1) + j + 1;
            }
        }
    }

    void UpdateMesh() {
        mesh.Clear();
        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
    }

    // void OnDrawGizmos() {
    //     if (vertices == null){
    //         return;
    //     }
    //     for (int i = 0; i < vertices.Length; i++) {
    //         Gizmos.DrawSphere(vertices[i], .01f);
    //     }
    // }
}