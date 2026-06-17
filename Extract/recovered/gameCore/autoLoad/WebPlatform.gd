extends Node





















func _ready() -> void :



    process_mode = Node.PROCESS_MODE_ALWAYS

    if not OS.has_feature("web"):
        return

    _install_contextmenu_suppression()


func _notification(what: int) -> void :



    if not OS.has_feature("web"):
        return

    match what:




        NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
            get_tree().paused = true
        NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
            get_tree().paused = false








func _install_contextmenu_suppression() -> void :



    var js: String = "\n\t\t(function() {\n\t\t\tif (window.__egm_ctxmenu_blocked) return;\n\t\t\twindow.__egm_ctxmenu_blocked = true;\n\t\t\tdocument.addEventListener('contextmenu', function(e) {\n\t\t\t\te.preventDefault();\n\t\t\t\treturn false;\n\t\t\t}, true);\n\t\t})();\n\t"









    JavaScriptBridge.eval(js, true)
