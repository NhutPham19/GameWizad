extends SceneTree

const KayKitAssetRegistry = preload("res://scripts/core/kaykit_asset_registry.gd")

func _init() -> void:
	print("==================================================================")
	print("KIỂM ĐỊNH PHASE 1: KAYKIT ASSET REGISTRY VERIFICATION")
	print("==================================================================")
	
	var all_assets: Dictionary = KayKitAssetRegistry.get_all_assets()
	var total: int = all_assets.size()
	var passed: int = 0
	var failed: int = 0
	
	for key in all_assets:
		var path: String = all_assets[key]
		var exists: bool = ResourceLoader.exists(path)
		if exists:
			var res = ResourceLoader.load(path)
			if res != null:
				passed += 1
				print("[PASS] %-16s -> %s (Loaded successfully)" % [key, path])
			else:
				failed += 1
				print("[FAIL] %-16s -> %s (Exists but load returned null!)" % [key, path])
		else:
			failed += 1
			print("[FAIL] %-16s -> %s (FILE NOT FOUND!)" % [key, path])
			
	print("==================================================================")
	print("KẾT QUẢ KIỂM ĐỊNH: %d/%d TÀI NGUYÊN HỢP LỆ (Passed: %d, Failed: %d)" % [passed, total, passed, failed])
	print("==================================================================")
	
	if failed == 0:
		print(">>> PHASE 1 HOÀN TẤT VỚI ĐỘ CHÍNH XÁC 100%! <<<")
		quit(0)
	else:
		print(">>> PHASE 1 THẤT BẠI! CẦN KIỂM TRA LẠI FILE THIẾU! <<<")
		quit(1)
