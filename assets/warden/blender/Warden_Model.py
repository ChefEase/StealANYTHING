import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler

# ---------------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------------
COLL_NAME = "Warden"
INSPECT_COLL_NAME = "Warden_Inspection"
PREFIX = "Warden_"
SAVE_BASENAME = "Warden_Model"
ARM_DROP_DEG = 58.0          # A-pose angle below horizontal (rig friendly)
CAP_TILT = (0.05, 0.18, 0.04)  # cap pitch / roll / yaw (radians)

# ---------------------------------------------------------------------------
# RESET (only Warden-owned data)
# ---------------------------------------------------------------------------
def _remove_collection_tree(name):
    coll = bpy.data.collections.get(name)
    if coll is None:
        return
    meshes, mats = set(), set()

    def walk(c):
        for child in list(c.children):
            walk(child)
        for ob in list(c.objects):
            if ob.type == 'MESH' and ob.data:
                meshes.add(ob.data)
                for s in ob.material_slots:
                    if s.material:
                        mats.add(s.material)
            data = ob.data
            bpy.data.objects.remove(ob, do_unlink=True)
            if data and data.users == 0:
                if isinstance(data, bpy.types.Light):
                    bpy.data.lights.remove(data)
                elif isinstance(data, bpy.types.Camera):
                    bpy.data.cameras.remove(data)
        if c != coll:
            bpy.data.collections.remove(c)

    walk(coll)
    bpy.data.collections.remove(coll)
    for m in meshes:
        if m.name in bpy.data.meshes and m.users == 0:
            bpy.data.meshes.remove(m)
    for m in mats:
        if m.name in bpy.data.materials and m.users == 0 and m.name.startswith(PREFIX):
            bpy.data.materials.remove(m)


def reset_warden():
    if bpy.context.mode != 'OBJECT':
        try:
            bpy.ops.object.mode_set(mode='OBJECT')
        except RuntimeError:
            pass
    _remove_collection_tree(COLL_NAME)
    _remove_collection_tree(INSPECT_COLL_NAME)
    for m in list(bpy.data.materials):
        if m.name.startswith(PREFIX) and m.users == 0:
            bpy.data.materials.remove(m)
    for m in list(bpy.data.meshes):
        if m.name.startswith(PREFIX) and m.users == 0:
            bpy.data.meshes.remove(m)


def make_collection(name):
    c = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(c)
    return c

# ---------------------------------------------------------------------------
# MATERIALS (one material per object -> one Roblox MeshPart material each)
# ---------------------------------------------------------------------------
def make_material(name, rgb, rough=0.6, metal=0.0, emission=None, strength=0.0):
    mat = bpy.data.materials.new(PREFIX + name)
    try:
        mat.use_nodes = True  # deprecated/no-op in 5.x, harmless
    except Exception:
        pass
    col = (*rgb, 1.0)
    mat.diffuse_color = col
    try:
        mat.roughness = rough
        mat.metallic = metal
    except Exception:
        pass
    nt = mat.node_tree
    bsdf = None
    if nt:
        bsdf = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if bsdf:
        bsdf.inputs["Base Color"].default_value = col
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        if emission is not None:
            for key in ("Emission Color", "Emission"):
                if key in bsdf.inputs:
                    bsdf.inputs[key].default_value = (*emission, 1.0)
                    break
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = strength
    return mat


def build_materials():
    return {
        "uniform": make_material("Mat_Uniform_Navy", (0.028, 0.045, 0.13), 0.7),
        "pants":   make_material("Mat_Pants_Navy",   (0.016, 0.022, 0.065), 0.75),
        "trim":    make_material("Mat_Trim_Teal",    (0.0, 0.55, 0.50), 0.4),
        "cap":     make_material("Mat_Cap_Navy",     (0.012, 0.018, 0.055), 0.55),
        "skin":    make_material("Mat_Skin_Pale",    (0.60, 0.64, 0.52), 0.65),
        "gold":    make_material("Mat_Badge_Gold",   (1.0, 0.68, 0.18), 0.28, 1.0),
        "belt":    make_material("Mat_Belt_Black",   (0.025, 0.02, 0.018), 0.35),
        "boot":    make_material("Mat_Boot_Black",   (0.02, 0.02, 0.025), 0.25),
        "glove":   make_material("Mat_Glove_Gray",   (0.62, 0.62, 0.60), 0.6),
        "eye":     make_material("Mat_Eye_Glow",     (1.0, 0.6, 0.05), 0.3, 0.0,
                                 emission=(1.0, 0.55, 0.0), strength=6.0),
        "mouth":   make_material("Mat_Mouth_Dark",   (0.03, 0.0, 0.01), 0.9),
        "teeth":   make_material("Mat_Teeth_Ivory",  (0.90, 0.86, 0.66), 0.5),
        "hair":    make_material("Mat_Brow_Hair",    (0.06, 0.045, 0.04), 0.9),
    }

