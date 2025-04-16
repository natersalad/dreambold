extends Node

var is_in_shop: bool = false
var should_capture_mouse: bool = true

func enter_shop():
    is_in_shop = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func enter_gameplay():
    is_in_shop = false
    if should_capture_mouse:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)