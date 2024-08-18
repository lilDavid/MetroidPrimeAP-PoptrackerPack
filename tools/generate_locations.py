#/usr/bin/env python3

from argparse import ArgumentParser
import ast
from enum import StrEnum
import json
from pathlib import Path
import importlib
import importlib.util
import sys
from typing import Dict, List, NamedTuple, Optional, Tuple, Union


locations = Path(__file__).parents[1] / "locations"


class ItemImage(StrEnum):
    EnergyTank = "energytank"
    MissileLauncher = "missilelauncher"
    MissileExpansion = "missilelauncher"
    WaveBeam = "wavebeam"
    IceBeam = "icebeam"
    PlasmaBeam = "plasmabeam"
    ChargeBeam = "chargebeam"
    SuperMissile = "supermissile"
    Wavebuster = "wavebuster"
    IceSpreader = "icespreader"
    Flamethrower = "flamethrower"
    GrappleBeam = "grapplebeam"
    MorphBall = "morphball"
    BoostBall = "boostball"
    SpiderBall = "spiderball"
    Bombs = "bombs"
    PowerBomb = "powerbomb"
    PowerBombExpansion = "powerbomb"
    ThermalVisor = "thermalvisor"
    XRayVisor = "xrayvisor"
    SpaceJump = "spacejumpboots"
    VariaSuit = "variasuit"
    GravitySuit = "gravitysuit"
    PhazonSuit = "phazonsuit"
    ArtifactTruth = "artifacts0"
    ArtifactStrength = "artifacts0"
    ArtifactElder = "artifacts0"
    ArtifactWild = "artifacts0"
    ArtifactLifegiver = "artifacts0"
    ArtifactWarrior = "artifacts0"
    ArtifactChozo = "artifacts0"
    ArtifactNature = "artifacts0"
    ArtifactSun = "artifacts0"
    ArtifactWorld = "artifacts0"
    ArtifactSpirit = "artifacts0"
    ArtifactNewborn = "artifacts0"

    def filename(self):
        return f"images/items/{self.value}.png"


item_images = {
    'Chozo Ruins: Main Plaza - Locked Door': ItemImage.EnergyTank,
    'Chozo Ruins: Ruined Shrine - Plated Beetle': ItemImage.MorphBall,
    'Chozo Ruins: Training Chamber': ItemImage.EnergyTank,
    'Chozo Ruins: Magma Pool': ItemImage.PowerBombExpansion,
    'Chozo Ruins: Tower of Light': ItemImage.Wavebuster,
    'Chozo Ruins: Tower Chamber': ItemImage.ArtifactLifegiver,
    'Chozo Ruins: Transport Access North': ItemImage.EnergyTank,
    'Chozo Ruins: Hive Totem': ItemImage.MissileLauncher,
    'Chozo Ruins: Sunchamber - Flaaghra': ItemImage.VariaSuit,
    'Chozo Ruins: Sunchamber - Ghosts': ItemImage.ArtifactWild,
    'Chozo Ruins: Burn Dome - Incinerator Drone': ItemImage.Bombs,
    'Chozo Ruins: Furnace - Inside Furnace': ItemImage.EnergyTank,
    'Chozo Ruins: Hall of the Elders': ItemImage.EnergyTank,
    'Chozo Ruins: Elder Chamber': ItemImage.ArtifactWorld,
    'Chozo Ruins: Antechamber': ItemImage.IceBeam,
    'Phendrana Drifts: Chozo Ice Temple': ItemImage.ArtifactSun,
    'Phendrana Drifts: Ice Ruins West': ItemImage.PowerBombExpansion,
    'Phendrana Drifts: Chapel of the Elders': ItemImage.WaveBeam,
    'Phendrana Drifts: Ruined Courtyard': ItemImage.EnergyTank,
    'Phendrana Drifts: Phendrana Canyon': ItemImage.BoostBall,
    'Phendrana Drifts: Quarantine Cave': ItemImage.SpiderBall,
    'Phendrana Drifts: Observatory': ItemImage.SuperMissile,
    'Phendrana Drifts: Transport Access': ItemImage.EnergyTank,
    'Phendrana Drifts: Control Tower': ItemImage.ArtifactElder,
    'Phendrana Drifts: Research Core': ItemImage.ThermalVisor,
    'Phendrana Drifts: Research Lab Aether - Tank': ItemImage.EnergyTank,
    'Phendrana Drifts: Gravity Chamber - Underwater': ItemImage.GravitySuit,
    'Phendrana Drifts: Storage Cave': ItemImage.ArtifactSpirit,
    'Phendrana Drifts: Security Cave': ItemImage.PowerBombExpansion,
    'Tallon Overworld: Alcove': ItemImage.SpaceJump,
    'Tallon Overworld: Artifact Temple': ItemImage.ArtifactTruth,
    'Tallon Overworld: Cargo Freight Lift to Deck Gamma': ItemImage.EnergyTank,
    'Tallon Overworld: Hydro Access Tunnel':  ItemImage.EnergyTank,
    'Tallon Overworld: Life Grove - Start': ItemImage.XRayVisor,
    'Tallon Overworld: Life Grove - Underwater Spinner': ItemImage.ArtifactChozo,
    'Phazon Mines: Storage Depot B': ItemImage.GrappleBeam,
    'Phazon Mines: Storage Depot A': ItemImage.Flamethrower,
    'Phazon Mines: Elite Research - Phazon Elite': ItemImage.ArtifactWarrior,
    'Phazon Mines: Ventilation Shaft': ItemImage.EnergyTank,
    'Phazon Mines: Processing Center Access': ItemImage.EnergyTank,
    'Phazon Mines: Elite Quarters': ItemImage.PhazonSuit,
    'Phazon Mines: Central Dynamo': ItemImage.PowerBomb,
    'Phazon Mines: Phazon Mining Tunnel': ItemImage.ArtifactNewborn,
    'Magmoor Caverns: Lava Lake': ItemImage.ArtifactNature,
    'Magmoor Caverns: Transport Tunnel A': ItemImage.EnergyTank,
    'Magmoor Caverns: Warrior Shrine': ItemImage.ArtifactStrength,
    'Magmoor Caverns: Shore Tunnel': ItemImage.IceSpreader,
    'Magmoor Caverns: Fiery Shores - Warrior Shrine Tunnel': ItemImage.PowerBombExpansion,
    'Magmoor Caverns: Plasma Processing': ItemImage.PlasmaBeam,
    'Magmoor Caverns: Magmoor Workstation': ItemImage.EnergyTank,
}