# ---------------------------------------------------------------------------
# GEOMETRY PRIMITIVES (bmesh only)
# ---------------------------------------------------------------------------
def add_tube(bm, pts, radii, segs=8, ref=(0, -1, 0), phase=None, axis=None,
             caps=(True, True)):
    """Lofted low-poly tube through pts. radii: float or (rx, ry) per point."""
    pts = [Vector(p) for p in pts]
    ref = Vector(ref).normalized()
    if phase is None:
        phase = math.pi / segs
    n = len(pts)
    rings = []
    for i, c in enumerate(pts):
        if axis is not None:
            t = Vector(axis)
        elif i == 0:
            t = pts[1] - pts[0]
        elif i == n - 1:
            t = pts[-1] - pts[-2]
        else:
            t = pts[i + 1] - pts[i - 1]
        t.normalize()
        u = t.cross(ref)
        if u.length < 1e-6:
            u = t.cross(Vector((1, 0, 0)))
        u.normalize()
        v = t.cross(u)
        r = radii[i]
        rx, ry = (r, r) if isinstance(r, (int, float)) else r
        ring = []
        for k in range(segs):
            a = phase + 2 * math.pi * k / segs
            ring.append(bm.verts.new(c + u * (rx * math.cos(a)) + v * (ry * math.sin(a))))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for k in range(segs):
            k2 = (k + 1) % segs
            bm.faces.new((a[k], a[k2], b[k2], b[k]))
    if caps[0]:
        bm.faces.new(list(reversed(rings[0])))
    if caps[1]:
        bm.faces.new(rings[-1])


def add_box(bm, size, mat4, taper=(1.0, 1.0), shear=0.0, bevel=0.0):
    sx, sy, sz = size
    vs = []
    for zi in (-1, 1):
        for yi in (-1, 1):
            for xi in (-1, 1):
                tx, ty = taper if zi > 0 else (1.0, 1.0)
                p = Vector((xi * sx / 2 * tx, yi * sy / 2 * ty + (shear if zi > 0 else 0.0),
                            zi * sz / 2))
                vs.append(bm.verts.new(mat4 @ p))
    idx = [(0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5), (0, 2, 3, 1), (4, 5, 7, 6)]
    faces = [bm.faces.new([vs[i] for i in f]) for f in idx]
    if bevel > 0:
        edges = list({e for f in faces for e in f.edges})
        try:
            bmesh.ops.bevel(bm, geom=vs + edges, offset=bevel, offset_type='OFFSET',
                            segments=1, profile=0.5, affect='EDGES', clamp_overlap=True)
        except Exception as ex:
            print(f"[Warden] bevel skipped: {ex}")


def add_torus(bm, center, normal, R, r, segs=8, sides=4):
    n = Vector(normal).normalized()
    a = n.orthogonal().normalized()
    b = n.cross(a)
    c = Vector(center)
    rings = []
    for i in range(segs):
        th = 2 * math.pi * i / segs
        d = a * math.cos(th) + b * math.sin(th)
        rings.append([bm.verts.new(c + d * (R + r * math.cos(ph)) + n * (r * math.sin(ph)))
                      for ph in (2 * math.pi * j / sides + math.pi / 4 for j in range(sides))])
    for i in range(segs):
        r0, r1 = rings[i], rings[(i + 1) % segs]
        for j in range(sides):
            j2 = (j + 1) % sides
            bm.faces.new((r0[j], r0[j2], r1[j2], r1[j]))


# closures so several shapes can be merged into one object
def Tube(pts, radii, segs=8, ref=(0, -1, 0), phase=None, axis=None, caps=(True, True)):
    return lambda bm: add_tube(bm, pts, radii, segs, ref, phase, axis, caps)


def Box(size, loc=(0, 0, 0), rot=(0, 0, 0), taper=(1, 1), shear=0.0, bevel=0.0, frame=None):
    m = frame if frame is not None else (
        Matrix.Translation(Vector(loc)) @ Euler(rot, 'XYZ').to_matrix().to_4x4())
    return lambda bm: add_box(bm, size, m, taper, shear, bevel)


def Torus(center, normal, R, r, segs=8, sides=4):
    return lambda bm: add_torus(bm, center, normal, R, r, segs, sides)


def frame_matrix(loc, xa, ya, za):
    m = Matrix((xa, ya, za)).transposed().to_4x4()
    m.translation = Vector(loc)
    return m

