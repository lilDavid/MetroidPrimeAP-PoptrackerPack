#/usr/bin/env python3

from argparse import ArgumentParser
import ast
from enum import StrEnum
import json
from pathlib import Path
import importlib.util
import sys
from typing import Dict, List, NamedTuple, Optional, Union


pack = Path(__file__).parents[1]
locations = pack / "locations"
options = pack / "items/options.json"


areas = [
    ("tallon", "TallonOverworld"),
    ("chozo", "ChozoRuins"),
    ("magmoor", "MagmoorCaverns"),
    ("phen", "PhendranaDrifts"),
    ("mines", "PhazonMines"),
]


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
    'Chozo Ruins: Watery Hall - Scan Puzzle': ItemImage.ChargeBeam,
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


locks = {
    "Blue": "AnyBeam",
    "Wave": "WaveBeam",
    "Ice": "IceBeam",
    "Plasma": "PlasmaBeam",
    "Missile": "Missile",
    "Power_Beam": "PowerBeam",
    "Bomb": "Bomb",
    "None_": "None",
}


override_functions = {
    "can_thermal",
    "can_xray",
    "can_flaahgra",
    "can_warp_to_start",
}


manual_door_rules = {
    ("Arboretum", "Sunchamber Lobby"): [
        "$can_scan,$can_bomb",
        "$can_scan,FlaahgraPowerBombs,$can_power_bomb,$can_space_jump"
    ],
    ("Hive Totem", "Transport Access North"): [
        "$can_power_beam",
        "RemoveHiveMecha"
    ],
    ("Magma Pool", "Meditation Fountain"): [
        "$has_energy_tanks|1,VariaSuit",
        "$has_energy_tanks|1,GravitySuit",
        "$has_energy_tanks|1,PhazonSuit",
    ]
}

manual_location_rules = {
    "Chozo Ruins: Hive Totem": [
        "$can_power_beam",
        "RemoveHiveMecha",
    ],
    "Magmoor Caverns: Fiery Shores - Warrior Shrine Tunnel": [
        "$can_power_bomb,$can_bomb,@Magmoor Caverns/Warrior Shrine",
    ],
    "Magmoor Caverns: Lava Lake": [
        "$can_missile,$can_space_jump,@Magmoor Caverns/Lake Tunnel/",
    ],
}

transport_rules = {
    "Tallon Overworld": {
        "Transport to Chozo Ruins West": "@Chozo Ruins/Transport to Tallon Overworld North",
        "Transport to Magmoor Caverns East": "@Magmoor Caverns/Transport to Tallon Overworld West",
        "Transport to Chozo Ruins East": "@Chozo Ruins/Transport to Tallon Overworld East",
        "Transport to Chozo Ruins South": "@Chozo Ruins/Transport to Tallon Overworld South",
        "Transport to Phazon Mines East": "@Phazon Mines/Transport to Tallon Overworld South",
    },
    "Chozo Ruins": {
        "Transport to Tallon Overworld North": "@Tallon Overworld/Transport to Chozo Ruins West",
        "Transport to Magmoor Caverns North": "@Magmoor Caverns/Transport to Chozo Ruins North",
        "Transport to Tallon Overworld East": "@Tallon Overworld/Transport to Chozo Ruins East",
        "Transport to Tallon Overworld West": "@Tallon Overworld/Transport to Chozo Ruins West",
    },
    "Magmoor Caverns": {
        "Transport to Chozo Ruins North": "@Chozo Ruins/Transport to Magmoor Caverns North",
        "Transport to Phendrana Drifts North": "@Phendrana Drifts/Transport to Magmoor Caverns West",
        "Transport to Tallon Overworld West": "@Tallon Overworld/Transport to Magmoor Caverns East",
        "Transport to Phendrana Drifts South": "@Phendrana Drifts/Transport to Magmoor Caverns South",
        "Transport to Phazon Mines West": "@Phazon Mines/Transport to Magmoor Caverns South",
    },
    "Phendrana Drifts": {
        "Transport to Magmoor Caverns West": "@Magmoor Caverns/Transport to Phendrana Drifts North",
        "Transport to Magmoor Caverns South": "@Magmoor Caverns/Transport to Phendrana Drifts South",
    },
    "Phazon Mines": {
        "Transport to Tallon Overworld South": "@Magmoor Caverns/Transport to Phazon Mines East",
        "Transport to Magmoor Caverns South": "@Magmoor Caverns/Transport to Phazon Mines West",
    },
}


