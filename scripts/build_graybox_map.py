"""Generate the measured museum map and its first architectural art pass."""

from __future__ import annotations

import json
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "places" / "MainMap.model.json"

CREAM = [0.87, 0.84, 0.75]
FLOOR = [0.75, 0.74, 0.68]
TEAL = [0.13, 0.58, 0.58]
TEAL_DARK = [0.08, 0.35, 0.39]
GOLD = [0.94, 0.67, 0.25]
ORANGE = [0.95, 0.39, 0.22]
BLUE = [0.25, 0.66, 0.9]
STONE = [0.35, 0.39, 0.41]
WOOD = [0.37, 0.24, 0.16]
WOOD_LIGHT = [0.56, 0.39, 0.25]
INK = [0.09, 0.14, 0.17]
PAVING = [0.57, 0.59, 0.56]
GRASS = [0.29, 0.43, 0.30]
LEAF = [0.24, 0.43, 0.34]
LIGHT = [1.0, 0.87, 0.64]


def model(name: str, children: list[dict]) -> dict:
    return {"Name": name, "ClassName": "Model", "Children": children}


def frame(x: float, y: float, z: float, yaw: float = 0) -> list[float]:
    c, s = math.cos(yaw), math.sin(yaw)
    return [x, y, z, c, 0, s, 0, 1, 0, -s, 0, c]


def block(
    name: str,
    position: tuple[float, float, float],
    size: tuple[float, float, float],
    color: list[float],
    *,
    yaw: float = 0,
    material: str = "SmoothPlastic",
    collide: bool = True,
    transparency: float = 0,
    attributes: dict[str, str] | None = None,
    tags: list[str] | None = None,
    class_name: str = "Part",
    shape: str | None = None,
) -> dict:
    x, y, z = position
    properties = {
        "Anchored": True,
        "CanCollide": collide,
        "CanTouch": True,
        "CanQuery": True,
        "CFrame": frame(x, y, z, yaw),
        "Size": list(size),
        "Color": color,
        "Material": material,
        "Transparency": transparency,
    }
    if attributes:
        properties["Attributes"] = {key: {"String": value} for key, value in attributes.items()}
    if tags:
        properties["Tags"] = tags
    if class_name == "SpawnLocation":
        properties["Neutral"] = True
        properties["Duration"] = 0
    if shape:
        properties["Shape"] = shape
    return {"Name": name, "ClassName": class_name, "Properties": properties}


def marker(name: str, position: tuple[float, float, float], size: tuple[float, float, float],
           socket_id: str, kind: str) -> dict:
    return block(name, position, size, TEAL, collide=False, transparency=1,
                 attributes={"SocketId": socket_id, "SocketKind": kind},
                 tags=["MapSocket", kind])


def decor(name: str, position: tuple[float, float, float], size: tuple[float, float, float],
          color: list[float], *, yaw: float = 0, material: str = "SmoothPlastic",
          transparency: float = 0, class_name: str = "Part",
          shape: str | None = None) -> dict:
    part = block(name, position, size, color, yaw=yaw, material=material,
                 collide=False, transparency=transparency,
                 class_name=class_name, shape=shape)
    part["Properties"]["CanTouch"] = False
    part["Properties"]["CanQuery"] = False
    return part


def solid_prop(name: str, position: tuple[float, float, float],
               size: tuple[float, float, float], color: list[float],
               *, material: str = "SmoothPlastic", yaw: float = 0,
               shape: str | None = None) -> dict:
    """Physical scenery, used only outside the required walking lanes."""
    part = block(name, position, size, color, material=material,
                 yaw=yaw, shape=shape)
    return part


def surface_sign(name: str, position: tuple[float, float, float],
                 size: tuple[float, float, float], text: str,
                 *, color: list[float] = TEAL_DARK,
                 face: str = "Front", text_color: list[float] = CREAM,
                 font: str = "GothamBold", yaw: float = 0) -> dict:
    sign = decor(name, position, size, color, material="Metal", yaw=yaw)
    sign["Children"] = [{
        "Name": "Lettering", "ClassName": "SurfaceGui",
        "Properties": {"Face": face, "PixelsPerStud": 36,
                       "SizingMode": "PixelsPerStud", "LightInfluence": 0,
                       "AlwaysOnTop": False},
        "Children": [{
            "Name": "Text", "ClassName": "TextLabel",
            "Properties": {"Size": {"UDim2": [[1, 0], [1, 0]]},
                           "BackgroundTransparency": 1, "Text": text,
                           "TextColor3": text_color, "TextScaled": True,
                           "Font": font, "TextStrokeTransparency": 0.8},
        }],
    }]
    return sign