# Get args
parser = ArgumentParser(
    description="Converts the logic rules from MetrodAPrime for use in this tracker."
)
parser.add_argument(
    "path_to_apworld", type=Path,
    help="Path to the extracted Metroid Prime AP world source"
)
parser.add_argument(
    "area", type=str,
    help="Name of the data module to read"
)
parser.add_argument(
    "output", type=Path,
    help="Filename to write results into"
)
args = parser.parse_args()

data_path: Path = args.path_to_apworld / "data"
area: str = args.area
output: Path = locations / args.output.name


# Import names
def import_file(path: Path):
    name = f"metroidprime.{path.stem}"
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)


import_file(data_path / "AreaNames.py")
import_file(data_path / "RoomNames.py")

from metroidprime.AreaNames import MetroidPrimeArea
from metroidprime.RoomNames import RoomName


# Parse file
JsonValue = Union[str, int, float, List["JsonValue"], Dict[str, "JsonValue"], None]


def omit_empty_lists_and_null(object: Dict[str, JsonValue]) -> Dict[str, JsonValue]:
    return {k: v for k, v in object.items() if v not in (None, [])}


class ASTParseError(ValueError):
    tree: ast.AST

    def __init__(self, tree: ast.AST, *args):
        super().__init__(*args)
        self.tree = tree


class PickupData(NamedTuple):
    name: str
    image: Optional[ItemImage]

    @classmethod
    def from_ast(cls, pickup_data: ast.expr):
        if (type(pickup_data) is not ast.Call or type(pickup_data.func) is not ast.Name or
            pickup_data.func.id != "PickupData"):
            raise ASTParseError(pickup_data, "Pickup item is not from PickupData constructor")
        check_name: str = ast.literal_eval(pickup_data.args[0])

        _, without_area = check_name.split(": ")
        parts = without_area.split(" - ")
        if len(parts) == 1:
            item_name = ""
        else:
            _, item_name = parts
        return cls(item_name, item_images.get(check_name))

    def into_json(self):
        return omit_empty_lists_and_null({
            "name": self.name,
            "chest_unopened_img": self.image.filename() if self.image is not None else None,
        })


