// Copyright (c) 2012-2022 Wojciech Figat. All rights reserved.

using System.Linq;
using FlaxEditor.CustomEditors.Elements;
using FlaxEngine;
using FlaxEngine.GUI;

namespace FlaxEditor.CustomEditors.Editors
{
    /// <summary>
    /// Default implementation of the inspector used to edit Vector4 value type properties.
    /// </summary>
    [CustomEditor(typeof(Vector4)), DefaultEditor]
    public class Vector4Editor :
#if USE_LARGE_WORLDS
    Double4Editor
#else
    Float4Editor
#endif
    {
    }

    /// <summary>
    /// Default implementation of the inspector used to edit Vector4 value type properties.
    /// </summary>
    [CustomEditor(typeof(Float4)), DefaultEditor]
    public class Float4Editor : CustomEditor
    {
        /// <summary>
        /// The X component editor.
        /// </summary>
        protected FloatValueElement XElement;

        /// <summary>
        /// The Y component editor.
        /// </summary>
        protected FloatValueElement YElement;

        /// <summary>
        /// The Z component editor.
        /// </summary>
        protected FloatValueElement ZElement;

        /// <summary>
        /// The W component editor.
        /// </summary>
        protected FloatValueElement WElement;

        /// <inheritdoc />
        public override DisplayStyle Style => DisplayStyle.Inline;

        /// <inheritdoc />
        public override void Initialize(LayoutElementsContainer layout)
        {
            var grid = layout.CustomContainer<UniformGridPanel>();
            var gridControl = grid.CustomControl;
            gridControl.ClipChildren = false;
            gridControl.Height = TextBox.DefaultHeight + 5;
            gridControl.SlotsHorizontally = 4;
            gridControl.SlotsVertically = 1;

            LimitAttribute limit = null;
            var attributes = Values.GetAttributes();
            if (attributes != null)
            {
                limit = (LimitAttribute)attributes.FirstOrDefault(x => x is LimitAttribute);
            }

            var xPanel = grid.HorizontalPanel();
            xPanel.Panel.Margin = new Margin(0);
            xPanel.Panel.AutoSize = false;

            var xLabel = xPanel.Label("X", TextAlignment.Center);
            xLabel.Label.BackgroundColor = Color.Red;
            xLabel.Label.TextColor = Color.White;
            xLabel.Label.Width = 20f;
            
            XElement = xPanel.FloatValue();
            XElement.ValueBox.AnchorPreset = AnchorPresets.StretchAll;
            XElement.ValueBox.Location += new Float2(22, 0);
            XElement.ValueBox.Width -= 22f;
            XElement.SetLimits(limit);
            XElement.ValueBox.ValueChanged += OnValueChanged;
            XElement.ValueBox.SlidingEnd += ClearToken;

            var yPanel = grid.HorizontalPanel();
            yPanel.Panel.Margin = new Margin(0);
            yPanel.Panel.AutoSize = false;

            var yLabel = yPanel.Label("Y", TextAlignment.Center);
            yLabel.Label.BackgroundColor = Color.Green;
            yLabel.Label.TextColor = Color.White;
            yLabel.Label.Width = 20f;
            
            YElement = yPanel.FloatValue();
            YElement.ValueBox.AnchorPreset = AnchorPresets.StretchAll;
            YElement.ValueBox.Location += new Float2(22, 0);
            YElement.ValueBox.Width -= 22f;
            YElement.SetLimits(limit);
            YElement.ValueBox.ValueChanged += OnValueChanged;
            YElement.ValueBox.SlidingEnd += ClearToken;
            
            var zPanel = grid.HorizontalPanel();
            zPanel.Panel.Margin = new Margin(0);
            zPanel.Panel.AutoSize = false;
            
            var zLabel = zPanel.Label("Z", TextAlignment.Center);
            zLabel.Label.BackgroundColor = Color.Blue;
            zLabel.Label.TextColor = Color.White;
            zLabel.Label.Width = 20f;
            
            ZElement = zPanel.FloatValue();
            ZElement.ValueBox.AnchorPreset = AnchorPresets.StretchAll;
            ZElement.ValueBox.Location += new Float2(22, 0);
            ZElement.ValueBox.Width -= 22f;
            ZElement.SetLimits(limit);
            ZElement.ValueBox.ValueChanged += OnValueChanged;
            ZElement.ValueBox.SlidingEnd += ClearToken;

            var wPanel = grid.HorizontalPanel();
            wPanel.Panel.Margin = new Margin(0);
            wPanel.Panel.AutoSize = false;
            
            var wLabel = wPanel.Label("W", TextAlignment.Center);
            wLabel.Label.BackgroundColor = Color.OrangeRed;
            wLabel.Label.TextColor = Color.White;
            wLabel.Label.Width = 20f;
            
            WElement = wPanel.FloatValue();
            WElement.ValueBox.AnchorPreset = AnchorPresets.StretchAll;
            WElement.ValueBox.Location += new Float2(22, 0);
            WElement.ValueBox.Width -= 22f;
            WElement.SetLimits(limit);
            WElement.ValueBox.ValueChanged += OnValueChanged;
            WElement.ValueBox.SlidingEnd += ClearToken;
        }

