using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using static UnityEditor.ShaderGUI;
namespace HybridDrawer
{
    public abstract class LevelDrawer : MaterialPropertyDrawer
    {
        protected float level = 0;

        protected MaterialProperty extraProp1;
        protected string extraPropString1;

        protected MaterialProperty extraProp2;
        protected string extraPropString2;

        protected MaterialProperty extraProp3;
        protected string extraPropString3;

        bool isActive;
    }

    public class LableDrawer : LevelDrawer
    {
        bool lableState = false;
        string lableGroup;
        public LableDrawer(float level, string group)
        {
            this.lableGroup = group;
            this.level = level;
        }

        static bool Foldout(bool display, string title)
        {
            var style = new GUIStyle("ShurikenModuleTitle");// 背景风格
            style.font = EditorStyles.boldLabel.font;
            //style.fontSize = EditorStyles.boldLabel.fontSize + 3;
            //style.border = new RectOffset(15, 7, 40, 4);//背景阴影偏移
            //style.fixedHeight = 30;//标签高度修正
            //style.contentOffset = new Vector2(50f, 0f);//标签文字偏移
            var rect = GUILayoutUtility.GetRect(16f, 22f, style);
            GUI.Box(rect,title,style);
            GUIContent lab = new GUIContent();
            lab.text = "text";

            var e = Event.current;

            var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);//三角
            if (e.type == EventType.Repaint)
            {
                EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
            }

            if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
            {
                display = !display;
                e.Use();
            }
            //HybridGUI.groupDic.Add(title,display);
            return display;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            lableState = Foldout(lableState,label.text);
            if(lableState)
            {
                GUI.Box(GUILayoutUtility.GetRect(0,100),"test true");
            }
        }
    }

    public class SubDrawer : MaterialPropertyDrawer
    {
        MaterialProperty group;
        string groupString;
        bool show;
        public SubDrawer(string group)
        {
            this.groupString = group;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            EditorGUI.indentLevel++;
            switch (prop.type)
            {
                case MaterialProperty.PropType.Texture:
                    editor.TexturePropertySingleLine(label,prop);
                break;
            }
            EditorGUI.indentLevel--;

        }
    }

    public class TextureDrawer : MaterialPropertyDrawer
    {
        MaterialProperty pramter;
        string pramterString;

        public TextureDrawer()
        {

        }

        public TextureDrawer(string pramter)
        {
            pramterString = pramter;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            HybridGUI gui = editor.customShaderGUI as HybridGUI;
            pramter = gui.InitProperty(pramterString,0);
            if(pramterString != null)
            {
                editor.TexturePropertySingleLine(label,prop,pramter);
            }
            else
            {
                editor.TexturePropertySingleLine(label,prop);
            }
        }
    }

    public class ShowIfDrawer : MaterialPropertyDrawer
    {
        MaterialProperty toggle;
        string toggleString;
        float threshold;

        public ShowIfDrawer(string toggle, float thres)
        {
            this.toggleString = toggle;
            this.threshold = thres;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            HybridGUI gui = editor.customShaderGUI as HybridGUI;
            toggle = gui.InitProperty(toggleString,0);
            if(toggle.floatValue == threshold)
            {
                switch (prop.type)
                {
                    case MaterialProperty.PropType.Texture:
                        editor.TexturePropertySingleLine(label,prop);
                    break;
                }
            }
        }
    }

}
