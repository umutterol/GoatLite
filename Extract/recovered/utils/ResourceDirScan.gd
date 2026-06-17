class_name ResourceDirScan
extends RefCounted




























static func list_tres_files(dir_path: String) -> Array[String]:
    var out: Array[String] = []
    var seen: Dictionary = {}
    _scan(dir_path, out, seen, false)
    return out




static func list_tres_files_recursive(dir_path: String) -> Array[String]:
    var out: Array[String] = []
    var seen: Dictionary = {}
    _scan(dir_path, out, seen, true)
    return out






static func _scan(dir_path: String, out: Array[String], seen: Dictionary, recursive: bool) -> void :
    var normalised: String = _ensure_trailing_slash(dir_path)
    var dir: = DirAccess.open(normalised)
    if dir == null:



        return

    if recursive:
        for sub_name in dir.get_directories():
            _scan(normalised + sub_name + "/", out, seen, true)

    for file_name in dir.get_files():
        var canonical: String = _to_canonical_tres(file_name)
        if canonical == "":
            continue
        var full_path: String = normalised + canonical
        if seen.has(full_path):
            continue
        seen[full_path] = true
        out.append(full_path)













static func _to_canonical_tres(file_name: String) -> String:
    if file_name.ends_with(".tres.remap"):
        return file_name.trim_suffix(".remap")
    if file_name.ends_with(".tres"):
        return file_name
    if file_name.ends_with(".res"):
        return file_name.trim_suffix(".res") + ".tres"
    return ""


static func _ensure_trailing_slash(path: String) -> String:
    if path.ends_with("/"):
        return path
    return path + "/"
