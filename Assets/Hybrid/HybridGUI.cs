using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class HybridGUI : ShaderGUI
{
    public MaterialProperty[] properties;
    public MaterialEditor materialEditor;
    public static Dictionary<MaterialProperty,float> matProps = new Dictionary<MaterialProperty, float>();
    
    public MaterialProperty InitProperty(string name)
    {
        MaterialProperty materialProperty = FindProperty(name,properties,false);
        //matProps.Add(materialProperty,0);
        return materialProperty;
    }

    public MaterialProperty InitProperty(string name, float group)
    {
        MaterialProperty materialProperty = FindProperty(name,properties,false);
        //matProps.Add(materialProperty,group);
        return materialProperty;
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.properties = properties;
        base.OnGUI(materialEditor, properties);
    }

    public static MaterialProperty FindProp(string propertyName, MaterialProperty[] properties, bool propertyIsMandatory = false)
    {
        return FindProperty(propertyName, properties, propertyIsMandatory);
    }
}
