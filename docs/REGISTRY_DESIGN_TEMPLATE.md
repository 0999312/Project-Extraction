# Registry Design Document Template

> Use this template when planning a new registry or revising an existing one.
> Copy the sections below into a working document and replace the placeholders.

---

## 1. Registry Overview

- **Registry name:** `<core:example_registry>`
- **Business purpose:** `<What problem does this registry solve?>`
- **Primary owner:** `<system / feature / team>`
- **Related gameplay/content areas:** `<items / POIs / quests / home modules / traders / audio / ...>`

## 2. ResourceLocation Rules

- **Entry namespace(s):** `<game / core / dlc_x / ...>`
- **Entry ID naming convention:** `<game:example_entry_name>`
- **Required tag naming convention (if any):** `<game:tag/example_tag>`
- **Cross-registry references:** `<Which other registries may entries reference?>`

## 3. Load Timing and Lifecycle

- **When is the registry created?** `<startup / loading screen / on demand>`
- **When are entries registered?** `<phase or function>`
- **Can entries be extended at runtime?** `<yes/no/how>`
- **Should the registry persist across scenes?** `<yes/no>`

## 4. Entry Schema

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `<id>` | `<ResourceLocation>` | `<yes/no>` | `<none>` | `<meaning>` |
| `<field_a>` | `<type>` | `<yes/no>` | `<value>` | `<meaning>` |
| `<field_b>` | `<type>` | `<yes/no>` | `<value>` | `<meaning>` |

### 4.1 Nested Structures (Optional)

| Nested Field | Type | Required | Description |
|---|---|---|---|
| `<nested.field>` | `<type>` | `<yes/no>` | `<meaning>` |

## 5. Validation Rules

- `<Rule 1: example — referenced ResourceLocations must exist>`
- `<Rule 2: example — numeric ranges must be clamped or rejected>`
- `<Rule 3: example — duplicate IDs are not allowed>`

## 6. Runtime Access Pattern

- **Lookup API:** `<RegistryManager.get_registry(...) / helper wrapper / service>`
- **Typical caller(s):** `<UI / gameplay runtime / save system / generation pipeline>`
- **Caching strategy:** `<none / local cache / precomputed map>`
- **Failure behavior:** `<log + skip / assert / fallback entry>`

## 7. Authoring Workflow

1. `<Where is source data authored?>`
2. `<How is it reviewed?>`
3. `<How is it validated?>`
4. `<How is it consumed by runtime code?>`

## 8. Save / Migration Notes

- **Are entry IDs saved directly?** `<yes/no>`
- **Compatibility strategy for removed entries:** `<fallback / conversion / refund>`
- **Version field needed?** `<yes/no>`

## 9. Example Entry

```json
{
  "id": "<game:example_entry>",
  "field_a": "<value>",
  "field_b": 0
}
```

## 10. Open Questions

- `<Question 1>`
- `<Question 2>`
- `<Question 3>`

## 11. Implementation Checklist

- [ ] Registry type name confirmed
- [ ] ResourceLocation naming rules confirmed
- [ ] Entry schema finalized
- [ ] Validation rules documented
- [ ] Runtime load timing documented
- [ ] Save/migration behavior documented
- [ ] Example entry reviewed
