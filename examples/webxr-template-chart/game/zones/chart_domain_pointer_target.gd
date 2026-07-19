@tool
class_name ChartDomainPointerTarget
extends StaticBody3D

var controller: Node


func pointer_event(event: Object) -> void:
	if controller != null and controller.has_method("_on_pointable_event"):
		controller._on_pointable_event(self, event)
