extends SceneTree
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func check(value: bool, message: String) -> void:
 if not value:
  failures += 1
  push_error(message)
func frames(count: int) -> void:
 for i in range(count):
  await physics_frame
  await process_frame
func action(name: StringName, pressed: bool) -> void:
 var event := InputEventAction.new()
 event.action = name
 event.pressed = pressed
 Input.parse_input_event(event)
func foot_minimum(visual: Node3D, name: String) -> float:
 var minimum := INF
 var leg: MeshInstance3D = visual.pieces[name]
 # Inspect the full exported leg geometry independently of the animation cache.
 for point in leg.mesh.get_faces():
  minimum = minf(minimum,(leg.transform*point).y)
 return minimum
func run() -> void:
 var scene: Node3D = load("res://scenes/main.tscn").instantiate()
 root.add_child(scene)
 var player: CharacterBody3D = scene.get_node("Player")
 var visual: Node3D = player.get_node("Visual")
 var camera: Camera3D = scene.get_node("Camera")
 await frames(70)
 check(is_equal_approx(player.speed,4.0),"Player speed changed")
 var shape: CapsuleShape3D = player.get_node("CollisionShape3D").shape
 check(is_equal_approx(shape.height,1.6) and is_equal_approx(shape.radius,0.3),"Player collision dimensions changed")
 check(player.get_node("CollisionShape3D").position == Vector3(0,0.8,0),"Capsule center changed")
 var queue: Array[Node] = [visual]
 while not queue.is_empty():
  var n: Node = queue.pop_front()
  queue.append_array(n.get_children())
  check(not (n is CollisionObject3D or n is CollisionShape3D or n is Skeleton3D or n is Light3D),"Visual adds functional node")
 var lantern: Node3D = visual.pieces["Lantern"]
 var right_arm: Node3D = visual.pieces["Arm_R"]
 var attachment: Transform3D = lantern.transform
 check(lantern.get_parent() == right_arm,"Lantern not attached to holding arm")
 var left_rest: Transform3D = visual.pieces["Leg_L"].transform
 var right_rest: Transform3D = visual.pieces["Leg_R"].transform
 await frames(25)
 check(visual.pieces["Leg_L"].transform == left_rest and visual.pieces["Leg_R"].transform == right_rest,"Idle moves feet")
 # All four input directions for each camera quadrant, on the real island floor.
 player.speed = 1.2
 for quadrant in range(4):
  for name in [&"move_forward",&"move_back",&"move_left",&"move_right"]:
   player.position = Vector3(-0.4,0.01,4.65)
   player.velocity = Vector3.ZERO
   await frames(3)
   var right := camera.global_basis.x
   var back := camera.global_basis.z
   right.y = 0
   back.y = 0
   var expected: Vector3 = -back.normalized() if name==&"move_forward" else back.normalized() if name==&"move_back" else -right.normalized() if name==&"move_left" else right.normalized()
   action(name,true)
   await frames(22)
   check(visual.global_basis.z.normalized().dot(expected) > 0.995,"Visual facing disagrees with camera-relative travel")
   check(visual.horizontal_speed > 1.0 and visual.motion_weight > 0.99,"Walking does not use real movement")
   var left_angle: float = visual.pieces["Leg_L"].rotation.x
   var right_angle: float = visual.pieces["Leg_R"].rotation.x
   check(absf(left_angle+right_angle)<0.0001,"Legs are not alternating")
   check(lantern.transform.is_equal_approx(attachment),"Lantern slips from hand")
   var lantern_bounds: AABB = visual.global_transform.affine_inverse()*lantern.global_transform*(lantern as MeshInstance3D).mesh.get_aabb()
   var torso: MeshInstance3D = visual.pieces["Torso"]
   var torso_bounds: AABB = visual.global_transform.affine_inverse()*torso.global_transform*torso.mesh.get_aabb()
   check(lantern_bounds.position.x > torso_bounds.end.x+0.01,"Lantern enters torso lateral envelope")
   check(foot_minimum(visual,"Leg_L") >= -0.0001 and foot_minimum(visual,"Leg_R") >= -0.0001,"Walking foot penetrates floor plane")
   action(name,false)
   await frames(20)
   check(visual.motion_weight == 0.0,"Walk does not blend back to idle")
  var stationary_heading: float = visual.rotation.y
  camera.request_turn(1)
  await frames(40)
  check(absf(angle_difference(visual.rotation.y,stationary_heading)) < 0.002,"Camera-only turn rotates idle character")
 # Gait phase follows distance, not a fixed timer or raw input.
 camera.yaw = 0
 await frames(2)
 for speed in [1.0,2.0]:
  player.speed = speed
  player.position = Vector3(-0.4,0.01,4.65)
  player.velocity = Vector3.ZERO
  await frames(3)
  var start: Vector3 = player.position
  var phase: float = visual.gait_phase
  action(&"move_right",true)
  await frames(12)
  var distance := Vector2(player.position.x-start.x,player.position.z-start.z).length()
  var phase_delta := fposmod(visual.gait_phase-phase,TAU)
  check(absf(phase_delta-distance*TAU/visual.STRIDE_LENGTH)<0.01,"Gait frequency is not proportional to real distance")
  action(&"move_right",false)
  await frames(20)
 # Turn Q during actual travel: heading must follow smoothly without altering controls.
 player.speed = 0.6
 player.position = Vector3(-0.4,0.01,4.65)
 player.velocity = Vector3.ZERO
 await frames(20)
 action(&"move_forward",true)
 await frames(1)
 check(visual.motion_weight > 0.0 and visual.motion_weight < 0.9,"Idle/walk transition is instantaneous")
 await frames(22)
 action(&"camera_left",true)
 for tick in range(40):
  var previous: float = visual.rotation.y
  await frames(1)
  check(absf(angle_difference(previous,visual.rotation.y)) < 0.25,"Camera turn causes abrupt visual heading")
 var real: Vector3 = player.get_real_velocity()
 real.y = 0
 check(visual.global_basis.z.normalized().dot(real.normalized()) > 0.995,"Visual fails to follow a moving camera-relative direction")
 action(&"camera_left",false)
 action(&"move_forward",false)
 await frames(20)
 camera.yaw = 0
 await frames(2)
 # Actual wall contact must stop walking even with the action held.
 player.speed = 4.0
 player.position = Vector3(-5.35,0.01,4.7)
 player.velocity = Vector3.ZERO
 await frames(3)
 action(&"move_left",true)
 await frames(35)
 check(player.is_on_wall() and visual.motion_weight==0.0,"Blocked player keeps walking")
 var stopped_phase: float = visual.gait_phase
 await frames(10)
 check(is_equal_approx(stopped_phase,visual.gait_phase),"Held input animates without displacement")
 action(&"move_left",false)
 # Inspection/control suspension must also stop the presentation.
 player.controls_suspended = true
 action(&"move_right",true)
 await frames(20)
 check(visual.motion_weight==0.0 and visual.horizontal_speed < 0.01,"Suspended controls still walk")
 action(&"move_right",false)
 player.controls_suspended = false
 print("keeper_visual: 16 camera-relative directions; idle feet, camera-only heading, gait distance, wall stop, lantern attachment/clearance, collision contract; %d failures" % failures)
 quit(0 if failures==0 else 1)
