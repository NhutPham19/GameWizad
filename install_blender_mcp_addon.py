# ==============================================================================
# INSTALL BLENDER MCP ADDON & PERSIST PREFERENCES
# DIRECTIVE 11 - TASK 11.2 STEP 3
# ==============================================================================
import bpy
import os
import sys

print("[BLENDER MCP SETUP] Starting Addon Activation...")

# In Blender 4.2+, addon can be named 'blender_mcp' or 'addon'
activated = False
for mod in ["blender_mcp", "addon"]:
    try:
        bpy.ops.preferences.addon_enable(module=mod)
        print(f"[BLENDER MCP SETUP] ✅ Successfully enabled addon module: '{mod}'")
        activated = True
    except Exception as e:
        print(f"[BLENDER MCP SETUP] ℹ️ Module '{mod}' enable notice: {e}")

if activated:
    try:
        bpy.ops.wm.save_userpref()
        print("[BLENDER MCP SETUP] ✅ Blender user preferences saved successfully!")
    except Exception as e:
        print(f"[BLENDER MCP SETUP] ⚠️ Warning while saving user preferences: {e}")
else:
    print("[BLENDER MCP SETUP] ❌ Failed to enable addon modules!")
    sys.exit(1)