def lamp(name: str, position: tuple[float, float, float], *, brightness: float = 1.2,
         radius: float = 16) -> dict:
    fixture = decor(name, position, (2.4, 0.25, 1.4), LIGHT, material="Neon")
    fixture["Children"] = [{"Name": "WarmLight", "ClassName": "PointLight",
                            "Properties": {"Brightness": brightness, "Range": radius,
                                           "Color": LIGHT, "Shadows": False}}]
    return fixture


def route_segment(name: str, start: tuple[float, float], end: tuple[float, float],
                  color: list[float], route_id: str, index: int,
                  covered: bool = False) -> list[dict]:
    x1, z1 = start
    x2, z2 = end
    dx, dz = x2 - x1, z2 - z1
    length = math.hypot(dx, dz)
    yaw = math.atan2(dx, dz)
    cx, cz = (x1 + x2) / 2, (z1 + z2) / 2
    # The route slabs overlap at bends and where the open and covered paths cross.
    # Give each visual slab a distinct top plane to prevent coplanar flicker.
    top = (0.58 + (index - 1) * 0.02) if covered else (0.72 if index == 1 else 0.66)
    pieces = [block(f"{name}Path", (cx, top - 0.05, cz), (14 if covered else 18, 0.1, length + 1), color,
                    yaw=yaw, collide=False, material="Pavement", attributes={"RouteId": route_id,
                        "SegmentIndex": str(index)}, tags=["RouteSegment"])]
    if covered:
        pieces.append(block(f"{name}Canopy", (cx, 15.5, cz), (18, 1, length - 12),
                            TEAL_DARK, yaw=yaw, material="Metal"))
        normal_x, normal_z = dz / length, -dx / length
        for end_name, fraction in (("A", 0.15), ("B", 0.85)):
            px, pz = x1 + fraction * dx, z1 + fraction * dz
            for side_name, sign in (("L", -1), ("R", 1)):
                pieces.append(block(f"{name}Post{end_name}{side_name}",
                                    (px + sign * normal_x * 10, 7.75, pz + sign * normal_z * 10),
                                    (1, 15.5, 1), TEAL_DARK, material="Metal"))
    return pieces


museum_roof = block("Roof", (65, 19.5, 60), (38, 1, 32), CREAM)
museum_roof["Children"] = [{
    "Name": "InteriorLight",
    "ClassName": "SurfaceLight",
    "Properties": {
        "Face": "Bottom", "Brightness": 0.75, "Range": 28,
        "Angle": 180, "Color": [1, 0.96, 0.82],
    },
}]

museum = model("Museum01", [
    block("Floor", (65, 0.75, 60), (36, 0.5, 30), FLOOR),
    block("WestWall", (46.5, 9.5, 60), (1, 19, 31), CREAM),
    block("EastWall", (83.5, 9.5, 60), (1, 19, 31), CREAM),
    block("NorthWall", (65, 9.5, 75.5), (37, 19, 1), CREAM),
    block("SouthWallLeft", (52.75, 9.5, 44.5), (12.5, 19, 1), CREAM),
    block("SouthWallRight", (77.25, 9.5, 44.5), (12.5, 19, 1), CREAM),
    block("DoorLintel", (65, 17, 44.5), (12, 4, 1), CREAM),
    museum_roof,
    block("EntranceStripe", (65, 1.03, 46), (12, 0.06, 2), ORANGE, collide=False),
    block("ReceivingPad", (65, 1.04, 52), (10, 0.08, 10), TEAL_DARK, collide=False, material="Rubber"),
    marker("ReceivingZone", (65, 3, 52), (10, 4, 10), "museum_01.receiving", "ReceivingZone"),
    marker("RaidEntrance", (65, 7.5, 45), (12, 14, 2), "museum_01.raid_entrance", "RaidEntrance"),
    block("ProtectedBase", (75, 1.25, 70.5), (8, 0.5, 8), STONE),
    block("ProtectedPlinth", (75, 2.6, 70.5), (4.8, 2.2, 4.8), CREAM),
    marker("ProtectedDisplaySocket", (75, 4.5, 70.5), (8, 3, 8),
           "museum_01.protected", "DisplaySocket"),
    block("RecoveryConsoleBase", (53, 2.5, 67), (3, 3, 2), TEAL_DARK, material="Metal"),
    block("RecoveryConsoleTop", (53, 4.1, 67), (3.5, 0.3, 2.5), WOOD, material="Wood"),
    marker("RecoveryConsoleSocket", (53, 3, 67), (6, 5, 5),
           "museum_01.recovery_console", "RecoveryConsole"),
    block("PlayerSpawn", (65, 1.08, 68), (6, 0.15, 6), FLOOR,
          collide=False, transparency=1, class_name="SpawnLocation"),
    block("SideDisplayWest", (51, 1.25, 59), (3.8, 0.5, 3.8), STONE),
    block("SideDisplayEast", (79, 1.25, 59), (3.8, 0.5, 3.8), STONE),
    block("DoorMarkerLeft", (58.75, 7.5, 43.7), (0.5, 14, 0.5), ORANGE, collide=False),
    block("DoorMarkerRight", (71.25, 7.5, 43.7), (0.5, 14, 0.5), ORANGE, collide=False),
])

