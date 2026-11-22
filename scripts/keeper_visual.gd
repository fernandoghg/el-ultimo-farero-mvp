extends Node3D
## Rigid-piece presentation only. Never writes to the player, its collider or the camera.
const STRIDE_LENGTH := 1.8
const STEP_ANGLE := 0.34
const TURN_RESPONSE := 16.0
const BLEND_DURATION := 0.14
const SPEED_EPSILON := 0.04
var horizontal_speed := 0.0
var motion_weight := 0.0
var gait_phase := 0.0
var target_yaw := 0.0
var idle_clock := 0.0
var body_motion: Node3D
var pieces: Dictionary = {}
var rest: Dictionary = {}
var sole_points: Dictionary = {}
@onready var player := get_parent() as CharacterBody3D
@onready var model: Node3D = $Model

func _ready() -> void:
 process_physics_priority = 10 # Read real motion after Player.move_and_slide().
 for piece_name in ["Torso","Head","Arm_L","Arm_R","Leg_L","Leg_R","Lantern"]:
  var piece: Node3D = model.find_child(piece_name,true,false)
  assert(piece != null,"Missing approved keeper piece: "+piece_name)
  pieces[piece_name] = piece
 body_motion = Node3D.new()
 body_motion.name = "UpperBodyMotion"
 add_child(body_motion)
 for piece_name in ["Torso","Head","Arm_L","Arm_R"]:
  pieces[piece_name].reparent(body_motion,true)
 # Keep its approved hand-relative transform; the lantern follows the actual right arm.
 pieces["Lantern"].reparent(pieces["Arm_R"],true)
 for piece_name in ["Leg_L","Leg_R"]:
  var leg: MeshInstance3D = pieces[piece_name]
  rest[piece_name] = leg.transform
  var points := PackedVector3Array()
  for surface in range(leg.mesh.get_surface_count()):
   var vertices: PackedVector3Array = leg.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
   for point in vertices:
    if (leg.transform * point).y < 0.1:
     points.append(point)
  assert(not points.is_empty())
  sole_points[piece_name] = points
 target_yaw = rotation.y

func _physics_process(delta: float) -> void:
 if not is_instance_valid(player):
  return
 var velocity := player.get_real_velocity() if player.is_physics_processing() else Vector3.ZERO
 var horizontal := Vector3(velocity.x,0,velocity.z)
 horizontal_speed = horizontal.length()
 var moving := horizontal_speed > SPEED_EPSILON and player.is_on_floor()
 var target_weight := 1.0 if moving else 0.0
 motion_weight = move_toward(motion_weight,target_weight,delta/BLEND_DURATION)
 if moving:
  # Cycles follow distance actually travelled, including slow movement and sliding.
  gait_phase = fposmod(gait_phase + horizontal_speed * delta * TAU / STRIDE_LENGTH,TAU)
  target_yaw = atan2(horizontal.x,horizontal.z) - player.global_rotation.y
 rotation.y = lerp_angle(rotation.y,target_yaw,1.0-exp(-TURN_RESPONSE*delta))
 idle_clock += delta
 var wave := sin(gait_phase)
 _pose_leg("Leg_L",-wave*STEP_ANGLE*motion_weight,maxf(0.0,cos(gait_phase))*0.045*motion_weight)
 _pose_leg("Leg_R",wave*STEP_ANGLE*motion_weight,maxf(0.0,-cos(gait_phase))*0.045*motion_weight)
 pieces["Arm_L"].rotation.x = wave*0.23*motion_weight
 pieces["Arm_R"].rotation.x = -wave*0.18*motion_weight
 pieces["Head"].rotation.x = -sin(gait_phase*2.0)*0.012*motion_weight
 body_motion.position.y = (1.0-cos(gait_phase*2.0))*0.011*motion_weight + sin(idle_clock*1.8)*0.002*(1.0-motion_weight)

func _pose_leg(piece_name: String, angle: float, lift: float) -> void:
 var leg: MeshInstance3D = pieces[piece_name]
 var original: Transform3D = rest[piece_name]
 var basis := original.basis * Basis(Vector3.RIGHT,angle)
 var minimum := INF
 for point in sole_points[piece_name]:
  minimum = minf(minimum,(basis*point+original.origin).y)
 # Visual-only foot clearance. The collision and player root remain untouched.
 leg.transform = Transform3D(basis,original.origin+Vector3.UP*(maxf(0.0,-minimum)+lift))
