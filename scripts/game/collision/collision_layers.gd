class_name CollisionLayers
extends RefCounted

const ENTITY_HIT := 1 << 0
const ENTITY_GROUND := 1 << 1
const ENTITY_AIR := 1 << 2
const TILE_GROUND := 1 << 3
const TILE_AIR := 1 << 4
const PROJECTILE_AIR := 1 << 5

const MASK_HUMAN := TILE_GROUND | ENTITY_GROUND | ENTITY_AIR
const MASK_NON_HUMAN_AIR := TILE_AIR | ENTITY_GROUND | ENTITY_AIR
const MASK_PROJECTILE_AIR := ENTITY_HIT | TILE_AIR