# Parse args
parser = ArgumentParser(
    description="Converts the logic rules from MetrodAPrime for use in this tracker."
)
parser.add_argument(
    "path_to_apworld", type=Path,
    help="Path to the extracted Metroid Prime AP world source"
)
args = parser.parse_args()

data_path: Path = args.path_to_apworld / "data"


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


# AST parsing
JsonValue = Union[str, int, float, List["JsonValue"], Dict[str, "JsonValue"], None]


def omit_empty_lists_and_null(object: Dict[str, JsonValue]) -> Dict[str, JsonValue]:
    return {k: v for k, v in object.items() if v not in (None, [])}


def load_starting_rooms(options: List[Dict[str, JsonValue]]):
    starting_room_data: Optional[List[Dict[str, JsonValue]]] = None
    for option in options:
        if option["name"] == "Starting Room":
            starting_room_data = option["stages"]
    if starting_room_data is None:
        raise ValueError("No starting room data")

    starting_rooms: Dict[str, str] = {}
    for room in starting_room_data:
        starting_rooms[room["name"]] = room["codes"]
    return starting_rooms


with open(options, "r") as stream:
    starting_rooms = load_starting_rooms(json.load(stream))


class ASTParseError(ValueError):
    tree: ast.AST

    def __init__(self, tree: ast.AST, *args):
        super().__init__(*args)
        self.tree = tree


def validate_prime_world_node(world: ast.expr):
    if type(world) != ast.Subscript:
        raise ASTParseError(world, "Expected subscript")
    worlds = world.value
    if type(worlds) != ast.Attribute or worlds.attr != "worlds":
        raise ASTParseError(world, "Expected attribute 'worlds'")
    multiworld = worlds.value
    if type(multiworld) != ast.Attribute or multiworld.attr != "multiworld":
        raise ASTParseError(world, "Expected attribute 'multiworld'")
    state = multiworld.value
    if type(state) != ast.Name:
        raise ASTParseError(world, "Expected name")


def logic_function(function_name: str):
    if function_name in override_functions:
        return f"@rules/{function_name}"
    if function_name.startswith("can_combat"):
        return f"[${function_name}]"
    return f"${function_name}"


class RuleConverter(ast.NodeTransformer):
    collected_rules: Dict[str, None]
    rule_list_name: str
    filename: str

    def __init__(self, rule_list_name: str, filename: str):
        self.collected_rules = {}
        self.rule_list_name = rule_list_name
        self.filename = filename

    def visit_Call(self, node: ast.Call):
        if type(node.func) is ast.Name:
            function_name = node.func.id
        elif type(node.func) is ast.Attribute:
            name = node.func.value
            if type(name) is not ast.Name:
                raise ASTParseError(name, f"Expected name: {ast.dump(name)}")
            if node.func.attr.startswith("can_reach"):
                function_name = "can_reach"
            else:
                raise NotImplementedError(node.func.attr)
        else:
            raise ASTParseError(node.func, "Invalid function name")

        if function_name == "can_reach":
            if type(node.args[0]) is ast.Attribute:
                location_name = eval(compile(ast.Expression(node.args[0]), self.filename, "eval"))
            elif type(node.args[0]) is ast.Call:
                func = node.args[0].func
                if type(func) is not ast.Attribute:
                    raise ASTParseError(func)
                if func.attr == "get_location":
                    validate_prime_world_node(func.value)
                    location_name = "/".join(PickupData.split_check_name(ast.literal_eval(node.args[0].args[0])))
                else:
                    raise NotImplementedError(func.attr)
            else:
                raise ASTParseError(node.args[0])
            rule = f"@{location_name}"
        elif len(node.args) < 2:
            raise ASTParseError(node, f"{function_name} call with {len(node.args)} arguments")
        elif len(node.args) == 2:
            rule = logic_function(function_name)
        else:
            args: List[str] = []
            for arg in node.args[2:]:
                value = ast.literal_eval(arg)
                if type(value) is str:
                    args.append(value)
                else:
                    args.append(str(value).lower())
            rule = "|".join((f"${function_name}", *args))


        self.collected_rules[rule] = None
        node = ast.Subscript(
            value=ast.Name(id=self.rule_list_name, ctx=ast.Load()),
            slice=ast.Constant(value=rule),
            ctx=ast.Load(),
        )
        ast.fix_missing_locations(node)
        return node