depot = model("Depot", [
    block("DepotPad", (-92, 0.6, -72), (26, 0.2, 22), PAVING, material="Pavement"),
    block("PedestalBase", (-92, 1.3, -72), (12, 1.2, 12), STONE, material="Concrete"),
    block("PedestalTop", (-92, 2.05, -72), (12, 0.3, 12), WOOD_LIGHT, material="WoodPlanks"),
    marker("TutorialPedestalSocket", (-92, 4, -72), (12, 3, 12),
           "depot.tutorial_pedestal", "TutorialPedestal"),
    block("DepotBeacon", (-92, 5.5, -83), (2, 10, 2), GOLD),
    block("DepotBeaconCap", (-92, 11, -83), (7, 1, 7), GOLD),
])

open_route = model("OpenRoute", [])
open_points = [(-92, -72), (65, 43), (65, 52)]
for i in range(len(open_points) - 1):
    open_route["Children"].extend(route_segment(f"Open{i + 1:02d}", open_points[i],
                                                 open_points[i + 1], PAVING, "open", i + 1))

covered_route = model("CoveredRoute", [])
covered_points = [(-92, -72), (-99, 52), (-20, 52), (65, 25), (65, 52)]
for i in range(len(covered_points) - 1):
    covered_route["Children"].extend(route_segment(
        f"Covered{i + 1:02d}", covered_points[i], covered_points[i + 1],
        PAVING, "covered", i + 1, covered=i in {0, 1}))

# Solid walls on the plaza-facing edge of the detour break sightlines. Leave
# at least ten studs open at every bend; canopy posts sit outside the clear path.
for i, (start, end) in enumerate(zip(covered_points, covered_points[1:]), 1):
    if i == 4:
        break
    dx, dz = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dz)
    nx, nz = dz / length, -dx / length
    fraction = 0.5
    wall_length = length - 30
    cx = start[0] + fraction * dx + 9 * nx
    cz = start[1] + fraction * dz + 9 * nz
    covered_route["Children"].append(block(
        f"CoverWall{i:02d}", (cx, 7.5, cz), (2, 14, wall_length),
        STONE, yaw=math.atan2(dx, dz), material="Concrete",
        attributes={"RouteId": "covered"}, tags=["SightlineCover"]))
for i, point in enumerate(covered_points[1:-1], 1):
    covered_route["Children"].append(block(
        f"WideCorner{i:02d}", (point[0], 0.62 + (i - 1) * 0.02, point[1]), (18, 0.08, 18),
        PAVING, collide=False, material="Pavement"))

map_model = {
    "ClassName": "Model",
    "Children": [
        block("Ground", (0, 0, 0), (220, 1, 180), GRASS),
        decor("ScenicGround", (0, 0.3, 0), (440, 0.2, 360),
              GRASS),
        museum, depot, open_route, covered_route,
        marker("OpenRouteStart", (-92, 2, -58), (10, 3, 4),
               "route.open.start", "RouteMarker"),
        marker("CoveredRouteStart", (-99, 2, -54), (10, 3, 4),
               "route.covered.start", "RouteMarker"),
        marker("MuseumApproach", (65, 2, 39), (12, 3, 4),
               "museum_01.approach", "RouteMarker"),
    ],
}

