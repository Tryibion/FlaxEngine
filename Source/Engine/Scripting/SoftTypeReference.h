// Copyright (c) Wojciech Figat. All rights reserved.

#pragma once

#include "Scripting.h"
#include "ScriptingObject.h"
#include "Engine/Core/Log.h"
#include "Engine/Core/Collections/HashFunctions.h"
#include "Engine/Core/Types/String.h"
#include "Engine/Serialization/SerializationFwd.h"

/// <summary>
/// The soft reference to the scripting type contained in the scripting assembly.
/// </summary>
template<typename T = ScriptingObject>
API_STRUCT(InBuild, MarshalAs=StringAnsi) struct SoftTypeReference
{
protected:
    StringAnsi _typeName;
    StringAnsi _assemblyName;

public:
    SoftTypeReference() = default;

    SoftTypeReference(const SoftTypeReference& s)
        : _typeName(s._typeName)
        , _assemblyName(s._assemblyName)
    {
    }

    SoftTypeReference(SoftTypeReference&& s) noexcept
        : _typeName(MoveTemp(s._typeName))
        , _assemblyName(MoveTemp(s._assemblyName))
    {
    }

    SoftTypeReference(const StringView& s)
        : _typeName(s)
    {
    }

    SoftTypeReference(const StringAnsiView& s)
        : _typeName(s)
    {
    }

    SoftTypeReference(const char* s)
        : _typeName(s)
    {
    }

    SoftTypeReference(const StringAnsiView& typeName, const StringAnsiView& assemblyName)
        : _typeName(typeName)
        , _assemblyName(assemblyName)
    {
    }

public:
    FORCE_INLINE SoftTypeReference& operator=(SoftTypeReference&& s) noexcept
    {
        _typeName = MoveTemp(s._typeName);
        _assemblyName = MoveTemp(s._assemblyName);
        return *this;
    }

    FORCE_INLINE SoftTypeReference& operator=(StringAnsi&& s) noexcept
    {
        _typeName = MoveTemp(s);
        _assemblyName.Clear();
        return *this;
    }

    FORCE_INLINE SoftTypeReference& operator=(const SoftTypeReference& s)
    {
        _typeName = s._typeName;
        _assemblyName = s._assemblyName;
        return *this;
    }

    FORCE_INLINE SoftTypeReference& operator=(const StringAnsiView& s) noexcept
    {
        _typeName = s;
        _assemblyName.Clear();
        return *this;
    }

    FORCE_INLINE bool operator==(const SoftTypeReference& other) const
    {
        return _typeName == other._typeName && _assemblyName == other._assemblyName;
    }

    FORCE_INLINE bool operator!=(const SoftTypeReference& other) const
    {
        return _typeName != other._typeName || _assemblyName != other._assemblyName;
    }

    FORCE_INLINE bool operator==(const StringAnsiView& other) const
    {
        return _typeName == other;
    }

    FORCE_INLINE bool operator!=(const StringAnsiView& other) const
    {
        return _typeName != other;
    }

    FORCE_INLINE operator bool() const
    {
        return _typeName.HasChars();
    }

    operator StringAnsi() const
    {
        return _typeName;
    }

    String ToString() const
    {
        return _typeName.ToString();
    }

public:
    // Gets the type full name (eg. FlaxEngine.Actor).
    StringAnsiView GetTypeName() const
    {
        return StringAnsiView(_typeName);
    }

    // Gets the type assembly name (eg. FlaxEngine.CSharp).
    StringAnsiView GetAssemblyName() const
    {
        return StringAnsiView(_assemblyName);
    }

    // Sets the type assembly name (eg. FlaxEngine.CSharp).
    void SetAssemblyName(const StringAnsiView& assemblyName)
    {
        _assemblyName = assemblyName;
    }

    // Gets the type (resolves soft reference).
    ScriptingTypeHandle GetType() const
    {
        return Scripting::FindScriptingType(_typeName, _assemblyName);
    }

    // Creates a new objects of that type (or of type T if failed to solve typename).
    T* NewObject() const
    {
        const ScriptingTypeHandle type = Scripting::FindScriptingType(_typeName);
        auto obj = ScriptingObject::NewObject<T>(type);
        if (!obj)
        {
            if (_typeName.HasChars())
                LOG(Error, "Unknown or invalid type {0}", String(_typeName));
            obj = ScriptingObject::NewObject<T>();
        }
        return obj;
    }
};

template<typename T>
uint32 GetHash(const SoftTypeReference<T>& key)
{
    uint32 hash = GetHash(key.GetTypeName());
    CombineHash(hash, GetHash(key.GetAssemblyName()));
    return hash;
}

// @formatter:off
namespace Serialization
{
    template<typename T>
    bool ShouldSerialize(const SoftTypeReference<T>& v, const void* otherObj)
    {
        return !otherObj || v != *(SoftTypeReference<T>*)otherObj;
    }
    template<typename T>
    void Serialize(ISerializable::SerializeStream& stream, const SoftTypeReference<T>& v, const void* otherObj)
    {
        if (v.GetAssemblyName().Length() == 0)
        {
            stream.String(v.GetTypeName());
            return;
        }
        stream.StartObject();
        stream.JKEY("TypeName");
        stream.String(v.GetTypeName());
        stream.JKEY("AssemblyName");
        stream.String(v.GetAssemblyName());
        stream.EndObject();
    }
    template<typename T>
    void Deserialize(ISerializable::DeserializeStream& stream, SoftTypeReference<T>& v, ISerializeModifier* modifier)
    {
        if (stream.IsString())
        {
            v = stream.GetStringAnsiView();
            return;
        }
        if (stream.IsObject())
        {
            StringAnsiView typeName;
            StringAnsiView assemblyName;
            const auto mTypeName = SERIALIZE_FIND_MEMBER(stream, "TypeName");
            if (mTypeName != stream.MemberEnd() && mTypeName->value.IsString())
                typeName = StringAnsiView(mTypeName->value.GetStringAnsiView());
            const auto mAssemblyName = SERIALIZE_FIND_MEMBER(stream, "AssemblyName");
            if (mAssemblyName != stream.MemberEnd() && mAssemblyName->value.IsString())
                assemblyName = StringAnsiView(mAssemblyName->value.GetStringAnsiView());
            v = SoftTypeReference<T>(typeName, assemblyName);
        }
    }
}
// @formatter:on
