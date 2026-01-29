// Copyright (c) Wojciech Figat. All rights reserved.

using System;

namespace FlaxEngine
{
    /// <summary>
    /// The soft reference to the scripting type contained in the scripting assembly.
    /// </summary>
    public struct SoftTypeReference : IComparable, IComparable<SoftTypeReference>
    {
        private string _typeName;
        private string _assemblyName;

        /// <summary>
        /// Gets or sets the type full name (eg. FlaxEngine.Actor).
        /// </summary>
        public string TypeName
        {
            get => _typeName;
            set => _typeName = value;
        }

        /// <summary>
        /// Gets or sets the type assembly name (eg. FlaxEngine.CSharp).
        /// </summary>
        public string AssemblyName
        {
            get => _assemblyName;
            set => _assemblyName = value;
        }

        /// <summary>
        /// Gets or sets the type (resolves soft reference).
        /// </summary>
        public Type Type
        {
            get
            {
                if (_typeName == null)
                    return null;
                if (!string.IsNullOrEmpty(_assemblyName))
                {
                    var type = Type.GetType(_typeName + ", " + _assemblyName);
                    if (type != null)
                        return type;
                }
                return Type.GetType(_typeName);
            }
            set
            {
                if (value == null)
                {
                    _typeName = null;
                    _assemblyName = null;
                    return;
                }
                _typeName = value.FullName;
                _assemblyName = _typeName != null ? value.Assembly.GetName().Name : null;
            }
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="SoftTypeReference"/>.
        /// </summary>
        /// <param name="typeName">The type name.</param>
        public SoftTypeReference(string typeName)
        {
            _typeName = typeName;
            _assemblyName = null;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="SoftTypeReference"/>.
        /// </summary>
        /// <param name="typeName">The type name.</param>
        /// <param name="assemblyName">The assembly name.</param>
        public SoftTypeReference(string typeName, string assemblyName)
        {
            _typeName = typeName;
            _assemblyName = assemblyName;
        }

        /// <summary>
        /// Implicit cast operator from type name to string.
        /// </summary>
        /// <param name="s">The soft type reference.</param>
        /// <returns>The type name.</returns>
        public static implicit operator string(SoftTypeReference s)
        {
            return s._typeName;
        }

        /// <summary>
        /// Gets the soft type reference from full name.
        /// </summary>
        /// <param name="s">The type name.</param>
        /// <returns>The soft type reference.</returns>
        public static implicit operator SoftTypeReference(string s)
        {
            return new SoftTypeReference { _typeName = s };
        }

        /// <summary>
        /// Gets the soft type reference from runtime type.
        /// </summary>
        /// <param name="s">The type.</param>
        /// <returns>The soft type reference.</returns>
        public static implicit operator SoftTypeReference(Type s)
        {
            return new SoftTypeReference { Type = s };
        }

        /// <inheritdoc />
        public override string ToString()
        {
            return _typeName;
        }

        /// <inheritdoc />
        public override int GetHashCode()
        {
            var hash = _typeName?.GetHashCode() ?? 0;
            if (_assemblyName != null)
                hash = (hash * 397) ^ _assemblyName.GetHashCode();
            return hash;
        }

        /// <inheritdoc />
        public int CompareTo(object obj)
        {
            if (obj is SoftTypeReference other)
                return CompareTo(other);
            return 0;
        }

        /// <inheritdoc />
        public int CompareTo(SoftTypeReference other)
        {
            var result = string.Compare(_typeName, other._typeName, StringComparison.Ordinal);
            if (result != 0)
                return result;
            return string.Compare(_assemblyName, other._assemblyName, StringComparison.Ordinal);
        }
    }
}