# The visual groups are separate from gameplay sockets. Small trim stays
# non-colliding; outdoor props use solid_prop only outside route clearance.
facade = model("MuseumFacadeArt", [])
f = facade["Children"]
for name, pos, size, color, material in [
    ("FrontCornice", (65, 19.2, 43.2), (40, 1.1, 2.4), CREAM, "Limestone"),
    ("LowerCornice", (65, 15.3, 43.65), (37, 0.45, 1.2), TEAL_DARK, "Metal"),
    ("LeftPilaster", (57.8, 8, 43.6), (1.4, 14, 1.3), CREAM, "Limestone"),
    ("RightPilaster", (72.2, 8, 43.6), (1.4, 14, 1.3), CREAM, "Limestone"),
    ("LeftColumnFoot", (57.8, 1.3, 43.4), (2.3, 0.7, 2.2), STONE, "SmoothPlastic"),
    ("RightColumnFoot", (72.2, 1.3, 43.4), (2.3, 0.7, 2.2), STONE, "SmoothPlastic"),
    ("FrontLeftLower", (52.8, 3.5, 43.92), (11.5, 5.2, 0.18), WOOD, "WoodPlanks"),
    ("FrontRightLower", (77.2, 3.5, 43.92), (11.5, 5.2, 0.18), WOOD, "WoodPlanks"),
    ("LeftDoorJamb", (58.25, 8, 43.2), (1.2, 14, 1.1), STONE, "SmoothPlastic"),
    ("RightDoorJamb", (71.75, 8, 43.2), (1.2, 14, 1.1), STONE, "SmoothPlastic"),
    ("DoorHeader", (65, 15.35, 43.2), (15, 0.9, 1.2), STONE, "SmoothPlastic"),
    ("WestRoofEdge", (46.3, 19.2, 60), (1.4, 1.1, 34), CREAM, "Limestone"),
    ("EastRoofEdge", (83.7, 19.2, 60), (1.4, 1.1, 34), CREAM, "Limestone"),
    ("RearRoofEdge", (65, 19.2, 76.2), (40, 1.1, 1.4), CREAM, "Limestone"),
]:
    f.append(decor(name, pos, size, color, material=material))
for x, side in ((43, "Left"), (87, "Right")):
    f.append(decor(f"{side}WallPanel", (x, 10.3, 43.85), (7.5, 7.3, 0.15),
                   FLOOR, material="Limestone"))
    f.append(decor(f"{side}WallPanelFrame", (x, 14, 43.72), (8.5, 0.35, 0.3),
                   TEAL_DARK, material="Metal"))
    f.append(solid_prop(f"{side}Planter", (x, 1.1, 42),
                        (5, 1.2, 3), STONE, material="Concrete"))
    for offset in (-1.3, 0, 1.3):
        f.append(solid_prop(f"{side}PlanterLeaf{offset}",
                            (x + offset, 2.1, 42),
                            (1.2, 1.5, 1.2), LEAF))
for side, x, direction in (("West", 45.9, -1), ("East", 84.1, 1)):
    f.append(decor(f"{side}ExteriorDado", (x, 3.1, 60),
                   (0.16, 4.8, 29), WOOD, material="WoodPlanks"))
    f.append(decor(f"{side}ExteriorRail", (x + direction * 0.12, 5.65, 60),
                   (0.32, 0.38, 29), TEAL_DARK, material="Metal"))
    f.append(surface_sign(f"{side}SidePlaque",
                          (x + direction * 0.17, 12, 60),
                          (0.18, 2.2, 7), "MUSEUM 01",
                          face="Left" if side == "West" else "Right",
                          color=TEAL_DARK, text_color=LIGHT))
    for z in (54, 67):
        f.append(decor(f"{side}WallPier{z}", (x, 9.5, z),
                       (0.8, 18, 1.1), CREAM, material="Limestone"))
        wall_lamp = decor(f"{side}WallLantern{z}",
                          (x + direction * 0.5, 11.5, z + 2.2),
                          (0.5, 1.7, 0.8), STONE, material="Metal")
        wall_lamp["Children"] = [{
            "Name": "Glow", "ClassName": "PointLight",
            "Properties": {"Brightness": 0.7, "Range": 12,
                           "Color": LIGHT, "Shadows": False},
        }]
        f.append(wall_lamp)
    for z in (59, 72):
        f.append(decor(f"{side}ClimbingStem{z}",
                       (x + direction * 0.18, 4.8, z),
                       (0.18, 7.6, 0.18), WOOD))
        for rise, offset in ((2.5, -0.5), (3.8, 0.5),
                             (5.1, -0.3), (6.4, 0.35),
                             (7.6, -0.15)):
            f.append(decor(f"{side}ClimbingLeaf{z}_{rise}",
                           (x + direction * 0.4, rise, z + offset),
                           (0.9, 1.6, 1.8), LEAF, shape="Ball"))
f.append(surface_sign("MuseumNameSign", (65, 17.35, 43.5), (18, 2.35, 0.35),
                      "THE MUSEUM  •  01", color=TEAL_DARK, text_color=CREAM))
f.append(decor("EntryThreshold", (65, 1.04, 44), (12, 0.06, 2),
               GOLD, material="Metal"))

