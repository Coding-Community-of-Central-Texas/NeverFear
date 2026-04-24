@tool
extends EditorPlugin

var export_plugin: AndroidExportPlugin

func _enter_tree() -> void:
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	if export_plugin:
		remove_export_plugin(export_plugin)
		export_plugin = null

class AndroidExportPlugin extends EditorExportPlugin:
	func _supports_platform(platform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform, debug) -> PackedStringArray:
		if debug:
			return PackedStringArray([
				"gpgs_plugin/GpgsPlugin-debug.aar"
			])
		return PackedStringArray([
			"gpgs_plugin/GpgsPlugin-release.aar"
		])

	func _get_android_dependencies(platform, debug) -> PackedStringArray:
		return PackedStringArray([
			"com.google.android.gms:play-services-games-v2:21.0.0"
		])

	func _get_android_dependencies_maven_repos(platform, debug) -> PackedStringArray:
		return PackedStringArray([
			"https://dl.google.com/dl/android/maven2",
			"https://repo.maven.apache.org/maven2"
		])

	func _get_name() -> String:
		return "GpgsPlugin"