        private void OnValueChanged()
        {
            if (IsSetBlocked)
                return;

            var isSliding = XElement.IsSliding || YElement.IsSliding || ZElement.IsSliding || WElement.IsSliding;
            var token = isSliding ? this : null;
            var value = new Float4(XElement.ValueBox.Value, YElement.ValueBox.Value, ZElement.ValueBox.Value, WElement.ValueBox.Value);
            object v = Values[0];
            if (v is Vector4)
                v = (Vector4)value;
            else if (v is Float4)
                v = (Float4)value;
            else if (v is Double4)
                v = (Double4)value;
            SetValue(v, token);
        }

        /// <inheritdoc />
        public override void Refresh()
        {
            base.Refresh();

            if (HasDifferentValues)
            {
                // TODO: support different values for ValueBox<T>
            }
            else
            {
                var value = Float4.Zero;
                if (Values[0] is Vector4 asVector4)
                    value = asVector4;
                else if (Values[0] is Float4 asFloat4)
                    value = asFloat4;
                else if (Values[0] is Double4 asDouble4)
                    value = asDouble4;
                XElement.ValueBox.Value = value.X;
                YElement.ValueBox.Value = value.Y;
                ZElement.ValueBox.Value = value.Z;
                WElement.ValueBox.Value = value.W;
            }
        }
    }

    /// <summary>
    /// Default implementation of the inspector used to edit Double4 value type properties.
    /// </summary>
    [CustomEditor(typeof(Double4)), DefaultEditor]
    public class Double4Editor : CustomEditor
    {
        /// <summary>
        /// The X component editor.
        /// </summary>
        protected DoubleValueElement XElement;

        /// <summary>
        /// The Y component editor.
        /// </summary>
        protected DoubleValueElement YElement;

        /// <summary>
        /// The Z component editor.
        /// </summary>
        protected DoubleValueElement ZElement;

        /// <summary>
        /// The W component editor.
        /// </summary>
        protected DoubleValueElement WElement;

        /// <inheritdoc />
        public override DisplayStyle Style => DisplayStyle.Inline;

        /// <inheritdoc />
        public override void Initialize(LayoutElementsContainer layout)
        {
            var grid = layout.CustomContainer<UniformGridPanel>();
            var gridControl = grid.CustomControl;
            gridControl.ClipChildren = false;
            gridControl.Height = TextBox.DefaultHeight;
            gridControl.SlotsHorizontally = 4;
            gridControl.SlotsVertically = 1;

            LimitAttribute limit = null;
            var attributes = Values.GetAttributes();
            if (attributes != null)
            {
                limit = (LimitAttribute)attributes.FirstOrDefault(x => x is LimitAttribute);
            }

            XElement = grid.DoubleValue();
            XElement.SetLimits(limit);
            XElement.ValueBox.ValueChanged += OnValueChanged;
            XElement.ValueBox.SlidingEnd += ClearToken;

            YElement = grid.DoubleValue();
            YElement.SetLimits(limit);
            YElement.ValueBox.ValueChanged += OnValueChanged;
            YElement.ValueBox.SlidingEnd += ClearToken;

            ZElement = grid.DoubleValue();
            ZElement.SetLimits(limit);
            ZElement.ValueBox.ValueChanged += OnValueChanged;
            ZElement.ValueBox.SlidingEnd += ClearToken;

            WElement = grid.DoubleValue();
            WElement.SetLimits(limit);
            WElement.ValueBox.ValueChanged += OnValueChanged;
            WElement.ValueBox.SlidingEnd += ClearToken;
        }