interior = model("MuseumInteriorArt", [])
inside = interior["Children"]
for x in (50, 56, 62, 68, 74, 80):
    for z in (48, 54, 60, 66, 72):
        tint = [0.80, 0.78, 0.73] if ((x + z) // 6) % 2 == 0 else [0.78, 0.76, 0.71]
        inside.append(decor(f"Tile_{x}_{z}", (x, 1.016, z), (5.85, 0.025, 5.85),
                            tint))
for name, pos, size in [
    ("WestDado", (47.12, 3, 60), (0.16, 4, 29)),
    ("EastDado", (82.88, 3, 60), (0.16, 4, 29)),
    ("RearDado", (65, 3, 74.9), (35, 4, 0.16)),
    ("WestChairRail", (47.2, 5.2, 60), (0.32, 0.35, 29)),
    ("EastChairRail", (82.8, 5.2, 60), (0.32, 0.35, 29)),
    ("RearChairRail", (65, 5.2, 74.8), (35, 0.35, 0.32)),
]:
    inside.append(decor(name, pos, size, WOOD if "Dado" in name else GOLD,
                        material="WoodPlanks" if "Dado" in name else "Metal"))
for x in (53, 65, 77):
    inside.append(decor(f"CeilingBeam{x}", (x, 18.35, 60), (0.8, 0.8, 29),
                        WOOD, material="WoodPlanks"))
for x, z in ((55, 53), (75, 53), (55, 67), (75, 67)):
    inside.append(decor(f"LightHousing{x}_{z}", (x, 18.25, z), (3, 0.4, 2),
                        STONE, material="Metal"))
    inside.append(lamp(f"CeilingLamp{x}_{z}", (x, 17.95, z), radius=17))
for label, x in (("WEST COLLECTION", 47.25), ("EAST COLLECTION", 82.75)):
    for z in (53, 66):
        face = "Right" if x < 65 else "Left"
        inside.append(surface_sign(f"Poster{label}{z}", (x, 10, z),
                                   (0.2, 5.5, 4.8), label,
                                   color=WOOD, face=face, text_color=LIGHT))
        inside.append(decor(f"PosterRail{label}{z}", (x, 13, z),
                            (0.3, 0.3, 5.2), GOLD, material="Metal"))
inside.append(surface_sign("DeliveryHangingSign", (65, 12.8, 47.2),
                           (7.5, 1.8, 0.3), "DROP-OFF  ↓",
                           color=TEAL_DARK, text_color=LIGHT))
for side in (-1, 1):
    inside.append(decor(f"MatSideBorder{side}", (65 + side * 5, 1.09, 52),
                        (0.3, 0.06, 10.3), GOLD, material="Metal"))
    inside.append(decor(f"MatEndBorder{side}", (65, 1.09, 52 + side * 5),
                        (10.3, 0.06, 0.3), GOLD, material="Metal"))
for z in (49.5, 52.5):
    inside.append(decor(f"MatArrowShaft{z}", (65, 1.095, z),
                        (0.5, 0.04, 2.1), CREAM))
    inside.append(decor(f"MatArrowLeft{z}", (64.4, 1.095, z + 0.7),
                        (0.3, 0.04, 1.3), CREAM, yaw=-0.7))
    inside.append(decor(f"MatArrowRight{z}", (65.6, 1.095, z + 0.7),
                        (0.3, 0.04, 1.3), CREAM, yaw=0.7))
for side, x in (("West", 51), ("East", 79)):
    inside.append(decor(f"{side}DisplayFoot", (x, 1.1, 59),
                        (4.25, 0.18, 4.25), WOOD, material="WoodPlanks"))
    inside.append(solid_prop(f"{side}DisplayPedestal", (x, 2.35, 59),
                             (2.8, 1.8, 2.8), CREAM))
    inside.append(decor(f"{side}DisplaySurface", (x, 3.45, 59),
                        (3.5, 0.3, 3.5), WOOD_LIGHT, material="WoodPlanks"))
    for dx in (-1.55, 1.55):
        for dz in (-1.55, 1.55):
            inside.append(decor(f"{side}CasePost{dx}_{dz}",
                                (x + dx, 4.7, 59 + dz),
                                (0.12, 2.1, 0.12), STONE, material="Metal"))
    inside.append(decor(f"{side}CaseTop", (x, 5.82, 59),
                        (3.65, 0.13, 3.65), STONE, material="Metal"))
    inside.append(decor(f"{side}GlassFront", (x, 4.7, 57.4),
                        (3.15, 2.05, 0.08), BLUE, transparency=0.85,
                        material="Glass"))
    inside.append(decor(f"{side}ExhibitForm", (x, 4.35, 59),
                        (1.25, 1.45, 1.25), TEAL_DARK, shape="Ball"))
    inside.append(surface_sign(f"{side}Nameplate", (x, 2.6, 57.5),
                               (2.5, 0.58, 0.15), "EXHIBIT",
                               color=INK, text_color=LIGHT))
inside.append(decor("ProtectedDisplaySurface", (75, 3.83, 70.5),
                    (5.5, 0.24, 5.5), WOOD_LIGHT, material="WoodPlanks"))
for side in (-1, 1):
    inside.append(decor(f"ProtectedFootSide{side}",
                        (75 + side * 3.9, 1.08, 70.5),
                        (0.16, 0.15, 8.05), GOLD, material="Metal"))
    inside.append(decor(f"ProtectedFootEnd{side}",
                        (75, 1.08, 70.5 + side * 3.9),
                        (8.05, 0.15, 0.16), GOLD, material="Metal"))
    inside.append(decor(f"ProtectedTopSide{side}",
                        (75 + side * 2.65, 3.95, 70.5),
                        (0.16, 0.15, 5.5), GOLD, material="Metal"))
    inside.append(decor(f"ProtectedTopEnd{side}",
                        (75, 3.95, 70.5 + side * 2.65),
                        (5.5, 0.15, 0.16), GOLD, material="Metal"))
inside.append(surface_sign("ProtectedNameplate", (75, 2.7, 68),
                           (4, 0.7, 0.15), "PROTECTED",
                           color=INK, text_color=GOLD))
inside.append(surface_sign("ShieldEmblem", (75, 8.5, 74.65),
                           (3.2, 3.2, 0.2), "◆  SHIELD",
                           color=TEAL_DARK, text_color=GOLD))
spot = decor("ProtectedSpotlight", (75, 18, 70.5), (2, 0.7, 2),
             STONE, material="Metal")
spot["Children"] = [{"Name": "SpotLight", "ClassName": "SpotLight",
                     "Properties": {"Face": "Bottom", "Angle": 60,
                                    "Brightness": 2.2, "Range": 18,
                                    "Color": LIGHT, "Shadows": False}}]
inside.append(spot)
inside.append(surface_sign("RecoveryScreen", (54.65, 3.3, 67),
                           (0.16, 2.1, 1.8), "↺  RECOVER",
                           face="Right", color=INK, text_color=TEAL))
inside.append(decor("RecoveryAngledControls", (54.2, 4.4, 67),
                    (1.8, 0.6, 2.2), STONE, class_name="WedgePart", material="Metal"))
for z in (66.4, 67, 67.6):
    inside.append(decor(f"RecoveryButton{z}", (54.4, 4.65, z),
                        (0.3, 0.1, 0.3), GOLD, material="Neon"))
museum["Children"].extend((facade, interior))

route_art = model("RouteArt", [])
ra = route_art["Children"]
for index, (start, end) in enumerate(zip(open_points, open_points[1:]), 1):
    dx, dz = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dz)
    yaw = math.atan2(dx, dz)
    nx, nz = dz / length, -dx / length
    cx, cz = (start[0] + end[0]) / 2, (start[1] + end[1]) / 2
    if index == 1:
        # Stop the route edging before the museum approach plaza. A full-length
        # strip crossed the plaza and appeared as a flickering white floor line.
        edge_end_clearance = 34
        for side in (-1, 1):
            ra.append(decor(f"OpenEdge{index}{side}",
                            (cx - dx / length * edge_end_clearance / 2 + side * nx * 9.2,
                             0.77,
                             cz - dz / length * edge_end_clearance / 2 + side * nz * 9.2),
                            (0.36, 0.09, length - 2 - edge_end_clearance), CREAM,
                            yaw=yaw, material="Limestone"))
    if index == 1:
        for step in range(1, 11):
            fraction = step / 11
            px, pz = start[0] + fraction * dx, start[1] + fraction * dz
            if px >= 45:
                continue
            ra.append(decor(f"PavingJoint{step:02d}", (px, 0.75, pz),
                            (17.7, 0.018, 0.15), STONE, yaw=yaw))
        for step, fraction in enumerate((0.18, 0.48, 0.78), 1):
            px, pz = start[0] + fraction * dx, start[1] + fraction * dz
            ra.append(decor(f"OpenArrowStem{step}", (px, 0.76, pz),
                            (0.7, 0.025, 3.3), CREAM, yaw=yaw))
            for side in (-1, 1):
                ra.append(decor(f"OpenArrowWing{step}{side}",
                                (px + side * nx * 1.15 + dx / length * 1.1,
                                0.76, pz + side * nz * 1.15 + dz / length * 1.1),
                                (0.5, 0.025, 2.3), CREAM, yaw=yaw + side * 0.7))