def bits(n, size):
    for _ in range(size):
        yield n & 1
        n >>= 1


def parse_access_rule(rule_func: ast.expr, filename: str):
    if type(rule_func) is ast.Name:
        return [logic_function(rule_func.id)]

    elif type(rule_func) is ast.Lambda:
        if len(rule_func.args.args) != 2:
            raise ASTParseError(rule_func, f"Lambda has {len(rule_func.args.args)} arguments")

        if type(rule_func.body) is ast.Constant:
            if ast.literal_eval(rule_func.body):
                return None
            else:
                return ["False"]

        if type(rule_func.body) is ast.Call:
            if type(rule_func.body.func) is ast.Name:
                return [f"${rule_func.body.func.id}"]
            raise NotImplementedError(ast.dump(rule_func.body.func))

        if type(rule_func.body) is not ast.BoolOp:
            raise ASTParseError(rule_func, f"Lambda body is not a boolean operation")

        # Generate a truth table corresponding to each function's output
        dnf = []
        converter = RuleConverter("rule_functions", filename)
        expression = ast.Expression(converter.visit(rule_func.body))
        for i in range(1 << (len(converter.collected_rules))):
            rule_functions = {rule: bit for rule, bit in zip(converter.collected_rules, bits(i, len(converter.collected_rules)))}
            try:
                if eval(compile(expression, __file__, "eval")):
                    dnf.append(",".join(rule for rule, value in rule_functions.items() if value))
            except Exception as e:
                raise ASTParseError(rule_func) from e
        return dnf

    else:
        raise ASTParseError(rule_func, "Could not parse access rule")


class PickupData(NamedTuple):
    name: str
    image: Optional[ItemImage]
    access_rules: List[str]

    @staticmethod
    def split_check_name(check: str):
        area, room = check.split(": ")
        parts = room.split(" - ")
        if len(parts) == 1:
            room = parts[0]
            item = ""
        else:
            room, item = parts
        return area, room, item

    @classmethod
    def from_ast(cls, pickup_data: ast.expr, filename):
        if (type(pickup_data) is not ast.Call or type(pickup_data.func) is not ast.Name or
            pickup_data.func.id != "PickupData"):
            raise ASTParseError(pickup_data, "Pickup item is not from PickupData constructor")
        check_name: str = ast.literal_eval(pickup_data.args[0])

        _, _, item_name = cls.split_check_name(check_name)

        if check_name in manual_location_rules:
            access_rule = manual_location_rules[check_name]
        else:
            access_rule: Optional[str] = None
            for kwarg in pickup_data.keywords:
                if kwarg.arg != "rule_func":
                    continue
                access_rule = parse_access_rule(kwarg.value, filename)

        return cls(item_name, item_images.get(check_name), access_rule if access_rule is not None else [])

    def into_json(self):
        return omit_empty_lists_and_null({
            "name": self.name,
            "chest_unopened_img": self.image.filename() if self.image is not None else None,
            "access_rules": self.access_rules
        })


