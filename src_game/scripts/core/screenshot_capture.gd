class_name ScreenshotCapture
extends Node

# ==============================================================================
# AGENT-06 AUTOMATED SCREENSHOT CAPTURE (RTX 4060 GPU RENDER VERIFICATION)
# ==============================================================================

@export var enabled: bool = true
@export var auto_quit_after_captures: bool = false
@export var output_dir: String = "E:/DoAnCaNhan/ThuVienGame/GameWizad/docs/QA_REPORTS/screenshots/"
@export var prefix: String = "capture"

var capture_delays := [1.2, 2.2, 3.2]
var current_index: int = 0
var timer: float = 0.0

func _ready() -> void:
	for arg in OS.get_cmdline_args():
		if arg == "--capture-screens":
			enabled = true
			auto_quit_after_captures = true
			break
	if not enabled:
		set_process(false)

func _process(delta: float) -> void:
	if current_index >= capture_delays.size():
		if auto_quit_after_captures:
			print("📸 [AGENT-06 QA GATE] All screenshots captured. Quitting engine...")
			get_tree().quit(0)
		set_process(false)
		return
		
	timer += delta
	if timer >= capture_delays[current_index]:
		_capture_frame(current_index + 1)
		current_index += 1

func _capture_frame(idx: int) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		var dir = output_dir
		if not dir.ends_with("/"):
			dir += "/"
		var path = dir + prefix + "_" + str(idx) + ".png"
		var err = img.save_png(path)
		if err == OK:
			print("📸 [AGENT-06 QA GATE] Saved screenshot: ", path)
		else:
			print("⚠️ [AGENT-06 QA GATE] Failed to save screenshot: ", err)