for index, (start, end) in enumerate(zip(covered_points, covered_points[1:]), 1):
    if index == 4:
        continue
    dx, dz = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dz)
    yaw = math.atan2(dx, dz)
    nx, nz = dz / length, -dx / length
    cx, cz = (start[0] + end[0]) / 2, (start[1] + end[1]) / 2
    wall_length = length - 30
    wall_x, wall_z = cx + nx * 9, cz + nz * 9
    # Lower brick and continuous metal coping are visual layers on the
    # existing collidable concrete cover wall.
    ra.append(decor(f"ServiceBrickLower{index}",
                    (wall_x - nx * 1.08, 2.9, wall_z - nz * 1.08),
                    (0.15, 4.8, wall_length - 1), WOOD_LIGHT,
                    yaw=yaw, material="Brick"))
    ra.append(decor(f"ServiceWallCap{index}", (wall_x, 14.6, wall_z),
                    (2.35, 0.3, wall_length), TEAL_DARK,
                    yaw=yaw, material="Metal"))
    ra.append(decor(f"ServicePipe{index}",
                    (wall_x - nx * 1.2, 9.2, wall_z - nz * 1.2),
                    (0.25, 0.25, wall_length - 4), STONE,
                    yaw=yaw, material="Metal"))
    for fraction in (0.33, 0.67):
        px = start[0] + fraction * dx + nx * 10.4
        pz = start[1] + fraction * dz + nz * 10.4
        ra.append(decor(f"ServiceWallPier{index}_{fraction}",
                        (px, 7.5, pz), (0.75, 14, 0.75),
                        FLOOR, yaw=yaw, material="Concrete"))
    ra.append(surface_sign(f"ServiceWallSign{index}",
                           (wall_x - nx * 1.18, 10.8, wall_z - nz * 1.18),
                           (0.16, 1.5, 7.5), "SERVICE ROUTE",
                           face="Left", yaw=yaw,
                           color=TEAL_DARK, text_color=LIGHT))
    for fraction in (0.25, 0.75):
        px = start[0] + fraction * dx + nx * 1.2
        pz = start[1] + fraction * dz + nz * 1.2
        ra.append(decor(f"ServiceVineStem{index}_{fraction}",
                        (px, 7.4, pz), (0.18, 11, 0.18),
                        WOOD, yaw=yaw))
        for rise in (4.5, 7.5, 10.5):
            ra.append(decor(f"ServiceVineLeaf{index}_{fraction}_{rise}",
                            (px + nx * 0.24, rise, pz + nz * 0.24),
                            (1.2, 0.8, 1.2), LEAF, shape="Ball"))
    if index < 3:
        for fraction in (0.3, 0.7):
            px, pz = start[0] + fraction * dx, start[1] + fraction * dz
            ra.append(decor(f"AwningRib{index}_{fraction}", (px, 15.05, pz),
                            (18.4, 0.4, 0.4), STONE, yaw=yaw, material="Metal"))
            ra.append(lamp(f"ServiceLamp{index}_{fraction}",
                           (px - nx * 0.2, 14.82, pz - nz * 0.2),
                           brightness=0.9, radius=14))
    for fraction in (0.38, 0.62):
        px, pz = start[0] + fraction * dx, start[1] + fraction * dz
        ra.append(decor(f"ServiceFloorJoint{index}_{fraction}",
                        (px, 0.786, pz), (13.6, 0.018, 0.14),
                        STONE, yaw=yaw))
