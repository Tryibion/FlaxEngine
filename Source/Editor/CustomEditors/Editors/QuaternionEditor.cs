// Copyright (c) 2012-2022 Wojciech Figat. All rights reserved.

using FlaxEditor.CustomEditors.Elements;
using FlaxEngine;
using FlaxEngine.GUI;

namespace FlaxEditor.CustomEditors.Editors
{
    /// <summary>
    /// Default implementation of the inspector used to edit Quaternion value type properties.
    /// </summary>
    [CustomEditor(typeof(Quaternion)), DefaultEditor]
    public class QuaternionEditor : CustomEditor
    {
        private Float3 _cachedAngles = Float3.Zero;
        private object _cachedToken;

        /// <summary>
        /// The X component element
        /// </summary>
        protected FloatValueElement XElement;

        /// <summary>
        /// The Y component element
        /// </summary>
        protected FloatValueElement YElement;

        /// <summary>
        /// The Z component element
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
            ZElement.ValueBox.ValueChanged += OnValueChanged;
            ZElement.ValueBox.SlidingEnd += ClearToken;
        }

        private void OnValueChanged()
        {
            if (IsSetBlocked)
                return;

            var isSliding = XElement.IsSliding || YElement.IsSliding || ZElement.IsSliding;
            var token = isSliding ? this : null;
            var useCachedAngles = isSliding && token == _cachedToken;

            float x = (useCachedAngles && !XElement.IsSliding) ? _cachedAngles.X : XElement.ValueBox.Value;
            float y = (useCachedAngles && !YElement.IsSliding) ? _cachedAngles.Y : YElement.ValueBox.Value;
            float z = (useCachedAngles && !ZElement.IsSliding) ? _cachedAngles.Z : ZElement.ValueBox.Value;

            x = Mathf.UnwindDegrees(x);
            y = Mathf.UnwindDegrees(y);
            z = Mathf.UnwindDegrees(z);

            if (!useCachedAngles)
            {
                _cachedAngles = new Float3(x, y, z);
            }

            _cachedToken = token;

            Quaternion.Euler(x, y, z, out Quaternion value);
            SetValue(value, token);
        }

        /// <inheritdoc />
        protected override void ClearToken()
        {
            _cachedToken = null;
            base.ClearToken();
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
                var value = (Quaternion)Values[0];
                var euler = value.EulerAngles;
                XElement.ValueBox.Value = euler.X;
                YElement.ValueBox.Value = euler.Y;
                ZElement.ValueBox.Value = euler.Z;
            }
        }
    }
}