class DoorData(NamedTuple):
    source: str
    destination: str
    access_rule: List[str]
    exclude_from_rando: bool

    @classmethod
    def from_ast(cls, door: ast.expr, source: str, filename: str):
        if (type(door) is not ast.Call or type(door.func) is not ast.Name or
            door.func.id != "DoorData"):
            raise ASTParseError(door, "Door item is not from DoorData constructor")
        door_type = None
        exclude_from_rando = False
        access_rule = None
        if (type(door.args[0]) is not ast.Attribute or type(door.args[0].value) is not ast.Name or
            door.args[0].value.id != "RoomName"):
            raise ASTParseError(door.args[0], "Expected room name")
        destination = eval(compile(ast.Expression(door.args[0]), filename, "eval"))
        for kwarg in door.keywords:
            if kwarg.arg in ("lock", "defaultLock"):
                if (type(kwarg.value) is not ast.Attribute or
                    type(kwarg.value.value) is not ast.Name or
                    kwarg.value.value.id != "DoorLockType"):
                    raise ASTParseError(kwarg.value, "Door lock is not a DoorLockType")
                if kwarg.arg == "lock" or door_type is None:
                    door_type = locks[kwarg.value.attr]
            if kwarg.arg == "exclude_from_rando":
                exclude_from_rando = ast.literal_eval(kwarg.value)
            if kwarg.arg == "rule_func":
                if (source, destination.value) in manual_door_rules:
                    access_rule = manual_door_rules[(source, destination.value)]
                else:
                    access_rule = parse_access_rule(kwarg.value, filename)
        if door_type is None:
            door_type = "AnyBeam"
        if access_rule:
            access_rule = [f"@doors/{door_type}/,{rule}" for rule in access_rule]
        else:
            access_rule = [f"@doors/{door_type}"]
        return cls(source, destination.value, access_rule, exclude_from_rando)


class WorldRoomData(NamedTuple):
    name: str
    pickups: List[PickupData]
    doors: List[DoorData]  # Doors whose sources are this room

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
        doors: List[DoorData] = []
        for keyword in room_data.keywords:
            if keyword.arg == "pickups":
                if type(keyword.value) is not ast.List:
                    raise ASTParseError(keyword.value, "Kwarg pickups is not a list")
                for element in keyword.value.elts:
                    pickups.append(PickupData.from_ast(element, filename))
            if keyword.arg == "doors":
                if type(keyword.value) is not ast.Dict:
                    raise ValueError("Kwarg doors is not a dict")
                for value in keyword.value.values:
                    doors.append(DoorData.from_ast(value, room_name, filename))

        return cls(room_name, pickups, doors)


class TrackerRoomData(NamedTuple):
    name: str
    pickups: List[PickupData]
    access_rules: List[str]

    @classmethod
    def from_world_room_data(cls, world_data: WorldRoomData, all_doors: List[DoorData], transports: Dict[str, str]):
        doors = [door for door in all_doors if door.destination == world_data.name]

        rules = []
        if world_data.name in starting_rooms:
            rules.append(starting_rooms[world_data.name])
        for door in doors:
            rules.extend(f"@{door.source},{rule}" for rule in door.access_rule)

        if world_data.name in transports:
            rules.append(f"$can_access_elevators,{transports[world_data.name]}")

        return cls(world_data.name, world_data.pickups, rules)

    def into_json(self):
        return omit_empty_lists_and_null({
            "name": self.name,
            "sections": [pickup.into_json() for pickup in self.pickups],
            "access_rules": self.access_rules,
        })


class AreaData(NamedTuple):
    name: str
    rooms: List[TrackerRoomData]

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
        world_rooms = [WorldRoomData.from_ast(key, value, filename)
                 for key, value in zip(rooms_assign.keys, rooms_assign.values, strict=True)]
        doors = []
        for room in world_rooms:
            doors.extend(room.doors)
        tracker_rooms = [TrackerRoomData.from_world_room_data(room, doors, transport_rules[area_name])
                         for room in world_rooms]
        return cls(area_name, tracker_rooms)

    def into_json(self):
        return [omit_empty_lists_and_null({
            "name": self.name,
            "chest_unopened_img": "images/items/missilelauncher.png",
            "chest_opened_img": "images/checked.png",
            "children": [room.into_json() for room in self.rooms]
        })]


# Parse files
for short_name, data_name in areas:
    input = (data_path / data_name).with_suffix(".py")
    output = (locations / short_name).with_suffix(".json")

    with open(input, "r") as stream:
        content = stream.read()

    data_ast = ast.parse(content)
    # print(ast.dump(data_ast, indent=2))
    try:
        result = AreaData.from_ast(data_ast, input.name)
    except ASTParseError as e:
        raise Exception(f"Could not parse {input.name}:\n{ast.dump(e.tree)}") from e
    except Exception as e:
        raise Exception(f"Could not parse {input.name}") from e

    with open(output, "w") as stream:
       json.dump(result.into_json(), stream, indent=2)