# ---------------------------------------------------------------------------
# SURFACE HELPERS (rings: list of (z, center_y, rx, ry), octagon flat front)
# ---------------------------------------------------------------------------
def surf_y(rings, z, x=0.0):
    if z <= rings[0][0]:
        a = b = rings[0]; t = 0.0
    elif z >= rings[-1][0]:
        a = b = rings[-1]; t = 0.0
    else:
        a, b, t = rings[0], rings[1], 0.0
        for ra, rb in zip(rings, rings[1:]):
            if ra[0] <= z <= rb[0]:
                a, b, t = ra, rb, (z - ra[0]) / (rb[0] - ra[0])
                break
    cy = a[1] + (b[1] - a[1]) * t
    rx = a[2] + (b[2] - a[2]) * t
    ry = a[3] + (b[3] - a[3]) * t
    yf = cy - 0.924 * ry
    flat = 0.383 * rx
    if abs(x) > flat:
        yf += (abs(x) - flat) * (ry / rx)
    return yf


def surf_n(rings, z, x=0.0, e=0.01):
    fx = (surf_y(rings, z, x + e) - surf_y(rings, z, x - e)) / (2 * e)
    fz = (surf_y(rings, z + e, x) - surf_y(rings, z - e, x)) / (2 * e)
    return Vector((fx, -1.0, fz)).normalized()


def Decal(rings, x, z, rx, ry, depth, segs=6, phase=0.0, sink=0.01, roll=0.0):
    """Disc/plate sitting on a ring-surface, facing its outward normal."""
    p = Vector((x, surf_y(rings, z, x), z))
    n = surf_n(rings, z, x)
    ref = (math.sin(roll), 0.0, math.cos(roll))
    return Tube([p - n * sink, p + n * depth], [(rx, ry), (rx, ry)], segs, ref, phase)

# ---------------------------------------------------------------------------
# PART BUILDER
# ---------------------------------------------------------------------------
class Builder:
    def __init__(self, coll):
        self.coll = coll
        self.parts = {}

    def part(self, name, mat, pivot, geoms, post=None, rigid=False):
        bm = bmesh.new()
        for g in geoms:
            g(bm)
        if post is not None:
            bmesh.ops.transform(bm, matrix=post, verts=bm.verts[:])
        pv = Vector(pivot)
        bmesh.ops.translate(bm, vec=-pv, verts=bm.verts[:])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        me = bpy.data.meshes.new(PREFIX + name + "_Mesh")
        bm.to_mesh(me)
        bm.free()
        for p in me.polygons:
            p.use_smooth = False          # faceted stylized low-poly
        me.materials.append(mat)
        ob = bpy.data.objects.new(PREFIX + name, me)
        ob.location = pv                  # origin = joint pivot
        self.coll.objects.link(ob)
        ob["warden_part"] = name
        ob["warden_deform"] = "rigid_attach" if rigid else "bone_segment"
        self.parts[name] = ob
        return ob