        private void OnValueChanged()
        {
            if (IsSetBlocked)
                return;

            var isSliding = XElement.IsSliding || YElement.IsSliding || ZElement.IsSliding || WElement.IsSliding;
            var token = isSliding ? this : null;
            var value = new Double4(XElement.ValueBox.Value, YElement.ValueBox.Value, ZElement.ValueBox.Value, WElement.ValueBox.Value);
            object v = Values[0];
            if (v is Vector4)
                v = (Vector4)value;
            else if (v is Float4)
                v = (Float4)value;
            else if (v is Double4)
                v = (Double4)value;
            SetValue(v, token);
        }

        /// <inheritdoc />
        public override void Refresh()
        {
            base.Refresh();

            if (HasDifferentValues)
            {
                // TODO: support different values for ValueBox<T>
            }
            else
            {
                var value = Double4.Zero;
                if (Values[0] is Vector4 asVector4)
                    value = asVector4;
                else if (Values[0] is Float4 asFloat4)
                    value = asFloat4;
                else if (Values[0] is Double4 asDouble4)
                    value = asDouble4;
                XElement.ValueBox.Value = value.X;
                YElement.ValueBox.Value = value.Y;
                ZElement.ValueBox.Value = value.Z;
                WElement.ValueBox.Value = value.W;
            }
        }
    }

    /// <summary>
    /// Default implementation of the inspector used to edit Int4 value type properties.
    /// </summary>
    [CustomEditor(typeof(Int4)), DefaultEditor]
    public class Int4Editor : CustomEditor
    {
        /// <summary>
        /// The X component editor.
        /// </summary>
        protected IntegerValueElement XElement;

        /// <summary>
        /// The Y component editor.
        /// </summary>
        protected IntegerValueElement YElement;

        /// <summary>
        /// The Z component editor.
        /// </summary>
        protected IntegerValueElement ZElement;

        /// <summary>
        /// The W component editor.
        /// </summary>
        protected IntegerValueElement WElement;

        /// <inheritdoc />
        public override DisplayStyle Style => DisplayStyle.Inline;

        /// <inheritdoc />
        public override void Initialize(LayoutElementsContainer layout)
        {
            var grid = layout.CustomContainer<UniformGridPanel>();
            var gridControl = grid.CustomControl;
            gridControl.ClipChildren = false;
            gridControl.Height = TextBox.DefaultHeight;
            gridControl.SlotsHorizontally = 4;
            gridControl.SlotsVertically = 1;

            LimitAttribute limit = null;
            var attributes = Values.GetAttributes();
            if (attributes != null)
            {
                limit = (LimitAttribute)attributes.FirstOrDefault(x => x is LimitAttribute);
            }

            XElement = grid.IntegerValue();
            XElement.SetLimits(limit);
            XElement.IntValue.ValueChanged += OnValueChanged;
            XElement.IntValue.SlidingEnd += ClearToken;

            YElement = grid.IntegerValue();
            YElement.SetLimits(limit);
            YElement.IntValue.ValueChanged += OnValueChanged;
            YElement.IntValue.SlidingEnd += ClearToken;

            ZElement = grid.IntegerValue();
            ZElement.SetLimits(limit);
            ZElement.IntValue.ValueChanged += OnValueChanged;
            ZElement.IntValue.SlidingEnd += ClearToken;

            WElement = grid.IntegerValue();
            WElement.SetLimits(limit);
            WElement.IntValue.ValueChanged += OnValueChanged;
            WElement.IntValue.SlidingEnd += ClearToken;
        }

        private void OnValueChanged()
        {
            if (IsSetBlocked)
                return;

            var isSliding = XElement.IsSliding || YElement.IsSliding || ZElement.IsSliding || WElement.IsSliding;
            var token = isSliding ? this : null;
            var value = new Int4(XElement.IntValue.Value, YElement.IntValue.Value, ZElement.IntValue.Value, WElement.IntValue.Value);
            SetValue(value, token);
        }

        /// <inheritdoc />
        public override void Refresh()
        {
            base.Refresh();

            if (HasDifferentValues)
            {
                // TODO: support different values for ValueBox<T>
            }
            else
            {
                var value = (Int4)Values[0];
                XElement.IntValue.Value = value.X;
                YElement.IntValue.Value = value.Y;
                ZElement.IntValue.Value = value.Z;
                WElement.IntValue.Value = value.W;
            }
        }
    }
}