map_model["Children"].append(route_art)

depot_art = model("DepotArt", [])
da = depot_art["Children"]
da.extend([
    solid_prop("LoadingAwning", (-92, 12.5, -72), (25, 0.7, 18),
               TEAL_DARK, material="Metal"),
    solid_prop("AwningFascia", (-92, 11.8, -63), (25, 1.2, 0.5),
               WOOD, material="WoodPlanks"),
    surface_sign("LoadingSign", (-92, 10.9, -62.6), (15, 1.7, 0.3),
                 "DEPOT  •  PICKUP", face="Back",
                 color=TEAL_DARK, text_color=LIGHT),
    solid_prop("StockDisplayShelf", (-105, 3.2, -73), (3, 0.4, 6),
               WOOD, material="WoodPlanks"),
    solid_prop("DepotBenchSeat", (-105, 1.8, -73), (3, 0.5, 6),
               WOOD, material="WoodPlanks"),
    solid_prop("DepotBenchLegA", (-105, 1.05, -75), (2.5, 1.5, 0.5),
               WOOD, material="WoodPlanks"),
    solid_prop("DepotBenchLegB", (-105, 1.05, -71), (2.5, 1.5, 0.5),
               WOOD, material="WoodPlanks"),
    decor("PickupFaceTrim", (-92, 2.05, -78.1), (12, 0.3, 0.3),
          GOLD, material="Metal"),
])
for x in (-103, -81):
    for z in (-80, -64):
        da.append(solid_prop(f"LoadingPost{x}_{z}", (x, 6.25, z),
                             (0.8, 12.5, 0.8), STONE,
                             material="Metal"))