# ---------------------------------------------------------------------------
# WARDEN
# ---------------------------------------------------------------------------
def build_warden(coll, M):
    B = Builder(coll)
    P = B.part
    X = Vector((1, 0, 0))

    def rings_tube(rings, segs=8):
        return Tube([(0, y, z) for z, y, rx, ry in rings],
                    [(rx, ry) for z, y, rx, ry in rings], segs, axis=(0, 0, 1))

    # ---------------- Pelvis / jacket hem / belt ---------------------------
    PELVIS_R = [(0.84, 0.02, 0.17, 0.13), (0.95, 0.02, 0.19, 0.145), (1.06, 0.02, 0.165, 0.13)]
    HEM_R = [(0.92, 0.02, 0.228, 0.172), (1.00, 0.02, 0.205, 0.16), (1.08, 0.02, 0.17, 0.135)]
    TORSO_R = [(1.07, 0.02, 0.155, 0.125), (1.33, -0.01, 0.24, 0.165),
               (1.54, -0.09, 0.37, 0.205), (1.70, -0.17, 0.42, 0.195),
               (1.80, -0.23, 0.28, 0.15)]
    PELVIS_PIV = (0, 0.02, 0.98)
    WAIST_PIV = (0, 0.02, 1.10)

    P("Pelvis", M["pants"], PELVIS_PIV, [rings_tube(PELVIS_R)])
    P("JacketHem", M["uniform"], PELVIS_PIV, [rings_tube(HEM_R)])
    P("Belt", M["belt"], PELVIS_PIV,
      [Tube([(0, 0.02, 1.075), (0, 0.02, 1.155)], [(0.19, 0.155)] * 2, axis=(0, 0, 1))])
    belt_front = 0.02 - 0.924 * 0.155
    P("BeltBuckle", M["gold"], PELVIS_PIV,
      [Box((0.13, 0.035, 0.09), (0, belt_front - 0.012, 1.115), bevel=0.012)], rigid=True)
    P("BeltPouch", M["belt"], PELVIS_PIV,
      [Box((0.08, 0.07, 0.10), (0.165, -0.07, 1.085), bevel=0.012),
       Box((0.085, 0.075, 0.03), (0.165, -0.072, 1.135), bevel=0.006)], rigid=True)
    P("BeltRadio", M["belt"], PELVIS_PIV,
      [Box((0.07, 0.05, 0.13), (-0.18, -0.04, 1.07), bevel=0.01),
       Tube([(-0.205, -0.04, 1.12), (-0.205, -0.04, 1.32)], [0.008, 0.006], 4)], rigid=True)
    P("Baton", M["belt"], PELVIS_PIV,
      [Tube([(0.205, 0.04, 1.13), (0.235, 0.06, 0.95), (0.26, 0.075, 0.70)],
            [0.03, 0.026, 0.03], 6)], rigid=True)
    P("Flashlight", M["glove"], PELVIS_PIV,
      [Tube([(-0.10, 0.17, 1.12), (-0.10, 0.18, 0.96)], [0.04, 0.03], 6)], rigid=True)
    keys = [Torus((-0.19, -0.03, 0.99), (0, 1, 0), 0.04, 0.008)]
    for i, ang in enumerate((-0.35, 0.0, 0.4)):
        keys.append(Box((0.022, 0.008, 0.075),
                        (-0.19 + math.sin(ang) * 0.06, -0.035 - i * 0.004,
                         0.93 - math.cos(ang) * 0.02), rot=(0, ang, 0)))
    P("KeyRing", M["gold"], PELVIS_PIV, keys, rigid=True)

    # ---------------- Torso: narrow waist, huge V-shoulders, hunched -------
    P("Torso", M["uniform"], WAIST_PIV, [rings_tube(TORSO_R)])
    P("Collar", M["trim"], WAIST_PIV,
      [Tube([(0, -0.21, 1.74), (0, -0.25, 1.86)], [(0.155, 0.13), (0.13, 0.11)], 8)])
    tie_z = [1.77, 1.72, 1.60, 1.48, 1.37, 1.30]
    tie_w = [0.06, 0.035, 0.045, 0.058, 0.07, 0.012]
    P("Tie", M["trim"], WAIST_PIV,
      [Tube([(0, surf_y(TORSO_R, z, 0) - 0.018, z) for z in tie_z],
            [(w, 0.016) for w in tie_w], 4, phase=math.pi / 4)])
    for side, sx in (("L", 1), ("R", -1)):
        z = 1.62
        fz = surf_n(TORSO_R, z, 0.115 * sx)
        pitch = -math.atan2(fz.z, 1.0) if False else math.atan2(-fz.z, -fz.y) * -1.0
        P(f"Lapel_{side}", M["trim"], WAIST_PIV,
          [Box((0.06, 0.02, 0.27), (0.115 * sx, surf_y(TORSO_R, z, 0.115) - 0.006, z),
               rot=(-pitch, sx * 0.38, 0), bevel=0.006)])
    buttons = []
    for z in (1.24, 1.36, 1.48):
        for bx in (-0.085, 0.085):
            buttons.append(Decal(TORSO_R, bx, z, 0.018, 0.018, 0.014, segs=6))
    P("Buttons", M["gold"], WAIST_PIV, buttons, rigid=True)
    P("Badge", M["gold"], WAIST_PIV,
      [Decal(TORSO_R, 0.20, 1.50, 0.075, 0.09, 0.025, segs=5, phase=math.pi / 2)], rigid=True)
    P("BadgeStar", M["trim"], WAIST_PIV,
      [Decal(TORSO_R, 0.20, 1.505, 0.032, 0.032, 0.036, segs=5, phase=1.5 * math.pi)],
      rigid=True)
    P("NamePlate", M["gold"], WAIST_PIV,
      [Decal(TORSO_R, -0.20, 1.53, 0.09, 0.03, 0.02, segs=4, phase=math.pi / 4)], rigid=True)

    # ---------------- Shoulders / epaulettes -------------------------------
    for side, sx in (("L", 1), ("R", -1)):
        P(f"Epaulette_{side}", M["trim"], WAIST_PIV,
          [Box((0.23, 0.21, 0.05), (0.34 * sx, -0.19, 1.80), rot=(0, sx * 0.5, 0),
               taper=(0.9, 0.85), bevel=0.012)], rigid=True)
        P(f"EpauletteFringe_{side}", M["gold"], WAIST_PIV,
          [Box((0.035, 0.21, 0.075), (0.445 * sx, -0.19, 1.73), rot=(0, sx * 0.5, 0),
               bevel=0.008)], rigid=True)

    # ---------------- Neck & big jutting head ------------------------------
    NECK_PIV = (0, -0.20, 1.74)
    HEAD_PIV = (0, -0.31, 1.93)
    P("Neck", M["skin"], NECK_PIV,
      [Tube([(0, -0.20, 1.72), (0, -0.31, 1.97)], [(0.09, 0.085), (0.085, 0.08)], 8)])
    HEAD_R = [(1.89, -0.40, 0.15, 0.12), (1.97, -0.40, 0.245, 0.20),
              (2.08, -0.37, 0.255, 0.22), (2.22, -0.35, 0.245, 0.22),
              (2.34, -0.34, 0.215, 0.20), (2.40, -0.335, 0.17, 0.155)]
    P("Head", M["skin"], HEAD_PIV, [rings_tube(HEAD_R)])

    def hf(z, x=0.0):
        return surf_y(HEAD_R, z, x)

    # angular brow ridge (diamond cross-section, angry V)
    bx = [-0.22, -0.16, -0.08, 0.0, 0.08, 0.16, 0.22]
    bz = [2.245 + 0.10 * abs(x) for x in bx]
    br = [(0.025, 0.03), (0.036, 0.042), (0.04, 0.05), (0.04, 0.052),
          (0.04, 0.05), (0.036, 0.042), (0.025, 0.03)]
    P("BrowRidge", M["skin"], HEAD_PIV,
      [Tube([(x, hf(z, x) - 0.015, z) for x, z in zip(bx, bz)], br, 4, phase=0.0)], rigid=True)
    # asymmetric eyebrows: L angry, R raised (creepy-comedic)
    brows = {"L": ([0.04, 0.12, 0.20], [2.262, 2.275, 2.29]),
             "R": ([-0.04, -0.12, -0.20], [2.28, 2.31, 2.295])}
    for side, (xs, zs) in brows.items():
        P(f"Eyebrow_{side}", M["hair"], HEAD_PIV,
          [Tube([(x, hf(z, x) - 0.05, z) for x, z in zip(xs, zs)],
                [(0.014, 0.02), (0.026, 0.03), (0.012, 0.018)], 4, phase=0.0)], rigid=True)

    # big glowing eyes in dark sockets (L wide stare, R squint)
    eyes = {"L": (0.12, 2.155, 0.068, 0.06, 0.0), "R": (-0.12, 2.145, 0.068, 0.036, 0.2)}
    for side, (ex, ez, erx, ery, roll) in eyes.items():
        P(f"Socket_{side}", M["mouth"], HEAD_PIV,
          [Decal(HEAD_R, ex, ez, erx + 0.018, ery + 0.016, 0.006, 6, 0.0, 0.02, roll)],
          rigid=True)
        P(f"Eye_{side}", M["eye"], HEAD_PIV,
          [Decal(HEAD_R, ex, ez, erx, ery, 0.022, 6, 0.0, 0.03, roll)], rigid=True)
        P(f"Pupil_{side}", M["mouth"], HEAD_PIV,
          [Decal(HEAD_R, ex + 0.022, ez, 0.011, ery * 0.6, 0.03, 4, math.pi / 4, 0.0, roll)],
          rigid=True)

    # crooked hooked nose (bends to -X)
    yf = hf(2.14, 0.0)
    P("Nose", M["skin"], HEAD_PIV,
      [Tube([(0.0, yf + 0.02, 2.17), (-0.015, yf - 0.045, 2.14),
             (-0.03, yf - 0.095, 2.10), (-0.036, yf - 0.12, 2.087)],
            [(0.035, 0.03), (0.04, 0.036), (0.046, 0.042), (0.02, 0.02)], 6,
            ref=(0, 0, 1))], rigid=True)

    # crooked wide grin + ivory teeth, one gold tooth, one missing
    def grin_z(x):
        return 1.99 + 1.3 * x * x + 0.10 * x
    gx = [-0.20, -0.15, -0.10, -0.05, 0.0, 0.05, 0.10, 0.15, 0.20]
    gr = [0.018, 0.03, 0.04, 0.046, 0.05, 0.046, 0.04, 0.03, 0.018]
    P("Mouth", M["mouth"], HEAD_PIV,
      [Tube([(x, hf(grin_z(x), x) - 0.012, grin_z(x)) for x in gx],
            [(r, 0.02) for r in gr], 4, phase=math.pi / 4)], rigid=True)
    teeth, gold_tooth = [], []
    for i, tx in enumerate((-0.12, -0.075, -0.03, 0.015, 0.06, 0.105)):
        if i == 1:
            continue  # missing tooth
        tz = grin_z(tx) + 0.012
        n = surf_n(HEAD_R, tz, tx)
        g = Box((0.036, 0.016, 0.032), (tx, hf(tz, tx) - 0.03, tz),
                rot=(0, 0, math.atan2(n.x, -n.y)))
        (gold_tooth if i == 3 else teeth).append(g)
    P("Teeth", M["teeth"], HEAD_PIV, teeth, rigid=True)
    P("GoldTooth", M["gold"], HEAD_PIV, gold_tooth, rigid=True)

    for side, sx in (("L", 1), ("R", -1)):
        P(f"Ear_{side}", M["skin"], HEAD_PIV,
          [Tube([(0.22 * sx, -0.36, 2.13), (0.335 * sx, -0.34, 2.155)],
                [(0.045, 0.03), (0.088, 0.062)], 6)], rigid=True)

    # ---------------- Oversized tilted peaked cap --------------------------
    cap_piv = Vector((0, -0.34, 2.40))
    cap_post = (Matrix.Translation(cap_piv) @ Euler(CAP_TILT, 'XYZ').to_matrix().to_4x4()
                @ Matrix.Translation(-cap_piv))
    P("CapBand", M["trim"], HEAD_PIV,
      [Tube([(0, -0.34, 2.30), (0, -0.34, 2.42)], [(0.24, 0.22)] * 2, 10, axis=(0, 0, 1)),
       Tube([(0, -0.37, 2.525), (0, -0.37, 2.555)], [(0.36, 0.335)] * 2, 10, axis=(0, 0, 1))],
      post=cap_post, rigid=True)
    P("Cap", M["cap"], HEAD_PIV,
      [Tube([(0, -0.34, 2.415), (0, -0.37, 2.54), (0, -0.38, 2.60)],
            [(0.245, 0.225), (0.35, 0.325), (0.335, 0.305)], 10, axis=(0, 0, 1))],
      post=cap_post, rigid=True)
    P("CapBrim", M["cap"], HEAD_PIV,
      [Tube([(0, -0.48, 2.38), (0, -0.60, 2.36), (0, -0.73, 2.315)],
            [(0.24, 0.02), (0.27, 0.018), (0.19, 0.012)], 6, ref=(0, 0, 1), phase=0.0)],
      post=cap_post, rigid=True)
    P("CapBadge", M["gold"], HEAD_PIV,
      [Tube([(0, -0.595, 2.48), (0, -0.635, 2.475)], [(0.06, 0.072)] * 2, 5,
            ref=(0, 0, 1), phase=math.pi / 2)], post=cap_post, rigid=True)

    # ---------------- Long arms, huge gloved hands --------------------------
    drop = math.radians(ARM_DROP_DEG)
    for side, sx in (("L", 1), ("R", -1)):
        sh = Vector((0.40 * sx, -0.17, 1.69))
        d_up = Vector((math.cos(drop) * sx, -0.12, -math.sin(drop))).normalized()
        el = sh + d_up * 0.46
        d_lo = Vector((math.cos(drop) * sx * 0.85, -0.28, -math.sin(drop))).normalized()
        wr = el + d_lo * 0.48
        P(f"UpperArm_{side}", M["uniform"], sh,
          [Tube([sh - d_up * 0.04, sh + d_up * 0.18, el + d_up * 0.03],
                [0.10, 0.105, 0.08], 8)])
        P(f"LowerArm_{side}", M["uniform"], el,
          [Tube([el - d_lo * 0.02, el + d_lo * 0.20, wr], [0.08, 0.09, 0.068], 8)])
        P(f"Cuff_{side}", M["trim"], el,
          [Tube([wr - d_lo * 0.075, wr - d_lo * 0.005], [0.088, 0.092], 8)], rigid=True)
        f = d_lo
        w = (Vector((0, 1, 0)) - f * f.y).normalized()
        n = (w.cross(f) * sx).normalized()
        hand = [Tube([wr - f * 0.02, wr + f * 0.065], [0.078, 0.098], 8),
                Box((0.10, 0.21, 0.19), frame=frame_matrix(wr + f * 0.15, n, w, f),
                    bevel=0.022)]
        for off, ln in ((-0.07, 0.9), (0.0, 1.1), (0.07, 0.95)):
            b0 = wr + f * 0.235 + w * off
            b1 = b0 + f * (0.075 * ln) + n * 0.015
            b2 = b1 + f * (0.06 * ln) + n * 0.045
            hand.append(Tube([b0, b1, b2], [0.038, 0.035, 0.028], 6))
        t0 = wr + f * 0.09 - w * 0.09
        t1 = t0 + f * 0.05 - w * 0.06 + n * 0.02
        t2 = t1 + f * 0.05 - w * 0.01 + n * 0.035
        hand.append(Tube([t0, t1, t2], [0.042, 0.036, 0.028], 6))
        P(f"Hand_{side}", M["glove"], wr, hand)

    # ---------------- Legs & clunky boots ----------------------------------
    for side, sx in (("L", 1), ("R", -1)):
        lx = 0.125 * sx
        hip = Vector((lx, 0.01, 0.92))
        knee = Vector((0.135 * sx, -0.05, 0.53))
        ankle = Vector((0.14 * sx, 0.0, 0.15))
        P(f"UpperLeg_{side}", M["pants"], hip,
          [Tube([hip + Vector((0, 0, 0.05)), hip.lerp(knee, 0.4), knee - Vector((0, 0, 0.02))],
                [0.11, 0.105, 0.085], 8)])
        P(f"LowerLeg_{side}", M["pants"], knee,
          [Tube([knee + Vector((0, 0, 0.03)), knee.lerp(ankle, 0.35),
                 Vector((ankle.x, -0.01, 0.30)), Vector((ankle.x, 0.0, 0.21))],
                [0.088, 0.085, 0.075, 0.098], 8)])
        P(f"StripeUpper_{side}", M["trim"], hip,
          [Tube([hip + Vector((0.106 * sx, 0, 0.02)), knee + Vector((0.084 * sx, 0, 0))],
                [(0.008, 0.024)] * 2, 4, phase=math.pi / 4)], rigid=True)
        P(f"StripeLower_{side}", M["trim"], knee,
          [Tube([knee + Vector((0.084 * sx, 0, 0)), Vector((ankle.x + 0.094 * sx, 0.0, 0.22))],
                [(0.008, 0.024)] * 2, 4, phase=math.pi / 4)], rigid=True)
        foot = [(0.11, 0.10, 0.075), (0.02, 0.118, 0.10), (-0.12, 0.128, 0.095),
                (-0.24, 0.128, 0.08), (-0.31, 0.09, 0.055)]
        P(f"Boot_{side}", M["boot"], ankle,
          [Tube([(ankle.x, 0.0, 0.08), (ankle.x, 0.0, 0.27)], [0.10, 0.106], 8),
           Tube([(ankle.x, y, 0.03 + 0.924 * rz) for y, rx, rz in foot],
                [(rx, rz) for y, rx, rz in foot], 8, ref=(0, 0, 1))])
        P(f"BootSole_{side}", M["belt"], ankle,
          [Box((0.27, 0.47, 0.035), (ankle.x, -0.095, 0.0175), bevel=0.01)], rigid=True)

    # ---------------- Hierarchy (object parenting; NOT a rig) --------------
    parts = B.parts
    bpy.context.view_layer.update()

    def parent(child, par):
        c, p = parts[child], parts[par]
        c.parent = p
        c.matrix_parent_inverse = p.matrix_world.inverted()

    for n in ("JacketHem", "Belt", "BeltBuckle", "BeltPouch", "BeltRadio", "Baton",
              "Flashlight", "KeyRing", "Torso", "UpperLeg_L", "UpperLeg_R"):
        parent(n, "Pelvis")
    for n in ("Collar", "Tie", "Lapel_L", "Lapel_R", "Buttons", "Badge", "BadgeStar",
              "NamePlate", "Neck", "Epaulette_L", "Epaulette_R", "EpauletteFringe_L",
              "EpauletteFringe_R", "UpperArm_L", "UpperArm_R"):
        parent(n, "Torso")
    parent("Head", "Neck")
    for n in ("BrowRidge", "Eyebrow_L", "Eyebrow_R", "Socket_L", "Socket_R", "Eye_L",
              "Eye_R", "Pupil_L", "Pupil_R", "Nose", "Mouth", "Teeth", "GoldTooth",
              "Ear_L", "Ear_R", "Cap"):
        parent(n, "Head")
    for n in ("CapBand", "CapBrim", "CapBadge"):
        parent(n, "Cap")
    for s in ("L", "R"):
        parent(f"LowerArm_{s}", f"UpperArm_{s}")
        parent(f"Cuff_{s}", f"LowerArm_{s}")
        parent(f"Hand_{s}", f"LowerArm_{s}")
        parent(f"LowerLeg_{s}", f"UpperLeg_{s}")
        parent(f"StripeUpper_{s}", f"UpperLeg_{s}")
        parent(f"StripeLower_{s}", f"LowerLeg_{s}")
        parent(f"Boot_{s}", f"LowerLeg_{s}")
        parent(f"BootSole_{s}", f"Boot_{s}")

    # R15-style bone intent for the future rigging task
    bone = {"Pelvis": "LowerTorso", "Torso": "UpperTorso", "Neck": "Head", "Head": "Head"}
    for s, full in (("L", "Left"), ("R", "Right")):
        bone.update({f"UpperArm_{s}": f"{full}UpperArm", f"LowerArm_{s}": f"{full}LowerArm",
                     f"Hand_{s}": f"{full}Hand", f"UpperLeg_{s}": f"{full}UpperLeg",
                     f"LowerLeg_{s}": f"{full}LowerLeg", f"Boot_{s}": f"{full}Foot"})
    for k, ob in parts.items():
        o = ob
        while o is not None and o.get("warden_part") not in bone:
            o = o.parent
        ob["warden_bone"] = bone[o["warden_part"]] if o is not None else "LowerTorso"
    return parts

