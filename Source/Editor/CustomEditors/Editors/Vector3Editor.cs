// Copyright (c) 2012-2022 Wojciech Figat. All rights reserved.

using System.Linq;
using FlaxEditor.CustomEditors.Elements;
using FlaxEngine;
using FlaxEngine.GUI;

namespace FlaxEditor.CustomEditors.Editors
{
    /// <summary>
    /// Default implementation of the inspector used to edit Vector3 value type properties.
    /// </summary>
    [CustomEditor(typeof(Vector3)), DefaultEditor]
    public class Vector3Editor :
#if USE_LARGE_WORLDS
    Double3Editor
#else
    Float3Editor
#endif
    {
    }

    /// <summary>
    /// Default implementation of the inspector used to edit Float3 value type properties.
    /// </summary>
    [CustomEditor(typeof(Float3)), DefaultEditor]
    public class Float3Editor : CustomEditor
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

        /// <inheritdoc />
        public override DisplayStyle Style => DisplayStyle.Inline;

        /// <inheritdoc />
        public override void Initialize(LayoutElementsContainer layout)
        {
            var grid = layout.CustomContainer<UniformGridPanel>();
            var gridControl = grid.CustomControl;
            gridControl.ClipChildren = false;
            gridControl.Height = TextBox.DefaultHeight + 5;
            gridControl.SlotsHorizontally = 3;
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
            YElement.ValueBox.BackgroundColor = Color.Black;
            YElement.ValueBox.BorderColor = Color.LightGray;
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
        }