for index, x in enumerate((-104, -81), 1):
    da.append(solid_prop(f"LoadingCrate{index}", (x, 1.8, -86),
                         (3, 2.6, 3), WOOD_LIGHT,
                         material="WoodPlanks"))
    da.append(decor(f"CrateBand{index}", (x, 2.5, -86),
                    (3.1, 0.25, 3.1), STONE, material="Metal"))
for index, x in enumerate(range(-99, -84, 3), 1):
    da.append(decor(f"LoadingWarning{index}", (x, 0.73, -61.2),
                    (1.3, 0.03, 0.5), GOLD, material="Neon"))
da.append(lamp("DepotLamp", (-92, 11.9, -72), brightness=1.3, radius=19))
depot["Children"].append(depot_art)

landscape = model("LandscapeArt", [])
land = landscape["Children"]
tree_specs = [
    (-62, -78, 5.4, -0.25, 6.2, [0.22, 0.40, 0.31]),
    (-50, -79, 6.6, 0.32, 7.0, [0.27, 0.46, 0.34]),
    (-38, -77, 4.7, -0.42, 5.6, [0.19, 0.37, 0.29]),
    (-75, 75, 5.2, 0.18, 6.7, [0.25, 0.44, 0.33]),
    (-63, 80, 6.3, -0.38, 7.3, [0.20, 0.39, 0.31]),
    (96, 15, 6.0, 0.4, 6.5, [0.25, 0.43, 0.32]),
    (101, 34, 4.5, -0.18, 5.5, [0.18, 0.36, 0.29]),
    (95, 54, 6.8, 0.25, 7.1, [0.28, 0.45, 0.34]),
]
for index, (x, z, height, yaw, width, leaf_color) in enumerate(tree_specs, 1):
    land.append(solid_prop(f"TreeTrunk{index}",
                           (x, 0.5 + height / 2, z),
                           (1.45, height, 1.45), WOOD,
                           material="Wood", yaw=yaw))
    land.append(solid_prop(f"TreeCrownLower{index}",
                           (x, 0.5 + height + 1.2, z),
                           (width, 4.4, width * 0.88), leaf_color,
                           shape="Ball"))
    land.append(solid_prop(f"TreeCrownUpper{index}",
                           (x + 0.35, 0.5 + height + 3.5, z - 0.35),
                           (width * 0.72, 3.5, width * 0.69),
                           leaf_color, shape="Ball"))
    offset = -1 if index % 2 else 1
    land.append(solid_prop(f"TreeCrownSide{index}",
                           (x + offset * width * 0.37,
                            0.5 + height + 1.2, z + width * 0.15),
                           (width * 0.58, 3.4, width * 0.55),
                           leaf_color, shape="Ball"))
for index, (x, z, sx, sz) in enumerate(((-44, -62, 8, 4),
                                       (12, 68, 10, 4),
                                       (96, -12, 7, 5)), 1):
    land.append(solid_prop(f"PlantingBed{index}", (x, 0.68, z),
                           (sx, 0.35, sz), WOOD,
                           material="WoodPlanks"))
    for offset in (-0.25, 0, 0.25):
        land.append(solid_prop(f"PlantingLeaf{index}_{offset}",
                               (x + offset * sx, 1.6, z),
                               (1.6, 1.8, 1.6), LEAF,
                               material="SmoothPlastic"))
for index, (x, z, sx, sy, sz) in enumerate(((-145, 112, 10, 15, 14),
                                            (-92, 129, 14, 20, 10),
                                            (15, 126, 13, 16, 10),
                                            (139, 106, 16, 19, 12),
                                            (145, -105, 14, 15, 10)), 1):
    land.append(decor(f"BackdropBuilding{index}",
                      (x, sy / 2, z), (sx, sy, sz),
                      [0.30, 0.38, 0.39], material="Concrete"))
    land.append(decor(f"BackdropRoof{index}",
                      (x, sy + 0.3, z), (sx + 1, 0.6, sz + 1),
                      TEAL_DARK, material="Metal"))
map_model["Children"].append(landscape)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text(json.dumps(map_model, indent=2) + "\n", encoding="utf-8")
print(f"Wrote {OUTPUT.relative_to(ROOT)}")