# ---------------------------------------------------------------------------
# INSPECTION (lights/camera/floor live outside the export collection)
# ---------------------------------------------------------------------------
def build_inspection(coll, model_coll):
    bpy.context.view_layer.update()
    meshes = [o for o in model_coll.objects if o.type == 'MESH']
    pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center, size = (mn + mx) / 2, mx - mn

    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1080, 1440
    for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            scene.render.engine = eng
            break
        except TypeError:
            continue

    def aim(ob, target):
        ob.rotation_euler = (Vector(target) - ob.location).to_track_quat('-Z', 'Y').to_euler()

    def light(name, energy, offset, color=(1, 1, 1), sz=2.0):
        ld = bpy.data.lights.new(PREFIX + name, 'AREA')
        ld.energy, ld.color, ld.size = energy, color, sz
        ob = bpy.data.objects.new(PREFIX + name, ld)
        ob.location = center + Vector(offset)
        coll.objects.link(ob)
        aim(ob, center)
        return ob

    light("Key", 450, (2.2, -2.6, 1.8))
    light("Fill", 140, (-2.6, -1.8, 0.6), (0.7, 0.8, 1.0))
    light("Rim", 400, (-0.6, 2.6, 1.6), (0.3, 1.0, 0.9))

    # floor (inspection only)
    fm = bpy.data.meshes.new(PREFIX + "InspectFloor_Mesh")
    fm.from_pydata([(-3, -3, 0), (3, -3, 0), (3, 3, 0), (-3, 3, 0)], [], [(0, 1, 2, 3)])
    fm.materials.append(make_material("Inspect_Floor", (0.12, 0.12, 0.13), 0.8))
    floor = bpy.data.objects.new(PREFIX + "InspectFloor", fm)
    coll.objects.link(floor)

    cd = bpy.data.cameras.new(PREFIX + "Camera")
    cd.lens, cd.sensor_fit, cd.sensor_height = 65, 'VERTICAL', 24
    vfov = 2 * math.atan(12 / cd.lens)
    aspect = scene.render.resolution_x / scene.render.resolution_y
    hfov = 2 * math.atan(math.tan(vfov / 2) * aspect)
    dist = max((size.z / 2 * 1.08) / math.tan(vfov / 2),
               (max(size.x, size.y) / 2 * 1.08) / math.tan(hfov / 2)) + size.y / 2
    cam = bpy.data.objects.new(PREFIX + "Camera", cd)
    cam.location = center + Vector((0.55, -1.0, 0.15)).normalized() * dist
    coll.objects.link(cam)
    aim(cam, center)
    scene.camera = cam
    quat = cam.rotation_euler.to_quaternion()

    # deselect so no outlines are saved
    for ob in bpy.context.view_layer.objects:
        try:
            ob.select_set(False)
        except RuntimeError:
            pass
    bpy.context.view_layer.objects.active = None

    # viewport: Material Preview, no camera/light overlays, framed through camera
    for scr in bpy.data.screens:
        for area in scr.areas:
            if area.type != 'VIEW_3D':
                continue
            for sp in area.spaces:
                if sp.type != 'VIEW_3D':
                    continue
                try:
                    sp.shading.type = 'MATERIAL'
                    sp.shading.use_scene_lights = True
                    sp.shading.use_scene_world = False
                except Exception:
                    pass
                for attr in ("show_object_viewport_camera", "show_object_viewport_light"):
                    if hasattr(sp, attr):
                        setattr(sp, attr, False)
                ov = sp.overlay
                for attr in ("show_extras", "show_relationship_lines"):
                    if hasattr(ov, attr):
                        setattr(ov, attr, False)
                r3d = sp.region_3d
                if r3d:
                    r3d.view_location = center
                    r3d.view_rotation = quat
                    r3d.view_distance = dist
                    r3d.view_perspective = 'CAMERA'
    return center, size