        private void OnValueChanged()
        {
            if (IsSetBlocked)
                return;

            var isSliding = XElement.IsSliding || YElement.IsSliding || ZElement.IsSliding;
            var token = isSliding ? this : null;
            var value = new Float3(XElement.ValueBox.Value, YElement.ValueBox.Value, ZElement.ValueBox.Value);
            object v = Values[0];
            if (v is Vector3)
                v = (Vector3)value;
            else if (v is Float3)
                v = (Float3)value;
            else if (v is Double3)
                v = (Double3)value;
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
                var value = Float3.Zero;
                if (Values[0] is Vector3 asVector3)
                    value = asVector3;
                else if (Values[0] is Float3 asFloat3)
                    value = asFloat3;
                else if (Values[0] is Double3 asDouble3)
                    value = asDouble3;
                XElement.ValueBox.Value = value.X;
                YElement.ValueBox.Value = value.Y;
                ZElement.ValueBox.Value = value.Z;
            }
        }
    }

    /// <summary>
    /// Default implementation of the inspector used to edit Double3 value type properties.
    /// </summary>
    [CustomEditor(typeof(Double3)), DefaultEditor]
    public class Double3Editor : CustomEditor
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

        /// <inheritdoc />
        public override DisplayStyle Style => DisplayStyle.Inline;

        /// <inheritdoc />
        public override void Initialize(LayoutElementsContainer layout)
        {
            var grid = layout.CustomContainer<UniformGridPanel>();
            var gridControl = grid.CustomControl;
            gridControl.ClipChildren = false;
            gridControl.Height = TextBox.DefaultHeight + 5;
            gridControl.SlotsHorizontally = 3;
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
            
            XElement = xPanel.DoubleValue();
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
            
            YElement = yPanel.DoubleValue();
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
            
            ZElement = zPanel.DoubleValue();
            ZElement.ValueBox.AnchorPreset = AnchorPresets.StretchAll;
            ZElement.ValueBox.Location += new Float2(22, 0);
            ZElement.ValueBox.Width -= 22f;
            ZElement.SetLimits(limit);
            ZElement.ValueBox.ValueChanged += OnValueChanged;
            ZElement.ValueBox.SlidingEnd += ClearToken;
        }

        private void OnValueChanged()
        {
            if (IsSetBlocked)
                return;

            var isSliding = XElement.IsSliding || YElement.IsSliding || ZElement.IsSliding;
            var token = isSliding ? this : null;
            var value = new Double3(XElement.ValueBox.Value, YElement.ValueBox.Value, ZElement.ValueBox.Value);
            object v = Values[0];
            if (v is Vector3)
                v = (Vector3)value;
            else if (v is Float3)
                v = (Float3)value;
            else if (v is Double3)
                v = (Double3)value;
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
                var value = Double3.Zero;
                if (Values[0] is Vector3 asVector3)
                    value = asVector3;
                else if (Values[0] is Float3 asFloat3)
                    value = asFloat3;
                else if (Values[0] is Double3 asDouble3)
                    value = asDouble3;
                XElement.ValueBox.Value = value.X;
                YElement.ValueBox.Value = value.Y;
                ZElement.ValueBox.Value = value.Z;
            }
        }
    }

    /// <summary>
    /// Default implementation of the inspector used to edit Int3 value type properties.
    /// </summary>
    [CustomEditor(typeof(Int3)), DefaultEditor]
    public class Int3Editor : CustomEditor
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

        /// <inheritdoc />
        public override DisplayStyle Style => DisplayStyle.Inline;

        /// <inheritdoc />
        public override void Initialize(LayoutElementsContainer layout)
        {
            var grid = layout.CustomContainer<UniformGridPanel>();
            var gridControl = grid.CustomControl;
            gridControl.ClipChildren = false;
            gridControl.Height = TextBox.DefaultHeight + 5;
            gridControl.SlotsHorizontally = 3;
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
            
            XElement = xPanel.IntegerValue();
            XElement.IntValue.AnchorPreset = AnchorPresets.StretchAll;
            XElement.IntValue.Location += new Float2(22, 0);
            XElement.IntValue.Width -= 22f;
            XElement.SetLimits(limit);
            XElement.IntValue.ValueChanged += OnValueChanged;
            XElement.IntValue.SlidingEnd += ClearToken;

            var yPanel = grid.HorizontalPanel();
            yPanel.Panel.Margin = new Margin(0);
            yPanel.Panel.AutoSize = false;

            var yLabel = yPanel.Label("Y", TextAlignment.Center);
            yLabel.Label.BackgroundColor = Color.Green;
            yLabel.Label.TextColor = Color.White;
            yLabel.Label.Width = 20f;
            
            YElement = yPanel.IntegerValue();
            YElement.IntValue.AnchorPreset = AnchorPresets.StretchAll;
            YElement.IntValue.Location += new Float2(22, 0);
            YElement.IntValue.Width -= 22f;
            YElement.SetLimits(limit);
            YElement.IntValue.ValueChanged += OnValueChanged;
            YElement.IntValue.SlidingEnd += ClearToken;
            
            var zPanel = grid.HorizontalPanel();
            zPanel.Panel.Margin = new Margin(0);
            zPanel.Panel.AutoSize = false;
            
            var zLabel = zPanel.Label("Z", TextAlignment.Center);
            zLabel.Label.BackgroundColor = Color.Blue;
            zLabel.Label.TextColor = Color.White;
            zLabel.Label.Width = 20f;
            
            ZElement = zPanel.IntegerValue();
            ZElement.IntValue.AnchorPreset = AnchorPresets.StretchAll;
            ZElement.IntValue.Location += new Float2(22, 0);
            ZElement.IntValue.Width -= 22f;
            ZElement.SetLimits(limit);
            ZElement.IntValue.ValueChanged += OnValueChanged;
            ZElement.IntValue.SlidingEnd += ClearToken;
        }

        private void OnValueChanged()
        {
            if (IsSetBlocked)
                return;

            var isSliding = XElement.IsSliding || YElement.IsSliding || ZElement.IsSliding;
            var token = isSliding ? this : null;
            var value = new Int3(XElement.IntValue.Value, YElement.IntValue.Value, ZElement.IntValue.Value);
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
                var value = (Int3)Values[0];
                XElement.IntValue.Value = value.X;
                YElement.IntValue.Value = value.Y;
                ZElement.IntValue.Value = value.Z;
            }
        }
    }
}