class RoomData(NamedTuple):
    name: str
    pickups: List[PickupData]

    @classmethod
    def from_ast(cls, name: ast.expr, room_data: ast.expr, filename: str):
        if (type(name) is not ast.Attribute or type(name.value) is not ast.Name or
            name.value.id != "RoomName"):
            raise ASTParseError(name, "Room name not from RoomName enum")

        room_name: str = eval(compile(ast.Expression(name), filename, "eval")).value

        if (type(room_data) is not ast.Call or type(room_data.func) is not ast.Name or
            room_data.func.id != "RoomData"):
            raise ASTParseError(room_data, "Room not assigned to RoomData object")

        pickups: List[PickupData] = []
        for keyword in room_data.keywords:
            if keyword.arg != "pickups":
                continue
            if type(keyword.value) is not ast.List:
                raise ASTParseError(keyword.value, "Kwarg pickups is not a list")
            for element in keyword.value.elts:
                pickups.append(PickupData.from_ast(element))

        return cls(room_name, pickups)

    def into_json(self):
        return omit_empty_lists_and_null({
            "name": self.name,
            "sections": [pickup.into_json() for pickup in self.pickups]
        })


class AreaData(NamedTuple):
    name: str
    rooms: List[RoomData]

    @classmethod
    def from_ast(cls, tree: ast.AST, filename: str):
        if type(tree) is not ast.Module:
            raise ASTParseError(tree, "Tree is not a module")
        module: ast.Module = tree

        class_def: Optional[ast.ClassDef] = None
        for statement in module.body:
            if type(statement) is ast.ClassDef:
                if class_def is None:
                    class_def = statement
                else:
                    raise ASTParseError(module, "Multiple class definitions in module")
        if class_def is None:
            raise ASTParseError(module, "No class definition in module")

        init_method: Optional[ast.FunctionDef] = None
        for statement in class_def.body:
            if type(statement) is ast.FunctionDef and statement.name == "__init__":
                if init_method is None:
                    init_method = statement
                else:
                    raise ASTParseError(class_def, "Found multiple __init__() methods")
        if init_method is None:
            raise ASTParseError(class_def, "Class is missing __init__() method")

        area_name_expr: Optional[ast.Expression] = None
        area_name: Optional[str] = None
        rooms_assign: Optional[ast.Dict] = None
        for statement in init_method.body:
            if type(statement) is ast.Expr and type(statement.value) is ast.Call:
                call = statement.value
                if type(call.func) is not ast.Attribute or type(call.func.value) is not ast.Call:
                    continue
                call = call.func.value
                if type(call.func) is not ast.Name or call.func.id != "super":
                    continue
                for arg in statement.value.args:
                    if type(arg) is ast.Attribute:
                        if area_name_expr is None:
                            area_name_expr = ast.Expression(arg)
                            break
                        else:
                            raise ASTParseError(statement.value, "Found multiple area name expressions")
            elif type(statement) is ast.Assign:
                for target in statement.targets:
                    if type(target) is ast.Attribute:
                        if (type(target.value) is ast.Name
                            and target.value.id == "self" and target.attr == "rooms"):
                            if type(statement.value) is not ast.Dict:
                                raise ASTParseError(statement.value, "Assigned a non-dict to self.rooms")
                            if rooms_assign is None:
                                rooms_assign = statement.value
                            else:
                                raise ASTParseError(init_method, "Found multiple assignments to self.rooms")
        if area_name_expr is None:
            ASTParseError(statement.value, "Missing area name")
        if rooms_assign is None:
            ASTParseError(init_method, "Missing assignment to self.rooms")

        area_name = eval(compile(area_name_expr, filename, "eval"))
        rooms = [RoomData.from_ast(key, value, filename)
                 for key, value in zip(rooms_assign.keys, rooms_assign.values, strict=True)]
        return cls(area_name, rooms)

    def into_json(self):
        return [omit_empty_lists_and_null({
            "name": self.name,
            "chest_unopened_img": "images/items/missilelauncher.png",
            "chest_opened_img": "images/checked.png",
            "children": [room.into_json() for room in self.rooms]
        })]


input = (data_path / area).with_suffix(".py")
with open(input, "r") as stream:
    content = stream.read()

data_ast = ast.parse(content)
# print(ast.dump(data_ast, indent=2))
try:
    result = AreaData.from_ast(data_ast, input.name)
except ASTParseError as e:
    print(ast.dump(e.tree))
    raise

with open(output, "w") as stream:
   json.dump(result.into_json(), stream, indent=2)