# ---------------------------------------------------------------------------
# SAVE (never overwrites)
# ---------------------------------------------------------------------------
def unique_save_path():
    try:
        base_dir = os.path.dirname(os.path.abspath(__file__))
    except NameError:
        base_dir = ""
    if not base_dir or not os.path.isdir(base_dir) or base_dir.endswith(".blend"):
        base_dir = bpy.path.abspath("//") or os.path.expanduser("~")
    path = os.path.join(base_dir, SAVE_BASENAME + ".blend")
    i = 1
    while os.path.exists(path):
        path = os.path.join(base_dir, f"{SAVE_BASENAME}_{i:03d}.blend")
        i += 1
    return path

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
def main():
    reset_warden()
    coll = make_collection(COLL_NAME)
    insp = make_collection(INSPECT_COLL_NAME)
    mats = build_materials()
    parts = build_warden(coll, mats)
    center, size = build_inspection(insp, coll)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
               for o in coll.objects if o.type == 'MESH')
    print(f"[Warden] Built {len(parts)} parts, ~{tris} triangles, "
          f"height {size.z:.2f} m.")
    path = unique_save_path()
    try:
        bpy.ops.wm.save_as_mainfile(filepath=path, copy=True)
        print(f"[Warden] Saved inspection copy: {path}")
    except RuntimeError as e:
        print(f"[Warden] Save failed ({e}); save manually.")


if __name__ == "__main__":
    main()