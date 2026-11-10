# ==============================================================================
# BLENDER MCP AUTO-STARTER (FOR BLENDER GUI RUNTIME)
# Triggered when START_BLENDER_MCP_STUDIO.bat launches Blender
# ==============================================================================
import bpy

def auto_start_mcp():
    try:
        # Check if server operator is available
        if hasattr(bpy.ops, "blendermcp") and hasattr(bpy.ops.blendermcp, "start_server"):
            bpy.ops.blendermcp.start_server()
            print("\n" + "="*65)
            print("🚀 [BLENDER MCP STUDIO] PORT 9876 ACTIVATED!")
            print("✨ Antigravity IDE is now connected to Blender 4.2 LTS")
            print("✨ Ready to sculpt, rig, and export 3D assets to Godot 4!")
            print("="*65 + "\n")
        else:
            print("⚠️ [BLENDER MCP] 'blendermcp.start_server' operator not found!")
    except Exception as e:
        print("❌ [BLENDER MCP] Failed to start MCP server:", e)
    return None

# Register timer to execute 0.8s after Blender window opens
bpy.app.timers.register(auto_start_mcp, first_interval=0.8)
